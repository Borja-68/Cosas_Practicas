mkdir wazuh-install && cd wazuh-install

cat > instalar_wazuh.sh <<'SCRIPT'
#!/bin/bash
# Ejecuta los siguientes comando para generar el archivo y luego pega el contenido.
# mkdir compose && cd compose && sudo nano instalar_wazuh.sh
# sudo chmod +x instalar_wazuh.sh && ./instalar_wazuh.sh

#Variables de configuración para wazuh
Var_puerto_waz=5601
Var_contrasena_admin_waz=SecretPassword
Var_contrasena_Api_waz=MyS3cr37P450r.*-

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
SCRIPT

chmod +x instalar_wazuh.sh && ./instalar_wazuh.sh
