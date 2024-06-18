<template>
  <page-layout>
    <div v-if="ready">
      <x-title> {{ jobSpecial.title }}</x-title>
      <image style="width: 100%" :src="jobSpecial.image" mode="widthFix" />
      <uni-list v-if="records.length">
        <uni-list-item
          v-for="e in records"
          :key="e.id"
          :title="e.job_name"
          :note="`${e.salary_min}-${e.salary_max}元/月\n${e.company_id__name || ''}`"
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
const jobSpecial = ref();
onLoad(async () => {
  const { jobs, special } = await usePost(`/job/by_special/${query.id}`);
  records.value = jobs;
  jobSpecial.value = special;
  ready.value = true;
});
</script>

<style>
page {
  background-color: #fff;
}
</style>
