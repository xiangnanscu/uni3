<template>
  <page-layout>
    <x-text text="头像、昵称用于评论" :size="0.8"></x-text>
    <modelform-fui
      v-if="ready"
      :model="profileModel"
      :values="userData"
      :success-url="redirectUrl"
      action-url="/update_profile"
      @success-post="login"
    ></modelform-fui>
  </page-layout>
</template>

<script setup>
const { session, login } = useAuth();
const redirectUrl = useRedirect();
let wx_avatar = true;
// #ifdef H5
wx_avatar = false;
// #endif
const userData = ref({ id: session.user.id });
const profileModel = Model.create_model({
  field_names: ["avatar", "nickname", "intro"],
  fields: {
    avatar: {
      label: "头像",
      type: "alioss_image",
      required: true,
      size: process.env.ALIOSS_AVATAR_SIZE || "2M",
      attrs: { wx_avatar },
    },
    nickname: { label: "昵称", required: true, input_type: "nickname" },
    intro: { label: "简介", input_type: "textarea" },
  },
});
const ready = ref(false);
onMounted(async () => {
  const { data } = await Http.get("/usr/profile/my");
  userData.value.intro = data.intro;
  userData.value.avatar = data.avatar;
  userData.value.nickname = data.nickname;
  ready.value = true;
});
</script>
