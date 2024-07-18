.PHONY: deploy-infra

deploy-infra:
	# Deploying the cluster and updating the kubectl config to have the cluster as current context
	cd infra && \
	terraform apply --auto-approve && \
	RESOURCE_GROUP=$$(terraform output -json | jq -r '.resource_group.value') && \
	AKS_CLUSTER=$$(terraform output -json | jq -r '.aks_cluster.value') && \
	az aks get-credentials --resource-group $$RESOURCE_GROUP --name $$AKS_CLUSTER --admin

.PHONY: config-infra
config-infra:
	# Install the CRDs
	kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.2.0/spin-operator.crds.yaml

	# Install the Runtime Class, which has been updated to account for node pools 
	cd infra && \
	kubectl apply -f spin-operator.runtime-class.yaml

	# Install cert-manager CRDs
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.crds.yaml


	helm repo add jetstack https://charts.jetstack.io
	helm repo add kwasm http://kwasm.sh/kwasm-operator/
	helm repo update

	helm upgrade --install cert-manager jetstack/cert-manager \
	--namespace cert-manager \
	--create-namespace \
	--version v1.14.3

	helm upgrade --install kwasm-operator kwasm/kwasm-operator \
	--namespace kwasm \
	--create-namespace \
	--set kwasmOperator.installerImage=ghcr.io/spinkube/containerd-shim-spin/node-installer:v0.15.1

	# Provision Nodes
	kubectl annotate node --all kwasm.sh/kwasm-node=true

	helm upgrade --install spin-operator \
	--namespace spin-operator \
	--create-namespace \
	--version 0.2.0 \
	--wait \
	oci://ghcr.io/spinkube/charts/spin-operator

	# The shim-executor needs to be installed in the same namespace as the spin apps (in this case, default)
	kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.2.0/spin-operator.shim-executor.yaml

.PHONY: destroy-infra
destroy-infra:
	cd infra && \
	terraform destroy --auto-approve

.PHONY: deploy-keda
deploy-keda:
	helm repo add kedacore https://kedacore.github.io/charts
	helm repo update
	helm install keda kedacore/keda --namespace keda --create-namespace

.PHONY: deploy-keda-workload
deploy-keda-workload:
	kubectl apply -f ./workloads/keda.yaml

.PHONY: deploy-hpa-workload
deploy-hpa-workload:
	kubectl apply -f ./workloads/hpa.yaml

.PHONY: k3d
k3d:
	k3d cluster delete wasm-cluster

	k3d cluster create wasm-cluster \
  		--image ghcr.io/spinkube/containerd-shim-spin/k3d:v0.15.1 \
  		--port "8081:80@loadbalancer" \
  		--agents 2

	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.yaml
	kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager
	kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.2.0/spin-operator.runtime-class.yaml
	kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.2.0/spin-operator.crds.yaml

	# Install Spin Operator with Helm
	helm upgrade --install spin-operator \
		--namespace spin-operator \
		--create-namespace \
		--version 0.2.0 \
		--wait \
		oci://ghcr.io/spinkube/charts/spin-operator

	kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.2.0/spin-operator.shim-executor.yaml