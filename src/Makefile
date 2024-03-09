CC=i686-w64-mingw32-gcc -O2 -fexec-charset=cp932 -Wall
#CC=x86_64-w64-mingw32-gcc -O2 -fexec-charset=cp932 -Wall

.SUFFIXES: .asm .rom

all: sg1000 SG1000.DAT

sg1000: sg1000.c loader.h
	$(CC) -o $@ $<
	strip $@

SG1000.DAT: SG1000.DAT.rom
	cp -f $< $@

.asm.rom:
	zasm --z80 -l0 -i $< -o $@

.rom.h:
	xxd -i $< | sed "s/unsigned char/const uint8_t/;/unsigned int/d" > $@

clean:
	$(RM) sg1000 loader.h loader.rom SG1000.DAT SG1000.DAT.rom
