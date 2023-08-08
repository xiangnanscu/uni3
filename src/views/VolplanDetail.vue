<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="volplan-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <image
        v-if="record.pics[0]"
        :src="record.pics[0]"
        mode="widthFix"
        style="width: 100%"
      />
      <fui-preview :previewData="previewData"></fui-preview>
      <tinymce-text :html="record.content"></tinymce-text>
      <template #actions> </template>
    </uni-card>
    <div style="height: 3em"></div>
    <x-button @click="joinVol" :disabled="record.joined">{{
      record.joined ? "已登记" : "我要参加"
    }}</x-button>
    <x-bottom>
      <generic-actions
        :target="record"
        target-model="volplan"
        style="width: 100%"
      />
    </x-bottom>
  </page-layout>
</template>

<script>
import { repr } from "@/lib/utils.mjs";
import MixinShare from "./MixinShare";

export default {
  mixins: [MixinShare],
  data() {
    return {
      disableJoinButton: false,
      record: null
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  computed: {
    previewData() {
      return {
        list: [
          {
            label: "召集人",
            value: this.record.xm
          },
          {
            label: "联系方式",
            value: this.record.lxdh
          },
          {
            label: "召集人数",
            value: this.record.amount
          },
          {
            label: "报名结束时间",
            value: this.record.call_endtime?.slice(0, 16)
          },
          {
            label: "志愿活动开始时间",
            value: this.record.plan_starttime?.slice(0, 16)
          },
          {
            label: "志愿活动结束时间",
            value: this.record.plan_endtime?.slice(0, 16)
          }
        ]
      };
    }
  },
  methods: {
    async fetchData(query) {
      const { data: volplan } = await Http.get(`/volplan/detail/${query.id}`);
      this.record = volplan;
      if (this.user.id) {
        const [joinLog] = await usePost(`/volreg/records`, {
          usr_id: this.user.id,
          volplan_id: volplan.id
        });
        this.record.joined = joinLog ? joinLog.enabled : false;
      }
    },
    async joinVol() {
      if (!this.user.id) {
        await utils.gotoPage({
          url: "/views/Login",
          query: {
            redirect: `/views/VolplanDetail?id=${this.query.id}`,
            message: "参加志愿活动需要先登录"
          },
          redirect: true
        });
      } else if (!this.user.username) {
        await utils.gotoPage({
          url: "/views/RealNameCert",
          query: {
            redirect: `/views/VolplanDetail?id=${this.query.id}`,
            message: "参加志愿活动需要进行实名认证"
          },
          redirect: true
        });
      } else {
        await usePost(`/volreg/get_or_create`, {
          volplan_id: this.record.id
        });
        uni.showToast({ title: "成功登记" });
        this.record.joined = true;
      }
    }
  }
};
</script>

<style scoped>
.volplan-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
