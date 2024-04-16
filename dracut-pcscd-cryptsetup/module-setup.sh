#!/usr/bin/bash
##########################################################################################
# PROJET : Master Linux
# OBJET  : Construction d'un module d'integration du service PCSCD dans l'initrd
# AUTEUR : Miguel COSTA
# DATE   : 11/12/2023
# INFO   : Validé sur RHEL 9
#          https://github.com/VTimofeenko/dracut-pcscd-cryptsetup/blob/main/module-setup.sh
##########################################################################################
# called by dracut
check() {
    if ! dracut_module_included "systemd" || ! dracut_module_included "crypt"; then
        derror "pcscd module requires systemd in the initramfs and crypt"
        return 1
    fi
    require_binaries /usr/sbin/pcscd
    require_binaries /usr/lib/polkit-1/polkitd

    return 0
}

# called by dracut
install() {
    _install_pcscd
    _install_ccid
    _install_opensc
    _install_polkit
}

_install_pcscd() {
    inst_multiple /usr/sbin/pcscd
    inst_rules /lib/udev/rules.d/99-pcscd-hotplug.rules
    inst_multiple \
        "$systemdsystemunitdir"/pcscd.service \
        "$systemdsystemunitdir"/pcscd.socket \
        /usr/share/polkit-1/actions/org.debian.pcsc-lite.policy

    # Allow the service and socket start when cryptsetup wants them to
    mkdir -p "${initdir}/$systemdsystemunitdir/pcscd.service.d"
    (
        echo "[Unit]"
        echo "DefaultDependencies=no"
        echo "[Install]"
        echo "WantedBy=cryptsetup-pre.target"
    ) > "${initdir}/$systemdsystemunitdir/pcscd.service.d/dracut.conf"
    mkdir -p "${initdir}/$systemdsystemunitdir/pcscd.socket.d"
    (
        echo "[Unit]"
        echo "DefaultDependencies=no"
        echo "[Install]"
        echo "WantedBy=cryptsetup-pre.target"
    ) > "${initdir}/$systemdsystemunitdir/pcscd.socket.d/dracut.conf"
    systemctl -q --root "$initdir" enable pcscd.socket
    systemctl -q --root "$initdir" enable pcscd.service

    inst_libdir_file libpcsclite.so
}

_install_ccid() {
    inst_multiple \
        /usr/lib64/pcsc/drivers/ifd-ccid.bundle/Contents/Linux/libccid.so \
        /usr/lib64/pcsc/drivers/ifd-ccid.bundle/Contents/Info.plist

    inst_rules /lib/udev/rules.d/92-pcsc-ccid.rules
}

_install_opensc() {
    inst_libdir_file \
        opensc-pkcs11.so \
        onepin-opensc-pkcs11.so \
        libopensc.so

    inst_multiple \
        /usr/lib64/pkcs11/*

    inst_multiple \
        /etc/opensc.conf \
        /usr/bin/pkcs11-tool
}

_install_polkit() {
    inst_libdir_file \
      libpolkit-gobject-1.so.0

    inst_multiple \
         /usr/lib/polkit-1/polkitd \
         /usr/lib/systemd/system/polkit.service
#         /etc/dbus-1/system.d/org.freedesktop.PolicyKit1.conf
         
    mkdir -p "${initdir}/$systemdsystemunitdir/polkit.service.d"
    (
      echo "[Unit]"
      echo "DefaultDependencies=no"
      echo "[Install]"
      echo "WantedBy=cryptsetup-pre.target"
    ) > "${initdir}/$systemdsystemunitdir/polkit.service.d/dracut.conf"
    systemctl -q --root "$initdir" enable polkit.service
    grep -w "polkitd" /etc/passwd >> "${initdir}/etc/passwd"
    grep -w polkitd /etc/group    >> "${initdir}/etc/group"
}
