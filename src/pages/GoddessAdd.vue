<template>
  <page-layout>
    <uni-forms
      ref="valiForm"
      validateTrigger="blur"
      :rules="formRules"
      :model-value="GoddessAddData"
      label-position="top"
    >
      <uni-forms-item label="女神宣言1" name="content">
        <uni-easyinput
          v-model:value="GoddessAddData.content"
          type="textarea"
          autoHeight
        />
      </uni-forms-item>
      <uni-forms-item label="图片" name="pics">
        <alioss-picker
          @fail="uploadFail"
          limit="9"
          v-model:value="GoddessAddData.pics"
          oss-size="100k"
        ></alioss-picker>
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
      GoddessAddData: {
        content: "",
        pics: []
      },
      formRules: {
        content: {
          rules: [
            {
              required: true,
              errorMessage: "女神宣言不能为空"
            },
            {
              validateFunction: function (rule, value, data, callback) {
                if (value.length > 1000) {
                  callback("字数不能超过1000");
                }
                return true;
              }
            }
          ]
        },
        pics: {
          rules: [
            {
              validateFunction: function (rule, value, data, callback) {
                if (value.length === 0) {
                  callback("至少要上传一张图片");
                }
                return true;
              }
            }
          ]
        }
      }
    };
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
    uploadFail({ tempFiles, tempFilePaths }) {
      console.log({
        tempFiles,
        tempFilePaths
      });
      console.log(this.GoddessAddData.pics);
    },
    async fetchData(params) {
      const { data } = await this.$http.get(`/GoddessAdd/${params.id}`);
      this.GoddessAddData = data;
    },
    async submit(ref) {
      await this.$refs[ref].validate();
      await this.$http.post(`/goddess/create`, {
        content: this.GoddessAddData.content,
        pics: this.GoddessAddData.pics.map((f) => f.url)
      });
      await this.tryGotoPage();
    }
  }
};
</script>

<style scoped>
.GoddessAdd-main {
  padding: 15px;
}
</style>
