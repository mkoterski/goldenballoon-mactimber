# RESEARCH.md — goldenballoon-mactimber

Research-phase findings (instructions §0), compiled 2026-09-03. Purpose: confirm
upstream state, series conventions, and toolchain feasibility for an Intel Mac
(x86_64) build/bundle/package wrapper around
[akratch/goldenballoon](https://github.com/akratch/goldenballoon), before any
scaffolding or build scripts are written.

**Bottom line: no architectural blockers. Upstream already anticipates an
x86_64 macOS build — this is a packaging/verification effort, not a port.**

---

## 1. Upstream: akratch/goldenballoon

- **Pinned version: `v1.5.2`** (latest stable, published 2026-08-25). A
  `v1.6.0` beta (online multiplayer) appeared 2026-09-02 — pre-release, not a
  pin target. Release cadence is fast (5 releases in Aug 2026 alone).
- **Build system:** single CMake project (CMake ≥ 3.16, C11); native and
  browser builds share one `CMakeLists.txt` (browser goes through Emscripten
  via `tools/web/build_web.sh`). macOS packaging is a layer of first-party bash
  scripts under `macos/Scripts/`.
- **Current release matrix:** Linux x86_64 (AppImage + tar.gz), Windows x64
  (MinGW cross-build zip), **macOS arm64 only** (`…-macos-arm64-unsigned.dmg`).
  CI (`.github/workflows/macos-release.yml`) runs on `macos-14` (arm64) with
  `--arch arm64` hardcoded.
- **x86_64 readiness — the key finding:** no NEON/SSE intrinsics, no
  arch-specific assembly, no hardcoded `CMAKE_OSX_ARCHITECTURES`. Upstream pins
  `-ffp-contract=off` specifically for cross-arch float determinism. The two
  per-arch binaries both have x86_64 paths in-tree already:
  - **wgpu-native v29.0.1.1** (Metal backend): fetched at configure time,
    SHA-256-pinned; `cmake/webgpu_artifact.cmake` already carries the hash for
    `wgpu-macos-x86_64-release.zip`.
  - **SDL2 2.32.10**: release builds compile it from source;
    `build_release_sdl2.sh` accepts `--arch x86_64`. The dylib is bundled into
    `Contents/Frameworks` (no Homebrew dependency at runtime).
  - `build_app_bundle.sh --arch x86_64` maps directly to
    `-DCMAKE_OSX_ARCHITECTURES=x86_64`.
- **Upstream intent:** `docs/sprints/S4-platform-breadth.md` contains
  "US-1 — Play on an Intel Mac" and milestone "M2 — macOS universal binary"
  with a full task list — **planned, unstarted**. No Intel-Mac issue/PR exists
  in their tracker; no maintainer rejection; no competing Intel port. Their
  `docs/PLATFORM_ACCEPTANCE.md` already lists a manual "Launch on an Intel
  Mac" route. → The §7 upstream-contribution path is wide open.
- **Known constraints:**
  - Configure step needs **network access** (hash-verified wgpu fetch), or
    `MDKR_WGPU_LOCAL_CACHE` pointing at the pinned zip.
  - Default **deployment target 13.0** (Ventura). Lower is adjustable via
    `--deployment-target` but untested upstream.
  - Single-configure universal builds fail at link (one wgpu arch per
    configure); x86_64-only is the clean path, universal needs the lipo dance
    their sprint doc describes.
  - **Main unknown: WebGPU-on-Metal on Intel-era GPUs** (AMD/Intel iGPU). The
    OpenGL fallback (`MDKR_RENDERER=gl`) is "diagnostic-only" on macOS. Real
    Intel hardware must answer this before v1.0.
- **ROM model:** strict bring-your-own-ROM, read at **runtime** (file picker /
  `--rom` flag) — no build-time asset extraction, unlike the prior ports.
  Launcher validates SHA-256 (US 1.1 / EU 1.1 only). Releases are scanned
  asset-free (`verify_asset_free.sh`). Wrapper must mirror this: never commit
  or bundle ROM data.
- **License:** MIT ("Golden Balloon contributors") — compatible with the
  series' MIT (c) mkoterski wrapper license.

## 2. Prior-series conventions (perfectdark-macvanta, spaghettikart-maccheese, starship-macalfa)

What the three repos **actually** are (differs from the instructions file in
places — see §5):

- **Scripts-only wrappers.** No git submodules, no `vendor/`, no `patches/`
  in any repo. Upstream is **cloned at build time** into a gitignored dir by
  the build script (stale-clone detection, `git pull` on rebuild).
- **Script suite** (zsh, `set -eo pipefail`, `VERSION` var, embedded header
  changelog starting at **v0.10**), 7 scripts with a short prefix
  (`pdmv-`/`spmc-`/`smca-`): initial-setup, build, bundle, package,
  run wrapper, systeminfo, collect-crash.
- **Build:** `-DCMAKE_OSX_ARCHITECTURES=x86_64` (identical in all three),
  Homebrew bootstrap at `/usr/local`, CLT check, `-j$(sysctl -n hw.logicalcpu)`,
  Mach-O validation via `file`. Logs to top-level `logs/<stage>-<timestamp>.log`
  via `tee -a`, emoji step headers, `════` summary box with 👉 next-step hint.
  **No `--clean`/`--verbose` flags exist in the series.**
- **Bundle:** heredoc `Info.plist`; real binary as `Contents/MacOS/<Name>Bin`
  plus a zsh cwd-wrapper; `NSHighResolutionCapable`; sips+iconutil icons.
  Bundle ID majority convention: **`com.mkoterski.<repo-name>`** (pdmv deviates).
  `LSMinimumSystemVersion`: 10.9 (pdmv, spmc) vs 12.0 (smca) — inconsistent.
- **Package:** pure `hdiutil` styled DMG (UDRW → AppleScript Finder styling →
  UDZO zlib-9 → verify), output `dist/<name>-Intel-Mac.dmg`.
  **No codesign step exists in any script** and no notarize script — the only
  signing guidance is spmc's README lesson: on Tahoe, `xattr -cr` alone is not
  enough; ad-hoc `codesign --sign - --force --deep` is required.
- **No CI in any repo** (no `.github/` at all).
- **Versioning:** scripts start at **v0.10**; README rule: "will reach v1.0
  after confirmed end-to-end working on a clean Intel Mac running macOS Tahoe"
  (spmc adds "on both a source build and a nightly CI build"). Only
  starship-macalfa has a `CHANGELOG.md` (Keep-a-Changelog-ish, short entries);
  its v1.0 entry lists concrete "Confirmed Working" facts incl. exact hardware.
- **Docs:** common README skeleton (description → sibling cross-links → ⚠️ ROM
  blockquote with hash → Confirmed Working + screenshots + exact hardware →
  Requirements → Quick Start → Scripts table → Versioning → Credits). MIT
  license (c) 2026 mkoterski; upstream credited in README + plist copyright.
- **Hygiene warning:** pdmv and spmc accidentally committed ROM files and
  logs/crash zips. **Not a convention to copy** — starship-macalfa (gitignored
  ROMs + `roms/README.md`) is the clean model.
- **Starship bug history (instructions §0.1):** `std::bad_variant_access` is a
  **Metal-backend crash, open upstream, permanently worked around** by
  defaulting to OpenGL on Intel. SDL controller mapping: worked around by
  auto-downloading `gamecontrollerdb.txt`. Relevance here: goldenballoon
  renders via wgpu-native→Metal, a different stack — the Starship Metal bug
  does not transfer directly, but "verify the Metal path on Intel GPUs before
  trusting it" absolutely does. Goldenballoon vendors
  `sdl_gamecontrollerdb` already, so the controller workaround is built in.
- **Template choice:** starship-macalfa for structure/hygiene (it is the
  codified "scripts-only (pdmv conventions)" restructure), newest script fixes
  from pdmv v0.17 / spmc v0.13, `com.mkoterski.*` bundle ID, spmc's README depth.

## 3. CI & toolchain landscape (Sept 2026)

- **GitHub-hosted Intel runners exist:** `macos-15-intel` (free tier) and
  `macos-26-intel`; `macos-13` retired Dec 2025. Intel runner retirement is
  ~Fall 2027. Google Dawn's own CI uses `macos-15-intel` today.
- **Cross-compilation fallback:** `-DCMAKE_OSX_ARCHITECTURES=x86_64` on arm64
  hosts works unchanged (fat SDK); arm64 runners can smoke-test x86_64
  binaries under Rosetta 2 through the macOS 27 image generation (~2027).
  Rosetta 2 is removed in macOS 28 (Fall 2027) except a game-compat shim.
- **Homebrew Intel is effectively dead:** Tier 3 since Sept 2026 — no new
  Intel bottles, full removal Sept 2027. Barely matters here: upstream builds
  SDL2 from source and fetches wgpu prebuilts. Host tools (cmake, pkg-config,
  ninja) on an Intel Mac now install from source with warnings.
- **Deployment target:** Ventura 13 is EOL (Sept 2025) but is the pragmatic
  floor for 2017-era Intel hardware; Sonoma 14 is the "still patched" line;
  Tahoe 26 is the last Intel macOS (only 4 Intel models). Upstream default
  13.0 fits; final call pending the actual macOS on the test Mac.
- **wgpu-native** ships first-class `x86_64` macOS archives (targets 10.13+);
  SDL2/SDL3 have not dropped Intel mac support.

## 4. Blockers & unknowns

1. **None blocking scaffold/build.** All required x86_64 pieces exist.
2. **Unverified:** WebGPU(Metal)-on-Intel-GPU rendering quality/stability —
   the single biggest v1.0 risk; only answerable on the real Intel Mac.
3. ~~Test hardware state~~ **Confirmed 2026-09-03:** MacBook Pro 13" 2020
   (i7-1068NG7, Intel Iris Plus integrated GPU, 32 GB), macOS **Tahoe 26.5.2**,
   CLT 26.6 (clang 21, SDK 26.5, no Xcode.app), Homebrew 6.0.13 at
   `/usr/local` with cmake 4.2.3 / ninja 1.13.2 / git 2.53 / Python 3.14
   already installed, 582 GB free, native Intel. Same hardware class the prior
   three ports were validated on. Toolchain fully ready — nothing to
   bootstrap. The integrated Iris Plus GPU is precisely the WebGPU-on-Metal
   risk case, making it the right validation machine. Note: the machine runs
   Tahoe, so lower `LSMinimumSystemVersion` values ship untested (series
   precedent: target "macOS Tahoe and later" anyway).
4. Upstream moves fast — expect to bump the pin (v1.6.0 stable is likely soon).

## 5. Deviations from the instructions file (justified by research)

| Instructions said | Reality / proposal |
|---|---|
| Git submodule at `vendor/goldenballoon` pinned to tag | Series convention is clone-at-build-time (gitignored). Proposal: keep series convention but **pin via `git checkout v1.5.2`** in the build script instead of tracking main (priors pull main — the pin is our improvement). |
| `scripts/` dir with `build-macos.sh` etc. | Series uses prefix-named scripts at repo root: `gbmt-initial-setup.sh`, `gbmt-build-macos.sh`, `gbmt-bundle-macos.sh`, `gbmt-package-macos.sh`, `run-gbmt-macos.sh`, `gbmt-systeminfo.sh`, `gbmt-collect-crash.sh`. |
| `patches/` dir | No prior repo has one; upstream needs no patches for x86_64. Omit until needed. |
| Start at v0.1 | Series starts at **v0.10**. |
| Ad-hoc codesign "consistent with prior releases" | Priors have **no** codesign step (a gap — Tahoe requires ad-hoc signing per spmc's lesson). Upstream's bundle script ad-hoc signs after every Mach-O mutation. We include ad-hoc signing (via upstream's scripts) — better than priors, matching instructions' intent. |
| `LSMinimumSystemVersion` e.g. 11.0 | Priors used 10.9/12.0; upstream defaults 13.0. Proposal: **13.0**, revisit after Mac diagnostic. |
| CI workflow required | No prior repo has CI, but `macos-15-intel` makes it easy and spmc's v1.0 wording anticipates CI builds. Proposal: include `.github/workflows/build.yml` on `macos-15-intel`. |
| Local dir `/Users/matthias/Documents/GitHub/goldenballoon-mac<codename>` | Confirmed; scaffolding happens from Windows, builds/tests on the Intel Mac (available, running in parallel). |
| notarize.sh optional | Keep optional/omit initially; upstream has a signed-notarized flow to crib from if Developer ID appears later. |

**Key structural decision:** upstream already ships complete macOS packaging
scripts (`build_release_sdl2.sh`, `build_app_bundle.sh`, `create_dmg.sh`,
`verify_asset_free.sh`, provenance stamping) that accept `--arch x86_64`.
Unlike the prior ports, we should **wrap upstream's own pipeline** rather than
reimplement bundle/DMG machinery — our scripts add: version pinning, series
logging/UX conventions, ROM handling, run wrapper, sysinfo/crash collection,
and Intel-specific checks (fail loudly on any non-x86_64 Mach-O slice).

## 5a. Sign-off decisions (matthias, 2026-09-03)

1. **Vendoring:** clone-at-build into gitignored `goldenballoon/`, pinned via
   `git checkout v1.5.2` (series convention + deliberate pin).
2. **Packaging:** wrap upstream's `macos/Scripts/` pipeline with
   `--arch x86_64` (ad-hoc signing, asset-free scan, provenance for free);
   wrapper adds pinning, series logging/UX, run wrapper, Intel slice checks.
3. **CI:** yes — `.github/workflows/build.yml` on `macos-15-intel`.
4. **Deployment target: 14.0 (Sonoma)** — deviates from upstream's 13.0
   default by choice (oldest still-patched macOS); passed via
   `--deployment-target 14.0`, validated only on Tahoe 26.5.2 hardware.

## 6. v1.0 promotion criteria (per instructions §2/§8 + series precedent)

v0.10 → v1.0 only after, on the real Intel Mac (no Rosetta): clean-checkout
build passes, app launches from `/Applications` via DMG, ROM validates and
loads, gameplay reached, **full race completed without crash**, controller +
audio + HUD parity with arm64 build noted, Gatekeeper behavior documented.
CHANGELOG v1.0 entry records exact hardware + macOS version (series style).

## 7. Primary sources

- github.com/akratch/goldenballoon @ v1.5.2 (`macos/README.md`,
  `macos/Scripts/*`, `cmake/webgpu_artifact.cmake`,
  `docs/sprints/S4-platform-breadth.md`, `docs/PLATFORM_ACCEPTANCE.md`)
- github.com/mkoterski/{perfectdark-macvanta, spaghettikart-maccheese, starship-macalfa}
- actions/runner-images README + macos-13 retirement changelog +
  macos-15-intel announcement (github.blog, 2025-09/2026-02)
- docs.brew.sh/Support-Tiers; brew.sh 5.0.0 (2025-11) & 6.0.0 (2026-06) posts
- gfx-rs/wgpu-native releases (v29.0.1.1); google/dawn releases; SDL3
  README-macos; endoflife.date/macos; cibuildwheel platform docs
