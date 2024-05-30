#!/bin/bash
systemd-ask-password --id "clevis-pkcs11" --no-tty "PIN:" &
sleep 1
for file in $(ls /run/systemd/ask-password/ask.*); do
    cat "${file}"
    grep "Id=clevis-pkcs11" "${file}" || continue
    socket=$(grep 'Socket=' "${file}" | awk -F '=' '{print $2}')
    echo "Socket:${socket}"
    echo "123456" | /lib/systemd/systemd-reply-password 1 "${socket}"
done
