#!/bin/bash
set -v

cd tiller
./helm-init.sh
cd ..

sleep 60s

cd consul
./consul.sh
cd ..

sleep 60s

cd mariadb
./mariadb.sh
cd ..

sleep 30s

cd vault
./vault.sh
sleep 60s
./vault_setup.sh
sleep 30s
cd ..

kubectl apply -f ./application_deploy
kubectl get svc k8s-transit-app

echo ""
echo "use the following command to get your demo IP, port is 5000"
echo "$ kubectl get svc k8s-transit-app"
