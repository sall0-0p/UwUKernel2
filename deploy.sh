ROOT_DIR=$PWD

# == clean
rm -rf /Users/bucket/Library/Application\ Support/CraftOS-PC/computer/0/System
rm -rf /Users/bucket/Library/Application\ Support/CraftOS-PC/computer/0/startup.lua
rm -rf out/

mkdir -p out/System/System
mkdir -p out/System/Library

# == version tracking
VERSION_MAJOR="UwUntuCC Alpha 1"
BUILD=$(git rev-list --count HEAD 2>/dev/null || echo 0)

echo "Deploying Build #$BUILD..."

# == compile ts stuff
echo "Building typescript packages"

# launchd
cd packages-ts/launchd
npx tstl
cd "$ROOT_DIR"


# rootfsd
cd packages-ts/ccfsd
npx tstl
cd "$ROOT_DIR"

# rootfsd
cd packages-ts/rootfsd
npx tstl
cd "$ROOT_DIR"


# == copying stuff

# copying kernel
cp -R packages/kernel out/System/System/kernel
cp packages/boot/startup.lua out/startup.lua

# copying launchd
mkdir out/System/System/launchd
cp packages-ts/launchd/init.lua out/System/System/launchd/init.lua

# copying system library
luabundler bundle packages/syslib/init.lua \
  -p "$ROOT_DIR/packages/syslib/?.lua" \
  -p "$ROOT_DIR/packages/syslib/?/init.lua" \
  -o out/System/Library/syslib/init.lua

# copying rootfsd
mkdir out/System/System/rootfsd
cp packages-ts/rootfsd/init.lua out/System/System/rootfsd/init.lua

# copying ccfsd
mkdir out/System/System/ccfsd
cp packages-ts/ccfsd/init.lua out/System/System/ccfsd/init.lua

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