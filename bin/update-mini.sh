rm -rf xodel
gh repo clone ${app:-xodel} xodel -- --depth=1
rm -rf src/lib/model
cp -r xodel/src/lib/model src/lib
cp xodel/.vscode/settings.json .vscode
cp xodel/.eslintrc.cjs .
rm -rf xodel