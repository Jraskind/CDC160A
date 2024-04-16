structure D = DataTypes
structure CDC160 :
	  sig val compile: string -> D.Instructions
	      val load : D.Instructions -> word array
	      val emulate : string -> unit
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
	val program = (extract ins)
	val instruction_count = List.length program
    in
	Array.fromList (program @ List.tabulate(4096-instruction_count, (fn x => 0wx0)))
    end
fun emulate (fileName : string) =
    let
	val rb : word array = load(compile(fileName))
	val db : word array = Array.fromList (List.tabulate(4096, (fn x => 0wx0)))
	val ib : word array= Array.fromList (List.tabulate(4096, (fn x => 0wx0)))
	val P : word = 0wx0
	val A : word = 0wx0
	fun decode line = (Word.andb(line,0wxfc0),Word.andb(line,0wx03f));
	fun execute (rb, db, ib, P, A) =
	    let
		val (F, E) = decode (Array.sub (rb, Word.toInt P)) (*Decode the word at P*)
	    in
		case F 
		 of
		    0wx00 =>
		    (case E
		      of
			 0wx00 => (print "ERROR RAISED --- TERMINATING EXECUTION\n";())
		       | _ => (execute (rb, db, ib, P+0wx1, A)) (*NOP*) 
		    )	
		  | 0wx3F => (print "HALTING EXECUTION\n"; ())
		  | 0wx01 => (if E = 0wx01 then (execute(rb, db, ib, P+0wx1, P)) else (print "INCORRECT INSTRUCTION -- TERMINATING EXECUTION"; ())) (*PTA*)
		  | 0wx04 => (execute(rb,db,ib,P+0wx1,E)) (*LDN*) 
		  | _ => ()
	    end
    in
	execute (rb, db, ib, P, A)
    end
end;
