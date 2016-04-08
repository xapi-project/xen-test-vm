
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

val shutdown: string -> shutdown
val testing:  string -> testing

