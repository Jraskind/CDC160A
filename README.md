# CDC160A
Toy Emulator of the CDC160A
## Architecture
![CDC160A Architecture](./images/architecture.png "CDC160A Architecture")

## Instructions
(Note: I have only included a subset of instructions provided by the CDC160A manual)
All codes are in the original octal format. A word is 12-bits. Codes take up one word unless they have a G component, in which case they take up two words.
XX refers to a 6-bit constant 
XXXX refers to a 12-bit constant
YYYY refers to a 12-bit memory address
| OPCODE | F | E | G | Description |
| --- | -- | -- | ------ | ---------- |
| NOP | 00 | 0X | ____ | No operation |
| ERR | 00 | 00 | ____ | Throws an ERROR to Screen |
| HLT | 77 | 00 | ____ | Terminates the session |
| PTA | 01 | 01 | ____ | Transfer P to A |
| LDN | 04 | XX | ____ | Load XX into A |
| LDD | 20 | XX | ____ | Load (d)XX into A |
| LDM | 21 | 00 | YYYY | Load (i)YYYY into A |
| LDI | 21 | XX | ____ | Load (i)((d)XX) into A |
| LDC | 22 | 00 | YYYY | Load YYYY into A |
| LDF | 22 | XX | ______ | Load (r)(P + XX) into A |
| LDB | 23 | XX | ______ | Load (r)(P - XX) into A |