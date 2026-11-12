cat > /tmp/crear_puente_n8n.sh <<'SCRIPT'
#!/bin/bash

cat > ./config/wazuh_cluster/custom-n8n.py <<'EOF'
#!/usr/bin/env python3
import sys, json, urllib.request

alert_file = open(sys.argv[1])
alert = json.loads(alert_file.read())
alert_file.close()

webhook_url = sys.argv[3]
req = urllib.request.Request(webhook_url, data=json.dumps(alert).encode("utf-8"), headers={"Content-Type": "application/json"})
urllib.request.urlopen(req, timeout=10)
EOF

chmod 750 ./config/wazuh_cluster/custom-n8n.py
echo "✅ Archivo custom-n8n.py creado y con permisos 750."
SCRIPT

chmod +x /tmp/crear_puente_n8n.sh && sudo /tmp/crear_puente_n8n.sh && rm -f /tmp/crear_puente_n8n.sh
