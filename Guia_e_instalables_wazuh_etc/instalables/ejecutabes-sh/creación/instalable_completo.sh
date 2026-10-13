mkdir installacion && cd installacion

cat > instalador_completo.sh <<'SCRIPT'
#!/bin/bash
# Ejecuta los siguientes comando para generar el archivo y luego pega el contenido.
# mkdir compose && cd compose && sudo nano instalador_completo.sh
# sudo chmod +x instalador_completo.sh && ./instalador_completo.sh

#Variables de configuración para wazuh
Var_puerto_waz=5601
Var_contrasena_admin_waz=SecretPassword
Var_contrasena_Api_waz=MyS3cr37P450r.*-

#Variables de configuración para grafana
Var_puerto_graf=3000
Var_usuario_admin_graf=admin
Var_contrasena_admin_graf=SecretPassword
Var_email_admin_graf=admin@grafana.local
Var_nombre_imagen=grafana:latest
Var_nombre_contenedor=grafana
Var_nombre_network=single-node_default

#Variables de configuración para prometheus
Var_nombre_network=single-node_default

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Sin color

set -e  # Detener ejecución si hay errores

echo -e "${BLUE}🛠️  Iniciando instalación de Wazuh en Docker...${NC}"
echo -e "${YELLOW}📦 Actualizando repositorios...${NC}"
sudo apt-get update

echo -e "${YELLOW}🔧 Clonando Repositorio oficial ...${NC}"
git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.8

echo -e "${YELLOW} Entrando en directorio ...${NC}"
cd wazuh-docker/single-node

echo -e "${YELLOW}🔑 Generando certificados...${NC}"
sudo docker compose -f generate-indexer-certs.yml run --rm generator

echo -e "${YELLOW}🔧 Cambiando puerto del dashboard...${NC}"
sed -i -e '/wazuh.dashboard:/,/ports:/ {' -e '/ports:/ {n; s/- 443:5601/- '"$Var_puerto_waz"':5601/;}' -e '}' docker-compose.yml

echo -e "${YELLOW}🔧 Introduciendo contraseña al admin...${NC}"
sed -i -e '/wazuh.indexer:/,/environment/{' -e '/environment:/a \      - OPENSEARCH_INITIAL_ADMIN_PASSWORD='"$Var_contrasena_admin_waz"'|' -e '}' docker-compose.yml
sed -i -e '/wazuh.manager:/,/INDEXER_PASSWORD=/ {' -e '/INDEXER_PASSWORD=/ {s/INDEXER_PASSWORD=.*/INDEXER_PASSWORD='"$Var_contrasena_admin_waz"'/;}' -e '}' docker-compose.yml
sed -i -e '/wazuh.dashboard:/,/INDEXER_PASSWORD=/ {' -e '/INDEXER_PASSWORD=/ {s/INDEXER_PASSWORD=.*/INDEXER_PASSWORD='"$Var_contrasena_admin_waz"'/;}' -e '}' docker-compose.yml
HASH_ADMIN=$(sudo docker run --rm wazuh/wazuh-indexer:4.14.8 /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh -p "$Var_contrasena_admin_waz" | tail -n 1)
sed -i -e '/admin:/,/reserved:/ {' -e 's|hash:.*|hash: \"'"$HASH_ADMIN"'"|' -e '}' config/wazuh_indexer/internal_users.yml

echo -e "${YELLOW}🔧 Cambiando contrasena de la API...${NC}"
sed -i -e '/wazuh.manager:/,/API_PASSWORD=/ {' -e '/API_PASSWORD=/ {s/API_PASSWORD=.*/API_PASSWORD='"$Var_contrasena_Api_waz"'/;}' -e '}' docker-compose.yml
sed -i -e '/wazuh.dashboard:/,/API_PASSWORD=/ {' -e '/API_PASSWORD=/ {s/API_PASSWORD=.*/API_PASSWORD='"$Var_contrasena_Api_waz"'/;}' -e '}' docker-compose.yml

echo -e "${YELLOW}🔧 Cambiando contrasena de la API en wazu_dashboard...${NC}"
sed -i -e '/hosts:/,/password:/ {' -e '/password:/ {s/password:.*/password: "'"$Var_contrasena_Api_waz"'"/;}' -e '}' config/wazuh_dashboard/wazuh.yml

echo -e "${YELLOW}📦 Creando contenedor...${NC}"
sudo docker compose up -d

echo -e "${GREEN}✅ Wazuh instalado correctamente.${NC}"

echo -e "${YELLOW}📦 Regresando al directorio principal...${NC}"
cd ../..

echo -e "${BLUE}🛠️  Iniciando instalación de Preometheus en Docker...${NC}"

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
    name: ${Var_nombre_network}
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
EOF

echo -e "${YELLOW}🔧 Iniciando contenedor...${NC}"
sudo docker compose up -d

echo -e "${GREEN}✅ Prometheus instalado correctamente.${NC}"


echo -e "${YELLOW}📦 Regresando al directorio principal...${NC}"
cd ..

echo -e "${BLUE}🛠️  Iniciando instalación de Grafana en Docker...${NC}"

echo -e "${YELLOW}🔧 Clonando Repositorio oficial ...${NC}"
git clone https://github.com/grafana/grafana.git

echo -e "${YELLOW} Entrando en directorio ...${NC}"
cd grafana

echo -e "${YELLOW}🔧 Cambiando nombre admin del dashboard...${NC}"
sed -i -e '/admin_user =/{' -e '/admin_user =/ {s/admin_user =.*/admin_user = '"$Var_usuario_admin_graf"'/;}' -e '}' conf/defaults.ini

echo -e "${YELLOW}🔧 Cambiando contraseña al admin...${NC}"
sed -i -e '/admin_password =/{' -e '/admin_password =/ {s/admin_password =.*/admin_password = '"$Var_contrasena_admin_graf"'/;}' -e '}' conf/defaults.ini

echo -e "${YELLOW}🔧 Cambiando email del admin...${NC}"
sed -i -e '/admin_email =/{' -e '/admin_email =/ {s/admin_email =.*/admin_email = '"$Var_email_admin_graf"'/;}' -e '}' conf/defaults.ini

echo -e "${YELLOW}🔧 Creando imagen de Docker...${NC}"
sudo docker build -t $Var_nombre_imagen .

echo -e "${YELLOW}📦 Creando contenedor...${NC}"
sudo docker run -d --name $Var_nombre_contenedor --network $Var_nombre_network -p 3000:3000 $Var_nombre_imagen

echo -e "${GREEN}✅ Grafana instalado correctamente.${NC}"
SCRIPT

chmod +x instalador_completo.sh && ./instalador_completo.sh && rm -rf instalador_completo.sh
