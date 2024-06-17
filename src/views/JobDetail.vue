<template>
  <page-layout v-if="record">
    <x-title>{{ record.job_name }}</x-title>
    <x-title :size-rate="0.6">
      {{ utils.fromNow(record.ctime) }}
    </x-title>
    <fui-preview :previewData="previewData"></fui-preview>
    <x-button @click="submitResume" :plain="false" size="default" type="default">投</x-button>
    <div style="height: 4em"></div>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      disableJoinButton: false,
      record: null,
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  computed: {
    previewData() {
      return {
        list: [
          {
            label: "公司名称",
            value: `${this.record.company_id__name}`,
          },
          {
            label: "职位待遇",
            value: `${this.record.salary_min}-${this.record.salary_max}元/月`,
          },
          {
            label: "招聘人数",
            value: this.record.hire_number,
          },
          {
            label: "经验要求",
            value: this.record.exp_req.join(),
          },
          {
            label: "学历要求",
            value: this.record.edu_req.join(),
          },
        ],
      };
    },
  },
  methods: {
    async fetchData(query) {
      this.record = await useGet(`/job/detail/${query.id}`);
    },
    async submitResume() {
      const logs = await usePost(`/resume_submission/records`, {
        usr_id: this.user.id,
        job_id: this.query.id,
      });
      log(logs);
      await utils.gotoPage(`/views/JobSubmit?job_id=${this.query.id}`);
    },
  },
};
</script>

<style scoped>
.stage-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
