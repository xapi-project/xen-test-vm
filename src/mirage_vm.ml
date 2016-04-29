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

  type cmd =
    | Cmd       of Commands.message
    | CmdError  of string 
    | CmdNone

  let read_cmd client path =
    read_opt client path >>= function
    | None      -> return CmdNone
    | Some ""   -> return CmdNone
    | Some msg  ->
        Lwt.catch 
          (fun () -> return @@ Cmd (Commands.Scan.message msg))
          (function
          | CMD.Error msg -> return @@ CmdError(msg)
          | x             -> return @@ CmdError("what happened?")
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
      ack' client control_shutdown >>= fun () ->
        ( match msg, override with
        | Some "" , _       -> return false
        | None    , _       -> return false
        | Some "suspend", _ -> suspend ()
        | Some "poweroff", _-> poweroff ()
        | Some "reboot", _  -> reboot ()
        | Some "halt",_     -> halt ()
        | Some "crash",_    -> crash ()
        | Some x,_          -> 
            log c "unknown shutdown reason %s" x >>= fun () -> 
            return false
        ) >>= fun x ->
      (* read command and store in override
       *)
      read_cmd client control_testing >>= fun msg ->
      ack' client control_testing >>= fun () ->
        ( match msg with
        | CmdNone   -> return x
        | Cmd cmd   -> 
            log c "received testing command" >>= fun () -> 
            loop (tick+1) (Some cmd)
        | CmdError msg -> 
            log c "received bogus command: %s" msg >>= fun () -> 
            return x
        ) >>= fun _ ->
      (* just some reporting *)
      sleep 1.0 >>= fun x ->
      read client "domid" >>= fun domid ->
      log c "domain %s tick %d" domid tick >>= fun () -> 
      ( match override with
      | Some cmd -> log c "override is active" >>= fun _ -> return x
      | None     -> return x
      ) >>= fun _ ->
      loop (tick+1) override
    in 
    loop 0 None
end
