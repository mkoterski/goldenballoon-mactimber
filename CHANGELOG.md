# Changelog

All notable changes to the goldenballoon-mactimber scripts. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions are wrapper
versions, each noting the upstream tag it tracks.

## [Unreleased]

- 2026-09-04: first build confirmed on real Intel hardware (MacBook Pro 13"
  2020, Tahoe 26.5.2) — setup + build clean, valid x86_64 `mdkr64.app`
  (sealed, verify PASS, reports `mdkr64 1.5.2`). Roadmap Phase 1 done.
- Documented that the app is intentionally named `mdkr64.app` (upstream's
  engine name), not `gbmt.app` — see README.

## [0.10] — 2026-09-03 (tracks goldenballoon v1.5.2)

- Initial scaffold: full gbmt-* script suite wrapping upstream's own
  `macos/Scripts/` pipeline with `--arch x86_64`, deployment target 14.0.
- CI on `macos-15-intel`; research findings in RESEARCH.md.
- Unverified on real Intel hardware — pre-v1.0.
