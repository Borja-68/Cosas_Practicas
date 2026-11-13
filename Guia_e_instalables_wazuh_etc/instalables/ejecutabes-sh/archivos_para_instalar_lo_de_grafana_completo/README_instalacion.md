# Guía instalación

1. Configuración previa
    (cambio idioma del teclado)
    `sudo dpkg-reconfigure keyboard-configuration`
    (luego)
    `sudo setupcon`

    (instalacion ssh)
    `sudo apt update && sudo apt install openssh-server -y`

    (reiniciar key del puerto por si acaso en powershell)
    `ssh-keygen -R "[localhost]:2225"`

    (ejecutar instalar_docker.sh)


2. Ejecutar yaml de intalacion **instalador.yaml**

3. Cambiar **manager.conf** y añadir

    ```yaml
        <localfile>
        <log_format>syslog</log_format>
        <location>/var/log/auth.log</location>
        </localfile>
    ```

4. Crear el prometheus del cliente con el instalador **instalable_prometheus_cliente.sh**

5. Añadir el cliente al **prometheus.yml** con **anadir_usuario_a_trabajo_prometheus.sh**

6. crear el usuario de wazuh con el ejecutable **intalador_agente.sh**

7. Cambiar **manager.conf** y añadir en el apartado de **active-response**

    ```yaml
        <command>firewall-drop</command>
        <location>local</location>
        <rules_id>100010</rules_id>
        <timeout>7200</timeout>
    ```

    (tiene que quedar así)

    ```yaml
    <active-response>
      <disabled>no</disabled>
      <command>firewall-drop</command>
      <location>local</location>
      <rules_id>100010</rules_id>
      <timeout>86.400</timeout>
    </active-response>
    ```

8. crear en la misma carpeta donde está **manager.conf**  **local_rules.xml**

    `sudo nano config/wazuh_cluster/local_rules.xml`

9. Introducirle lo siguiente

    ```xml
    <group name="local,syslog,sshd,">

    <!-- Sobreescribir regla predeterminada de fuerza bruta para SSH -->
    <rule id="100010" level="10" frequency="5" timeframe="120" overwrite="yes">
        <if_matched_sid>5760</if_matched_sid> <!-- Evalúa basándose en fallos individuales de SSH -->
        <same_source_ip />
        <description>SSHD: Fuerza bruta detectada (Bloqueo automático activado).</description>
        <mitre>
        <id>T1110</id>
        </mitre>
        <group>authentication_failed,recon,</group>
    </rule>

    </group>
    ```

10. Entrar en **docker-compose.yml** y en la sección de **volúmenes** de **wazuh.manager** colocar lo siguiente al final
    `- ./config/wazuh_cluster/local_rules.xml:/var/ossec/etc/rules/local_rules.xml`

11. Para el desbloqueo de IPs utilizar el ejecutable desbaneador_de_ips.sh

12. añadir al apartado **wazuh.manager->volumes** de **docker-compose**

    `- ./config/wazuh_cluster/custom-n8n.py:/var/ossec/integrations/custom-n8n.py`

13. Añadir lo siguiente al final, antes del volumes, de **docker-compose**

    ```yaml
      n8n:
    image: n8nio/n8n:latest
    container_name: n8n-wazuh
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - N8N_SECURE_COOKIE=false
      - GENERIC_TIMEZONE=Europe/Madrid
      - TZ=Europe/Madrid
    volumes:
      - n8n_data:/home/node/.n8n
    ```

14. Añadir lo siguiente a la seccion de volumes, al fnal del todo, de **docker-compose**
    `n8n_data:`

15. Añadir lo siguiente antes de /ossec-conf de **wazuh_manager.conf**

    ````xml
    <integration>
      <name>custom-n8n.py</name>
      <hook_url>http://n8n:5678/webhook/wazuh-alertas</hook_url>
      <level>5</level>
      <alert_format>json</alert_format>
    </integration>

    ```
16. Ejecutar lo siguiente

    ```bash
    sudo docker compose up -d
    sudo docker exec -it single-node-wazuh.manager-1 chown root:wazuh /var/ossec/integrations/custom-n8n.py
    sudo docker exec -it single-node-wazuh.manager-1 chmod 750 /var/ossec/integrations/custom-n8n.py
    sudo docker exec -it single-node-wazuh.manager-1 /var/ossec/bin/wazuh-control restart

    ```

17. Abrir n8n e iniciar sesion, despues pegar el json **workflow_n8n.json**
