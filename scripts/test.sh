#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:-}"

case "$SERVICE" in
    books)
        bun x nx affected --target=test || true
        ;;

    "")
        echo "Argument required to specify which test to run."
        echo "Usage: make test [books]"
        ;;

    *)
        echo "❌ Unknown service: $SERVICE"
        echo "Usage: make test [books]"
        exit 1
        ;;
esac
