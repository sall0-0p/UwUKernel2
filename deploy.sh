# clean
rm -rf /Users/bucket/Library/Application\ Support/CraftOS-PC/computer/0/SystemVolume
rm -rf /Users/bucket/Library/Application\ Support/CraftOS-PC/computer/0/startup.lua
rm -rf out/

mkdir -p out/SystemVolume/System
mkdir -p out/SystemVolume/Library

# version tracking
BUILD_FILE=".build"
VERSION_MAJOR=">-< UwUntu 0.1.0"

if [ ! -f "$BUILD_FILE" ]; then echo 0 > "$BUILD_FILE"; fi

BUILD=$(cat "$BUILD_FILE")
BUILD=$((BUILD + 1))
echo "$BUILD" > "$BUILD_FILE"

echo "Deploying Build #$BUILD..."

# copying kernel
cp -R packages/kernel out/SystemVolume/System/kernel
cp packages/boot/startup.lua out/startup.lua

echo "$PWD/packages/syslib/?.lua;$PWD/packages/syslib/?/init.lua"

# copying launchd
luabundler bundle packages/launchd/init.lua -p "$PWD/packages/launchd/?.lua" -p "$PWD/packages/launchd/?/init.lua" -o out/SystemVolume/System/launchd/init.lua

# copying system library
luabundler bundle packages/syslib/init.lua -p "$PWD/packages/syslib/?.lua" -p "$PWD/packages/syslib/?/init.lua" -o out/SystemVolume/Library/syslib/init.lua

# generate version.lua
cat > out/SystemVolume/System/kernel/version.lua <<EOF
return {
    major = "$VERSION_MAJOR",
    build = $BUILD,
    string = "$VERSION_MAJOR (Build $BUILD)"
}
EOF

# deploy
cp -R out/* /Users/bucket/Library/Application\ Support/CraftOS-PC/computer/0/
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