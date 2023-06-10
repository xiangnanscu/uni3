<template>
  <uni-card v-if="member" :title="branch_name" :extra="member.xm">
    <span v-if="FeeplanList.length === 0">暂无需要缴费的记录</span>
    <uni-list v-else :border="false">
      <uni-list-item
        v-for="(feeItem, index) in FeeplanList"
        :key="index"
        :showArrow="false"
        :title="`${feeItem.year}年${String(feeItem.month).padStart(
          2,
          '0'
        )}月团费${feeItem.amount}元`"
      >
        <template #footer>
          <button
            v-if="feeItem.status !== '已缴费'"
            :disabled="disabled"
            @click="payFee(feeItem)"
            type="primary"
            size="mini"
          >
            缴费
          </button>
          <span v-else>{{ feeItem.status }}</span>
        </template>
      </uni-list-item>
    </uni-list>
  </uni-card>
  <div v-else-if="ready" style="padding: 1em">
    <fui-alert
      type="warn"
      spacing
      title="你还不是团员, 无法缴费"
      size="28rpx"
      :marginTop="24"
      :marginBottom="24"
    >
    </fui-alert>
    <navigator
      open-type="navigateBack"
      style="display: flex; justify-content: space-around"
    >
      <button type="primary" size="mini">返回</button>
    </navigator>
  </div>
</template>

<script>
export default {
  data() {
    return {
      ready: false,
      disabled: false,
      member: null,
      branch_name: "",
      FeeplanList: []
    };
  },
  async onLoad(query) {
    if (!this.user.id) {
      await utils.gotoPage({
        url: "/pages/Login",
        query: { redirect: "/pages/FeeplanList" },
        redirect: true
      });
    } else if (!this.user.username) {
      await utils.gotoPage({
        url: "/pages/RealNameCert",
        query: {
          redirect: "/pages/FeeplanList",
          message: "缴纳团费请先实名认证"
        },
        redirect: true
      });
    } else {
      await this.fetchData(query);
    }
  },
  methods: {
    async fetchData(query) {
      const { data: members } = await Http.post(`/youth_member/get`, {
        sfzh: this.user.username
      });

      if (members.length === 0) {
        this.ready = true;
      } else {
        const { data: records } = await Http.post(`/youth_fee/self`);
        this.ready = true;
        this.member = members[0];
        this.branch_name = this.member.branch_name.replace(
          "四川省宜宾市江安县",
          ""
        );
        this.FeeplanList = records;
      }
    },
    async payFee(feeItem) {
      const planId = feeItem.feeplan_id;
      const { data: payed } = await Http.post(`/orders/check`, {
        feeplan_id: planId
      });
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
        youth_fee_id: feeItem.id,
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
            feeItem.status = "已缴费";
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
