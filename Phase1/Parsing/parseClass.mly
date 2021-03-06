%{
  open AstClass
%}




/**************/
/* The tokens */
/**************/

/* Separators */
%token EOF
%token LBRACE RBRACE LPAR RPAR LBRACKET RBRACKET
%token SC EQUAL NEQUAL

/* Literal values */


/* Identifiers */
%token <string> IDENT
%token CLASS INTERFACE ENUM
%token PUBLIC PROTECTED PRIVATE STATIC ABSTRACT FINAL STRICTFP VOLATILE TRANSIENT
%token IMPORT PACKAGE
%token EXTENDS IMPLEMENTS
%token THIS SUPER
%token RETURN
%token PINT PSHORT PDOUBLE PCHAR PBOOLEAN PFLOAT PLONG PBYTE
%token POINT
%token VOID
%token THROWS
%token AT

%start compilationUnit

%type < AstClass.fileType > compilationUnit

(*%type < string > content*)

%%

compilationUnit:
  | packname=packageDeclaration? imp=importDeclarations? liste=typeDeclarations? EOF { FileType({packagename=packname; listImport=imp; listClass=liste; })}


packageDeclaration:
  | annotations? PACKAGE str=pathName SC { Package(str) }
  (*| error {raise Illegal_package}*)

importDeclarations:
  | str=importDeclaration { [Import(str)] }
  | p=importDeclarations str=importDeclaration 	{ p @ [Import(str)] }
  (*| error { raise Illegal_import }*)

importDeclaration:
  | decl = 	singleTypeImportDeclaration			{ decl }
  | decl = typeImportOnDemandDeclaration		{ decl }
  | decl = singleStaticImportDeclaration		{ decl }
  | decl = staticImportOnDemandDeclaration		{ decl }

singleTypeImportDeclaration:
  | IMPORT str=typeName SC { { name=str; isStatic=false; isOnDemand=false } }

typeImportOnDemandDeclaration:
  | IMPORT p=typeName POINT TIMES SC		{ { name=p; isStatic=false; isOnDemand=true } }

singleStaticImportDeclaration:
  | IMPORT STATIC p=typeName SC { { name=p; isStatic=true; isOnDemand=false} }

staticImportOnDemandDeclaration:
  | IMPORT STATIC p=typeName POINT TIMES SC { { name=p; isStatic=true; isOnDemand = true } }

typeDeclarations:
  |  decl = typeDeclaration { [decl] }
  | liste = typeDeclarations decl = typeDeclaration { liste @ [decl] }
  | error { raise External_error }

typeDeclaration:
  | decl = classDeclaration		{ decl }
  | decl = interfaceDeclaration	{ decl }


%public
classDeclaration:
  | decl = normalClassDeclaration	{ decl }
  | enum = enumDeclaration			{ enum }

normalClassDeclaration:
  | modi=classModifiers? CLASS id=IDENT leg=super? listeinterface= interfaces?  body=classBody { ClassType {classename = id; access = modi; classbody = body; inheritance=leg; interfaces = listeinterface  } }

enumDeclaration:
  | modi=classModifiers? ENUM id=IDENT listeinterface=interfaces? LBRACE body=enumBody RBRACE { EnumType { enumname = id; access = modi; enumbody = body; interfaces = listeinterface  } }


interfaceDeclaration:
  | modi=classModifiers? INTERFACE id=IDENT  (*typeParameters?*) (*extendsInterface?*) body=interfaceBody   { InterfaceType{interfacename = id; access = modi; interfaceBody=body } }

interfaceBody:
  | LBRACE liste = interfaceMemberDeclarations? RBRACE 	{ liste }
  | error { raise Illegal_interfaceBody }


interfaceMemberDeclarations:
  | decl=interfaceMemberDeclaration	{ [decl] }
  | liste=interfaceMemberDeclarations decl=interfaceMemberDeclaration	{ liste @ [decl] }
  | error { raise Illegal_interfaceBody }

interfaceMemberDeclaration:
  | constantDeclaration		{ ConstantDeclarationType }
  | decl=abstractMethodDeclaration	{ AbstractMethodDeclarationType(decl) }
  | decl=classDeclaration		{ InterfaceInnerClass(decl)  }
  | decl=interfaceDeclaration	{ InterfaceInnerInterface(decl) }

