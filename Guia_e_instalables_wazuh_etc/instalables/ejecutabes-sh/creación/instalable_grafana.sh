
cat > instalar_grafana.sh <<'SCRIPT'
set -e # Detener ejecución si hay errores

VAR_PUERTO_GRAF=3000
VAR_USUARIO_ADMIN_GRAF="admin"
VAR_CONTRASENA_ADMIN_GRAF="SecretPassword"
VAR_NOMBRE_IMAGEN="grafana/grafana:latest"
VAR_NOMBRE_CONTENEDOR="grafana"
VAR_NOMBRE_NETWORK="single-node_default"
VAR_VOLUME_NAME="grafana_data"

# Colores para salida en consola
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}🛠️  Iniciando instalación optimizada de Grafana en Docker...${NC}"

if ! sudo docker network inspect "$VAR_NOMBRE_NETWORK" >/dev/null 2>&1; then
    echo -e "${YELLOW}🌐 Creando la red de Docker '${VAR_NOMBRE_NETWORK}'...${NC}"
    sudo docker network create "$VAR_NOMBRE_NETWORK"
fi

if ! sudo docker volume inspect "$VAR_VOLUME_NAME" >/dev/null 2>&1; then
    echo -e "${YELLOW}💾 Creando volumen de datos persistente '${VAR_VOLUME_NAME}'...${NC}"
    sudo docker volume create "$VAR_VOLUME_NAME"
fi

echo -e "${YELLOW}📦 Descargando imagen oficial de Grafana...${NC}"
sudo docker pull "$VAR_NOMBRE_IMAGEN"

if sudo docker ps -a --format '{{.Names}}' | grep -q "^${VAR_NOMBRE_CONTENEDOR}$"; then
    echo -e "${YELLOW}⚠️  Eliminando contenedor previo de Grafana...${NC}"
    sudo docker rm -f "$VAR_NOMBRE_CONTENEDOR"
fi

echo -e "${YELLOW}🚀 Desplegando contenedor de Grafana...${NC}"
sudo docker run -d \
  --name "$VAR_NOMBRE_CONTENEDOR" \
  --restart unless-stopped \
  --network "$VAR_NOMBRE_NETWORK" \
  -p "${VAR_PUERTO_GRAF}:3000" \
  -e "GF_SECURITY_ADMIN_USER=${VAR_USUARIO_ADMIN_GRAF}" \
  -e "GF_SECURITY_ADMIN_PASSWORD=${VAR_CONTRASENA_ADMIN_GRAF}" \
  -v "${VAR_VOLUME_NAME}:/var/lib/grafana" \
  "$VAR_NOMBRE_IMAGEN"

echo -e "${GREEN}✅ Grafana instalado y ejecutándose correctamente.${NC}"
SCRIPT

chmod +x instalar_grafana.sh && ./instalar_grafana.sh
mkdir grafana-install && cd grafana-install