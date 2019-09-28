#!/bin/bash

consul intention create -replace -deny "*" "*"
consul intention create -replace -allow k8s-transit-app vault
consul intention create -replace -allow k8s-transit-app mariadb
