(* This code implements a minimal kernel that responds to
 * life cycle events.
 *)

(* Documentation of important interfaces:
 * http://mirage.github.io/mirage-xen/#Xs
 * http://mirage.github.io/mirage-xen/#Sched
 * http://mirage.github.io/mirage-types/#V1:CONSOLE
 * http://mirage.github.io/xenstore/#Xs_protocol
 *)

module Main (Time : Mirage_time.S) = struct
  module CMD = Commands
  module XS = Xen_os.Xs

  let ( let* ) = Lwt.bind
  let return = Lwt.return
  let ( let@ ) f x = f x

  (* command strings *)
  let control_shutdown = "control/shutdown"
  let control_testing = "control/testing"

  let read client path =
    let@ h = XS.immediate client in
    XS.read h path

  (* [ack] acknowledges a message and offers to violate the proper
     protocol (AckOK) by doing something else *)
  let ack client path = function
    | CMD.AckOK ->
        let@ h = XS.immediate client in
        XS.write h path ""
    | CMD.AckWrite x ->
        let@ h = XS.immediate client in
        XS.write h path x
    | CMD.AckDelete ->
        let@ h = XS.immediate client in
        XS.rm h path
    | CMD.AckNone -> return ()

  (* [read_opt client path] reads [path] from the Xen Store and
     returns it as an option value on success, and [None] otherwise.
     Unexpected errors still raise an exception.
  *)
  let read_path client path =
    Lwt.catch
      (fun () ->
        let* msg = read client path in
        return (Some msg))
      (function Xs_protocol.Enoent _ -> return None | ex -> Lwt.fail ex)

  (** [read_cmd] reads a command in JSON format from [path] and * returns it, or
      [None] when nothing is there *)
  let read_cmd client path =
    let* msg = read_path client path in
    match msg with
    | None -> return None
    | Some msg ->
        let* () = ack client path CMD.AckOK in
        Lwt.catch
          (fun () -> return (Some (Commands.from_string msg)))
          (function
            | CMD.Error msg ->
                let () = Logs.warn (fun m -> m "bogus command %s" msg) in
                return None
            | x -> Lwt.fail x)

  let suspend () =
    Logs.info (fun m -> m "%s!" __FUNCTION__);
    return true

  let poweroff () =
    Logs.info (fun m -> m "%s!" __FUNCTION__);
    return true

  let reboot () =
    Logs.info (fun m -> m "%s!" __FUNCTION__);
    return true

  let halt () =
    Logs.info (fun m -> m "%s!" __FUNCTION__);
    return true

  let crash () =
    Logs.info (fun m -> m "%s!" __FUNCTION__);
    return true

  (** [dispatch] implements the reaction to control messages *)
  let dispatch = function
    | CMD.Suspend -> suspend ()
    | CMD.PowerOff -> poweroff ()
    | CMD.Reboot -> reboot ()
    | CMD.Halt -> halt ()
    | CMD.Crash -> crash ()
    | CMD.Ignore -> return false

  let cmd_of_msg = function
    | "suspend" -> CMD.Suspend
    | "poweroff" -> CMD.PowerOff
    | "reboot" -> CMD.Reboot
    | "halt" -> CMD.Halt
    | "crash" -> CMD.Crash
    | _ -> CMD.Ignore

  (* event loop *)
  let start _time =
    let* client = XS.make () in
    let rec loop tick cmd =
      let* msg = read_path client control_shutdown in
      let* x =
        match (cmd, msg) with
        (* no testing command present, regular kernel behaviour *)
        | None, None -> return true
        | None, Some msg ->
            let* () = ack client control_shutdown CMD.AckOK in
            cmd_of_msg msg |> dispatch
        (* we have a command to execute and to remove it for the
         * next iteration of the loop *)
        | Some (CMD.Now action), _ ->
            let* _ = dispatch action in
            loop (tick + 1) None
        | Some (CMD.OnShutdown (a, action)), Some _ ->
            let* () = ack client control_shutdown a in
            let _ = dispatch action in
            loop (tick + 1) None
        | Some (CMD.OnShutdown (_, _)), None ->
            return true (* not yet - wait for shutdown message *)
      in
      (* read command, ack it, and store it for execution *)
      let* x =
        let* cmd = read_cmd client control_testing in
        match cmd with
        | Some cmd -> loop (tick + 1) (Some cmd)
        | None -> return x
      in
      (* report the current state *)
      let* () = Time.sleep_ns (Duration.of_sec 1) in
      let* domid = read client "domid" in
      let () = Logs.info (fun m -> m "domain %s tick %d" domid tick) in
      let* _ =
        match cmd with
        | Some _ ->
            let () = Logs.info (fun m -> m "command is active") in
            return x
        | None -> return x
      in
      (* loop *)
      loop (tick + 1) cmd
    in
    let* (_ : bool) = loop 0 None in
    return ()
end
