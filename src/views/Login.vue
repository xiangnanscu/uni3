<template>
  <page-layout>
    <!-- #ifdef H5 -->
    <modelform-uni
      :model="loginModel"
      action-url="/login_h5"
      label-position="left"
      label-align="left"
      :show-modal="true"
      :success-url="redirectUrl"
      :success-use-redirect="true"
      @success-post="login"
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
        :success-url="redirectUrl"
        :success-use-redirect="true"
        @success-post="successPostWX"
        submit-button-text="微信登录"
        action-url="/update_profile?update_session=1"
      ></modelform-uni>
    </div>
    <!-- #endif -->
  </page-layout>
</template>

<script setup>
const avatarSize = process.env.ALIOSS_AVATAR_SIZE || "500K";
const store = useStore();
store.message = "请先登录";
const sessionUser = useUser();
const redirectUrl = useRedirect();
const { login } = useSession();
// #ifdef H5
const loginModel = Model.create_model({
  field_names: ["username", "password"],
  fields: {
    username: { label: "用户名", hint: "昵称/手机号/身份证号" },
    password: { label: "密码", type: "password" },
  },
});
// #endif

// #ifdef MP-WEIXIN
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
const successPostWX = (user) => {
  login({ ...userData.value, ...user });
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
  if (sessionUser.id) {
    //有时候不知何故已经登录了也会重定向到此页面,则不用再调用了
    console.log(
      "Login.vue onLoad检测已经登录直接重定向,options:",
      JSON.stringify(options),
    );
    return await utils.redirect(redirectUrl.value);
  }
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
    login(userData.value);
    await utils.redirect(redirectUrl.value);
  }
});

// #endif
</script>
