# Build Stage
FROM --platform="${BUILDPLATFORM}" rust:1.86.0-slim-bookworm AS builder
USER 0:0
WORKDIR /home/rust/src

ARG TARGETARCH

# Install build requirements
RUN dpkg --add-architecture "${TARGETARCH}"
RUN apt-get update && \
    apt-get install -y \
    make \
    pkg-config \
    libssl-dev:"${TARGETARCH}"
COPY build-image-layer.sh /tmp/
RUN sh /tmp/build-image-layer.sh tools

# Build all dependencies
COPY Cargo.toml Cargo.lock ./
COPY downloader/Cargo.toml ./downloader/
COPY easypwned/Cargo.toml ./easypwned/
COPY easypwned_bloom/Cargo.toml ./easypwned_bloom/
RUN sh /tmp/build-image-layer.sh deps

# Build all apps
COPY downloader ./downloader
COPY easypwned ./easypwned
COPY easypwned_bloom ./easypwned_bloom
RUN sh /tmp/build-image-layer.sh apps

# Bundle Stage
FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=builder /home/rust/src/target/release/easypwned ./
COPY --from=builder /home/rust/src/target/release/easypwned_haveibeenpwned_downloader ./

EXPOSE 3342
USER nonroot
CMD ["./easypwned", "--bloomfile", "/easypwned.bloom"]
