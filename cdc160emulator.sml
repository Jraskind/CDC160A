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
	fun decode line = (Word.>>(Word.andb(line,0wxfc0), 0wx6),Word.andb(line,0wx03f));
	fun getComplement w = Word.andb(Word.notb(w), 0wxfff);
	fun leftshift w n =
	    let val shifted = Word.<<(w, Word.fromInt n)
	    in
		if shifted > 0wxfff then Word.andb(Word.orb(shifted, Word.>>(shifted, 0wxC)), 0wxfff) else shifted		
	    end
	fun isPositive w = (w >= 0wx800 andalso w < 0wxfff)
	fun CDCPrint w = (if w>=0wxfff then print( (Int.toString (~(Word.toInt (getComplement(w)))))^"\n")  else (print ((Int.toString (Word.toInt(w)))^"\n")))
	fun execute (rb, db, ib, P, A) =
	    let
		val (F, E) = decode (Array.sub (rb, Word.toInt P)) (*Decode the word at P*)
	    in
		(* print("DEBUG: "^Word.toString(F)^" "^Word.toString(E)^"\n"); *)
		case F 
		 of
		    0wx00 =>
		    (case E
		      of
			 (*ERR*)
			 0wx00 => (print "ERROR RAISED --- TERMINATING EXECUTION\n";())
		       (*NOP*) 
		       | _ => (execute (rb, db, ib, P+0wx1, A)) 
		    )
		  (*HLT*)
		  | 0wx3F => (print "HALTING EXECUTION\n"; ())
		  (*PTA/MUL/LSX/RSX/PRT*)
		  | 0wx01 => (case E
			       of
				  (*PTA*)
				  0wx1 => (execute(rb, db, ib, P+0wx1, P))
				(*MUL*)
				| 0wxA => (execute(rb,db,ib,P+0wx1,Word.andb(A*0wxA, 0wxfff)))
				(*MUH*)
				| 0wxB => (execute(rb,db,ib,P+0wx1,Word.andb(A*0wx64, 0wxfff)))
				(*LS1*)
				| 0wx02 => (execute(rb,db,ib,P+0wx1, leftshift A 1))
				(*LS2*)
				| 0wx03 => (execute(rb,db,ib,P+0wx1, leftshift A 2))
				(*LS3*)
				| 0wx08 => (execute(rb,db,ib,P+0wx1, leftshift A 3))
				(*LS6*)
				| 0wx09 => (execute(rb,db,ib,P+0wx1, leftshift A 6))
				(*RS1*)
				| 0wx0C => (execute(rb,db,ib,P+0wx1, Word.>>(A,0wx1)))
				(*RS2*)
				| 0wx0D => (execute(rb,db,ib,P+0wx1, Word.>>(A,0wx2)))
				(*PRT*)
				| 0wx04 => (CDCPrint A; execute(rb,db,ib,P+0wx1,A))
				| _ =>  (print "INCORRECT INSTRUCTION -- TERMINATING EXECUTION"; ())
			     )
		  (*LDN*)
		  | 0wx04 => (execute(rb,db,ib,P+0wx1,E))
		  (*LDD*)
		  | 0wx10 => (execute(rb,db,ib,P+0wx1,Array.sub(db, Word.toInt E)))
		  (*LDM/I*)
		  | 0wx11 => (case E
			       of
				  (*LDM*)
				  0wx00 => (execute(rb,db,ib,P+0wx2,Array.sub(ib, Word.toInt (Array.sub(rb, Word.toInt (P+0wx1))))))
				(*LDI*)
				| _ => (execute(rb,db,ib,P+0wx1,Array.sub(ib, Word.toInt (Array.sub(db, Word.toInt(E)))))) 
			     )
		  (*LDC/F*)
		  | 0wx12 => (case E
			      of
				 (*LDC*)
				 0wx00 => (execute(rb,db,ib,P+0wx2,Array.sub(rb, Word.toInt(P+0wx1))))
			       (*LDF*)
			       | _ => (execute(rb,db,ib,P+0wx1,Array.sub(rb, Word.toInt(P+E))))
			     )
		  (*LDB*)
		  | 0wx13 => (execute(rb,db,ib,P+0wx1,Array.sub(rb, Word.toInt(P-E))))
		  (*LCN*)
		  | 0wx05 => (execute(rb,db,ib,P+0wx1,getComplement E))
		  (*LCD*)
		  | 0wx14 => (execute(rb,db,ib,P+0wx1,getComplement (Array.sub(db, Word.toInt E))))
		  (*LCM/I*)
		  | 0wx15 => (case E
			       of
				  (*LCM*)
				  0wx00 => (execute(rb,db,ib,P+0wx2, getComplement (Array.sub(ib, Word.toInt (Array.sub(rb, Word.toInt (P+0wx1)))))))
				(*LCI*)
				| _ => (execute(rb,db,ib,P+0wx1, getComplement (Array.sub (ib, Word.toInt (Array.sub(db, Word.toInt(E))))))) 
			     )
		  (*LCC/F*)
		  | 0wx16 => (case E
			      of
				 (*LCC*)
				 0wx00 => (execute(rb,db,ib,P+0wx2, getComplement (Array.sub(rb, Word.toInt(P+0wx1)))))
			       (*LCF*)
			       | _ => (execute(rb,db,ib,P+0wx1, getComplement (Array.sub(rb, Word.toInt(P+E)))))
			     )
		  (*LCB*)
		  | 0wx17 => (execute(rb,db,ib,P+0wx1, getComplement (Array.sub(rb, Word.toInt(P-E)))))
		  (*STD*)
		  | 0wx20 => (Array.update (db,Word.toInt E,A); execute(rb,db,ib,P+0wx1,A))
		  (*STM/I*)
		  | 0wx21 => (case E
			       of
				  (*STM*)
				  0wx00 => (Array.update(ib,(Word.toInt (Array.sub(ib, (Word.toInt (Array.sub(rb,Word.toInt (P+0wx1))))))) ,A); execute(rb,db,ib,P+0wx2,A))
				(*STI*)
				| _ => ( Array.update(ib,Word.toInt (Array.sub(db, Word.toInt E)),A); execute(rb,db,ib,P+0wx1,A))
			     )
		  (*STC/F*)
		  | 0wx22 => (case E
			       of
				  (*STC*)
				  0wx00 => (Array.update(ib, Word.toInt P, Array.sub(rb, Word.toInt(P+0wx1))) ; execute(rb,db,ib,P+0wx2,A))
				(*STF*)
				| _ => (Array.update(rb, Word.toInt(P+E), A) ; execute(rb,db,ib,P+0wx1,A)) 
			     )
		  (*STB*)
		  | 0wx23 => (Array.update(rb, Word.toInt(P-E), A) ; execute(rb,db,ib,P+0wx1,A))
		  (*ADN*)
		  | 0wx06 => (execute(rb,db,ib,P+0wx1,Word.andb(A+E, 0wxfff)))
		  (*ADD*)
		  | 0wx18 => (execute(rb,db,ib,P+0wx1,Word.andb(A+(Array.sub(db,Word.toInt(E))),0wxfff)))
		  (*ADM/I*)
		  | 0wx19 => (case E
			       of
				  (*ADM*)
				  0wx00 => (execute(rb,db,ib,P+0wx2,Word.andb(A+(Array.sub(ib,Word.toInt(Array.sub(rb, Word.toInt(P+0wx1))))),0wxfff)))
				(*ADI*)
				| _ => (execute(rb,db,ib,P+0wx1,Word.andb(A+(Array.sub(ib,Word.toInt(Array.sub(db, Word.toInt(E))))),0wxfff)))
			     )
		  (*ADC/F*)
		  | 0wx1A => (case E
			       of
				  (*ADC*)
				  0wx00 => (execute(rb,db,ib,P+0wx2, Word.andb(A+(Array.sub(rb, Word.toInt(P+0wx1))), 0wxfff)))
				(*ADF*)
				| _ => (execute(rb,db,ib,P+0wx1, Word.andb(A+(Array.sub(rb, Word.toInt(P+E))),0wxfff)))
			     )
		  (*ADB*)
		  | 0wx1B => (execute(rb,db,ib,P+0wx1, Word.andb(A+(Array.sub(rb, Word.toInt(P-E))),0wxfff)))
		  (*SBN*)
		  | 0wx07 => (execute(rb,db,ib,P+0wx1,Word.andb(A-E, 0wxfff)))
		  (*SBD*)
		  | 0wx1C => (execute(rb,db,ib,P+0wx1,Word.andb(A-(Array.sub(db,Word.toInt(E))),0wxfff)))
		  (*SBM/I*)
		  | 0wx1D => (case E
			       of
				  (*SBM*)
				  0wx00 => (execute(rb,db,ib,P+0wx2,Word.andb(A-(Array.sub(ib,Word.toInt(Array.sub(rb, Word.toInt(P+0wx1))))),0wxfff)))
				(*SBI*)
				| _ => (execute(rb,db,ib,P+0wx1,Word.andb(A-(Array.sub(ib,Word.toInt(Array.sub(db, Word.toInt(E))))),0wxfff)))
			     )
		  (*SBC/F*)
		  | 0wx1E => (case E
			       of
				  (*SBC*)
				  0wx00 => (execute(rb,db,ib,P+0wx2, Word.andb(A-(Array.sub(rb, Word.toInt(P+0wx1))), 0wxfff)))
				(*SBF*)
				| _ => (execute(rb,db,ib,P+0wx1, Word.andb(A-(Array.sub(rb, Word.toInt(P+E))),0wxfff)))
			     )
		  (*SBB*)
		  | 0wx1F => (execute(rb,db,ib,P+0wx1, Word.andb(A-(Array.sub(rb, Word.toInt(P-E))),0wxfff)))
		  (*LPN*)
		  | 0wx02 => (execute(rb,db,ib,P+0wx1,Word.andb(A,E)))
		  (*LPD*)
		  | 0wx8 => (execute(rb,db,ib,P+0wx1, Word.andb(A,Array.sub(ib, Word.toInt (Array.sub(ib, Word.toInt E))))))
		  (*LPM/I*)
		  | 0wx9 => (case E
			      of
				 0wx0 => (execute(rb,db,ib,P+0wx2, Word.andb(A, Array.sub(ib, Word.toInt (Array.sub(rb, Word.toInt (P+0wx1)))))))
			       | _ => (execute(rb,db,ib,P+0wx1,Word.andb(A, Array.sub(ib, Word.toInt(Array.sub(db, Word.toInt E))))))
			    )
		  (*LPC/F*)
		  | 0wxA => (case E
			      of
				 0wx0 => (execute(rb,db,ib,P+0wx2,Word.andb(A,(Array.sub(rb, Word.toInt (P+0wx1))))))
			       | _ => (execute(rb,db,ib,P+0wx1, Word.andb(A, (Array.sub(rb, Word.toInt(P+E))))))
			    ) 
		  (*LPB*)
		  | 0wxB => (execute(rb,db,ib,P+0wx1, Word.andb(A, (Array.sub(rb, Word.toInt(P-E))))))
		  (*SCN*)
		  | 0wx03 => (execute(rb,db,ib,P+0wx1,Word.xorb(A,E)))
		  (*SCD*)
		  | 0wxC => (execute(rb,db,ib,P+0wx1, Word.xorb(A,Array.sub(ib, Word.toInt (Array.sub(ib, Word.toInt E))))))
		  (*SCM/I*)
		  | 0wxD => (case E
			      of
				 0wx0 => (execute(rb,db,ib,P+0wx2, Word.xorb(A, Array.sub(ib, Word.toInt (Array.sub(rb, Word.toInt (P+0wx1)))))))
			       | _ => (execute(rb,db,ib,P+0wx1,Word.xorb(A, Array.sub(ib, Word.toInt(Array.sub(db, Word.toInt E))))))
			    )
		  (*SCC/F*)
		  | 0wxE => (case E
			      of
				 0wx0 => (execute(rb,db,ib,P+0wx2,Word.xorb(A,(Array.sub(rb, Word.toInt (P+0wx1))))))
			       | _ => (execute(rb,db,ib,P+0wx1, Word.xorb(A, (Array.sub(rb, Word.toInt(P+E))))))
			    ) 
		  (*SCB*)
		  | 0wxF => (execute(rb,db,ib,P+0wx1, Word.xorb(A, (Array.sub(rb, Word.toInt(P-E))))))
		  (*ZJF*)
		  | 0wx30 => (if A = 0wx0 then execute(rb,db,ib,P+E,A) else execute(rb,db,ib,P+0wx1,A))
		  (*NZF*)
		  | 0wx31 => (if A <> 0wx0 then execute(rb,db,ib,P+E,A) else execute(rb,db,ib,P+0wx1,A))
		  (*PJF*)
		  | 0wx32 => (if (isPositive A) then execute(rb,db,ib,P+E,A) else execute(rb,db,ib,P+0wx1,A))
		  (*NJF*)
		  | 0wx33 => (if (not (isPositive A)) then execute(rb,db,ib,P+E,A) else execute(rb,db,ib,P+0wx1,A))
		  (*ZJB*)
		  | 0wx34 => (if A = 0wx0 then execute(rb,db,ib,P-E,A) else execute(rb,db,ib,P+0wx1,A))
		  (*NZB*)
		  | 0wx35 => (if A <> 0wx0 then execute(rb,db,ib,P-E,A) else execute(rb,db,ib,P+0wx1,A))
		  (*PJB*)
		  | 0wx36 => (if (isPositive A) then execute(rb,db,ib,P-E,A) else execute(rb,db,ib,P+0wx1,A))
		  (*NJB*)
		  | 0wx37 => (if (not (isPositive A)) then execute(rb,db,ib,P-E,A) else execute(rb,db,ib,P+0wx1,A))
		  (*JPI*)
		  | 0wx38 => (execute(rb,db,ib, Array.sub (db, Word.toInt E),A))
		  (*JPR/JFI*)
		  | 0wx39 => (case E
			       of
				  0wx00 => (Array.update(rb, Word.toInt (Array.sub(rb, Word.toInt (P+0wx1))),P+0wx2); execute(rb,db,ib, Array.sub(rb, Word.toInt (P+0wx1)) + 0wx1,A))
				| _ => (execute(rb,db,ib, Array.sub(rb, Word.toInt(P+E)),A))
			     )  
		  | _ => ()
	    end
    in
	execute (rb, db, ib, P, A)
    end
end;
