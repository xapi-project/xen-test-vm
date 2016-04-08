module Main: functor (C : V1_LWT.CONSOLE) -> sig
  val start : C.t -> bool Lwt.t       (* doesn't return *)
end
