let contains_substring s1 s2 =
  let re = Str.regexp_string s2 in
  try
    ignore (Str.search_forward re s1 0);
    true
  with Not_found -> false

let search_in_nix_store search_term =
  let rawEntries = Sys.readdir "/nix/store/" in
  let entries = Array.to_list rawEntries in
  let filtered_entries =
    List.filter (fun name -> contains_substring name search_term) entries
  in
  List.iter (fun x -> Printf.printf "%s\n" x) filtered_entries

let print_usage exit_code =
  Printf.printf
    "Get /nix/store paths that match the given argument.\n\n\
     Usage:\n\
    \ pstore <search-term>\n\n\
     Flags:\n\
    \  -h, --help\tHelp for this program\n";
  exit exit_code

let main () =
  let code =
    if Array.length Sys.argv == 1 then 1
    else if List.mem Sys.argv.(1) [ "--help"; "-h" ] then 0
    else -1
  in
  match code with
  | -1 -> search_in_nix_store Sys.argv.(1)
  | _ -> print_usage code

let () = main ()
