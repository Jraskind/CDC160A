structure T = Tokens
type pos = int (* Position in file *)
type svalue = T.svalue
type ('a,'b) token = ('a,'b) Tokens.token
type lexresult = (svalue,pos) token
type lexarg = string
type arg = lexarg
val linep = ref 1
exception Error
val error : string * int -> unit = fn (e,l1) => (TextIO.output(TextIO.stdOut,"lex:line "^Int.toString l1^": "^e^"\n"); raise Error)
  val eof = fn fileName => (T.EOF(!linep, !linep))
%%
%header (functor CDC160LexFun(structure Tokens: CDC160_TOKENS));
%arg (fileName:string);
%s COMMENT;
octals = [0-7];
digits = [0-9];
ws = [\ \t\r];
alpha = [A-Z];
%%
<INITIAL> \n => (linep := !linep + 1; continue());
<INITIAL> {ws}+ => (continue());
<INITIAL> {octals}{4} => (T.W(foldl (fn(elem,acc)=>Word.fromInt(ord(elem)-ord(#"0"))+ Word.<<(acc, 0wx3)) 0wx0 (explode (yytext)), yypos, yypos+size yytext));
<INITIAL> {octals}{2} => (T.W(foldl (fn(elem,acc)=>Word.fromInt(ord(elem)-ord(#"0"))+ Word.<<(acc, 0wx3)) 0wx0 (explode (yytext)), yypos, yypos+size yytext));
<INITIAL> {octals}* => (error("OCTALS MUST BE 2 OR 4 BITS LONG: "^yytext, !linep); continue());
<INITIAL> {digits}* => (error("YOU MAY ONLY ENTER OCTALS : "^yytext, !linep); continue());
<INITIAL> [A-Z]{3} => (T.INS(yypos, yypos+size yytext));
<INITIAL> [A-Z]* => (error("OPCODE MUST BE THREE LETTERS: "^yytext, !linep); continue());
<INITIAL> "#" => (YYBEGIN COMMENT; continue());
<INITIAL> . => (error("Bad character "^yytext, !linep); continue());

<COMMENT> \n => (YYBEGIN INITIAL; linep := !linep + 1; continue());
<COMMENT> . => (continue());
