<template>
  <page-layout>
    <modelform-uni
      :model="loginModel"
      action-url="/login_h5"
      label-position="left"
      label-align="left"
      :show-modal="true"
      @success-post="successPost"
    >
    </modelform-uni>
  </page-layout>
</template>

<script setup>
const store = useStore();
const { loginWithRedirect } = useSession();

store.message = "请先登录";
const successPost = async (user) => {
  await loginWithRedirect(user);
};
const loginModel = Model.createModel({
  fieldNames: ["username", "password"],
  fields: {
    username: { label: "用户名", hint: "昵称/手机号/身份证号" },
    password: { label: "密码", type: "password" }
  }
});
</script>
