# Rita Aperture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run Rita with Claude through a private Tailscale Aperture gateway and reuse the 18 client live tests.

**Architecture:** Extend the pinned, patched Rita recipe with a native Anthropic provider. Configure its base URL for Aperture and make helper calls honor DEFAULT_MODEL. Keep the instance and evidence isolated.

**Tech Stack:** Bun, TypeScript, AI SDK 6, @ai-sdk/anthropic 3.x, Docker, Vitest.

**Spec:** ../specs/2026-10-25-rita-aperture-design.md

## Global Constraints

- No public gateway/provider policy changes.
- No release tag movement or changes to running automation.
- No credentials in tracked files, logs, or command arguments.
- No acceptance of Aperture terms or expansion of tailnet permissions without action-time user confirmation.

## Review Focus

- Missing Anthropic configuration must fail clearly rather than fall through to OpenAI.
- Base URLs with and without trailing /v1 must reach exactly /v1/messages.
- Helpers must use DEFAULT_MODEL while preserving an explicit per-call model override.
- Tool-result turns and SSE text must survive the Anthropic adapter.
- API failures must propagate and never become a successful test result.

### Task 1: Provider and helper model routing

**Files:** generated build/rita/src/lib/providers.ts, build/rita/src/lib/llm.ts, build/rita/package.json, build/rita/bun.lock, build/rita/tests/integration/aperture-provider.test.ts; preserve edits as patches/0013*.patch.

**Interfaces:** resolveModel(rawModelId) returns LanguageModel; singleShotLlm(prompt, opts?) returns Promise<string>. New config: ANTHROPIC_BASE_URL, ANTHROPIC_API_KEY and DEFAULT_MODEL=anthropic:<gateway-model>.

- [ ] Apply existing recipe patches in a new generated checkout; run baseline tests.
- [ ] Add real HTTP boundary tests for Anthropic single-shot, streaming/tool result round trips, missing-provider rejection, URL normalization, explicit override and provider errors. Run before implementation and retain expected failures.
- [ ] Add compatible Anthropic SDK; register Anthropic when keyed, list the configured Claude default, normalize /v1 once, and reject unknown explicit providers rather than OpenAI fallback. Use DEFAULT_MODEL between per-call override and historical helper default.
- [ ] Run focused and complete suite plus typecheck. Preserve source changes and tests as recipe patch.

### Task 2: Reproducible audit configuration and image

**Files:** rita-aperture.env.example, README.md, scripts/test-aperture.sh; own output runtime runner/evidence.

- [ ] Document gateway setup, managed versus passthrough auth, environment settings and known test limits.
- [ ] Verify recipe applies from its pinned SHA; build uniquely tagged image and exercise startup/helper paths via local controlled gateway.
- [ ] Run 18 unchanged native live tests once real Aperture is authorized, reachable and grants Claude access. Record actual model, gateway and all failures/skips.
- [ ] Obtain final independent review, fix material findings, commit local recipe changes.

## Execution ruling

User explicitly approved implementation in this session. Execute inline under that authorization without another routine plan approval. Gateway setup may block live verification but not isolated source work. Preserve the audit worktree while live verification remains pending.
