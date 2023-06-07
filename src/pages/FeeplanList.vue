<template>
  <uni-card v-if="member" :title="branch_name" :extra="member.xm">
    <uni-list :border="false">
      <uni-list-item
        v-for="(item, index) in FeeplanList"
        :key="index"
        :showArrow="false"
        :title="`${item.year}年${String(item.month).padStart(2, '0')}月团费${
          item.amount
        }元`"
      >
        <template #footer>
          <button
            v-if="item.status !== '已缴费'"
            :disabled="disabled"
            @click="payFee(item)"
            type="primary"
            size="mini"
          >
            缴费
          </button>
          <span v-else>{{ item.status }}</span>
        </template>
      </uni-list-item>
    </uni-list>
  </uni-card>
</template>

<script>
export default {
  data() {
    return {
      disabled: false,
      member: null,
      branch_name: "",
      FeeplanList: []
    };
  },
  async onLoad(query) {
    console.log("this.user", useSession());
    await this.fetchData(query);
  },
  methods: {
    async fetchData(query) {
      const { data: records } = await Http.post(`/youth_fee/self`);
      const { data: member } = await Http.post(`/youth_member/get`, {
        sfzh: this.user.username
      });
      this.member = member;
      this.branch_name = member.branch_name.replace("四川省宜宾市江安县", "");
      this.FeeplanList = records;
    },
    async payFee({ feeplan_id: planId }) {
      const { data: payed } = await Http.post(`/orders/check`, {
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
      const { code, errMsg } = await uni.login();
      if (errMsg !== "login:ok") {
        throw new Error(errMsg);
      }
      const { data } = await Http.post(`/wx/jsapi_mini_preorder`, {
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
            uni.showToast({ title: "缴费成功" });
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
.slot-box {
  display: flex;
  flex-direction: row;
  align-items: center;
}
.footer {
  color: #666;
  font-size: 90%;
  padding-top: 3px;
}
</style>
