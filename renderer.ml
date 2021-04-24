open Curses

let check_err err =
  if err = true then () else raise Command.Program_terminate

let init_colors () =
  check_err (Curses.start_color ());
  check_err (Curses.init_pair 1 Curses.Color.red Curses.Color.black);
  check_err (Curses.init_pair 2 Curses.Color.green Curses.Color.black);
  check_err (Curses.init_pair 3 Curses.Color.yellow Curses.Color.black);
  check_err (Curses.init_pair 4 Curses.Color.blue Curses.Color.black);
  check_err (Curses.init_pair 5 Curses.Color.magenta Curses.Color.black);
  check_err (Curses.init_pair 6 Curses.Color.cyan Curses.Color.black);
  check_err (Curses.init_pair 7 Curses.Color.white Curses.Color.black);
  check_err (Curses.init_pair 8 Curses.Color.black Curses.Color.red);
  check_err (Curses.init_pair 9 Curses.Color.black Curses.Color.green);
  check_err (Curses.init_pair 10 Curses.Color.black Curses.Color.yellow);
  check_err (Curses.init_pair 11 Curses.Color.black Curses.Color.blue);
  check_err
    (Curses.init_pair 12 Curses.Color.black Curses.Color.magenta);
  check_err (Curses.init_pair 13 Curses.Color.black Curses.Color.cyan);
  check_err (Curses.init_pair 14 Curses.Color.black Curses.Color.white)

let get_color color =
  let colors =
    [
      "red";
      "green";
      "yellow";
      "blue";
      "magenta";
      "cyan";
      "white";
      "red_back";
      "green_back";
      "yellow_back";
      "blue_back";
      "magenta_back";
      "cyan_back";
      "white_back";
    ]
  in
  let rec r_color color n =
    if List.nth colors n = color then n + 1 else r_color color (n + 1)
  in
  r_color color 0

let enable_color color =
  Curses.attron (Curses.A.color_pair (get_color color))

let disable_color color =
  Curses.attroff (Curses.A.color_pair (get_color color))

let init () : Curses.window =
  let win = Curses.initscr () in
  init_colors ();
  check_err (Curses.cbreak ());
  check_err (Curses.noecho ());
  check_err (Curses.curs_set 0);
  check_err (Curses.keypad win true);
  Curses.clear ();
  win

let cleanup () =
  check_err (Curses.curs_set 1);
  check_err (Curses.echo ());
  check_err (Curses.nocbreak ());
  Curses.endwin ()

let cursor_nextline win =
  let yx = Curses.getyx win in
  let new_yx = (fst yx + 1, 0) in
  check_err (Curses.wmove win (fst new_yx) (snd new_yx))

let cursor_prevline win =
  let yx = Curses.getyx win in
  let new_yx = (fst yx - 1, 0) in
  check_err (Curses.wmove win (fst new_yx) (snd new_yx))

let cursor_reset win = check_err (Curses.wmove win 0 0)

let rec render_user_line win (line : State.printable) =
  enable_color "cyan_back";
  let fst_char =
    if String.length line.text = 0 then " "
    else String.sub line.text 0 1
  in
  let rest =
    if String.length line.text <= 1 then ""
    else String.sub line.text 1 (String.length line.text - 1)
  in
  check_err (Curses.waddstr win fst_char);
  disable_color "cyan_back";
  enable_color line.color;
  check_err (Curses.waddstr win rest);
  disable_color line.color;
  cursor_nextline win

let render_line win curs render_curs (line : State.printable) =
  let yx = Curses.getyx win in
  if fst yx = curs && render_curs then render_user_line win line
  else (
    enable_color line.color;
    check_err (Curses.waddstr win line.text);
    disable_color line.color;
    cursor_nextline win)

let render_lines win lines curs render_curs =
  List.iter (render_line win curs render_curs) lines

let rec parse_string win str =
  check_err (Curses.echo ());
  enable_color "cyan_back";
  check_err (Curses.waddstr win " ");
  disable_color "cyan_back";
  let yx = Curses.getyx win in
  check_err (Curses.wmove win (fst yx) (snd yx - 1));
  try
    let key = Curses.wgetch win in
    if key = 10 then str
    else if key = Curses.Key.backspace then (
      let new_str =
        if str = "" then str
        else String.sub str 0 (String.length str - 1)
      in
      Curses.clrtoeol ();
      parse_string win new_str)
    else parse_string win (str ^ String.make 1 (char_of_int key))
  with _ -> parse_string win str

let commit_msg_prompt : State.printable =
  { text = "Enter your commit message: "; color = "green" }

let commit_header : State.printable =
  { text = "Commit results: "; color = "green" }

let blank_line : State.printable = { text = " "; color = "white" }

let render_commit_done state win msg =
  render_line win (State.get_curs state) false commit_header;
  render_line win (State.get_curs state) false
    { text = msg; color = "white" }

let render state win =
  Curses.werase win;
  let lines = State.printable_of_state state in
  cursor_reset win;
  let render_curs = State.get_mode state <> CommitMode in
  render_lines win lines (State.get_curs state) render_curs;
  render_line win (State.get_curs state) false blank_line;
  match State.get_mode state with
  | CommitDone msg -> render_commit_done state win msg
  | _ ->
      ();
      check_err (Curses.wrefresh win)

let render_commit_mode state win =
  render state win;
  render_line win (State.get_curs state) false commit_msg_prompt;
  let msg = parse_string win "" in
  check_err (Curses.noecho ());
  render (State.update_mode state Command.Nop) win;
  msg