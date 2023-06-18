<template>
  <page-layout>
    <modelform-uni
      :model="profileModel"
      :values="userData"
      :sync-values="true"
      @success-post="successPostWX"
      action-url="/update_profile"
    ></modelform-uni>
  </page-layout>
</template>

<script setup>
const { session } = useSession();
const loginUser = useLogin();
let wxAvatar = true;
// #ifdef H5
wxAvatar = false;
// #endif
const userData = ref({ id: session.user.id });
const profileModel = Model.createModel({
  fieldNames: ["avatar", "nickname", "intro"],
  fields: {
    avatar: {
      label: "头像",
      type: "aliossImage",
      wxAvatar,
      required: true,
      size: process.env.ALIOSS_AVATAR_SIZE || "2M"
    },
    nickname: { label: "昵称", required: true, inputType: "nickname" },
    intro: { label: "简介", inputType: "textarea" }
  }
});

const successPostWX = async (user) => {
  await loginUser(userData.value);
};
onMounted(async () => {
  const { data } = await Http.get("/usr/profile/my");
  userData.value.intro = data.intro;
  userData.value.avatar = data.avatar;
  userData.value.nickname = data.nickname;
});
</script>
