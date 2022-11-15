.POSIX:

CURL = curl
FLUX_CRD_SCHEMAS_URL = https://github.com/fluxcd/flux2/releases/latest/download/crd-schemas.tar.gz
FLUX_CRD_SCHEMAS_TMPDIR = /tmp/flux-crd-schemas
FLUX_CRD_SCHEMAS_TMPFILE = $(FLUX_CRD_SCHEMAS_TMPDIR)/flux-crd-schemas.tar.gz
KUBERNETES_VERSION = 1.25.3
KUBECONFORM = kubeconform
KUBECONFORM_FLAGS = -ignore-missing-schemas -strict -kubernetes-version $(KUBERNETES_VERSION) -schema-location default -schema-location $(FLUX_CRD_SCHEMAS_TMPDIR) -verbose
KUSTOMIZE = kustomize
KUSTOMIZE_FLAGS = --load-restrictor=LoadRestrictionsNone --reorder=legacy

all: validate

crds:
	@echo "Fetching Flux CRD schemas"
	@mkdir -p $(FLUX_CRD_SCHEMAS_TMPDIR)/master-standalone-strict
	@$(CURL) --silent --remote-time \
		--time-cond $(FLUX_CRD_SCHEMAS_TMPFILE) \
		--output $(FLUX_CRD_SCHEMAS_TMPFILE) \
		--location $(FLUX_CRD_SCHEMAS_URL)
	@echo "Extracting Flux CRD schemas"
	@tar xzf $(FLUX_CRD_SCHEMAS_TMPFILE) \
		-C $(FLUX_CRD_SCHEMAS_TMPDIR)/master-standalone-strict

validate: crds
	@echo "Validating Flux kustomizations"
	@set -e; \
	find . -regex './clusters/.*' -type f -name '*.yaml' -maxdepth 3 | \
		while IFS= read file; do \
			$(KUBECONFORM) $(KUBECONFORM_FLAGS) $$file; \
		done
	@echo "Validating kustomizations"
	@set -e; \
	find . -type f -name 'kustomization.yaml' | \
		while IFS= read file; do \
			dirname=$$(dirname $$file); \
			echo "Validating $${dirname}"; \
			$(KUSTOMIZE) build $(KUSTOMIZE_FLAGS) $$dirname > /dev/null; \
			$(KUSTOMIZE) build $(KUSTOMIZE_FLAGS) $$dirname | \
			$(KUBECONFORM) $(KUBECONFORM_FLAGS); \
		done
