<template>
  <page-layout>
    <fui-tabs
      :tabs="tabs"
      center
      @change="changeActionType"
      :current="current"
    ></fui-tabs>
    <fui-panel
      v-if="ready"
      :panelData="friendsData"
      radius="16"
      :marginTop="24"
      width="60"
      height="60"
      :size="32"
    ></fui-panel>
  </page-layout>
</template>

<script setup>
const user = useUser();
const query = useQuery();
const current = computed(() => Number(query.value.current || 0));
const tabs = ["朋友", "待处理"];
const type = computed(() => tabs[current.value]);
const ready = ref(false);
const friendsData = ref([]);

const setRecordsByType = async (newType) => {
  const { data } = await Http.post("/friends/tabbar", { type: newType });
  friendsData.value = {
    // head: "★",
    list: data.map((e) => {
      const other = e.apply.id !== user.id ? e.apply : e.approve;
      return {
        title: other.nickname,
        src: other.avatar
      };
    })
  };
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
