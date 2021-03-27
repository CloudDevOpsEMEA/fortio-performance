# Makefile

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

CLIENT_CHART_DIR := ../helm/fortio-client
SERVER_CHART_DIR := ../helm/fortio-server
SCENARIO  := 1pod-samenode-nosidecar-2core
NAMESPACE := fortio



install-client:  ## Install fortio client
	helm install ${SCENARIO} ${CLIENT_CHART_DIR} --namespace ${NAMESPACE} --values ./${SCENARIO}.yaml || true

upgrade-client:  ## Upgrade fortio client
	helm upgrade ${SCENARIO} ${CLIENT_CHART_DIR} --namespace ${NAMESPACE} --values ./${SCENARIO}.yaml || true

uninstall-client:  ## Uninstall fortio client
	helm uninstall ${SCENARIO} --namespace ${NAMESPACE} || true

reinstall-client: uninstall-client install-client  ## Reinstall fortio client



install-server:  ## Install fortio server
	helm install ${SCENARIO} ${SERVER_CHART_DIR} --namespace ${NAMESPACE} --values ./${SCENARIO}.yaml || true

upgrade-server:  ## Upgrade fortio server
	helm upgrade ${SCENARIO} ${SERVER_CHART_DIR} --namespace ${NAMESPACE} --values ./${SCENARIO}.yaml || true

uninstall-server:  ## Uninstall fortio server
	helm uninstall ${SCENARIO} --namespace ${NAMESPACE} || true

reinstall-server: uninstall-client install-client  ## Reinstall fortio server



namespace:  ## Create namespace
	kubectl create namespace ${NAMESPACE} || true

restart:  ## Restart all microservices
	kubectl -n ${NAMESPACE} rollout restart deploy

view:  ## View all microservices
	kubectl -n ${NAMESPACE} get services -o wide
	kubectl -n ${NAMESPACE} get pods -o wide
