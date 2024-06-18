<template>
  <page-layout v-if="record">
    <x-title>{{ record.job_name }}</x-title>
    <x-title :size-rate="0.6">
      {{ utils.fromNow(record.ctime) }}
    </x-title>
    <fui-preview :previewData="previewData"></fui-preview>
    <div style="padding: 0 1rem">
      <tinymce-text :html="record.job_details"></tinymce-text>
    </div>

    <x-button @click="submitResume" :plain="false" size="default" type="default">投</x-button>
    <div style="height: 4em"></div>
  </page-layout>
</template>

<script setup>
import { ref, computed } from "vue";

const record = ref(null);
const query = useQuery();

async function fetchData() {
  record.value = await useGet(`/job/detail/${query.id}`);
}

const previewData = computed(() => {
  const campany = record.value?.company_id__name;
  const list = [
    {
      label: "职位待遇",
      value: `${record.value?.salary_min}-${record.value?.salary_max}元/月`,
    },
    {
      label: "招聘人数",
      value: record.value?.hire_number,
    },
    {
      label: "经验要求",
      value: record.value?.exp_req.join(),
    },
    {
      label: "学历要求",
      value: record.value?.edu_req.join(),
    },
  ];
  if (campany) {
    list.unshift({
      label: "公司名称",
      value: campany,
    });
  }
  return { list };
});

async function submitResume() {
  const logs = await usePost(`/resume_submission/records?select=status`, {
    usr_id: query.usr_id, // 假设 user 对象在组件外部定义并传递进来
    job_id: query.id,
  });
  const queryData = { job_id: record.value?.id, job_name: record.value?.job_name };
  if (logs.length === 1) {
    queryData.status = logs[0].status;
  }
  await utils.gotoPage({ name: `JobSubmit`, query: queryData });
}

onLoad(async () => {
  await fetchData(query);
});
</script>
