.PHONY: install test all clean dracut_clean dracut_install

DRACUT_TARGET_DIR?=/usr/lib/dracut/modules.d/99clevis-pkcs11-dracut

all:
	true

clean:
	true

install:
	cp -rfav *-pkcs11 /usr/bin/

dracut_install:
	cp -rfav dracut/* $(DRACUT_TARGET_DIR)/

dracut_clean:
	rm -rfv $(DRACUT_TARGET_DIR)/*

check: test
	-true

test:
	echo secret | clevis encrypt pkcs11 '{}' | clevis decrypt
