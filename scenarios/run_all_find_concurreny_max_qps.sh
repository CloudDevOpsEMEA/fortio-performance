#!/usr/bin/env bash

SCENARIO_ARRAY=(
  "1pod-diffnode-nosidecar-1core"
  "1pod-diffnode-nosidecar-2core"
  "1pod-diffnode-nosidecar-3core"
  "1pod-diffnode-nosidecar-maxcore"
  "1pod-samenode-nosidecar-1core"
  "1pod-samenode-nosidecar-2core"
  "1pod-samenode-nosidecar-3core"
  "1pod-samenode-nosidecar-maxcore"
  "2pod-diffnode-nosidecar-1core"
  "2pod-diffnode-nosidecar-maxcore"
  "2pod-samenode-nosidecar-1core"
  "3pod-diffnode-nosidecar-1core"
  "3pod-diffnode-nosidecar-maxcore"
  "3pod-samenode-nosidecar-1core"
)

for SCENARIO in "${SCENARIO_ARRAY[@]}" ; do

  make uninstall-client uninstall-server delete-namespace 
  sleep 20
  make create-namespace install-client install-server SCENARIO=${SCENARIO}
  sleep 20
  make wait-ready

  ./find_concurreny_max_qps.sh -l ${SCENARIO} -t 1m

done
