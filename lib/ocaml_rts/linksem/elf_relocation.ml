(*Generated by Lem from elf_relocation.lem.*)
(** [elf_relocation] formalises types, functions and other definitions for working
  * with ELF relocation and relocation with addend entries.
  *)

open Lem_basic_classes
open Lem_num
open Lem_list
(*import Set*)

open Endianness
open Byte_sequence
open Error

open Lem_string
open Show
open Missing_pervasives

open Elf_types_native_uint

(** ELF relocation records *)

(** [elf32_relocation] is a simple relocation record (without addend).
  *)
type elf32_relocation =
  { elf32_r_offset : Uint32.uint32 (** Address at which to relocate *)
   ; elf32_r_info   : Uint32.uint32 (** Symbol table index/type of relocation to apply *)
   }

(** [elf32_relocation_a] is a relocation record with addend.
  *)
type elf32_relocation_a =
  { elf32_ra_offset : Uint32.uint32  (** Address at which to relocate *)
   ; elf32_ra_info   : Uint32.uint32  (** Symbol table index/type of relocation to apply *)
   ; elf32_ra_addend : Int32.t (** Addend used to compute value to be stored *)
   }

(** [elf64_relocation] is a simple relocation record (without addend).
  *)
type elf64_relocation =
  { elf64_r_offset : Uint64.uint64  (** Address at which to relocate *)
   ; elf64_r_info   : Uint64.uint64 (** Symbol table index/type of relocation to apply *)
   }

(** [elf64_relocation_a] is a relocation record with addend.
  *)
type elf64_relocation_a =
  { elf64_ra_offset : Uint64.uint64   (** Address at which to relocate *)
   ; elf64_ra_info   : Uint64.uint64  (** Symbol table index/type of relocation to apply *)
   ; elf64_ra_addend : Int64.t (** Addend used to compute value to be stored *)
   }

(** [elf64_relocation_a_compare r1 r2] is an ordering comparison function for
  * relocation with addend records suitable for constructing sets, finite map
  * and other ordered data structures.
  * NB: we exclusively use elf64_relocation_a in range tags, regardless of what
  * file/reloc  the info came from, so only this one needs an Ord instance.
  *)
(*val elf64_relocation_a_compare : elf64_relocation_a -> elf64_relocation_a ->
  ordering*)
let elf64_relocation_a_compare ent1 ent2:int=     
 (tripleCompare Nat_big_num.compare Nat_big_num.compare Nat_big_num.compare (Ml_bindings.nat_big_num_of_uint64 ent1.elf64_ra_offset, Ml_bindings.nat_big_num_of_uint64 ent1.elf64_ra_info,
        Nat_big_num.of_int64 ent1.elf64_ra_addend) 
        (Ml_bindings.nat_big_num_of_uint64 ent2.elf64_ra_offset, Ml_bindings.nat_big_num_of_uint64 ent2.elf64_ra_info,
        Nat_big_num.of_int64 ent2.elf64_ra_addend))

let instance_Basic_classes_Ord_Elf_relocation_elf64_relocation_a_dict:(elf64_relocation_a)ord_class= ({

  compare_method = elf64_relocation_a_compare;

  isLess_method = (fun f1 -> (fun f2 -> ( Lem.orderingEqual(elf64_relocation_a_compare f1 f2) (-1))));

  isLessEqual_method = (fun f1 -> (fun f2 -> Pset.mem (elf64_relocation_a_compare f1 f2)(Pset.from_list compare [(-1); 0])));

  isGreater_method = (fun f1 -> (fun f2 -> ( Lem.orderingEqual(elf64_relocation_a_compare f1 f2) 1)));

  isGreaterEqual_method = (fun f1 -> (fun f2 -> Pset.mem (elf64_relocation_a_compare f1 f2)(Pset.from_list compare [1; 0])))})   

(** Extracting useful information *)

(** [extract_elf32_relocation_r_sym w] computes the symbol table index associated with
  * an ELF32 relocation(a) entry.
  * [w] here is the [r_info] member of the [elf32_relocation(a)] type.
  *)
(*val extract_elf32_relocation_r_sym : elf32_word -> natural*)
let extract_elf32_relocation_r_sym w:Nat_big_num.num=  
 (Nat_big_num.of_string (Uint32.to_string (Uint32.shift_right w( 8))))

