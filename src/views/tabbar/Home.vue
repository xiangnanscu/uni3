<script setup>
// onShareTimeline
// onShareAppMessage
useWxShare({ title: "江安youth home!", imageUrl: "../../static/cover-share.jpg" });
onShow(async () => {});
</script>

<script>
import { useStore } from "~/composables/useStore";
// panelNews: {
// 	head: 'First UI介绍',
// 	list: [{
// 		src: '/static/images/common/logo.png',
// 		title: 'First UI组件库',
// 		desc: 'First UI 是一套基于uni-app开发的组件化、可复用、易扩展、低耦合的跨平台移动端UI 组件库。'
// 	}, {
// 		src: '/static/images/common/logo.png',
// 		title: 'First UI跨平台UI组件库',
// 		desc: 'First UI组件库，是基于uni-app开发的一款轻量、全面可靠的跨平台移动端组件库。'
// 	}]
// },
export default {
  watch: {
    imageList(res) {},
  },
  data() {
    return {
      panelNews: {
        head: "青年新闻",
        list: [
          {
            id: 142,
            title: "被狗咬伤女童200万捐款惹争议",
            src: "//lzwlkj.oss-cn-shenzhen.aliyuncs.com/jaqn/vc-upload-1698112190246-10.jpg",
          },
          {
            id: 141,
            title: "张艺谋都没拍成的犯罪片，被他拍出来了",
            src: "//lzwlkj.oss-cn-shenzhen.aliyuncs.com/jaqn/vc-upload-1698112190246-4.jpg",
          },
        ],
      },
      volplan: {
        pics: ["//lzwlkj.oss-cn-shenzhen.aliyuncs.com/jaqn/vc-upload-1698107988250-8.jpg"],
        views: 15,
        title: "大妙镇防灭火宣传志愿服务活动",
        ctime: "2023-10-24 08:46:08+08",
        id: 54,
      },
      panelVolplan: { head: "志愿服务", list: [] },
      panelAd: { head: "杂文轩", list: [] },
      panelJob: { head: "招聘求职", list: [] },
      panelPoll: { head: "问卷调查", list: [] },
      searchValue: "",
      goddess: null,
      ads: null,
      jobs: [
        { id: 1, pic: "../../static/zdnl.jpg", title: "职等你来!2024年江安春节招聘" },
        { id: 2, pic: "../../static/zdnl.jpg", title: "国企专场!2024年江安春节招聘" },
      ],
      polls: null,
      news: null,
      wheels: null,
      imageList: [],
      noticeText: "",
      mainKist: [
        {
          url: "../../static/img/vol.png",
          text: "志愿者",
          badge: "",
          pagePath: "/views/VolplanList",
          type: "error",
        },
        {
          url: "../../static/img/chat.png",
          text: "论坛",
          pagePath: "/views/ThreadListAll",
          badge: "",
          type: "error",
        },
        {
          url: "../../static/img/school.png",
          text: "智慧校园",
          pagePath: "/views/SchoolHome",
          badge: "",
          type: "error",
        },
        {
          url: "../../static/gqt.png",
          text: "团建E家",
          pagePath: "/views/EHome",
          badge: "",
          type: "error",
        },
        // {
        //   url: "../../static/img/fee8.png",
        //   text: "缴费",
        //   pagePath: "/views/fee",
        //   badge: "",
        //   type: "error",
        // },
      ],
      openid: "",
      session_key: "",
      log_err: "",
      avatarUrl: "",
      nickname: "",
      phone: "",
      authSetting: "",
    };
  },
  async onLoad() {
    // #ifdef MP-WEIXIN
    this.updateApp();
    // #endif
  },
  onUnload() {
    console.log("Home onUnload");
  },
  computed: {
    panelData4() {
      return { head: `江安“新青年”`, list: [] };
    },
  },
  async onShow() {
    const store = useStore();
    store.disableLoading = true;
    try {
      await useBadgeNumber({ isTabbar: true });
      const { noticeText, goddess, volplan, ads, polls, news, specials } = await usePost(`/home_data`);
      this.specials = specials;
      this.noticeText = noticeText;
      this.goddess = goddess[0];
      this.volplan = volplan[0];
      this.ads = ads;
      this.polls = polls;
      this.panelNews.list = news.map((e) => ({
        id: e.id,
        title: e.title,
        src: e.pics[0],
        desc1: e.content.slice(0, 50),
      }));
      this.wheels = await usePost(`/lottery/records`);
    } catch (error) {
      console.log("更新letter_mdoel错误", error);
    } finally {
      store.disableLoading = false;
    }
  },
  methods: {
    onJobClick(e) {
      utils.gotoPage({ name: `JobSpecialDetail`, query: { id: e.id } });
    },
    updateApp() {
      const updateManager = uni.getUpdateManager();

      updateManager.onCheckForUpdate(function (res) {
        // 请求完新版本信息的回调
        console.log(res, res.hasUpdate);
      });

      updateManager.onUpdateReady(function (res) {
        uni.showModal({
          title: "更新提示",
          content: "新版本已经准备好，是否重启应用？",
          success(res) {
            if (res.confirm) {
              // 新的版本已经下载好，调用 applyUpdate 应用新版本并重启
              updateManager.applyUpdate();
            }
          },
        });
      });

      updateManager.onUpdateFailed(function (res) {
        // 新的版本下载失败
        console.log("新的版本下载失败", res);
      });
    },
    newsClick(e) {
      utils.gotoPage({ name: "NewsDetail", query: { id: e.id } });
    },
    gotoNewsPage() {
      utils.gotoPage("NewsList");
    },
    async onVolplanClick() {
      utils.gotoPage({
        url: "/views/VolplanDetail",
        query: { id: this.volplan.id },
      });
    },
    async onAdClick(e) {
      utils.gotoPage({
        url: "/views/AdDetail",
        query: { id: e.id },
      });
    },
    async onGoddessClick() {
      utils.gotoPage({
        url: "/views/GoddessDetail",
        query: { id: this.goddess.id },
      });
    },
    async onGoddessListClick() {
      utils.gotoPage({
        url: "/views/GoddessList",
      });
    },
    async onVolplanListClick() {
      utils.gotoPage({
        url: "/views/VolplanList",
      });
    },
    async onAdListClick() {
      utils.gotoPage({
        url: "/views/AdList",
      });
    },
    async getNoticeBar() {
      const { data } = await Http.get("/settings?key=notice_bar");
      return data;
    },
    async getAds() {
      const data = await usePost("/ad/records", {
        hide: false,
      });
      return data;
    },
    async getCoverVolplan() {
      const data = await usePost("/volplan/cover");
      return data[0];
    },
    async getCoverGoddess() {
      const data = await usePost("/goddess/cover");
      return data[0];
    },
    async getNews() {
      const news = await usePost("/news/records?limit=2", { status: "通过" });
      return news.map((e) => ({
        id: e.id,
        title: e.title,
        src: e.pics[0],
        desc1: e.content.slice(0, 50),
      }));
    },
    change(event) {
      console.log({ event });
    },
    getSetting() {
      wx.getSetting({
        fail(res) {
          console.log("wx.getSetting fail:", res);
        },
        success: (res) => {
          console.log(res.authSetting);
          // https://developers.weixin.qq.com/miniprogram/dev/api/open-api/setting/AuthSetting.html
          this.authSetting = JSON.stringify(res.authSetting);
          // res.authSetting = {
          //   "scope.userInfo": true,
          //   "scope.userLocation": true
          // }
        },
      });
    },
    // https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/getPhoneNumber.html
    async getPhoneNumber(e) {
      // 用户允许: e.detail = {errMsg: "getPhoneNumber:ok", code: "??" encryptedData: "??"iv: "??"}
      // 用户拒绝: e.detail = {errMsg: "getPhoneNumber:fail user deny"}
      const { code } = e.detail;
      if (code) {
        const { data } = await Http.post("/wx_phone", { code });
        this.phone = data.purePhoneNumber;
      }
    },
    openSetting(e) {
      console.log("授权：", e);
    },
    getAvatar(e) {
      console.log("头像：", e);
      this.avatarUrl = e.detail?.avatarUrl;
    },
  },
};
</script>

