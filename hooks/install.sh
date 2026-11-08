#!/usr/bin/env bash
# Install tracked git hooks by symlinking them into .git/hooks/.
# Run from the repo root: bash hooks/install.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_SRC="$REPO_ROOT/hooks"
HOOKS_DST="$REPO_ROOT/.git/hooks"

for hook in "$HOOKS_SRC"/pre-commit; do
    name="$(basename "$hook")"
    target="$HOOKS_DST/$name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "hooks/install.sh: $name already exists and is not a symlink — skipping (back it up first)" >&2
        continue
    fi
    ln -sf "$hook" "$target"
    echo "Installed $name → $target"
done
