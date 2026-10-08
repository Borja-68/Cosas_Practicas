cat > script_crear_trabajo_y_anadir_usuario_prometheus.sh <<'SCRIPT'
#!/bin/bash
# Ejecuta los siguientes comando para borrar un contenedor completamente, ademas de las imagenes y volumenes.


#Variables de configuración para crear agente de prometheus
Var_directorio_prometheus=prometheus_server/prometheus
Var_ip_nuevo_usuario=10.10.200.181
Var_nombre_equipo_nuevo_usuario=10.10.200.181
Var_trabajo_a_asignar_usuario=nodo-usuarios
Var_nombre_nodo_exporter_local=Servidor

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Sin color

set -e  # Detener ejecución si hay errores

echo -e "${BLUE}🛠️  Iniciando creacion...${NC}"
echo -e "${YELLOW}📦 Creando contenido a anadir...${NC}"
Contenido=$(cat <<EOF
\n  - job_name: "${Var_trabajo_a_asignar_usuario}"
    static_configs:
      - targets: ["${Var_ip_nuevo_usuario}:9100"]
        labels:
          nodename: "${Var_nombre_equipo_nuevo_usuario}"
EOF
)

Contenido_sed=$(echo "$Contenido" | sed 's/$/\\/')

echo -e "${YELLOW}📦 Anadiendo contenido...${NC}"
sed -i -e '/job_name: "node-exporter-local"/,/nodename: "'"$Var_nombre_nodo_exporter_local"'"/{' -e '/nodename: "'"$Var_nombre_nodo_exporter_local"'"/a\'$'\n'"$Contenido_sed"' ' -e '}' ${Var_directorio_prometheus}/prometheus.yml
sed -i -e '/job_name: "'"$Var_trabajo_a_asignar_usuario"'"/,/nodename: "'"$Var_nombre_equipo_nuevo_usuario"'"/ {' -e '/nodename: "'"$Var_nombre_equipo_nuevo_usuario"'"/ {s/nodename: "'"$Var_nombre_equipo_nuevo_usuario"'" /nodename: "'"$Var_nombre_equipo_nuevo_usuario"'"/;}' -e '}' ${Var_directorio_prometheus}/prometheus.yml

echo -e "${GREEN}✅ Usuario anadido correctamente.${NC}"
SCRIPT

chmod +x script_crear_trabajo_y_anadir_usuario_prometheus.sh && ./script_crear_trabajo_y_anadir_usuario_prometheus.sh && rm -rf script_crear_trabajo_y_anadir_usuario_prometheus.sh
