#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

USER="$(whoami)"
ENV_PATH="${ENV_PATH:-mainnet}"
MARKER_FILE="/home/$USER/.local/share/sth-core/$ENV_PATH/.snapshot_restored"

echo "👤 Running as user: $USER"
echo "🌐 Network: $ENV_PATH"

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

  # Restore snapshot only once (first-time setup)
  if [ ! -f "$MARKER_FILE" ]; then
    echo "📦 First-time setup detected on mainnet. Downloading and restoring snapshot..."
    wget -q "$SNAPSHOT_URL"
    tar -zxf "$SNAPSHOT_FILE"
    rm "$SNAPSHOT_FILE"

    cd /home/$USER/app/packages/core
    yarn sth snapshot:restore --blocks 1-8133951

    touch "$MARKER_FILE"
    echo "✅ Snapshot restored and marker file created at $MARKER_FILE"
  else
    echo "✅ Snapshot already restored previously. Skipping restore."
  fi

  # Start node for mainnet
  # yarn sth relay:start --network=$ENV_PATH
  yarn sth core:run --network=$ENV_PATH
else
  echo "🚫 Not mainnet — skipping snapshot restore."
  yarn full:testnet
fi