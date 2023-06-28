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
      <template v-for="e in friendsData" :key="e.id">
        <uni-list-item
          v-if="e.approvable && e.status == '待添加'"
          :title="e.title"
          :note="e.hello_message"
          thumb-size="lg"
          :thumb="e.avatar"
        >
          <template v-slot:footer>
            <div class="slot-box">
              <x-tagbutton
                text="同意"
                type="success"
                @click="approve(e, '通过')"
              ></x-tagbutton>
              <x-tagbutton
                style="margin-left: 1em"
                text="拒绝"
                type="warning"
                @click="approve(e, '拒绝')"
              ></x-tagbutton>
            </div>
          </template>
        </uni-list-item>
        <uni-list-item
          v-else
          :title="e.title"
          :note="e.hello_message"
          :right-text="e.approvable ? `已${e.status}` : `待对方处理`"
          thumb-size="lg"
          :thumb="e.avatar"
        >
        </uni-list-item>
      </template>
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
      hello_message: e.hello_message,
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
.slot-text {
  flex: 1;
  font-size: 14px;
  color: #4cd964;
  margin-right: 10px;
}
</style>
