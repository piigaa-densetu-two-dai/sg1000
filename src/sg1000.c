#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "loader.h"
#include "loader48.h"

typedef struct {
	uint8_t org;
	uint8_t mod;
	uint16_t addr;
} __attribute__((packed)) patch_t;

static uint8_t get_patch(FILE *fp, patch_t *patch)
{
	uint8_t cnt;

	if (fread(&cnt, 1, 1, fp) != 1) {
		return 0;
	}
	if (fread(patch, 4, cnt, fp) != cnt) {
		return 0;
	}
	return cnt;
}

static void patch_vdp(uint8_t *rom, uint32_t size)
{
	uint32_t i;
	/* mingwにはmemmem()が無い模様 */
	for (i = 0 ; i < (size - 1) ; i++) {
		if ((rom[i] == 0xdb) && (rom[i + 1] == 0xbe)) { /* IN 0xbe */
			rom[i + 1] = 0x98;
		}
		if ((rom[i] == 0xd3) && (rom[i + 1] == 0xbe)) { /* OUT 0xbe */
			rom[i + 1] = 0x98;
		}
		if ((rom[i] == 0xdb) && (rom[i + 1] == 0xbf)) { /* IN 0xbf */
			rom[i + 1] = 0x99;
		}
		if ((rom[i] == 0xd3) && (rom[i + 1] == 0xbf)) { /* OUT 0xbf */
			rom[i + 1] = 0x99;
		}
	}
}

int main(int argc, char *argv[])
{
	uint8_t rom[1024 * 56];
	struct stat st;
	FILE *fp;
	uint8_t cnt, i;
	patch_t patch[256];

	if (argc != 3) {
		fprintf(stderr, "～ ピーガー伝説のSG1000 ～\n");
		fprintf(stderr, "使い方: %s <SGファイル> <ROMファイル>\n", argv[0]);
		return 1;
	}

	memset(rom, 0x00, sizeof(rom));

	if (stat(argv[1], &st)) {
		perror(argv[0]);
		return 1;
	}
	if (st.st_size > (1024 * 48)) {
		fprintf(stderr, "%s: サイズオーバーですぞ\n", argv[1]);
		return 1;
	}
	if (!(fp = fopen(argv[1], "rb"))) {
		perror(argv[0]);
		return 1;
	}
	if (fread(rom, 1, sizeof(rom), fp) == 0) {
		return 1;
	}
	fclose(fp);

	/* VDPパッチ */
	patch_vdp(rom, sizeof(rom));

	if (!(fp = fopen("SG1000.DAT", "rb"))) {
		perror(argv[0]);
		return 1;
	}
	while ((cnt = get_patch(fp, patch))) {
		for (i = 0 ; i < cnt ; i++) { /* パッチが適合するかを確認 */
			if (rom[patch[i].addr - 0x1000] != patch[i].org) {
				break;
			}
		}
		if (i != cnt) { /* 適合しない */
			continue;
		}
		/* 個別パッチ */
		for (i = 0 ; i < cnt ; i++) {
			rom[patch[i].addr - 0x1000] = patch[i].mod;
		}
		/* ローダー追加 */
		memmove(&rom[0x8200], &rom[0x8000], 0x4000);
		memset(&rom[0x8000], 0xff , 0x0200);
		if (st.st_size > (1024 * 40)) {
			memcpy(&rom[0x8000], loader48_rom, sizeof(loader48_rom));
		} else {
			memcpy(&rom[0x8000], loader_rom, sizeof(loader_rom));
		}
		break;
	}
	fclose(fp);
	if (cnt == 0) {
		fprintf(stderr, "%s: 対応パッチがありません。。。\n", argv[1]);
		return 1;
	}

	if (!(fp = fopen(argv[2], "wb"))) {
		perror(argv[0]);
		return 1;
	}
	if (fwrite(rom, 1, sizeof(rom), fp) != sizeof(rom)) {
		perror(argv[0]);
		return 1;
	}
	fclose(fp);

	fprintf(stderr, "%s: 変換完了\n", argv[1]);

	return 0;
}
