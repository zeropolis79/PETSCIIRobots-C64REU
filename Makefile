ACME=acme

PROGS	= boot-64x

all: $(PROGS)

boot-64x: boot.asm
	$(ACME) $<

boot.asm: loader.sym
loader.sym: hrintro.sym mcbackground.sym mcendgame.sym \
	hrfont.sym mcfont.sym hrsprites.sym mcweapons.sym \
	mcitems.sym mcfaces.sym mctiles.sym game.sym loader.asm 

%.sym: %.asm
	$(ACME) $< || rm $@

clean:
	rm -f *.sym boot-64x game-64x hrfont-64x hrintro-64x \
		hrsprites-64x loader-64x mcbackground-64x mcendgame-64x \
		mcfaces-64x mcfont-64x mcitems-64x mctiles-64x mcweapons-64x

check: all
	@echo "Verifying checksums....(you should look for errors below)"
	@./checksum.sh

