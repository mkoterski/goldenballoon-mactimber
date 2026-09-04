# Changelog

All notable changes to the goldenballoon-mactimber scripts. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions are wrapper
versions, each noting the upstream tag it tracks.

## [1.0] — 2026-09-04 (tracks goldenballoon v1.5.2)

Confirmed end-to-end working on real Intel hardware: **MacBook Pro 13" 2020
(i7-1068NG7, Intel Iris Plus, 32 GB), macOS Tahoe 26.5.2**. Scripts promoted
v0.10 → v1.0 unchanged.

Confirmed working:

- Build from fresh checkout: valid x86_64-only `mdkr64.app`, ad-hoc sealed,
  verify PASS, reports `mdkr64 1.5.2`; no patches needed (clang 21).
- Bundle: rebrand + re-seal; Gatekeeper + asset-free verifiers PASS (6/6).
- Package: `Golden-Balloon-MacTimber-1.5.2-Intel-Mac.dmg` (10 MB) +
  `.sha256`; DMG and packaged-app re-verify PASS.
- Install: DMG mounted, app installed to `/Applications`, launched via the
  documented Gatekeeper "Open Anyway" flow — no "damaged" error.
- Gameplay: US 1.1 ROM SHA-256-validated and loaded; **WebGPU
  (wgpu-native → Metal) works on Intel Iris Plus** — the main v1.0 unknown,
  answered. 1280×960 @ 2×, 60 Hz fifo, clean exit. Minor: 4 audio underruns
  in ~2.5 min (watch item).
- Documented: the app is intentionally named `mdkr64.app` (upstream's engine
  name), not `gbmt.app` — see README.

## [0.10] — 2026-09-03 (tracks goldenballoon v1.5.2)

- Initial scaffold: full gbmt-* script suite wrapping upstream's own
  `macos/Scripts/` pipeline with `--arch x86_64`, deployment target 14.0.
- CI on `macos-15-intel`; research findings in RESEARCH.md.
- Unverified on real Intel hardware — pre-v1.0.
