CC=i686-w64-mingw32-gcc -O2 -fexec-charset=cp932 -Wall

.SUFFIXES: .rel .ihx .bin

all: sg1000 loader.bin

sg1000: sg1000.c loader.h
	$(CC) -o $@ $<
	strip $@

.s.rel:
	sdasz80 -o $<

.rel.ihx:
	sdldz80 -i $<

.ihx.bin:
	objcopy -I ihex -O binary $< $@

.bin.h:
	xxd -i $< | sed "s/unsigned char/const uint8_t/;/unsigned int/d" > $@

clean:
	$(RM) loader.bin loader.h loader.ihx loader.rel sg1000
