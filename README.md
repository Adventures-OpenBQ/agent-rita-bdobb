# agent-rita-bdobb

The recipe for the Rita agent that BDOBB talks to in Adventures in OpenBQ (Episode 6 onward). It takes Rita's source from [openbq-org/agent-rita](https://github.com/openbq-org/agent-rita) at the commit pinned in `sources.lock`, applies the patches in `patches/`, and builds a Docker image on your own machine. Nothing is downloaded from a container registry, and no image is published from here.

## What the patches change

| Patch | Change |
|---|---|
| 0001 | Honor `OPENAI_BASE_URL` in the OpenAI provider, so Rita can use a private OpenAI-compatible model server |
| 0002 | Force the Chat Completions API for that provider |
| 0003 | SSE comment keepalive, so a long model "think" doesn't idle the stream out |
| 0004 | MCP tool schemas: resolve `$ref`/`$defs` and keep constraints |
| 0006 | MCP: don't forward tool calls the schema rejects |
| 0007 | MCP: `patternProperties` maps, strict objects and arrays |
| 0008 | HTML artifacts: tell the model that scripts never run |
| 0009 | The agent tool-queue fix (upstream PR #3's first-parent diff) |
| 0010 | Routes answer a non-JSON body with 400, not 500 |
| 0011 | Follow-up suggestions only on the final answer |
| 0012 | Retry an empty step, also after a client tool |

There is no 0005; it was a compose file, which this recipe does not carry.

## Build

Needs `git` and Docker.

```sh
git clone --branch v6.0.0 https://github.com/Adventures-OpenBQ/agent-rita-bdobb.git
cd agent-rita-bdobb
scripts/build.sh               # builds openbq-rita:6.0.0 for this machine
scripts/build.sh --check-only  # clone, verify and patch only; no Docker
```

`build.sh` refuses to continue if the fetched commit is not the pinned SHA or a patch does not apply. Set `IMAGE=name:tag` to build under another name. Build on the machine that will run Rita (for this series, the NAS), so the image matches its architecture.

If your NAS has Docker but no `git` (`build.sh` needs both), run it there in a throwaway Docker CLI container that adds `git` and `bash` and drives the NAS's own Docker daemon through its socket. From this checkout:

```sh
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD":/recipe -w /recipe \
  docker:27-cli sh -c "apk add -q --no-cache git bash && scripts/build.sh"
```

The image is still built by, and lands in, the NAS's Docker, as `openbq-rita:6.0.0`. On some NAS systems the `docker` binary is not on the SSH `PATH`; call it by its full path. Without git you can't clone this repository on the NAS, so copy the checkout there, for example with `scp -r` from another machine.

## Configure

Copy `rita.env.example` somewhere outside every repository, `chmod 600` it, and fill in the model endpoint. Never commit the filled copy. openbq-docker's `docker-compose.v6.yml` reads it as `rita.env` and runs the image.

## Provenance

The image the series' regression ran for BDOBB v6.0.0 was `ghcr.io/adventures-openbq/openbq-rita:6.0.0` (`sha256:6e422484…`), built from the same upstream commit and patches by the maintainer recipe in Adventures-OpenBQ/agent-rita. That registry image is private and is not needed to follow the series.

Copyright 2026 SecretoftheUniverse.com LLC. Apache-2.0; see LICENSE and NOTICE.
