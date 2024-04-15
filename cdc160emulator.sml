structure D = DataTypes
structure CDC160 :
	  sig val compile: string -> D.Instructions
	      val load : D.Instructions -> word array
	      val main : string -> word array
	  end =
struct
exception CDC160Error;
fun compile (fileName) =
    let val inStream = TextIO.openIn fileName;
	val grab : int -> string = fn
				  n => if TextIO.endOfStream inStream
				       then ""
				       else TextIO.inputN (inStream, n);
	val printError : string * int * int -> unit = fn
						     (msg, line, col) => print (fileName^"["^Int.toString line^":"^Int.toString col^"] "^msg^"\n");
	val (tree, rem) = CDC160Parser.parse
			      (15,
			       (CDC160Parser.makeLexer grab fileName),
			       printError,
			       fileName)
			  handle CDC160Parser.ParseError => raise CDC160Error;
	(* Close the source program file *)
	val _ = TextIO.closeIn inStream;
    in
	tree
    end
fun load (D.Instructions(ins)) =
    let fun combineInstr (w1:word) (w2:word) = (Word.orb(Word.<<(w1,0wx6), w2))
	fun extract [] = []
	  | extract (i::is) =
	    case i
	     of 
		D.Instr(W1, W2) => ((combineInstr W1 W2) :: extract is)
	      | D.InstrLong(W1, W2, W3) => ( ((combineInstr W1 W2)) :: W3 :: extract is)
    in
	Array.fromList (extract ins)
    end
fun main (fileName : string) = load(compile(fileName))
end;
