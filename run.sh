#!/usr/bin/env bash
# Reads .env and launches the app with values passed as --dart-define.
# Usage: ./run.sh   (defaults to chrome; pass another device id as $1)
set -a
[ -f .env ] && . ./.env
set +a

DEVICE="${1:-chrome}"

flutter run -d "$DEVICE" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=FLW_PUBLIC_KEY="$FLW_PUBLIC_KEY"