<template>
  <page-layout>
    <view class="search-bar">
      <uni-easyinput
        suffixIcon="search"
        v-model="searchValue"
        placeholder="请输入查找内容"
        iconClick="onClick"
      ></uni-easyinput>
    </view>
    <uni-notice-bar class="notice-bar" :speed="50" show-icon scrollable :text="noticeText" />
    <uni-grid :column="4" :show-border="false" :square="false" @change="change">
      <uni-grid-item v-for="(item, index) in mainKist" :index="index" :key="index">
        <view class="grid-item-box" style="text-align: center">
          <x-navigator :url="item.pagePath" hover-class="navigator-hover" open-type="navigate">
            <image class="banner-image" :src="item.url" mode="widthFix" style="width: 64px; height: 64px" />
            <view>
              <text class="logo-text">{{ item.text }}</text>
            </view>
            <view v-if="item.badge" class="grid-dot">
              <uni-badge :text="item.badge" :type="item.type" />
            </view>
          </x-navigator>
        </view>
      </uni-grid-item>
    </uni-grid>
    <fui-panel v-if="specials?.length" :panelData="panelJob" :marginTop="24" :size="25" :descSize="26">
      <swiper class="swiper" circular :indicator-dots="true" :autoplay="true" :interval="2000" :duration="500">
        <swiper-item v-for="e in specials" :key="e.id">
          <view class="swiper-item">
            <image @click="onJobClick(e)" style="width: 100%" :src="e.image" mode="widthFix" />
          </view>
        </swiper-item>
      </swiper>
    </fui-panel>
    <fui-panel
      v-if="panelNews.list.length > 0"
      @click="newsClick"
      :panelData="panelNews"
      :width="150"
      :height="120"
      :marginTop="24"
      :size="25"
      :descSize="26"
    >
      <fui-list-cell arrow :bottomBorder="false" topBorder topLeft="32" @click="gotoNewsPage">
        <text class="fui-text__link">查看更多</text>
      </fui-list-cell>
    </fui-panel>
    <fui-panel
      v-if="goddess"
      :panelData="panelData4"
      :width="150"
      :height="120"
      :marginTop="24"
      :size="25"
      :descSize="26"
    >
      <fui-card>
        <view class="fui-list__item">
          <image @click="onGoddessClick" style="width: 100%" :src="goddess.pics[0]" mode="widthFix" />
        </view>
      </fui-card>
      <fui-list-cell arrow :bottomBorder="false" topBorder topLeft="32" @click="onGoddessClick">
        <text class="fui-text__link"> {{ goddess.title }}</text>
      </fui-list-cell>
      <fui-list-cell arrow :bottomBorder="false" topBorder topLeft="32" @click="onGoddessListClick">
        <text class="fui-text__link"> 查看更多</text>
      </fui-list-cell>
    </fui-panel>
    <fui-panel
      v-if="volplan"
      :panelData="panelVolplan"
      :width="150"
      :height="120"
      :marginTop="24"
      :size="25"
      :descSize="26"
    >
      <fui-card>
        <view class="fui-list__item">
          <image @click="onVolplanClick" style="width: 100%" :src="volplan.pics[0]" mode="widthFix" />
        </view>
      </fui-card>
      <fui-list-cell arrow :bottomBorder="false" topBorder topLeft="32" @click="onVolplanClick">
        <text class="fui-text__link"> {{ volplan.title }}</text>
      </fui-list-cell>
      <fui-list-cell arrow :bottomBorder="false" topBorder topLeft="32" @click="onVolplanListClick">
        <text class="fui-text__link"> 查看更多</text>
      </fui-list-cell>
    </fui-panel>
    <fui-panel v-if="ads?.length" :panelData="panelAd" :marginTop="24" :size="25" :descSize="26">
      <fui-card>
        <view class="fui-list__item">
          <swiper class="swiper" circular :indicator-dots="true" :autoplay="true" :interval="2000" :duration="500">
            <swiper-item v-for="e in ads" :key="e.id">
              <view>
                <image @click="onAdClick(e)" style="width: 100%" :src="e.pics[0]" mode="widthFix" />
              </view>
            </swiper-item>
          </swiper>
        </view>
      </fui-card>
      <fui-list-cell arrow :bottomBorder="false" topBorder topLeft="32" @click="onAdListClick">
        <text class="fui-text__link"> 查看更多</text>
      </fui-list-cell>
    </fui-panel>

    <fui-panel
      v-if="polls && polls.length"
      :panelData="panelPoll"
      :width="150"
      :height="120"
      :marginTop="24"
      :size="25"
      :descSize="26"
    >
      <uni-list>
        <uni-list-item
          v-for="e in polls"
          :key="e.id"
          :title="e.title"
          showArrow
          link="navigateTo"
          :to="`/views/PollDetail?id=${e.id}`"
        >
        </uni-list-item>
      </uni-list>
    </fui-panel>
    <x-title>幸运转盘</x-title>
    <uni-list>
      <uni-list-item
        v-for="w in wheels"
        :key="w.id"
        :title="w.name"
        showArrow
        link="navigateTo"
        :to="`/views/LuckyWheel?id=${w.id}`"
      >
      </uni-list-item>
    </uni-list>
    <fui-divider text="到底了" />
  </page-layout>
</template>

<style scoped>
.swiper-item {
  width: 100%;
  height: 600rpx;
  display: flex;
  justify-content: center;
  font-size: 34rpx;
  font-weight: 600;
}
.fui-section__title {
  margin-left: 32rpx;
}
.fui-list__item {
  width: 100%;
  position: relative;
  background: #eee;
}
.fui-banner__item {
  width: 100%;
  align-items: center;
  justify-content: center;
  font-size: 34rpx;
  font-weight: 600;
}

.fui-cover {
  width: 100%;
  display: block;
}
.fui-text__link {
  color: #666;
  font-size: 25rpx;
}
.grid-dot {
  position: absolute;
  top: 5px;
  right: 15px;
}
.notice-bar {
  /* margin-top: 150px; */
}
.search-bar {
  margin-bottom: 10px;
}
.logo-text {
  font-size: 90%;
  text-align: center;
}
.banner-image {
  width: 120upx;
  height: 120upx;
}
</style>
