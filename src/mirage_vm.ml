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
  let ack' client path  = XS.(immediate client @@ fun h -> write h path "") 
  let read client path = XS.(immediate client @@ fun h -> read h path) 

  (* [ack] acknowledges a message and offers to violate the proper
   * protocol (AckOK) by doing something else *)

  let ack client path = function
    | CMD.AckOK        -> XS.(immediate client @@ fun h -> write h path "") 
    | CMD.AckWrite(x)  -> XS.(immediate client @@ fun h -> write h path x )
    | CMD.AckNone      -> return () (* do nothing *)
    | CMD.AckDelete    -> XS.(immediate client @@ fun h -> rm h path)


  (* [read_opt client path] reads [path] from the Xen Store and
   * returns it as an option value on success, and [None] otherwise.
   * A empty string is returned as [None] (and thus conflates
   * no string and the empty string).  Unexpected errors still raise an
   * exception.
  *)
  let read_opt client  path  = 
    Lwt.catch
      ( fun () ->
          read client path >>= 
          ( function 
          | ""  -> return None       (* XXX right design choice? *)
          | msg -> return (Some msg)
          )
      )
      ( function 
        | Xs_protocol.Enoent _ -> return None 
        | ex                   -> Lwt.fail ex 
      )

  (** [read_cmd] reads a command in JSON format from [path] and 
   * returns it, or [None] when nothing is there *)
  let read_cmd c client path =
    read_opt client path >>= function
    | None      -> return None
    | Some msg  ->
        ack' client path >>= fun () ->
        Lwt.catch 
          (fun () -> return @@ Some (Commands.from_string msg))
          (function
          | CMD.Error msg -> 
              log c "bogus command %s" msg >>= fun () -> return None
          | x -> Lwt.fail x
          )

  let sleep secs    = OS.Time.sleep secs

  let suspend ()    = OS.Sched.suspend () >>= fun _ -> return true
  let poweroff ()   = OS.Sched.(shutdown Poweroff); return true 
  let reboot ()     = OS.Sched.(shutdown Reboot);   return true 
  let halt ()       = OS.Sched.(shutdown Poweroff); return true
  let crash ()      = OS.Sched.(shutdown Crash);    return true

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
    let rec loop tick cmd = 
      read_opt client control_shutdown >>= fun msg ->
      ( match cmd, msg with
      
      (* no testing command present, regular kernel behaviour *)
      | None, None      ->  return true
      | None, Some msg  ->  
        ack' client control_shutdown >>= fun () ->
        ( match msg with
        | "suspend"     ->  suspend ()
        | "poweroff"    ->  poweroff ()
        | "reboot"      ->  reboot ()
        | "halt"        ->  halt ()
        | "crash"       ->  crash ()
        |  x            ->  log c "unknown shutdown reason %s" x 
                            >>= fun () -> return true
        ) 
      
      (* we have a command to execute and to remove it for the
       * next iteration of the loop *)
      | Some(CMD.Now(action)), _           -> 
          dispatch action >>= fun _ -> loop (tick+1) None
      | Some(CMD.OnShutdown(a, action)), Some _ ->
          ack client control_shutdown a >>= fun () ->
          dispatch action >>= fun _ -> loop (tick+1) None
      | Some(CMD.OnShutdown(_, _)), None ->
          return true (* not yet - wait for shutdown message *)
      ) >>= fun x ->
      
      (* read command, ack it, and store it for execution *)    
      read_cmd c client control_testing >>= 
        ( function
        | Some cmd  -> loop (tick+1) (Some cmd)
        | None      -> return x
        ) >>= fun _ ->

      (* report the current state *)
      sleep 1.0 >>= fun x ->
      read client "domid" >>= fun domid ->
      log c "domain %s tick %d" domid tick >>= fun () -> 
      ( match cmd with
      | Some _   -> log c "command is active" >>= fun _ -> return x
      | None     -> return x
      ) >>= fun _ ->
      
      (* loop *)
      loop (tick+1) cmd
    in 
    loop 0 None
end
