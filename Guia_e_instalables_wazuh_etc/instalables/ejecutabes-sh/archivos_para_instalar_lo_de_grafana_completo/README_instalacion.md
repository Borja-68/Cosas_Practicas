# Guía instalación

1. Cambiar comfiguración de teclado a español

    `sudo dpkg-reconfigure keyboard-configuration`
    (luego)
    `sudo setupcon`

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

10. Entrar en **docker_compose.yml** y en la sección de **volúmenes** de **wazuh.manager** colocar lo siguiente al final
    `- ./config/wazuh_cluster/local_rules.xml:/var/ossec/etc/rules/local_rules.xml`

11. Para el desbloqueo de IPs utilizar el ejecutable desbaneador_de_ips.sh
