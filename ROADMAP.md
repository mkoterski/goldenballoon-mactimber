# ROADMAP — goldenballoon-mactimber

The conceptual path from scaffold (v0.10) to a confirmed Intel Mac release
(v1.0) and beyond. Each phase gates the next.

## Phase 1 — First build on the Intel Mac ✅ done 2026-09-04

Setup + build ran clean on the MacBook Pro 2020 (Tahoe 26.5.2); valid
x86_64 `mdkr64.app`, sealed and verified, reports `mdkr64 1.5.2`. Findings:

- wgpu fetch and SDL2-from-source worked; clang 21 fine, no `patches/` needed.
- Setup log warning `refs/tags/v1.5.2 ... is not a commit!` is harmless — git
  noting the annotated tag object; checkout landed on the pinned commit.
- The app is named `mdkr64.app`, not `gbmt.app` — upstream's engine name,
  kept by design (see README "Why is the app called mdkr64.app?").
- Only build noise: expected SDL2 deprecation warnings and the Homebrew
  Tier 3 notice.

## Phase 2 — Bundle, package, install like a user (next step)

`./gbmt-bundle-macos.sh` → `./gbmt-package-macos.sh`, then: mount the DMG,
drag to `/Applications`, launch via the documented Gatekeeper flow. A
"damaged" error (vs. the normal unidentified-developer prompt) fails this
phase.

## Phase 3 — Hardware validation (the v1.0 gate)

The single biggest unknown: **WebGPU (wgpu-native → Metal) on the Intel
Iris Plus GPU**. Checklist (mirrors README Versioning + instructions §8):

- [ ] Clean `--clean` build from a fresh checkout passes
- [ ] App launches from `/Applications`; Gatekeeper behaves as documented
- [ ] Diagnostics panel shows `Renderer: webgpu` (no `--gl` override)
- [ ] ROM (US/EU 1.1) validates and loads; gameplay reached
- [ ] **Full race completed without crash** (watch for
      `std::bad_variant_access`-class errors — the Starship port's Intel
      Metal failure mode; different stack here, same caution)
- [ ] No fractured sky/terrain or repeated-logo corruption (upstream's own
      play-test criteria)
- [ ] Controller input, audio, widescreen HUD on par with the arm64 build
- [ ] If WebGPU fails on Iris Plus: document, test `--gl` as diagnostic
      evidence, and file upstream — do NOT ship OpenGL as the default

Then: cut **v1.0**, recording exact hardware + macOS in CHANGELOG.md, and
attach the DMG + `.sha256` to a GitHub release.

## Phase 4 — Upstream contribution (after v1.0)

Upstream has already planned this work but not executed it
(`docs/sprints/S4-platform-breadth.md`: "US-1 — Play on an Intel Mac",
"M2 — macOS universal binary"). Offer:

1. Parameterize `verify_unsigned_release.sh` (`--expected-arch`,
   `--expected-min-os` are hardcoded arm64/13.0) — small, uncontroversial.
2. An `x86_64` (or universal, per their M2 task list: fetch both wgpu
   slices, `lipo -create`) lane in `macos-release.yml`, citing our
   validated hardware results.

Keep this wrapper alive regardless — it owns Intel-specific validation and
faster iteration even if upstream ships its own Intel builds.

## Phase 5 — Maintenance

- **Pin bumps:** upstream moves fast (v1.6.0 with online multiplayer is in
  beta). When it goes stable: bump `UPSTREAM_TAG` in all gbmt-* scripts,
  rebuild, re-run the Phase 3 checklist (abbreviated), release as
  `v1.1 (tracks goldenballoon v1.6.0)`.
- **CI runner sunset:** `macos-15-intel` retires ~Fall 2027. Fallback:
  cross-compile on an arm64 runner (`CMAKE_OSX_ARCHITECTURES=x86_64`,
  Rosetta smoke test — itself gone with macOS 28 images), or a self-hosted
  runner on the Intel Mac.
- **Homebrew Intel removal (2027-09):** only host tools are affected
  (cmake/pkg-config/python3); runtime deps are already brew-free. Plan:
  vendor host-tool bootstrap or pin last-working versions.
- **Notarization (optional):** if a Developer ID appears, upstream's
  `sign_and_notarize.sh` / `notarize_artifact.sh` flow can be wrapped the
  same way — kept strictly separate from the default ad-hoc path.

## Known blockers / open questions

| Item | Status |
| --- | --- |
| wgpu→Metal on Intel Iris Plus | **Unknown — Phase 3 answers it** |
| Upstream x86_64 CMake path | In-tree, hash pinned, unshipped (verified in RESEARCH.md) |
| `verify_unsigned_release.sh` arm64 hardcode | Worked around (direct verifier calls); upstream PR candidate |
| GitHub Intel runners | Available (`macos-15-intel`) until ~Fall 2027 |
| Deployment target 14.0 below Tahoe | Ships untested — only Tahoe hardware available |
