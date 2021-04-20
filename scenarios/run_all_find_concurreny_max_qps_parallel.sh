#!/usr/bin/env bash

SCENARIO_ARRAY=(
  "scenario_sidecars_no_mtls_scale_1"
  "scenario_sidecars_with_mtls_scale_1"
  "scenario_sidecars_no_mtls_scale_2"
  "scenario_sidecars_with_mtls_scale_2"
  "scenario_sidecars_no_mtls_scale_3"
  "scenario_sidecars_with_mtls_scale_3"
  "scenario_sidecars_no_mtls_scale_4"
  "scenario_sidecars_with_mtls_scale_4"
  "scenario_sidecars_no_mtls_scale_5"
  "scenario_sidecars_with_mtls_scale_5"
)

for SCENARIO in "${SCENARIO_ARRAY[@]}" ; do

  make uninstall-client uninstall-server delete-namespace 
  sleep 20
  make create-namespace install-client install-server SCENARIO=${SCENARIO}
  sleep 20
  make wait-ready

  ./find_concurreny_max_qps_parallel.sh -l ${SCENARIO} -t 1m

done
