IP_A_DESBANEAR="10.0.2.8"

cat > /tmp/desbaneador_de_ips.sh <<'SCRIPT'
#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

IPS_A_DESBANEAR=("$@")
PASS_INDEXER="SecretPassword"

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

for IP_TARGET in "${IPS_A_DESBANEAR[@]}"; do
    echo -e "\n${BLUE}=========================================${NC}"
    echo -e "${BLUE}🎯 Procesando desbaneo para: ${IP_TARGET}${NC}"
    echo -e "${BLUE}=========================================${NC}"

    for HOST in $IPS_AGENTES; do
        echo -e "${YELLOW}🔓 Limpiando ${IP_TARGET} en ${HOST}...${NC}"
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 "root@${HOST}" "
            OTRAS_IPS=\$(iptables -S INPUT | grep ' -j DROP' | grep -v '${IP_TARGET}' | awk '{print \$4}' | sort -u);
            systemctl restart wazuh-agent;
            sleep 2;
            while iptables -D INPUT -s ${IP_TARGET} -j DROP 2>/dev/null; do :; done;
            while iptables -D FORWARD -s ${IP_TARGET} -j DROP 2>/dev/null; do :; done;
            for IP_KEEP in \$OTRAS_IPS; do
                iptables -C INPUT -s \$IP_KEEP -j DROP 2>/dev/null || iptables -I INPUT -s \$IP_KEEP -j DROP 2>/dev/null;
                iptables -C FORWARD -s \$IP_KEEP -j DROP 2>/dev/null || iptables -I FORWARD -s \$IP_KEEP -j DROP 2>/dev/null;
            done
        " 2>/dev/null || echo -e "${YELLOW}⚠️  No se pudo conectar con ${HOST} (posiblemente apagado).${NC}"
    done

    echo -e "${YELLOW}🔓 Limpiando ${IP_TARGET} en el Servidor anfitrión...${NC}"
    while sudo iptables -D INPUT -s "${IP_TARGET}" -j DROP 2>/dev/null; do :; done
    while sudo iptables -D FORWARD -s "${IP_TARGET}" -j DROP 2>/dev/null; do :; done
    while sudo iptables -D DOCKER-USER -s "${IP_TARGET}" -j DROP 2>/dev/null; do :; done

    echo -e "${BLUE}🧹 Eliminando alertas 100010 de ${IP_TARGET} en Wazuh Indexer...${NC}"
    curl -fsS -k -u "admin:${PASS_INDEXER}" -X POST "https://localhost:9200/wazuh-alerts-*/_delete_by_query?refresh=true" \
      -H 'Content-Type: application/json' \
      -d "{
        \"query\": {
          \"bool\": {
            \"must\": [
              { \"term\": { \"rule.id\": \"100010\" } },
              { \"term\": { \"data.srcip\": \"${IP_TARGET}\" } }
            ]
          }
        }
      }" >/dev/null

    echo -e "${GREEN}✅ IP ${IP_TARGET} desbaneada por completo.${NC}"
done
SCRIPT

chmod +x /tmp/desbaneador_de_ips.sh && /tmp/desbaneador_de_ips.sh $IP_A_DESBANEAR && rm -f /tmp/desbaneador_de_ips.sh
