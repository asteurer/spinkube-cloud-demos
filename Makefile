.PHONY: deploy-aks
deploy-aks:
	# Deploying the cluster and updating the kubectl config to have the cluster as current context
	cd azure/azure-aks-spinkube && \
	terraform apply --auto-approve && \
	RESOURCE_GROUP=$$(terraform output -json | jq -r '.resource_group.value') && \
	AKS_CLUSTER=$$(terraform output -json | jq -r '.aks_cluster.value') && \
	az login && \
	az aks get-credentials --resource-group $$RESOURCE_GROUP --name $$AKS_CLUSTER --admin

	# # Install the CRDs
	# kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.2.0/spin-operator.crds.yaml

	# Install the runtime class, which has been updated to account for node pools 
	cd azure/azure-aks-spinkube && \
	kubectl apply -f spin-operator.runtime-class.yaml

	# Install cert-manager CRDs
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.crds.yaml


	helm repo add jetstack https://charts.jetstack.io
	helm repo add kwasm http://kwasm.sh/kwasm-operator/
	helm repo update

	helm install cert-manager jetstack/cert-manager \
	--namespace cert-manager \
	--create-namespace \
	--version v1.14.3

	helm install kwasm-operator kwasm/kwasm-operator \
	--namespace kwasm \
	--create-namespace \
	--set kwasmOperator.installerImage=ghcr.io/spinkube/containerd-shim-spin/node-installer:v0.14.1

	# Provision Nodes
	kubectl annotate node --all kwasm.sh/kwasm-node=true

	helm install spin-operator \
	--namespace spin-operator \
	--create-namespace \
	--version 0.2.0 \
	--wait \
	oci://ghcr.io/spinkube/charts/spin-operator

	# The shim-executor needs to be installed in the same namespace as the spin apps (in this case, default)
	kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.2.0/spin-operator.shim-executor.yaml

.PHONY: destroy-aks
destroy-aks:
	cd azure/azure-aks-spinkube && \
	terraform destroy --auto-approve

.PHONY: deploy-aks-keda
deploy-aks-keda:
	helm repo add kedacore https://kedacore.github.io/charts
	helm repo update
	helm install keda kedacore/keda --namespace keda --create-namespace

	cd azure/azure-aks-keda && \
	kubectl apply -f keda.yaml && \
	kubectl apply -f hpa.yaml