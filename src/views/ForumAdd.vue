<template>
  <page-layout>
    <modelform-uni
      v-if="ready"
      :model="forumModel"
      :values="formData"
      label-width="6em"
      @success-post="successPost"
      action-url="/forum/create"
    ></modelform-uni>
  </page-layout>
</template>

<script setup>
const formData = ref({});
const ready = ref(false);
const forumModel = Model.create_model({
  field_names: ["xm", "sfzh", "lxdh", "name", "avatar"],
  fields: {
    xm: { label: "创建人", required: true },
    sfzh: { label: "身份证号", required: true, type: "sfzh" },
    lxdh: { label: "手机号", required: true, attrs: { wxPhone: true } },
    name: { label: "吧名", required: true },
    avatar: {
      label: "吧头像",
      type: "alioss_image",
      required: true,
      size: process.env.ALIOSS_AVATAR_SIZE || "2M"
    }
  }
});
onLoad(async (query) => {
  const user = useUser();
  if (!user.username) {
    await utils.gotoPage({
      url: "/views/RealNameCert",
      query: {
        redirect: "/views/ForumAdd",
        message: "创建贴吧先实名认证"
      },
      redirect: true
    });
  } else {
    console.log(user);
    formData.value.xm = user.xm;
    formData.value.lxdh = user.phone;
    formData.value.sfzh = user.username;
  }
  ready.value = true;
});

const successPost = async (data) => {
  await utils.gotoPage("Home");
  uni.showToast({ title: "成功创建, 等待审核" });
};
</script>
