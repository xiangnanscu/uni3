<template>
  <button type="primary" @click="showDrawer('showLeft')" class="thread-btn">
    <text class="word-btn-white">查看所有贴吧</text>
  </button>
  <uni-drawer ref="showLeft" mode="left" :width="320">
    <scroll-view style="height: 100%" scroll-y="true">
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
    </scroll-view>
  </uni-drawer>
  <thread-list :records="threads"></thread-list>

  <fui-fab
    :distance="30"
    position="right"
    :isDrag="true"
    @click="addThread"
  ></fui-fab>
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
    addThread() {
      utils.gotoPage("ThreadAdd");
    },
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
.thread-btn {
  margin: 15px;
}
</style>