(** [extract_elf64_relocation_r_sym w] computes the symbol table index associated with
  * an ELF64 relocation(a) entry.
  * [w] here is the [r_info] member of the [elf64_relocation(a)] type.
  *)
(*val extract_elf64_relocation_r_sym : elf64_xword -> natural*)
let extract_elf64_relocation_r_sym w:Nat_big_num.num=  
 (Ml_bindings.nat_big_num_of_uint64 (Uint64.shift_right w( 32)))

(** [extract_elf32_relocation_r_type w] computes the symbol type associated with an ELF32
  * relocation(a) entry.
  * [w] here is the [r_info] member of the [elf32_relocation(a)] type.
  *)
(*val extract_elf32_relocation_r_type : elf32_word -> natural*)
let extract_elf32_relocation_r_type w:Nat_big_num.num=  (Nat_big_num.modulus
  (Nat_big_num.of_string (Uint32.to_string w))(Nat_big_num.of_int 256))

(** [extract_elf64_relocation_r_type w] computes the symbol type associated with an ELF64
  * relocation(a) entry.
  * [w] here is the [r_info] member of the [elf64_relocation(a)] type.
  *)
(*val extract_elf64_relocation_r_type : elf64_xword -> natural*)
let extract_elf64_relocation_r_type w:Nat_big_num.num=  
 (let magic = (Nat_big_num.sub_nat ( Nat_big_num.mul(Nat_big_num.of_int 65536)(Nat_big_num.of_int 65536))(Nat_big_num.of_int 1)) in (* 0xffffffffL *)
    Ml_bindings.nat_big_num_of_uint64 (Uint64.logand w (Uint64.of_string (Nat_big_num.to_string magic))))
    
(* Accessors *) 

(*val get_elf32_relocation_r_sym : elf32_relocation -> natural*)
let get_elf32_relocation_r_sym r:Nat_big_num.num=  
 (extract_elf32_relocation_r_sym r.elf32_r_info)

(*val get_elf32_relocation_a_sym :  elf32_relocation_a -> natural*)
let get_elf32_relocation_a_sym r:Nat_big_num.num=  
  (extract_elf32_relocation_r_sym r.elf32_ra_info)  

(*val get_elf64_relocation_sym : elf64_relocation -> natural*)
let get_elf64_relocation_sym r:Nat_big_num.num=  
 (extract_elf64_relocation_r_sym r.elf64_r_info)  
  
(*val get_elf64_relocation_a_sym :  elf64_relocation_a -> natural*)
let get_elf64_relocation_a_sym r:Nat_big_num.num=  
  (extract_elf64_relocation_r_sym r.elf64_ra_info)  

(*val get_elf32_relocation_type : elf32_relocation -> natural*)
let get_elf32_relocation_type r:Nat_big_num.num=  
 (extract_elf32_relocation_r_type r.elf32_r_info)

(*val get_elf32_relocation_a_type  : elf32_relocation_a -> natural*)
let get_elf32_relocation_a_type  r:Nat_big_num.num=  
 (extract_elf32_relocation_r_type r.elf32_ra_info)  

(*val get_elf64_relocation_type : elf64_relocation -> natural*)
let get_elf64_relocation_type r:Nat_big_num.num=  
 (extract_elf64_relocation_r_type r.elf64_r_info)  

(*val get_elf64_relocation_a_type  : elf64_relocation_a -> natural*)
let get_elf64_relocation_a_type  r:Nat_big_num.num=  
 (extract_elf64_relocation_r_type r.elf64_ra_info)  

    
(** Reading relocation entries *)
    
(** [read_elf32_relocation ed bs0] parses an [elf32_relocation] record from
  * byte sequence [bs0] assuming endianness [ed].  The suffix of [bs0] remaining
  * after parsing is also returned.
  * Fails if the relocation record cannot be parsed.
  *)
(*val read_elf32_relocation : endianness -> byte_sequence ->
  error (elf32_relocation * byte_sequence)*)
let read_elf32_relocation endian bs:(elf32_relocation*byte_sequence)error=  
 (read_elf32_addr endian bs >>= (fun (r_offset, bs) ->
  read_elf32_word endian bs >>= (fun (r_info, bs) ->
  return ({ elf32_r_offset = r_offset; elf32_r_info = r_info }, bs))))
    
