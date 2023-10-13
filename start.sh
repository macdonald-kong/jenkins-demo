#!/bin/bash

# Deploy Jenkins into existing Kubernetes cluster:

kubectl create ns devops-tools

kubectl apply -f ./deploy/jenkins/serviceAccount.yaml
kubectl apply -f ./deploy/jenkins/volume.yaml
kubectl apply -f ./deploy/jenkins/deployment.yaml
kubectl apply -f ./deploy/jenkins/service.yaml

# kubectl port-forward service/jenkins-service 8080:8080 -n devops-tools > /dev/null 2>&1 &