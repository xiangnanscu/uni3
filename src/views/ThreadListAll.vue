<template>
  <page-layout>
    <button type="primary" @click="showDrawer('showLeft')">
      <text class="word-btn-white">查看所有贴吧</text>
    </button>
    <uni-drawer ref="showLeft" mode="left" :width="320">
      <uni-list>
        <uni-list-item
          v-for="(e, i) in forums"
          @click="enterForum({ type: e.name })"
          :clickable="true"
          :key="e.name"
          :title="e.name"
          thumb-size="lg"
          :thumb="e.avatar"
          :link="currentType == e.name ? false : true"
        >
        </uni-list-item>
      </uni-list>
    </uni-drawer>
    <thread-list :records="threads"></thread-list>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      query: {},
      current: this.page,
      threads: [],
      forums: [],
      currentType: "",
      total: 0
    };
  },
  async onLoad(query) {
    console.log("Thread.vue onLoad", query);
    this.query = query;
    await this.fetchData(this.query);
  },
  methods: {
    showDrawer() {
      this.$refs.showLeft.open();
    },
    closeDrawer() {
      this.$refs.showLeft.close();
    },
    async enterForum({ type }) {
      this.currentType = type;
      await this.fetchThreads({ type });
      this.$refs.showLeft.close();
    },
    async fetchThreads(query) {
      const records = await usePost(`/thread/records`, {
        type: query.type,
        status: "通过",
        hide: false
      });
      this.threads = records;
    },
    async fetchData(query) {
      this.forums = await usePost(`/forum/menu`);
      await this.fetchThreads(query);
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
