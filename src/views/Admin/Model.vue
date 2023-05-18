<route lang="yaml"></route>
<template>
  <model-panel
    v-if="adminModel"
    :model="adminModel"
  />
</template>
<script setup >
import { computed, onMounted } from "vue";
import { useRoute } from "vue-router";
import { Http } from "@/globals/Http";


import { Model } from "@/lib/model.mjs";

const route = useRoute();
const adminModel = shallowRef(null);
const modelName = computed(() => route.query.modelName);

const setModel = async (modelName) => {
  const { data } = await Http.get(`/admin/model/${modelName}`);
  const model = await Model.createModelAsync(data);
  adminModel.value = model;
};
onMounted(async () => {
  await setModel(modelName.value);
});
watch(
  modelName,
  async (model) => {
    if (!model) {
      //直接跳到其他页面时, watch仍会执行且modelName是undefined
      return;
    }
    adminModel.value = null;
    await setModel(model);
  },
  { immediate: false }
);


</script>
