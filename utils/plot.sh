#!/bin/bash
#
# Copyright (c) 2023, Sergio Arroutbi Braojos <sarroutbi (at) redhat.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
unit=default.target
destination=plot.svg

function usage() {
  echo ""
  echo "$1 [-u unit, default:default.target] [-d destination, default:plot.svg]"
  echo ""
  exit "$2"
}

while getopts "u:d:h" arg
do
  case "${arg}" in
    u) unit=${OPTARG}
       echo "unit=${unit}"
       ;;
    d) destination=${OPTARG}
       echo "destination=${destination}"
       ;;
    h) usage "$0" 0
       ;;
    *) usage "$0" 1
       ;;
  esac
done

systemd-analyze verify "${unit}" |& perl -lne 'print $1 if m{Found.*?on\s+([^/]+)}' \
    | xargs --no-run-if-empty systemd-analyze dot | dot -Tsvg > "${destination}"
