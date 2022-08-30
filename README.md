# Computer Architecture projects

## Project 1
Write a program in RISC-V assembly using [RARS](https://github.com/TheThirdOne/rars) simulator:

Write a C language source preprocessor, removing the digit separators in numeric constants supported in the new C2x standard (like 123’456, 0x12’34’56’78) to make the source compatible with compilers supporting the older standards. The program should not change the comments and strings.

## Project 2
Write a program containing two source files: main program written in C and assembly module callable from C. Use NASM assembler (nasm.sf.net) to assemble the assembly module.\
The program should be implemented in two versions: 32-bit and 64-bit, conforming to the respective Unix calling convention.

```C
void filter(void *img, int width, int height, unsigned char *mtx;
```
Filter a 24 bpp .BMP using 3×3 matrix filter. Coefficients of a filter are given as 8-bit fixed point unsigned numbers in 0.8 format, representing fractions from 0/256 to 255/256, which are entered as integers in range 0..255. The matrix may be hard coded in C program.

### Project 2 results
Before
<img src="https://raw.githubusercontent.com/TheDoom-IT/Computer-Architecture-projects/master/Project2/images/image.bmp" width="200"/>

After
<img src="https://raw.githubusercontent.com/TheDoom-IT/Computer-Architecture-projects/master/Project2/images/output.bmp" width="200"/>
