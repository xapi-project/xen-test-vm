(* This code implements a minimal kernel that responds to
 * lifecycle events.
 *)

(* Documentation of important interfaces:
 * http://mirage.github.io/mirage-xen/#Xs
 * http://mirage.github.io/mirage-xen/#Sched
 * http://mirage.github.io/mirage-types/#V1:CONSOLE
 *)


module Main (C: V1_LWT.CONSOLE) = struct
  open Lwt

  (* These are like [C.log] and [C.log_s] but accept printf-style
   * formatting instructions.
   *)
  let log_s c fmt = Printf.kprintf (fun msg -> C.log_s c msg) fmt
  let log   c fmt = Printf.kprintf (fun msg -> C.log   c msg) fmt


  (* The suspend operation acknowledges the request by removing 
   * "control/shutdown" from Xen Store.
   *)
  let suspend client c =
    OS.Xs.(immediate client (fun h -> rm h "control/shutdown")) >>= fun _ -> 
    OS.Sched.suspend () >>= fun cancelled -> 
    log_s c "cancelled=%d" cancelled >>= fun () ->
    log_s c "About to read domid"    >>= fun () ->
    OS.Xs.(immediate client (fun h -> read h "domid")) >>= fun domid -> 
    log_s c "We're back: domid=%s" domid >>= fun _ -> 
    return true

  let read client path  = 
    catch   
        (fun () -> OS.Xs.(immediate client (fun h -> read h path)) >>= fun
          msg -> return (Some msg) )
        ( function 
        | _ -> return None
        )

  let sleep secs    = OS.Time.sleep secs
  let poweroff ()   = OS.Sched.(shutdown Poweroff); return false 
  let reboot ()     = OS.Sched.(shutdown Reboot);   return false 
  let halt ()       = OS.Sched.(shutdown Poweroff); return false
  let crash ()      = OS.Sched.(shutdown Crash);    return false

  (* event loop *)  
  let start c = 
    OS.Xs.make () >>= fun client -> 
    OS.Xs.(immediate client (fun h -> read h "domid")) >>= fun domid -> 
    log_s c "domid=%s" domid >>= fun () ->
    let rec loop () = 
        read client "control/shutdown" >>= 
        ( function
        | Some "suspend"    -> suspend client c
        | Some "poweroff"   -> poweroff ()
        | Some "reboot"     -> reboot ()
        | Some "halt"       -> halt ()
        | Some "crash"      -> crash ()
        | Some msg          -> log_s c "control/shutdown %s" msg >>= fun _ -> return false
        | None              -> log_s c "No message in control/shutdown" >>= fun _ -> return false
        ) >>= fun _ ->
      sleep 1.0 >>= fun _ ->
      loop ()
    in 
      loop ()
end
