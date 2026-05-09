#!/usr/bin/env bash
set -e

# Clean previous build artifacts
rm -rf build/bdist.*/egg dist/*.egg *.egg-info

# Build egg directory structure via setuptools
python3 setup.py bdist_egg --keep-temp 2>&1

# Find the built directory
egg_dir=$(ls -d build/bdist.*/egg 2>/dev/null | head -1)
if [ -z "$egg_dir" ]; then
    echo "ERROR: build directory not found"
    exit 1
fi

# Copy bundled libraries into the egg directory
cp -r telegramer/include/. "$egg_dir/telegramer/include/"

# Clean pycache and .pyc files
find "$egg_dir" -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
find "$egg_dir" -name '*.pyc' -delete 2>/dev/null || true

# Determine output egg name from Python version
py_ver=$(python3 -c "import sys; print(f'py{sys.version_info.major}.{sys.version_info.minor}')")
egg_name="dist/Telegramer-2.1.1.4-${py_ver}.egg"

mkdir -p dist
rm -rf "$egg_name"
cp -r "$egg_dir" "$egg_name"

echo "OK: $egg_name ($(find "$egg_name" -type f | wc -l) files)"
