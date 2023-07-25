<template>
  <page-layout>
    <modelform-uni
      :model="GoddessAddModel"
      action-url="/goddess/create_from_user"
    ></modelform-uni>
  </page-layout>
</template>

<script setup>
const GoddessAddModel = Model.createModel({
  fieldNames: ["sex", "title", "pics"],
  fields: {
    sex: { label: "性别", required: true, choices: ["男", "女"], tag: "radio" },
    title: { label: "标题", required: true },
    pics: {
      label: "封面图",
      type: "aliossImageList",
      required: true,
      maxCount: 1,
      size: process.env.ALIOSS_AVATAR_SIZE || "2M"
    }
  }
});
</script>

<style scoped>
.GoddessAdd-main {
  padding: 15px;
}
</style>
