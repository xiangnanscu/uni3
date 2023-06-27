<template>
  <page-layout>
    <fui-tabs
      :tabs="tabs"
      center
      @change="changeActionType"
      :current="current"
    ></fui-tabs>
    <uni-list v-if="ready && current === 0">
      <uni-list-item
        v-for="e in friendsData"
        :key="e.id"
        :title="e.title"
        showArrow
        link="navigateTo"
        :to="`/views/MessageDetail?id=${e.id}`"
        thumb-size="lg"
        :thumb="e.avatar"
      >
      </uni-list-item>
    </uni-list>
    <uni-list v-if="ready && current === 1">
      <uni-list-item
        v-for="e in friendsData"
        :key="e.id"
        :title="e.title"
        note2="列表描述信息"
        thumb-size="lg"
        :thumb="e.avatar"
      >
        <template v-slot:footer>
          <template v-if="e.status == '待添加'">
            <template v-if="e.approvable">
              <x-tag theme="plain" @click="approve(e, '通过')">同意</x-tag>
              <x-tag theme="plain" @click="approve(e, '拒绝')">拒绝</x-tag>
            </template>
            <span v-else class="slot-box"> 等待对方操作 </span>
          </template>
          <span v-else> 已{{ e.status }} </span>
        </template>
      </uni-list-item>
    </uni-list>
  </page-layout>
</template>

<script setup>
const user = useUser();
const query = useQuery();
const current = ref(Number(query.value.current || 0));
const tabs = ["朋友", "待处理"];
const type = computed(() => tabs[current.value]);
const ready = ref(false);
const friendsData = ref([]);

const clickFriend = async (e) => {
  await utils.gotoPage(`/views/MessageDetail?id=${e.id}`);
};
const approve = async (e, status) => {
  await usePost(`/friends/approve/${e.id}`, { status });
  e.status = status;
};
const setRecordsByType = async (newType) => {
  const data = await usePost("/friends/tabbar", { type: newType });
  friendsData.value = data
    .map((e) => ({
      ...(e.apply.id !== user.id ? e.apply : e.approve),
      approvable: e.apply.id !== user.id,
      status: e.status
    }))
    .map((e) => ({ ...e, title: e.nickname }));
  console.log(friendsData, data);
};
const changeActionType = async ({ index, name }) => {
  // await setRecordsByType(name);
  current.value = index;
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
.slot-box {
  /* #ifndef APP-NVUE */
  display: flex;
  /* #endif */
  flex-direction: row;
  align-items: center;
  font-size: 90%;
  color: #7f7f7f;
}
</style>
