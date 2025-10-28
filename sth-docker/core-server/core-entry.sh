#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

USER="$(whoami)"
ENV_PATH="${ENV_PATH:-mainnet}"
MARKER_FILE="/home/$USER/.local/share/sth-core/$ENV_PATH/.snapshot_restored"

# Default flags from ENV
SKIP_DOWNLOAD="${SKIP_DOWNLOAD:-false}"
SKIP_RESTORE="${SKIP_RESTORE:-false}"

# Parse CLI arguments (CLI overrides ENV)
for arg in "$@"; do
  case $arg in
    --skip-download)
      SKIP_DOWNLOAD=true
      shift
      ;;
    --skip-restore)
      SKIP_RESTORE=true
      shift
      ;;
  esac
done

echo "👤 Running as user: $USER"
echo "🌐 Network: $ENV_PATH"
echo "⚙️  Options: SKIP_DOWNLOAD=$SKIP_DOWNLOAD, SKIP_RESTORE=$SKIP_RESTORE"

# Install core
yarn setup:clean

# Testnet/Mainnet config
cd /home/$USER/app/packages/core
yarn sth config:publish --network=$ENV_PATH --reset

# Restore snapshot only if mainnet
if [ "$ENV_PATH" = "mainnet" ]; then
  SNAPSHOT_DIR="/home/$USER/.local/share/sth-core/$ENV_PATH/snapshots"
  SNAPSHOT_FILE="1-8133951.tgz"
  SNAPSHOT_URL="https://snapshots.smartholdem.io/$SNAPSHOT_FILE"

  mkdir -p "$SNAPSHOT_DIR"
  cd "$SNAPSHOT_DIR"

  if [ ! -f "$MARKER_FILE" ]; then
    echo "📦 First-time setup detected on mainnet."

    if [ "$SKIP_DOWNLOAD" = false ]; then
      echo "⬇️  Downloading and extracting snapshot..."
      wget -q "$SNAPSHOT_URL"
      tar -zxf "$SNAPSHOT_FILE"
      rm "$SNAPSHOT_FILE"
    else
      echo "⏭️  Skipping snapshot download/extraction."
    fi

    if [ "$SKIP_RESTORE" = false ]; then
      echo "🧩 Restoring snapshot blocks..."

      cd /home/$USER/app/packages/core
      yarn sth snapshot:restore --blocks 1-8133951
    else
      echo "⏭️  Skipping snapshot restore."
    fi

    touch "$MARKER_FILE"
    echo "✅ Snapshot process complete and marker file created at $MARKER_FILE"
  else
    echo "✅ Snapshot already restored previously. Skipping restore."
  fi

  cd /home/$USER/app/packages/core

  echo "🚀 Starting node for mainnet..."
  yarn sth core:run --network=$ENV_PATH
else
  echo "🚫 Not mainnet — skipping snapshot restore."
  yarn full:testnet
fi