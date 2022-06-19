run:
	make build
	./output
assembly:
	nasm -f elf64 second.s -O0
link:
	cc -std=c99 -O0 -m64 -o output first.c second.o -g -lm

build:
	make assembly
	make link
	make clean
clean:
	rm second.o