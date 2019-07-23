FROM alpine:3.10.1

RUN apk add --no-cache \
  "go=1.12.6-r0" \
  "libc-dev=0.7.1-r0" \
  "git=2.22.0-r0" \
  "bash"

ENV GOPATH=/code
RUN mkdir -p /code/bin
ENV PATH=$GOPATH/bin:$PATH

RUN go get -u github.com/golang/dep/cmd/dep
