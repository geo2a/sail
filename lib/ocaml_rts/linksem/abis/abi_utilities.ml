(*Generated by Lem from abis/abi_utilities.lem.*)
(** [abi_utilities], generic utilities shared between all ABIs.
  *)

open Lem_map
open Lem_maybe
open Lem_num
open Lem_basic_classes
open Lem_maybe
open Lem_string
open Error
open Lem_assert_extra

open Abi_classes
open Missing_pervasives
open Elf_types_native_uint
open Elf_symbol_table
open Elf_relocation
open Memory_image
open Memory_image_orderings


open Error

(** [integer_bit_width] records various bit widths for integral types, as used
  * in relocation calculations. The names are taken directly from the processor
  * supplements to keep the calculations as close as possible
  * to the specification of relocations.
  *)
type integer_bit_width
  = I8        (** Signed 8 bit *)
  | I12
  | U12       (** Unsigned 12 bit *)
  | Low14
  | U15       (** Unsigned 15 bit *)
  | I15
  | I16       (** Signed 16 bit *)
  | Half16ds
  | I20       (** Signed 20 bit *)
  | Low24
  | I27
  | Word30
  | I32       (** Signed 32 bit *)
  | I48       (** Signed 48 bit *)
  | I64       (** Signed 64 bit *)
  | I64X2     (** Signed 128 bit *)
  | U16       (** Unsigned 16 bit *)
  | U24       (** Unsigned 24 bit *)
  | U32       (** Unsigned 32 bit *)
  | U48       (** Unsigned 48 bit *)
  | U64       (** Unsigned 64 bit *)
  
(** [natural_of_integer_bit_width i] computes the bit width of integer bit width
  * [i].
  *)
(*val natural_of_integer_bit_width : integer_bit_width -> natural*)
let natural_of_integer_bit_width i:Nat_big_num.num=  
 ((match i with
    | I8       ->Nat_big_num.of_int 8
    | I12      ->Nat_big_num.of_int 12
    | U12      ->Nat_big_num.of_int 12
    | Low14    ->Nat_big_num.of_int 14
    | I15      ->Nat_big_num.of_int 15
    | U15      ->Nat_big_num.of_int 15
    | I16      ->Nat_big_num.of_int 16
    | Half16ds ->Nat_big_num.of_int 16
    | U16      ->Nat_big_num.of_int 16
    | I20      ->Nat_big_num.of_int 20
    | Low24    ->Nat_big_num.of_int 24
    | U24      ->Nat_big_num.of_int 24
    | I27      ->Nat_big_num.of_int 27
    | Word30   ->Nat_big_num.of_int 30
    | I32      ->Nat_big_num.of_int 32
    | U32      ->Nat_big_num.of_int 32
    | I48      ->Nat_big_num.of_int 48
    | U48      ->Nat_big_num.of_int 48
    | I64      ->Nat_big_num.of_int 64
    | U64      ->Nat_big_num.of_int 64
    | I64X2    ->Nat_big_num.of_int 128
  ))
  
(** [relocation_operator] records the operators used to calculate relocations by
  * the various ABIs.  Each ABI will only use a subset of these, and they should
  * be interpreted on a per-ABI basis.  As more ABIs are added, more operators
  * will be needed, and therefore more constructors in this type will need to
  * be added.  These are unary operators, operating on a single integral type.
  *)
type relocation_operator
  = TPRel
  | LTOff
  | DTPMod
  | DTPRel
  | Page
  | GDat
  | G
  | GLDM
  | GTPRel
  | GTLSDesc
  | Delta
  | LDM
  | TLSDesc
  | Indirect
  | Lo
  | Hi
  | Ha
  | Higher
  | HigherA
  | Highest
  | HighestA
  
(** [relocation_operator2] is a binary relocation operator, as detailed above.
  *)
type relocation_operator2 =
  | GTLSIdx
  
(** Generalising and abstracting over relocation calculations and their return
  * types
  *)
  
type( 'k, 'v) val_map = ('k, 'v)
  Pmap.map

