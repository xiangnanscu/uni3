<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="poll-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <tinymce-text :html="record.content"></tinymce-text>
      <template #actions> </template>
      <uni-data-checkbox
        multiple
        v-model="selectedPolls"
        :localdata="pollChoices"
        :min="record.min_count"
        :max="record.max_count"
        mode="list"
        @change="change"
      ></uni-data-checkbox>
      <div style="height: 3em"></div>
      <x-button @click="submitPoll">提交</x-button>
    </uni-card>

    <div style="height: 3em"></div>
    <x-bottom>
      <generic-actions
        :target="record"
        target-model="poll"
        style="width: 100%"
      />
    </x-bottom>
  </page-layout>
</template>

<script>
import MixinShare from "./MixinShare";

export default {
  mixins: [MixinShare],
  data() {
    return {
      selectedPolls: [],
      record: null
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  computed: {
    pollChoices() {
      return this.record.model.map((e) => ({
        value: e.选项文本,
        text: e.选项文本
      }));
    }
  },
  methods: {
    async submitPoll() {
      const data = await usePost(
        `/poll_log/insert`,
        this.selectedPolls.map((e) => ({ poll_id: this.record.id, choice: e }))
      );
      if (data.affected_rows === this.selectedPolls.length) {
        uni.showToast({ title: "提交成功" });
        utils.gotoPage("Home");
      }
    },
    async fetchData(query) {
      const { data: poll } = await Http.get(`/poll/detail/${query.id}`);
      this.record = poll;
    }
  }
};
</script>

<style scoped>
.poll-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
