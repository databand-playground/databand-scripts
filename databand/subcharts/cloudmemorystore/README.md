# CloudMemorystore

[Memorystore](https://cloud.google.com/memorystore) is a secure, and highly available in-memory service for Redis and Memcached.

## Prerequisites

Before you can run the scripts you need to install
[Helm](https://docs.helm.sh/using_helm/#installing-helm),
[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/),
[crossplane](https://crossplane.io/docs/v1.1/) with permissions to access GCP project.

## Install Chart

To install the CloudMemorystore Chart into your Kubernetes cluster:

```bash
helm install cloudmemorystore --namespace cloudmemorystore-system --set memorystoreInstanceName=<name> --set settings.authorizedNetworks=<gcp_vpc_resource_name> <CHART_DIR>
```

After installation succeeds, you can get a status of Chart

```bash
helm status "cloudmemorystore" --namespace cloudsqlinstance-system
```

This helm chart rollout Redis Memorystore instance base on configuration you provide.

In the output you'll get:

1. Fully managed HA Redis Memorystore instance.
2. `cloudmemorystore-conn` secret with Redis access parameteres in the installation namespace.

## Uninstall Chart

If you want to delete your Chart, use this command:

```bash
helm uninstall "cloudmemorystore" --namespace cloudmemorystore-system
```

When you use `deletionPolicy: Orphan` it'll not delete Memorystore instance when helm chart deleted. To delete it you need to use `deletionPolicy: Delete`

## Upgrading Chart

If you want to upgrade your Chart, use this command:

```bash
helm upgrade cloudmemorystore  --namespace cloudmemorystore-system --set memorystoreInstanceName=<name> --set settings.authorizedNetworks=<gcp_vpc_resource_name> <CHART_DIR>
```
