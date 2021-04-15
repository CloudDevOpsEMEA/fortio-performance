#!/usr/bin/env bash

# aws s3api create-bucket --bucket aspenmesh-performance-state-store --region eu-west-3 --create-bucket-configuration LocationConstraint=eu-west-3
# aws s3api put-bucket-versioning --bucket aspenmesh-performance-state-store  --versioning-configuration Status=Enabled

export NAME=aspenmesh.performance.k8s.local
export KOPS_STATE_STORE=s3://aspenmesh-performance-state-store

kops replace --force -f *.yaml
kops update cluster --yes --admin=87600h
kops rolling-update cluster
