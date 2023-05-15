<script setup>
const formState = reactive({
  username: "",
  password: "",
});
const formRef = ref();
const errMsg = ref("");
const router = useRouter();
const route = useRoute();
const { login } = useSession();

const submitLogin = async () => {
  errMsg.value = "";
  const res = await Http.post("/admin/login", formState);
  const { code, user, msg, name } = unref(res.data);
  // console.log({ code, user, msg, name });
  if (code == 200) {
    const redirect = route.query.redirect;
    const path = redirect ? decodeURIComponent(redirect) : "/Admin";
    login(user);
    return router.push(path);
  } else if (code == 422) {
    errMsg.value = msg;
  } else {
    console.log();
  }
};
const onFinishFailed = (errorInfo) => {
  console.log("Failed2:", errorInfo);
};
const labelCol = ref(4);
</script>

<template>
  <div style="width: 400px; margin: auto">
    <a-form
      ref="formRef"
      :model="formState"
      name="basic"
      :label-col="{ span: labelCol }"
      :wrapper-col="{ span: 24 - labelCol }"
      autocomplete="off"
      @finishFailed="onFinishFailed"
    >
      <a-alert
        v-if="errMsg"
        :message="errMsg"
        type="error"
        closable
      />
      <a-form-item
        label="用户名"
        name="username"
        :rules="[{ required: true, message: '请输入用户名' }]"
      >
        <a-input v-model:value="formState.username">
          <template #prefix>
            <UserOutlined style="color: rgba(0, 0, 0, 0.25)" />
          </template>
        </a-input>
      </a-form-item>

      <a-form-item
        label="密码"
        name="password"
        :rules="[{ required: true, message: '请输入密码' }]"
      >
        <a-input
          v-model:value="formState.password"
          type="password"
        >
          <template #prefix>
            <LockOutlined style="color: rgba(0, 0, 0, 0.25)" />
          </template>
        </a-input>
      </a-form-item>

      <a-form-item :wrapper-col="{ offset: labelCol, span: 24 - labelCol }">
        <a-button
          type="primary"
          @click="submitLogin"
          html-type="submit"
        >登录</a-button>
      </a-form-item>
    </a-form>
  </div>
</template>
