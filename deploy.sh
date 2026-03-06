#!/bin/bash
set -e

ROOT_DIR=$PWD
OUT_DIR="$ROOT_DIR/out"
CRAFTOS_DIR="/Users/bucket/Library/Application Support/CraftOS-PC/computer/0"

echo "Cleaning build directories..."
rm -rf "$CRAFTOS_DIR/System"
rm -rf "$CRAFTOS_DIR/startup.lua"
rm -rf "$OUT_DIR"

mkdir -p "$OUT_DIR/System/System"
mkdir -p "$OUT_DIR/System/Library"

# version control
VERSION_MAJOR="UwUntuCC Alpha 1"
BUILD=$(git rev-list --count HEAD 2>/dev/null || echo 0)
echo "Deploying Build #$BUILD..."

# bulding packages
echo "Building all workspace packages..."
for pkg_json in $(find src/daemons src/libsystem src/utils -name "package.json" 2>/dev/null); do
  PKG_DIR=$(dirname "$pkg_json")

  if grep -q '"build":' "$pkg_json"; then
    NEEDS_BUILD=0
    OUTPUT_FILE="$PKG_DIR/init.lua"

    if [ ! -f "$OUTPUT_FILE" ]; then
      NEEDS_BUILD=1
    elif [ "tsconfig.base.json" -nt "$OUTPUT_FILE" ]; then
      NEEDS_BUILD=1
    else
      NEWER_FILES=$(find "$PKG_DIR" -type f \( -name "*.ts" -o -name "*.json" \) -newer "$OUTPUT_FILE" | head -n 1)
      if [ -n "$NEWER_FILES" ]; then
        NEEDS_BUILD=1
      fi
    fi

    if [ "$NEEDS_BUILD" -eq 1 ]; then
      echo " -> Recompiling $PKG_DIR..."
      npm run build --workspace="$PKG_DIR"
    else
      echo " -> Skipping $PKG_DIR (up to date)"
    fi
  fi
done

echo "Packaging system components..."
for pkg_json in $(find src/daemons src/libsystem src/utils -name "package.json" 2>/dev/null); do
  PKG_DIR=$(dirname "$pkg_json")

  TARGET_PATH=$(jq -r '.uwuntu.target // empty' "$pkg_json")
  PKG_TYPE=$(jq -r '.uwuntu.type // empty' "$pkg_json")
  ENTRY_LUA=$(jq -r '.uwuntu.entry // empty' "$pkg_json")
  PKG_NAME=$(jq -r '.name' "$pkg_json")

  if [ -n "$TARGET_PATH" ]; then
    echo " -> Processing $PKG_NAME ($PKG_TYPE)..."
    mkdir -p "$(dirname "$OUT_DIR/$TARGET_PATH")"

    if [ "$PKG_TYPE" == "lua-bundle" ]; then
      echo $PKG_DIR
      luabundler bundle "$PKG_DIR/$ENTRY_LUA" \
        -p "$PKG_DIR/src/?.lua" \
        -p "$PKG_DIR/src/?/init.lua" \
        -o "$OUT_DIR/$TARGET_PATH"
    else
      cp "$PKG_DIR/init.lua" "$OUT_DIR/$TARGET_PATH"
    fi
  fi
done

# moving bootloader
echo "Copying kernel and boot files..."
cp -R src/kernel/src "$OUT_DIR/System/System/kernel"
cp src/boot/startup.lua "$OUT_DIR/startup.lua"

cat > "$OUT_DIR/System/System/kernel/version.lua" <<EOF
return {
    major = "$VERSION_MAJOR",
    build = $BUILD,
    string = "$VERSION_MAJOR (Build $BUILD)"
}
EOF

# deploy to emulator
echo "Deploying to CraftOS-PC..."
cp -R "$OUT_DIR/"* "$CRAFTOS_DIR/"
echo "Deploy complete!"

# run emulator
if [[ "$1" == "--cli" ]]; then
    echo "Launching CraftOS-PC (CLI Mode)..."
    CRAFTOS_APP="/Applications/CraftOS-PC.app/Contents/MacOS/craftos"
    if command -v craftos &> /dev/null; then
      craftos --cli --id 0
    elif [ -f "$CRAFTOS_APP" ]; then
      "$CRAFTOS_APP" --cli --id 0
    else
        echo "Error: Could not find 'craftos' executable."
        echo "Please add it to your PATH or ensure it is in /Applications."
    fi
fi