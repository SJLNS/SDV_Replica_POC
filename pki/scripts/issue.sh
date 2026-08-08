#!/usr/bin/env bash
# Run from anywhere — this always operates relative to the pki/ directory.
# Usage:
#   ./issue.sh init                      # generate root CA + 3 intermediate CAs (run once)
#   ./issue.sh leaf <ca> <cn> <outdir>    # issue a leaf cert, outdir is relative to pki/, e.g.:
#                                         #   ./issue.sh leaf hpc-ca hpc1 certs/hpc1
set -euo pipefail
cd "$(dirname "$0")/.."   # now running from pki/

init() {
  mkdir -p root-ca
  openssl genrsa -out root-ca/root-ca.key 4096
  openssl req -x509 -new -nodes -key root-ca/root-ca.key -sha256 -days 3650 \
    -out root-ca/root-ca.crt -subj "/CN=SDV_Replica_POC Root CA"

  for ca in zcu-ca hpc-ca cloud-ca; do
    mkdir -p "intermediate-ca/$ca"
    openssl genrsa -out "intermediate-ca/$ca/$ca.key" 4096
    openssl req -new -key "intermediate-ca/$ca/$ca.key" -out "intermediate-ca/$ca/$ca.csr" \
      -subj "/CN=SDV_Replica_POC $ca"
    openssl x509 -req -in "intermediate-ca/$ca/$ca.csr" -CA root-ca/root-ca.crt \
      -CAkey root-ca/root-ca.key -CAcreateserial -out "intermediate-ca/$ca/$ca.crt" \
      -days 1825 -sha256
    rm "intermediate-ca/$ca/$ca.csr"
  done
  echo "root + 3 intermediate CAs generated under pki/"
}

leaf() {
  local ca="$1" cn="$2" outdir="$3"
  mkdir -p "$outdir"
  openssl genrsa -out "$outdir/$cn.key" 2048
  openssl req -new -key "$outdir/$cn.key" -out "$outdir/$cn.csr" -subj "/CN=$cn"
  openssl x509 -req -in "$outdir/$cn.csr" -CA "intermediate-ca/$ca/$ca.crt" \
    -CAkey "intermediate-ca/$ca/$ca.key" -CAcreateserial \
    -out "$outdir/$cn.crt" -days 365 -sha256
  rm "$outdir/$cn.csr"
  echo "issued $outdir/$cn.crt (signed by $ca)"
}

case "${1:-}" in
  init) init ;;
  leaf) leaf "$2" "$3" "$4" ;;
  *) echo "usage: $0 {init | leaf <ca> <cn> <outdir>}" >&2; exit 1 ;;
esac
