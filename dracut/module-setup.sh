#!/usr/bin/bash

depends() {
    echo clevis
    return 255
}

install() {
    inst_hook initqueue/online 60 "${moddir}/clevis-pkcs11-hook.sh"
    inst_hook initqueue/settled 60 "${moddir}/clevis-pkcs11-hook.sh"

    inst_multiple \
        pcscd \
        /usr/lib64/pcsc/drivers/ifd-ccid.bundle/Contents/Linux/libccid.so \
        /usr/lib64/pcsc/drivers/ifd-ccid.bundle/Contents/Info.plist \
        /usr/lib64/libykcs11.so.2 \
        /usr/lib64/opensc-pkcs11.so \
        /usr/lib64/pkcs11/opensc-pkcs11.so \
        pkcs11-tool \
        clevis-decrypt-pkcs11

    dracut_need_initqueue
}
