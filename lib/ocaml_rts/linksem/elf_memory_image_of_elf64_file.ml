(*Generated by Lem from elf_memory_image_of_elf64_file.lem.*)
open Lem_basic_classes
open Lem_function
open Lem_string
open Lem_tuple
open Lem_bool
open Lem_list
open Lem_sorting
open Lem_map
(*import Set*)
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
open Elf_symbol_table
open Elf_types_native_uint
open Elf_relocation
open String_table

open Memory_image
open Memory_image_orderings

open Elf_memory_image

(*val section_name_is_unique : string -> elf64_file -> bool*)
let section_name_is_unique name1 f:bool=    
 ((match mapMaybe (fun sec -> 
        if name1 = sec.elf64_section_name_as_string then Some sec else None
    ) f.elf64_file_interpreted_sections
    with
        [_] -> true
        | _ -> false
    ))

(*val create_unique_name_for_section_from_index : natural -> elf64_interpreted_section -> elf64_file -> string*)
let create_unique_name_for_section_from_index idx1 s f:string=    
 (let secname1 = (s.elf64_section_name_as_string)
    in if section_name_is_unique secname1 f then secname1 else gensym secname1)

(*val create_unique_name_for_common_symbol_from_linkable_name : string -> elf64_symbol_table_entry -> string -> elf64_file -> string*)
let create_unique_name_for_common_symbol_from_linkable_name fname1 syment symname f:string=    
(  
    (* FIXME: uniqueness? I suppose file names are unique. How to avoid overlapping with 
     * section names? *)fname1 ^ ("_" ^ symname))
    
(*val get_unique_name_for_common_symbol_from_linkable_name : string -> elf64_symbol_table_entry -> string -> string*)
let get_unique_name_for_common_symbol_from_linkable_name fname1 syment symname:string=    
(  
    (* FIXME: uniqueness? I suppose file names are unique. How to avoid overlapping with 
     * section names? *)fname1 ^ ("_" ^ symname))

