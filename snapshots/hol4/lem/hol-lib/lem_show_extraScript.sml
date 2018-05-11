(*Generated by Lem from show_extra.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_stringTheory lem_maybeTheory lem_numTheory lem_basic_classesTheory lem_setTheory lem_relationTheory lem_showTheory lem_set_extraTheory lem_string_extraTheory;

val _ = numLib.prefer_num();



val _ = new_theory "lem_show_extra"



(*open import String Maybe Num Basic_classes Set Relation Show*) 
(*import Set_extra String_extra*)

val _ = Define `
((instance_Show_Show_nat_dict:(num)lem_show$Show_class)= (<|

  show_method := num_to_dec_string|>))`;


val _ = Define `
((instance_Show_Show_Num_natural_dict:(num)lem_show$Show_class)= (<|

  show_method := num_to_dec_string|>))`;


val _ = Define `
((instance_Show_Show_Num_int_dict:(int)lem_show$Show_class)= (<|

  show_method := lem_string_extra$stringFromInt|>))`;


val _ = Define `
((instance_Show_Show_Num_integer_dict:(int)lem_show$Show_class)= (<|

  show_method := lem_string_extra$stringFromInteger|>))`;


val _ = Define `
 ((stringFromSet:('a -> string) -> 'a set -> string) showX xs=   
 (STRCAT"{"  (STRCAT(lem_show$stringFromListAux showX (SET_TO_LIST xs)) "}")))`;


(* Abbreviates the representation if the relation is transitive. *)
val _ = Define `
 ((stringFromRelation:('a#'a -> string) ->('a#'a)set -> string) showX rel=  
 (if transitive rel then
    let pruned_rel = (withoutTransitiveEdges rel) in
    if (! (e :: rel). (e IN pruned_rel)) then
      (* The relations are the same (there are no transitive edges),
         so we can just as well print the original one. *)
      stringFromSet showX rel
    else
       STRCAT"trancl of " (stringFromSet showX pruned_rel)
  else
    stringFromSet showX rel))`;


val _ = Define `
((instance_Show_Show_set_dict:'a lem_show$Show_class ->('a set)lem_show$Show_class)dict_Show_Show_a= (<|

  show_method := (\ xs. stringFromSet  
  dict_Show_Show_a.show_method xs)|>))`;

val _ = export_theory()

