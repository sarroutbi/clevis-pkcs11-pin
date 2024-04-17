.PHONY: install test all clean dracut_clean dracut_install list

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
	-(cd / ; sudo patch -N -p0) < clevis-luks-askpass.patch

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

test: clevis-encrypt-test pkcs-tool-test clevis-luks-list-test clevis-luks-pass-test
	@true

clevis-encrypt-test:
	@echo "--------------------------------------------------------------------------------"
	echo secret | clevis encrypt pkcs11 '{}' | clevis decrypt

pkcs-tool-test:
	@echo "--------------------------------------------------------------------------------"
	pkcs11-tool -pkcs11-tool --login --test -p "$(PIN)"-login --test -p $(PIN)

clevis-luks-list-test:
	@echo "--------------------------------------------------------------------------------"
	test -b $(ENCRYPTED_DEVICE) && clevis luks list -d $(ENCRYPTED_DEVICE) -s $(CLEVIS_SLOT)

clevis-luks-pass-test:
	@echo "--------------------------------------------------------------------------------"
	test -b $(ENCRYPTED_DEVICE) && clevis luks pass -d $(ENCRYPTED_DEVICE) -s $(CLEVIS_SLOT)
	@echo

list: opensc-tool-info pkcs11-tool-info

opensc-tool-info:
	@echo "--------------------------------------------------------------------------------"
	opensc-tool -l
	@echo "--------------------------------------------------------------------------------"
	opensc-tool -a

pkcs11-tool-info:
	@echo "--------------------------------------------------------------------------------"
	pkcs11-tool --show-info
	@echo "--------------------------------------------------------------------------------"
	pkcs11-tool -L
	@echo "--------------------------------------------------------------------------------"
	pkcs11-tool -M
