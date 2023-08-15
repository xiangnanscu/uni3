<template>
  <page-layout>
    <modelform-uni
      v-if="ready"
      :model="threadModel"
      :values="ThreadAddData"
      :sync-values="true"
      @success-post="successPost"
      action-url="/stage_apply/create"
    ></modelform-uni>
  </page-layout>
</template>

<script setup>
const ThreadAddData = ref({ title: "", content: "", pics: [] });
const successPost = async (data) => {
  await utils.gotoPage({ url: "/views/SuccessPage", redirect: true ,query:{title:'申请已提交',descr:'请等待审核'}});
};

const threadModel = ref(null);
const ready = ref(false);
onLoad(async (query) => {
  console.log(query)
  const data = await useGet(`/stage_apply/json`)
  data.fields.stage = {name:'stage', disabled:true, db_type:'varchar',label:'驿站名称',choices:[{label:query.stage_name, value:query.stage_id}]}
  threadModel.value = await Model.createModelAsync(data);
  ThreadAddData.value.stage = query.stage_id
  ready.value = true;
});
</script>
