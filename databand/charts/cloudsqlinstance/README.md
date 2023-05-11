# CloudSQL

[CloudSQL](https://cloud.google.com/sql) is a fully managed relational database service for MySQL, PostgreSQL, and SQL Server.

## Prerequisites

Before you can run the scripts you need to install
[Helm](https://docs.helm.sh/using_helm/#installing-helm),
[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/),
[crossplane](https://crossplane.io/docs/v1.1/) with permission to access GCP env.

## Install Chart

To install the Cloudsqlinstance Chart into your Kubernetes cluster:

```bash
$ helm install cloudsqlinstance  --namespace cloudsqlinstance-system --set sqlInstanceName=$SQL_INSTANCE_NAME --set settings.ipConfiguration.privateNetwork=$PRIVATE_NATWORK <CHART_DIR>
```

After installation succeeds, you can get a status of Chart

```bash
$ helm status "cloudsqlinstance" --namespace cloudsqlinstance-system
```

This helm chart rollout Postgres CloudSQL instance base on configuration you provide.

In the output you'll get:
1. Fully managed HA CloudSQL Postgres instance.
2. `databand` db created on this instance.
3. `pg_stat_statements` extension created in `databand` db.
4. `prometheus-postgres-exporter-secret` secret created/update with DB connection string in the instalation namespace.
5. `cloudsqlpostgresql-conn` secret with DB access parameteres in the instalation namespace.

For database/extension/secret(prometheus-postgres-exporter-secret) creation responsible helm post-install Job. It's going to be run only during first installation, not upgrade.

## Uninstall Chart

If you want to delete your Chart, use this command:

```bash
$ helm uninstall "cloudsqlinstance" --namespace cloudsqlinstance-system
```

When you use `deletionPolicy: Orphan` it'll not delete CloudSQL instance when helm chart deleted. To delete it you need to use `deletionPolicy: Delete`

## Upgrading Chart

If you want to upgrade your Chart, use this command:

```bash
$ helm upgrade cloudsqlinstance  --namespace cloudsqlinstance-system --set sqlInstanceName=$SQL_INSTANCE_NAME --set settings.ipConfiguration.privateNetwork=$PRIVATE_NATWORK <CHART_DIR>
```