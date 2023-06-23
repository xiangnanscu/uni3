<template>
  <page-layout>
    <modelform-uni
      :model="forumModel"
      :values="formData"
      label-width="6em"
      @success-post="successPost"
      action-url="/forum/create"
    ></modelform-uni>
  </page-layout>
</template>

<script setup>
const forumModel = Model.createModel({
  fieldNames: ["xm", "sfzh", "lxdh", "name", "avatar"],
  fields: {
    xm: { label: "创建人", required: true },
    sfzh: { label: "身份证号", required: true, type: "sfzh" },
    lxdh: { label: "手机号", required: true, wxPhone: true },
    name: { label: "吧名", required: true },
    avatar: {
      label: "吧头像",
      type: "aliossImage",
      required: true,
      size: process.env.ALIOSS_AVATAR_SIZE || "2M"
    }
  }
});
const formData = ref({});
const successPost = async (data) => {
  console.log("add forum ok:", data);
  await utils.gotoPage("Home");
  uni.showToast({ title: "成功创建, 等待审核" });
};
</script>
