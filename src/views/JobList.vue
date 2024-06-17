<template>
  <page-layout>
    <div v-if="ready">
      <x-title> </x-title>
      <uni-list v-if="records.length">
        <uni-list-item
          v-for="e in records"
          :key="e.id"
          :title="e.job_name"
          :note="`${e.salary_min}-${e.salary_max}元/月\n${e.company_id__name}`"
          :to="`/views/JobDetail?id=${e.id}`"
          :rightText="utils.fromNow(e.ctime)"
          link="navigateTo"
        >
          <template #body2>
            <x-title> {{}} </x-title>
            <span>{{ `${e.salary_min}-${e.salary_max}元/月\n${e.company_id__name}` }}</span>
          </template>
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
  records.value = await usePost(`/job/records`);
  ready.value = true;
});
</script>

<style>
page {
  background-color: #fff;
}
</style>
