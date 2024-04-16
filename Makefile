.PHONY: install test all clean dracut_clean dracut_install

DRACUT_TARGET_DIR?=/usr/lib/dracut/modules.d/99clevis-pkcs11-dracut
DRACUT_PCSCD_TARGET_DIR?=/usr/lib/dracut/modules.d/99pcscd-cryptsetup

all:
	@true

clean:
	@true

install:
	cp -rfav *-pkcs11 /usr/bin/

dracut_install:
	cp -rfav dracut/* $(DRACUT_TARGET_DIR)/

dracut_pcscd_install:
	test -d $(DRACUT_PCSCD_TARGET_DIR)/ || mkdir -p $(DRACUT_PCSCD_TARGET_DIR)/
	cp -rfav dracut-pcscd-cryptsetup/* $(DRACUT_PCSCD_TARGET_DIR)/

dracut_clean:
	rm -rfv $(DRACUT_TARGET_DIR)/*

dracut_pcscd_clean:
	rm -rfv $(DRACUT_PCSCD_TARGET_DIR)/*

check: test
	@true

test:
	echo secret | clevis encrypt pkcs11 '{}' | clevis decrypt
