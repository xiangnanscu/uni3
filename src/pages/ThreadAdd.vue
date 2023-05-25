<template>
  <page-layout class="ThreadAdd-main">
    <uni-forms
      ref="valiForm"
      validateTrigger="blur"
      :model-value="ThreadAddData"
      label-position="top"
    >
      <uni-forms-item label="标题" name="title">
        <uni-easyinput v-model:value="ThreadAddData.title" />
      </uni-forms-item>
      <uni-forms-item label="内容" name="content">
        <uni-easyinput
          v-model:value="ThreadAddData.content"
          type="textarea"
          :autoHeight="true"
        />
      </uni-forms-item>
    </uni-forms>
    <button type="primary" @click="submit('valiForm')">发帖</button>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      params: {},
      ThreadAddData: { title: "", content: "" },
      formRules: {
        content: {
          rules: [
            {
              required: true,
              errorMessage: "内容不能为空"
            },
            {
              validateFunction: function (rule, value, data, callback) {
                if (value.length > 5000) {
                  callback("字数不能超过5000");
                }
                return true;
              }
            }
          ]
        }
      }
    };
  },
  onShow() {
    this.ThreadAddData = { title: "", content: "" };
  },
  onReady() {
    // 需要在onReady中设置规则
    this.$refs.valiForm.setRules(this.formRules);
  },
  async onLoad(params) {
    this.params = params;
    // await this.fetchData(params);
  },
  methods: {
    async fetchData(params) {
      const { data } = await this.$http.get(`/ThreadAdd/${params.id}`);
      this.ThreadAddData = data;
    },
    async submit(ref) {
      await this.$refs[ref].validate();
      await this.$http.post(`/thread/create`, this.ThreadAddData);
      await this.gotoPage({ url: "/pages/ThreadList/ThreadList" });
    }
  }
};
</script>

<style scoped>
.ThreadAdd-main {
  padding: 15px;
}
</style>
