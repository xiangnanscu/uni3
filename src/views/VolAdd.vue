<template>
  <page-layout>
    <modelform-uni
      :model="volplanModel"
      :values="formData"
      label-width="8em"
      @success-post="successPost"
      action-url="/volplan/create"
    ></modelform-uni>
  </page-layout>
</template>

<script setup>
const volplanModel = Model.createModel({
  fieldNames: [
    "title",
    "xm",
    "lxdh",
    "call_endtime",
    "plan_starttime",
    "plan_endtime",
    "pics",
    "amount",
    "content"
  ],
  fields: {
    title: { label: "志愿主题", required: true },
    xm: { label: "召集人姓名", required: true },
    lxdh: { label: "联系电话", required: true, wxPhone: true },
    call_endtime: { label: "召集截止时间", type: "datetime", required: true },
    plan_starttime: { label: "志愿开始时间", type: "datetime", required: true },
    plan_endtime: { label: "志愿结束时间", type: "datetime", required: true },
    pics: {
      label: "封面图",
      type: "aliossImageList",
      required: false,
      maxCount: 1,
      size: process.env.ALIOSS_AVATAR_SIZE || "2M"
    },
    amount: { label: "召集人数", required: true, type: "integer" },
    content: { label: "正文", required: true, inputType: "textarea" }
  }
});
const formData = ref({ title: "", content: "", pics: [] });
const successPost = async (data) => {
  await utils.gotoPage("Home");
};
</script>
