
open Lwt

let run = OS.Main.run
let _   = Printexc.record_backtrace true

module Mirage_guest_agent1 = Mirage_guest_agent.Main(Console_xen)

let argv_xen1 = 
  lazy (Bootvar.argv ())

let console_xen_01 = 
  lazy ( Console_xen.connect "0")

let key1 = lazy (
  let __argv_xen1 = Lazy.force argv_xen1 in
  __argv_xen1 >>= function
  | `Error _e         -> fail (Failure "argv_xen1")
  | `Ok _argv_xen1    -> 
    return @@
    Functoria_runtime.with_argv Key_gen.runtime_keys "suspend" _argv_xen1
)

let f11 = lazy (
  let __console_xen_01 = Lazy.force console_xen_01 in
  __console_xen_01 >>= function
  | `Error _e -> fail (Failure "console_xen_01")
  | `Ok _console_xen_01 ->
    Mirage_guest_agent1.start _console_xen_01 >>= fun t -> Lwt.return (`Ok t)
)

let mirage1 = lazy (
  let __key1 = Lazy.force key1 in
  let __f11 = Lazy.force f11 in
  __key1 >>= function
  | `Error _e -> fail (Failure "key1")
  | `Ok _key1 ->
    __f11 >>= function
    | `Error _e -> fail (Failure "f11")
    | `Ok _f11 ->
      Lwt.return_unit
)

let () =
  let t = Lazy.force key1 >>= function
    | `Error _e -> exit 1
    | `Ok _ -> Lazy.force mirage1
  in run t

