type binop =
  | Badd | Bsub | Bmul | Bdiv | Bmod
  | Band | Bor
  | Beq | Bneq | Bgt | Bge | Blt | Ble

type unop =
  | Uminus
  | Unot

type expression =
  | Const of float
  | Var of string
  | Binop of binop * expression * expression
  | Bool of bool
  | Unop of unop * expression

let string_of_binop = function
  | Badd -> "+"
  | Bsub -> "-"
  | Bmul -> "*"
  | Bdiv -> "/"
  | Bmod -> "%"
  | Band -> "&&"
  | Bor  -> "||"
  | Beq  -> "="
  | Bneq -> "!="
  | Bgt  -> ">"
  | Bge  -> ">="
  | Blt  -> "<"
  | Ble  -> "<="

let string_of_unop = function
  | Unot -> "not"
  | Uminus -> "-"

let rec string_of_expr expr =
  match expr with
  | Const c -> string_of_float c
  | Var v -> v
  | Binop(op, e1, e2) -> "(" ^ (string_of_expr e1) ^ (string_of_binop op) ^ (string_of_expr e2) ^ ")"
  | Bool true -> "true"
  | Bool false -> "false"
  | Unop(op, e) -> "(" ^ (string_of_unop op) ^ (string_of_expr e) ^ ")"

