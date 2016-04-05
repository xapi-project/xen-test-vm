
module Main (C: V1_LWT.CONSOLE) = struct
  open Lwt

  (* These are like [C.log] and [C.log_s] but accept printf-style
   * formatting instructions.
   *)
  let log   c fmt = Printf.kprintf (fun msg -> C.log   c msg) fmt 
  let log_s c fmt = Printf.kprintf (fun msg -> C.log_s c msg) fmt

  let suspend c =
    OS.Sched.suspend () >>= fun cancelled -> 
    log c "cancelled=%d" cancelled;
    return cancelled

    (* Documentation 
     * http://mirage.github.io/mirage-xen/#Xs
     * http://mirage.github.io/mirage-xen/#Sched
     * http://mirage.github.io/mirage-types/#V1:CONSOLE
     *)

  let start c = 
    log_s c "xs_watch ()" >>= fun () -> 
    OS.Xs.make () >>= fun client -> 
    let rec loop () = 
      OS.Xs.(immediate client (fun h -> directory h "control")) >>= fun dir -> 
      begin if List.mem "shutdown" dir then begin
          OS.Xs.(immediate client (fun h -> read h "control/shutdown")) >>= fun msg ->
          log_s c "Got control message: %s" msg >>= fun () ->
          match msg with
          | "suspend" -> 
            OS.Xs.(immediate client (fun h -> rm h "control/shutdown")) >>= fun _ -> 
            suspend c >>= fun _ -> 
            log_s c "About to read domid" >>= fun _ ->
            OS.Xs.(immediate client (fun h -> read h "domid")) >>= fun domid -> 
            log_s c "We're back: domid=%s" domid >>= fun _ -> 
            return true
          | "poweroff" -> 
            OS.Sched.shutdown OS.Sched.Poweroff;
            return false (* Doesn't get here! *)
          | "reboot" ->
            OS.Sched.shutdown OS.Sched.Reboot;
            return false (* Doesn't get here! *)
          | "halt" ->
            OS.Sched.shutdown OS.Sched.Poweroff;
            return false
          | "crash" ->
            OS.Sched.shutdown OS.Sched.Crash;
            return false
          | _ -> 
            return false
        end else return false end >>= fun _ ->
      OS.Time.sleep 1.0 >>= fun _ ->
      loop ()
    in loop ()

end
