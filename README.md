# CDC160A
Toy Emulator of the CDC160A
## Architecture
![CDC160A Architecture](./images/architecture.png "CDC160A Architecture")

The real CDC160A had a variety of extra registers that handle I/O, buffered data control, and overflow. Since I wrote this in SML with the power of a computer thousands of times faster than a CDC I chose to ignore those constraints (hence the "Toy" in "Toy Emulator"). We are only concerned with two registers: A and P. A is the arithmetic register (or accumulator) which is where all arithmetic computations take place. P is the program control register which stores the value of the current address in data bank (r).


## Instructions
(Note: I have only included a subset of instructions provided by the CDC160A manual)

All codes are in the original octal format. A word is 12-bits. Codes take up one word unless they have a G component, in which case they take up two words.

XX refers to a 6-bit constant 

XXXX refers to a 12-bit constant

YYYY refers to a 12-bit memory address

| OPCODE | F | E | G | Description |
| --- | -- | -- | ---- | ---------- |
| NOP | 00 | 0X | ____ | No operation |
| ERR | 00 | 00 | ____ | Throws an ERROR to Screen |
| HLT | 77 | 00 | ____ | Terminates the session |
| PTA | 01 | 01 | ____ | Transfer P to A |
| LDN | 04 | XX | ____ | Load XX into A |
| LDD | 20 | XX | ____ | Load (d)XX into A |
| LDM | 21 | 00 | YYYY | Load (i)YYYY into A |
| LDI | 21 | XX | ____ | Load (i)((d)XX) into A |
| LDC | 22 | 00 | XXXX | Load XXXX into A |
| LDF | 22 | XX | ____ | Load (r)(P + XX) into A |
| LDB | 23 | XX | ____ | Load (r)(P - XX) into A |
| LCN | 05 | XX | ____ | Load Complement XX into A |
| LCD | 24 | XX | ____ | Load Complement (d)XX into A |
| LCM | 25 | 00 | YYYY | Load Complement (i)YYYY into A |
| LCI | 26 | XX | ____ | Load Complement (i)((d)XX) into A |
| LCC | 26 | 00 | XXXX | Load Complement XXXX into A |
| LCF | 26 | XX | ____ | Load Complement (r)(P + XX) into A |
| LCB | 27 | XX | ____ | Load Complement (r)(P - XX) into A |
| STD | 40 | XX | ____ | Store A into (d)XX |
| STM | 41 | 00 | YYYY | Store A into (i)YYYY |
| STI | 41 | XX | ____ | Store A into (i)((d)XX) |
| STC | 42 | 00 | XXXX | Store A into (r)XXXX  |
| STF | 42 | XX | ____ | Store A into (r)(P + XX) |
| STB | 43 | XX | ____ | Store A into (r)(P - XX) |
| MUL | 01 | 12 | ____ | Multiply A by 10[^1] |
| MUL | 01 | 13 | ____ | Multiply A by 100[^2] |
| ADN | 06 | XX | ____ | Add XX to A |
| ADD | 30 | XX | ____ | Add (d)XX to A |
| ADM | 31 | 00 | YYYY | Add (i)YYYY to A |
| ADI | 31 | XX | ____ | Add (i)((d)XX) to A |
| ADC | 32 | 00 | XXXX | Add XXXX to A |
| ADF | 32 | XX | ____ | Add (r)(P + XX) to A |
| ADB | 33 | XX | ____ | Add (r)(P - XX) to A |
| SBN | 07 | XX | ____ | Subtract XX from A |
| SBD | 34 | XX | ____ | Subtract (d)XX from A |
| SBM | 35 | 00 | YYYY | Subtract (i)YYYY from A |
| SBI | 35 | XX | ____ | Subtract (i)((d)XX) from A |
| SBC | 36 | 00 | XXXX | Subtract XXXX from A |
| SBF | 36 | XX | ____ | Subtract (r)(P + XX) from A |
| SBB | 37 | XX | ____ | Subtract (r)(P - XX) from A |
| LS1 | 04 | XX | ____ | Left shift A by 1 bit[^3] |
| LS2 | 20 | XX | ____ | Left shift A by 2 bits |
| LS3 | 21 | 00 | YYYY | Left shift A by 3 bits |
| LS6 | 21 | XX | ____ | Left shift A by 6 bits |
| RS1 | 22 | 00 | XXXX | Right shift A by 1 bit |
| RS2 | 22 | XX | ____ | Right shift A by 2 bits |
| LPN | 02 | XX | ____ | Logical AND XX with A |
| LPD | 10 | XX | ____ | Logical AND (d)XX with A |
| LPM | 11 | 00 | YYYY | Logical AND (i)YYYY with A |
| LPI | 11 | XX | ____ | Logical AND (i)((d)XX) with A |
| LPC | 12 | 00 | XXXX | Logical AND XXXX with A |
| LPF | 12 | XX | ____ | Logical AND (r)(P + XX) with A |
| LPB | 13 | XX | ____ | Logical AND (r)(P - XX) with A |
| SCN | 03 | XX | ____ | Logical XOR XX with A[^5] |
| SCD | 14 | XX | ____ | Logical XOR (d)XX with A |
| SCM | 15 | 00 | YYYY | Logical XOR (i)YYYY with A |
| SCI | 15 | XX | ____ | Logical XOR (i)((d)XX) with A |
| SCC | 16 | 00 | XXXX | Logical XOR XXXX with A |
| SCF | 16 | XX | ____ | Logical XOR (r)(P + XX) with A |
| SCB | 17 | XX | ____ | Logical XOR (r)(P - XX) with A |
| ZJF | 60 | XX | ____ | Zero Jump Forward (P + XX) |
| NZF | 61 | XX | ____ | Non-Zero Jump Forward (P + XX) |
| PJF | 62 | XX | ____ | Positive Jump Forward (P + XX) |
| NJF | 63 | XX | ____ | Negative Jump Forward (P + XX) |
| ZJB | 64 | XX | ____ | Zero Jump Backward (P - XX) |
| NZB | 65 | XX | ____ | Non-Zero Jump Backward (P - XX) |
| PJB | 66 | XX | ____ | Positive Jump Backward (P - XX) |
| NJB | 67 | XX | ____ | Negative Jump Backward (P - XX) |
| JPI | 70 | XX | ____ | Jump Indirect[^6] |
| JPR | 71 | 00 | YYYY | Return Jump[^7] |
| JFI | 71 | XX | ____ | Jump Forward Indirect[^8] |
| PRT | 01 | 04 | ____ | Print Contents of A |

[^1]: For -314 (oct) to 314 (oct) the result will be correct. For A > +314 or A < -314 then result will be correct modulo 2^12^-1 (204 decimal).
[^2]: For -24 (oct) to 24 (oct) the result will be correct. For A > +24 or A < -24 then result will be correct modulo 2^12^-1 (204 decimal).
[^3]: Left shifts are circular. (400 << 1 => 001)
[^4]: Right shifts are not circular. (001 >> 1 => 000)
[^5]: The CDC160A manual calls this "Selective Complement".
[^6]: ((d)XX) => P
[^7]: (P) + 2 => (r)YYYY; YYYY+1 => P
[^8]: (r)(P + XX) => P