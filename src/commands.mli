
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


module Scan : sig
  val shutdown: string -> shutdown
  val testing:  string -> testing
end

(** module [String] provides functions to turn commands back into
 * strings
 *)
 module String : sig
  val shutdown: shutdown -> string
  val testing:   testing  -> string
end

