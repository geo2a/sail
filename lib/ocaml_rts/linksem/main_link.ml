(*Generated by Lem from main_link.lem.*)
open Lem_basic_classes
open Lem_function
open Lem_string
open Lem_tuple
open Lem_bool
open Lem_list
open Lem_sorting
(*import Map*)
(*import Set*)
(*import Set_extra*)
open Lem_num
open Lem_maybe
open Lem_assert_extra

open Byte_sequence
open Default_printing
open Error
open Missing_pervasives
open Show
open Endianness

open Elf_header
open Elf_file
open Elf_interpreted_section
open Elf_interpreted_segment
open Elf_section_header_table
open Elf_program_header_table
open Elf_types_native_uint
open Elf_relocation
open String_table

open Abi_amd64_elf_header
open Abi_amd64_serialisation
open Abis
(*import Gnu_ext_abi*)

open Command_line
open Input_list
open Linkable_list

open Memory_image
open Elf_memory_image
open Elf_memory_image_of_elf64_file
open Elf64_file_of_elf_memory_image

open Linker_script
open Link

(*val images_consistent : elf_memory_image -> elf_memory_image -> bool*)
let images_consistent img1 img2:bool= 
    (* img1.by_tag = img2.by_tag *) true

(*val correctly_linked : abi any_abi_feature -> linkable_list -> list string -> set link_option -> elf64_file -> maybe elf_memory_image*)
let correctly_linked a linkables names options eout:((any_abi_feature)annotated_memory_image)option=    
  (let output_image = (elf_memory_image_of_elf64_file a "(output file)" eout)
    in
    let (fresh, alloc_map, script1) = (default_linker_control_script(Nat_big_num.of_int 0) (Pmap.empty Nat_big_num.compare) a 
        (* user_text_segment_start *) ((match Command_line.find_option_matching_tag (TextSegmentStart(Nat_big_num.of_int 0)) options with Some(TextSegmentStart(addr)) -> Some addr | _ -> None ))
        (* user_data_segment_start *) None
        (* user_rodata_segment_start *) ((match Command_line.find_option_matching_tag (RodataSegmentStart(Nat_big_num.of_int 0)) options with Some(RodataSegmentStart(addr)) -> Some addr | _ -> None ))
        (* elf_headers_size *)
            ( Nat_big_num.add(Nat_big_num.of_int 
                (* ELF header size *)64) (Nat_big_num.mul a.max_phnum(Nat_big_num.of_int 56)) (* size of one phdr *)
            ))
    in
    let linked_image = (link alloc_map script1 a options linkables)
    in
    if images_consistent output_image linked_image then Some linked_image else None)

(* We need to elaborate the command line to handle objects, archives 
 * and archive groups appropriately. 
 * We could imagine a relation between objects such that 
 * (o1, o2) is in the relation
 * iff definitions in o1 might be used to satisfy references in o2. ("o1 supplies o2")
 * If o1 is a .o, all other .o files are searched.
 * If o1 comes from an archive and is not in a group, it only supplies *preceding* objects (whether from an archive or a .o).
 * If o1 comes from an archive in a group, it supplies preceding objects and any objects from the same group.
 * 
 * That doesn't capture the ordering, though: 
 * for each object, there's an ordered list of other objects 
 * in which to search for the *first* definition. *)

let ( _:unit) =  
(let res =    
(let (input_units1, link_options1) = (command_line ())
    in
    let items_and_options = (elaborate_input input_units1)
    in
    let (input_items, item_options) = (List.split items_and_options)
    in
    let _ = (prerr_endline ("Got " ^ ((Pervasives.string_of_int (List.length input_items)) ^ (" input items: {"
        ^ ((List.fold_left (^) "" (Lem_list.map (fun item -> (string_of_triple 
  instance_Show_Show_string_dict instance_Show_Show_Input_list_input_blob_dict (instance_Show_Show_tup2_dict instance_Show_Show_Command_line_input_unit_dict
   (instance_Show_Show_list_dict
      instance_Show_Show_Input_list_origin_coord_dict)) item) ^ ",\n") input_items)) ^ "}")))))
    in
    let output_filename = ((match Command_line.find_option_matching_tag (Command_line.OutputFilename("")) link_options1 with
        None -> "impossible: no output file specified, despite default value of `a.out'"
        | Some (Command_line.OutputFilename(s)) -> s
        | _ -> "impossible: bad output filename option returned"
    ))
    in
    Byte_sequence.acquire output_filename >>= (fun out ->
    let _ = (prerr_endline ("Successfully opened output file")) in
    Elf_file.read_elf64_file out >>= (fun eout ->
    let _ = (prerr_endline ("Output file seems to be an ELF file")) in
    let guessed_abi = (list_find_opt (fun a -> a.is_valid_elf_header eout.elf64_file_header) all_abis)
    in
    let a = ((match guessed_abi with
      Some a -> if (* get_elf64_osabi eout.elf64_file_header = elf_osabi_gnu *) true
                    (* The GNU linker does not set the ABI to "GNU", but happily uses GNU extensions.
                     * FIXME: delegate to a personality function here
                     *)
                    then let _ = (prerr_endline "Using GNU-extended ABI") in Gnu_ext_abi.gnu_extend (Abis.tls_extend a) 
                    else (Abis.tls_extend a)
      | None -> failwith "output file does not conform to any known ABI"
    ))
    in
    let make_linkable = (fun (it, opts) -> linkable_item_of_input_item_and_options a it opts)
    in
    let linkable_items_and_options = (Lem_list.map make_linkable items_and_options)
    in
    let names = (Lem_list.map  
  (string_of_triple instance_Show_Show_string_dict
     instance_Show_Show_Input_list_input_blob_dict
     (instance_Show_Show_tup2_dict
        instance_Show_Show_Command_line_input_unit_dict
        (instance_Show_Show_list_dict
           instance_Show_Show_Input_list_origin_coord_dict))) input_items)
    in 
    let maybe_symbolic_image = (correctly_linked a linkable_items_and_options names link_options1 eout)
    in
    let v = ((match maybe_symbolic_image with 
        None -> false 
        | Some img2 ->
            (* generate some output, using the symbolic image we just got *)
            let our_output_filename = (output_filename ^ ".test-out")
            in
            let f = (elf64_file_of_elf_memory_image a (fun x -> x) our_output_filename img2)
            in
            (match 
            bytes_of_elf64_file f >>= (fun bytes -> 
                Byte_sequence.serialise our_output_filename bytes)
            with
                Success _ -> true
                | Fail s -> let _ = (print_endline ("error writing output: " ^ s)) in true
            )
    ))
    in
    return (string_of_bool v))))
  in
    (match res with
      | Fail err  -> prerr_endline ("[!]: " ^ err)
      | Success e -> prerr_endline e
    ))


