module Main: functor (C : V1_LWT.CONSOLE) -> sig
  val start : C.t -> 'a Lwt.t       (* doesn't return *)
end
