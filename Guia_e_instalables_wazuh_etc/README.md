# Índice

1. [Despliegue con Docker de Wazuh y agentes Wazuh](#despliegue-con-docker-de-wazuh-y-agentes-wazuh)
    1. [Despliegue de Wazuh](#despliegue-de-wazuh)
    2. [Despliegue de agentes Wazuh](#despliegue-de-agentes-wazuh)
    3. [Configuración Wazuh](#configuración-wazuh)
    4. [Configuración agentes Wazuh](#configuración-agentes-wazuh)
2. [Instalación de Grafana](#instalación-de-grafana)
    1. [Pasos previos](#pasos-previos)
    2. [Creación de imagen y contenedor](#creación-de-imagen-y-contenedor)

3. [Implementación de Wazuh en Grafana](#implementación-de-wazuh-en-grafana)
    1. [Creación de Data Source](#creación-de-data-source)
    2. [Importación y arreglos de la dashboard](#importación-y-arreglos-de-la-dashboard)
4. [Despliegue con Docker de Prometheus](#despliegue-con-docker-de-prometheus)
5. [Implementación de Prometheus en Grafana](#implementación-de-prometheus-en-grafana)
    1. [Configuración Dashboard Prometheus](#configuración-dashboard-prometheus)

---

## Despliegue con Docker de Wazuh y agentes Wazuh

---

### Despliegue de Wazuh

---

1. Entrar en el directorio donde se quiera clonar el repositorio de Wazuh.
<br>

2. Clonar el repositorio con el siguiente comando:

    `git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.8`
<br>

3. Entrar en el siguiente directorio ejecutando este comando:

    ```bash
    cd wazuh-docker/single-node
    ```

4. Generar los certificados SSL/TLS:

    ```bash
    sudo docker compose -f generate-indexer-certs.yml run --rm generator
    ```

5. Levantar los contenedores con el siguiente comando:

    ```bash
    sudo docker compose up -d
    ```

---

### Despliegue de agentes Wazuh

---

**Existen dos opciones**:

- **Opción 1: Desde el dashboard de Wazuh**, accediendo a la URL del servidor en el navegador:

1. Entrar en `https://<IP_SERVIDOR>:443`
<br>

2. Si no hay ningún agente creado, pulsar en **Deploy new agent**.
<br>

3. Si ya se cuenta con al menos un agente creado, ir al panel **AGENTS SUMMARY**, pulsar en **Active** o en **Disconnected** y después hacer clic en **Deploy new agent**.
<br>

4. Elegir el paquete de instalación necesario para el cliente, según el sistema operativo que se posea.
<br>

5. En **Server Address**, introducir la `<IP_SERVIDOR>`.
<br>

6. En **Optional settings**, introducir el nombre con el que se quiera identificar al agente.
<br>

7. En **Select one or more existing groups**, introducir el grupo o grupos en los que se quiera incluir al agente (por defecto se asigna el grupo `default`).
<br>

8. El sistema genera el siguiente comando de forma automática con base en las opciones seleccionadas (en este ejemplo se ha seleccionado `Linux - DEB amd64`):

    ```bash
        sudo wget https://wazuh.com && sudo WAZUH_MANAGER='<IP_SERVIDOR>' WAZUH_AGENT_NAME='<NOMBRE_AGENTE>' dpkg -i ./wazuh-agent_4.14.8-1_amd64.deb
    ```

    *(Nota: La versión del agente no es fija; varía según la versión que tenga instalada el servidor).*
<br>

9. El comando anterior descarga e instala todo lo necesario para desplegar el agente, aunque la máquina cliente no tenga Wazuh instalado previamente.
<br>

- **Opción 2: Usar el instalador oficial**, descargando el asistente de instalación del agente Wazuh desde la página oficial e introduciendo la IP del servidor cuando el asistente la solicite.
<br>

    **Para finalizar, activar el servicio del agente Wazuh**:

    ```bash
        sudo systemctl daemon-reload
        sudo systemctl enable wazuh-agent
        sudo systemctl start wazuh-agent
    ```

---

## Configuración Wazuh

---

1. Modificar la configuración general de Wazuh Dashboard (Dark mode, timezone, etc.):

    Ir a `Dashboards management -> Advanced settings`.
<br>

2. Cambiar las credenciales de acceso a Wazuh: 

    Editar el archivo `~<TU_DIRECTORIO>/wazuh-docker/single-node/docker-compose.yml`

- Las contraseñas se deben actualizar de forma unificada en todo el documento para no romper los enlaces de comunicación internos
<br>

    En **wazuh.indexer** -> **environment**:
<br>

- Añadir esta línea de forma manual (No viene por defecto en el repositorio)

     ```yaml
    - OPENSEARCH_INITIAL_ADMIN_PASSWORD=<MI_CONTRASEÑA>
    ```

    En **wazuh.manager** -> **environment**:

    ```yaml
    - INDEXER_USERNAME=admin
    - INDEXER_PASSWORD=<MI_CONTRASEÑA> (Debe coincidir con la del indexer)

    - API_USERNAME=wazuh-wui
    - API_PASSWORD=<MI_CONTRASEÑA_API>
    ```

    En **wazuh.dashboard** -> **environment**:

    ```yaml
    - INDEXER_USERNAME=admin
    - INDEXER_PASSWORD=<MI_CONTRASEÑA> (Debe coincidir con la del indexer)

    - API_USERNAME=wazuh-wui
    - API_PASSWORD=<MI_CONTRASEÑA_API> (Debe coincidir con la del manager)
    ```

- Tras esto tendremos que sincronizar también la contraseña en el archivo `wazuh.yml`, para ello nos moveremos al siguiente directorio usando este comando:

    ```bash
    cd wazuh-docker/single-node/config/wazuh-dashboard
    ```

- Abrir el archivo para poder editarlo con el siguiente comando:

    ```bash
    sudo nano wazuh.yml
    ```

- Actualizar las credenciales dentro del archivo:

    ```yaml
    username: wazuh-wui
    password: <MI_CONTRASEÑA_API> (Debe coincidir con las del manager y dashboard)
    ```

- En este mismo archivo le podemos cambiar el puerto al Dashboard ya que por defecto tiene el puerto 443 y suele ser usado para proxys. Para cambiar sería en esta línea:

    ```yaml
    wazuh.dashboard:
        image: wazuh/wazuh-dashboard:4.14.8
        hostname: wazuh.dashboard
        restart: always
        ports:
        - <NUMERO_PUERTO>:5601
    ```

- Tras realizar cualquier modificación en la configuración, reiniciar los contenedores ejecutando los siguientes comandos:

    ```bash
    sudo docker compose down
    sudo docker compose up -d
    ```

---

## Configuración agentes Wazuh

---

- Por defecto, los agentes de Wazuh se instalan en el siguiente directorio del cliente:

    `/var/ossec`
<br>

- En caso de que la **IP del servidor** cambie y se necesite modificarla en el agente, editar el archivo `ossec.conf` utilizando este comando:

    ```bash
        sudo nano /var/ossec/etc/ossec.conf
    ```

- Cambiar el apartado `<address>` para actualizar el parámetro.
<br>

- Reiniciar el servicio de agentes Wazuh con el siguiente comando:

    ```bash
        sudo systemctl restart wazuh-agent
    ```

---

## Instalación de Grafana

---

### Pasos previos

---

1. Entrar a la carpeta donde se quiera hacer la clonación del repositorio
<br>

2. Clonar el repositorio en github de Grafana

    ```git
        git clone https://github.com/grafana/grafana.git
    ```

3. Abrir la carpeta clonada una vez finalice

    ```bash
        cd grafana
    ```

4. Acceder a la carpeta de configuración y abrir el archivo defaults

    ```bash
        cd conf 
        nano defaults.ini
    ```

5. Cambiar el nombre del admin, contraseña y correo para el inicio de sesión en el dashboard de más adelante

    ```ini
        admin_user = <NOMBRE_DEL_ADMIN>
        admin_password = <CONTRSEÑA_DEL_ADMIN>
        admin_email = <CORREO_DEL_ADMIN>
    ```

6. Una vez guardados los cambios se regresa a la capeta anterior

    ```bash
        cd ..
    ```

---

### Creación de imagen y contenedor

---

1. Crear la imagen en docker mediante con el siguiente comando

    ```bash
        sudo docker build -t <NOMBRE_DE_LA_IMAGEN> .
    ```

2. Una vez finalize el proceso hay que iniciar el contenedor

    ```bash
       sudo docker run -d --name <NOMBRE_DEL_CONTENEDOR> --network <NOMBRE_DE_LA_NETWORK> -p 3000:3000 <NOMBRE_DE_LA_IMAGEN>
    ```

    (la network ha de ser la misma entre todos ya sea propia o no,si no se desea crear una, colocar single-node_default)
    <br>

3. Con esto ya se crea e inicia el contenedor, permitiendo acceder al dashboard de Grafana mediante esta URL

    ```html
        http://<DIRRECCIÓN_IP_DEL_SERVIDOR>:3000
    ```

4. Una vez cargue la pagina se inicia la sesión con los datos cambiados anteriormente

---

## Implementación de Wazuh en Grafana

---

### Creación de Data Source

---

1. Una vez dentro del dashboard de Grafana, abrir el burguer y dirigirse a **Connections** -> **Add new conection**
<br>

2. Buscar en la barra de busqueda la conexión de **Wazuh** e instalarlo, el botón se encuentra dentro arriba a la derecha
<br>

3. Al acabar de instalarse  hay que crear un nuevo data source pulsando en el botón correspondiente arriba a la derecha
<br>

4. Una vez dentro del apartado de creación, rellenar los campos de la siguiente manera

    ```html
        Nombre del Datasource: Wazuh

        Manager URL: https://<DIRECCION_IP_DEL_SERVIDOR_DE_WAZUH>:55000
        Indexer URL: https://<DIRECCION_IP_DEL_SERVIDOR_DE_WAZUH>:9200
        API Username: <NOMBRE_DE_LA_API>
        API password Indexer:<CONTRASEÑA_DE_LA_API>
        Username: <NOMBRE_DEL_ADMINISTRADOR>
        Indexer password :<CONTRASEÑA_DEL_ADMINISTRADOR>
    ```

    - [x] Skip TLS verifyM
    (Los nombres del administrador, API y sus contraseñas se pueden encontrar en [*wazuh.manager*](#configuración-wazuh))
<br>

5. Una vez rellenados los campos, hacer click en el boton de save and test y esperar a que dé los datos por válido

---

### Importación y arreglos de la dashboard

---

1. Una vez creado el data source, acceder al apartado de dashboards del mismo e importar las dashboards disponibles o deseadas
<br>

2. Entrar en el **Dashboards del burguer** de la página, situado a la izquierda con el burger abierto, para observar las dashboards importadas
<br>

3. Acceder a la dashboard llamada **Agent Status**
<br>

4. Hacer click en los 3 puntos del panel llamado **Total agents**, situado arriba a la derecha del panel
<br>

5. Seleccionar la opcion **Edit** y cambiar lo siguiente:

    **Value Options**

    ```txt
        Calculation: count
        Fields: Agent_id
    ```

    **Stat styles**

    ```txt
        Graph mode: None
    ```

6. Una vez realizados los cambios pulsar el boton **Save**, arriba a la derecha
<br>

7. Si es la primera vez que se modifica un dashboard importado, se ha de copiar el json que aparece o descargarlo
<br>

8. Dirigirse a **Dashboards**->**Import dashboard**
(Importar se encuentra arriba a la derecha de dashboards, en el desplegable)
<br>

9. Cargar el Json:
     - **Opción 1: subir un Json file**, si se eligió la opción de descargarlo solo hay que arrastrar el archivo al lugar correspondiente
     - **Opción 2**: pegar/escribir un Json file

    Una vez cargado darle al botón de importar
<br>

10. Entrar en otro dashboard y dirigirse a **Edit** -> **Dashboard options**
(Ambos botones se situan a la derecha)
<br>

11. Dirigirse a **Variables** -> **Above dashboard** -> **agent**
<br>

12. Desactivar las siguientes opciones de **Selection options**, abajo del todo

    ```txt
        Multi-value
        Include All value
    ```

13. Repetir del paso 6 al 12 con los demás archivos

---

## Despliegue con Docker de Prometheus

---

1. Ejecutar la siguiente lista de comandos

    ```bash
        mkdir prometheus_server
        cd prometheus_server
        mkdir prometheus
        mkdir data
    ```

    <br>

2. Crear docker-compose.yml

    ```bash
    nano docker-compose.yml
    ```

    **Pegarle**

```yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    user: "root"
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=15d'
    restart: unless-stopped
    networks:
      - red_wazuh
    depends_on:
      - node-exporter

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    pid: host
    networks:
      - red_wazuh

networks:
  red_wazuh:
    name: single-node_default
    external: true
```

(En red_wazuh name colocar la network a la que están conectados wazuh y grafana)
<br>

3. Ir al directorio prometheus:

    ```bash
        cd prometheus
    ```

4. Crear prometheus.yml:

    ```bash
        nano prometheus.yml
    ```

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node-exporter-local"
    static_configs:
      - targets: ["node-exporter:9100"]
        labels:
          nodename: "MI_SERVIDOR"

  - job_name: "MIS_NODOS_CLIENTE"
    static_configs:
      - targets: ["IP_AGENTE_1:9100"]
        labels:
          nodename: "NOMBRE_AGENTE_1"
      - targets: ["IP_AGENTE_2:9100"]
        labels:
          nodename: "NOMBRE_AGENTE_2"
```

<br>

5. Crear el contenedor con el siguente comando

    ```bash
        sudo docker compose up -d
    ```

---

## Implementación de Prometheus en Grafana

---

1. Entrar en la interfaz de Grafana a través de la URL:

    ```html
    http://<IP_DEL_SERVIDOR>:3000
    ```

2. Acceder introduciendo el usuario y la contraseña (se pueden revisar los pasos en la sección de [Instalación de Grafana](#instalación-de-grafana)).
<br>

3. Dirigirse a **Connections** -> **Add new connection**.
<br>

4. En la barra de búsqueda introducir `Prometheus` y pulsar sobre la coincidencia que aparezca en pantalla.
<br>

5. En la esquina superior derecha, pulsar en **Install**.
<br>

6. En el apartado de **Connection**, introducir la URL de Prometheus: `http://prometheus:9090` (o `http://docker.internal`).
<br>

7. Desplazarse hasta el final de la página y pulsar en **Save & Test** para confirmar y validar la conexión.

---

### Configuración Dashboard Prometheus

---

- Tras crear e importar el dashboard de Prometheus (ver [Importación y arreglos del dashboard](#importación-y-arreglos-de-la-dashboard)), proceder a configurar cada panel de forma individual.
<br>

1. Entrar en el dashboard **Wazuh - Correlation with Prometheus**.
<br>

2. En el panel **Node CPU usage**, dirigirse a la esquina superior derecha y pulsar en el icono de **Menú** -> **Edit**.
<br>

3. En el apartado de **Queries** -> **Metrics browser**, cambiar la query por defecto por la siguiente:

    ```prometheus
        100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[$__rate_interval])) * 100)
    ```

4. En el panel **Node memory usage**, acceder al mismo menú de edición que en el panel anterior y reemplazar la query por la siguiente:

    ```prometheus
        node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes
    ```

5. En el **Dashboard del burger** -> **Import dashboard**, en la opción de el centro , colocar **1860**, darle a load e importar
<br>

6. En cada dispositivo cliente que queramos monitorizar, instalaremos Node Exporter mediante Docker (este comando descarga el agente, configura el inicio automático con el sistema y expone las métricas):

    **Linux**

    ```bash
        sudo docker run -d \
        --name=node-exporter \
        --restart=always \
        --net="host" \
        --pid="host" \
        -v "/:/host:ro,rslave" \
        prom/node-exporter:v1.8.2 \
        --path.rootfs=/host
    ```

    **Windows**

    ```powershell
        docker run -d `
        --name node-exporter `
        --restart always `
        -p 9100:9100 `
        -v /proc:/host/proc:ro `
        -v /sys:/host/sys:ro `
        -v /:/rootfs:ro `
        prom/node-exporter:v1.8.2 `
        --path.procfs=/host/proc `
        --path.sysfs=/host/sys `
        --path.rootfs=/rootfs
    ```

7. Abrir el puerto en el firewall del cliente en caso de ser necesario para permitir que el servidor de Prometheus absorba los datos:

    ```bash
    sudo ufw allow 9100/tcp
    ```

8. Por último, añadir la IP del nuevo cliente al archivo de configuración de Prometheus en el servidor central:

    ```yaml
      - job_name: 'nodos_clientes'
        static_configs:
          - targets: ['IP_DEL_DISPOSITIVO_CLIENTE:9100']
            labels:
              nodename: "NOMBRE_EQUIPO"
    ```
