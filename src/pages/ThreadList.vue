<template>
  <page-layout>
    <uni-list :border="false">
      <navigator
        v-for="(item, index) in threads"
        :key="index"
        :url="`/pages/ThreadDetail/ThreadDetail?id=${item.id}`"
        hover-class="navigator-hover"
      >
        <uni-list-item>
          <template v-slot:header>
            <view class="slot-box">
              <image
                class="thread-avatar slot-image"
                :src="item.creator.avatar"
                mode="widthFix"
              ></image>
            </view>
          </template>
          <template v-slot:body
            ><text class="thread-body slot-box slot-text">{{
              item.title
            }}</text>
          </template>
          <template v-slot:footer>
            <view
              ><view class="thread-header">{{ item.creator.nickname }}</view>
              <view class="thread-footer"
                ><text>{{ fromNow(item.ctime) }}</text></view
              >
            </view></template
          >
        </uni-list-item>
      </navigator>
    </uni-list>
    <uni-pagination
      v-if="!noPage"
      :total="total"
      @change="clickPage"
      :current="page"
      :pageSize="pagesize"
    />
  </page-layout>
</template>

<script>
export default {
  props: {
    noPage: { type: Boolean, default: false },
    records: { type: Array, default: () => [] },
    pagesize: { type: Number, default: 10 },
    page: { type: Number, default: 1 }
  },
  data() {
    return {
      query: {},
      current: this.page,
      threads: [],
      total: 0
    };
  },
  async onLoad(query) {
    this.query = query;
  },
  async mounted() {
    // console.log("mounted", this.records);
    if (!this.records.length) {
      await this.fetchData(this.query);
    } else {
      this.threads = this.records;
    }
  },
  methods: {
    async clickPage(e) {
      this.current = e.current;
      await this.fetchData({ page: this.current, pagesize: this.pagesize });
    },
    async fetchData(query) {
      const {
        data: { records, total }
      } = await this.$http.get(
        `/thread?page=${query.page || this.current}&pagesize=${
          query.pagesize || this.pagesize
        }`
      );
      this.threads = records;
      this.total = total;
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
.slot-image {
  display: block;
  margin-right: 10px;
  margin-left: -10px;
  width: 30px;
  height: 30px;
}
.thread-avatar {
  border-radius: 15px;
  width: 30px;
}
.slot-text {
  flex: 1;
  margin-right: 10px;
}
.thread-header {
  color: #666;
  font-size: 70%;
}
.thread-footer {
  color: #666;
  font-size: 60%;
  padding-top: 3px;
}
.thread-body {
  padding: 2px;
}
</style>
