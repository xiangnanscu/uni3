<template>
  <page-layout class="usr-main">
    <uni-forms
      ref="valiForm"
      validateTrigger="blur"
      :rules="formRules"
      :model-value="usrData"
      label-position="top"
    >
      <uni-forms-item label="姓名" name="xm">
        <uni-easyinput v-model="usrData.xm" />
      </uni-forms-item>
      <uni-forms-item label="密码" name="password">
        <uni-easyinput v-model="usrData.password" />
      </uni-forms-item>
    </uni-forms>
    <button type="primary" @click="submit('valiForm')">提交</button>
  </page-layout>
</template>
<script>
export default {
  data() {
    return {
      params: {},
      usrData: { xm: "", password: "" },
      formRules: {
        xm: {
          rules: [
            {
              required: true,
              errorMessage: "姓名不能为空",
            },
            {
              validateFunction: function (rule, value, data, callback) {
                if (value.length > 255) {
                  callback("字数不能超过255");
                }
                return true;
              },
            },
          ],
        },
        password: {
          rules: [
            {
              required: true,
              errorMessage: "密码不能为空",
            },
            {
              validateFunction: function (rule, value, data, callback) {
                if (value.length > 255) {
                  callback("字数不能超过255");
                }
                return true;
              },
            },
          ],
        },
      },
    };
  },
  async onLoad(params) {
    this.params = params;
    await this.fetchData(params);
  },
  methods: {
    async fetchData(params) {
      const { data } = await this.$http.get(`/usr/${params.id}`);
      this.usrData = data;
    },
    async submit(ref) {
      await this.$refs[ref].validate();
      await this.$http.post(`/usr/update/${this.params.id}`);
      await this.tryGotoPage();
    },
  },
};
</script>
<style scoped>
.usr-main {
  padding: 15px;
}
</style>
