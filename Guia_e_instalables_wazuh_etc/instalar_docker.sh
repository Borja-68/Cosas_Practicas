mkdir compose && cd compose

cat > instalar_docker.sh <<'SCRIPT'
#!/bin/bash
# Ejecuta los siguientes comando para generar el archivo y luego pega el contenido.
# mkdir compose && cd compose && sudo nano instalar_docker.sh
# sudo chmod +x instalar_docker.sh && ./instalar_docker.sh

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Sin color

set -e  # Detener ejecución si hay errores

echo -e "${BLUE}🛠️  Iniciando instalación de Docker en Ubuntu...${NC}"
echo -e "${YELLOW}📦 Actualizando repositorios...${NC}"
sudo apt-get update

echo -e "${YELLOW}🔧 Instalando dependencias necesarias...${NC}"
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

echo -e "${YELLOW}🔑 Añadiendo clave GPG de Docker...${NC}"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo -e "${YELLOW}➕ Añadiendo repositorio oficial de Docker...${NC}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo -e "${YELLOW}🔁 Actualizando repositorios nuevamente...${NC}"
sudo apt update

echo -e "${YELLOW}🔍 Verificando política de versiones de Docker...${NC}"
apt-cache policy docker-ce

echo -e "${YELLOW}🐳 Instalando Docker y sus componentes...${NC}"
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

echo -e "${YELLOW}🚀 Iniciando y habilitando el servicio Docker...${NC}"
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker --no-pager

echo -e "${YELLOW}👤 Añadiendo el usuario 'user' al grupo docker...${NC}"
sudo usermod -aG docker user

echo -e "${YELLOW}⚙️ Configurando daemon.json para Docker...${NC}"
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "default-address-pools":
  [
    {"base":"172.10.0.0/16","size":24}
  ]
}
EOF

echo -e "${YELLOW}🔄 Reiniciando servicio Docker para aplicar la configuración...${NC}"
sudo systemctl restart docker

echo -e "${GREEN}✅ Docker instalado correctamente.${NC}"
echo -e "${BLUE}🔁 Cierra y vuelve a iniciar sesión para aplicar los cambios de grupo.${NC}"
sleep 5
sudo reboot

SCRIPT

chmod +x instalar_docker.sh && ./instalar_docker.sh