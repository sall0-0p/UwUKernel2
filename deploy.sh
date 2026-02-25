ROOT_DIR=$PWD

# == clean
rm -rf /Users/bucket/Library/Application\ Support/CraftOS-PC/computer/0/System
rm -rf /Users/bucket/Library/Application\ Support/CraftOS-PC/computer/0/startup.lua
rm -rf out/

mkdir -p out/System/System
mkdir -p out/System/Library

# == version tracking
BUILD_FILE=".build"
VERSION_MAJOR=">-< UwUntu 0.1.0"

if [ ! -f "$BUILD_FILE" ]; then echo 0 > "$BUILD_FILE"; fi

BUILD=$(cat "$BUILD_FILE")
BUILD=$((BUILD + 1))
echo "$BUILD" > "$BUILD_FILE"

echo "Deploying Build #$BUILD..."

# == compile teal stuff
echo "Building teal packages"

# # rootfsd
# cd packages-tl/rootfsd
# cyan build
# cd "$ROOT_DIR"

# == compile ts stuff
echo "Building typescript packages"

# rootfsd
cd packages-ts/rootfsd
npx tstl
cd "$ROOT_DIR"

# == copying stuff

# copying kernel
cp -R packages/kernel out/System/System/kernel
cp packages/boot/startup.lua out/startup.lua

echo "$ROOT_DIR/packages/syslib/?.lua;$ROOT_DIR/packages/syslib/?/init.lua"

# copying launchd
luabundler bundle packages/launchd/init.lua \
  -p "$ROOT_DIR/packages/launchd/?.lua" \
  -p "$ROOT_DIR/packages/launchd/?/init.lua" \
  -o out/System/System/launchd/init.lua

# copying system library
luabundler bundle packages/syslib/init.lua \
  -p "$ROOT_DIR/packages/syslib/?.lua" \
  -p "$ROOT_DIR/packages/syslib/?/init.lua" \
  -o out/System/Library/syslib/init.lua

# copying rootfsd
mkdir out/System/System/rootfsd
cp packages-ts/rootfsd/init.lua out/System/System/rootfsd/init.lua

# == generate version.lua
cat > out/System/System/kernel/version.lua <<EOF
return {
    major = "$VERSION_MAJOR",
    build = $BUILD,
    string = "$VERSION_MAJOR (Build $BUILD)"
}
EOF

# == deploy
cp -R out/* /Users/bucket/Library/Application\ Support/CraftOS-PC/computer/0/
echo "Deploy complete!"

# == craftos-pc via CLI
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