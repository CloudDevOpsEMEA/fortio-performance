#!/usr/bin/env bash

TIME=1m
QPS=0
FORTIO_CLIENT=$(kubectl get pods -n fortio -l app=fortio-client --output=jsonpath={.items..metadata.name})

# CONNECTION_ARRAY=( 16 256 1024 4096 8192 )
RESPONSE_SIZE_ARRAY=( 32 128 512 1024 2048 )
# RESPONSE_SIZE_ARRAY=( 32 128 )

MAX_OVERSHOOT=3

printhelp() {
   echo "This bash script starts fortio tests"
   echo
   echo "Syntax: runner.sh --label <label> [--time <time> --qps <qps>]"
   echo " options:"
   echo "   --label|-l <label>  Label prefix to add to each tests"
   echo "   --time|-t <time>    Time duration of each test (30s, 1m, 2h)"
   echo "   --qps|-q <qps>      Queries per second (0 is try maximum)"
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
      -q|--qps)
      QPS="$2"
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

for RESPONSE_SIZE in "${RESPONSE_SIZE_ARRAY[@]}" ; do
  MAX_QPS_RESULT=0
  OVERSHOOT=0
  BEST_CONNECTIONS=1
  for CONNECTIONS in  `eval echo {1..10000}` ; do
    if [[ ${OVERSHOOT} -ge ${MAX_OVERSHOOT} ]] ; then
      break
    fi

    LABELS="${LABEL_PREFIX}-conn${CONNECTIONS}-resp${RESPONSE_SIZE}"
    FORTIO_CMD="/usr/bin/fortio load -jitter=true -c=${CONNECTIONS} -qps=${QPS} -t=${TIME} -a -r=0.001 -labels=${LABELS} http://fortio-server:8080/echo\?size\=${RESPONSE_SIZE}"
    echo "kubectl -n fortio exec -it ${FORTIO_CLIENT} -c fortio -- ${FORTIO_CMD}"
    RESULT=$(kubectl -n fortio exec -it ${FORTIO_CLIENT} -c fortio -- ${FORTIO_CMD} | tail -n 6)
    QPS_RESULT_NEW=$(echo $RESULT | sed -n -E 's|.* ([0-9\.]+) qps.*|\1|p')
    echo "QPS_RESULTS = ${QPS_RESULT_NEW}"

    if (( $(echo "$QPS_RESULT_NEW < $MAX_QPS_RESULT" | bc -l) )) ; then
      let "CONNECTIONS++"
      let "OVERSHOOT++"
      continue
    else 
      OVERSHOOT=0
    fi

    MAX_QPS_RESULT=${QPS_RESULT_NEW}
    BEST_CONNECTIONS=${CONNECTIONS}
    let "CONNECTIONS++"
  done

  echo "Best result for RESPONSE_SIZE ${RESPONSE_SIZE} : ${MAX_QPS_RESULT} with connections/concurrency ${BEST_CONNECTIONS}"
  sleep 30
done

echo "Download  results for scenario ${LABEL_PREFIX}"
FORTIO_CLIENT=$(kubectl get pods -n fortio -l app=fortio-client --output=jsonpath={.items..metadata.name})
kubectl -n fortio cp ${FORTIO_CLIENT}:/var/lib/fortio ./results/${LABEL_PREFIX} -c shell
