#!/bin/bash
set -v

#REQUIRES HELM 3
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

cd consul
./consul.sh
cd ..
kubectl wait --timeout=180s --for=condition=Ready $(kubectl get pod --selector=app=consul -o name)
sleep 1s

cd mariadb
./mariadb.sh
cd ..
kubectl wait --timeout=180s --for=condition=Ready $(kubectl get pod --selector=app=mariadb -o name)
sleep 1s

cd postgresql
./postgresql.sh
cd ..
kubectl wait --timeout=180s --for=condition=Ready $(kubectl get pod pq-postgresql-0 -o name)
sleep 1s

cd vault
./vault.sh
sleep 5s
./vault_setup.sh
cd ..
sleep 5s

kubectl apply -f ./application_deploy_sidecar
kubectl get svc k8s-transit-app

kubectl apply -f ./go_movies_app
kubectl get svc go-movies-app

kubectl wait --timeout=180s --for=condition=Ready $(kubectl get pod --selector=app=go-movies-app -o name)

consul config write consul/ingress.hcl
consul config write consul/resolver.hcl
consul config write consul/splitter.hcl
consul config write consul/router-headers.hcl

echo ""
echo "use the following command to get your demo IP, port is 5000"
echo "$ kubectl get svc k8s-transit-app"
