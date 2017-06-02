#!/usr/bin/env bash
docker run --rm -it -v /containers/eth:/root/.ethereum ethereum/client-go:alpine --fast --cache 512 console
