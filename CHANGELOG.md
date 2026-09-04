# Changelog

All notable changes to the goldenballoon-mactimber scripts. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions are wrapper
versions, each noting the upstream tag it tracks.

## [Unreleased]

- 2026-09-04: full pipeline confirmed working on real Intel hardware
  (MacBook Pro 13" 2020, i7-1068NG7, Iris Plus, Tahoe 26.5.2):
  - Setup + build: valid x86_64 `mdkr64.app`, sealed, verify PASS
    (`mdkr64 1.5.2`), no patches needed.
  - Bundle: rebrand + re-seal; Gatekeeper + asset-free verifiers PASS (6/6).
  - Package: `Golden-Balloon-MacTimber-1.5.2-Intel-Mac.dmg` (10 MB) +
    `.sha256`, DMG and packaged-app re-verify PASS.
  - Run: US 1.1 ROM validated + loaded; **WebGPU works on Intel Iris Plus**
    (main v1.0 unknown answered); clean exit. Minor: 4 audio underruns.
  - Roadmap Phases 1–2 done; v1.0 pending the DMG `/Applications` install
    test.
- Documented that the app is intentionally named `mdkr64.app` (upstream's
  engine name), not `gbmt.app` — see README.

## [0.10] — 2026-09-03 (tracks goldenballoon v1.5.2)

- Initial scaffold: full gbmt-* script suite wrapping upstream's own
  `macos/Scripts/` pipeline with `--arch x86_64`, deployment target 14.0.
- CI on `macos-15-intel`; research findings in RESEARCH.md.
- Unverified on real Intel hardware — pre-v1.0.
