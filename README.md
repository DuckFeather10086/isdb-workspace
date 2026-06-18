# isdb-workspace

> A self-hosted **ISDB-T** TV stack — tune, descramble, record, and
> stream live to your LAN. One Go orchestrator driving three focused
> Rust engines.

This is the **umbrella repo** (主仓库). The four components live in
their own repositories and are wired in here as **git submodules**
(子仓库), so a single recursive clone gives you the whole stack at
known-good commits.

```bash
git clone --recursive https://github.com/DuckFeather10086/isdb-workspace.git
# or, if you already cloned without --recursive:
git submodule update --init --recursive
```

## The repos

| Component | Role | Lang | Repository | Pinned branch |
|-----------|------|------|------------|---------------|
| **isdbd** | 调度器 / orchestrator — owns adapters, EPG, scheduler, recorder, live HLS, web UI + REST API | Go | [DuckFeather10086/isdbd](https://github.com/DuckFeather10086/isdbd) | `feat/b25-pipeline-and-webui` |
| **dvbr** | Tuner frontend — DVB API v5 `tune` / `scan` / `epg` over direct ioctls (no `libdvbv5`) | Rust | [DuckFeather10086/dvbr](https://github.com/DuckFeather10086/dvbr) | `fix/sdt-arib-b24` |
| **libaribb25-rs** (`b25`) | ARIB STD-B25 descrambler — MULTI2 decrypt via B-CAS card over PC/SC | Rust | [DuckFeather10086/libaribb25-rs](https://github.com/DuckFeather10086/libaribb25-rs) | `main` |
| **arib-b24-rs** (`b24`) | ARIB STD-B24 text decoder — SDT/EIT bytes → UTF-8 (titles, service names, captions) | Rust | [DuckFeather10086/arib-b24-rs](https://github.com/DuckFeather10086/arib-b24-rs) | `main` |

> **Note on pinned branches.** `dvbr` and `isdbd` are currently pinned
> to in-flight feature branches (work not yet merged to `main`). After a
> recursive clone the submodules sit in detached HEAD at the pinned
> commit; to develop, `cd` in and `git checkout <branch>` (the tracked
> branch is recorded in `.gitmodules`). Run `git submodule update --remote`
> to fast-forward each submodule to the tip of its tracked branch.

## How it fits together

```
                    ┌──────────────────────────────────────────────────────┐
                    │                     isdbd  (Go)  ── 调度器             │
                    │  EPG ingest · cron scheduler · recorder · live HLS     │
                    │  tuner.Pool (refcounted leases) · fanout · web UI/API  │
                    └───────────────┬──────────────────────────┬────────────┘
                          spawns subprocesses                serves
                                    │                            │
  /dev/dvb/adapterN                 ▼                            ▼
  (Linux DVB v5) ──────►  dvbr tune  ──TS──►  b25  ──plain TS──►  fanout ──┬──► recorder ──► .mp4
                          (Rust)              (Rust)                       │
                             │                  ▲                         └──► ffmpeg ──► HLS
                             │ uses             │ B-CAS card                    (.m3u8/.ts) ──► browser
                             ▼                  │ via pcscd
                          arib-b24 (Rust): SDT service names + EIT programme text → UTF-8
```

The hot path per active channel is a two-process pipe —
`dvbr tune … | b25 -v 0 - -` — broadcast 1→N by `fanout` (slow
consumers are dropped, never block live playback). `dvbr epg` feeds the
EPG store on a timer.

## Quickstart

```bash
# 1. get everything
git clone --recursive https://github.com/DuckFeather10086/isdb-workspace.git
cd isdb-workspace

# 2. build the Rust engines + the Go daemon
./bootstrap.sh build          # see "Build" below for the manual steps

# 3. configure + run
#    edit isdbd/configs/*.toml and channels.json for your adapter,
#    then run the daemon (serves the web UI + REST API):
cd isdbd && go run ./cmd/isdbd -config configs/isdbd.toml
```

Open the web UI in a browser (Live / Guide / Schedules / Recordings).

## Build

The two Rust build roots and the Go module build independently:

```bash
# Rust: arib-b24 + dvbr share the root virtual workspace
cargo build --release
#   → dvbr/target/release/dvbr        (root target/ via the workspace)

# Rust: b25 has its own inner workspace (excluded from the root one)
cargo build --release --manifest-path libaribb25-rs/Cargo.toml
#   → libaribb25-rs/target/release/b25

# Go daemon
cd isdbd && go build ./...
```

`bootstrap.sh` wraps these and verifies the submodules are checked out.

### Why two Cargo roots?

The root `Cargo.toml` is a virtual workspace over `arib-b24-rs` + `dvbr`
(`dvbr` depends on `arib-b24` by path). `libaribb25-rs` is **excluded**
because it carries its own inner workspace (`aribb25` lib + `b25` bin),
so it is built with its own `--manifest-path`.

## Releases

Pre-built tarballs for **linux/amd64** and **linux/arm64** are attached to
every [GitHub Release](https://github.com/DuckFeather10086/isdb-workspace/releases).

```bash
# pick your arch
curl -L "https://github.com/DuckFeather10086/isdb-workspace/releases/download/v1.0.0/isdbd-v1.0.0-linux-amd64.tar.gz" | tar xz
cd isdbd-v1.0.0-linux-amd64

# install system-wide
sudo cp isdbd dvbr b25 /usr/local/bin/
sudo mkdir -p /etc/isdbd && sudo cp configs/* /etc/isdbd/
sudo cp isdbd.service /etc/systemd/system/
```

Each tarball contains:

```
isdbd-vX.Y.Z-linux-{arch}/
├── isdbd              # Go daemon (web UI embedded)
├── dvbr               # Rust tuner
├── b25                # Rust B25 descrambler
├── configs/           # example TOML + channels.json
├── isdbd.service      # systemd unit
├── README.md
└── VERSION
```

### Cutting a release

1. Bump `version` in `dvbr/Cargo.toml`, `libaribb25-rs/aribb25/Cargo.toml`,
   and `libaribb25-rs/b25/Cargo.toml` to the desired tag.
2. Commit: `chore: bump versions for vX.Y.Z`.
3. Tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z" && git push --tags`.
4. CI builds both archs and attaches the tarballs to the release.

## Runtime requirements

- A USB ISDB-T tuner at `/dev/dvb/adapter*/`.
- `ffmpeg` / `ffprobe` on `$PATH` (HLS remux + A/V-skew correction).
- For scrambled (non-FTA) channels: **`pcscd`** running + a B-CAS card
  reader (polkit rule for the invoking user). FTA-only setups can run
  without `b25`.

## Maintainer notes

- Each submodule is a normal git clone — `cd` in, branch, commit, push
  as usual. The umbrella repo only records *which commit* of each it
  points at; bump a pointer with `git add <submodule> && git commit`.
- The canonical channel-matching rules live in `dvbr`
  (`config::find_entry`); `isdbd` mirrors them. Don't fork that logic.
- Architecture invariants (one process per adapter, stderr→slog,
  validate-bytes watchdog, drop-don't-block fanout) are documented in
  `isdbd/CLAUDE.md`.
