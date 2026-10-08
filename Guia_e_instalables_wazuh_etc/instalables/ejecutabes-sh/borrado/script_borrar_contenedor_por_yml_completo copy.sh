cat > script_borrar_contenedor_por_yml_completo.sh <<'SCRIPT'
#!/bin/bash
# Ejecuta los siguientes comando para borrar un contenedor completamente, ademas de las imagenes y volumenes.


#Variables de configuración de borrado por imagen
Var_directorio_yml_contenedor=.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Sin color

set -e  # Detener ejecución si hay errores

echo -e "${BLUE}🛠️  Iniciando borrado...${NC}"
echo -e "${YELLOW}📦 Accediendo a carpeta repositorios...${NC}"
cd $Var_directorio_yml_contenedor

echo -e "${YELLOW}📦 Borrando contenedor...${NC}"
sudo docker compose down

echo -e "${YELLOW}📦 eliminando contenedores sin usar...${NC}"
sudo docker container prune 


echo -e "${YELLOW}📦 eliminando volumenes sin usar...${NC}"
sudo docker volume prune -a

echo -e "${YELLOW}📦 eliminando imagenes sin usar...${NC}"
sudo docker image prune -a

echo -e "${GREEN}✅ Contenedor borrado completamente.${NC}"
SCRIPT

chmod +x script_borrar_contenedor_por_yml_completo.sh && ./script_borrar_contenedor_por_yml_completo.sh && rm -rf script_borrar_contenedor_por_yml_completo.sh
