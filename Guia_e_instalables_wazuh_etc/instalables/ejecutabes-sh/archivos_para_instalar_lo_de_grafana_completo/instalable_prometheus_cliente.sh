cat > /tmp/instalable_prometheus_cliente.sh <<'SCRIPT'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Sin color

set -e  # Detener ejecución si hay errores

echo -e "${BLUE}🛠️  Iniciando instalación de prometheus cliente...${NC}"

 sudo docker run -d \
        --name=node-exporter \
        --restart=always \
        --net="host" \
        --pid="host" \
        -v "/:/host:ro,rslave" \
        prom/node-exporter:v1.8.2 \
        --path.rootfs=/host

echo -e "${GREEN}✅ Prometheus cliente instalado correctamente.${NC}"

SCRIPT

sudo chmod +x /tmp/instalable_prometheus_cliente.sh && sudo /tmp/instalable_prometheus_cliente.sh && sudo rm -rf /tmp/instalable_prometheus_cliente.sh