(*val elf_memory_image_of_elf64_file : forall 'abifeature. abi 'abifeature -> string -> elf64_file -> elf_memory_image*)
let elf_memory_image_of_elf64_file a fname1 f:(Abis.any_abi_feature)annotated_memory_image=    
(  
    (* Do we have program headers? This decides whether we choose a 
     * sectionwise or segmentwise view. *)(match f.elf64_file_program_header_table with
        [] ->   let extracted_symbols =  (extract_definitions_from_symtab_of_type sht_symtab f)
                in
                let interpreted_sections_without_null = ((match f.elf64_file_interpreted_sections with
                    [] -> failwith "impossible: empty list of interpreted sections"
                    | null_entry :: more -> more
                ))
                in
                let section_names_and_elements = (mapMaybei (fun i -> (fun isec1 -> 
                    (* In principle, we can have unnamed sections. But 
                     * don't add the dummy initial SHT entry. This is *not* in the 
                     * list of interpreted sections. *)
                    if elf64_interpreted_section_equal isec1 null_elf64_interpreted_section then
                        (if Nat_big_num.equal i(Nat_big_num.of_int 0) then None else failwith "internal error: null interpreted section not at index 0")
                    else 
                        if Nat_big_num.equal i(Nat_big_num.of_int 0) then failwith "internal error: non-null interpreted section at index 0"
                        else
                        let created_name = (create_unique_name_for_section_from_index i isec1 f)
                        in
                        (*let _ = errln ("In file " ^ fname ^ " created element name " ^ created_name ^ " for section idx " ^ (show i) ^ ", name " ^ 
                            isec.elf64_section_name_as_string)
                        in*)
                        Some (created_name, {
                        startpos = None
                      ; length1 = (Some isec1.elf64_section_size)
                      ; contents = (byte_pattern_of_byte_sequence isec1.elf64_section_body)
                    })
                )) f.elf64_file_interpreted_sections)
                in
                let common_symbols = (List.filter (fun x -> Nat_big_num.equal (Nat_big_num.of_string (Uint32.to_string (x.def_syment.elf64_st_shndx))) shn_common) extracted_symbols)
                in
                (*let _ = Missing_pervasives.errln ("Found " ^ (show (length common_symbols)) ^ " common symbols in file " ^ fname)
                in*)
                let common_symbol_names_and_elements = (mapMaybei (fun i -> (fun isym -> 
                    let symlen = (Ml_bindings.nat_big_num_of_uint64 isym.def_syment.elf64_st_size)
                    in
                    Some (get_unique_name_for_common_symbol_from_linkable_name fname1 isym.def_syment isym.def_symname, {
                        startpos = None
                      ; length1 = (Some symlen)
                      ; contents = (Missing_pervasives.replicate0 symlen None)
                    })
                )) common_symbols)
                in
                let all_names_and_elements =  (List.rev_append (List.rev section_names_and_elements) common_symbol_names_and_elements)
                in
                (* -- annotations are reloc sites, symbol defs, ELF sections/segments/headers, PLT/GOT/...
                 * Since we stripped the null SHT entry, mapMaybei would ideally index from one. We add one.  *)
                let (elf_sections : ( element_range option * elf_range_tag) list) = (mapMaybei (fun secidx_minus_one -> (
                    (fun (isec1, (secname1, _)) -> 
                        let (r :  element_range option) = (Some(secname1, (Nat_big_num.of_int 0, isec1.elf64_section_size)))
                        in
                        Some (r, FileFeature(ElfSection( Nat_big_num.add secidx_minus_one(Nat_big_num.of_int 1), isec1)))
                    )))
                    (list_combine interpreted_sections_without_null section_names_and_elements))
                in
                let (symbol_defs : ( element_range option * elf_range_tag) list) = (mapMaybe
                    (fun x -> 
                        let section_num = (Nat_big_num.of_string (Uint32.to_string x.def_syment.elf64_st_shndx))
                        in
                        let labelled_range =                            
 (if Nat_big_num.equal section_num shn_abs then
                                (* We have an annotation that doesn't apply to any range.
                                 * That's all right -- that's why the range is a maybe. *)
                                None
                            else if Nat_big_num.equal section_num shn_common then 
                                (* Each common symbol becomes its own elemenet (\approx section).
                                 * We label *that element* with a (coextensive) symbol definition. *)
                                 let element_name = (get_unique_name_for_common_symbol_from_linkable_name 
                                    fname1 x.def_syment x.def_symname)
                                 in
                                 Some(element_name, (Nat_big_num.of_int 0, Ml_bindings.nat_big_num_of_uint64 x.def_syment.elf64_st_size))
                            else 
                                let (section_name, _) = ((match Ml_bindings.list_index_big_int ( Nat_big_num.sub_nat section_num(Nat_big_num.of_int 1)) section_names_and_elements with
                                    Some x -> x
                                    | None -> failwith ("symbol " ^ (x.def_symname ^ " references nonexistent section"))
                                ))
                                in
                                Some(section_name, (Ml_bindings.nat_big_num_of_uint64 x.def_syment.elf64_st_value, Ml_bindings.nat_big_num_of_uint64 x.def_syment.elf64_st_size)))
                        in
                        Some (labelled_range, SymbolDef(x))
                    )
                    (extract_definitions_from_symtab_of_type sht_symtab f))
                in
                (* FIXME: should a common symbol be a reference too? 
                 * I prefer to think of common symbols as mergeable sections. 
                 * Under this interpretation, there's no need for a reference. 
                 * BUT the GC behaviour might be different! What happens if
                 * a common symbol is not referenced? *)
                let (symbol_refs : ( element_range option * elf_range_tag) list) = (mapMaybe
                    (fun (x : symbol_reference) -> 
                        Some (None, SymbolRef({ ref = x; maybe_reloc = None; maybe_def_bound_to = None }))
                    )
                    (extract_references_from_symtab_of_type sht_symtab f))
                in
                let (all_reloc_sites : (element_range * elf_range_tag) list) = (Lem_list.map 
                    (fun (x : symbol_reference_and_reloc_site) ->
                        let rel = ((match x.maybe_reloc with 
                            Some rel -> rel
                            | None -> failwith "impossible: reloc site has no reloc"
                        ))
                        in
                        let (section_name, _) = ((match Ml_bindings.list_index_big_int ( Nat_big_num.sub_nat rel.ref_src_scn(Nat_big_num.of_int 1)) section_names_and_elements with
                            Some y -> y
                            | None -> failwith "relocs came from nonexistent section"
                        ))
                        in
                        let (_, applyfn) = (a.reloc (get_elf64_relocation_a_type rel.ref_relent))
                        in
                        let (width, calcfn) = (applyfn (get_empty_memory_image ())(Nat_big_num.of_int 0) x)
                         (* GAH. We don't have an image. 
                            If we pass an empty memory image, will we fail? Need to make it work *)
                        in
                          (* FIXME: for copy relocs, the size depends on the *definition*.
                             AHA! a copy reloc always *has* a symbol definition locally; it just gets its *value*
                             from the shared object's definition.
                             In other words, a copy reloc always references a defined symbol, and the amount
                             copied is the minimum of that symbol's size and the overridden (copied-from .so)'s 
                             symbol's size. *)
                        let (offset : Uint64.uint64) = (rel.ref_relent.elf64_ra_offset)
                        in 
                        ((section_name, (Ml_bindings.nat_big_num_of_uint64 offset, width)), SymbolRef(x))
                    )
                    (extract_all_relocs_as_symbol_references fname1 f))
                in
                let all_reloc_pairs = (Lem_list.map (fun (el_range, r_tag) -> (Some el_range, r_tag)) all_reloc_sites)
                in
                let reloc_as_triple = (fun ((_ : bool Memory_image.range_tag), (x : bool Memory_image.range_tag)) -> ((match x with
                            SymbolRef(r) -> (match r.maybe_reloc with
                                Some rel -> (rel.ref_rel_scn, rel.ref_rel_idx, rel.ref_src_scn)
                                | None -> failwith "impossible: "
                                )
                            | _ -> failwith "unexpected tag"
                        )))
                in
                (*let _ = Missing_pervasives.errln ("Extracted " ^ (show (length all_reloc_sites)) ^ " reloc site tags from "
                    ^ "file " ^ fname ^ ": " ^ (show (List.map reloc_as_triple all_reloc_sites)))
                in*)
                let retrieved_reloc_sites = (Multimap.lookupBy0 
  (instance_Basic_classes_Ord_Memory_image_range_tag_dict
     Abis.instance_Basic_classes_Ord_Abis_any_abi_feature_dict) (instance_Basic_classes_Ord_tup2_dict
   Lem_string_extra.instance_Basic_classes_Ord_string_dict
   (instance_Basic_classes_Ord_tup2_dict
      instance_Basic_classes_Ord_Num_natural_dict
      instance_Basic_classes_Ord_Num_natural_dict)) instance_Basic_classes_SetType_var_dict (instance_Basic_classes_SetType_tup2_dict
   instance_Basic_classes_SetType_var_dict
   (instance_Basic_classes_SetType_tup2_dict
      instance_Basic_classes_SetType_Num_natural_dict
      instance_Basic_classes_SetType_Num_natural_dict))  (Memory_image_orderings.tagEquiv
    Abis.instance_Abi_classes_AbiFeatureTagEquiv_Abis_any_abi_feature_dict)
                    (SymbolRef(null_symbol_reference_and_reloc_site)) 
                    (let ((fst : (string * Memory_image.range) list), (snd : ( Abis.any_abi_feature Memory_image.range_tag) list)) = (List.split all_reloc_sites) in (Pset.from_list (pairCompare compare (pairCompare compare (pairCompare Nat_big_num.compare Nat_big_num.compare))) (list_combine snd fst))))
                in
                (*let _ = Missing_pervasives.errln ("Re-reading: retrieved " ^ (show (length retrieved_reloc_sites)) ^ " reloc site tags from "
                    ^ "file " ^ fname ^ ": " ^ (show (List.map reloc_as_triple (let (fst, snd) = unzip retrieved_reloc_sites in zip snd fst))))
                in*)
                let elf_header = ([(Some("header", (Nat_big_num.of_int 0, Nat_big_num.of_string (Uint32.to_string f.elf64_file_header.elf64_ehsize))), FileFeature(ElfHeader(f.elf64_file_header)))])
                in
                (*let _ = Missing_pervasives.errln ("ELF header contributes " ^ (show (List.length elf_header)) ^ " annotations.")
                in*)
                let all_annotations_list =  (List.rev_append (List.rev (List.rev_append (List.rev (List.rev_append (List.rev (List.rev_append (List.rev all_reloc_pairs) symbol_refs)) symbol_defs)) elf_sections)) elf_header)
                in
                let all_annotations_length = (List.length all_annotations_list)
                in
                (*let _ = Missing_pervasives.errln ("total annotations: " ^ (show all_annotations_length))
                in*)
                let all_annotations = (Pset.from_list (pairCompare (maybeCompare (pairCompare compare (pairCompare Nat_big_num.compare Nat_big_num.compare))) compare) all_annotations_list)
                in
                let (apply_content_relocations : string -> byte_pattern -> byte_pattern) = (fun (name1 : string) -> (fun content -> 
                    let this_element_reloc_sites = (List.filter (fun ((n, range1), _) -> name1 = n) all_reloc_sites)
                    in
                    let ((this_element_name_and_reloc_ranges : (string * (Nat_big_num.num * Nat_big_num.num)) list), _) = (List.split this_element_reloc_sites)
                    in
                    let (this_element_reloc_ranges : (Nat_big_num.num * Nat_big_num.num) list) = (snd (List.split this_element_name_and_reloc_ranges))
                    in
                    let (all_ranges_expanded : bool list) = (expand_unsorted_ranges this_element_reloc_ranges (Missing_pervasives.length content) [])
                    in
                    relax_byte_pattern content all_ranges_expanded
                ))
                in
                let new_elements_list = (Lem_list.map (fun (name1, element1) -> 
                    (* We can now mark the relocation sites in the section contents as "subject to change". *)
                    (
                        name1, 
                        {
                           startpos = (element1.startpos)
                         ; length1   = (element1.length1)
                         ; contents =                            
( 
                            (*let _ = errln ("Reloc-relaxing section " ^ name ^ " in file " ^ fname ^ ": before, first 20 bytes: " ^
                                (show (take 20 element.contents)))
                            in*)let relaxed = (apply_content_relocations name1 element1.contents)
                            in
                            (*let _ = errln ("After, first 20 bytes: " ^  (show (take 20 relaxed)))
                            in*)
                            relaxed)

                         }
                    )
                  ) all_names_and_elements)
                in
                            (*
                            List.foldr (fun acc -> (fun  element.contents this_element_reloc_ranges
                            let (expand_and_relax : list (maybe byte) -> (natural * natural) -> list (maybe byte)) = fun pat -> (fun r -> (
                                relax_byte_pattern pat (expand_ranges r)
                            ))
                            in*)
                 {
                      elements = (Lem_map.fromList 
  (instance_Map_MapKeyType_var_dict instance_Basic_classes_SetType_var_dict) new_elements_list)
                      (* : memory_image -- the image elements, without annotation, i.e. 
                        a map from string to (startpos, length, contents)
                        -- an element is the ELF header, PHT, SHT, section or segment
                        -- exploit the fact that section names beginning `.' are reserved, and 
                           the reserved ones don't use caps: ".PHT", ".SHT", ".HDR"
                        -- what about ambiguous section names? use ".GENSYM_<...>" perhaps 
                      *)
                    ; by_range = all_annotations
                    ; by_tag = (let (fst, snd) = (List.split all_annotations_list) in (Pset.from_list (pairCompare compare (maybeCompare (pairCompare compare (pairCompare Nat_big_num.compare Nat_big_num.compare)))) (list_combine snd fst)))
                        (*  : multimap (elf_range_tag 'symdef 'reloc 'filefeature 'abifeature) (string * range) 
                         -- annotations by *)
                  }
      | pht -> let segment_names_and_images = (mapMaybei (fun i -> (fun seg -> 
                    Some((gensym (hex_string_of_natural seg.elf64_segment_base) ^ ("_" ^ (hex_string_of_natural seg.elf64_segment_type))), 
                    {
                        startpos = (Some seg.elf64_segment_base)
                      ; length1 = (Some seg.elf64_segment_memsz)
                      ; contents = ([]) (* FIXME *)
                     })
                )) f.elf64_file_interpreted_segments)
                in
                (* let annotations = *)
                 {
                      elements = (Lem_map.fromList 
  (instance_Map_MapKeyType_var_dict instance_Basic_classes_SetType_var_dict) segment_names_and_images)  (* : memory_image -- the image elements, without annotation, i.e. 
                        a map from string to (startpos, length, contents)
                        -- an element is the ELF header, PHT, SHT, section or segment
                        -- exploit the fact that section names beginning `.' are reserved, and 
                           the reserved ones don't use caps: ".PHT", ".SHT", ".HDR"
                        -- what about ambiguous section names? use ".GENSYM_<...>" perhaps 
                      *)
                    ; by_range = (Pset.from_list (pairCompare (maybeCompare (pairCompare compare (pairCompare Nat_big_num.compare Nat_big_num.compare))) compare) [])
                        (* : map element_range (list (elf_range_tag 'symdef 'reloc 'filefeature 'abifeature))
                         -- annotations are reloc sites, symbol defs, ELF sections/segments/headers, PLT/GOT/...  *)
                    ; by_tag = (Pset.from_list (pairCompare compare (maybeCompare (pairCompare compare (pairCompare Nat_big_num.compare Nat_big_num.compare)))) [])
                        (*  : multimap (elf_range_tag 'symdef 'reloc 'filefeature 'abifeature) (string * range) 
                         -- annotations by *)
                  }

    ))

(*val elf_memory_image_header : elf_memory_image -> elf64_header*)
let elf_memory_image_header img2:elf64_header=    
  ((match unique_tag_matching 
  Abis.instance_Basic_classes_Ord_Abis_any_abi_feature_dict Abis.instance_Abi_classes_AbiFeatureTagEquiv_Abis_any_abi_feature_dict (FileFeature(ElfHeader(null_elf_header))) img2 with
        FileFeature(ElfHeader(x)) -> x
        | _ -> failwith "impossible: no header"
    ))

(*val elf_memory_image_sht : elf_memory_image -> maybe elf64_section_header_table*)
let elf_memory_image_sht img2:((elf64_section_header_table_entry)list)option=    
  ((match unique_tag_matching 
  Abis.instance_Basic_classes_Ord_Abis_any_abi_feature_dict Abis.instance_Abi_classes_AbiFeatureTagEquiv_Abis_any_abi_feature_dict (FileFeature(null_section_header_table)) img2 with
        FileFeature(ElfSectionHeaderTable(x)) -> Some x
        | _ -> None
    ))

(*val elf_memory_image_section_ranges : elf_memory_image -> (list elf_range_tag * list element_range)*)
let elf_memory_image_section_ranges img2:((Abis.any_abi_feature)range_tag)list*(element_range)list=    
(  
    (* find all element ranges labelled as ELF sections *)let tagged_ranges = (tagged_ranges_matching_tag 
  Abis.instance_Basic_classes_Ord_Abis_any_abi_feature_dict Abis.instance_Abi_classes_AbiFeatureTagEquiv_Abis_any_abi_feature_dict (FileFeature(ElfSection(Nat_big_num.of_int 0, null_elf64_interpreted_section))) img2)
    in
    let (tags, maybe_ranges) = (List.split tagged_ranges)
    in
    (tags, make_ranges_definite maybe_ranges))

(*val elf_memory_image_section_by_index : natural -> elf_memory_image -> maybe elf64_interpreted_section*)
let elf_memory_image_section_by_index idx1 img2:(elf64_interpreted_section)option=    
(  
    (* find all element ranges labelled as ELF sections *)let (allSectionTags, allSectionElementRanges) = (elf_memory_image_section_ranges img2) 
    in
    let matches = (mapMaybei (fun i -> (fun tag -> (match tag with
         FileFeature(ElfSection(itsIdx, s)) -> if Nat_big_num.equal itsIdx idx1 then Some s else None
        | _ -> failwith "impossible"
    ))) allSectionTags)
    in
    (match matches with
        [] -> None
        | [x] -> Some x
        | x -> failwith ("impossible: more than one ELF section with same index" (*"(" ^ (show idx) ^ ")"*))
    ))

(*val elf_memory_image_element_coextensive_with_section : natural -> elf_memory_image -> maybe string*)
let elf_memory_image_element_coextensive_with_section idx1 img2:(string)option=    
(  
    (* find all element ranges labelled as ELF sections *)let (allSectionTags, allSectionElementRanges) = (elf_memory_image_section_ranges img2) 
    in
    let matches = (mapMaybei (fun i -> (fun (tag, (elName, (rangeStart, rangeLen))) -> (match tag with
         FileFeature(ElfSection(itsIdx, s)) -> 
            let el_rec = ((match Pmap.lookup elName img2.elements with
                Some x -> x
                | None -> failwith "impossible: element not found"
            ))
            in
            let size_matches =                
( 
                (* HMM. This is complicated. Generally we like to ignore 
                 * isec fields that are superseded by memory_image fields, 
                 * here the element length. But we want to catch the case
                 * where there's an inconsistency, and we *might* want to allow the
                 * case where the element length is still vague (Nothing). *)let range_len_matches_sec = ( Nat_big_num.equal rangeLen s.elf64_section_size)
                in
                let sec_matches_element_len = ( (Lem.option_equal Nat_big_num.equal(Some(s.elf64_section_size)) el_rec.length1))
                in
                let range_len_matches_element_len = ( (Lem.option_equal Nat_big_num.equal(Some(rangeLen)) el_rec.length1))
                in
                (* If any pair are unequal, then warn. *)
                (*let _ = 
                if (range_len_matches_sec <> sec_matches_element_len
                 || sec_matches_element_len <> range_len_matches_element_len
                 || range_len_matches_sec <> range_len_matches_element_len)
                then errln ("Warning: section lengths do not agree: " ^ s.elf64_section_name_as_string)
                else ()
                in*)
                range_len_matches_element_len)
            in
            if Nat_big_num.equal itsIdx idx1 && (Nat_big_num.equal rangeStart(Nat_big_num.of_int 0) 
                && size_matches)
            then
            (* *)
            (* Sanity check: does the *)
            Some elName
            else None
        | _ -> failwith "impossible"
    ))) (list_combine allSectionTags allSectionElementRanges))
    in
    (match matches with
        [] -> None
        | [x] -> Some x
        | xs -> failwith ("impossible: more than one ELF section coextensive with section" ^ ((Nat_big_num.to_string idx1) ^ (", names: "
            ^ (string_of_list 
  instance_Show_Show_string_dict xs))))
    ))


(*val name_of_elf_interpreted_section : 
    elf64_interpreted_section -> elf64_interpreted_section -> maybe string*)
let name_of_elf_interpreted_section s shstrtab:(string)option=    
  ((match get_string_at s.elf64_section_name (string_table_of_byte_sequence shstrtab.elf64_section_body) with
        Success(x) -> Some x
        | Fail(e) -> None
    ))

(*val elf_memory_image_sections_with_indices : elf_memory_image -> list (elf64_interpreted_section * natural)*)
let elf_memory_image_sections_with_indices img2:(elf64_interpreted_section*Nat_big_num.num)list=    
(  
    (* We have to get all sections and their names,
     * because section names need not be unique. *)let ((all_section_tags : elf_range_tag list), (all_section_ranges : element_range list))
     = (elf_memory_image_section_ranges img2)
    in
    Lem_list.map (fun tag -> 
        (match tag with
            FileFeature(ElfSection(idx1, i)) -> (i, idx1)
            | _ -> failwith "impossible: non-section in list of sections"
        )) all_section_tags)

(*val elf_memory_image_sections : elf_memory_image -> list elf64_interpreted_section*)
let elf_memory_image_sections img2:(elf64_interpreted_section)list=    
  (let (secs, _) = (List.split (elf_memory_image_sections_with_indices img2))
    in secs)

(*val elf_memory_image_sections_with_name : string -> elf_memory_image -> list elf64_interpreted_section*)
let elf_memory_image_sections_with_name name1 img2:(elf64_interpreted_section)list=    
  (let all_interpreted_sections = (elf_memory_image_sections img2)
    in
    let maybe_shstrtab = (elf_memory_image_section_by_index (Nat_big_num.of_string (Uint32.to_string ((elf_memory_image_header img2).elf64_shstrndx))) img2)
    in
    let shstrtab = ((match maybe_shstrtab with 
        None -> failwith "no shtstrtab"
        | Some x -> x
    ))
    in
    let all_section_names = (Lem_list.map (fun i -> 
        let (stringtab : string_table) = (string_table_of_byte_sequence (shstrtab.elf64_section_body)) in
        (match get_string_at i.elf64_section_name stringtab with
            Fail _ -> None
            | Success x -> Some x
        )) all_interpreted_sections)
    in
    mapMaybe (fun (n, i) -> if (Lem.option_equal (=) (Some(name1)) n) then Some i else None) (list_combine all_section_names all_interpreted_sections))
(*
val elf_memory_image_unique_section_with_name : string -> elf_memory_image -> elf64_interpreted_section
let elf_memory_image_unique_section_with_name name img = 
    match Map.lookup name img.image with
        Just el -> match el with
            FileFeature(ElfSection(_, x)) -> x
            | _ -> failwith "impossible: section name does not name a section"
        end
        | 
        | Nothing -> failwith ("no section named '" ^ name ^ "' but asserted unique")
    end
*)

(* FIXME: delete these symbol functions, because Memory_image_orderings
 * has generic ones. *)

(*val elf_memory_image_symbol_def_ranges : elf_memory_image -> (list elf_range_tag * list (maybe element_range))*)
let elf_memory_image_symbol_def_ranges img2:((Abis.any_abi_feature)range_tag)list*((element_range)option)list=    
(  
    (* find all element ranges labelled as ELF symbols *)let (tags, maybe_ranges) = (List.split (
        tagged_ranges_matching_tag 
  Abis.instance_Basic_classes_Ord_Abis_any_abi_feature_dict Abis.instance_Abi_classes_AbiFeatureTagEquiv_Abis_any_abi_feature_dict (SymbolDef(null_symbol_definition)) img2
    ))
    in
    (* some symbols, specifically ABS symbols, needn't label a range. *)
    (tags, maybe_ranges))

(*val name_of_symbol_def : symbol_definition -> string*)
let name_of_symbol_def0 sym:string=  (sym.def_symname)

(*val elf_memory_image_defined_symbols_and_ranges : elf_memory_image -> list ((maybe element_range) * symbol_definition)*)
let elf_memory_image_defined_symbols_and_ranges img2:((element_range)option*symbol_definition)list=    
  (Memory_image_orderings.defined_symbols_and_ranges 
  Abis.instance_Basic_classes_Ord_Abis_any_abi_feature_dict Abis.instance_Abi_classes_AbiFeatureTagEquiv_Abis_any_abi_feature_dict img2)

(*val elf_memory_image_defined_symbols : elf_memory_image -> list symbol_definition*)
let elf_memory_image_defined_symbols img2:(symbol_definition)list=    
  (let ((all_symbol_tags : elf_range_tag list), (all_symbol_ranges : ( element_range option) list))
     = (elf_memory_image_symbol_def_ranges img2)
    in
    Lem_list.mapMaybe (fun tag -> 
        (match tag with
            SymbolDef(ent) -> Some ent
            | _ -> failwith "impossible: non-symbol def in list of symbol defs"
        )) all_symbol_tags)

(*
val elf_memory_image_symbols_with_name : string -> elf_memory_image -> list symbol_definition
let elf_memory_image_symbols_with_name name img = 
    let all_interpreted_sections = elf_memory_image_sections img
    in
    let maybe_shstrtab = elf_memory_image_section_by_index (natural_of_elf64_half ((elf_memory_image_header img).elf64_shstrndx)) img
    in
    let shstrtab = match maybe_shstrtab with 
        Nothing -> failwith "no shtstrtab"
        | Just x -> x
    end
    in
    let all_section_names = List.map (fun i -> 
        let (stringtab : string_table) = string_table_of_byte_sequence (shstrtab.elf64_section_body) in
        match get_string_at i.elf64_section_name stringtab with
            Fail _ -> Nothing
            | Success x -> Just x
        end) all_interpreted_sections
    in
    mapMaybe (fun (n, i) -> if Just(name) = n then Just i else Nothing) (zip all_section_names all_interpreted_sections)
*)
(*
val elf_memory_image_unique_symbol_with_name : string -> elf_memory_image -> symbol_def
let elf_memory_image_unique_symbol_with_name name img = 
    match Map.lookup name img.image with
        Just el -> match el with
            FileFeature(ElfSection(_, x)) -> x
            | _ -> failwith "impossible: section name does not name a section"
        end
        | 
        | Nothing -> failwith ("no section named '" ^ name ^ "' but asserted unique")
    end
*)


(*val name_of_elf_section : elf64_interpreted_section -> elf_memory_image -> maybe string*)
let name_of_elf_section sec img2:(string)option=   
(  
   (* let shstrndx = natural_of_elf64_half ((elf_memory_image_header img).elf64_shstrndx)
   in
   match elf_memory_image_section_by_index shstrndx img with
        Nothing -> Nothing
        | Just shstrtab -> name_of_elf_interpreted_section sec shstrtab
  end *)Some sec.elf64_section_name_as_string)

(*val name_of_elf_element : elf_file_feature -> elf_memory_image -> maybe string*)
let name_of_elf_element feature img2:(string)option=    
  ((match feature with
        ElfSection(_, sec) -> name_of_elf_section sec img2
        | _ -> None (* FIXME *) 
    ))

(*val get_unique_name_for_section_from_index : natural -> elf64_interpreted_section -> elf_memory_image -> string*)
let get_unique_name_for_section_from_index idx1 isec1 img2:string=    
( 
    (* Don't call gensym just to retrieve the name *)(match elf_memory_image_element_coextensive_with_section idx1 img2 with
        Some n -> n
        | None -> failwith "section does not have an element name"
    ))
