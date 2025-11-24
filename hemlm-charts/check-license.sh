#!/bin/sh
set -eu

LICENSE_DIR="/licenses"
LICENSE="${LICENSE_DIR}/license.pem"
SIG="${LICENSE_DIR}/license.sig"
PUB="${LICENSE_DIR}/public_key.pem"

# 1) Comprobar archivos
if [ ! -f "$LICENSE" ] || [ ! -f "$SIG" ] || [ ! -f "$PUB" ]; then
  echo "Falta archivo: license.pem, license.sig o public_key.pem" >&2
  exit 2
fi

# 2) Verificar firma (ED25519)
if ! openssl pkeyutl -verify \
    -pubin -inkey "$PUB" \
    -rawin \
    -in "$LICENSE" \
    -sigfile "$SIG" >/dev/null 2>&1; then

  echo "Firma inválida" >&2
  openssl pkeyutl -verify \
    -pubin -inkey "$PUB" \
    -rawin \
    -in "$LICENSE" \
    -sigfile "$SIG" || true

  exit 3
fi

# 3) Comprobar expiry
expire=$(grep '^expire=' "$LICENSE" | cut -d= -f2 || true)
if [ -z "$expire" ]; then
  echo "No se encontró expire en license.pem" >&2
  exit 4
fi

now=$(date +%s)
if [ "$now" -ge "$expire" ]; then
  echo "Licencia expirada (expire=$expire, ahora=$now)" >&2
  echo "expire legible: $(date -d @$expire || date -r $expire 2>/dev/null || true)"
  exit 5
fi

echo "Licencia válida (student_id=$(grep '^student_id=' "$LICENSE" | cut -d= -f2))."
exit 0
