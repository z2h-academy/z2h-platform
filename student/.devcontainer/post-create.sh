#!/usr/bin/env bash
set -e

echo "🔧 Post-create: Inicializando entorno K3D-LAKEHOUSE..."

#######################################################
# 1. VERIFICAR TOKEN
#######################################################
if [[ -z "$K3D_TOKEN" ]]; then
    echo "❌ ERROR: No existe la variable K3D_TOKEN."
    echo "Por favor agrega el token temporal de acceso:"
    echo ""
    echo "   Codespaces  →  Settings → Secrets → Add Secret"
    echo "   Gitpod      →  Variables → Add Variable"
    echo ""
    exit 1
fi

#######################################################
# 2. VALIDAR TOKEN CONTRA GHCR (HEAD request)
#######################################################
echo "🔐 Validando token..."

VALID=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $K3D_TOKEN" \
    https://ghcr.io/v2/)

if [[ "$VALID" != "200" ]]; then
    echo "❌ Token inválido o expirado."
    echo "Solicita un nuevo token al instructor."
    exit 1
fi

echo "✅ Token válido."


#######################################################
# 3. INSTALAR K3D
#######################################################
echo "📦 Instalando k3d..."

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "✅ k3d instalado."


#######################################################
# 4. CREAR CLUSTER SI NO EXISTE
#######################################################
CLUSTER_NAME="z2h"

if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo "ℹ️ Cluster '$CLUSTER_NAME' ya existe."
else
    echo "🔨 Creando cluster '$CLUSTER_NAME'..."
    k3d cluster create "$CLUSTER_NAME" \
        --agents 0 \
        --api-port 6443 \
        --port 8080:80@loadbalancer \
        --wait
    echo "✅ Cluster creado."
fi


#######################################################
# 5. AUTENTICAR DOCKER CLIENT → GHCR
#######################################################
echo "🔐 Autenticando docker con GHCR..."

echo "$K3D_TOKEN" | docker login ghcr.io -u USERNAME_PLACEHOLDER --password-stdin

echo "✅ Autenticação correcta."


#######################################################
# 6. TRAER IMÁGENES PRIVADAS (SIN EXHIBIR NOMBRES)
#######################################################
echo "📥 Descargando imágenes necesarias..."

# IMPORTANTE:
# aquí NO mostramos los nombres reales
# solo un mensaje genérico
# (los nombres se agregan en el runtime final)

IMAGES=(
    "ghcr.io/MYORG/MY-IMAGE-1:latest"
    "ghcr.io/MYORG/MY-IMAGE-2:latest"
)

for img in "${IMAGES[@]}"; do
    echo "   🔹 Importando imagen..."
    docker pull "$img"
    k3d image import "$img" -c "$CLUSTER_NAME"
done

echo "✅ Imágenes importadas."


#######################################################
# 7. MENSAJE FINAL
#######################################################
echo ""
echo "🎉 Entorno completado."
echo "Puedes ejecutar:"
echo ""
echo "   kubectl get pods -A"
echo ""
echo "para verificar el estado del cluster."
