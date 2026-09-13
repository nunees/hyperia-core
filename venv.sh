#!/bin/bash

VENV_DIR=".venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "[ERROR] Virtual environment not found: $VENV_DIR"
    echo "Creating a new env"
    python3 -m venv .venv
fi

echo "[INFO] Activating Python virtual environment..."

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

echo "[OK] Environment activated."
echo "Python: $(which python)"
echo "Version: $(python --version)"

exec "$SHELL"

source .venv/bin/activate