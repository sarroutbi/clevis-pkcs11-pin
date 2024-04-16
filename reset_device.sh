#!/bin/bash
YUBICO_HANDLER=ykman
PUBKEY_FILE=pubkey.pem
SUBJECT=clevis

"${YUBICO_HANDLER}" piv reset --force
"${YUBICO_HANDLER}" piv keys generate -a RSA2048 9d "${PUBKEY_FILE}"<<EOF

EOF
"${YUBICO_HANDLER}" piv certificates generate --subject "${SUBJECT}" 9d "${PUBKEY_FILE}"<<EOF

123456
EOF
"${YUBICO_HANDLER}" list
"${YUBICO_HANDLER}" piv info

rm -v "${PUBKEY_FILE}"
