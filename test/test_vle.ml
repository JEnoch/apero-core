open Apero


let check_if b ?arg line =
  let test_name =
    match arg with
    | None -> Printf.sprintf "test line %d" line
    | Some(s) -> Printf.sprintf "test line %d with %s" line s
  in
    Alcotest.(check bool) test_name b


let test_no_size i expected_buf_size =
  let buf = IOBuf.create 16 in
  match encode_vle i buf with
  | Ok buf ->
    begin
      let buf = IOBuf.flip buf in
      let _ = Logs_lwt.debug (fun m -> m "encoding %LX result: %s" i (IOBuf.hexdump buf)) in
      if IOBuf.limit buf = expected_buf_size then
        match decode_vle buf with 
        | Ok (j, _) ->
          let _ = Logs_lwt.debug (fun m -> m "encoding %LX decoding: %LX" i j) in
          i = j
        | Error e ->
          let _ = Logs_lwt.err (fun m -> m "Error decoding VLE %LX : %s" i (Atypes.show_error e)) in
          false
      else
        let _ = Logs_lwt.debug (fun m -> m "encoding %LX resulting buffer hasn't the expeted size: %d vs. %d" i (IOBuf.limit buf) expected_buf_size) in
        false
    end
  | Error e ->
    let _ = Logs_lwt.err (fun m -> m "Error encoding VLE %LX : %s" i (Atypes.show_error e)) in
    false

let test_with_size i expected_buf_size =
  let buf = IOBuf.create 16 in
  match encode_vle i ~size:expected_buf_size buf with
  | Ok buf ->
    begin
      let buf = IOBuf.flip buf in
      let _ = Logs_lwt.debug (fun m -> m "encoding %LX result: %s" i (IOBuf.hexdump buf)) in
      if IOBuf.limit buf = expected_buf_size then
        match decode_vle buf with 
        | Ok (j, _) ->
          let _ = Logs_lwt.debug (fun m -> m "encoding %LX decoding: %LX" i j) in
          i = j
        | Error e ->
          let _ = Logs_lwt.err (fun m -> m "Error decoding VLE %LX : %s" i (Atypes.show_error e)) in
          false
      else
        let _ = Logs_lwt.debug (fun m -> m "encoding %LX resulting buffer hasn't the expeted size: %d vs. %d" i (IOBuf.limit buf) expected_buf_size) in
        false
    end
  | Error e ->
    let _ = Logs_lwt.err (fun m -> m "Error encoding VLE %LX : %s" i (Atypes.show_error e)) in
    false


let test_encoding () =
  check_if true  __LINE__ @@ test_no_size 0L 1;
  check_if true  __LINE__ @@ test_no_size 1L 1;
  check_if true  __LINE__ @@ test_no_size 0x7FL 1;
  check_if true  __LINE__ @@ test_no_size 0x80L 2;
  check_if true  __LINE__ @@ test_no_size 0xFFL 2;
  check_if true  __LINE__ @@ test_no_size 0x100L 2;
  check_if true  __LINE__ @@ test_no_size 0x7FFFL 3;
  check_if true  __LINE__ @@ test_no_size 0x8000L 3;
  check_if true  __LINE__ @@ test_no_size 0x10000L 3;
  check_if true  __LINE__ @@ test_no_size Int64.max_int 9;

  check_if false  __LINE__ @@ test_no_size (-1L) 0;
  check_if false  __LINE__ @@ test_no_size Int64.min_int 0;

  check_if true  __LINE__ @@ test_with_size 0L 2;
  check_if true  __LINE__ @@ test_with_size 1L 3;
  check_if true  __LINE__ @@ test_with_size 0x7FL 4;
  check_if true  __LINE__ @@ test_with_size 0x80L 5;
  check_if true  __LINE__ @@ test_with_size 0xFFL 6;
  check_if true  __LINE__ @@ test_with_size 0x100L 4;
  check_if true  __LINE__ @@ test_with_size 0x7FFFL 5;
  check_if true  __LINE__ @@ test_with_size 0x8000L 6;
  check_if true  __LINE__ @@ test_with_size 0x10000L 7;
  check_if true  __LINE__ @@ test_with_size Int64.max_int 9;

  check_if false  __LINE__ @@ test_with_size 0L 0;
  check_if false  __LINE__ @@ test_with_size 0x80L 1;
  check_if false  __LINE__ @@ test_with_size 0x7FFFL 2;
  check_if false  __LINE__ @@ test_with_size Int64.max_int 2;

  ()

let test_yojson () = 
   check_if true  __LINE__ @@ (9L |> Vle.to_yojson |> Vle.of_yojson |> Result.get = 9L);
   check_if true  __LINE__ @@ (9L |> Vle.to_yojson |> Yojson.Safe.to_string |> Yojson.Safe.from_string |> Vle.of_yojson |> Result.get = 9L);
   check_if true  __LINE__ @@ (987654321987654321L |> Vle.to_yojson |> Vle.of_yojson |> Result.get = 987654321987654321L);
   check_if true  __LINE__ @@ (987654321987654321L |> Vle.to_yojson |> Yojson.Safe.to_string |> Yojson.Safe.from_string |> Vle.of_yojson |> Result.get = 987654321987654321L);
   check_if true  __LINE__ @@ ((`Int 12) |> Vle.of_yojson |> Result.get = 12L);
   check_if true  __LINE__ @@ ((`Intlit "987654321987654321") |> Vle.of_yojson |> Result.get = 987654321987654321L);
   check_if true  __LINE__ @@ ("987654321987654321" |> Yojson.Safe.from_string |> Vle.of_yojson |> Result.get = 987654321987654321L);
   ()

let all_tests = [
  "VLE encoding", `Quick, test_encoding;
  "VLE yojson" , `Quick, test_yojson;
]
