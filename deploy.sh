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