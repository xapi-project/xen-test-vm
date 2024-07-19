open Mirage

let main =
  let packages =
    [
      package "logs";
      package "lwt";
      package "yojson";
      package "xenstore";
    ]
  in
  main ~packages "Unikernel.Main" (time @-> job)

let () = register "xenserver-test-vm" [ main $ default_time ]
