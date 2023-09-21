<template>
  <page-layout>
    <x-alert title="红云智慧校园"> </x-alert>
    <uni-card title="温馨提示">
      <p>此处填写教师基本信息，请确保正确，提交之后将不可修改。</p>
      <p>如果实名认证信息有误，需要联系团县委管理员核实修改。</p>
    </uni-card>
    <modelform-uni
      v-if="loaded"
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
const userData = ref({ id: session.user.id, xm: "", username: "", avatar: "" });
const loaded = ref(false);
let profileModel;
onLoad(async () => {
  const modelJson = await useGet(`/teacher/json`);
  profileModel = Model.createModel(modelJson);
  const data = await usePost(`/teacher/detail`);
});

const successPost = async (user) => {
  const newUser = { ...userData.value, ...user };
  await loginUser(newUser);
};
</script>
