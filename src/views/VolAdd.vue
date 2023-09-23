<template>
  <page-layout>
    <modelform-uni
      :model="volplanModel"
      :values="formData"
      :sync-values="true"
      label-width="8em"
      @success-post="successPost"
      action-url="/volplan/create"
    ></modelform-uni>
  </page-layout>
</template>

<script setup>
const formData = ref({ title: "", content: "", pics: [] });

const volplanModel = Model.create_model({
  field_names: [
    "title",
    "xm",
    "sfzh",
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
    xm: { label: "召集人姓名", required: true, disabled: false },
    sfzh: {
      label: "召集人身份证",
      type: "sfzh",
      required: true,
      disabled: false
    },
    lxdh: {
      label: "联系电话",
      required: true,
      disabled: false,
      attrs: { wxPhone: true }
    },
    call_endtime: { label: "召集截止时间", type: "datetime", required: true },
    plan_starttime: { label: "志愿开始时间", type: "datetime", required: true },
    plan_endtime: { label: "志愿结束时间", type: "datetime", required: true },
    pics: {
      label: "封面图",
      type: "alioss_image_list",
      required: false,
      size: process.env.ALIOSS_AVATAR_SIZE || "2M",
      limit: 1
    },
    amount: { label: "召集人数", required: true, type: "integer" },
    content: { label: "正文", required: true, input_type: "textarea" }
  }
});

onLoad(async (query) => {
  const user = useUser();
  if (!user.username) {
    await utils.gotoPage({
      url: "/views/RealNameCert",
      query: {
        redirect: "/views/VolAdd",
        message: "发起志愿请先实名认证"
      },
      redirect: true
    });
  } else {
    console.log(user);
    formData.value.xm = user.xm;
    formData.value.lxdh = user.phone;
    formData.value.sfzh = user.username;
  }
});

const successPost = async (data) => {
  await utils.gotoPage("Home");
};
</script>
