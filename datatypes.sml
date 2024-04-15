signature DATATYPES =
sig datatype Instr = Instr of word * word
		   | InstrLong of word * word * word
	 and Instructions = Instructions of Instr list
end;

structure DataTypes : DATATYPES =
struct
datatype Instr = Instr of word * word
	       | InstrLong of word * word * word
	and Instructions = Instructions of Instr list	      
end;