(*val lookupM : forall 'k 'v. MapKeyType 'k => 'k -> val_map 'k 'v -> error 'v*)
let lookupM dict_Map_MapKeyType_k key val_map1:'v error=  
 ((match Pmap.lookup key val_map1 with
    | None -> fail "lookupM: key not found in val_map"
    | Some j  -> return j
  ))
  
(** Some relocations may fail, for example:
  * Page 58, Power ABI: relocation types whose Field column is marked with an
  * asterisk are subject to failure is the value computed does not fit in the
  * allocated bits.  [can_fail] type passes this information back to the caller
  * of the relocation application function.
  *)
type 'a can_fail
  = CanFail                       (** [CanFail] signals a potential failing relocation calculation when width constraints are invalidated *)
  | CanFailOnTest of ('a -> bool) (** [CanFailOnTest p] signals a potentially failing relocation calculation when predicate [p] on the result of the calculation returns [false] *)
  | CannotFail                    (** [CannotFail] states the relocation calculation cannot fail and bit-width constraints should be ignored *)
  
(** [relocation_operator_expression] is an AST of expressions describing a relocation
  * calculation.  An AST is used as it allows us to unify the treatment of relocation
  * calculation: rather than passing in dozens of functions to the calculation function
  * that perform the actual relocation, we can simply return a description (in the form
  * of the AST below) of the calculation to be carried out and have it interpreted
  * separately from the function that produces it.  The type parameter 'a is the
  * type of base integral type.  This AST suffices for the relocation calculations we
  * currently have implemented, but adding more ABIs may require that this type is
  * expanded.
  *)
type 'a relocation_operator_expression
  = Lift   of 'a                                                                                             (** Lift a base type into an AST *)
  | Apply  of (relocation_operator * 'a relocation_operator_expression)                                      (** Apply a unary operator to an expression *)
  | Apply2 of (relocation_operator2 * 'a relocation_operator_expression * 'a relocation_operator_expression) (** Apply a binary operator to two expressions *)
  | Plus   of ( 'a relocation_operator_expression * 'a relocation_operator_expression)                        (** Add two expressions. *)
  | Minus  of ( 'a relocation_operator_expression * 'a relocation_operator_expression)                        (** Subtract two expressions. *)
  | RShift of ( 'a relocation_operator_expression * Nat_big_num.num)                                                  (** Right shift the result of an expression [m] places. *)
  
type( 'addr, 'res) relocation_frame =
  | Copy
  | NoCopy of ( ('addr, ( 'res relocation_operator_expression * integer_bit_width * 'res can_fail))Pmap.map)

(*val size_of_def : symbol_reference_and_reloc_site -> natural*)
let size_of_def rr:Nat_big_num.num=  
 (let rf = (rr.ref) in
  let sm = (rf.ref_syment) in
    Ml_bindings.nat_big_num_of_uint64 sm.elf64_st_size)

(*val size_of_copy_reloc : forall 'abifeature. annotated_memory_image 'abifeature -> symbol_reference_and_reloc_site -> natural*)
let size_of_copy_reloc img2 rr:Nat_big_num.num=    
(  
    (* it's the minimum of the two definition symbol sizes. FIXME: for now, just use the rr *)size_of_def rr)

(*val reloc_site_address : forall 'abifeature. Ord 'abifeature, AbiFeatureTagEquiv 'abifeature => 
    annotated_memory_image 'abifeature -> symbol_reference_and_reloc_site -> natural*)
let reloc_site_address dict_Basic_classes_Ord_abifeature dict_Abi_classes_AbiFeatureTagEquiv_abifeature img2 rr:Nat_big_num.num=    
(  
    (* find the element range that's tagged with this reloc site *)let found_kvs = (Multimap.lookupBy0 
  (instance_Basic_classes_Ord_Memory_image_range_tag_dict
     dict_Basic_classes_Ord_abifeature) (instance_Basic_classes_Ord_Maybe_maybe_dict
   (instance_Basic_classes_Ord_tup2_dict
      Lem_string_extra.instance_Basic_classes_Ord_string_dict
      (instance_Basic_classes_Ord_tup2_dict
         instance_Basic_classes_Ord_Num_natural_dict
         instance_Basic_classes_Ord_Num_natural_dict))) instance_Basic_classes_SetType_var_dict (instance_Basic_classes_SetType_Maybe_maybe_dict
   (instance_Basic_classes_SetType_tup2_dict
      instance_Basic_classes_SetType_var_dict
      (instance_Basic_classes_SetType_tup2_dict
         instance_Basic_classes_SetType_Num_natural_dict
         instance_Basic_classes_SetType_Num_natural_dict))) (=) (SymbolRef(rr)) img2.by_tag)
    in
    (match found_kvs with
        [] -> failwith "impossible: reloc site not marked in memory image"
        | [(_, maybe_range)] -> (match maybe_range with 
                None -> failwith "impossible: reloc site has no element range"
                | Some (el_name, el_range) -> 
                    let element_addr = ((match Pmap.lookup el_name img2.elements with
                        None -> failwith "impossible: non-existent element"
                        | Some el -> (match el.startpos with
                            None -> failwith "error: resolving relocation site address before address has been assigned"
                            | Some addr -> addr
                        )
                    ))
                    in
                    let site_offset = (* match rr.maybe_reloc with 
                        Just reloc -> natural_of_elf64_addr reloc.ref_relent.elf64_ra_offset
                        | Nothing -> failwith "symbol reference with range but no reloc site"
                    end*) (let (start, _) = el_range in start)
                    in Nat_big_num.add
                    element_addr site_offset
            )
        | _ -> failwith "error: more than one address with identical relocation record"
    ))
