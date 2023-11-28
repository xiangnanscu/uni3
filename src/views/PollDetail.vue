<template>
  <page-layout v-if="poll">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <template #actions> </template>
      <p class="poll-title">{{ poll.title }}</p>
      <x-subtitle>
        <div>{{ utils.fromNow(poll.ctime) }}</div>
      </x-subtitle>
      <image
        v-if="poll.pics[0]"
        :src="poll.pics[0]"
        @click="previewImage(poll.pics[0])"
        mode="widthFix"
        style="width: 100%; margin: auto; margin-bottom: 1em"
      />
      <tinymce-text :html="poll.content"></tinymce-text>
      <div v-if="timelineShareMode" class="tigan center">
        请点击下方“前往小程序”进行投票
      </div>
      <div v-if="pollEnd" class="tigan center">投票已结束</div>
      <template v-if="loaded && (pollEnd || showResult)">
        <template
          v-for="(
            { 题干, 类型, 选中, 选项, 选项图, 最大选择数, 最小选择数, 是否必填 },
            itemIndex
          ) in poll.items"
          :key="itemIndex"
        >
          <div :class="{ tigan: true, center: onlyOne }" style="width: 100%">
            <span v-if="!onlyOne"> {{ itemIndex + 1 }} 、 </span>{{ 题干 }}
          </div>
          <div v-for="(c, i) in 选项" :key="i">
            <div class="uni-list-cell">
              <div v-if="选项图[i]" style="width: 75px">
                <image
                  style="width: 75px; height: 75px"
                  :src="选项图[i]"
                  mode="aspectFit"
                />
              </div>
              <div style="flex: auto; padding: 0 5px">
                <p>
                  {{ c }}
                  <span style="font-weight: bold">{{ 选中[i] ? "（已选）" : "" }}</span>
                  {{ count(itemIndex, c) }}票
                </p>
                <uni-row>
                  <uni-col :span="24">
                    <progress
                      :percent="percent(itemIndex, c)"
                      show-info
                      style="width: 100%"
                    />
                  </uni-col>
                  <uni-col> </uni-col>
                </uni-row>
              </div>
            </div>
          </div>
        </template>
      </template>
      <template v-else-if="loaded">
        <template
          v-for="(
            { 题干, 类型, 选项, 选项图, 最大选择数, 最小选择数, 是否必填 }, index
          ) in poll.items"
          :key="index"
        >
          <div :class="{ tigan: true, center: onlyOne }" style="width: 100%">
            <span v-if="!onlyOne"> {{ index + 1 }} 、 </span>{{ 题干 }}
          </div>
          <x-radio
            v-if="类型 == '单选'"
            v-model="answers[index]"
            :choices="
              选项.map((e, i) => ({
                name: e,
                value: e,
                checked: false,
                image: 选项图[i],
              }))
            "
          ></x-radio>
          <x-checkbox
            v-else-if="类型 == '多选'"
            v-model="answers[index]"
            :choices="
              选项.map((e, i) => ({
                name: e,
                value: e,
                checked: false,
                image: 选项图[i],
              }))
            "
            :min="最小选择数"
            :max="最大选择数"
            mode="list"
          ></x-checkbox>
          <uni-easyinput v-else v-model.trim="answers[index]" type="text" />
        </template>
        <div style="height: 3em"></div>
        <x-button @click="submitPoll">提交</x-button>
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
      timelineShareMode: false,
      pollEnd: false,
      loaded: false,
      showResult: false,
      answers: [],
      pollLogs: [],
      poll: null,
    };
  },
  async onLoad(query) {
    this.query = query;
    const scene = wx?.getLaunchOptionsSync().scene;
    await this.fetchData(query);
    const now = new Date();
    if (scene === 1154) {
      this.timelineShareMode = true;
      return;
    }
    const startOfDay = utils.getLocalTime(
      new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0),
    );
    const endOfDay = utils.getLocalTime(
      new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59),
    );
    if (utils.getLocalTime(now) > this.poll.endtime) {
      this.pollEnd = true;
      this.showResult = true; // 投票结束直接显示结果, 无需投票
    } else {
      this.showResult = await usePost(`/poll_log/voted`, {
        poll_id: this.query.id,
        creator: this.user.id,
      });
    }
    this.loaded = true;
  },
  watch: {
    async showResult(show) {
      if (show) {
        this.pollLogs = await usePost(`/poll_log/records`, {
          poll_id: this.query.id,
        });
        const myVote = this.pollLogs.find((e) => e.creator === this.user.id);
        if (myVote) {
          for (const [i, answer] of myVote.answers.entries()) {
            const item = this.poll.items[i]; // 题目
            item.选中 = item.选项.map((choice) =>
              Array.isArray(answer) ? answer.includes(choice) : choice === answer,
            );
          }
        }
      }
    },
  },
  computed: {
    onlyOne() {
      return this.poll.items.length === 1;
    },
    pollChoices() {
      return this.poll.items.map((e) => ({
        value: e.选项文本,
        text: e.选项文本,
      }));
    },
    totalVote() {
      return this.pollLogs.map((e) => e.answers[itemIndex]).flat().length;
    },
  },
  methods: {
    count(itemIndex, key) {
      let n = 0;
      const config = this.poll.items[itemIndex];
      if (config.类型 == "多选") {
        for (const log of this.pollLogs) {
          n += log.answers[itemIndex].reduce((x, y) => x + y.includes(key), 0);
        }
      } else if (config.类型 == "单选") {
        for (const log of this.pollLogs) {
          if (log.answers[itemIndex] == key) n += 1;
        }
      }
      return n;
    },
    percent(itemIndex, key) {
      return (
        Math.round(
          (this.count(itemIndex, key) * 1000) /
            this.pollLogs.map((e) => e.answers[itemIndex]).flat().length,
        ) / 10
      );
    },
    async submitPoll() {
      for (const [i, e] of this.poll.items.entries()) {
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
        poll_id: this.poll.id,
        // creator: this.user.id,
        answers: this.answers,
      });
      this.showResult = true;
      uni.showToast({ title: "提交成功" });
    },
    async fetchData(query) {
      const poll = await useGet(`/poll/detail/${query.id}`);
      this.poll = poll;
      this.record = poll;
      // 初始化
      this.answers = poll.items.map((e) => (e.类型 == "多选" ? [] : ""));
      this.poll.items.forEach((item) => {
        item.选中 = item.选项.map(() => false);
      });
    },
  },
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
