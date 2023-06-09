<template>
  <page-layout>
    <!-- #ifdef H5 -->
    <modelform-uni
      :model="loginModel"
      action-url="/login_h5"
      label-position="left"
      label-align="left"
      :show-modal="true"
      @success-post="successPost"
    >
    </modelform-uni>
    <!-- #endif -->
    <!-- #ifdef MP-WEIXIN -->
    <div v-show="needCompleteProfile">
      <uni-notice-bar text="首次登陆，请完善头像和昵称" />
      <uni-forms
        ref="valiForm"
        :rules="rules"
        :model-value="profileData"
        label-position="left"
      >
        <uni-forms-item label="头像" name="avatar">
          <x-picker v-model="profileData.avatar" />
        </uni-forms-item>
        <uni-forms-item label="昵称" name="nickname">
          <uni-easyinput
            v-model="profileData.nickname"
            placeholder="请输入昵称"
            type="nickname"
          />
        </uni-forms-item>
      </uni-forms>
      <button type="primary" @click="submitLoginData('valiForm')">
        微信登录
      </button>
    </div>
    <!-- #endif -->
  </page-layout>
</template>

<script setup>
const { login } = useSession();
const store = useStore();
const redirectUrl = useRedirect();

const loginUser = async (user) => {
  login(user);
  await utils.gotoPage({ url: redirectUrl.value, redirect: true });
};
// #ifdef H5
store.message = "请先登录";
const successPost = async (user) => {
  await loginUser(user);
};
const loginModel = Model.createModel({
  fieldNames: ["username", "password"],
  fields: {
    username: { label: "用户名", hint: "昵称/手机号/身份证号" },
    password: { label: "密码", type: "password" }
  }
});
// #endif

// #ifdef MP-WEIXIN
const needCompleteProfile = ref(false);
const valiForm = ref();
const profileData = ref({
  id: "",
  username: "",
  xm: "",
  nickname: "",
  avatar: { url: "", errMsg: "" },
  permission: "",
  openid: ""
});

const userData = computed(() => ({
  ...profileData.value,
  avatar: profileData.value.avatar.url
}));
async function getWxUser() {
  const { code, errMsg } = await uni.login();
  if (errMsg !== "login:ok") {
    throw new Error(errMsg);
  }
  const { data: user } = await Http.post("/wx_login", {
    code
  });
  return user;
}
async function submitLoginData() {
  await valiForm.value.validate();
  await Http.post("/update_profile", {
    id: userData.value.id,
    nickname: userData.value.nickname,
    avatar: userData.value.avatar
  });
  await loginUser(userData.value);
}
const rules = {
  nickname: {
    rules: [
      {
        required: true,
        errorMessage: "姓名不能为空"
      }
    ]
  },
  avatar: {
    rules: [
      {
        validateFunction: function (rule, value, data, callback) {
          if (!value.url) {
            callback("必须上传头像");
          }
          return true;
        }
      }
    ]
  }
};
onReady(() => {
  valiForm.value.setRules(rules);
});
onLoad(async (options) => {
  console.log("login onLoad", options);
  const user = await getWxUser();
  profileData.value.id = user.id;
  profileData.value.openid = user.id;
  profileData.value.permission = user.permission;
  profileData.value.xm = user.xm;
  profileData.value.username = user.username;
  if (!user.nickname || !user.avatar) {
    needCompleteProfile.value = true;
  } else {
    profileData.value.nickname = user.nickname;
    profileData.value.avatar.url = user.avatar;
    await loginUser(userData.value);
  }
});

// #endif
</script>
