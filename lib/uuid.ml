open Iobuf
open Acommon

module Uuid = struct
  type t = { uuid:Uuidm.t; alias:string option }

  let state = Random.State.make_self_init ()

  let make () = { uuid=Uuidm.v4_gen state (); alias=None}

  (* Note: ns_apero namespace is inspired by those specified in https://tools.ietf.org/html/rfc4122#appendix-C *)
  let ns_apero = Uuidm.of_string "6ba7b842-9dad-11d1-80b4-00c04fd430c8" |> Acommon.Option.get


  let make_from_alias alias = { uuid=Uuidm.v5 ns_apero alias; alias=Some alias}

  let alias t = t.alias

  let compare t t' = Uuidm.compare t.uuid t'.uuid
  let equal t t' = Uuidm.equal t.uuid t'.uuid

  let of_bytes ?pos s =
    let open Acommon.Option.Infix in
    Uuidm.of_bytes ?pos s >== fun uuid -> { uuid; alias=None }
  let to_bytes t = Uuidm.to_bytes t.uuid

  let of_string ?pos s =
    let open Acommon.Option.Infix in
    Uuidm.of_string ?pos s >== fun uuid -> { uuid; alias=None }
  let to_string ?upper t = Uuidm.to_string ?upper t.uuid

  let nb_bytes = Uuidm.to_bytes ns_apero |> Lwt_bytes.of_string |> Lwt_bytes.length

  let encode t buf =
    let bytes = Lwt_bytes.of_string @@ to_bytes t in
    IOBuf.blit_from_bytes bytes 0 nb_bytes buf

  let decode buf =
    let open Result.Infix in
    IOBuf.blit_to_bytes nb_bytes buf
    >>= fun (bytes, buf) -> match of_bytes @@ Lwt_bytes.to_string bytes with
      | Some uuid -> Result.ok (uuid, buf)
      | None -> Result.fail @@ `InvalidFormat (`Msg ("Failed to decode Uuid"))

end 