constantDeclaration:
  | classModifiers? typ variableDeclarators SC	{ }

abstractMethodDeclaration:
  | modi=classModifiers? (*typeParameters?*) VOID decl = methodDeclarator (*throws*)	SC	{ match decl with 
		| (methodname, listeparameter) -> { name=methodname; access=modi;parameters=listeparameter; resultType= Void }  }
  | modi=classModifiers? (*typeParameters?*) letype=typ decl=methodDeclarator (*throws*)	SC	{ match decl with 
		| (methodname, listeparameter) -> { name=methodname; access=modi;parameters=listeparameter; resultType=AttributType(letype) } }

enumBody:
  | cons=enumConstants?  decl=enumBodyDeclarations?	{ { enumConstants = cons; enumDeclarations= decl } }

enumConstants:
  | e=enumConstant	(*classBody?*)		{ [e] }
  | liste=enumConstants COMA e=enumConstant		{ liste @ [e] }

enumConstant:
  | str=IDENT liste=arguments?	{ { name=str; argumentlist=liste } }
    | error {raise Illegal_enumConstant}

arguments:
  | LPAR liste=argumentList RPAR		{ liste }

enumBodyDeclarations:
  | SC decl=classBodyDeclarations?		{ decl }


classBody:
  | LBRACE body=classBodyDeclarations?  RBRACE { body }

classBodyDeclarations:
  | decl = classBodyDeclaration	{ [decl] }
  | decls = classBodyDeclarations decl = classBodyDeclaration { decls @ [decl] }

classBodyDeclaration:
  | decl = classMemberDeclaration	{ ClassMemberType(decl) } (*TODO* faire types pour celui là *)
  | decl = instanceInitializer		{ InstanceInitializerType(decl) }
  | decl = staticInitializer	{ StaticInitializerType(decl) }
  | constructor = constructorDeclaration	{ constructor }

(*classMemberDeclaration*)

instanceInitializer:
  | stmts=block		{ BlockStatements(stmts) }

staticInitializer:
  | STATIC stmts=block		{ BlockStatements(stmts) }

classMemberDeclaration:
  | attribut = fieldDeclaration		{ Attribut(attribut) }
  | decl = methodDeclaration		{ MethodClass(decl) }
  | decl = classDeclaration			{ InnerClass(decl)	}
  | interface = interfaceDeclaration	{ InnerInterface(interface) }


	(*declaration des attributs*)
(*attributDeclaration:*)
(*  | classModifiers? str=typeDeclaration2 listDecl = variableDeclarators SC	{ { names=listeDecl; typeof=str } }*)

fieldDeclaration:
  | modi=classModifiers? str=typ n=variableDeclarators SC { { names=n; typeof=str; modifiers=modi } }

constructorDeclaration:
  | modi=classModifiers? result=constructorDeclarator LBRACE body=constructorBody? RBRACE	{ match result with
																					| (str, parameterliste) -> ConstructorType{name = str; access = modi; parameters = parameterliste; constructorbody = body } }

constructorDeclarator:
  | str=IDENT LPAR parameters = formalParameterList? RPAR	{ str, parameters  }
  | error { raise Illegal_ConstructorException}


constructorBody:
  | inv=explicitConstructorInvocation? stmts = blockstmts	{ { liststatements = stmts;  invocation=inv } }		(* blockstatements peut etre à redéfinir dans Expr*)



explicitConstructorInvocation: 
  | THIS LPAR liste=argumentList RPAR SC	{ { invocator=This; argumentlist=liste } }
  | SUPER LPAR liste=argumentList RPAR SC		{ {invocator=Super; argumentlist=liste } }
(*  | PRIMARY POINT SUPER parameterList? RBRACE SC*)



(* déclaration de méthodes*)
methodDeclaration:
  | decl=methodHeader body=methodBody { match decl with
													| (modi, (str, liste), result) -> { name=str; access=modi;methodbody=body; parameters=liste; resultType= result} }

methodHeader:
  | modi=classModifiers? r=VOID temp=methodDeclarator throws?	{ modi, temp, Void }
  | modi=classModifiers? r=typ temp=methodDeclarator throws?	{ modi, temp, AttributType(r) }

