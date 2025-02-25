# syntax=docker/dockerfile:1
FROM rust:alpine AS chef 

WORKDIR /usr/src/integer

RUN set -eux; \
    apk add --no-cache musl-dev; \
    cargo install cargo-chef; \
    rm -rf $CARGO_HOME/registry

FROM chef as planner

COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder

RUN apk add --no-cache postgresql-dev

COPY --from=planner /usr/src/integer/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

COPY . .
RUN cargo build --release

FROM alpine:3.14

WORKDIR /usr/local/bin

RUN apk add --no-cache tzdata

COPY --from=builder /usr/src/integer/target/release/integer .

ENV TZ Asia/Seoul
EXPOSE 3000
CMD ["./integer"]

