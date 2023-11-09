exception Error of string

(** actions a guest can take *)
type action =
  | Suspend
  | PowerOff
  | Reboot
  | Halt
  | Crash
  | Ignore

(** how is a control message from the host acknowledged by the guest *)
type ack =
  | AckOK               (* ack by putting empty string *)
  | AckWrite of string  (* ack by putting string *)
  | AckNone             (* don't ack *)
  | AckDelete           (* delete key /control/shutdown *)

(** message to a guest *)
type t =
  | Now           of action
  | OnShutdown    of ack * action

(** [from_string str] reads a JSON object [str] and returns a [t]
    value that represents it *)
val from_string: string -> t  (* Error *)
