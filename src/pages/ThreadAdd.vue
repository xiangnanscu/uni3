<template>
  <page-layout>
    <modelform-uni
      :model="threadModel"
      :values="ThreadAddData"
      :sync-values="true"
      @success-post="successPost"
      action-url="/thread/create"
    ></modelform-uni>
  </page-layout>
</template>

<script setup>
const threadModel = Model.createModel({
  fieldNames: ["title", "content", "pics"],
  fields: {
    pics: {
      label: "图片",
      type: "aliossImageList",
      required: false,
      size: process.env.ALIOSS_AVATAR_SIZE || "2M"
    },
    title: { label: "标题", required: true },
    content: { label: "内容", required: true, inputType: "textarea" }
  }
});
const ThreadAddData = ref({ title: "", content: "", pics: [] });
const successPost = async (data) => {
  console.log(data);
  await utils.gotoPage({ url: "/pages/ThreadListAll" });
};
</script>
