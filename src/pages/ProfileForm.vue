<template>
  <page-layout>
    <!-- {{ JSON.stringify(profileData) }} -->
    <uni-forms
      ref="valiForm"
      :rules="rules"
      :model-value="profileData"
      label-position="left"
    >
      <uni-forms-item label="头像" name="avatar">
        <w-picker
          v-model="profileData.avatar"
          :value="profileData.avatar"
          @update:value="profileData.avatar = $event"
        />
      </uni-forms-item>
      <uni-forms-item label="昵称" name="nickname">
        <uni-easyinput
          v-model="profileData.nickname"
          placeholder="请输入昵称"
          type="nickname"
        />
      </uni-forms-item>
      <uni-forms-item label="简介" name="intro">
        <uni-easyinput
          v-model="profileData.intro"
          placeholder="请输入简介"
          type="intro"
        />
      </uni-forms-item>
      <button type="primary" @click="submit('valiForm')">提交</button>
    </uni-forms>
  </page-layout>
</template>

<script>
import login from "~/login.js";
// import wxPicker from "../../components/w-picker/w-picker.vue";

export default {
  mixins: [login],
  data() {
    return {
      profileData: {
        intro: "",
        nickname: "",
        avatar: {
          url: "",
          errMsg: "",
        },
      },
    };
  },

  async mounted() {
    const { data } = await this.$http.get("/usr/profile/my");
    this.profileData.intro = data.intro;
    this.profileData.avatar.url = data.avatar;
    this.profileData.nickname = data.nickname;
  },

  methods: {
    async submit(ref) {
      await this.$refs[ref].validate();
      const id = this.user.id;
      if (id) {
        const user = {
          id,
          intro: this.profileData.intro,
          nickname: this.profileData.nickname,
          avatar: this.profileData.avatar.url,
        };
        await this.$http.post("/update_profile", user);
        this.$store.commit("login", {
          ...this.user,
          ...user,
        });
        await this.gotoPage({
          url: this.redirect || "/pages/tabbar/ProfileMy/ProfileMy",
        });
      }
    },
  },
};
</script>

<style>
.content {
  padding: 15px;
}
</style>
