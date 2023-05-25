<template>
  <page-layout class="{{tableName}}-main">
    <uni-forms
      ref="valiForm"
      validateTrigger="blur"
      :model-value="{{modelName}}Data"
      label-position="top"
    >
{{formItemToken}}
    </uni-forms>
    <button type="primary" @click="submit('valiForm')">提交</button>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      params: {},
      {{modelName}}Data: {{dataToken}},
      formRules: {{rulesToken}}
    };
  },
  onReady() {
    this.$refs.valiForm.setRules(this.formRules);
  },
  async onLoad(params) {
    this.params = params
    await this.fetchData(params)
  },
  methods: {
    async fetchData(params) {
      const { data } = await $Http.get(`/{{tableName}}/detail/${params.id}`);
      this.{{modelName}}Data = data
    },
    async submit(ref) {
      await this.$refs[ref].validate();
      await $Http.post(`/{{tableName}}/update/${this.params.id}`);
      await utils.tryGotoPage();
    },
  },
};
</script>

<style scoped>
</style>
