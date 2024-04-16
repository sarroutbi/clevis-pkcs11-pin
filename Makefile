.PHONY: install test all clean dracut_clean dracut_install

DRACUT_TARGET_DIR?=/usr/lib/dracut/modules.d/99clevis-pkcs11-dracut
DRACUT_PCSCD_TARGET_DIR?=/usr/lib/dracut/modules.d/99pcscd-cryptsetup
ENCRYPTED_DEVICE?=/dev/nvme0n1p2
CLEVIS_SLOT?=1
PIN?=123456

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
	@echo "--------------------------------------------------------------------------------"
	pkcs11-tool -pkcs11-tool --login --test -p "$(PIN)"-login --test -p $(PIN)
	@echo "--------------------------------------------------------------------------------"
	test -b $(ENCRYPTED_DEVICE) && clevis luks list -d $(ENCRYPTED_DEVICE) -s $(CLEVIS_SLOT)
	@echo "--------------------------------------------------------------------------------"
	test -b $(ENCRYPTED_DEVICE) && clevis luks pass -d $(ENCRYPTED_DEVICE) -s $(CLEVIS_SLOT)
	@echo
	@echo "--------------------------------------------------------------------------------"
