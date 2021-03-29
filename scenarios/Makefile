# Makefile

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

CLIENT_CHART_DIR := ../helm/fortio-client
SERVER_CHART_DIR := ../helm/fortio-server
NAMESPACE := fortio

# SCENARIO  := 1pod-samenode-nosidecar-maxcore

# SCENARIO  := 1pod-diffnode-nosidecar-maxcore
# SCENARIO  := 2pod-diffnode-nosidecar-maxcore
# SCENARIO  := 3pod-diffnode-nosidecar-maxcore

# SCENARIO  := 1pod-samenode-nosidecar-1core
# SCENARIO  := 1pod-samenode-nosidecar-2core
# SCENARIO  := 1pod-samenode-nosidecar-3core

# SCENARIO  := 1pod-samenode-nosidecar-1core
# SCENARIO  := 2pod-samenode-nosidecar-1core
# SCENARIO  := 3pod-samenode-nosidecar-1core

# SCENARIO  := 1pod-diffnode-nosidecar-1core
# SCENARIO  := 1pod-diffnode-nosidecar-2core
# SCENARIO  := 1pod-diffnode-nosidecar-3core

# SCENARIO  := 1pod-diffnode-nosidecar-1core
# SCENARIO  := 2pod-diffnode-nosidecar-1core
# SCENARIO  := 3pod-diffnode-nosidecar-1core


install-client:  ## Install fortio client
	helm install fortio-client ${CLIENT_CHART_DIR} --namespace ${NAMESPACE} --values ./${SCENARIO}/client.yaml || true

upgrade-client:  ## Upgrade fortio client
	helm upgrade fortio-client ${CLIENT_CHART_DIR} --namespace ${NAMESPACE} --values ./${SCENARIO}/client.yaml || true

uninstall-client:  ## Uninstall fortio client
	helm uninstall fortio-client --namespace ${NAMESPACE} || true

reinstall-client: uninstall-client install-client  ## Reinstall fortio client



install-server:  ## Install fortio server
	helm install fortio-server ${SERVER_CHART_DIR} --namespace ${NAMESPACE} --values ./${SCENARIO}/server.yaml || true

upgrade-server:  ## Upgrade fortio server
	helm upgrade fortio-server ${SERVER_CHART_DIR} --namespace ${NAMESPACE} --values ./${SCENARIO}/server.yaml || true

uninstall-server:  ## Uninstall fortio server
	helm uninstall fortio-server --namespace ${NAMESPACE} || true

reinstall-server: uninstall-server install-server  ## Reinstall fortio server



create-namespace:  ## Create namespace
	kubectl create namespace ${NAMESPACE} || true
	kubectl label namespace ${NAMESPACE} istio-injection=enabled --overwrite

delete-namespace:  ## Delete namespace
	kubectl delete namespace ${NAMESPACE} || true

restart:  ## Restart all microservices
	kubectl -n ${NAMESPACE} rollout restart deploy

wait-ready:  ## Wait for all fortio pods to be ready
	kubectl -n ${NAMESPACE} wait --for=condition=Ready pods --all

view:  ## View all microservices
	kubectl -n ${NAMESPACE} get services -o wide
	kubectl -n ${NAMESPACE} get pods -o wide
	kubectl -n ${NAMESPACE} get serviceaccount -o wide
	kubectl -n ${NAMESPACE} get destinationrule -o wide
	kubectl -n ${NAMESPACE} get peerauthentication -o wide

exec-client:  ## Kubectl exec in client shell container
	kubectl -n ${NAMESPACE} exec -it `kubectl get pods -n fortio -l app=fortio-client --output=jsonpath={.items..metadata.name}` -c shell -- bash
