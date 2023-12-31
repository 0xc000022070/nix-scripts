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

let main () =
  let term =
    if Array.length Sys.argv == 1 then "<><><><><><><><>" else Sys.argv.(1)
  in
  search_in_nix_store term

let () = main ()
