<template>
  <fui-tabs
    :tabs="tabs"
    center
    @change="changeActionType"
    :current="current"
  ></fui-tabs>
  <uni-card>
    <modelform-uni
      v-if="current == 1"
      :model="PayForOther"
      @sendData="findOtherYouth"
      submit-button-text="查找"
    ></modelform-uni>
    <template v-if="member">
      <fui-preview
        style="font-size: 90%"
        :previewData="{
          list: [
            { label: '支部名称', value: branch_name },
            { label: '姓名', value: member.xm }
          ]
        }"
      ></fui-preview>
      <x-alert
        v-if="fees.length === 0"
        class="no-member"
        title="暂无需要缴费的记录"
      ></x-alert>
      <uni-list v-else :border="false">
        <uni-list-item
          v-for="(feeItem, index) in fees"
          :key="index"
          :showArrow="false"
          :title="`${feeItem.year}年${String(feeItem.month).padStart(
            2,
            '0'
          )}月团费${feeItem.amount}元`"
        >
          <template #footer>
            <x-button
              v-if="feeItem.status !== '已缴费'"
              :disabled="disabled"
              size="mini"
              @click="payFee(feeItem)"
            >
              缴费
            </x-button>
            <span v-else>{{ feeItem.status }}</span>
          </template>
        </uni-list-item>
      </uni-list>
    </template>
    <div v-else-if="ready" style="padding: 1em">
      <x-alert title="你还不是团员, 无法缴费"> </x-alert>
      <navigator
        open-type="navigateBack"
        style="display: flex; justify-content: space-around"
      >
        <x-button size="mini">返回</x-button>
      </navigator>
    </div>
  </uni-card>
</template>

<script setup>
const PayForOther = Model.createModel({
  fields: {
    sfzh: { label: "身份证号", type: "sfzh" }
  }
});
</script>

<script>
export default {
  data() {
    return {
      ready: false,
      disabled: false,
      member: null,
      branch_name: "",
      current: 0,
      tabs: ["本人交费", "代人交费"],
      fees: []
    };
  },
  async onLoad() {
    if (!this.user.username) {
      await utils.gotoPage({
        url: "/views/RealNameCert",
        query: {
          redirect: "/views/FeeplanList",
          message: "缴纳团费请先实名认证"
        },
        redirect: true
      });
    } else {
      await this.fetchData({ sfzh: this.user.username });
    }
  },
  methods: {
    async changeActionType({ index }) {
      this.member = null;
      this.ready = false;
      this.current = index;
      if (index === 0) {
        await this.fetchData({ sfzh: this.user.username });
      }
    },
    async findOtherYouth({ sfzh }) {
      await this.fetchData({ sfzh });
    },
    async fetchData({ sfzh }) {
      const { data: members } = await Http.post(`/youth_member/get`, { sfzh });
      if (members.length === 0) {
        this.ready = true;
      } else {
        const { data: records } = await Http.post(`/youth_fee/by_sfzh`, {
          sfzh
        });
        this.ready = true;
        this.fees = records;
        this.member = members[0];
        this.branch_name = this.member.branch_name.replace(
          "四川省宜宾市江安县",
          ""
        );
      }
    },
    async payFee(feeItem) {
      const planId = feeItem.feeplan_id;
      const { data: payed } = await Http.post(`/orders/check`, {
        youth_fee_id: feeItem.id
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
        timestamp: String(new Date().getTime()),
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
