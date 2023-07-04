<template>
  <page-layout>
    <x-tagbutton
      v-for="(type, i) in types"
      :text="type"
      :key="type"
      :index="i"
      @click="enterForum({ index: i })"
      type="primary"
      :inverted="currentType !== type"
      style="margin-right: 5px; margin-top: 5px; display: inline-block"
    ></x-tagbutton>
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
      types: [],
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
    async enterForum({ index }) {
      const type = this.types[index];
      this.currentType = type;
      await this.fetchThreads({ type });
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
      this.types = await usePost(`/forum/types`);
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
