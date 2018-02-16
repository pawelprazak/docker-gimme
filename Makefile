# Import config
# You can change the default config with `make config="config_special.env" build`
config ?= config.env
include $(config)

VERSION := $(shell cat VERSION)
GITCOMMIT := $(shell git rev-parse --short HEAD)
GITUNTRACKEDCHANGES := $(shell git status --porcelain --untracked-files=no)
ifneq ($(GITUNTRACKEDCHANGES),)
	GITCOMMIT := $(GITCOMMIT)-dirty
endif

GOLANG_VERSION ?= tip

DETAILED_TAG := $(GITCOMMIT)-$(GOLANG_VERSION)
VERSION_TAG := $(GITCOMMIT)-$(GOLANG_VERSION)
LATEST_TAG := $(GITCOMMIT)-$(GOLANG_VERSION)


ifneq ($(TRAVIS_TAG),)
	override DETAILED_TAG := $(TRAVIS_TAG)-$(GITCOMMIT)-$(GOLANG_VERSION)
	override VERSION_TAG := $(TRAVIS_TAG)-$(GOLANG_VERSION)
	override LATEST_TAG := old
	ifeq ($(GOLANG_VERSION),stable)
		override VERSION_TAG := $(TRAVIS_TAG)
		override LATEST_TAG := stable
	endif
	ifeq ($(GOLANG_VERSION),tip)
		override LATEST_TAG := tip
	endif
endif

.DEFAULT_GOAL := help

.PHONY: all
all: docker-build docker-images docker-push ## Runs a docker-build, docker-images, docker-push

.PHONY: check-env
check-env: ## Checks the environment variables
ifndef GOLANG_VERSION
	$(error GOLANG_VERSION is undefined)
endif
	@echo "VERSION: $(VERSION)"
	@echo "GOLANG_VERSION: $(GOLANG_VERSION)"
	@echo "DETAILED_TAG: $(DETAILED_TAG)"
	@echo "VERSION_TAG: $(VERSION_TAG)"
	@echo "LATEST_TAG: $(LATEST_TAG)"
	@echo "TRAVIS_TAG: $(TRAVIS_TAG)"

.PHONY: docker-build
docker-build: check-env ## Build the container
	@echo "+ $@"
	@docker build --build-arg GOLANG_VERSION_ARG=$(GOLANG_VERSION) --build-arg GIMME_VERSION_ARG=$(VERSION) -t $(REPO):$(GITCOMMIT) .
	@docker tag $(REPO):$(GITCOMMIT) $(DOCKER_REGISTRY)/$(REPO):$(DETAILED_TAG)
	@docker tag $(REPO):$(GITCOMMIT) $(DOCKER_REGISTRY)/$(REPO):$(VERSION_TAG)
	@docker tag $(REPO):$(GITCOMMIT) $(DOCKER_REGISTRY)/$(REPO):$(LATEST_TAG)

.PHONY: docker-login
docker-login: ## Log in into the repository
	@echo "+ $@"
	@docker login -u="${DOCKER_USER}" -p="${DOCKER_PASS}" $(DOCKER_REGISTRY)

.PHONY: docker-images
docker-images: ## List all local containers
	@echo "+ $@"
	@docker images

.PHONY: docker-push
docker-push: docker-login ## Push the container
	@echo "+ $@"
	@docker push $(DOCKER_REGISTRY)/$(REPO):$(DETAILED_TAG)
	@docker push $(DOCKER_REGISTRY)/$(REPO):$(VERSION_TAG)
	@docker push $(DOCKER_REGISTRY)/$(REPO):$(LATEST_TAG)

.PHONY: bump-version
BUMP := patch
bump-version: ## Bump the version in the version file. Set BUMP to [ patch | major | minor ]
	@go get -u github.com/jessfraz/junk/sembump # update sembump tool
	$(shell command -v sembump)
	$(eval NEW_VERSION=$(shell sembump --kind $(BUMP) $(VERSION)))
	@echo "Bumping VERSION from $(VERSION) to $(NEW_VERSION)"
	echo $(NEW_VERSION) > VERSION
	@echo "Updating version from $(VERSION) to $(NEW_VERSION) in README.md"
	sed -i s/$(VERSION)/$(NEW_VERSION)/g README.md
	git add VERSION README.md
	git commit -vsam "Bump version to $(NEW_VERSION)"
	@echo "Run make tag to create and push the tag for new version $(NEW_VERSION)"

.PHONY: tag
tag: ## Create a new git tag to prepare to build a release
	git tag -sa $(VERSION) -m "$(VERSION)"
	@echo "Run git push origin $(VERSION) to push your new tag to GitHub and trigger a travis build."

.PHONY: help
help:
	@grep -Eh '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: status
status: ## Shows git and dep status
	@echo "Changed files:"
	@git status --porcelain
	@echo
	@echo "Ignored but tracked files:"
	@git ls-files -i --exclude-standard
	@echo
