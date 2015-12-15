%{
    open Expr
%}

/**********/
/* Tokens */
/**********/

/* Separators */
%token EOF LPAR RPAR

/* Operators */
%token PLUS MINUS TIMES DIV MOD
%token AND OR NOT
%token GT GE LT LE EQ NEQ

/* Literal values */
%token <float> FLOAT
%token <bool> BOOL

/* Identifiers */
%token <string> IDENT

/********************************/
/* Priorities and associativity */
/********************************/

%left OR
%left AND
%left EQ NEQ
%left GT GE LT LE
%left PLUS MINUS
%left TIMES DIV MOD
%right UMINUS NOT

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
  | e = expr EOF                      { e }

expr:
  | LPAR e = expr RPAR                { e }
  | e1 = expr op = binop e2 = expr    { Binop(op, e1, e2) }
  | f = FLOAT                         { Const f }
  | id = IDENT                        { Var id }
  | b = BOOL                              { Bool b }
  | NOT e = expr                      { Unop(Unot, e) }
  | MINUS e = expr %prec UMINUS       { Unop(Uminus, e) }

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

%%

