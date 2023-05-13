rm -rf xodel
gh repo clone ${app:-xodel} xodel -- --depth=1
cp -r xodel/.github .
cp -r xodel/.vscode .
cp -r xodel/conf .
cp -r xodel/lualib/xodel lualib
cp -r xodel/controllers/admin.lua controllers
cp -r xodel/controllers/alioss_payload.lua controllers
cp -r xodel/controllers/logs.lua controllers
cp -r xodel/controllers/oauth.lua controllers
cp -r xodel/controllers/wx*.lua controllers
cp -r xodel/src/components src
cp -r xodel/src/composables src
cp -r xodel/src/globals src
cp -r xodel/src/views/Admin/List src/views/Admin
cp -r xodel/src/views/Admin/List.vue src/views/Admin
cp -r xodel/src/views/Admin/UserLogin.vue src/views/Admin
cp -r xodel/src/views/Admin/UserLogout.vue src/views/Admin
cp -r xodel/src/store/session.ts src/store
cp -r xodel/src/store/store.ts src/store
cp -r xodel/src/field.mjs src
cp -r xodel/src/model.mjs src
cp -r xodel/src/validator.mjs src
cp -r xodel/src/style.scss src
cp -r xodel/spec .
cp -r xodel/README.md .
cp -r xodel/init.lua .
cp -r xodel/install.sh .
# cp -r xodel/tsconfig.json .
cp -r xodel/tsconfig.node.json .
cp -r xodel/src/vite-env.d.ts src
# cp -r xodel/vite.config.ts .
cp -r xodel/.eslintrc.js .
cp -r xodel/bin .
cp -r xodel/.gitignore .
rm -rf xodel