(** [read_elf64_relocation ed bs0] parses an [elf64_relocation] record from
  * byte sequence [bs0] assuming endianness [ed].  The suffix of [bs0] remaining
  * after parsing is also returned.
  * Fails if the relocation record cannot be parsed.
  *)
(*val read_elf64_relocation : endianness -> byte_sequence ->
  error (elf64_relocation * byte_sequence)*)
let read_elf64_relocation endian bs:(elf64_relocation*byte_sequence)error=  
 (read_elf64_addr endian bs  >>= (fun (r_offset, bs) ->
  read_elf64_xword endian bs >>= (fun (r_info, bs) ->
  return ({ elf64_r_offset = r_offset; elf64_r_info = r_info }, bs))))

(** [read_elf32_relocation_a ed bs0] parses an [elf32_relocation_a] record from
  * byte sequence [bs0] assuming endianness [ed].  The suffix of [bs0] remaining
  * after parsing is also returned.
  * Fails if the relocation record cannot be parsed.
  *)
(*val read_elf32_relocation_a : endianness -> byte_sequence ->
  error (elf32_relocation_a * byte_sequence)*)
let read_elf32_relocation_a endian bs:(elf32_relocation_a*byte_sequence)error=  
 (read_elf32_addr endian bs  >>= (fun (r_offset, bs) ->
  read_elf32_word endian bs  >>= (fun (r_info, bs) ->
  read_elf32_sword endian bs >>= (fun (r_addend, bs) ->
  return ({ elf32_ra_offset = r_offset; elf32_ra_info = r_info;
    elf32_ra_addend = r_addend }, bs)))))

(** [read_elf64_relocation_a ed bs0] parses an [elf64_relocation_a] record from
  * byte sequence [bs0] assuming endianness [ed].  The suffix of [bs0] remaining
  * after parsing is also returned.
  * Fails if the relocation record cannot be parsed.
  *)
(*val read_elf64_relocation_a : endianness -> byte_sequence -> error (elf64_relocation_a * byte_sequence)*)
let read_elf64_relocation_a endian bs:(elf64_relocation_a*byte_sequence)error=  
 (read_elf64_addr endian bs   >>= (fun (r_offset, bs) ->
  read_elf64_xword endian bs  >>= (fun (r_info, bs) ->
  read_elf64_sxword endian bs >>= (fun (r_addend, bs) ->
  return ({ elf64_ra_offset = r_offset; elf64_ra_info = r_info;
    elf64_ra_addend = r_addend }, bs)))))

(** [read_elf32_relocation_section' ed bs0] parses a list of [elf32_relocation]
  * records from byte sequence [bs0], which is assumed to have the exact size
  * required, assuming endianness [ed].
  * Fails if any of the records cannot be parsed.
  *)
(*val read_elf32_relocation_section' : endianness -> byte_sequence ->
  error (list elf32_relocation)*)
let rec read_elf32_relocation_section' endian bs0:((elf32_relocation)list)error=  
 (if Nat_big_num.equal (Byte_sequence.length0 bs0)(Nat_big_num.of_int 0) then
    return []
  else
    read_elf32_relocation endian bs0 >>= (fun (entry, bs1) ->
    read_elf32_relocation_section' endian bs1 >>= (fun tail ->
    return (entry::tail))))

(** [read_elf64_relocation_section' ed bs0] parses a list of [elf64_relocation]
  * records from byte sequence [bs0], which is assumed to have the exact size
  * required, assuming endianness [ed].
  * Fails if any of the records cannot be parsed.
  *)
(*val read_elf64_relocation_section' : endianness -> byte_sequence ->
  error (list elf64_relocation)*)
let rec read_elf64_relocation_section' endian bs0:((elf64_relocation)list)error=  
 (if Nat_big_num.equal (Byte_sequence.length0 bs0)(Nat_big_num.of_int 0) then
    return []
  else
    read_elf64_relocation endian bs0 >>= (fun (entry, bs1) ->
    read_elf64_relocation_section' endian bs1 >>= (fun tail ->
    return (entry::tail))))
    
