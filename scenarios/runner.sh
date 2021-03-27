#!/usr/bin/env bash

TIME=5m
QPS=0
FORTIO_CLIENT=$(kubectl get pods -n fortio -l app=fortio-client --output=jsonpath={.items..metadata.name})

#CONNECTION_ARRAY=( 16 256 1024 4096 8192 )
#RESPONSE_SIZE_ARRAY=( 32 512 1024 2048 )
CONNECTION_ARRAY=( 16 )
RESPONSE_SIZE_ARRAY=( 32 512 1024 2048 )

printhelp() {
   echo "This bash script starts fortio tests"
   echo
   echo "Syntax: runner.sh --label <label> [--time <time> --qps <qps>]"
   echo " options:"
   echo "   --label|-l <label>  Label prefix to add to each tests"
   echo "   --time|-t <time>    Time duration of each test"
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

for res_s in "${RESPONSE_SIZE_ARRAY[@]}" ;do
  for con in "${CONNECTION_ARRAY[@]}" ; do
    LABELS="${LABEL_PREFIX}-conn${con}-resp${res_s}"
    FORTIO_CMD="/usr/bin/fortio load -jitter=true -c=${con} -qps=${QPS} -t=${TIME} -a -r=0.001 -labels=${LABELS} http://fortio-server:8080/echo\?size\=${res_s}"
    echo "kubectl -n fortio exec -it ${FORTIO_CLIENT} -c fortio -- ${FORTIO_CMD}"
    kubectl -n fortio exec -it ${FORTIO_CLIENT} -c fortio -- ${FORTIO_CMD} | grep "All done"
  done
done


echo "Download  results for scenario ${LABEL_PREFIX}"
mkdir -p ./${LABEL_PREFIX}
kubectl -n fortio cp ${FORTIO_CLIENT}:/var/log/fortio ./${LABEL_PREFIX} -c shell
