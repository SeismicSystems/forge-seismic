# syntax=docker/dockerfile:1.2

FROM ubuntu:jammy-20240212 as solc-builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    git \
    libboost-all-dev \
    openssh-client \
    && \
    update-ca-certificates

# Set up SSH known hosts to avoid host verification prompts
RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan -H github.com >> ~/.ssh/known_hosts

WORKDIR /app/solidity

# Clone the seismic-solidity repository using SSH
RUN --mount=type=ssh git clone -b seismic git@github.com:SeismicSystems/seismic-solidity.git .

# Build the solc binary
RUN mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release \
             -DCMAKE_CXX_FLAGS="-Wno-error=conversion" && \
    make solc -j$(nproc)

FROM ubuntu:jammy-20240212

COPY --from=solc-builder /app/solidity/build/solc/solc /app/solc
WORKDIR /app/root

ENTRYPOINT ["/app/solc"]