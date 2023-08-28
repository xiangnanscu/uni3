<template>
  <page-layout>
    <fui-tabs
      :tabs="tabs"
      center
      @change="changeActionType"
      :current="current"
    ></fui-tabs>
    <uni-list v-if="ready">
      <uni-list-item
        v-for="e in records"
        :key="e.id"
        :title="e.title"
        :to="`/views/${utils.toModelName(e.target_model)}Detail?id=${
          e.target_id
        }`"
        :rightText="utils.fromNow(e.ctime)"
        link="navigateTo"
      >
      </uni-list-item>
    </uni-list>
  </page-layout>
</template>

<script setup>
const query = useQuery();
const current = computed(() => Number(query.current || 0));
const tabs = ["浏览", "收藏", "点赞"];
const type = computed(() => tabs[current.value]);
const ready = ref(false);
const records = ref([]);

const setRecordsByType = async (newType) => {
  const { data } = await Http.post("/actions/my", { type: newType });
  records.value = data;
};
const changeActionType = async ({ index, name }) => {
  await setRecordsByType(name);
};
watch(type, setRecordsByType);

onLoad(async () => {
  await setRecordsByType(type.value);
  ready.value = true;
});
</script>

<style scoped>
.fui-list__item {
  flex: 1;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.fui-text__explain {
  font-size: 28rpx;
  color: #7f7f7f;
  flex-shrink: 0;
}
</style>
