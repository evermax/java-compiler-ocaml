%{
    open Expr
%}

/**********/
/* Tokens */
/**********/

/* Operators */
%token PLUS MINUS TIMES DIV MOD
%token AND OR NOT
%token GT GE LT LE EQ NEQ
%token NULL
%token INCR DECR BITWISE
%token  ASS MULASS DIVASS MODASS PLUSASS MINUSASS

/* Literal values */
%token <float> FLOAT
%token <int> INT
%token <bool> BOOL
%token <string> STRING
%token <string> CHAR

/* Identifiers */
(*%token <string> IDENT*)

/********************************/
/* Priorities and associativity */
/********************************/

%left OR
%left AND
%left EQ NEQ
%left GT GE LT LE
%left PLUS MINUS
%left TIMES DIV MOD
%right UMINUS UPLUS NOT INCR DECR BITWISE

/******************************/
/* Entry points of the parser */
/******************************/

%start expression
%type <Expr.expression> expression

%%

/*********/
/* Rules */
/*********/

expression:
  | e = expr EOL* EOF                 { e }

expr:
  | LPAR e = expr RPAR                { e }
  | e1 = expr op = binop e2 = expr    { Binop(e1, op, e2) }
  | f = FLOAT                         { Float f }
  | i = INT                           { Int i }
  | id = IDENT                        { Var id }
  | str = STRING                      { String str }
  | c = CHAR                          { Char c }
  | b = BOOL                          { Bool b }
  | op = unop e = expr                { Unop(op, e) }
  | MINUS e = expr %prec UMINUS       { Unop(Uminus, e) }
  | PLUS e = expr %prec UPLUS         { Unop(Uplus, e) }
  | e1 = expr ass = assign e2 = expr  { Assign(e1, ass, e2) }

%inline binop:
  | PLUS      { Badd }
  | MINUS     { Bsub }
  | TIMES     { Bmul }
  | DIV       { Bdiv }
  | MOD       { Bmod }
  | AND       { Band }
  | OR        { Bor }
  | EQ        { Beq }
  | NEQ       { Bneq }
  | GT        { Bgt }
  | GE        { Bge }
  | LT        { Blt }
  | LE        { Ble }

%inline unop:
  | NOT       { Unot }
  | INCR      { Uincr }
  | DECR      { Udecr }
  | BITWISE   { Ubit }

%inline assign:
  | ASS       { Ass }
  | MULASS    { Assmul }
  | DIVASS    { Assdiv }
  | MODASS    { Assmod }
  | PLUSASS   { Assplus }
  | MINUSASS  { Assminus }

%%

