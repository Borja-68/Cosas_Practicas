# Configuración de Defensa Activa contra Ataques SSH en Wazuh

Este documento detalla cómo configurar **Wazuh Active Response** para bloquear de forma automática y dinámica las direcciones IP que realizan ataques de fuerza bruta por SSH, protegiendo al mismo tiempo a los usuarios verídicos mediante un umbral de tolerancia a fallos y listas blancas.

---

## 1. Activación de Active Response (Servidor Wazuh)

Para permitir que el servidor ordene a los agentes bloquear las IPs tras acumular un número determinado de fallos, añade el siguiente bloque al archivo de configuración global del servidor `/var/ossec/etc/ossec.conf`:

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

## 2. Personalización del Umbral de Fallos (Evitar Falsos Positivos)

Por defecto, Wazuh requiere múltiples fallos en una ventana corta de tiempo para activar la alerta de fuerza bruta (`5712`). Si deseas definir con precisión cuántas oportunidades tiene un usuario real antes de ser bloqueado, edita el archivo de reglas locales `/var/ossec/etc/rules/local_rules.xml`:

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

## 3. Protección de IPs Confiables (Listas Blancas)

Para asegurar que los administradores, oficinas centralizadas o subredes locales de confianza nunca sean bloqueados por accidente (incluso si fallan el número estipulado de veces), declara sus IPs en la sección `<global>` del archivo `/var/ossec/etc/ossec.conf` en el servidor:

```xml
<global>
  <white_list>127.0.0.1</white_list>
  <white_list>192.168.1.50</white_list>  <!-- IP estática del administrador -->
  <white_list>10.0.0.0/24</white_list>   <!-- Rango completo de la red interna -->
</global>
```

---

## 4. Aplicación de Cambios

Una vez modificados los archivos en el servidor de Wazuh, es necesario reiniciar el servicio para aplicar la nueva lógica de defensa:

```bash
sudo systemctl restart wazuh-manager
```

---

## 5. Visualización de Bloqueos en Grafana

Para monitorizar las acciones defensivas en tus paneles de Grafana utilizando consultas **PPL**, puedes emplear los siguientes filtros:

* **Contar cuántos bloqueos automáticos han ocurrido por Agente:**
  ```ppl
  source=wazuh-alerts-* | where data.integration = 'ossec' and data.command = 'firewall-drop' | stats count() by agent.name
  ```
* **Listado de últimas IPs atacantes mitigadas recientemente:**
  ```ppl
  source=wazuh-alerts-* | where rule.id = '5712' | fields timestamp, agent.name, data.srcip, rule.description | head 10
  ```
