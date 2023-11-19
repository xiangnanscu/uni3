<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <x-title>请假详情</x-title>
      <fui-preview :previewData="previewData"></fui-preview>
      <x-title>请假说明</x-title>
      <x-text :text="record.reason" size="32rpx"></x-text>
      <div v-if="roles.class_director">
        <x-title>审核操作</x-title>
        <div class="x-row">
          <x-button @click="check('通过')">通过</x-button>
          <x-button @click="check('拒绝')">拒绝</x-button>
        </div>
      </div>
      <template #actions> </template>
    </uni-card>
    <div style="height: 4em"></div>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      modelName: "student_leave_log",
      previewNames: ["ctime", "status", "school_id", "class_id", "student_id"],
      roles: {},
      record: null,
    };
  },
  async onLoad(query) {
    await helpers.autoLogin();
    this.roles = await helpers.getRoles({ status: "通过" });
    this.query = query;
    await this.fetchData(query);
  },
  computed: {
    previewData() {
      return {
        list: this.previewNames.map((e) => {
          const f = this.modelJson.fields[e];
          let value;
          if (f.reference) {
            value = this.record[`${e}__${f.reference_label_column}`] || this.record[e];
          } else {
            value = this.record[e];
          }
          const res = {
            label: f?.label,
            value,
          };
          return res;
        }),
      };
    },
  },
  methods: {
    async check(status) {
      await usePost(`/${this.modelName}/update/${this.record.id}`, { status });
      helpers.gotoPageWithSuccess("SchoolLeave");
    },
    async fetchData(query) {
      this.modelJson = await useGet(`/${this.modelName}/json`);
      this.record = await useGet(`/${this.modelName}/detail/${query.id}`);
    },
  },
};
</script>

<style scoped>
.x-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
</style>
