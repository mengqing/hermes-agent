#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_TEMPLATE="${HERMES_BOOTSTRAP_CONFIG_TEMPLATE:-$REPO_ROOT/deploy/prod/hermes-config.env}"
ENV_TEMPLATE="${HERMES_BOOTSTRAP_ENV_TEMPLATE:-$REPO_ROOT/deploy/prod/hermes.env.example}"
HERMES_HOME="${HERMES_HOME:-$REPO_ROOT/.hermes}"
ENV_FILE="$HERMES_HOME/.env"

if [ -x "$REPO_ROOT/venv/bin/hermes" ]; then
  HERMES_BIN="$REPO_ROOT/venv/bin/hermes"
elif [ -x "$REPO_ROOT/.venv/bin/hermes" ]; then
  HERMES_BIN="$REPO_ROOT/.venv/bin/hermes"
elif command -v hermes >/dev/null 2>&1; then
  HERMES_BIN="$(command -v hermes)"
else
  echo "hermes binary not found (checked venv/.venv/PATH)" >&2
  exit 1
fi

if [ ! -f "$CONFIG_TEMPLATE" ]; then
  echo "missing config template: $CONFIG_TEMPLATE" >&2
  exit 1
fi

if [ ! -f "$ENV_TEMPLATE" ]; then
  echo "missing env template: $ENV_TEMPLATE" >&2
  exit 1
fi

mkdir -p "$HERMES_HOME"
touch "$ENV_FILE"

while IFS='=' read -r key value; do
  if [ -z "$key" ] || [[ "$key" == \#* ]]; then
    continue
  fi

  current_line="$(grep -E "^${key}=" "$ENV_FILE" || true)"
  if [ -z "$current_line" ]; then
    printf "%s=%s\n" "$key" "$value" >> "$ENV_FILE"
    continue
  fi

  current_value="${current_line#*=}"
  if [ -z "$current_value" ] && [ -n "$value" ]; then
    sed -i.bak "s|^${key}=.*$|${key}=${value}|" "$ENV_FILE"
    rm -f "$ENV_FILE.bak"
  fi
done < "$ENV_TEMPLATE"

set -a
. "$CONFIG_TEMPLATE"
set +a

HERMES_HOME="$HERMES_HOME" "$HERMES_BIN" config set model.provider "$MODEL_PROVIDER"
HERMES_HOME="$HERMES_HOME" "$HERMES_BIN" config set model.default "$MODEL_DEFAULT"
HERMES_HOME="$HERMES_HOME" "$HERMES_BIN" config set model.base_url "$MODEL_BASE_URL"
HERMES_HOME="$HERMES_HOME" "$HERMES_BIN" config set model.api_mode "$MODEL_API_MODE"

echo "Bootstrapped Hermes production config in $HERMES_HOME"
