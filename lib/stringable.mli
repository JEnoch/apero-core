module type S = sig
  type t 
  val to_string : t -> string
  val of_string : string -> t 
end 
