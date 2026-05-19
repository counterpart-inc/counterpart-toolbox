.PHONY: context-generate context-validate context-check

context-generate:
	bash scripts/context-lock.sh generate

context-validate:
	bash scripts/context-lock.sh validate

context-check:
	bash scripts/context-lock.sh ci-check
