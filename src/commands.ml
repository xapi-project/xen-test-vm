(* vim: set et sw=2 ts=2 *)

module Y  = Yojson.Basic
module U  = Yojson.Basic.Util

exception Error of string
let error fmt = Printf.ksprintf (fun msg -> raise (Error msg)) fmt

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

let action = function
  | "suspend"   -> Suspend 
  | "poweroff"  -> PowerOff 
  | "reboot"    -> Reboot 
  | "halt"      -> Halt 
  | "crash"     -> Crash 
  | "ignore"    -> Ignore 
  | x           -> error "unknown action: %s" x
 
let do_when ack action = function
  | "now"       -> Now(action)
  | "onshutdown"-> OnShutdown(ack, action)
  | x           -> error "unknown when: %s" x

let ack = function
  | "ok"        -> AckOK
  | "none"      -> AckNone
  | "delete"    -> AckDelete
  | x           -> AckWrite(x)

let from_string str =
  try
    let json    = Y.from_string str in
    let ack'    = json |> U.member "ack"     |> U.to_string |> ack in
    let action' = json |> U.member "action"  |> U.to_string |> action in
      json 
      |> U.member "when" 
      |> U.to_string
      |> do_when ack' action'
  with
    Yojson.Json_error msg -> error "bad json: %s" msg


