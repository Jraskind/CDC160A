(* glue.sml Create a lexer and a parser *)
structure CDC160LrVals = CDC160LrValsFun(
    structure Token = LrParser.Token);
structure CDC160Lex = CDC160LexFun(
    structure Tokens = CDC160LrVals.Tokens);
structure CDC160Parser = JoinWithArg(
    structure ParserData = CDC160LrVals.ParserData
    structure Lex=CDC160Lex
    structure LrParser=LrParser);
