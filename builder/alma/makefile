IMAGENAME  = serviced-iso-build
VERSION   ?= alma-base-1.0.2
TAG = zenoss/$(IMAGENAME):$(VERSION)

.PHONY: build push clean

build:
	@echo Building image
	@docker build -f Dockerfile -t $(TAG) .

push:
	docker push $(TAG)

# Don't generate an error if the image does not exist
clean:
	-docker rmi $(TAG)

