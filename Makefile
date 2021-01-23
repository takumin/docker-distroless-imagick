################################################################################
# Environment Variables
################################################################################

DOCKER_IMAGE_REPOS          := takumi/distroless-imagick
DEBIAN_IMAGE_DOMAIN         := docker.io/library/debian
DEBIAN_IMAGE_BRANCH         := 10-slim
GOLANG_IMAGE_DOMAIN         := docker.io/library/golang
GOLANG_IMAGE_BRANCH         := buster
DISTROLESS_IMAGE_DOMAIN     := gcr.io/distroless/base-debian10
DISTROLESS_IMAGE_BRANCH     := latest
IMAGE_MAGICK_6_VERSION      := 6.9.11-57
IMAGE_MAGICK_7_VERSION      := 7.0.10-58
SELECT_IMAGE_MAGICK_VERSION := 6

################################################################################
# Version
################################################################################

NAME := $(shell basename $(CURDIR))

VERSION := 0.0.1

ifeq (,$(wildcard ../.git/HEAD))
REVISION := ${GIT_SHA1_HASH}
else
REVISION := $(shell git rev-parse --short HEAD)
endif

################################################################################
# Go Build
################################################################################

SRCS := $(shell find $(CURDIR) -type f -name '*.go')

GOOS   := linux
GOARCH := amd64

LDFLAGS_NAME     := -X "main.name=$(NAME)"
LDFLAGS_VERSION  := -X "main.version=v$(VERSION)"
LDFLAGS_REVISION := -X "main.revision=$(REVISION)"
LDFLAGS          := -ldflags '$(LDFLAGS_NAME) $(LDFLAGS_VERSION) $(LDFLAGS_REVISION)'

################################################################################
# Docker Build
################################################################################

DEBIAN_IMAGE     := $(DEBIAN_IMAGE_DOMAIN):$(DEBIAN_IMAGE_BRANCH)
GOLANG_IMAGE     := $(GOLANG_IMAGE_DOMAIN):$(GOLANG_IMAGE_BRANCH)
DISTROLESS_IMAGE := $(DISTROLESS_IMAGE_DOMAIN):$(DISTROLESS_IMAGE_BRANCH)

BUILD_ARGS ?= --build-arg DEBIAN_IMAGE_DOMAIN=$(DEBIAN_IMAGE_DOMAIN) \
              --build-arg DEBIAN_IMAGE_BRANCH=$(DEBIAN_IMAGE_BRANCH) \
              --build-arg GOLANG_IMAGE_DOMAIN=$(GOLANG_IMAGE_DOMAIN) \
              --build-arg GOLANG_IMAGE_BRANCH=$(GOLANG_IMAGE_BRANCH) \
              --build-arg DISTROLESS_IMAGE_DOMAIN=$(DISTROLESS_IMAGE_DOMAIN) \
              --build-arg DISTROLESS_IMAGE_BRANCH=$(DISTROLESS_IMAGE_BRANCH) \
              --build-arg IMAGE_MAGICK_6_VERSION=$(IMAGE_MAGICK_6_VERSION) \
              --build-arg IMAGE_MAGICK_7_VERSION=$(IMAGE_MAGICK_7_VERSION) \
              --build-arg SELECT_IMAGE_MAGICK_VERSION=$(SELECT_IMAGE_MAGICK_VERSION)

ifneq (x${no_proxy}x,xx)
BUILD_ARGS += --build-arg no_proxy=${no_proxy}
endif
ifneq (x${NO_PROXY}x,xx)
BUILD_ARGS += --build-arg NO_PROXY=${NO_PROXY}
endif

ifneq (x${ftp_proxy}x,xx)
BUILD_ARGS += --build-arg ftp_proxy=${ftp_proxy}
endif
ifneq (x${FTP_PROXY}x,xx)
BUILD_ARGS += --build-arg FTP_PROXY=${FTP_PROXY}
endif

ifneq (x${http_proxy}x,xx)
BUILD_ARGS += --build-arg http_proxy=${http_proxy}
endif
ifneq (x${HTTP_PROXY}x,xx)
BUILD_ARGS += --build-arg HTTP_PROXY=${HTTP_PROXY}
endif

ifneq (x${https_proxy}x,xx)
BUILD_ARGS += --build-arg https_proxy=${https_proxy}
endif
ifneq (x${HTTPS_PROXY}x,xx)
BUILD_ARGS += --build-arg HTTPS_PROXY=${HTTPS_PROXY}
endif

################################################################################
# Default Target
################################################################################

.PHONY: all
all: $(NAME)

################################################################################
# Binary Target
################################################################################

.PHONY: $(NAME)
$(NAME): $(CURDIR)/bin/$(NAME)
$(CURDIR)/bin/$(NAME): $(SRCS)
	@GOOS=$(GOOS) GOARCH=$(GOARCH) go build $(LDFLAGS) -o $@

################################################################################
# Archive Target
################################################################################

$(CURDIR)/bin/$(NAME).zip: $(CURDIR)/bin/$(NAME)
	@cd $(CURDIR)/bin && zip $@ $(NAME)

################################################################################
# Running Target
################################################################################

.PHONY: run
run: $(CURDIR)/bin/$(NAME)
	@$(CURDIR)/bin/$(NAME)

################################################################################
# Docker Target
################################################################################

.PHONY: docker
docker:
	@docker build --cache-from $(DEBIAN_IMAGE) --target imagick6 -t $(DOCKER_IMAGE_REPOS):imagick6 $(BUILD_ARGS) .
	@docker build --cache-from $(DEBIAN_IMAGE) --target imagick7 -t $(DOCKER_IMAGE_REPOS):imagick7 $(BUILD_ARGS) .
	@docker build --cache-from $(GOLANG_IMAGE) --target goimagick -t $(DOCKER_IMAGE_REPOS):goimagick $(BUILD_ARGS) .
	@docker build --cache-from $(DISTROLESS_IMAGE) --target service -t $(DOCKER_IMAGE_REPOS):latest $(BUILD_ARGS) .

################################################################################
# Cleanup Target
################################################################################

.PHONY: clean
clean:
	@rm -rf $(CURDIR)/bin
	@rm -f *.jpg
	@rm -f *.pgm
	@rm -f *.png
	@docker system prune -f
	@docker volume prune -f
