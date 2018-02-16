# docker-gimme
Travis CI [gimme](https://github.com/travis-ci/gimme) Docker image, useful debugging failed jobs

Example usage:

    GIMME_IMAGE := reg-gimme
    docker build --rm --force-rm -f Dockerfile -t $(GIMME_IMAGE) .
    docker run --rm -i $(DOCKER_FLAGS) \
    	-v $PWD:/go/src/github.com/codem8s/2fy \
    	--workdir /go/src/github.com/codem8s/2fy \
    	-v /tmp:/tmp \
    	$(GIMME_IMAGE) \
    	make
