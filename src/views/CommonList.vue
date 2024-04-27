<template>
  <page-layout>
    <div v-if="ready">
      <x-title v-if="query.title"> {{ query.title }}</x-title>
      <uni-list v-if="records.length">
        <uni-list-item
          v-for="e in records"
          :key="e.id"
          :title="e.title"
          :to="`/views/${utils.toModelName(query.model)}Detail?id=${e.id}`"
          :rightText="utils.fromNow(e.ctime)"
          link="navigateTo"
        >
        </uni-list-item>
      </uni-list>
      <f-alert v-else>暂无记录</f-alert>
    </div>
    <f-alert v-else>加载中</f-alert>
  </page-layout>
</template>

<script setup>
const ready = ref();
const query = useQuery();
const records = ref([]);
onLoad(async () => {
  records.value = await usePost(`/${query.model}/records`);
  ready.value = true;
});
</script>

<style>
page {
  background-color: #fff;
}
</style>
