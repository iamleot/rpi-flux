.POSIX:

KUBERNETES_VERSION = 1.33.4
KUBECONFORM = kubeconform
KUBECONFORM_FLAGS = -strict -kubernetes-version $(KUBERNETES_VERSION) -schema-location default -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' -skip CustomResourceDefinition -verbose
KUSTOMIZE = kustomize
KUSTOMIZE_FLAGS = --load-restrictor=LoadRestrictionsNone --reorder=legacy
YAMLLINT = yamllint

all: validate

validate:
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

yamllint:
	@echo "Linting YAML files"
	@$(YAMLLINT) --config-data relaxed --no-warnings .
