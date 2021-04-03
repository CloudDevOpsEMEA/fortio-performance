#!/usr/bin/env bash

SCENARIO_ARRAY=(
  "1pod-diffnode-nosidecar-1core"
  "1pod-samenode-nosidecar-1core"
  "1pod-diffnode-sidecar-1core-default"
  "1pod-samenode-sidecar-1core-default"
  "1pod-diffnode-sidecar-mtls-1core-default"
  "1pod-samenode-sidecar-mtls-1core-default"
  "1pod-diffnode-sidecarclient-1core-default"
  "1pod-diffnode-sidecarserver-1core-default"
  "1pod-samenode-sidecarclient-1core-default"
  "1pod-samenode-sidecarserver-1core-default"
  "1pod-diffnode-sidecar-1core-tuned"
  "1pod-diffnode-sidecar-mtls-1core-tuned"
)

for SCENARIO in "${SCENARIO_ARRAY[@]}" ; do

  make uninstall-client uninstall-server delete-namespace 
  sleep 20
  make create-namespace install-client install-server SCENARIO=${SCENARIO}
  sleep 20
  make wait-ready

  ./find_mem_cpu.sh -l ${SCENARIO} -t 90s

done
