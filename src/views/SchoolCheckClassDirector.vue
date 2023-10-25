<template>
  <page-layout>
    <fui-tabs
      :tabs="tabs"
      center
      @change="changeActionType"
      :current="current"
    ></fui-tabs>
    <uni-list v-if="ready">
      <div v-for="(e, i) in records" :key="e.id">
        <div class="x-row">
          <div style="margin-left: 1em; padding: 5px">
            {{ e.usr_id__xm }}（{{ e.usr_id__username }}）
          </div>
          <div class="x-row">
            <x-button
              styleString="padding: 0px 5px; font-size: 80%;margin-right:1em"
              size="mini"
              @click="onCheck(i, '通过')"
            >
              通过
            </x-button>
            <x-button
              styleString="padding: 0px 5px; font-size: 80%; color: red; border-color:red"
              size="mini"
              @click="onCheck(i, '拒绝')"
            >
              拒绝
            </x-button>
          </div>
        </div>
      </div>
    </uni-list>
  </page-layout>
</template>

<script setup>
const query = useQuery();
const current = computed(() => Number(query.current || 0));
const tabs = ["待审核", "通过", "拒绝"];
const status = computed(() => tabs[current.value]);
const ready = ref(false);
const records = ref([]);

const setRecordsByType = async (newType) => {
  const { data } = await Http.post("/class_director/records", { status: newType });
  records.value = data;
};
const changeActionType = async ({ index, name }) => {
  await setRecordsByType(name);
};
const onCheck = async (index, status) => {
  await Http.post(`/class_director/update/${records.value[index].id}`, {
    status,
  });
  records.value.splice(index, 1);
  uni.showToast({ title: "操作成功" });
};
watch(status, setRecordsByType);
onLoad(async () => {
  await setRecordsByType(status.value);
  ready.value = true;
});
</script>

<style scoped>
.x-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
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
