<template>
  <page-layout>
    <ThreadList :records="threads"></ThreadList>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      query: {},
      current: this.page,
      threads: [],
      total: 0
    };
  },
  async onLoad(query) {
    console.log("Thread.vue onLoad", query);
    this.query = query;
  },
  async onShow() {
    console.log("Thread.vue onShow", this.records);
    await this.fetchData(this.query);
  },
  methods: {
    async fetchData(query) {
      const {
        data: { records, total }
      } = await Http.get(`/thread?page=1&pagesize=${query.pagesize || 100}`);
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
