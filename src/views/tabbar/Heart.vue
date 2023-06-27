<template>
  <page-layout>
    <fui-tabs
      :tabs="tabs"
      center
      @change="changeActionType"
      :current="current"
    ></fui-tabs>
    <fui-panel
      v-if="ready && current === 0"
      @click="clickFriend"
      :panelData="friendsData"
      radius="16"
      :marginTop="24"
      width="60"
      height="60"
      :size="32"
    ></fui-panel>
    <div v-if="ready && current === 1">
      <uni-list-item title="自定义右侧插槽" note="列表描述信息">
        <template v-slot:footer>
          <button>同意</button>
        </template>
      </uni-list-item>
      <fui-list>
        <fui-list-cell>标题文字</fui-list-cell>
        <fui-list-cell>
          <text>标题文字</text>
          <text class="fui-text__explain">说明文字</text>
        </fui-list-cell>
        <fui-list-cell arrow>
          <text>标题文字</text>
        </fui-list-cell>
      </fui-list>
    </div>
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
const setRecordsByType = async (newType) => {
  const data = await usePost("/friends/tabbar", { type: newType });
  friendsData.value = {
    // head: "★",
    list: data.map((e) => {
      const other = e.apply.id !== user.id ? e.apply : e.approve;
      return {
        id: other.id,
        title: other.nickname,
        src: other.avatar
      };
    })
  };
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
</style>
