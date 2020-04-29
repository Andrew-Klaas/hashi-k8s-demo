#!/bin/bash

kubectl apply -f grafana-ui-svc.yaml
kubectl apply -f prometheus-ui-svc.yaml

helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm install --wait -f prometheus-values.yaml prometheus stable/prometheus
helm install --wait  -f grafana-values.yaml grafana stable/grafana --version 4.6.3

sleep 15

kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode > /tmp/grafana-pass.txt

