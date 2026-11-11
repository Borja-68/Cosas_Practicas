cat > /tmp/desbaneador_de_ips.sh <<'SCRIPT'
#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

Var_ip_a_desbanear="${1:-10.0.2.6}"

echo -e "${BLUE}🔑 Obteniendo token de API...${NC}"
TOKEN=$(curl -fsS -u wazuh-wui:MyS3cr37P450r.*- -k -X POST "https://localhost:55000/security/user/authenticate?raw=true")

echo -e "${BLUE}🔍 Consultando IPs reales de los agentes activos...${NC}"
JSON_AGENTES=$(curl -fsS -k -X GET "https://localhost:55000/agents?status=active" -H "Authorization: Bearer $TOKEN")

IPS_AGENTES=$(python3 -c '
import sys, json
data = json.load(sys.stdin)
for agent in data.get("data", {}).get("affected_items", []):
    if agent.get("id") != "000":
        ip = agent.get("ip")
        if ip and ip not in ("any", "127.0.0.1"):
            print(ip)
' <<< "$JSON_AGENTES" | sort -u)

for HOST in $IPS_AGENTES; do
    echo -e "${YELLOW}🔓 Desbaneando ${Var_ip_a_desbanear} y reseteando bloqueo en ${HOST}...${NC}"
    # 1. Guarda las demás IPs que estaban bloqueadas en iptables (excepto la que queremos desbanear)
    # 2. Reinicia wazuh-agent para limpiar la memoria de esa IP específica
    # 3. Restaura inmediatamente las demás IPs bloqueadas en iptables
    ssh -o StrictHostKeyChecking=no "root@${HOST}" "
        OTRAS_IPS=\$(iptables -S INPUT | grep ' -j DROP' | grep -v '${Var_ip_a_desbanear}' | awk '{print \$4}');
        systemctl restart wazuh-agent;
        sleep 2;
        for IP_KEEP in \$OTRAS_IPS; do
            iptables -I INPUT -s \$IP_KEEP -j DROP 2>/dev/null;
            iptables -I FORWARD -s \$IP_KEEP -j DROP 2>/dev/null;
        done
    "
done

echo -e "${GREEN}✅ IP ${Var_ip_a_desbanear} desbaneada y lista para volver a detectarse. Las demás IPs siguen bloqueadas.${NC}"
SCRIPT

chmod +x /tmp/desbaneador_de_ips.sh && /tmp/desbaneador_de_ips.sh && rm -f /tmp/desbaneador_de_ips.sh
