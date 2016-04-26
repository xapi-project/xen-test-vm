(** This module implements recognizers for commands and maps them from
 *  strings to a more abstract data type
 *)

{
  module L = Lexing
  exception Error of string

  type shutdown =
    | Suspend
    | PowerOff
    | Reboot
    | Halt
    | Crash
    | Ignore

  type testing =
    | Now   of shutdown
    | Next  of shutdown 
}

  rule shutdown = parse
    | "suspend"   { Suspend }
    | "poweroff"  { PowerOff }
    | "reboot"    { Reboot }
    | "halt"      { Halt }
    | "crash"     { Crash }
    | "ignore"    { Ignore }
    | _           { raise (Error "unknown shutdown command") }

  and testing = parse
    | "now:"      { Now(shutdown lexbuf) }
    | "next:"     { Next(shutdown lexbuf) }
    | _           { raise (Error "unknown side channel command") }
 
{

  module Scan = struct
    let shutdown str =  shutdown (L.from_string str) 
    let testing  str =  testing  (L.from_string str) 
  end

  module String = struct
    let shutdown = function
      | Suspend   -> "suspend"
      | PowerOff  -> "poweroff"
      | Reboot    -> "reboot"
      | Halt      -> "halt"
      | Crash     -> "crash"
      | Ignore    -> "ignore"

    let testing = function
      | Now(msg)  -> Printf.sprintf "now:%s"  (shutdown msg)
      | Next(msg) -> Printf.sprintf "next:%s" (shutdown msg)
  end
}
 
