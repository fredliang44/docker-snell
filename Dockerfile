FROM alpine:edge as builder

LABEL maintainer="metowolf <i@i-meto.com>"

ENV SNELL_VERSION 4.0.0

RUN case `uname -m` in \
      x86_64) ARCH=amd64; ;; \
      armv7l) ARCH=armv7l; ;; \
      aarch64) ARCH=aarch64; ;; \
      ppc64le) ARCH=ppc64le; ;; \
      s390x) ARCH=s390x; ;; \
      *) echo "un-supported arch, exit ..."; exit 1; ;; \
    esac \
    && apk update \
    && apk add ca-certificates \
    && update-ca-certificates \
    && apk --no-cache add openssl wget \
    && apk add --no-cache \
      unzip \
      # upx \
    && echo "https://dl.nssurge.com/snell/snell-server-v${SNELL_VERSION}-linux-${ARCH}.zip" \
    && wget -O snell-server.zip https://dl.nssurge.com/snell/snell-server-v${SNELL_VERSION}-linux-${ARCH}.zip \
    && unzip snell-server.zip \
    # && upx --brute snell-server \
    && mv snell-server /usr/local/bin/


FROM alpine:3.6

LABEL maintainer="metowolf <i@i-meto.com>"

ENV GLIBC_VERSION 2.30-r0

ENV SERVER_HOST 0.0.0.0
ENV SERVER_PORT 8388
ENV PSK=
ENV OBFS http
ENV ARGS=

EXPOSE ${SERVER_PORT}/tcp
EXPOSE ${SERVER_PORT}/udp

COPY --from=builder /usr/local/bin /usr/local/bin

RUN case `uname -m` in \
      x86_64) ARCH=amd64; ;; \
      armv7l) ARCH=armv7l; ;; \
      aarch64) ARCH=aarch64; ;; \
      ppc64le) ARCH=ppc64le; ;; \
      s390x) ARCH=s390x; ;; \
      *) echo "un-supported arch, exit ..."; exit 1; ;; \
    esac \
    && apk update \
    && apk add ca-certificates \
    && update-ca-certificates \
    && apk --no-cache add openssl wget
#RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
RUN if [ $ARCH == aarch64 ]; then \
      wget -O glibc.apk https://github.com/Rjerk/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}-arm64/glibc-${GLIBC_VERSION}.apk \
      && wget -O glibc-bin.apk https://github.com/Rjerk/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}-arm64/glibc-bin-${GLIBC_VERSION}.apk ; \
    else \
      wget -O glibc.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
      && wget -O glibc-bin.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk ; \
    fi
RUN apk add --allow-untrusted glibc.apk glibc-bin.apk \
    && apk add --no-cache libstdc++ \
    && rm -rf glibc.apk glibc-bin.apk /etc/apk/keys/sgerrand.rsa.pub /var/cache/apk/*

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
