<template>
  <page-layout>
    <modelform-uni
      v-if="ready"
      label-width="6em"
      :values="values"
      :model="GoddessAddModel"
      action-url="/goddess/create_from_user"
      @success-post="successPost"
    ></modelform-uni>
  </page-layout>
</template>

<script setup>
// onShareTimeline
// onShareAppMessage
useWxShare({ title: "江安“新青年”邀请你！", imageUrl: "" });
const GoddessAddModel = Model.create_model({
  field_names: ["xm", "sex", "sfzh", "title", "pics"],
  fields: {
    xm: { label: "姓名", required: true, minlength: 2 },
    sfzh: { label: "身份证号", required: true, type: "sfzh" },
    sex: { label: "性别", required: true, choices: ["男", "女"], tag: "radio" },
    title: { label: "标题", required: true, minlength: 5 },
    pics: {
      label: "封面图",
      type: "alioss_image_list",
      required: true,
      size: process.env.ALIOSS_AVATAR_SIZE || "2M",
      limit: 1,
    },
  },
});
const values = ref({});
const user = useUser();
const ready = ref();
const successPost = async (data) => {
  await utils.gotoPage({
    name: "SuccessPage",
    query: { type: "success", title: "操作成功", descr: "请等待后台审核通过" },
  });
};
onLoad(async () => {
  console.log("GODDESS-ADD:user", user);
  values.value.xm = user.xm;
  values.value.sfzh = user.username;
  values.value.sex = user.username[16] % 2 === 0 ? "女" : "男";
  ready.value = true;
});
</script>

<style scoped>
.GoddessAdd-main {
  padding: 15px;
}
</style>
