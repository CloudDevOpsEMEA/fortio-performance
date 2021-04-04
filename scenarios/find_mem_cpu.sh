#!/usr/bin/env bash

TIME=90s
FORTIO_CLIENT_POD=$(kubectl get pods -n fortio -l app=fortio-client --output=jsonpath={.items..metadata.name})
FORTIO_SERVER_POD=$(kubectl get pods -n fortio -l app=fortio-server --output=jsonpath={.items..metadata.name})
FORTIO_NAMESPACE=fortio
JQ_EXTRACT='.data.result[0].value[1]'
PROMETHEUS_URL=http://localhost:9090


# CONNECTION_ARRAY=( 16 256 1024 4096 8192 )
# RESPONSE_SIZE_ARRAY=( 32 128 512 1024 2048 )
RESPONSE_SIZE_ARRAY=( 512 1024 )
CONNECTIONS_ARRAY=( 2 4 )
QPS_ARRAY=( 1000 2000 3000 4000 5000 6000 7000 8000 9000 10000 11000 12000 )

MAX_CPU="0.9"

printhelp() {
   echo "This bash script starts fortio tests"
   echo
   echo "Syntax: runner.sh --label <label> [--time <time> --qps <qps>]"
   echo " options:"
   echo "   --label|-l <label>  Label prefix to add to each tests"
   echo "   --time|-t <time>    Time duration of each test (30s, 1m, 2h)"
   echo "   --help|-h           Print this help"
   echo
}

while [[ $# -gt 0 ]] ; do
  key="$1"
  case $key in
      -l|--label)
      LABEL_PREFIX="$2"
      shift # past argument
      shift # past value
      ;;
      -t|--time)
      TIME="$2"
      shift # past argument
      shift # past value
      ;;
      -h|--help)
      printhelp
      exit 0
      ;;
      *)    # unknown option
      shift # past argument
      ;;
  esac
done

if [[ -z "${LABEL_PREFIX}" ]]; then
    echo -e "Missing argument: -l=<label> or --label=<label> \n"
    printhelp
    exit 1
fi

CLIENT_POD=`kubectl get pods -n fortio -l app=fortio-client --output=jsonpath={.items..metadata.name}`
SERVER_POD=`kubectl get pods -n fortio -l app=fortio-server --output=jsonpath={.items..metadata.name}`

FORTIO_CLIENT_SIDECAR_CPU_QUERY="rate(container_cpu_usage_seconds_total{namespace=\"${FORTIO_NAMESPACE}\",pod=\"${CLIENT_POD}\",container=\"istio-proxy\"}[1m])"
FORTIO_SERVER_SIDECAR_CPU_QUERY="rate(container_cpu_usage_seconds_total{namespace=\"${FORTIO_NAMESPACE}\",pod=\"${SERVER_POD}\",container=\"istio-proxy\"}[1m])"
FORTIO_CLIENT_SIDECAR_MEM_QUERY="container_memory_usage_bytes{namespace=\"${FORTIO_NAMESPACE}\",pod=\"${CLIENT_POD}\",container=\"istio-proxy\"}"
FORTIO_SERVER_SIDECAR_MEM_QUERY="container_memory_usage_bytes{namespace=\"${FORTIO_NAMESPACE}\",pod=\"${SERVER_POD}\",container=\"istio-proxy\"}"

FORTIO_CLIENT_CPU_QUERY="rate(container_cpu_usage_seconds_total{namespace=\"${FORTIO_NAMESPACE}\",pod=\"${CLIENT_POD}\",container=\"fortio\"}[1m])"
FORTIO_SERVER_CPU_QUERY="rate(container_cpu_usage_seconds_total{namespace=\"${FORTIO_NAMESPACE}\",pod=\"${SERVER_POD}\",container=\"fortio\"}[1m])"
FORTIO_CLIENT_MEM_QUERY="container_memory_usage_bytes{namespace=\"${FORTIO_NAMESPACE}\",pod=\"${CLIENT_POD}\",container=\"fortio\"}"
FORTIO_SERVER_MEM_QUERY="container_memory_usage_bytes{namespace=\"${FORTIO_NAMESPACE}\",pod=\"${SERVER_POD}\",container=\"fortio\"}"


