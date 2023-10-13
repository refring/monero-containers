[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository is forked from https://github.com/farcaster-project/containers

# Containers

A list of Docker images built for supporting integration tests for https://github.com/refring/monero-rpc-php

- **monerod**: [`monerod` image](./monerod/)
- **monero-wallet-rpc**: [`monero-wallet-rpc` image](./monero-wallet-rpc/)
- **monero-lws**: [`monero-lws` image](./monero-lws/)

## About

All images are built with the same aim: flexibility and ease of use in GitHub Actions.

The later support adding `services` to a `job` described in yaml format, the docker command is issued with `docker create` and it is not possible to modify the Docker `CMD` attribute. Thus images aim to be configured for CI context through `env` variable with a default `CMD`.

To be able to reuse these images in other contexts no `ENTRYPOINT` is specified. Containers can be created by changing the `CMD` argument, e.g.

```
docker run --rm ghcr.io/refring/containers/monerod:latest /usr/bin/monerod\
    --regtest\
    --p2p-bind-ip 0.0.0.0\
    --rpc-bind-ip 0.0.0.0\
    --zmq-rpc-bind-ip 0.0.0.0\
    --confirm-external-bind\
    --non-interactive\
    --fixed-difficulty 1\
    --offline
```

## Licensing

The code in this project is licensed under the [MIT License](LICENSE)
