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

## Phase 2 — Bundle + package ✅ done 2026-09-04

Bundle: rebrand + re-seal clean; Gatekeeper + asset-free verifiers PASS
(6/6). Package: `Golden-Balloon-MacTimber-1.5.2-Intel-Mac.dmg` (10 MB) +
`.sha256`; DMG checksum and packaged-app re-verify PASS. Remaining
user-install test moved to Phase 3.

## Phase 3 — Hardware validation (the v1.0 gate) ✅ done 2026-09-04 → v1.0

The single biggest unknown — **WebGPU (wgpu-native → Metal) on Intel Iris
Plus — is answered: it works.**

- [x] Build from fresh checkout passes (first-clone build, 2026-09-04)
- [x] Renderer `webgpu` on Iris Plus (no `--gl` override); 1280×960 @ 2×,
      60 Hz fifo, no visual corruption, clean exit
- [x] ROM (US 1.1) validates and loads; gameplay confirmed working
- [x] No `std::bad_variant_access`-class crash (the Starship-port caution)
- [x] DMG mounted, app installed to `/Applications`, launched via the
      documented Gatekeeper flow — no "damaged" error

Watch item (non-blocking): 4 audio underruns in a ~2.5 min session.
**v1.0 cut** — hardware + macOS recorded in CHANGELOG.md; attach the DMG +
`.sha256` to a GitHub release.

## Phase 4 — Upstream contribution (next step)

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

- **Pin bumps:** v1.6.0 went stable and the pin is bumped (2026-09-04) —
  upstream also renamed the bundle to `Golden Balloon.app` (engine binary
  still `mdkr64`), and the scripts track that. Next: rebuild + abbreviated
  Phase 3 checklist on the Intel Mac, then release
  `v1.1 (tracks goldenballoon v1.6.0)`. Same procedure for future bumps.
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
| wgpu→Metal on Intel Iris Plus | **Confirmed working 2026-09-04** |
| Upstream x86_64 CMake path | In-tree, hash pinned, unshipped (verified in RESEARCH.md) |
| `verify_unsigned_release.sh` arm64 hardcode | Worked around (direct verifier calls); upstream PR candidate |
| GitHub Intel runners | Available (`macos-15-intel`) until ~Fall 2027 |
| Deployment target 14.0 below Tahoe | Ships untested — only Tahoe hardware available |
