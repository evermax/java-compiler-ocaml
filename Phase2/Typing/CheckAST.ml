open AST

(* String of helpers *)

let string_of_prefix_type = function
  | Op_not -> "boolean"
  | Op_bnot -> "int"
  | Op_neg | Op_incr | Op_decr | Op_plus -> "int ou float"


(* ERRORS *)

exception Wrong_types_aop of Type.t option * assign_op * Type.t option
exception Wrong_types_op of Type.t option * infix_op * Type.t option
exception Wrong_types_bool_op of Type.t option * infix_op
exception Wrong_type_tern of Type.t option
exception Wrong_type_if of Type.t option
exception Wrong_type_for of Type.t option
exception Wrong_type_post of Type.t option
exception Wrong_type_unop of prefix_op * Type.t option
exception Type_mismatch_tern of Type.t option * Type.t option
exception Type_mismatch_decl of Type.t option * Type.t option
exception Function_exist of string * Type.t * argument list
exception Variable_name_exist of string
exception Attribute_name_exist of string
exception Class_name_exist of string
exception Unknown_variable of string
exception Unknown_method of string * AST.expression list * string option
exception Unknown_class of string list
exception Unknown_constructor of string list * AST.expression list
exception Unknown_attribute of string * string
exception Wrong_type_list of Type.t option * Type.t option
exception Wrong_return_type of Type.t * Type.t
exception Return_expression_no_type
exception Not_typed_arg of string
exception Wrong_ref_type of Type.ref_type * Type.ref_type

(* String of errors *)
let print_wrong_types_aop x op y =
  print_string ("L'operateur " ^ (AST.string_of_assign_op op));
  print_string (" attend deux arguments de meme type");
  print_string (" et il recoit " ^ (Type.stringOfOpt x));
  print_endline (" et " ^ (Type.stringOfOpt y))

let print_wrong_types_op x op y =
    print_string ("L'operateur " ^ (AST.string_of_infix_op op));
    print_string (" attend deux arguments de meme type");
    print_string (" et il recoit " ^ (Type.stringOfOpt x));
    print_endline (" et " ^ (Type.stringOfOpt y))

let print_wrong_types_bool_op x op =
    print_string ("L'operateur " ^ (AST.string_of_infix_op op));
    print_string (" attend deux arguments type bool");
    print_endline (" et il recoit des " ^ (Type.stringOfOpt x))

let print_not_bool_exception expression test =
  print_string ("La condition d'une expression " ^ expression ^ " doit etre un booleen");
  print_endline (" et elle recoit un " ^ (Type.stringOfOpt test))

let print_wrong_type_post x =
  print_string ("Les operateurs ++ et -- attendent un int ou un float");
  print_endline (" et recoivent un " ^ (Type.stringOfOpt x))

let print_wrong_type_pre op x =
  print_string ("L'operateur " ^ (AST.string_of_prefix_op op));
  print_string (" attend un argument de type " ^ (string_of_prefix_type op));
  print_endline (" et il recoit " ^ (Type.stringOfOpt x))

let print_type_mismatch expression x y =
  print_string ("Les deux expressions d'une " ^ expression ^ " doivent etre du meme type");
  print_string (" et elle recoit " ^ (Type.stringOfOpt x));
  print_endline (" et " ^ (Type.stringOfOpt y))

let print_type_ref_mismatch x y =
  print_string ("Les deux expressions doivent etre du meme type");
  print_string (" mais ont " ^ (Type.stringOf_ref x));
  print_endline (" et " ^ (Type.stringOf_ref y))

let print_name_exist str name =
  print_endline ("Le nom de " ^ str ^ " \"" ^ name ^ "\" existe deja")

let print_unknown_variable name =
  print_endline ("Pas de variable \"" ^ name ^ "\"")

let print_unknown_method name args cname =
  print_string ("Pas de method \"" ^ name ^ "\" avec les arguments (");
  print_string (String.concat ", " (List.map AST.stringOfExpType args));
  match cname with
  | None -> print_endline (") dans le scope global")
  | Some(str) -> print_endline (") dans la classe " ^ str)

let print_unknown_class name =
  print_endline ("Pas de classe \"" ^ name ^ "\" visible")

let print_unknown_constructor name args =
  print_string ("Pas de constructeur \"" ^ name ^ "\" avec les arguments (");
  print_endline ((String.concat ", " (List.map AST.stringOfExpType args) ^ ")"))

let print_unknown_attribute name c =
  print_endline ("Pas d'attribut " ^ name ^ " dans la classe " ^ c)

let print_wrong_type_list x y =
  print_string ("Toutes les entrees d'un tableau doivent etre de meme type");
  print_string (" et il recoit " ^ (Type.stringOfOpt x));
  print_endline (" et " ^ (Type.stringOfOpt y))

let print_wrong_return_type x y =
  print_endline ("Le type de retour attendu est " ^ (Type.stringOf x) ^ " mais il recoit " ^ (Type.stringOf y))

let print_method_exist name typ args =
  print_endline ("La methode " ^ Type.stringOf typ ^ " " ^ name ^ "(" ^ (String.concat "," (List.map AST.stringOf_arg args)) ^ ") existe deja")

let print_arg_not_typed name =
  print_endline ("La methode " ^ name ^ " contient des parametres non types")

(* CHECKS *)
let check_op_type x op y =
  (if x <> y then raise(Wrong_types_op(x, op, y)));
  match op with
  | Op_cor | Op_cand -> if (x <> Some(Type.Primitive(Type.Boolean)) || y <> Some(Type.Primitive(Type.Boolean)))
    then raise(Wrong_types_bool_op(x, op))
  | _ -> ()

let check_return_type x y =
  match x, y with
  | _, None -> raise(Return_expression_no_type)
  | x, Some(z) -> if x <> z then raise(Wrong_return_type(x, z))

let check_tern_type test x y =
  if test <> Some(Type.Primitive(Type.Boolean)) then raise(Wrong_type_tern(test));
  match x, y with
  | Some(Type.Primitive(_)), None -> raise(Type_mismatch_tern(x, y))
  | None, Some(Type.Primitive(_)) -> raise(Type_mismatch_tern(x, y))
  | Some(_), None -> ()
  | None, Some(_) -> ()
  | Some(typ1), Some(typ2) ->  if typ1 <> typ2 then raise(Type_mismatch_tern(x, y))

let check_if_test_type test =
  if test <> Some(Type.Primitive(Type.Boolean)) then raise(Wrong_type_if(test))

let check_post_type x =
  if (x <> Some(Type.Primitive(Type.Int)) && x <> Some(Type.Primitive(Type.Float))) then raise(Wrong_type_post(x))

let check_pre_type op x =
  match op with
  | Op_not -> if x <> Some(Type.Primitive(Type.Boolean)) then raise(Wrong_type_unop(op, x))
  | Op_bnot -> if x <> Some(Type.Primitive(Type.Int)) then raise(Wrong_type_unop(op, x))
  | Op_neg | Op_incr | Op_decr | Op_plus -> if (x <> Some(Type.Primitive(Type.Int)) && x <> Some(Type.Primitive(Type.Float))) then raise(Wrong_type_unop(op, x))

let rec check_array_list_type exp =
  match exp with
  | [] -> ()
  | h::t -> (match t with
    | [] -> ()
    | h2::t2 -> if h.etype <> h2.etype then raise(Wrong_type_list(h.etype, h2.etype)));
    check_array_list_type t

let check_for_expr test =
  if test <> Some(Type.Primitive(Type.Boolean)) then raise(Wrong_type_for(test))
