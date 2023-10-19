<template>
  <page-layout>
    <fui-tabs
      :tabs="tabs"
      center
      @change="changeActionType"
      :current="current"
    ></fui-tabs>
    <uni-list v-if="ready">
      <uni-notice-bar
        v-if="!records.length"
        single
        text="没有任何记录"
        style="margin-top: 5px"
      />
      <uni-list-item
        v-for="e in records"
        :key="e.id"
        :title="e.title"
        :to="`/views/SchoolNoticeDetail?id=${e.id}`"
        :rightText="utils.fromNow(e.ctime)"
        link="navigateTo"
      >
      </uni-list-item>
    </uni-list>
  </page-layout>
</template>

<script setup>
const query = useQuery();
const user = useUser();
const current = computed(() => Number(query.current || 0));
const tabs = ["待查看", "已查看"];
const type = computed(() => tabs[current.value]);
const ready = ref(false);
const records = ref([]);

const setRecordsByType = async (newType) => {
  const cond = {
    where: {},
    select: ["id", "ctime", "title"],
  };
  const data = await usePost("/school_notice/query", cond);
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
