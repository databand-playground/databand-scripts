# Databand

Using this guide you will be able to deploy databand on the Kubernetes/OpenShift clusters.

Tested on the following versions:
| Cluster  | Version |
| ------------- | ------------- |
| Kubernetes  | 1.16-1.23 |
| OpenShift  | 4.8-4.11 |

## Installation Prerequisites

Before you can run scripts described in this topic, you need to have the following software installed:

- [Helm 3](https://docs.helm.sh/using_helm/#installing-helm)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)/[oc](https://docs.openshift.com/container-platform/4.8/cli_reference/openshift_cli/getting-started-cli.html)
- [docker](https://www.docker.com/) or [podman](https://podman.io/)

Clusters configuration prerequisites:

- Postgres 12 - it's highly recommended to use external postgres DB instance version 12, hosted outside of Kubernetes/Openshift cluster(by default local postgres instance is used)
- If external DB will be used - `databand` DB should be created in Postgres 12 instance before the installation
- Redis 6 - it's highly recommended to use external redis in-memory store version 6, hosted outside of Kubernetes/Openshift cluster(by default local redis instance is used)
- Kubernetes/OpenShift node - 2 nodes, 4CPU 16RAM recources available
- Access to Kubernetes/OpenShift API `PATCH` method to update Alertmanager configmap
- Pods should able to mount PVC
- RBAC support: able to create serviceaccount/role/rolebinding
- Download databand-<VERSION>-helm-chart.tar.gz from IBM PPA. Extract files from the archive. Upload docker images from  databand-<VERSION>-images.tar archive to your private registry using docker utility(docker load -i - to load to local, docker tag and docker push to upload to registry). Extract file from databand-<VERSION>.tgz - Databand helm chart, use it for installation.
- Ability to use publicly available images: prometheus, alertmanager, redis, postgres, flower(celery), busybox. Below is a list of publicly available images:

```bash
busybox:1.28.4
jimmidyson/configmap-reload:v0.5.0
mher/flower:0.9.7
quay.io/prometheus/alertmanager:v0.24.0
quay.io/prometheus/prometheus:v2.40.5
bitnami/postgresql:12.11.0(if you don't have external DB or want to use bundled PostgreSQL DB)
bitnami/redis:6.2.6-debian-10-r103(if you don't have external in-memory store or want to use bundled Redis in-memory store)
```

To install Databand in a remote Kubernetes/OpenShift cluster, perform the tasks described in this topic.

### Create user-values.yaml

Copy file `user-values.yaml.example` to `user-values.yaml`. Use user-values.yaml as main file to override default values from values.yaml(don't edit values.yaml/values-ocp.yaml directly), example:

```yaml
# user-values.yaml
global:
  databand:
    image:
      repository: <YOUR_REPOSITORY_FOR_DATABAND_IMAGES>
      tag: <YOUR_TAG_FOR_DATABAND_IMAGES>
    imageCredentials:
      registry: <YOUR_REGISTRY_FOR_DATABAND_IMAGES>
      username: <YOUR_USERNAME>
      password: <YOUR_PASSWORD>
```

If you don't have an access to publicly available prometheus, alertmanager and busybox images, set your own image properties in `user-values.yaml` as well:

```yaml
# user-values.yaml
databand:
  initContainers:
    wait_web:
      image:
        repository: <YOUR_REPOSITORY_FOR_BUSYBOX_IMAGE>
        tag: <YOUR_TAG_FOR_BUSYBOX_IMAGE>

prometheus:
  server:
    image:
      repository: <YOUR_REPOSITORY_FOR_PROMETHEUS_IMAGE>
      tag: <YOUR_TAG_FOR_PROMETHEUS_IMAGE>
  alertmanager:
    image:
      repository: <YOUR_REPOSITORY_FOR_ALERTMANAGER_IMAGE>
      tag: <YOUR_REPOSITORY_FOR_ALERTMANAGER_IMAGE>
  configmapReload:
    image:
      repository: <YOUR_REPOSITORY_FOR_CONFIGMAPRELOAD_IMAGE>
      tag: <YOUR_REPOSITORY_FOR_CONFIGMAPRELOAD_IMAGE>

```

### Databand secrets

You need to generate 2 secrets and provide it via `user-values.yaml`.

First secret - fernet key, use following command to generate it:

```bash
dd if=/dev/urandom bs=32 count=1 2>/dev/null | openssl base64
```

Then, override default fernet key in  `user-values.yaml`:

```yaml
# user-values.yaml
databand:
  fernetKey: "<GENERATED_FERNET_KEY_FROM_COMMAND_ABOVE>"
```

Second key - webserver secret, use following command to generate it:

```bash
head -c 32 /dev/urandom | base64 | tr -d =
```

Then, override default webserver secret in  `user-values.yaml`:

```yaml
# user-values.yaml
web:
  secret_key: "<GENERATED_WEBSERVER_SECRET_FROM_COMMAND_ABOVE>"
```

By default, we create following username/password for admin user: `databand/databand`. You can override it with the following values:

```yaml
# user-values.yaml
web:
  default_user:
    disabled: false
    role: "Support"
    username: "databand"
    email: "support@databand.ai"
    firstname: "databand"
    lastname: "databand"
    password: "databand"
```

## Install/Update Helm Chart

To install/update the Databand Chart into your Kubernetes/OpenShift cluster, run the following command:

```bash
 helm upgrade databand --install --create-namespace --namespace databand-system --values ./user-values.yaml .
```

After the installation/update completes successfully, run the following command to get the status of the Chart:

```bash
helm status databand --namespace databand-system
```

### HA mode

By default, Databand install in single mode configuration, to enable HA mode for Databand, override following values in user-values.yaml:

```yaml
# user-values.yaml
databand:
  ha:
    enabled: true
    replicaCount: 2
```

### Databand Monitors

By default, additional components like `datastage-monitor` (for [tracking](https://docs.databand.ai/docs/tracking-datastage) [IBM DataStage](https://www.ibm.com/products/datastage)), `dbt-monitor` (for [tracking](https://docs.databand.ai/docs/tracking-dbt) [dbt](https://www.getdbt.com/)) and `datasource-monitor` (for [tracking](https://docs.databand.ai/docs/all-integrations#tracking-databases) databases like [Google BigQuery](https://cloud.google.com/bigquery)) are disabled. Monitors require username/password or [databand access token](https://docs.databand.ai/docs/access-tokens) to connect to tracking system. If you don't provide username/password, default databand/databand will be using. To enable them - override following values in user-values.yaml:

```yaml
# user-values.yaml

dbnd-datastage-monitor:
  enabled: true
  databand_access_token: ""
  dbnd_username: "databand"
  dbnd_password: "databand"

dbnd-dbt-monitor:
  enabled: true
  databand_access_token: ""
  dbnd_username: "databand"
  dbnd_password: "databand"

dbnd-datasource-monitor:
  enabled: true
  databand_access_token: ""
  dbnd_username: "databand"
  dbnd_password: "databand"
```

### Common Ingress configuration

The chart provides an Ingress configuration to allow customizing the installation depending on your setup. Review the
comments in the `values.yaml` file for more details on how to configure your reverse proxy or load balancer. Ingress Controller must be provisioned in your cluster.

```yaml
# user-values.yaml

ingress:
  enabled: true
  web:
    host: <DATABAND_EXTERNAL_URL>
    ## To enable TLS
    tls:
      ## Set to "true" to enable TLS termination at the ingress controller level
      enabled: false
      ## If enabled, set "secretName" to the secret containing the TLS private key and certificate
      ## Example:
      ## secretName: example-com-crt
```

### GKE Ingress configuration

The chart provides a support for native GKE Ingress configuration with BackendConfig object.

```yaml
# user-values.yaml

# GKE Ingress requires NodePort Service type
databand:
  service:
    type: NodePort

ingress:
  enabled: true
  backendconfig:
    enabled: true
  web:
    host: <DATABAND_EXTERNAL_URL>
    annotations:
      ## Set a GKE Ingress annotations
      ## External Load balancer
      ## To provision internal Load Balancer, set the value of annotation to "gce-internal"
      kubernetes.io/ingress.class: "gce"
      ## Set to false to disable http and use Load Balancer with https only
      kubernetes.io/ingress.allow-http: "true"
    ## To enable TLS
    tls:
      ## Set to "true" to enable TLS termination at the ingress controller level
      enabled: false
      ## If enabled, set "secretName" to the secret containing the TLS private key and certificate
      ## Example:
      ## secretName: example-com-crt
```

### Chart Notes

- This chart automatically prefixes all names using the release name to avoid collisions.
- This chart exposes a single endpoint for the Databand Web UI which can be placed either at the root of the domain or
    at the subpath, for example **<http://mycompany.com/databand/>** .
- In this chart, by default the local PostgreSQL is used as Databand Database.

## Database Configuration

### External DB

Update your `user-values.yaml` with

```yaml
# user-values.yaml

postgresql:
  enabled: false

sql_alchemy_conn:
  protocol: "postgresql+psycopg2"
  username: "databand"
  password: "databand"
  host: "databand.example.com"
  port: "5432"
  dbname: "databand"
```

If you already have an existing secret with Database password in namespace, you can read from it:

```yaml
# user-values.yaml

postgresql:
  enabled: false

sql_alchemy_conn:
  protocol: "postgresql+psycopg2"
  username: "databand"
  password: ""
  host: "databand.example.com"
  port: "5432"
  dbname: "databand"
  existingSecret:
    name: "somesecretname"
    secretKeys:
      userPasswordKey: "password"
```

### External In-Memory Store

Instead of local bitnami Redis, you can use external in-memory store:

```yaml
# user-values.yaml

redis:
  enabled: false

inmemorystore:
  host: "10.1.3.4"
  port: "6379"
  password: "verysecretpassword"
```

If you want to read in-memory store password from secret, specify following values:

```yaml
# user-values.yaml

redis:
  enabled: false

inmemorystore:
  host: "10.1.3.4"
  port: "6379"
  password: ""
  existingSecret:
    name: "somesecretname"
    secretKeys:
      passwordKey: "password"
```

#### For Postgres DB and Redis built in into Databand Chart

Create secure Database connection credentials.

```bash
kubectl create secret generic databand-postgres --namespace databand-system --from-literal=postgres-password=$(openssl rand -base64 13)
kubectl create secret generic databand-redis ---namespace databand-system  --from-literal=redis-password=$(openssl rand -base64 13)
```

Update your `user-values.yaml`

```yaml
# user-values.yaml

postgresql:
  existingSecret: databand-postgres

redis:
  existingSecret: databand-redis
```

If you don't have an access to publicly available postgres, redis and busybox images, set your own image properties in `user-values.yaml` as well:

```yaml
# user-values.yaml
databand:
  initdb:
    job:
      initContainers:
        wait_postgres:
          busybox:
            image:
              repository: <YOUR_REPOSITORY_FOR_BUSYBOX_IMAGE>
              tag: <YOUR_TAG_FOR_BUSYBOX_IMAGE>

postgresql:
  existingSecret: databand-postgres
  image:
    registry: <YOUR_REGISTRY_FOR_POSTGRES_IMAGE> # e.g. docker.io
    repository: <YOUR_REPOSITORY_FOR_POSTGRES_IMAGE> # e.g. bitnami/postgresql
    tag: <YOUR_TAG_FOR_POSTGRES_IMAGE> # e.g. 12.11.0

redis:
  existingSecret: databand-redis
  image:
    registry: <YOUR_REGISTRY_FOR_REDIS_IMAGE> # e.g. docker.io
    repository: <YOUR_REPOSITORY_FOR_REDIS_IMAGE> # e.g. bitnami/redis
    tag: <YOUR_TAG_FOR_REDIS_IMAGE> # e.g. 7.0.5-debian-11-r15

```

## Additional environment variables

You can also specify additional environment variables by using the same format as in the pod's `.spec.containers.env`
definition. These environment variables are mounted on the web, scheduler, and worker pods. You can use this feature to
pass additional secret environment variables to Databand.

Here is a simple example showing how to pass in a Fernet key. Of course, for this example to work, `databand` Kubernetes/OpenShift
secret must already exist in the proper namespace; be sure to create those before running Helm.

```yaml
# user-values.yaml

extraEnv:
  - name: DBND__WEBSERVER__FERNET_KEY
    valueFrom:
      secretKeyRef:
        name: databand
        key: fernet-key
```

## Set a specific StorageClass for Databand components

If your Kubernetes cluster doesn't have a default `storageClass` set, you'll need to specify a desired `storageClass` for Databand components, which require a provisioning of `PersistentVolume` object. To set it, add following values in user-values.yaml:

```
...
postgresql:
  global:
    storageClass: <YOUR_STORAGE_CLASS_NAME>
...
prometheus:
  server:
    persistentVolume:
      storageClass: <YOUR_STORAGE_CLASS_NAME>
  alertmanager:
    persistentVolume:
      storageClass: <YOUR_STORAGE_CLASS_NAME>
...
redis:
  global:
    storageClass: <YOUR_STORAGE_CLASS_NAME>
...
webapp:
  persistence:
    storageClass: <YOUR_STORAGE_CLASS_NAME>
```

## Deploy Databand without RBAC permissions

Default Databand installation requires RBAC permissions. In case you don't have RBAC:

- Alert receiver settings tab won't be shown in Databand UI.
- Alertmanager will use the deployment configmap configurations

Disable alert_def_syncer syncing Alertmanager template file from Databand DB by changing `user-values.yaml`

```yaml
# user-values.yaml

databand:
  alert:
    sync_alertmanager_config: false
```

## Deploy Databand to OpenShift Container Platform (OCP)

OpenShift requires pod `securityContext` and container `securityContext` to be set according to OpenShift cluster SCCs.

Databand Helm chart provides two methods on how to do that:

- First one (and default for `values-ocp.yaml` file) is to disable securityContext for all Databand-related workloads.
This will allow OpenShift's cluster SCC admission controller to inject `securityContext` dynamically on chart deploy,
based on OpenShift's cluster configured SCCs. It also provides great portability between different OpenShift versions.

- Second method - is to set both pod and container desired `securityContext` by the user or cluster administrator,
who deploy the chart via corresponding Helm values - `values-ocp.yaml`. Please see `values-ocp.yaml` for additional details and available parameters.

To install the Databand Chart into your OpenShift cluster, run the following command:

```bash
 helm upgrade databand --install --create-namespace --namespace databand-system --values ./values-ocp.yaml --values ./user-values.yaml .
```

After the installation completes successfully, run the following command to get the status of the Chart:

```bash
helm status databand --namespace databand-system
```

## Monitoring

Databand Helm chart includes `ServiceMonitor` objects for usage with [prometheus-operator](https://github.com/prometheus-operator/prometheus-operator), which can be enabled for specific components.

To enable `ServiceMonitor` for databand component(s), set next values in `user-values.yaml` and set appropriate label configured for `ServiceMonitor`s discovery in your `prometheus-operator`, e.g.:

```
...
web:
  serviceMonitor:
    enabled: true
    labels:
      <YOUR_LABEL_KEY>: <YOUR_LABEL_VALUE>
...
tracking:
  serviceMonitor:
    enabled: true
    labels:
      <YOUR_LABEL_KEY>: <YOUR_LABEL_VALUE>
...
```

Databand components that support `ServiceMonitor` enablement are:

- web
- tracking
- webapp
- rule_engine
- celery.flower
- dbnd-datastage-monitor
- dbnd-datasource-monitor
- dbnd-dbt-monitor

Databand Helm chart also has a `ServiceMonitor` for [Blackbox Exporter](https://github.com/prometheus/blackbox_exporter), that you can use to monitor Databand availability on Ingress URL endpoint. To enable `ServiceMonitor` for Blackbox exporter, set next values in `user-values.yaml` and set appropriate label(s) configured for `ServiceMonitor`s discovery in your `prometheus-operator`:

```
blackbox:
  enabled: true
  labels:
    <YOUR_LABEL_KEY>: <YOUR_LABEL_VALUE>
```

To list Databand's `web`, `tracking` and `rule_engine` metrics, access following endpoints (you must be logged-it to Databand UI):

- `<INGRESS_URL>/api/internal/v1/dbnd_tracking_metrics` and `/api/internal/v1/dbnd_application_metrics` for `web`
- `<INGRESS_URL>/api/internal/v1/dbnd_tracking_metrics` for `tracking`
- `<RULE_ENGINE_SVC_NAME>:<RULE_ENGINE_SVC_PORT>/` for `rule_engine`

Mostly all of Databand metrics have a `dbnd_` prefix in metric name. Python runtime metrics have a `flask_` prefix in metric name.

Example Prometheus monitoring alert rules:

Databand's endpoint response time:

```
    - alert: ApiResponseTimeTooHightUpdateTaskRunAttempts
      expr: (rate(flask_http_request_duration_seconds_sum{status="200",path="/api/v1/tracking/update_task_run_attempts"}[60s])/rate(flask_http_request_duration_seconds_count{status="200",path="/api/v1/tracking/update_task_run_attempts"}[60s])) > 10 < +Inf
      for: 10s
      labels:
        severity: high
      annotations:
        summary: API /api/v1/tracking/update_task_run_attempts average response time is too high
        description: "Avarange response time for api /api/v1/tracking/update_task_run_attempts is above 10s for the last 10s\n  VALUE = {{ $value }}s\n API = {{ $labels.path }}"

    - alert: ApiResponseTimeTooHightInitRun
      expr: (rate(flask_http_request_duration_seconds_sum{status="200",path="/api/v1/tracking/init_run"}[60s])/rate(flask_http_request_duration_seconds_count{status="200",path="/api/v1/tracking/init_run"}[60s])) > 10 < +Inf
      for: 10s
      labels:
        severity: high
      annotations:
        summary: API /api/v1/tracking/init_run average response time is too high
        description: "Avarange response time for api /api/v1/tracking/init_run is above 10s for the last 10s\n VALUE = {{ $value }}s\n API = {{ $labels.path }}"
```

Databand's Access token expiration:

```
    - alert: DatabandAccessTokenIsAboutToExpire
      expr: ((dbnd_auth_tokens - time()) / (3600 * 24)) <= 7 > 0 # 7 days
      for: 1m
      labels:
        severity: high
      annotations:
        summary: "Databand Access Token {{ $labels.label }} will expire in {{ humanize $value }} days"
        description: "Databand Access Token is about to expire"
```
