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
        :to="`/views/ShykDetail?id=${e.id}`"
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
const tabs = ["待参加", "进行中", "已结束"];
const type = computed(() => tabs[current.value]);
const ready = ref(false);
const records = ref([]);

const setRecordsByType = async (newType) => {
  const cond = {
    where: {},
    select: ["id", "ctime", "title", "start_time", "end_time"],
  };
  const now = utils.getLocalTime();
  if (newType == "待参加") {
    cond.where.start_time__gt = now;
  } else if (newType == "进行中") {
    cond.where.start_time__lt = now;
    cond.where.end_time__gt = now;
  } else {
    cond.where.end_time__lt = now;
  }
  const data = await usePost("/shyk/query_my", cond);
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
