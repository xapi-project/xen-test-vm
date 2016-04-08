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
    | _           { raise (Error "unknown shutdown command") }

  and testing = parse
    | "now:"      { Now(shutdown lexbuf) }
    | "next:"     { Next(shutdown lexbuf) }
    | _           { raise (Error "unknown side channel command") }
 
{
  let shutdown str =  shutdown (L.from_string str) 
  let testing  str =  testing  (L.from_string str) 
}
 
