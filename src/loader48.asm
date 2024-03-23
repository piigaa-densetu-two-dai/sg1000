TMP	equ	0xc200
RAM	equ	0xc201

	org	0x8000

top:
	; ROMヘッダ
	.db #0x41, #0x42, #0x10, #0x80, #0x00, #0x00, #0x00, #0x00
	.db #0x00, #0x00, #0x00, #0x00, #0x00, #0x00, #0x00, #0x00

#include "init.asm"

	; ページ2のRAMを検索
	ld	a, #0x00
	ld	hl, #0x8000
search:
	push	hl
	push	de
	push	af
	call	0x0c		; RD
	cpl
	ld	(TMP), a
	pop	af
	pop	de
	pop	hl
	push	hl
	push	de
	push	af
	ld	a, (TMP)
	ld	e, a
	pop	af
	push	af
	call	0x14		; WR
	pop	af
	pop	de
	pop	hl
	push	hl
	push	de
	push	af
	call	0x0c		; RD
	ld	b, a
	ld      a, (TMP)
	cp	b
	jr	z, break
	pop	af
	pop	de
	pop	hl
	inc	a
	jr	nz, search
	jr	out
break:
	pop	af
	pop	de
	pop	hl
out:
	ld	(RAM), a

	; このコードを裏RAMにコピー
	ld      hl, #0x8000
	ld      de, #0x8000
	ld      bc, end - top
copy1:
	push	hl
	push	de
	push	bc
	ld	a, (de)
	ld	e, a
	ld	a, (RAM)
	call	0x14
	pop	bc
	pop	de
	pop	hl
	inc	hl
	inc	de
	dec	bc
	ld	a, b
	or	c
	jr	nz, copy1

	; ページ2をRAMに、ページ3をこのROMに設定
	in	a, (0xa8)
	ld	(TMP), a
	ld	a, (RAM)
	ld	h, #0b10000000
	call	0x24
	ld	a, (TMP)
	ld	b, a
	and	#0b00110000
	rlca
	rlca
	ld	c, a
	in	a, (0xa8)
	and	#0x3f
	or	a, c
	out	(0xA8), a
	ld	a, b

	; ROMの0xc000-0xc1ffをRAMの0xbe00-0xbfffにコピー
	ld	hl, #0xc000
	ld	de, #0xbe00
	ld	bc, #0x0200
	ldir

	; スロットを元に戻す
	out	(0xA8), a

	; このコードをページ3にコピー
	ld	hl, #0x8000
	ld	de, #0xc000
	ld	bc, end - top
	ldir

	; ページ3のコードへ
	jp	page3 + 0x4000

page3:	; ページ3上で行なう処理
	; ROMの0x8200-0xbfffをRAMの0x8000-0xbdffにコピー
	ld      de, #0x8200
	ld      hl, #0x8000
	ld      bc, #0x3e00
copy2:
	push	hl
	push	de
	push	bc
	ld	a, (de)
	ld	e, a
	ld	a, (RAM)
	call	0x14
	pop	bc
	pop	de
	pop	hl
	inc	hl
	inc	de
	dec	bc
	ld	a, b
	or	c
	jr	nz, copy2

start:
	; ページ0,1をこのROMに、ページ2をRAMに設定
	in	a, (0xa8)
	ld	(TMP), a
	ld	a, (RAM)
	ld	h, #0b10000000
	call	0x24
	ld	a, (TMP)
	and	a, #0b00110000
	rrca
	rrca
	ld	b, a
	rrca
	rrca
	or	a, b
	ld	b, a
	in	a, (0xa8)
	and	a, #0xf0
	or	a, b
	out	(0xa8), a

	; ジョイスティック1選択
	ld	a, #15
	out	(0xa0), a
	in	a, (0xa2)	; Read register 15
	and	#0b10001111
	out	(0xa1), a	; Select Joystick port 1
	ld	a, #14
	out	(0xa0), a	; Set register 14 as accessible

	; ジョイスティック関数を0xf420に配置
	ld	hl, joypad1 + 0x4000
	ld	de, #0xf420
	ld	bc, end - joypad1
	ldir

	; ロム起動
	di
	im	0
	ld	sp, #0xfffe
	rst	0

joypad1:			; Start at 0F420h
	push	bc
	ld	a, #15
	out	(0xa0), a
	in	a, (0xa2)	; Read register 15
	and	#0b10001111
	out	(0xa1), a	; Select Joystick port 1
	ld	a, #14
	out	(0xa0), a
	in	a, (0xa2)	; Read register 14
	and	#0x3f
	ld	b, a
	ld	a, #15
	out	(0xa0), a
	in	a, (0xa2)	; Read register 15
	or	#0b01000000
	out	(0xa1), a	; Select Joystick port 2
	ld	a, #14
	out	(0xa0), a
	in	a, (0xa2)	; Read register 14
	rra
	rra
	rra
	and	#0xc0
	or	b
	pop	bc
	ret

joypad2:			; Start at 0F44Ch
	in	a, (0xa2)	; Read register 14
	rra
	rra
	or	#0xf0
	ret

end:
