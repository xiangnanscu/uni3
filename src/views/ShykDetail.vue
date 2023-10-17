<template>
  <page-layout v-if="loaded">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="news-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>发布于：{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <x-button @click="joinVol" :disabled="status !== '进行中' || record.joined">{{
        record.joined ? "已签到" : "签到"
      }}</x-button>
      <fui-preview :previewData="previewData"></fui-preview>
      <video
        v-if="record.video"
        :src="'https:' + record.video"
        :show-mute-btn="true"
        controls
        style="width: 100%"
      ></video>
      <div>会议附件</div>
      <uni-list>
        <div
          class="link"
          v-for="(file, i) of record.attachments"
          :key="i"
          @tap="downloadAttachments(file)"
        >
          {{ i + 1 }} . {{ file.name }}
        </div>
      </uni-list>
      <div style="height: 2em"></div>
      <template #actions> </template>
    </uni-card>
  </page-layout>
</template>

<script>
import MixinShare from "./MixinShare";
// import MixinThreadPost from "./MixinThreadPost";

export default {
  mixins: [MixinShare],
  data() {
    return {
      loaded: false,
      record: null,
      target_model: "shyk",
    };
  },
  async onLoad(query) {
    this.record = await useGet(`/${this.target_model}/detail/${query.id}`);
    if (this.user.id) {
      const [joinLog] = await usePost(`/shyk_reg/records`, {
        usr_id: this.user.id,
        shyk_id: this.record.id,
      });
      this.record.joined = joinLog ? joinLog.enabled : false;
    }
    this.loaded = true;
  },
  computed: {
    status() {
      const now = new Date();
      const start = new Date(this.record.start_time);
      const end = new Date(this.record.end_time);
      if (now > end) {
        return "已结束";
      } else if (now > start) {
        return "进行中";
      } else {
        return "待开始";
      }
    },
    previewData() {
      return {
        list: [
          {
            label: "会议状态",
            value: this.status,
          },
          {
            label: "时间",
            value: this.record.start_time?.slice(0, 16),
          },
          {
            label: "地点",
            value: this.record.address,
          },
          {
            label: "类型",
            value: this.record.type,
          },
        ],
      };
    },
  },
  methods: {
    async downloadAttachments(file) {
      uni.showLoading({
        title: "下载中",
      });
      console.log(file);
      try {
        const res = await uni.downloadFile({ url: `https:${file.url}` });
        const saveRes = await uni.saveFile({ tempFilePath: res.tempFilePath });
        const openRes = uni.openDocument({ filePath: saveRes.savedFilePath, menu: true });
        console.log({ saveRes, openRes });
      } finally {
        uni.hideLoading();
      }
      return file;
    },
    async joinVol() {
      await usePost(`/shyk_reg/get_or_create`, {
        usr_id: this.user.id,
        shyk_id: this.record.id,
      });
      uni.showToast({ title: "成功签到" });
      this.record.joined = true;
    },
  },
};
</script>

<style scoped>
.link {
  margin: 8px;
  min-width: 8em;
}
.news-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
