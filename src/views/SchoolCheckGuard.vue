<template>
  <page-layout>
    <fui-tabs
      :tabs="tabs"
      center
      @change="changeActionType"
      :current="current"
    ></fui-tabs>
    <div v-if="ready" style="margin-top: 1em">
      <div v-if="records.length">
        <div v-for="(e, i) in records" :key="e.id" class="x-row">
          <div style="margin-left: 1em; padding: 5px">
            {{ e.usr_id__xm }}（{{ e.usr_id__username }}）
          </div>
          <div class="x-row">
            <button
              v-if="status == '待审核' || status == '拒绝'"
              style="
                padding: 0px 5px;
                font-size: 80%;
                margin-right: 1em;
                color: green;
                border-color: green;
              "
              size="mini"
              :plain="true"
              @click="onCheck(i, '通过')"
            >
              通过
            </button>
            <button
              v-if="status == '待审核' || status == '通过'"
              style="padding: 0px 5px; font-size: 80%; color: red; border-color: red"
              size="mini"
              :plain="true"
              @click="onCheck(i, '拒绝')"
            >
              拒绝
            </button>
          </div>
        </div>
      </div>
      <uni-notice-bar v-else single text="没有记录" />
    </div>
  </page-layout>
</template>

<script setup>
//TODO: 应该是uniapp的bug为什么使用x-button就会报错ua.split不是function
const query = useQuery();
const current = ref(query.current || 0);
const tabs = ["待审核", "通过", "拒绝"];
const status = computed(() => tabs[current.value]);
const ready = ref(false);
const records = ref([]);

const setRecordsByType = async (newType) => {
  const { data } = await Http.post("/guard/records", { status: newType });
  records.value = data;
};
const changeActionType = async ({ index, name }) => {
  await setRecordsByType(name);
  current.value = index;
  // console.log({ index, status: status.value });
};
const onCheck = async (index, status) => {
  await Http.post(`/guard/update/${records.value[index].id}`, {
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
