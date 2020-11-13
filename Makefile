.PHONY: clear run

bf.rom: bf.s
	nasm -fbin bf.s -o bf.rom

run:
	qemu-system-x86_64 -fda bf.rom

clear:
	rm bf.rom
