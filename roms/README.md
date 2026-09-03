# roms/

Place your **legally obtained** Diddy Kong Racing N64 ROM here
(`.z64`, `.v64`, or `.n64`). `run-gbmt-macos.sh` passes the first one it
finds to the game via `--rom`; without one, the in-app launcher asks.

- Supported dumps: **US 1.1** and **EU 1.1** only — the game validates the
  complete image by SHA-256 at runtime and refuses other revisions
  (JP, US 1.0, EU 1.0 are recognized and rejected).
- The ROM is read in place at runtime. It is never copied into the build,
  the app bundle, or the DMG — releases are verified asset-free.
- Everything in this directory except this README is gitignored. Never
  commit ROM files.
