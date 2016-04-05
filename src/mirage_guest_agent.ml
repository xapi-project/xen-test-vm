
module Main (C: V1_LWT.CONSOLE) = struct
  open Lwt

  (* These are like [C.log] and [C.log_s] but accept printf-style
   * formatting instructions.
   *)
  let log   c fmt = Printf.kprintf (fun msg -> C.log   c msg) fmt 
  let log_s c fmt = Printf.kprintf (fun msg -> C.log_s c msg) fmt

  (* implementation of control operations *)
  let suspend client c =
    OS.Xs.(immediate client (fun h -> rm h "control/shutdown")) >>= fun _ -> 
    OS.Sched.suspend () >>= fun cancelled -> 
    log_s c "cancelled=%d" cancelled >>= fun () ->
    log_s c "About to read domid"    >>= fun () ->
    OS.Xs.(immediate client (fun h -> read h "domid")) >>= fun domid -> 
    log_s c "We're back: domid=%s" domid >>= fun _ -> 
    return true

  let poweroff ()   = OS.Sched.shutdown OS.Sched.Poweroff; return false 
  let reboot ()     = OS.Sched.shutdown OS.Sched.Reboot;   return false 
  let halt ()       = OS.Sched.shutdown OS.Sched.Poweroff; return false
  let crash ()      = OS.Sched.shutdown OS.Sched.Crash;    return false

    (* Documentation 
     * http://mirage.github.io/mirage-xen/#Xs
     * http://mirage.github.io/mirage-xen/#Sched
     * http://mirage.github.io/mirage-types/#V1:CONSOLE
     *)

  (* event loop *)  
  let start c = 
    OS.Xs.make () >>= fun client -> 
    let rec loop () = 
      OS.Xs.(immediate client (fun h -> directory h "control")) >>= fun dir -> 
      if not @@ List.mem "shutdown" dir then 
        return false 
      else begin
        OS.Xs.(immediate client (fun h -> read h "control/shutdown")) >>= fun msg ->
        log_s c "Got control message: %s" msg >>= fun () ->
        ( match msg with
        | "suspend"   -> suspend client c
        | "poweroff"  -> poweroff ()
        | "reboot"    -> reboot ()
        | "halt"      -> halt ()
        | "crash"     -> crash ()
        | _           -> return false
        )
      end >>= fun _ ->
      OS.Time.sleep 1.0 >>= fun _ ->
      loop ()
    in 
      loop ()

end
