cat > /tmp/instalador_agente.sh <<'SCRIPT'
#!/bin/bash

# ==========================================
# VARIABLES DE CONFIGURACIÓN DEL CLIENTE
# ==========================================
Var_ipServer="10.0.2.15"
Var_NombreAgente="Servidor-Host"
# Para generar la clave SSH en el Servidor: ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 && cat ~/.ssh/id_ed25519.pub
Var_clave_ssh_servidor="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyEw5JYOtqwvjKdpenwaO63pPSj22DDCW+vZG5Fz512 servidor@Servidor"

# Evita que el navegador recorte el enlace al copiar el texto
REPO_HOST="packages.wazuh.com"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

set -e

echo -e "${BLUE}🛠️  Iniciando instalación del agente de Wazuh (${Var_NombreAgente})...${NC}"

# Limpiar residuos anteriores
sudo rm -f /etc/apt/sources.list.d/wazuh.list /usr/share/keyrings/wazuh.gpg ./index.html

# 1. Instalación desde el repositorio oficial de Wazuh
curl -fsSL "https://${REPO_HOST}/key/GPG-KEY-WAZUH" | sudo gpg --yes --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
sudo chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://${REPO_HOST}/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list > /dev/null

sudo apt-get update -qq
sudo WAZUH_MANAGER="${Var_ipServer}" WAZUH_AGENT_NAME="${Var_NombreAgente}" apt-get install -y wazuh-agent

# 2. Actualización de la IP del servidor y limpieza de logs duplicados
echo -e "${YELLOW}📦 Configurando ossec.conf...${NC}"
sudo sed -i -E "s|<address>[^<]+</address>|<address>${Var_ipServer}</address>|g" /var/ossec/etc/ossec.conf
sudo sed -i '/<location>\/var\/log\/auth\.log<\/location>/,+1d' /var/ossec/etc/ossec.conf 2>/dev/null || true

# 3. Configuración de acceso SSH sin contraseña para el Servidor (con prioridad en sshd_config.d)
echo -e "${YELLOW}🔑 Configurando acceso SSH sin contraseña...${NC}"
sudo mkdir -p /root/.ssh
sudo touch /root/.ssh/authorized_keys

if ! sudo grep -Fq "${Var_clave_ssh_servidor}" /root/.ssh/authorized_keys; then
    echo "${Var_clave_ssh_servidor}" | sudo tee -a /root/.ssh/authorized_keys > /dev/null
fi

sudo chmod 700 /root/.ssh
sudo chmod 600 /root/.ssh/authorized_keys
sudo chown -R root:root /root/.ssh

sudo mkdir -p /etc/ssh/sshd_config.d
echo -e "PermitRootLogin prohibit-password\nPubkeyAuthentication yes" | sudo tee /etc/ssh/sshd_config.d/01-permit-root.conf > /dev/null
sudo systemctl restart ssh || sudo systemctl restart sshd

# 4. Arranque del servicio
echo -e "${YELLOW}🔄 Reiniciando servicio wazuh-agent...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl restart wazuh-agent

echo -e "${GREEN}✅ Agente ${Var_NombreAgente} instalado y acceso SSH sin contraseña listo.${NC}"
SCRIPT

chmod +x /tmp/instalador_agente.sh && sudo /tmp/instalador_agente.sh && rm -f /tmp/instalador_agente.sh
