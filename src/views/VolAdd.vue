<template>
  <page-layout>
    <modelform-uni
      :model="volplanModel"
      :values="formData"
      label-width="6em"
      @success-post="successPost"
      action-url="/vol/create"
    ></modelform-uni>
  </page-layout>
</template>

<script setup>
const volplanModel = Model.createModel({
  fieldNames: ["title", "content", "pics", "amount"],
  fields: {
    pics: {
      label: "图片",
      type: "aliossImageList",
      required: false,
      size: process.env.ALIOSS_AVATAR_SIZE || "2M"
    },
    title: { label: "志愿主题", required: true },
    content: { label: "内容", required: true, inputType: "textarea" },
    amount: { label: "召集人数", required: true, type: "integer" }
  }
});
const formData = ref({ title: "", content: "", pics: [], amount: 1 });
const successPost = async (data) => {
  await utils.gotoPage("Home");
};
</script>
