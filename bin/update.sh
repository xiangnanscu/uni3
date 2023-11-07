rm -rf uni3
gh repo clone ${app:-uni3} uni3 -- --depth=1
cp -r uni3/bin .
cp -r uni3/src/components src
cp -r uni3/src/composables src
cp -r uni3/src/globals src
cp -r uni3/src/lib src
cp -r uni3/src/main.js src
cp -r uni3/src/views/Login.vue src/views
cp -r uni3/src/views/MixinShare.js src/views
cp -r uni3/src/views/Profile.vue src/views
cp -r uni3/src/views/ProfileForm.vue src/views
cp -r uni3/src/views/RealNameCert.vue src/views
cp -r uni3/src/views/SubscribeList.vue src/views
cp -r uni3/src/views/SuccessPage.vue src/views
cp -r uni3/patches .
cp -r uni3/.eslintrc.cjs .
rm -rf uni3