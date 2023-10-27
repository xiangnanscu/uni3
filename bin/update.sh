rm -rf uni3
gh repo clone ${app:-uni3} uni3 -- --depth=1
cp -r uni3/bin .
cp -r uni3/src/components src
cp -r uni3/src/composables src
cp -r uni3/src/globals src
cp -r uni3/src/lib src
cp -r uni3/src/uniSetup.js src
cp -r uni3/src/main.js src
cp -r uni3/patches .
cp -r uni3/.eslintrc.cjs .
cp -r uni3/package.json .
rm -rf uni3