for RESPONSE_SIZE in "${RESPONSE_SIZE_ARRAY[@]}" ; do
  for CONNECTIONS in "${CONNECTIONS_ARRAY[@]}" ; do # CONNECTIONS
    for QPS in "${QPS_ARRAY[@]}" ; do # QPS

      LABELS="${LABEL_PREFIX}-conn${CONNECTIONS}-qps${QPS}-resp${RESPONSE_SIZE}"
      FORTIO_CMD="/usr/bin/fortio load -jitter=true -c=${CONNECTIONS} -qps=${QPS} -t=${TIME} -a -r=0.001 -labels=${LABELS} http://fortio-server:8080/echo\?size\=${RESPONSE_SIZE}"
      echo "kubectl -n fortio exec -it ${FORTIO_CLIENT_POD} -c fortio -- ${FORTIO_CMD}"
      RESULT=$(kubectl -n fortio exec -it ${FORTIO_CLIENT_POD} -c fortio -- ${FORTIO_CMD} | tail -n 6)
      QPS_RESULT=$(echo $RESULT | sed -n -E 's|.* ([0-9\.]+) qps.*|\1|p')
      echo "QPS_RESULTS = ${QPS_RESULT}"

      FORTIO_CLIENT_CPU_QUERY_RESULT=`curl -s --data-urlencode query=${FORTIO_CLIENT_CPU_QUERY} --data-urlencode time="$(date --date '-15 sec' +%s.%3N)" ${PROMETHEUS_URL}/api/v1/query`
      FORTIO_CLIENT_CPU_STAT=`echo $FORTIO_CLIENT_CPU_QUERY_RESULT | jq ${JQ_EXTRACT} | tr -d '"'`
      FORTIO_CLIENT_SIDECAR_CPU_QUERY_RESULT=`curl -s --data-urlencode query=${FORTIO_CLIENT_SIDECAR_CPU_QUERY} --data-urlencode time="$(date --date '-15 sec' +%s.%3N)" ${PROMETHEUS_URL}/api/v1/query`
      FORTIO_CLIENT_SIDECAR_CPU_STAT=`echo $FORTIO_CLIENT_SIDECAR_CPU_QUERY_RESULT | jq ${JQ_EXTRACT} | tr -d '"'`
      FORTIO_SERVER_CPU_QUERY_RESULT=`curl -s --data-urlencode query=${FORTIO_SERVER_CPU_QUERY} --data-urlencode time="$(date --date '-15 sec' +%s.%3N)" ${PROMETHEUS_URL}/api/v1/query`
      FORTIO_SERVER_CPU_STAT=`echo $FORTIO_SERVER_CPU_QUERY_RESULT | jq ${JQ_EXTRACT} | tr -d '"'`
      FORTIO_SERVER_SIDECAR_CPU_QUERY_RESULT=`curl -s --data-urlencode query=${FORTIO_SERVER_SIDECAR_CPU_QUERY} --data-urlencode time="$(date --date '-15 sec' +%s.%3N)" ${PROMETHEUS_URL}/api/v1/query`
      FORTIO_SERVER_SIDECAR_CPU_STAT=`echo $FORTIO_SERVER_SIDECAR_CPU_QUERY_RESULT | jq ${JQ_EXTRACT} | tr -d '"'`

      FORTIO_CLIENT_MEM_QUERY_RESULT=`curl -s --data-urlencode query=${FORTIO_CLIENT_MEM_QUERY} --data-urlencode time="$(date --date '-15 sec' +%s.%3N)" ${PROMETHEUS_URL}/api/v1/query`
      FORTIO_CLIENT_MEM_STAT=`echo $FORTIO_CLIENT_MEM_QUERY_RESULT | jq ${JQ_EXTRACT} | tr -d '"'`
      FORTIO_CLIENT_SIDECAR_MEM_QUERY_RESULT=`curl -s --data-urlencode query=${FORTIO_CLIENT_SIDECAR_MEM_QUERY} --data-urlencode time="$(date --date '-15 sec' +%s.%3N)" ${PROMETHEUS_URL}/api/v1/query`
      FORTIO_CLIENT_SIDECAR_MEM_STAT=`echo $FORTIO_CLIENT_SIDECAR_MEM_QUERY_RESULT | jq ${JQ_EXTRACT} | tr -d '"'`
      FORTIO_SERVER_MEM_QUERY_RESULT=`curl -s --data-urlencode query=${FORTIO_SERVER_MEM_QUERY} --data-urlencode time="$(date --date '-15 sec' +%s.%3N)" ${PROMETHEUS_URL}/api/v1/query`
      FORTIO_SERVER_MEM_STAT=`echo $FORTIO_SERVER_MEM_QUERY_RESULT | jq ${JQ_EXTRACT} | tr -d '"'`
      FORTIO_SERVER_SIDECAR_MEM_QUERY_RESULT=`curl -s --data-urlencode query=${FORTIO_SERVER_SIDECAR_MEM_QUERY} --data-urlencode time="$(date --date '-15 sec' +%s.%3N)" ${PROMETHEUS_URL}/api/v1/query`
      FORTIO_SERVER_SIDECAR_MEM_STAT=`echo $FORTIO_SERVER_SIDECAR_MEM_QUERY_RESULT | jq ${JQ_EXTRACT} | tr -d '"'`

      echo "client_cpu=${FORTIO_CLIENT_CPU_STAT}, client_sidecar_cpu=${FORTIO_CLIENT_SIDECAR_CPU_STAT}, server_cpu=${FORTIO_SERVER_CPU_STAT}, server_sidecar_cpu=${FORTIO_SERVER_SIDECAR_CPU_STAT}"
      echo "{\"client_cpu\": \"${FORTIO_CLIENT_CPU_STAT}\", \"client_sidecar_cpu\": \"${FORTIO_CLIENT_SIDECAR_CPU_STAT}\", \"server_cpu\": \"${FORTIO_SERVER_CPU_STAT}\", \"server_sidecar_cpu\": \"${FORTIO_SERVER_SIDECAR_CPU_STAT}\"}" > ${LABELS}-cpustats.json

      echo "client_mem=${FORTIO_CLIENT_MEM_STAT}, client_sidecar_mem=${FORTIO_CLIENT_SIDECAR_MEM_STAT}, server_mem=${FORTIO_SERVER_MEM_STAT}, server_sidecar_mem=${FORTIO_SERVER_SIDECAR_MEM_STAT}"
      echo "{\"client_mem\": \"${FORTIO_CLIENT_MEM_STAT}\", \"client_sidecar_mem\": \"${FORTIO_CLIENT_SIDECAR_MEM_STAT}\", \"server_mem\": \"${FORTIO_SERVER_MEM_STAT}\", \"server_sidecar_mem\": \"${FORTIO_SERVER_SIDECAR_MEM_STAT}\"}" > ${LABELS}-memstats.json

      sleep 10
    done # QPS
  done # Connections
done

echo "Download  results for scenario ${LABEL_PREFIX}"
FORTIO_CLIENT=$(kubectl get pods -n fortio -l app=fortio-client --output=jsonpath={.items..metadata.name})
kubectl -n fortio cp ${FORTIO_CLIENT}:/var/lib/fortio ./results/${LABEL_PREFIX} -c shell