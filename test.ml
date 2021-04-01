open OUnit2
open Plumbing
open Porcelain

(** Some Helper Methods *)

(** [rmr p] recursibley removes the direcory [p] and everything in it *)
let rec rmr path =
  match Sys.is_directory path with
  | true ->
      let files = Sys.readdir path in
      Array.iter (fun file -> rmr (Filename.concat path file)) files;
      Unix.rmdir path
  | false -> Sys.remove path

let init_repo name = Plumbing.init [| name |]

(** [plumbing_test n a ch cl] constructs an OUnit test named [n] that
    asserts [ch] to check side effects and then calls [cl] which cleans
    up the side effects *)
let plumbing_test_side_effect
    (name : string)
    (f : string array -> 'a)
    (args : string array)
    (check_side_effect : unit -> bool)
    (clean_side_effect : unit -> unit) : test =
  name >:: fun _ ->
  f args;
  try
    let res =
      assert_bool "side effect did not occur" (check_side_effect ())
    in
    clean_side_effect ();
    res
  with Failure f ->
    clean_side_effect ();
    raise (Failure f)

(** [plumbing_test n a ch cl] constructs an OUnit test named [n] that
    asserts [Plumbing.get_out (f args)] is equal to [res] *)
let plumbing_test
    (name : string)
    (f : string array -> 'a)
    (args : string array)
    (res : string list) : test =
  name >:: fun _ -> assert_equal res (Plumbing.get_out (f args))

(** [check_err_raises_test n err] constructs an OUnit test named [n]
    that asserts [Command.check_err] raises [Command.Program_terminate] *)
let check_err_raises_test (name : string) (err : bool) : test =
  name >:: fun _ ->
  assert_raises Command.Program_terminate (fun () ->
      Command.check_err err)

(** [parse_key_test k exp] constructs an OUnit test named [n] that
    asserts [Command.parse_key k] is exp*)
let parse_key_test (name : string) (key : int) (exp : Command.cmd) :
    test =
  name >:: fun _ -> assert_equal exp (Command.parse_key key)

(** [parse_key_raises_test n key] constructs an OUnit test named [n]
    that asserts [Command.parse_key] raises [Command.Invalid_cmd] *)
let parse_key_raises_test (name : string) (key : int) : test =
  name >:: fun _ ->
  assert_raises (Command.Invalid_cmd "Invalid command") (fun () ->
      Command.parse_key key)

(** [check_err_test err] constructs an OUnit test named [n] that asserts
    [Command.check_err] is unit *)
let check_err_test (name : string) (err : bool) : test =
  name >:: fun _ -> assert_equal (Command.check_err err) ()

(** Tests for [Plumbing.init] *)
let init_tests =
  [
    plumbing_test_side_effect "init tmp" Plumbing.init [| "tmp" |]
      (fun () -> Sys.file_exists "tmp/.git")
      (fun () -> rmr "tmp");
  ]

(** Tests for [Plumbing.hash_object] *)
let hash_object_tests = []

(** Tests for [Plumbing.cat_file] *)
let cat_file_tests = []

(** Tests for [Plumbing.update_index] *)
let update_index_tests = []

(** Tests for [Plumbing.write_tree] *)
let write_tree_tests = []

(** Tests for [Plumbing.read_tree] *)
let read_tree_tests = []

(** Tests for [Plumbing.commit_tree] *)
let commit_tree_tests = []

(** Tests for [Plumbing.log] *)
let log_tests =
  [
    plumbing_test "log empty" Plumbing.log [| "tmp" |]
      [
        "fatal: your current branch 'master' does not have any commits \
         yet";
      ];
  ]

(** Tests for [Plumbing.add] *)
let add_tests =
  [
    plumbing_test "nothing specified" Plumbing.add [||] [ "" ];
    plumbing_test "add one file" Plumbing.add [| "test1.txt" |] [ "" ];
    plumbing_test "add multiple" Plumbing.add
      [| "test1.txt"; "test2.txt" |]
      [ "" ];
  ]

(** Tests for [Plumbing.commit] *)
let commit_tests =
  [
    plumbing_test "nothing to commit" Plumbing.commit [||] [ "" ];
    plumbing_test "commit staged no message" Plumbing.commit [||] [ "" ];
    plumbing_test "commit staged with message" Plumbing.commit
      [| "-m"; "message" |] [ "" ];
  ]

(** Tests for [Plumbing.show] *)
let show_tests =
  [
    plumbing_test "show empty" Plumbing.show [| "tmp" |] [ "" ];
    plumbing_test "one comit" Plumbing.show [| "tmp" |] [ "" ];
  ]

(** Tests for [Plumbing.diff] *)
let diff_tests =
  [
    plumbing_test "no diff" Plumbing.diff [||] [ "" ];
    plumbing_test "one file has one new line" Plumbing.diff [||] [ "" ];
    plumbing_test "diff a specific file" Plumbing.diff [| "test.txt" |]
      [ "" ];
  ]

(** Tests for [Plumbing.status] *)
let status_tests =
  [
    plumbing_test "no commits" Plumbing.status [||] [ "" ];
    plumbing_test "nothing to commit" Plumbing.status [||] [ "" ];
    plumbing_test "untracked files" Plumbing.status [||] [ "" ];
    plumbing_test "check file specifically" Plumbing.status
      [| "test.txt" |] [ "" ];
  ]

(** 

Porcelain Helper Functions

let add_to_status_t_test
    (name : string)
    (status : status_t)
    (lines : string)
    (exp_output : status_t) : test =
  name >:: fun _ ->
  assert_equal exp_output (Porcelain.add_to_status_t status lines)

let init_test (name : string) (dir : string option) (exp_output : unit)
    : test =
  name >:: fun _ -> assert_equal exp_output (Porcelain.init dir)

let hash_object_test
    (name : string)
    (file : string)
    (exp_output : string) : test =
  name >:: fun _ -> assert_equal exp_output Porcelain.hash_object

let cat_file_test
    (name : string)
    (hash : object_id)
    (exp_output : object_content) : test =
  name >:: fun _ -> assert_equal exp_output (Porcelain.cat_file hash)

let cat_file_type_test
    (name : string)
    (hash : object_id)
    (exp_output : object_type) : test =
  name >:: fun _ ->
  assert_equal exp_output (Porcelain.cat_file_type hash)

let update_index_test
    (name : string)
    (hash : object_id)
    (filename : string)
    (exp_output : unit) : test =
  name >:: fun _ ->
  assert_equal exp_output (Porcelain.update_index hash filename)

let write_tree_test
    (name : string)
    (nothing : unit)
    (exp_output : object_id) : test =
  name >:: fun _ ->
  assert_equal exp_output (Porcelain.write_tree nothing)

let read_tree_test
    (name : string)
    (hash : object_id)
    (exp_output : unit) : test =
  name >:: fun _ -> assert_equal exp_output (Porcelain.read_tree hash)

let read_tree_prefix_test
    (name : string)
    (ob_id : object_id)
    (prefix : string)
    (exp_output : unit) : test =
  name >:: fun _ ->
  assert_equal exp_output (Porcelain.read_tree_prefix ob_id prefix)

let commit_tree_test
    (name : string)
    (hash : object_id)
    (msg : string)
    (exp_output : object_id) : test =
  name >:: fun _ ->
  assert_equal exp_output (Porcelain.commit_tree hash msg)

let log_test
    (name : string)
    (ob_id : object_id option)
    (exp_output : commit_object list) : test =
  name >:: fun _ -> assert_equal exp_output (Porcelain.log ob_id)

let add_test
    (name : string)
    (filenames : string list)
    (exp_output : unit) : test =
  name >:: fun _ -> assert_equal exp_output (Porcelain.add filenames)

let commit_test (name : string) (msg : string) (exp_output : unit) :
    test =
  name >:: fun _ -> assert_equal exp_output (Porcelain.commit msg)

let show_test (name : string) (nothing : unit) (exp_output : unit) :
    test =
  name >:: fun _ -> assert_equal exp_output (Porcelain.show nothing)

let diff_test (name : string) (nothing : unit) (exp_output : unit) :
    test =
  name >:: fun _ -> assert_equal exp_output (Porcelain.diff nothing)

*)

(** Tests for [Plumbing ] module *)
let plumbing_tests = init_tests
(*@ hash_object_tests @ cat_file_tests @ update_index_tests @
  write_tree_tests @ read_tree_tests @ commit_tree_tests*)
(*@ log_tests @ add_tests @ commit_tests @ show_tests @ diff_tests @
  status_tests *)

(**

let get_untracked_test
    (name : string)
    (func : string -> unit)
    (clean_up : string -> unit)
    (stat : status_t)
    (exp_output : string list) : test =
  name >:: fun _ ->
  assert_equal exp_output (Porcelain.get_untracked stat)

let get_tracked_test
    (name : string)
    (func : string -> unit)
    (clean_up : string -> unit)
    (stat : status_t)
    (exp_output : string list) : test =
  name >:: fun _ -> assert_equal exp_output (Porcelain.get_tracked stat)

let get_staged_test
    (name : string)
    (func : string -> unit)
    (clean_up : string -> unit)
    (stat : status_t)
    (exp_output : string list) : test =
  name >:: fun _ -> assert_equal exp_output (Porcelain.get_staged stat)


  let get_tracked_and_staged_test
    (name : string)
    (func : string -> unit)
    (clean_up : string -> unit)
    (stat : status_t)
    (exp_output : string list) : test =
  name >:: fun _ -> assert_equal exp_output (Porcelain.get_staged stat) (* append get_tracked *)

let create_file filename = failwith "todo"

let setup_untracked_test filename =
  init_repo "test";
  create_file filename;


let setup_tracked_test filename =
  init_repo "test";
  create_file filename;
  Plumbing.add [| filename |];
  Plumbing.commit [|"-m"; "adding file for tracked test"|]
  (* modify file somehow to get " M" XY value *)

let setup_staged_test filename = 
  init_repo "test";
  create_file filename;
  Plumbing.add [| filename |]

let setup_tracked_and_staged_test filename =
  init_repo "test";
  create_file filename;
  Plumbing.add [| filename |]
  (* modify file *)



let status_tests = 
  [
    get_untracked_test "One untracked file" (setup_untracked_test 
    ("untracked.txt") 
    (rmr "test") Porcelain.status ["untracked.txt"]

    get_tracked_test "One tracked file" (setup_tracked_test "tracked.txt") 
    (rmr "test") Porcelain.status ["tracked.txt"]

    get_staged_test "One staged file" (setup_staged_test "staged.txt")
    (rmr "test") Porcelain.status ["staged.txt"]

  ]
*)
  
(** Tests for [Porcelain] module *)
let porcelain_tests = []
  (** status_tests *)

let check_err_tests =
  [
    check_err_raises_test "false (an error occured)" false;
    check_err_test "true (an error did not occur)" true;
  ]

let parse_key_tests =
  [
    parse_key_test "s is status" (int_of_char 's') Command.Status;
    parse_key_test "q is quit" (int_of_char 'q') Command.Quit;
    parse_key_raises_test "unsupported raises Invalid_cmd" 9999;
  ]

(** Tests for [Command] module *)
let command_tests = check_err_tests @ parse_key_tests
(*@ exec_tests*)

let suite =
  "test suite for ogit"
  >::: List.flatten
         [ plumbing_tests; command_tests (*; porcelain_tests*) ]

let _ = run_test_tt_main suite
