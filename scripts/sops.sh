#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 <encrypt|decrypt|encrypt-staged>" >&2
    exit 1
}

if [ "$#" -lt 1 ]; then
    COMMAND="encrypt-staged"
else
    COMMAND="$1"
    shift || true
fi

collect_sops_files_all() {
    mapfile -t FILES < <(find . -type f -name "*.sops.*" || true)

    if [ "${#FILES[@]}" -eq 0 ]; then
        return 0
    fi

    local filtered=()
    for FILE in "${FILES[@]}"; do
        local base
        base="$(basename "$FILE")"
        if [ "$base" = ".sops.yaml" ] || [ "$base" = ".sops.yml" ]; then
            echo "[SKIP] SOPS config file (not a secret): $FILE"
            continue
        fi
        filtered+=("$FILE")
    done

    FILES=("${filtered[@]}")
}

collect_sops_files_staged() {
    mapfile -t FILES < <(
        git diff --cached --name-only --diff-filter=ACM -- '*.sops.*' || true
    )

    if [ "${#FILES[@]}" -eq 0 ]; then
        return 0
    fi

    local filtered=()
    for FILE in "${FILES[@]}"; do
        local base
        base="$(basename "$FILE")"
        if [ "$base" = ".sops.yaml" ] || [ "$base" = ".sops.yml" ]; then
            echo "[SKIP] SOPS config file (not a secret): $FILE"
            continue
        fi
        filtered+=("$FILE")
    done

    FILES=("${filtered[@]}")
}

is_encrypted() {
    local file="$1"
    grep -q '"sops"' "$file" 2>/dev/null || grep -q '^sops:' "$file" 2>/dev/null
}

is_encrypted_staged() {
    local file="$1"
    local content
    content="$(git show ":$file" 2>/dev/null || true)"
    printf '%s' "$content" | grep -q '"sops"' || printf '%s' "$content" | grep -q '^sops:'
}

encrypt_all() {
    collect_sops_files_all

    if [ "${#FILES[@]}" -eq 0 ]; then
        echo "No .sops.* files found."
        return 0
    fi

    for FILE in "${FILES[@]}"; do
        if is_encrypted "$FILE"; then
            echo "[SKIP] Already encrypted: $FILE"
        else
            echo "[ENC] Encrypting: $FILE"
            sops --encrypt --in-place "$FILE"
        fi
    done
}

decrypt_all() {
    collect_sops_files_all

    if [ "${#FILES[@]}" -eq 0 ]; then
        echo "No .sops.* files found."
        return 0
    fi

    for FILE in "${FILES[@]}"; do
        if is_encrypted "$FILE"; then
            echo "[DEC] Decrypting: $FILE"
            sops --decrypt --in-place "$FILE"
        else
            echo "[SKIP] Not encrypted: $FILE"
        fi
    done
}

encrypt_staged() {
    collect_sops_files_staged

    if [ "${#FILES[@]}" -eq 0 ]; then
        echo "No staged .sops.* files to process."
        return 0
    fi

    echo "Processing staged .sops.* files..."
    for FILE in "${FILES[@]}"; do
        if [ ! -f "$FILE" ]; then
            echo "[SKIP] $FILE no longer exists in working tree (maybe deleted)."
            continue
        fi

        if is_encrypted "$FILE"; then
            echo "[SKIP] Already encrypted (working tree): $FILE"
        else
            echo "[ENC] Encrypting (working tree): $FILE"
            sops --encrypt --in-place "$FILE"
            git add "$FILE"
        fi
    done

    echo "Verifying staged versions are encrypted..."
    local failed=0
    for FILE in "${FILES[@]}"; do
        if is_encrypted_staged "$FILE"; then
            echo "[OK] Staged file is encrypted: $FILE"
        else
            echo "[ERROR] Staged file is NOT encrypted: $FILE"
            failed=1
        fi
    done

    if [ "$failed" -ne 0 ]; then
        echo "One or more .sops.* files are not encrypted in the index. Aborting commit." >&2
        exit 1
    fi
}

case "$COMMAND" in
    encrypt)
        encrypt_all
        ;;
    decrypt)
        decrypt_all
        ;;
    encrypt-staged)
        encrypt_staged
        ;;
    *)
        usage
        ;;
esac
