#!/usr/bin/env bash
set -euo pipefail

script_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
canonical_root=${ANTURAS_CANONICAL_ROOT:-}

if [[ -z "$canonical_root" ]]; then
  canonical_root=$(git --no-optional-locks -C "$script_root" worktree list --porcelain | awk '
    /^worktree / { path = substr($0, 10) }
    /^branch refs\/heads\/main$/ { print path; exit }
  ')
fi

if [[ -z "$canonical_root" ]]; then
  echo "Cannot resolve the primary main worktree; set ANTURAS_CANONICAL_ROOT." >&2
  exit 2
fi

python_bin="$canonical_root/tools/tts-bakeoff/.venv/bin/python"
if [[ ! -x "$python_bin" ]]; then
  echo "Missing project UV environment: $python_bin" >&2
  echo "Create or restore the existing tools/tts-bakeoff/.venv before running audio." >&2
  exit 2
fi

exec "$python_bin" "$script_root/tools/structured_audio_generation.py" \
  --canonical-root "$canonical_root" "$@"
