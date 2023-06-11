rm -rf xodel
gh repo clone ${app:-jaqn} xodel -- --depth=1
cp -r xodel/src/lib/field.mjs src/lib
cp -r xodel/src/lib/model.mjs src/lib
cp -r xodel/src/lib/validator.mjs src/lib
rm -rf xodel