<template>
  <div v-if="needCompleteProfile === null">请稍候...</div>
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
</template>

<script>
import login from "@/lib/login.js";

export default {
  mixins: [login],
  data() {
    return {
      needCompleteProfile: null,
      profileData: {
        id: "",
        nickname: "",
        avatar: { url: "", errMsg: "" },
        permission: "",
        openid: ""
      }
    };
  },
  async onShow() {
    console.log("loginWx onShow");
    const user = await this.getWxUser();
    uni.hideLoading();
    this.profileData.id = user.id;
    this.profileData.openid = user.id;
    this.profileData.permission = user.permission;
    if (!user.nickname || !user.avatar) {
      this.needCompleteProfile = true;
    } else {
      this.profileData.nickname = user.nickname;
      this.profileData.avatar.url = user.avatar;
      await this.wxLogin();
    }
  },
  computed: {
    userData() {
      const user = {
        ...this.profileData,
        avatar: this.profileData.avatar.url
      };
      return user;
    }
  },
  methods: {
    async getWxUser() {
      const { code, errMsg } = await uni.login();
      if (errMsg !== "login:ok") {
        throw new Error(errMsg);
      }
      const { data: user } = await Http.post("/wx_login", {
        code
      });
      return user;
    },
    async wxLogin() {
      const { login } = useSession();
      login(this.userData);
      const safeRedirect =
        !this.redirect || this.redirect.includes(process.env.UNI_LOGIN_PAGE)
          ? process.env.UNI_HOME_PAGE
          : this.redirect;
      // console.log({safeRedirect})
      await utils.gotoPage({
        url: safeRedirect || process.env.UNI_HOME_PAGE,
        redirect: true
      });
    },
    async submitLoginData(ref) {
      await this.$refs[ref].validate();
      await Http.post("/update_profile", {
        id: this.userData.id,
        nickname: this.userData.nickname,
        avatar: this.userData.avatar
      });
      await this.wxLogin();
    }
  }
};
</script>

<style>
.content {
  padding: 15px;
  text-align: center;
  height: 400upx;
  margin-top: 15upx;
}
</style>
