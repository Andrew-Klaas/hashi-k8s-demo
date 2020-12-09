#!/bin/bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install mariadb -f ./new.values.yaml bitnami/mariadb
