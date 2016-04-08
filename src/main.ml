
open Lwt

let run = OS.Main.run
let _   = Printexc.record_backtrace true

module VM = Mirage_vm.Main(Console_xen)

let argv    = lazy (Bootvar.argv ())
let console = lazy (Console_xen.connect "0")

let key = lazy (
  let __argv = Lazy.force argv in
  __argv >>= function
  | `Error _e   -> fail (Failure "argv")
  | `Ok _argv   -> 
    return @@
    Functoria_runtime.with_argv Key_gen.runtime_keys "suspend" _argv
)

let f11 = lazy (
  let __console = Lazy.force console in
  __console >>= function
  | `Error _e     -> fail (Failure "console")
  | `Ok _console  -> VM.start _console >>= fun t -> Lwt.return (`Ok t)
)

let mirage = lazy (
  let __key = Lazy.force key in
  let __f11 = Lazy.force f11 in
  __key >>= function
  | `Error _e -> fail (Failure "key")
  | `Ok _key ->
    __f11 >>= function
    | `Error _e -> fail (Failure "f11")
    | `Ok _f11 ->
      Lwt.return_unit
)

let () =
  let t = Lazy.force key >>= function
    | `Error _e -> exit 1
    | `Ok _     -> Lazy.force mirage
  in run t

