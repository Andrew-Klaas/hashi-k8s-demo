#!/bin/bash

consul intention create -replace -allow "*" "*"
consul intention create -replace -allow k8s-transit-app vault
consul intention create -replace -allow k8s-transit-app mariadb
consul intention create -replace -allow vault mariadb
