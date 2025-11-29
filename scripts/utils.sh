#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/constants.sh"

wait_for_postgres() {
    echo "Waiting for Postgres to become healthy..."
    while true; do
        status=$(docker inspect --format='{{.State.Health.Status}}' "$POSTGRES_CONTAINER" 2>/dev/null || echo "starting")

        if [ "$status" = "healthy" ]; then
            echo "Postgres is healthy"
            break
        elif [ "$status" = "unhealthy" ]; then
            echo "Postgres is UNHEALTHY — check logs with 'make logs'"
            exit 1
        else
            echo "Current status: $status… waiting 1s"
            sleep 1
        fi
    done
}   

cleanup_infra() {
    echo
    echo "Stopping infra..."
    cd "$PROJECT_ROOT"
    docker compose --env-file "$ENV_FILE" -f "$INFRA_COMPOSE_FILE" down
}
