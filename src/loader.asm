	org 0x8000

	; ROMヘッダ
	.db #0x41, #0x42, #0x10, #0x80, #0x00, #0x00, #0x00, #0x00
	.db #0x00, #0x00, #0x00, #0x00, #0x00, #0x00, #0x00, #0x00

	; 音声ミュート
	ld	b, #4
	ld	a, #0x9f
Volume0:
	out	(0x7f), a	; Set the
	add	a, #0x20	; volume of SN76489AN
	djnz	Volume0		; to zero

	; 画面設定
	xor	a
	ld	(0xf3ea), a	; Border color = 0
	ld	(0xf3eb), a	; Border color = 0
	inc	a
	call	0x005f		; SCREEN 1 mode

	; page0,1をこのロムに設定
	in	a, (0xa8)
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
	ld	hl, Joypad1
	ld	de, #0xf420
	ld	bc, end - Joypad1
	ldir

	; ロム起動
	ld	sp, #0xffff
	rst	0

Joypad1:			; Start at 0F420h
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

Joypad2:			; Start at 0F44Ch
	in	a, (0xa2)	; Read register 14
	rra
	rra
	or	#0xf0
	ret

end:
