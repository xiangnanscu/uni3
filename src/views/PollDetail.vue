<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <template #actions> </template>
      <p class="poll-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <tinymce-text :html="record.content"></tinymce-text>
      <template
        v-for="(
          { 题干, 类型, 选项, 选项图, 最大选择数, 最小选择数, 是否必填 }, index
        ) in record.items"
        :key="index"
      >
        <p style="color: black; margin-top: 1em">
          <span>{{ index + 1 }} </span>、{{ 题干 }}
        </p>
        <uni-row class="row">
          <uni-col></uni-col>
          <uni-col> </uni-col>
        </uni-row>
        <uni-data-checkbox
          v-if="类型 == '单选'"
          v-model="answers[index]"
          :localdata="选项.map((e) => ({ text: e, value: e }))"
          mode="list"
        ></uni-data-checkbox>
        <x-checkbox
          v-else-if="类型 == '多选'"
          v-model="answers[index]"
          :choices="
            选项.map((e, i) => ({
              name: e,
              value: e,
              checked: false,
              image: 选项图[i]
            }))
          "
          :min2="最小选择数"
          :max="最大选择数"
          mode="list"
        ></x-checkbox>
        <uni-easyinput v-else v-model.trim="answers[index]" type="text" />
      </template>
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
      answers: [],
      record: null
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  computed: {
    pollChoices() {
      return this.record.items.map((e) => ({
        value: e.选项文本,
        text: e.选项文本
      }));
    }
  },
  methods: {
    async submitPoll() {
      for (const [i, e] of this.record.items.entries()) {
        const value = this.answers[i];
        if (e.类型 == "多选") {
          if (e.是否必填 == "是" && !value.length) {
            throw `第${i + 1}题必填`;
          }
          if (e.最小选择数 > value.length) {
            throw `第${i + 1}题至少要选${e.最小选择数}个`;
          }
          if (e.最大选择数 < value.length) {
            throw `第${i + 1}题最多选${e.最大选择数}个`;
          }
        } else {
          if (e.是否必填 == "是" && value == "") {
            throw `第${i + 1}题必填`;
          }
        }
      }
      const data = await usePost(`/poll_log/create`, {
        poll_id: this.record.id,
        answers: this.answers
      });
      utils.gotoPage({
        name: "SuccessPage",
        query: { title: "提交成功,感谢参与" }
      });
    },
    async fetchData(query) {
      const poll = await useGet(`/poll/detail/${query.id}`);
      this.record = poll;
      this.answers = poll.items.map((e) => (e.类型 == "多选" ? [] : ""));
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