(** [read_elf32_relocation_a_section' ed bs0] parses a list of [elf32_relocation_a]
  * records from byte sequence [bs0], which is assumed to have the exact size
  * required, assuming endianness [ed].
  * Fails if any of the records cannot be parsed.
  *)
(*val read_elf32_relocation_a_section' : endianness -> byte_sequence ->
  error (list elf32_relocation_a)*)
let rec read_elf32_relocation_a_section' endian bs0:((elf32_relocation_a)list)error=  
 (if Nat_big_num.equal (Byte_sequence.length0 bs0)(Nat_big_num.of_int 0) then
    return []
  else
    read_elf32_relocation_a endian bs0 >>= (fun (entry, bs1) ->
    read_elf32_relocation_a_section' endian bs1 >>= (fun tail ->
    return (entry::tail))))
    
(** [read_elf64_relocation_a_section' ed bs0] parses a list of [elf64_relocation_a]
  * records from byte sequence [bs0], which is assumed to have the exact size
  * required, assuming endianness [ed].
  * Fails if any of the records cannot be parsed.
  *)
(*val read_elf64_relocation_a_section' : endianness -> byte_sequence ->
  error (list elf64_relocation_a)*)
let rec read_elf64_relocation_a_section' endian bs0:((elf64_relocation_a)list)error=  
 (if Nat_big_num.equal (Byte_sequence.length0 bs0)(Nat_big_num.of_int 0) then
    return []
  else
    read_elf64_relocation_a endian bs0 >>= (fun (entry, bs1) ->
    read_elf64_relocation_a_section' endian bs1 >>= (fun tail ->
    return (entry::tail))))
    
(** [read_elf32_relocation_section sz ed bs0] reads in a list of [elf32_relocation]
  * records from a prefix of [bs0] of size [sz] assuming endianness [ed].  The
  * suffix of [bs0] remaining after parsing is also returned.
  * Fails if any of the records cannot be parsed or if the length of [bs0] is
  * less than [sz].
  *)
(*val read_elf32_relocation_section : natural -> endianness -> byte_sequence
  -> error (list elf32_relocation * byte_sequence)*)
let read_elf32_relocation_section table_size endian bs0:((elf32_relocation)list*byte_sequence)error=  
 (partition0 table_size bs0 >>= (fun (eat, rest) ->
  read_elf32_relocation_section' endian eat >>= (fun entries ->
  return (entries, rest))))

(** [read_elf64_relocation_section sz ed bs0] reads in a list of [elf64_relocation]
  * records from a prefix of [bs0] of size [sz] assuming endianness [ed].  The
  * suffix of [bs0] remaining after parsing is also returned.
  * Fails if any of the records cannot be parsed or if the length of [bs0] is
  * less than [sz].
  *)
(*val read_elf64_relocation_section : natural -> endianness -> byte_sequence
  -> error (list elf64_relocation * byte_sequence)*)
let read_elf64_relocation_section table_size endian bs0:((elf64_relocation)list*byte_sequence)error=  
 (partition0 table_size bs0 >>= (fun (eat, rest) ->
  read_elf64_relocation_section' endian eat >>= (fun entries ->
  return (entries, rest))))

(** [read_elf32_relocation_a_section sz ed bs0] reads in a list of [elf32_relocation_a]
  * records from a prefix of [bs0] of size [sz] assuming endianness [ed].  The
  * suffix of [bs0] remaining after parsing is also returned.
  * Fails if any of the records cannot be parsed or if the length of [bs0] is
  * less than [sz].
  *)
(*val read_elf32_relocation_a_section : natural -> endianness -> byte_sequence ->
  error (list elf32_relocation_a * byte_sequence)*)
let read_elf32_relocation_a_section table_size endian bs0:((elf32_relocation_a)list*byte_sequence)error=  
 (partition0 table_size bs0 >>= (fun (eat, rest) ->
  read_elf32_relocation_a_section' endian eat >>= (fun entries ->
  return (entries, rest))))

(** [read_elf64_relocation_a_section sz ed bs0] reads in a list of [elf64_relocation_a]
  * records from a prefix of [bs0] of size [sz] assuming endianness [ed].  The
  * suffix of [bs0] remaining after parsing is also returned.
  * Fails if any of the records cannot be parsed or if the length of [bs0] is
  * less than [sz].
  *)
(*val read_elf64_relocation_a_section : natural -> endianness -> byte_sequence ->
  error (list elf64_relocation_a * byte_sequence)*)
let read_elf64_relocation_a_section table_size endian bs0:((elf64_relocation_a)list*byte_sequence)error=  
 (partition0 table_size bs0 >>= (fun (eat, rest) ->
  read_elf64_relocation_a_section' endian eat >>= (fun entries ->
  return (entries, rest))))
