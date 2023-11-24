<template>
  <page-layout>
    <f-alert v-if="query.message"> {{ query.message }} </f-alert>
    <uni-card title="温馨提示">
      <p>此处填写小程序用户的实名信息，请确保正确，提交之后将不可修改。</p>
      <p>如果实名认证信息有误，请联系小程序管理员核实修改。</p>
    </uni-card>
    <modelform-fui
      :model="profileModel"
      :values="userData"
      :sync-values="true"
      :success-url="redirectUrl"
      :success-use-redirect="true"
      @success-post="successPost"
      action-url="/update_profile?update_session=1"
    ></modelform-fui>
  </page-layout>
</template>
<script setup>
const query = useQuery();
const redirectUrl = useRedirect();
const { session, login } = useSession();
let wx_phone = true;
// #ifdef H5
wx_phone = false;
// #endif
const userData = ref({ id: session.user.id, xm: "", username: "", phone: "" });
const profileModel = Model.create_model({
  field_names: ["xm", "username", "phone"],
  fields: {
    xm: { label: "姓名", required: true },
    username: { label: "身份证号", type: "sfzh", required: true },
    phone: {
      label: "手机号",
      required: true,
      attrs: { wx_phone },
      disabled: true,
    },
  },
});

const successPost = (user) => {
  const newUser = { ...userData.value, ...user };
  login(newUser);
};
onLoad(async () => {
  console.log("RealNameCert onLoad query:", JSON.stringify(query));
  await helpers.autoLogin();
  const { data } = await Http.get("/usr/profile/my");
  userData.value.xm = data.xm || "";
  userData.value.phone = data.phone || "";
  userData.value.username = data.username || "";
  if (data.xm) {
    profileModel.fields.xm.disabled = true;
  }
  if (data.username) {
    profileModel.fields.username.disabled = true;
  }
});
</script>
