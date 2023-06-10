<template>
  <page-layout>
    <view class="passwordset-main">
      <uni-forms
        ref="valiForm"
        validateTrigger="blur"
        :model-value="PasswordSetData"
        label-position="left"
        label-width="5em"
      >
        <uni-forms-item label="新密码" name="password">
          <uni-easyinput v-model="PasswordSetData.password" />
        </uni-forms-item>
      </uni-forms>
      <x-button @click="submit('valiForm')">提交</x-button>
    </view>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      params: {},
      PasswordSetData: { password: "" },
      formRules: {
        password: {
          rules: [
            {
              required: true,
              errorMessage: "密码不能为空"
            },
            {
              validateFunction: function (rule, value, data, callback) {
                if (value.length > 50) {
                  callback("密码不能超过50个字符");
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
    this.$refs.valiForm.setRules(this.formRules);
  },
  methods: {
    async fetchData(params) {},
    async submit(ref) {
      await this.$refs[ref].validate();
      const { data } = await Http.post(
        `/usr/set_password`,
        this.PasswordSetData
      );
      await utils.tryGotoPage();
      uni.showToast({
        icon: "success",
        title: "修改成功",
        duration: 2000
      });
    }
  }
};
</script>
