#!/bin/bash

helm install pq \
  --set postgresqlPassword=password,postgresqlDatabase=movies \
    bitnami/postgresql -f values.yaml