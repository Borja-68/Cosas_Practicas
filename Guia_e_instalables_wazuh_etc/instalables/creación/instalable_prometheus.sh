mkdir prometheus-install && cd prometheus-install
cat > instalar_wazuh.sh <<'SCRIPT'
#!/bin/bash
# Ejecuta los siguientes comando para generar el archivo y luego pega el contenido.
# mkdir compose && cd compose && sudo nano instalar_wazuh.sh
# sudo chmod +x instalar_wazuh.sh && ./instalar_wazuh.sh

#Variables de configuración para prometheus
Var_nombre_network=single-node_default
Var_nombre_servidor=MI_SERVIDOR
Var_contrasena_Api_waz=MyS3cr37P450r.*-

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Sin color

set -e  # Detener ejecución si hay errores

echo -e "${BLUE}🛠️  Iniciando instalación de Preometheus en Docker...${NC}"
echo -e "${YELLOW}📦 Actualizando repositorios...${NC}"
sudo apt-get update

echo -e "${YELLOW}🔧 Creando estructura de carpetas...${NC}"
mkdir prometheus-server
mkdir prometheus-server/prometheus
mkdir prometheus-server/data

echo -e "${YELLOW} Entrando encarpeta prometheus-server...${NC}"
cd prometheus-server

echo -e "${YELLOW} Creando docker-compose...${NC}"
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    user: "root"
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=15d'
    restart: unless-stopped
    networks:
      - red_wazuh
    depends_on:
      - node-exporter

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    pid: host
    networks:
      - red_wazuh

networks:
  red_wazuh:
    name: $Var_nombre_network
    external: true
EOF

echo -e "${YELLOW} Creando prometheus yml...${NC}"
cat > prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node-exporter-local"
    static_configs:
      - targets: ["node-exporter:9100"]
        labels:
          nodename: "Servidor"

  - job_name: "nodos-node-exporter"
    static_configs:
EOF

echo -e "${YELLOW}🔧 Iniciando contenedor...${NC}"
sudo docker compose up -d

echo -e "${GREEN}✅ Prometheus instalado correctamente.${NC}"
SCRIPT

chmod +x instalar_wazuh.sh && ./instalar_wazuh.sh
