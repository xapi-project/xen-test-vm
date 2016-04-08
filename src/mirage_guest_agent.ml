(* This code implements a minimal kernel that responds to
 * life cycle events.
*)

(* Documentation of important interfaces:
 * http://mirage.github.io/mirage-xen/#Xs
 * http://mirage.github.io/mirage-xen/#Sched
 * http://mirage.github.io/mirage-types/#V1:CONSOLE
 * http://mirage.github.io/xenstore/#Xs_protocol
*)


module Main (C: V1_LWT.CONSOLE) = struct

  module CMD = Commands

  let (>>=)  = Lwt.(>>=)
  let return = Lwt.return

  (* command strings *)
  let control_shutdown = "control/shutdown"
  let control_testing  = "control/testing"


  (* These are like [C.log] and [C.log_s] but accept printf-style
   * formatting instructions.
  *)
  let log_s c fmt = Printf.kprintf (fun msg -> C.log_s c msg) fmt
  (* let log   c fmt = Printf.kprintf (fun msg -> C.log   c msg) fmt *)

  let rm   client path = OS.Xs.(immediate client @@ fun h -> rm   h path)
  let read client path = OS.Xs.(immediate client @@ fun h -> read h path) 

  (* [read_opt client path] reads [path] from the Xen Store and
   * returns it as an option value on success, and [None] otherwise.
   * Unexpected errors still raise an exception.
  *)
  let read_opt client  path  = 
    Lwt.catch
      ( fun () ->
          read client path >>= fun msg -> 
          return (Some msg)
      )
      ( function 
        | Xs_protocol.Enoent _ -> return None 
        | ex                   -> Lwt.fail ex 
      )

  (* The suspend operation acknowledges the request by removing 
   * "control/shutdown" from Xen Store.
  *)
  let suspend client c =
    rm client control_shutdown>>= fun () ->
    OS.Sched.suspend ()                 >>= fun cancelled -> 
    log_s c "cancelled=%d" cancelled    >>= fun () ->
    read client "domid"                 >>= fun domid ->
    log_s c "We're back: domid=%s" domid >>= fun _ -> 
    return true


  let sleep secs    = OS.Time.sleep secs
  let poweroff ()   = OS.Sched.(shutdown Poweroff); return false 
  let reboot ()     = OS.Sched.(shutdown Reboot);   return false 
  let halt ()       = OS.Sched.(shutdown Poweroff); return false
  let crash ()      = OS.Sched.(shutdown Crash);    return false

  (** [dispatch] implements the reaction to control messages *)
  let dispatch client c = function
    | CMD.Suspend   -> suspend client c
    | CMD.PowerOff  -> poweroff ()
    | CMD.Reboot    -> reboot ()
    | CMD.Halt      -> halt ()
    | CMD.Crash     -> crash ()


  (** [override client c msg tst] implements the reaction to
   * having received [msg] but reacting as having received [tst] instead
  let override client c msg tst = 
    log_s c "overriding command %s with %s" msg tst >>= fun () ->
    rm client control_testing >>= fun () ->
    dispatch client c tst
  *)

  (* event loop *)  
  let start c = 
    OS.Xs.make ()               >>= fun client -> 
    read client "domid"         >>= fun domid ->
    log_s c "domid=%s" domid    >>= fun () ->
    let rec loop tick override = 
      read_opt client control_shutdown >>= fun msg ->
        ( match msg, override with
        | Some msg, Some override -> dispatch client c override
        | Some msg, None          -> dispatch client c (CMD.shutdown msg)
        | None    , _             -> return false
        ) >>= fun x ->
      read_opt client control_testing >>= 
        ( function 
        | Some msg ->
            rm client control_testing >>= fun () ->
            ( match CMD.testing msg with
            | CMD.Now(shutdown)  -> dispatch client c shutdown
            | CMD.Next(override) -> loop (tick+1) (Some override)
            ) 
        | None     -> return x
        ) >>= fun _ ->
      sleep 1.0 >>= fun x ->
      log_s c "domain %s tick %d" domid tick >>= fun () -> 
      ( match override with
      | Some _ -> log_s c "override is active"
      | None   -> return x
      ) >>= fun x ->
      loop (tick+1) override
    in 
    loop 0 None
end
