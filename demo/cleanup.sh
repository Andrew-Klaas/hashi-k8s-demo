#!/bin/bash

kubectl delete -f ./application_deploy
helm delete --purge consul
helm delete --purge vault
helm delete --purge mariadb