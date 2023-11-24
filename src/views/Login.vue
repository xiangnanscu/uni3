<template>
  <page-layout>
    <f-alert v-if="query.message"> {{ query.message }} </f-alert>
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
const query = useQuery();
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

onLoad(async (options) => {
  const user = await helpers.getWxUser();
  userData.value.id = user.id;
  userData.value.openid = user.openid;
  userData.value.permission = user.permission;
  userData.value.xm = user.xm;
  userData.value.username = user.username;
  userData.value.phone = user.phone;
  if (process.env.NEED_COMPLETE_PROFILE == "true" && (!user.nickname || !user.avatar)) {
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
