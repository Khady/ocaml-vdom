open Js_browser

let editor =
  Ojs.get_prop_ascii (Ojs.get_prop_ascii Ojs.global "window") "editor"

let get_value () =
  Ojs.string_of_js (Ojs.call editor "getValue" [||])

let set_value s =
  ignore (Ojs.call editor "setValue" [|Ojs.string_to_js s|] : Ojs.t)

let () =
  match Document.get_element_by_id document "examples" with
  | None -> ()
  | Some examples ->
      let option (name, _) =
        let elt = Document.create_element document "option" in
        Element.append_child elt (Document.create_text_node document name);
        elt
      in
      let onchange evt =
        let target = Event.target evt in
        let idx = Ojs.int_of_js (Ojs.get_prop_ascii target "selectedIndex") in
        set_value (snd Examples.v.(idx))
      in
      Array.iter (fun v -> Element.append_child examples (option v)) Examples.v;
      Element.add_event_listener examples Change onchange true;
      set_value (snd Examples.v.(0))

let run _ =
  match Document.get_element_by_id document "right" with
  | None -> ()
  | Some right ->
      Element.remove_all_children right;
      let iframe = Document.create_element document "iframe" in
      IFrame.set_src iframe "runner.html";
      Element.append_child right iframe;
      begin match IFrame.content_window iframe with
      | None -> ()
      | Some window ->
          Element.add_event_listener iframe Load (fun _ ->
              Window.post_message window (Ojs.string_to_js (get_value ())) "*";
            ) false;
      end

let () =
  Window.add_event_listener window Message (fun event ->
      let lnum, cnum1, cnum2 =
        match Ojs.list_of_js Ojs.int_of_js (Event.data event) with
        | [lnum; cnum1; cnum2] -> lnum, cnum1, cnum2
        | _ -> assert false
      in
      let pos line ch =
        let line = line - 1 in (* CM lines are zero-based *)
        Ojs.obj [|"line", Ojs.int_to_js line; "ch", Ojs.int_to_js ch|]
      in
      ignore (Ojs.call editor "setSelection" [|pos lnum cnum1; pos lnum cnum2|] : Ojs.t)
    ) true

let () =
  match Document.get_element_by_id document "run" with
  | None -> ()
  | Some button -> Element.add_event_listener button Click run true

let help _ =
  match Document.get_element_by_id document "examples" with
  | None -> ()
  | Some examples ->
      let url =
        Printf.sprintf "https://github.com/LexiFi/ocaml-vdom/blob/nojebar_7guis/examples/%s/README.md"
          (fst Examples.v.(Element.selected_index examples))
      in
      ignore (Window.open_ window ~url ())

let () =
  match Document.get_element_by_id document "help" with
  | None -> ()
  | Some button -> Element.add_event_listener button Click help true
