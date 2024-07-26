rm -rf xodel
gh repo clone xnscu/create xodel -- --depth=1
rm -rf ./lib/model
cp -r xodel/template/lib/model ./lib
cp xodel/template/.vscode/settings.json .vscode
cp xodel/template/.eslintrc.cjs .
rm -rf xodel