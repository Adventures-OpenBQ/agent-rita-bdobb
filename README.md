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
| 0013 | Claude through Aperture: native Anthropic provider, explicit provider routing, and helper model defaults |
| 0014 | Distinguish model authentication, billing, permissions and rate-limit failures in the visible answer |

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

## Claude through Tailscale Aperture

Use a separate private Rita instance for Claude tests. The public Funnel Rita
remains Qwen-only; do not change its provider keys or policy.

1. Complete [Aperture setup](https://tailscale.com/docs/aperture/get-started).
   Configure Claude access, billing or upstream credentials, and the required
   tailnet grants. Aperture account setup does not itself grant model access.
2. Copy `rita-aperture.env.example` outside every repository and `chmod 600` it.
   Set `ANTHROPIC_BASE_URL` to the gateway URL and `DEFAULT_MODEL` to
   `anthropic:<exact-enabled-model-id>`. The URL can end in `/v1` or `/v1/`;
   Rita sends requests to exactly one `/v1/messages` path.
3. For a managed gateway, leave `ANTHROPIC_API_KEY` blank. Rita sends a
   non-secret placeholder; Aperture uses tailnet identity and injects upstream
   credentials. For API-key passthrough, provide the required provider key in
   the private env file. Do not copy Claude subscription tokens from another
   app; subscription-client compatibility is a separate qualification.
4. Build under a distinct audit image name:
   `IMAGE=rita-aperture:audit scripts/build.sh`.
   Run that image privately on a host or network that can reach the gateway.
   If publishing a test port, bind it to `127.0.0.1` only. Do not add a Funnel.
5. Verify `/agents.json` names the configured Claude model, then send a plain
   streamed query and tool calls. An unavailable provider now fails explicitly
   instead of being passed to the OpenAI provider.

An explicit helper model overrides `DEFAULT_MODEL`. Without an explicit model,
helper routes and tools use `DEFAULT_MODEL`, retaining their historical
`openai:gpt-4o-mini` default only when no model is configured. The chat model
picker still overrides chat's default; it does not change helper defaults.

After `scripts/build.sh --check-only`, run `scripts/test-aperture.sh`. This
installs the frozen dependencies in the generated Linux checkout, runs the
complete Rita suite without external networking, and checks types with
TypeScript 5.9.3. The HTTP boundary tests cover streaming/tool-result rounds,
helper routing, URL normalization, gateway 401 responses, and missing-provider
errors; they do not prove that a real Aperture gateway grants Claude access.

For BDOBB's existing live suites, set `OPENBB_RITA_URL` to the isolated instance
and `OPENBB_BACKEND_URL` to the reference backend. Set `OPENBB_LIVE=1`
to enable the table suite, then run:

```sh
pnpm exec vitest run src/test/integration/rita-live.test.ts \
  src/test/integration/rita-authoring-live.test.ts \
  src/test/integration/rita-table-model-live.test.ts \
  --maxWorkers=1 --minWorkers=1 --testTimeout=300000
```

There are 18 tests at the audited BDOBB revision. They use real model requests,
in-memory dashboard stores, and a reference data backend. They do not qualify
all helper endpoints, native UI, physical devices, or a release by themselves.

## Provenance

The image the series' regression ran for BDOBB v6.0.0 was `ghcr.io/adventures-openbq/openbq-rita:6.0.0` (`sha256:6e422484…`), built from the same upstream commit and patches by the maintainer recipe in Adventures-OpenBQ/agent-rita. That registry image is private and is not needed to follow the series.

Copyright 2026 SecretoftheUniverse.com LLC. Apache-2.0; see LICENSE and NOTICE.

## Version applicability

This shared service recipe applies from BDOBB v6.0.0 onward. Patches0013–0014
are general Rita corrections: provider/helper routing and model access errors.
The native application's provider aggregation hints start in v9.0.0; their
entity-category guidance and transactional refusal belong in v9 and later,
not in v6–v8. Table-model tools themselves already exist in v6.

Test the native source for the target version, not a later checkout. V6 has17
live tests across chat, authoring and table-model suites; v9 adds the provider
hint acceptance case. Outcome-based chart authoring accepts parameters applied
by add_widget or a subsequent set_widget_params. A separate reconfiguration
case still verifies set_widget_params. The injected-save case removes alternate
creation/content tools so its intended rejected write must actually occur.
