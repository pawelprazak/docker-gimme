FROM buildpack-deps:stretch-scm

ARG GOLANG_VERSION_ARG=tip
ARG GIMME_VERSION_ARG=master

# gcc for cgo
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
		pkg-config \
		curl && \
    apt-get clean -y && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /usr/share/locale/* && \
    rm -rf /var/cache/debconf/*-old && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/doc/*

ENV GIMME_VERSION $GIMME_VERSION_ARG
RUN set -eux; \
	curl -sSL -o /usr/local/bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/$GIMME_VERSION/gimme; \
    chmod +x /usr/local/bin/gimme;

ENV GOLANG_VERSION $GOLANG_VERSION_ARG
RUN set -eux; \
    gimme $GOLANG_VERSION | tee -a $HOME/.bashrc; \
    rm -rf $HOME/.gimme/versions/*/api; \
    rm -rf $HOME/.gimme/versions/*/blog; \
    rm -rf $HOME/.gimme/versions/*/doc; \
    rm -rf $HOME/.gimme/versions/*/misc; \
    rm -rf $HOME/.gimme/versions/*/pkg; \
    rm -rf $HOME/.gimme/versions/*/src; \
    rm -rf $HOME/.gimme/versions/*/test; \
    rm -rf $HOME/.gimme/versions/*/.git; \
    rm -rf $HOME/.gimme/versions/*/.github; \
    rm -rf /tmp/gimme

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
