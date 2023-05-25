<template>
  <page-layout>
    <uni-card
      :border="false"
      :isFull="true"
      :is-shadow="false"
      padding="10px 0"
    >
      <template v-slot:title
        ><div class="feeplan-title">{{ feeplan.title }}</div>
        <div>缴费金额:{{ feeplan.total / 100 }}元</div></template
      >
      <text user-select class="feeplan-content">{{ feeplan.content }}</text>
    </uni-card>
    <button
      type="primary"
      @click="payFee(params.id)"
      plain="true"
      :disabled="disabled"
    >
      缴费
    </button>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      disabled: false,
      params: {},
      feeplan: { title: "", content: "" }
    };
  },
  onReady() {},
  async onLoad(params) {
    this.params = params;
    await this.fetchData(params);
  },
  methods: {
    async fetchData(params) {
      const { data } = await $Http.get(`/feeplan/${params.id}`);
      this.feeplan = data;
    },
    async payFee(planId) {
      const { data: payed } = await $Http.post(`/orders/check`, {
        feeplan_id: planId
      });
      console.log({ payed });
      if (payed) {
        return uni.showToast({
          title: `您已缴费, 无需重复`,
          icon: "none"
        });
      }
      this.disabled = true;
      const [err, { code }] = await uni.login();
      if (err) {
        throw new Error(err);
      }
      const { data } = await $Http.post(`/wx/jsapi_mini_preorder`, {
        code,
        feeplan_id: planId
      });
      const {
        signature: paySign,
        prepay_id,
        timestamp: timeStamp,
        nonce_str: nonceStr
      } = data;
      const self = this;
      const opts = {
        timeStamp: String(timeStamp),
        nonceStr: String(nonceStr),
        package: `prepay_id=${prepay_id}`,
        signType: "RSA",
        paySign: paySign,
        async success(res) {
          self.disabled = false;
          if (res.errMsg == "requestPayment:ok") {
            await self.tryGotoPage();
          }
        },
        fail(res) {
          self.disabled = false;
          console.log("wx.requestPayment fail:", res);
        }
      };
      wx.requestPayment(opts);
      // await utils.tryGotoPage();
    }
  }
};
</script>

<style scoped>
.feeplan-title {
  font-weight: bold;
  font-size: 110%;
}
.feeplan-content {
  color: black;
  font-size: 100%;
}
</style>
