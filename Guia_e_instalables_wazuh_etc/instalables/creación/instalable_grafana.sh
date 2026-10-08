mkdir grafana-install && cd grafana-install

cat > instalar_grafana.sh <<'SCRIPT'
#!/bin/bash
# Ejecuta los siguientes comando para generar el archivo y luego pega el contenido.
# mkdir compose && cd compose && sudo nano instalar_grafana.sh
# sudo chmod +x instalar_grafana.sh && ./instalar_grafana.sh

#Variables de configuración para grafana
Var_puerto_graf=3000
Var_usuario_admin_graf=admin
Var_contrasena_admin_graf=SecretPassword
Var_email_admin_graf=admin@grafana.local
Var_nombre_imagen=grafana:latest
Var_nombre_contenedor=grafana
Var_nombre_network=single-node_default


GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Sin color

set -e  # Detener ejecución si hay errores

echo -e "${BLUE}🛠️  Iniciando instalación de Grafana en Docker...${NC}"
echo -e "${YELLOW}📦 Actualizando repositorios...${NC}"
sudo apt-get update

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

chmod +x instalar_grafana.sh && ./instalar_grafana.sh
