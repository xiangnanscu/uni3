<template>
  <page-layout>
    <x-alert v-if="query.message" :title="query.message"> </x-alert>
    <uni-card title="温馨提示">
      <p>
        此处填写需要缴纳团费的团员姓名和身份证号，请确保正确，提交之后将不可修改。
      </p>
      <p>如果实名认证信息有误，需要联系团县委管理员核实修改。</p>
    </uni-card>
    <modelform-uni
      :model="profileModel"
      :values="userData"
      :sync-values="true"
      label-width="6em"
      @success-post="successPost"
      action-url="/update_profile?update_session=1"
    ></modelform-uni>
  </page-layout>
</template>
<script setup>
const { session } = useSession();
const loginUser = useLogin();
const query = useQuery();
let wxPhone = true;
// #ifdef H5
wxPhone = false;
// #endif
const userData = ref({ id: session.user.id, xm: "", username: "", phone: "" });
const profileModel = Model.createModel({
  fieldNames: ["xm", "username", "phone"],
  fields: {
    xm: { label: "姓名", required: true },
    username: { label: "身份证号", type: "sfzh", required: true },
    phone: { label: "手机号", required: true, wxPhone, disabled: false }
  }
});

const successPost = async (user) => {
  const newUser = { ...userData.value, ...user };
  console.log({ newUser });
  await loginUser(newUser);
};
onLoad(async () => {
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
