# Rita through Tailscale Aperture

The user chose Aperture so Claude can run the same Rita integration tests previously exercised with Qwen.

## Approaches

OpenRouter directly was initially selected, then superseded by the user’s explicit Aperture choice. An additional OpenAI-to-Anthropic proxy would add another untested component. The proposed route uses Rita’s AI SDK with a native Anthropic provider and configurable Aperture base URL.

## Proposed implementation

Work from the pinned Rita recipe and its existing patches in a separate audit checkout/image. Add an AI SDK 6 compatible Anthropic provider. Explicitly route the configured Claude model through Aperture’s /v1/messages endpoint. Leave the public gateway Qwen-only. Ensure single-shot helper calls honor the configured provider/model, preserving existing defaults when no model is configured. Do not silently send Claude requests to OpenAI or Qwen when provider setup is missing.

Aperture owns upstream credentials or billing; client authentication will follow the gateway’s actual configuration. Do not extract existing Claude subscription tokens. Do not authorize new tailnet access or accept service terms without the user’s action-time confirmation.

## Verification

Provider routing and missing-configuration tests, helper model-selection tests, type checking, isolated image build, gateway model discovery, streamed pong, and the existing 18 client live tests: 3 chat/widget tests, 12 dashboard authoring tests, 3 table-model tests. Helper endpoint smoke checks supplement those suites. A skipped or unrun test is not a pass. The client suites use in-memory stores and a reference backend; they do not replace native UI/device gates.

## Current access state

Local Tailscale is connected. No visible peer has Aperture or gateway in its hostname. The official Aperture sign-in page requires login; the signup page stops at a Continue action that accepts terms of service. No account was created, no terms accepted, no tailnet access expanded, and no Claude inference sent. Gateway URL and authenticated account setup remain unresolved.

## Approval

User approved the short design and implementation on 2026-10-25. Release tags remain held. Existing automation and device apps are unchanged.