(*methodHeader:*)
(*  | modi=classModifiers? r=result temp=methodDeclarator (*throws?*)	{ modi, temp, r }*)

methodDeclarator:
  | str=IDENT LPAR liste=formalParameterList? RPAR	{ str, liste }

throws:
  | THROWS exceptionTypeList { }

exceptionTypeList:
  | exceptionType			{ }
  | exceptionTypeList COMA exceptionType	{ }

exceptionType:
  | classType		{ }
(*  | typeVariable	{ }*)

methodBody:
  | stmts = block { BlockStatements(stmts) }
  | error { raise Illegal_methodeBody } 
(*  | SC {  }*)

blockstmts:
  | stmts = statements	{ BlockStatements(stmts) }
| error { raise Illegal_methodeBody } 

(* utilisé par les ClassBody*)

formalParameterList:
  | p=lastFormalParameter 	{ [p] }
  | liste = formalParameters COMA p=lastFormalParameter	{ liste @ [p] }

formalParameters:
  | p=formalParameter		{ [p] }
  | liste=formalParameters COMA p=formalParameter		{ liste @ [p]}

lastFormalParameter:
  | variableModifiers? var=variableType POINT POINT POINT id=variableDeclaratorId	{ { name = id; parametertype=var} }
  | p=formalParameter		{ p }

formalParameter:
  | variableModifiers? var=variableType id=variableDeclaratorId		{ { name = id; parametertype=var} }

%public
variableModifiers:
  | modifier = variableModifier	{ [modifier] }
  | liste = variableModifiers modifier = variableModifier		{ liste @ [modifier] }

variableModifier:
  | f = FINAL 	{ AstExpr.Final }

variableType:
  | str=typ { str }
  | error {raise Illegal_variable}

annotations:
  |  annotation		{ }
  |  annotations annotation		{ }

annotation:
(*  |  normalAnnotation		{}*)
  |  expr = markerAnnotation			{ Annotation(expr) }
(*  |  singleElementAnnotation		{ }*)

(*normalAnnotation:*)
(*  | AT typeName LPAR elementValuePairs? RPAR	{ }*)

(*elementValuePairs:*)
(*  | elementValuePair	{ }*)
(*  | elementValuePairs COMA elementValuePair { }*)

(*elementValuePair:*)
(*  | IDENT ASS elementValue	{ }*)

(*elementValue:*)
(*  | conditionalExpression		{ }*)
(*  | annotation			{ }*)
(*  | elementValueArrayInitializer		{ }*)

(*elementValueArrayInitializer:*)
(*  | LBRACE elementValues? COMA? RBRACE 	{ }*)

(*elementValues:*)
(*  | elementValue		{ }*)
(*  | elementValues COMA elementValue 		{ }*)

markerAnnotation:
  | AT str=IDENT		{ Var str }


(* Caracteres speciaux *)

(*egalite:*)
(*  | str=IDENT EQUAL stri=IDENT SC {str^ " egale " ^ stri}*)

classModifiers:
  | m=classModifier		{ [m]}
  | liste=classModifiers m=classModifier	{ liste @ [m] }

classModifier:
  | m=modifierPrivate | m=modifierProtected | m=modifierPublic | m=modifierAbstract | m=modifierStatic | m=modifierFinal | m=modifierStrictfp | m=modifierTransient | m=modifierVolatile | m=annotation {m } 


modifierStrictfp:
  | STRICTFP		{ Strictfp }

modifierPublic:
  | PUBLIC 		{ Public }

modifierPrivate:
  | PRIVATE 	{ Private }

modifierProtected:
  | PROTECTED 	{ Protected }

modifierFinal:
  | FINAL			{ AstExpr.Final }

modifierStatic:
  | STATIC 	{ Static }

modifierAbstract:
  | ABSTRACT { Abstract }

modifierTransient:
  | TRANSIENT { Transient }

modifierVolatile:
  | VOLATILE { Volatile }

super:
  | EXTENDS str=classType { str }

interfaces:
  | IMPLEMENTS liste=interfaceTypeList  { liste }

interfaceTypeList:
  | str= interfaceType		{ [str] }
  | liste=interfaceTypeList COMA str=interfaceType 	{ liste @ [str] }

interfaceType:
  | str=IDENT	{ str }

classType:
  | str=IDENT	{ str }


