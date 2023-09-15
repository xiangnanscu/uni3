<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <template #actions> </template>
      <p class="poll-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <tinymce-text :html="record.content"></tinymce-text>
      <div v-if="pollEnd" class="tigan center">投票已结束</div>
      <template v-if="loaded && (pollEnd || showResult)">
        <template
          v-for="(
            { 题干, 类型, 选项, 选项图, 最大选择数, 最小选择数, 是否必填 },
            index
          ) in record.items"
          :key="index"
        >
          <div :class="{ tigan: true, center: onlyOne }" style="width: 100%">
            <span v-if="!onlyOne"> {{ index + 1 }} 、 </span>{{ 题干 }}
          </div>
          <div v-for="(c, i) in 选项" :key="i">
            <div class="uni-list-cell">
              <div v-if="选项图[i]">
                <image
                  style="width: 75px; height: 75px"
                  :src="选项图[i]"
                  mode="aspectFit"
                />
              </div>
              <div style="flex: auto">
                <p>
                  {{ c }}
                  {{ count(index, c) }}
                </p>
                <progress
                  :percent="percent(index, c)"
                  show-info
                  style="width: 100%"
                />
              </div>
            </div>
          </div>
        </template>
      </template>
      <template v-else-if="loaded">
        <template
          v-for="(
            { 题干, 类型, 选项, 选项图, 最大选择数, 最小选择数, 是否必填 },
            index
          ) in record.items"
          :key="index"
        >
          <div :class="{ tigan: true, center: onlyOne }" style="width: 100%">
            <span v-if="!onlyOne"> {{ index + 1 }} 、 </span>{{ 题干 }}
          </div>
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
            :min="最小选择数"
            :max="最大选择数"
            mode="list"
          ></x-checkbox>
          <uni-easyinput v-else v-model.trim="answers[index]" type="text" />
          <div style="height: 3em"></div>
          <x-button @click="submitPoll">提交</x-button>
        </template>
      </template>
    </uni-card>
  </page-layout>
</template>

<script>
import MixinShare from "./MixinShare";

export default {
  mixins: [MixinShare],
  data() {
    return {
      pollEnd: false,
      loaded: false,
      showResult: false,
      answers: [],
      pollLogs: [],
      record: null
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
    const now = new Date();
    const startOfDay = utils.getLocalTime(
      new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0)
    );
    const endOfDay = utils.getLocalTime(
      new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59)
    );
    if (utils.getLocalTime(now) > this.record.endtime) {
      this.pollEnd = true;
      this.showResult = true; // 投票结束直接显示结果, 无需投票
    } else {
      this.showResult = await usePost(`/poll_log/voted`, {
        poll_id: this.query.id,
        creator: this.user.id
      });
    }
    this.loaded = true;
  },
  watch: {
    async showResult(show) {
      if (show) {
        this.pollLogs = await usePost(`/poll_log/records`, {
          poll_id: this.query.id
        });
      }
    }
  },
  computed: {
    onlyOne() {
      return this.record.items.length === 1;
    },
    pollChoices() {
      return this.record.items.map((e) => ({
        value: e.选项文本,
        text: e.选项文本
      }));
    },
    totalVote() {
      return this.pollLogs.map((e) => e.answers[itemIndex]).flat().length;
    }
  },
  methods: {
    count(itemIndex, key) {
      let n = 0;
      for (const log of this.pollLogs) {
        n += log.answers[itemIndex].reduce((x, y) => x + y.includes(key), 0);
      }
      return n;
    },
    percent(itemIndex, key) {
      return (
        Math.round(
          (this.count(itemIndex, key) * 1000) /
            this.pollLogs.map((e) => e.answers[itemIndex]).flat().length
        ) / 10
      );
    },
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
        creator: this.user.id,
        answers: this.answers
      });
      this.showResult = true;
      // utils.gotoPage({
      //   name: "SuccessPage",
      //   query: { title: "提交成功,感谢参与" }
      // });
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
.center {
  text-align: center;
}
.tigan {
  color: black;
  margin-top: 1em;
  margin-bottom: 1em;
  font-size: 120%;
  font-weight: bold;
}
.uni-list-cell {
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  align-items: center;
}
.poll-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
