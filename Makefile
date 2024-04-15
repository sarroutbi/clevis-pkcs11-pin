.PHONY: install test all clean

nothing:
	true

clean:
	true

install:
	cp -rfav *-pkcs11 /usr/bin/

test:
	echo secret | clevis encrypt pkcs11 '{}' | clevis decrypt
