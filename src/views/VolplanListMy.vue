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
        :to="`/views/VolplanDetail?id=${e.id}`"
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
const tabs = ["我参加的", "我发起的"];
const type = computed(() => tabs[current.value]);
const ready = ref(false);
const records = ref([]);
const user = useUser();
const setRecordsByType = async (newType) => {
  if (newType == "我发起的") {
    records.value = await usePost("/volplan/records", {
      usr_id: user.id
    });
  } else {
    const data = await usePost("/volreg/records", {
      usr_id: user.id
    });
    records.value = data.map((e) => ({
      id: e.volplan_id,
      title: e.volplan_id__title
    }));
  }
};
const changeActionType = async ({ index, name }) => {
  console.log({ index, name });
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
