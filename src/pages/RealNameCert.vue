<template>
  <page-layout>
    <x-alert v-if="query.message" :title="query.message"> </x-alert>
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
    phone: { label: "手机号", required: true, wxPhone }
  }
});

const successPost = async (user) => {
  await loginUser(userData.value);
};
onMounted(async () => {
  const { data } = await Http.get("/usr/profile/my");
  userData.value.xm = data.xm || "";
  userData.value.phone = data.phone || "";
  userData.value.username = data.username || "";
});
</script>
