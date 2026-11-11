# Configuración de Defensa Activa contra Ataques SSH en Wazuh (Docker)

Este documento detalla cómo configurar **Wazuh Active Response** mediante la edición de archivos locales en el host para bloquear de forma automática las direcciones IP que realizan ataques de fuerza bruta por SSH, cómo monitorizarlas desde Grafana y el procedimiento para desbanear usuarios legítimos.

---

## 1. Activación de Active Response y Listas Blancas

Abre el archivo de configuración global del servidor en tu máquina host:
```bash
sudo nano single-node/config/wazuh_cluster/wazuh_manager.conf
```

### A. Listas Blancas (Evitar bloqueos a IPs confiables)
Busca la sección `<global>` al inicio del archivo y añade tus IPs o rangos de red administrativa para que el sistema nunca los bloquee por accidente:
```xml
<global>
  <white_list>127.0.0.1</white_list>
  <white_list>192.168.1.50</white_list>  <!-- IP estática del administrador -->
  <white_list>10.0.0.0/24</white_list>   <!-- Rango completo de la red interna -->
</global>
```

### B. Comandos y Respuestas Activas
Ve al final de las configuraciones de respuesta activa del archivo y añade las siguientes directivas para activar el script de firewall:
```xml
<!-- 1. Definir el comando de bloqueo del Firewall del sistema -->
<command>
  <name>firewall-drop</name>
  <executable>firewall-drop</executable>
  <timeout_allowed>yes</timeout_allowed>
</command>

<!-- 2. Vincular el comando a la regla de fuerza bruta SSH (ID: 5712) -->
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>5712</rules_id> 
  <timeout>7200</timeout> <!-- Bloqueo temporal por 2 horas (7200 segundos) -->
</active-response>
```

---

## 2. Personalización del Umbral de Fallos

Crea y edita el archivo de reglas locales en tu máquina host para definir cuántas oportunidades tiene un usuario real antes de ser bloqueado:
```bash
sudo nano single-node/config/wazuh_cluster/local_rules.xml
```

Pega el siguiente bloque de código XML:
```xml
<group name="local,syslog,sshd,">

  <!-- Sobreescribir regla predeterminada de fuerza bruta para SSH -->
  <rule id="5712" level="10" overwrite="yes">
    <if_matched_sid>5710</if_matched_sid> <!-- Evalúa basándose en fallos individuales de SSH -->
    <frequency>5</frequency>              <!-- Bloquear exactamente al 5º intento fallido -->
    <timeframe>120</timeframe>            <!-- Dentro de una ventana de tiempo de 2 minutos -->
    <description>SSHD: Fuerza bruta detectada (Bloqueo automático activado).</description>
    <group>authentication_failed,recon,</group>
  </rule>

</group>
```

---

## 3. Mapeo de Volúmenes en Docker Compose

Para asegurar que el contenedor de Wazuh procese el archivo de reglas que acabas de crear, edita el archivo `docker-compose.yml` en la raíz de tu despliegue:
```bash
sudo nano docker-compose.yml
```

Localiza el servicio del manager (`wazuh.manager` o `wazuh.master`) y, bajo la sección de `volumes:`, monta la línea de tus reglas justo debajo de la del archivo de configuración general:
```yaml
    volumes:
      - ./config/wazuh_cluster/wazuh_manager.conf:/var/ossec/etc/ossec.conf
      - ./config/wazuh_cluster/local_rules.xml:/var/ossec/etc/rules/local_rules.xml
```

Guarda los cambios y reinicia el entorno Docker para aplicar la nueva lógica de defensa:
```bash
docker compose down && docker compose up -d
```

---

## 4. Visualización de Bloqueos en Grafana

Para monitorizar las mitigaciones en tus paneles utilizando consultas **PPL**, emplea los siguientes filtros en tus componentes de tabla o métricas:

* **Listado de IPs mitigadas / bloqueadas recientemente:**
  ```ppl
  source=wazuh-alerts-* | where data.integration = 'ossec' and data.command = 'firewall-drop' | fields timestamp, agent.name, data.srcip, data.rules_id | sort -timestamp | head 50
  ```
* **Contar cuántos bloqueos automáticos acumulados han ocurrido por Agente:**
  ```ppl
  source=wazuh-alerts-* | where data.integration = 'ossec' and data.command = 'firewall-drop' | stats count() by agent.name
  ```

---

## 5. Procedimiento de Desbloqueo Manual (Desbanear IPs)

Si un usuario legítimo es bloqueado por error, puedes restituirle el acceso de forma inmediata sin esperar a que expire el tiempo de `timeout`.

### Método A: Centralizado desde el Contenedor de Wazuh (Recomendado)
Entra en la terminal del contenedor del Manager para enviar de forma remota la orden de desbanear al agente afectado:

```bash
# 1. Acceder al contenedor
docker exec -it wazuh.master /bin/bash

# 2. Ejecutar la contraorden de desbloqueo
/var/ossec/bin/agent_control -b <IP_A_DESBLOQUEAR> -f firewall-drop -u <ID_DEL_AGENTE>
```
* `<IP_A_DESBLOQUEAR>`: La dirección IP física que deseas liberar (ej. `192.168.1.15`).
* `<ID_DEL_AGENTE>`: El identificador numérico de Wazuh asignado al cliente o servidor donde el usuario intenta ingresar (ej. `002`). Puedes listar tus agentes mediante `/var/ossec/bin/agent_control -l`.

### Método B: Local en el Cortafuegos de la Máquina Cliente Afectada
Si el agente no dispone de comunicación con el gestor, conéctate por terminal a la máquina afectada y remueve la regla de su motor `iptables`:

```bash
# 1. Buscar y confirmar la regla existente para la IP bloqueada
sudo iptables -L INPUT -v -n | grep <IP_A_DESBLOQUEAR>

# 2. Eliminar manualmente la IP de la cadena específica de Wazuh
sudo iptables -D wazuh-drop -s <IP_A_DESBLOQUEAR> -j DROP
```
