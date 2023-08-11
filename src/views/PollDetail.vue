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
          { 题干, 类型, 选项, 最大选择数, 最小选择数, 是否必填 }, index
        ) in record.model"
        :key="index"
      >
        <p style="color: black">
          <span>{{ index + 1 }} </span>、{{ 题干 }}
        </p>
        <uni-data-checkbox
          v-if="类型 == '单选'"
          v-model="answers[index]"
          :localdata="选项.map((e) => ({ text: e, value: e }))"
          mode="list"
        ></uni-data-checkbox>
        <uni-data-checkbox
          v-else-if="类型 == '多选'"
          v-model="answers[index]"
          :localdata="选项.map((e) => ({ text: e, value: e }))"
          :multiple="true"
          :min2="最小选择数"
          :max="最大选择数"
          mode="list"
        ></uni-data-checkbox>
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
      return this.record.model.map((e) => ({
        value: e.选项文本,
        text: e.选项文本
      }));
    }
  },
  methods: {
    async submitPoll() {
      for (const [i, e] of this.record.model.entries()) {
        const value = this.answers[i];
        console.log(i, e);
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
      const { data: poll } = await Http.get(`/poll/detail/${query.id}`);
      this.record = poll;
      this.answers = poll.model.map((e) => (e.类型 == "多选" ? [] : ""));
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
