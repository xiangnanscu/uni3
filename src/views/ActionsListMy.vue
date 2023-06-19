<template>
  <page-layout>
    <fui-tabs
      :tabs="tabs"
      center
      @change="change"
      :current="current"
    ></fui-tabs>
    <fui-list v-if="ready">
      <fui-list-cell v-for="e in records" :key="e.id" arrow>
        <view class="fui-list__item">
          <text>{{ e.title }}</text>
          <text class="fui-text__explain">{{ fromNow(e.ctime) }}</text>
        </view>
      </fui-list-cell>
    </fui-list>
  </page-layout>
</template>

<script setup>
const query = useQuery();
const current = computed(() => Number(query.value.current || 0));
const tabs = ["浏览", "收藏", "点赞"];
const type = computed(() => tabs[current.value]);
const ready = ref(false);
const records = ref([]);
onLoad(async () => {
  const { data } = await Http.post("/actions/my", { type: type.value });
  records.value = data;
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
