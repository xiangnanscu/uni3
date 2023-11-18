<template>
  <page-layout>
    <modelform-uni
      v-if="ready"
      :model="threadModel"
      :values="ThreadAddData"
      :sync-values="true"
      label-width="7em"
      @success-post="successPost"
      action-url="/stage_apply/create"
    ></modelform-uni>
  </page-layout>
</template>

<script setup>
const ThreadAddData = ref({ title: "", content: "", pics: [] });
const successPost = async (data) => {
  await utils.redirect("StageApplySuccess");
};

const threadModel = ref(null);
const ready = ref(false);
const query = useQuery();
onLoad(async () => {
  const data = await useGet(`/stage_apply/json`);
  data.fields.stage = {
    name: "stage",
    disabled: true,
    db_type: "varchar",
    label: "驿站名称",
    choices: [{ label: query.stage_name, value: query.stage_id }],
  };
  threadModel.value = await Model.create_model_async(data);
  ThreadAddData.value.stage = query.stage_id;
  ready.value = true;
});
</script>
