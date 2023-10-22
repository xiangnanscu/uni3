<template>
  <page-layout>
    <!-- #ifdef H5 -->
    <modelform-uni
      :model="loginModel"
      action-url="/login_h5"
      label-position="left"
      label-align="left"
      :show-modal="true"
      @success-post="successPostH5"
    >
    </modelform-uni>
    <!-- #endif -->
    <!-- #ifdef MP-WEIXIN -->
    <div v-if="needCompleteProfile">
      <uni-notice-bar text="首次登陆，请完善头像和昵称" style="text-align: center" />
      <modelform-uni
        :model="profileModel"
        :values="userData"
        :sync-values="true"
        @success-post="successPostWX"
        submit-button-text="微信登录"
        action-url="/update_profile?update_session=1"
      ></modelform-uni>
    </div>
    <!-- #endif -->
  </page-layout>
</template>

<script setup>
const store = useStore();
store.message = "请先登录";
const avatarSize = process.env.ALIOSS_AVATAR_SIZE || "2M";
const loginUser = useLogin();
// #ifdef H5
const successPostH5 = async (user) => {
  await loginUser(user);
};

const loginModel = Model.create_model({
  field_names: ["username", "password"],
  fields: {
    username: { label: "用户名", hint: "昵称/手机号/身份证号" },
    password: { label: "密码", type: "password" },
  },
});
// #endif

// #ifdef MP-WEIXIN
const successPostWX = async (user) => {
  console.log("fullPath:", utils.getFullPath());
  console.log("redirect:", useRedirect().value);
  await loginUser({ ...userData.value, ...user }, useRedirect().value);
};

const profileModel = Model.create_model({
  field_names: ["avatar", "nickname"],
  fields: {
    avatar: {
      label: "头像",
      type: "alioss_image",
      required: true,
      size: avatarSize,
      attrs: { wx_avatar: true },
    },
    nickname: { label: "昵称", required: true, input_type: "nickname" },
  },
});
const needCompleteProfile = ref(false);
const userData = ref({
  id: "",
  username: "",
  xm: "",
  nickname: "",
  avatar: "",
  permission: "",
  phone: "",
  openid: "",
});

async function getWxUser() {
  const { code, errMsg } = await uni.login();
  if (errMsg !== "login:ok") {
    throw new Error(errMsg);
  }
  const user = await usePost("/wx_login", {
    code,
  });
  return user;
}

onLoad(async (options) => {
  const user = await getWxUser();
  userData.value.id = user.id;
  userData.value.openid = user.openid;
  userData.value.permission = user.permission;
  userData.value.xm = user.xm;
  userData.value.username = user.username;
  userData.value.phone = user.phone;
  if (!user.nickname || !user.avatar) {
    needCompleteProfile.value = true;
  } else {
    userData.value.nickname = user.nickname;
    userData.value.avatar = user.avatar;
    await loginUser(userData.value);
  }
});

// #endif
</script>
