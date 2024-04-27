rm -rf xodel
gh repo clone xnscu/create xodel -- --depth=1
rm -rf src/lib/model
cp -r xodel/template/src/lib/model src/lib
cp xodel/template/.vscode/settings.json .vscode
cp xodel/template/.eslintrc.cjs .
rm -rf xodel