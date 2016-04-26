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
  module XS  = OS.Xs (* Xen Store *)

  let (>>=)  = Lwt.(>>=)
  let return = Lwt.return

  (* command strings *)
  let control_shutdown = "control/shutdown"
  let control_testing  = "control/testing"


  (* These are like [C.log] and [C.log] but accept printf-style
   * formatting instructions.
  *)
  let log c fmt = Printf.kprintf (fun msg -> C.log_s c msg) fmt

  let read client path = XS.(immediate client @@ fun h -> read h path) 
  let ack  client path = XS.(immediate client @@ fun h -> write h path "") 

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


  let sleep secs    = OS.Time.sleep secs

  let suspend ()    = OS.Sched.suspend () >>= fun _ -> return true
  let poweroff ()   = OS.Sched.(shutdown Poweroff); return false 
  let reboot ()     = OS.Sched.(shutdown Reboot);   return false 
  let halt ()       = OS.Sched.(shutdown Poweroff); return false
  let crash ()      = OS.Sched.(shutdown Crash);    return false

  (** [dispatch] implements the reaction to control messages *)
  let dispatch = function
    | CMD.Suspend   -> suspend ()
    | CMD.PowerOff  -> poweroff ()
    | CMD.Reboot    -> reboot ()
    | CMD.Halt      -> halt ()
    | CMD.Crash     -> crash ()
    | CMD.Ignore    -> return false


  (* event loop *)  
  let start c = 
    OS.Xs.make () >>= fun client -> 
    let rec loop tick override = 
      (* read control messages, honor override if present *)
      read_opt client control_shutdown >>= fun msg ->
        ( match msg, override with
        | Some "" , _ -> return false
        | Some _  , Some override ->
            ack client control_shutdown >>= fun () ->
            dispatch override >>= fun _ ->
            loop (tick+1) None (* clear override *)
        | Some msg, None ->
            ack client control_shutdown >>= fun () ->
            dispatch (CMD.Scan.shutdown msg)
        | None    , _ -> 
            return false
        ) >>= fun x ->
      (* read out-of band test messages like now:reboot or 
       * next:reboot and register it as an override  
       *)
      read_opt client control_testing >>= 
        ( function 
        | Some ""  -> return x
        | Some msg ->
            ack client control_testing >>= fun () ->
            ( match CMD.Scan.testing msg with
            | CMD.Now(shutdown)  -> dispatch shutdown
            | CMD.Next(override) -> loop (tick+1) (Some override)
            ) 
        | None -> return x
        ) >>= fun _ ->
      (* just some reporting *)
      sleep 1.0 >>= fun x ->
      read client "domid" >>= fun domid ->
      log c "domain %s tick %d" domid tick >>= fun () -> 
      ( match override with
      | Some cmd -> log c "override %s is active" 
                      (CMD.String.shutdown cmd) >>= fun _ -> return x 
      | None     -> return x
      ) >>= fun _ ->
      loop (tick+1) override
    in 
    loop 0 None
end
