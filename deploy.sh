# clean
rm -rf /Users/bucket/Library/Application\ Support/CraftOS-PC/computer/0
rm -rf out/

# create out
mkdir out/
mkdir out/hdd1
cp -R packages/kernel out/hdd1/kernel
cp startup.lua out/startup.lua
cp test.lua out/test.lua

# deploy
cp -R out /Users/bucket/Library/Application\ Support/CraftOS-PC/computer/0
echo "Deploy complete!"