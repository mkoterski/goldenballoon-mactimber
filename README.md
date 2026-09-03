# goldenballoon-mactimber

macOS **Intel (x86_64)** build, bundle, and packaging scripts for
[akratch/goldenballoon](https://github.com/akratch/goldenballoon) — the native
source port of the 1997 N64 kart racer, built from its decompilation. Upstream
ships Apple Silicon (arm64), Windows, and Linux builds; this unofficial,
community wrapper adds the missing Intel Mac build — targeting **Intel Macs
(x86_64) on macOS Sonoma 14 and later** (validated on Tahoe).

Follows the same conventions as
[perfectdark-macvanta](https://github.com/mkoterski/perfectdark-macvanta),
[spaghettikart-maccheese](https://github.com/mkoterski/spaghettikart-maccheese),
and [starship-macalfa](https://github.com/mkoterski/starship-macalfa).
Codename: *Timber* — the tiger who runs the races while Diddy's away.

> ⚠️ **You need a legally obtained Diddy Kong Racing N64 ROM to play.**
> Supported versions are **US 1.1** and **EU 1.1** (`.z64`/`.v64`/`.n64`);
> the game validates the dump by SHA-256 at runtime and refuses others.
> No ROM or game data is ever bundled, committed, or required to *build* —
> see [roms/README.md](roms/README.md).

---

## Status

**v0.10 — scaffold, unverified.** No build has been confirmed on real Intel
hardware yet; see [ROADMAP.md](ROADMAP.md) for the path to v1.0 and
[RESEARCH.md](RESEARCH.md) for why this is expected to be a routine build:
upstream's build system already carries x86_64 support (pinned
`wgpu-macos-x86_64` prebuilt, SDL2-from-source with `--arch x86_64`) — it has
simply never been shipped.

---

## How this differs from the sibling ports

Upstream ships a complete first-party macOS packaging pipeline
(`macos/Scripts/`: pinned SDL2 build, app bundling with ad-hoc signing, DMG
creation, asset-free verification). Unlike the siblings, these scripts
**wrap that pipeline with `--arch x86_64`** instead of reimplementing it.
The wrapper owns: the version **pin** (upstream `v1.5.2`, bumped
deliberately), series logging/UX, bundle rebranding
(`com.mkoterski.goldenballoon-mactimber`), x86_64-only enforcement (any
arm64/universal output fails the build), and the run/diagnostics tooling.

---

## Requirements

- Intel Mac (x86_64) on macOS 14+ — validated hardware: MacBook Pro 13" 2020
  (i7-1068NG7, Iris Plus), macOS Tahoe 26.5
- Xcode Command Line Tools (`xcode-select --install`)
- Homebrew with `cmake`, `pkg-config`, `python3`, `git` (installed
  automatically; note Intel macOS is Homebrew **Tier 3** since 2026-09 —
  installs may compile from source)
- **Network access during build**: upstream fetches a SHA-256-pinned
  wgpu-native prebuilt at CMake configure time
- ~5 GB free disk space

---

## Quick Start

```
git clone https://github.com/mkoterski/goldenballoon-mactimber.git
cd goldenballoon-mactimber
chmod +x *.sh
./gbmt-initial-setup.sh    # 1. toolchain check + clone upstream @ v1.5.2
./gbmt-build-macos.sh      # 2. SDL2 (x86_64) + engine + ad-hoc-signed .app
./gbmt-bundle-macos.sh     # 3. rebrand + re-seal + verify (x86_64, ROM-free)
./gbmt-package-macos.sh    # 4. distributable DMG + SHA-256 sidecar
./run-gbmt-macos.sh        # 5. play (put your ROM in roms/ first)
```

## Scripts

| Script | Purpose |
| --- | --- |
| `gbmt-initial-setup.sh` | One-time host check (CLT, Homebrew, tools) + pinned upstream clone |
| `gbmt-build-macos.sh` | Build pinned SDL2 + engine, assemble `mdkr64.app` via upstream, x86_64-only enforced. Flags: `--clean`, `--verbose` |
| `gbmt-bundle-macos.sh` | Rebrand bundle ID, ad-hoc re-seal, run upstream's Gatekeeper + asset-free verifiers with `--expected-arch x86_64` |
| `gbmt-package-macos.sh` | DMG via upstream `create_dmg.sh` → `dist/Golden-Balloon-MacTimber-<ver>-Intel-Mac.dmg` + `.sha256` |
| `run-gbmt-macos.sh` | Dev launcher; auto-passes a ROM from `roms/`; `--gl` forces the diagnostic OpenGL renderer |
| `gbmt-systeminfo.sh` | Host/GPU/toolchain snapshot for bug reports |
| `gbmt-collect-crash.sh` | Zip DiagnosticReports + logs for a bug report (never ROMs) |

---

## Renderer notes (Intel GPUs)

Golden Balloon's qualified visual path is **WebGPU** (wgpu-native → Metal).
How Metal-via-wgpu behaves on Intel-era GPUs (Intel Iris/AMD) is the main
open question for v1.0 — it is exactly what hardware validation must answer.
`./run-gbmt-macos.sh --gl` forces upstream's OpenGL backend, which is
**diagnostic-only**: use it to isolate renderer problems, not to play.

## Gatekeeper ("unidentified developer")

Releases are **ad-hoc signed** (integrity seal, no Developer ID, no
notarization). On first launch macOS will refuse with an unidentified-
developer warning:

1. Attempt the launch once (double-click, let it refuse).
2. Open **System Settings → Privacy & Security**, scroll down, click
   **Open Anyway**, then confirm **Open**.

On older macOS the classic right-click → **Open** → **Open** shortcut also
works. A **"damaged"** error is not normal — it means the seal is broken;
re-run `./gbmt-bundle-macos.sh` and file an issue. (Lesson from the sibling
ports: on Tahoe, `xattr -cr` alone is not sufficient — the ad-hoc seal is
required.)

---

## Versioning

Scripts start at `v0.10` and will reach `v1.0` only after confirmed
end-to-end working on a clean Intel Mac running macOS Tahoe: clean
`--clean` build, DMG install to `/Applications`, Gatekeeper behavior as
documented, ROM load, and a **full race completed without crashing** — with
controller input, audio, and HUD on par with upstream's arm64 build. After
v1.0, versions track the upstream pin, e.g. `v1.1 (tracks goldenballoon
v1.6.0)`. See [CHANGELOG.md](CHANGELOG.md) and [ROADMAP.md](ROADMAP.md).

## CI

`.github/workflows/build.yml` builds and packages on GitHub's native Intel
runner (`macos-15-intel`, available until ~Fall 2027). Hosted CI validates
the toolchain, binary architecture, bundle seal, and `--version` startup —
it **cannot** validate real GPU gameplay. Hardware testing gates v1.0.

## Credits

- [akratch/goldenballoon](https://github.com/akratch/goldenballoon) — the
  Golden Balloon port and its first-class macOS packaging pipeline (MIT)
- The Diddy Kong Racing decompilation contributors
- Sibling conventions: perfectdark-macvanta / spaghettikart-maccheese /
  starship-macalfa
- Intel Mac packaging scripts: mkoterski

This project is unaffiliated with Nintendo or Rare. It contains no game
assets; bring your own legally obtained ROM.
