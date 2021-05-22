(** Parsing of user commands. *)

(** The type [file_name] represents the file name that can be part of a
    user command. *)
type file_name = string

(** The type [commit_msg] represents the commit message that can be part
    of a user command. *)
type commit_msg = string

(** The type [branch_name] represents the branch name that can be part
    of a user command. *)
type branch_name = string

(** The type that represents a key. The interpretation of a key is
    equivalent to the definition's in [Curses.Key]. [Curses.Key] does
    not expose a type key, and is instead implemented using an integer
    and some functions that map the name of a key to an integer. *)
type key = int

(** The type [t] represents a git command that is decomposed into a verb
    and possibly a file_name, commit_msg, or branch_name. *)
type t =
  | Stage
  | Unstage
  | Quit
  | NavUp of bool
  | NavDown of bool
  | Commit of string
  | DiffMenu
  | DiffFile
  | DiffTracked
  | DiffStaged
  | DiffAll
  | PullMenu
  | PullRemote
  | PullOriginMaster
  | PullElsewhere of string
  | PushMenu
  | PushRemote
  | PushOriginMaster
  | BranchMenu
  | CheckoutBranchPrompt
  | CreateBranchPrompt
  | DeleteBranchPrompt
  | CheckoutBranch of string
  | CreateBranch of string
  | DeleteBranch of string
  | PushElsewhere of string
  | NormalTutorial
  | DiffTutorial
  | PullTutorial
  | PushTutorial
  | BranchTutorial
  | BackNormal
  | BackDiff
  | BackPull
  | BackPush
  | BackBranch
  | Clear
  | Nop

(** Raised when program should be terminated *)
exception Program_terminate

(** [parse_key key] parses a user's keystroke input into a [cmd]. If a
    keystroke is not suported, it returns [Nop]. Examples: Key: s ->
    Stage Key: u -> Unstage Key: k -> NavUp Key: Up -> NavUp Key: j ->
    NavDown Key: Down -> NavDown Key: q -> Quit test*)
val parse_key : key -> t

(** [parse_key_diff_mode key] has the same function as [parse_key key]
    but works when diff menu has been activated *)
val parse_key_diff_mode : key -> t

(** [parse_key_pull_mode key] has the same function as [parse_key key]
    but works when pull menu has been activated *)
val parse_key_pull_mode : key -> t

(** [parse_key_push_mode key] has the same function as [parse_key key]
    but works when push menu has been activated *)
val parse_key_push_mode : key -> t

(** [parse_key_branch_mode key] has the same function as [parse_key key]
    but works when branch menu has been activated *)
val parse_key_branch_mode : key -> t

(** [parse_key_normal_tutorial key] has the same function as
    [parse_key key] but works when normal tutorial has been activated *)
val parse_key_normal_tutorial : key -> t

(** [parse_key_diff_tutorial key] has the same function as
    [parse_key key] but works when normal tutorial has been activated *)
val parse_key_diff_tutorial : key -> t

(** [parse_key_pull_tutorial key] has the same function as
    [parse_key key] but works when normal tutorial has been activated *)
val parse_key_pull_tutorial : key -> t

(** [parse_key_push_tutorial key] has the same function as
    [parse_key key] but works when normal tutorial has been activated *)
val parse_key_push_tutorial : key -> t

(** [parse_key_branch_tutorial key] has the same function as
    [parse_key key] but works when normal tutorial has been activated *)
val parse_key_branch_tutorial : key -> t

(** [string_of_cmd cmd] is the lowercase string representation of [cmd] *)
val string_of_cmd : t -> string
