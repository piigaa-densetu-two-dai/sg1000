TMP	equ	0xc200
RAM	equ	0xc201

	org	0xc000

top:
	; ROMヘッダ
	.db #0x41, #0x42, #0x10, #0x80, #0x00, #0x00, #0x00, #0x00
	.db #0x00, #0x00, #0x00, #0x00, #0x00, #0x00, #0x00, #0x00

	; このコードをページ3にコピーして実行
	ld	hl, #0x8000
	ld	de, #0xc000
	ld	bc, end - top
	ldir
	jp	start

start:
	; 音声ミュート
	ld	a, #0x9f
	out	(0x7f), a
	ld	a, #0xbf
	out	(0x7f), a
	ld	a, #0xdf
	out	(0x7f), a
	ld	a, #0xff
	out	(0x7f), a

	; 画面設定
	ld	a, #0x00
	ld	(0xf3ea), a
	ld	(0xf3eb), a
	ld	a, #0x01
	call	0x005f

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

	; RAMにコピー
	ld      hl, #0x8000
	ld      de, #0x8200
	ld      bc, #0x2000
copy:
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
	jr	nz, copy

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
	ld	hl, joypad1
	ld	de, #0xf420
	ld	bc, end - joypad1
	ldir

	; ロム起動
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
