<template>
  <modelform-uni
    :model="loginModel"
    action-url="/login_h5"
    label-position="left"
    label-align="left"
    :show-modal="true"
    @success-post="successPost"
    :success-url="redirect"
  >
  </modelform-uni>
</template>

<script setup>
const { redirect } = useRedirect({ decode: true });
const store = useStore();
store.message = "请先登录";
const successPost = (user) => {
  const { login } = useSession();
  login(user);
};
const loginModel = Model.createModel({
  fieldNames: ["username", "password"],
  fields: {
    username: { label: "用户名", hint: "昵称/手机号/身份证号" },
    password: { label: "密码", type: "password" }
  }
});
</script>
