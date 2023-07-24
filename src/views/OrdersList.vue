<template>
  <page-layout class="orders-main">
    <uni-list :border="false">
      <uni-list-item
        v-for="(item, index) in OrdersList"
        :key="index"
        :title="extractOrderInfo(item)"
        :showArrow="false"
        :pageSize="pageSize"
        :rightText="fromNow(item.success_time)"
      >
      </uni-list-item>
    </uni-list>
    <uni-pagination
      v-if="pageSize < total"
      :total="total"
      @change="clickPage"
      :current="current"
    />
  </page-layout>
</template>

<script setup>
const user = useUser();
const extractOrderInfo = (order) => {
  let payOther;
  console.log({ user, order });
  if (user.openid !== order.openid) {
    payOther = "他人代缴";
  } else if (user.username !== order.youth_fee_id__sfzh) {
    payOther = "代他人缴";
  } else {
    payOther = "本人缴纳";
  }
  return `${order.description} / ${order.total / 100}元  / ${payOther}`;
};
</script>

<script>
export default {
  data() {
    return {
      pageSize: 60,
      total: 0,
      current: 1,
      query: {},
      OrdersList: []
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  methods: {
    async clickPage(e) {
      this.current = e.current;
      await this.fetchData({ page: this.current, pagesize: this.pageSize });
    },
    async fetchData(query) {
      const {
        data: { records, total }
      } = await Http.get(
        `/orders/mylist?page=${query.page || this.current}&pagesize=${
          query.pagesize || this.pageSize
        }`
      );
      this.OrdersList = records;
      this.total = total;
    }
  }
};
</script>
