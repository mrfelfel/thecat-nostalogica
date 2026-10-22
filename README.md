# thecat-nostalogica

Build recipes for a [Retro Messenger](https://github.com/RetroMessenger/retro-messenger)
desktop client that talks to the self-hosted **CatGram** MTProto server instead of Telegram.

Retro Messenger is upstream C++/GTKmm on TDLib; nothing here is a fork. The repo holds
the patches, the build scripts, and CI that turn upstream into a self-hosted build.

## Patches

| Patch | Targets | What it does |
|---|---|---|
| `patches/tdlib-selfhosted.patch` | TDLib `a17f87c4` | Replaces Telegram's DC list with one self-hosted DC, swaps in the server's RSA public key, and fills in a default `api_id`/`api_hash` when the client sends none |
| `patches/client-selfhosted.patch` | Retro Messenger | Uses a local patched TDLib (`-DTD_PATCH_DIR`), drops the `TG_APP_ID`/`TG_APP_HASH` login gate |
| `patches/client-calls-macos.patch` | Retro Messenger | Wires the upstream `ntgcalls.macos-arm64` prebuilt for voice/video on Apple Silicon |
| `patches/client-rlottie-arm64.patch` | Retro Messenger | Disables rlottie's AArch32-only NEON drawing path on 64-bit ARM, which otherwise fails to link |

## CI

`.github/workflows/build.yml` runs three jobs:

- **verify-tdlib** — patches TDLib and compiles `tdcore`. Fast; this is the canary for
  the TDLib side.
- **build-linux** — full client on `ubuntu-24.04`, x86_64.
- **build-macos** — full client on `macos-14` (Apple Silicon), with calls.

Artifacts are attached to each run. Both client jobs take optional `dc_host` / `dc_port`
inputs from a manual run (`workflow_dispatch`).

## Building locally

```bash
./scripts/apply.sh ~/retro-build          # fetches TDLib + Retro and applies every patch
cd ~/retro-build/retro
./scripts/deps.sh                          # Debian/Ubuntu only
./scripts/build-lnx.sh -DTD_PATCH_DIR=~/retro-build/td
```

On macOS with Homebrew:

```bash
brew install gtkmm4 gstreamer gst-plugins-base ninja pkg-config gperf
cd ~/retro-build/retro
cmake -B build -GNinja -DCMAKE_BUILD_TYPE=Release -DTD_PATCH_DIR=~/retro-build/td
cmake --build build -j "$(sysctl -n hw.ncpu)"
./build/src/retro-messenger
```

The dev login code on the server is `12345`.

## Pointing at a different server

Every value lives in TDLib's CMake cache; no source edits needed:

```bash
cmake ... \
  -DSELF_HOSTED_DC_HOST=62.220.127.238 \
  -DSELF_HOSTED_DC_PORT=30001 \
  -DSELF_HOSTED_DC_ID=2 \
  -DSELF_HOSTED_API_ID=2040 \
  -DSELF_HOSTED_API_HASH=...
```

The server's `help.getConfig` must advertise a reachable address (`TELESRV_ADVERTISE_IP`)
or the client keeps reconnecting to the compiled-in DC only.

## RSA key

`tdlib-selfhosted.patch` embeds the public half of `data/server_rsa.pem`. If that key is
regenerated on the server, re-export it and update the patch:

```bash
openssl rsa -in server_rsa.pem -RSAPublicKey_out
```

## Upstream

- Retro Messenger: https://github.com/RetroMessenger/retro-messenger (MIT; bundled
  ntgcalls is LGPL-3.0)
- TDLib: https://github.com/tdlib/td

Not affiliated with either project.
