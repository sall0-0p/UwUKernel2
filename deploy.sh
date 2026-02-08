# clean
rm -rf /Users/bucket/Library/Application\ Support/CraftOS-PC/computer/0
rm -rf out/

mkdir -p out/hdd1

# version tracking
BUILD_FILE=".build"
VERSION_MAJOR=">-< UwUntu 0.1.0"

if [ ! -f "$BUILD_FILE" ]; then echo 0 > "$BUILD_FILE"; fi

BUILD=$(cat "$BUILD_FILE")
BUILD=$((BUILD + 1))
echo "$BUILD" > "$BUILD_FILE"

echo "Deploying Build #$BUILD..."

# copying
cp -R packages/kernel out/hdd1/kernel
cp startup.lua out/startup.lua
cp test.lua out/test.lua

# generate version.lua
cat > out/hdd1/kernel/version.lua <<EOF
return {
    major = "$VERSION_MAJOR",
    build = $BUILD,
    string = "$VERSION_MAJOR (Build $BUILD)"
}
EOF

# deploy
cp -R out /Users/bucket/Library/Application\ Support/CraftOS-PC/computer/0
echo "Deploy complete!"

# craftos-pc via CLI
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