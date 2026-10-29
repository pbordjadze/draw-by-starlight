#!/usr/bin/env bash
# Runs a Swift toolchain command for the package: a `swift` on the PATH when there is one (a
# session without Docker can unpack a Linux toolchain from swift.org and put its usr/bin first),
# else inside the swift:6.2 Docker image.
#   tools/swift.sh build -c release
#   tools/swift.sh test
# Extra mounts (Docker only): set STARLIGHT_MOUNT=/host/dir to expose it at the same path in the container.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v swift >/dev/null 2>&1; then
  # Builds outside the repository, where scratch output belongs.
  exec swift "$1" --package-path "$ROOT" --scratch-path "${STARLIGHT_SCRATCH:-/tmp/starlight-build}" "${@:2}"
fi
if ! docker info >/dev/null 2>&1; then
  (dockerd >/tmp/dockerd.log 2>&1 &)
  for _ in $(seq 1 30); do docker info >/dev/null 2>&1 && break; sleep 1; done
fi
MOUNTS=(-v "$ROOT:$ROOT")
if [[ -n "${STARLIGHT_MOUNT:-}" ]]; then MOUNTS+=(-v "$STARLIGHT_MOUNT:$STARLIGHT_MOUNT"); fi
exec docker run --rm "${MOUNTS[@]}" -w "$ROOT" swift:6.2-noble swift "$@"
