#!/bin/bash
#
# Copyright (c) 2024 Red Hat, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# shellcheck disable=SC2154
#
depends() {
    echo clevis
    return 255
}

install() {
    inst_hook initqueue 60 "${moddir}/clevis-pkcs11-prehook.sh"
    inst_hook initqueue/settled 60 "${moddir}/clevis-pkcs11-hook.sh"
    inst_hook initqueue/online 60 "${moddir}/clevis-pkcs11-hook.sh"

    inst_multiple \
        pcscd \
        pkcs11-tool \
        head \
        socat \
        tail \
        tr \
        /usr/lib64/pcsc/drivers/ifd-ccid.bundle/Contents/Linux/libccid.so \
        /usr/lib64/pcsc/drivers/ifd-ccid.bundle/Contents/Info.plist \
        /usr/lib64/opensc-pkcs11.so \
        /usr/lib64/pkcs11/opensc-pkcs11.so \
        /usr/lib64/libopensc.so* \
        /etc/opensc.conf \
        /usr/lib64/ossl-modules/legacy.so \
        /lib64/libpcsclite.so.1 \
        /usr/libexec/clevis-luks-pkcs11-askpass \
        /usr/libexec/clevis-luks-pkcs11-askpin \
        clevis-luks-common-functions \
        clevis-pkcs11-afunix-socket-unlock \
        clevis-pkcs11-common \
        clevis-decrypt-pkcs11

    dracut_need_initqueue
}