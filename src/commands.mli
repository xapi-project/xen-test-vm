
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
type message =
  | Now           of action
  | OnShutdown    of ack * action


module Scan : sig
  val shutdown: string -> action   (* control/shutdown *)
  val message:  string -> message  (* control/testing - in JSON *)
end


