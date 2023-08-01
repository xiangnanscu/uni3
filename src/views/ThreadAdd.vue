<template>
  <page-layout>
    <modelform-uni
      v-if="ready"
      :model="threadModel"
      :values="ThreadAddData"
      :sync-values="true"
      @success-post="successPost"
      action-url="/thread/create"
    ></modelform-uni>
  </page-layout>
</template>

<script setup>
const ThreadAddData = ref({ title: "", content: "", pics: [] });
const successPost = async (data) => {
  await utils.gotoPage({ url: "/views/ThreadListAll", redirect: true });
};

const threadModel = ref(null);
const ready = ref(false);
onLoad(async () => {
  threadModel.value = await Model.createModelAsync({
    field_names: ["type", "title", "content", "pics"],
    fields: {
      type: { label: "贴吧", required: true, choicesUrl: "/forum/types" },
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
  ready.value = true;
});
</script>
