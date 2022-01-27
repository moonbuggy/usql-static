ARG GOLANG_VER="1.17.6"
ARG BUILD_OS="alpine"
ARG FROM_IMAGE="golang:${GOLANG_VER}-${BUILD_OS}"

ARG APP_REPO="github.com/xo/usql"
ARG APP_VERSION="v0.9.2"
ARG APP_COMMIT_HASH="414a3e55eb0be97b8c6ae827e4089ffb5f637ed2"
ARG APP_BUILD_TAGS=""

ARG TARGET_ARCH_TAG="amd64"

ARG GOPATH="/go"
ARG OUT_DIR="/out"

## get and prepare the source
#
FROM moonbuggy2000/fetcher:latest AS fetcher

RUN apk -U add --no-cache go

ARG GOPATH
ARG APP_REPO
WORKDIR "${GOPATH}/src/${APP_REPO}"

ARG APP_COMMIT_HASH
RUN git init -q \
	&& git remote add origin "https://${APP_REPO}.git" \
	&& git fetch --depth=1 origin "${APP_COMMIT_HASH}" \
	&& git reset --hard FETCH_HEAD \
	&& git submodule update --init --recursive

RUN go get -d -tags 'all' "${APP_REPO}"

# go-ole doesn't support arm until after v1.25
# specifically, a variant_arm.go file is added at commit bac9a21098b9908a7260c558a678008c6e4fead4
RUN go get -u -d github.com/go-ole/go-ole@master

# there are no variant files for arm64 but this seems to make it go
RUN ole_dir="${GOPATH}/pkg/mod/github.com/go-ole/$(ls ${GOPATH}/pkg/mod/github.com/go-ole/ | xargs -n1 | sort -uV | tail -n1)" \
	&& [ -f "${ole_dir}/variant_arm64.go" ] || cp "${ole_dir}/variant_amd64.go" "${ole_dir}/variant_arm64.go" \
	&& [ -f "${ole_dir}/variant_date_arm64.go" ] || cp "${ole_dir}/variant_date_amd64.go" "${ole_dir}/variant_date_arm64.go" \
	&& sed 's|amd64|arm64|' -i "${ole_dir}/variant_arm64.go" -i "${ole_dir}/variant_date_arm64.go"


## build the binary
#
FROM "${FROM_IMAGE}" AS builder

# QEMU static binaries from pre_build
ARG QEMU_DIR
ARG QEMU_ARCH=""
COPY _dummyfile "${QEMU_DIR}/qemu-${QEMU_ARCH}-static*" /usr/bin/

RUN apk -U add --no-cache \
		gcc \
		musl-dev \
		unixodbc-dev \
		unixodbc-static

ARG GOPATH
COPY --from=fetcher "${GOPATH}" "${GOPATH}"

ARG APP_REPO
WORKDIR "${GOPATH}/src/${APP_REPO}"

ARG OUT_DIR
ARG APP_BUILD_TAGS
ARG EXCLUDED_DRIVERS
RUN mkdir "${OUT_DIR}" \
	&& ldflags="-linkmode=external -extldflags=-static" \
	&& APP_BUILD_TAGS="${APP_BUILD_TAGS} ${EXCLUDED_DRIVERS}" \
	&& if [ -n "${APP_BUILD_TAGS}" ]; then \
			go build -ldflags "${ldflags}" -tags "${APP_BUILD_TAGS}" -o "${OUT_DIR}"; \
		else go build -ldflags "${ldflags}" -o "${OUT_DIR}"; \
		fi


## collect just the built binary
#
FROM "moonbuggy2000/scratch:${TARGET_ARCH_TAG}"

ARG OUT_DIR
COPY --from=builder "${OUT_DIR}/" /
