rm -rf xodel
gh repo clone ${app:-jaqn} xodel -- --depth=1
rm -rf src/lib/model
cp -r xodel/src/lib/model src/lib
rm -rf xodel