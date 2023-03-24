open Mirage

let suspend =
  let doc = Key.Arg.info ~doc:"suspend" [ "suspend" ] in
  Key.(create "key" Arg.(opt (some string) None doc))

let console_handler =
  let packages =
    [
      package "logs";
      package "lwt";
      package "mirage-console-xen";
      package "mirage-logs";
      package "mirage-xen";
      package ~min:"4.3.1" "mirage-runtime";
      package "yojson";
      package "xenstore";
    ]
  in
  foreign ~packages "Unikernel.Main" (console @-> time @-> job)

let () = register "xenserver-test-vm" [ console_handler $ default_console $ default_time ]
