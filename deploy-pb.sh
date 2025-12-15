#!/bin/bash

# PocketBase deployment script
# Syncs migrations and data from local to server

set -e

# Default values
MIGRATIONS_PATH=""
DATA_PATH=""
DEST=""
STOP_PB=true

show_help() {
    echo "Usage: $0 --dest user@host:/path [OPTIONS]"
    echo ""
    echo "Required:"
    echo "  --dest=user@host:/path    Destination server and path"
    echo ""
    echo "Options:"
    echo "  --migrations=./path       Path to pb_migrations directory"
    echo "  --data=./path            Path to pb_data directory"
    echo "  --no-stop                Don't stop PocketBase before sync"
    echo "  --help                   Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --dest=peti@shared:/home/peti/app/bin --migrations=./pb_migrations --data=./pb_data_dev"
    echo "  $0 --dest=user@host:/path --migrations=./pb_migrations"
    exit 0
}

# Parse arguments
while [ $# -gt 0 ]; do
    case $1 in
        --dest=*)
            DEST="${1#*=}"
            ;;
        --migrations=*)
            MIGRATIONS_PATH="${1#*=}"
            ;;
        --data=*)
            DATA_PATH="${1#*=}"
            ;;
        --no-stop)
            STOP_PB=false
            ;;
        --help)
            show_help
            ;;
        *)
            echo "[ERROR] Unknown argument: $1"
            show_help
            ;;
    esac
    shift
done

# Validate required arguments
if [ -z "$DEST" ]; then
    echo "[ERROR] --dest is required"
    show_help
fi

if [ -z "$MIGRATIONS_PATH" ] && [ -z "$DATA_PATH" ]; then
    echo "[ERROR] At least one of --migrations or --data is required"
    show_help
fi

# Parse destination
SERVER="${DEST%%:*}"
REMOTE_PATH="${DEST#*:}"

if [ "$SERVER" = "$DEST" ]; then
    echo "[ERROR] Invalid destination format. Use: user@host:/path"
    exit 1
fi

echo "[INFO] PocketBase Deployment"
echo "[INFO] Server: $SERVER"
echo "[INFO] Remote: $REMOTE_PATH"
echo ""

# Stop PocketBase on server
if [ "$STOP_PB" = true ]; then
    echo "[INFO] Stopping PocketBase on server..."
    ssh $SERVER "cd $REMOTE_PATH && pkill -f pocketbase || true" 2>/dev/null || true
    sleep 2
fi

# Sync migrations
if [ -n "$MIGRATIONS_PATH" ]; then
    # Expand tilde
    MIGRATIONS_PATH="${MIGRATIONS_PATH/#\~/$HOME}"
    if [ ! -d "$MIGRATIONS_PATH" ]; then
        echo "[ERROR] Migrations path not found: $MIGRATIONS_PATH"
        exit 1
    fi
    echo "[INFO] Syncing migrations..."
    rsync -avz --delete "$MIGRATIONS_PATH/" "$SERVER:$REMOTE_PATH/pb_migrations/"
fi

# Sync data
if [ -n "$DATA_PATH" ]; then
    # Expand tilde
    DATA_PATH="${DATA_PATH/#\~/$HOME}"
    if [ ! -d "$DATA_PATH" ]; then
        echo "[ERROR] Data path not found: $DATA_PATH"
        exit 1
    fi
    echo "[INFO] Syncing data..."
    rsync -avz --progress "$DATA_PATH/" "$SERVER:$REMOTE_PATH/pb_data/"
fi

echo ""
echo "[SUCCESS] Sync complete!"
echo ""
echo "To start PocketBase on server:"
echo "  ssh $SERVER 'cd $REMOTE_PATH && nohup ./pocketbase serve --http=127.0.0.1:8090 > pocketbase.log 2>&1 &'"
