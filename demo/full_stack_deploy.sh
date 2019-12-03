#!/bin/bash
set -v

if [ -z "$1" ]
  then
    echo "Please provide private_ip from terraform output. This is the DC2 VM private IP"
    exit 0
fi

DC2_PRIVATE_IP=$1

cd tiller
./helm-init.sh
cd ..

kubectl wait --timeout=120s --for=condition=Ready $(kubectl get pod --selector=app=helm -o name -n kube-system) -n kube-system
sleep 1s

cd consul
./consul.sh
kubectl wait --timeout=120s --for=condition=Ready $(kubectl get pod --selector=app=consul -o name)
sleep 1s
#./intentions.sh
#Wan Join with DC2
consul join -wan $DC2_PRIVATE_IP
cd ..

cd mariadb
./mariadb.sh
cd ..

kubectl wait --timeout=120s --for=condition=Ready $(kubectl get pod --selector=app=mariadb -o name)
sleep 1s

cd vault
./vault.sh
sleep 60s
./vault_setup.sh
cd ..

kubectl apply -f ./application_deploy
kubectl get svc k8s-transit-app

echo ""
echo "use the following command to get your demo IP, port is 5000"
echo "$ kubectl get svc k8s-transit-app"
