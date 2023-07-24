<template>
  <page-layout>
    <view class="search-bar">
      <uni-easyinput
        suffixIcon="search"
        v-model="searchValue"
        placeholder="请输入查找内容."
        iconClick="onClick"
      ></uni-easyinput>
    </view>
    <uni-notice-bar
      class="notice-bar"
      :speed="50"
      show-icon
      scrollable
      :text="noticeText"
    />
    <uni-grid :column="4" :show-border="false" :square="false" @change="change">
      <uni-grid-item
        v-for="(item, index) in mainKist"
        :index="index"
        :key="index"
      >
        <view class="grid-item-box" style="text-align: center">
          <navigator
            :url="item.pagePath"
            hover-class="navigator-hover"
            open-type="navigate"
          >
            <image class="banner-image" :src="item.url" mode="widthFix" />
            <view>
              <text class="logo-text">{{ item.text }}</text>
            </view>
            <view v-if="item.badge" class="grid-dot">
              <uni-badge :text="item.badge" :type="item.type" />
            </view>
          </navigator>
        </view>
      </uni-grid-item>
    </uni-grid>
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
      <fui-list-cell
        arrow
        :bottomBorder="false"
        topBorder
        topLeft="32"
        @click="gotoNewsPage"
      >
        <text class="fui-text__link">查看更多</text>
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
          <image
            @click="onVolplanClick"
            style="width: 100%"
            :src="volplan.pics[0]"
            mode="widthFix"
          />
        </view>
      </fui-card>
      <fui-list-cell
        arrow
        :bottomBorder="false"
        topBorder
        topLeft="32"
        @click="onVolplanClick"
      >
        <text class="fui-text__link"> {{ volplan.title }}</text>
      </fui-list-cell>
      <fui-list-cell
        arrow
        :bottomBorder="false"
        topBorder
        topLeft="32"
        @click="onVolplanListClick"
      >
        <text class="fui-text__link"> 查看更多</text>
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
          <image
            @click="onGoddessClick"
            style="width: 100%"
            :src="goddess.pics[0]"
            mode="widthFix"
          />
        </view>
      </fui-card>
      <fui-list-cell
        arrow
        :bottomBorder="false"
        topBorder
        topLeft="32"
        @click="onGoddessClick"
      >
        <text class="fui-text__link"> {{ goddess.title }}</text>
      </fui-list-cell>
      <fui-list-cell
        arrow
        :bottomBorder="false"
        topBorder
        topLeft="32"
        @click="onGoddessListClick"
      >
        <text class="fui-text__link"> 查看更多</text>
      </fui-list-cell>
    </fui-panel>
    <fui-panel
      v-if="ads?.length"
      :panelData="panelAd"
      :marginTop="24"
      :size="25"
      :descSize="26"
    >
      <swiper
        class="swiper"
        circular
        :indicator-dots="true"
        :autoplay="true"
        :interval="2000"
        :duration="500"
      >
        <swiper-item v-for="e in ads" :key="e.id">
          <view>
            <image
              @click="onAdClick(e)"
              style="width: 100%"
              :src="e.pics[0]"
              mode="widthFix"
            />
          </view>
        </swiper-item>
      </swiper>
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

    <fui-divider text="到底了" />
  </page-layout>
</template>

<script>
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
    imageList(res) {}
  },
  data() {
    return {
      panelNews: { head: "青年新闻", list: [] },
      panelVolplan: { head: "志愿服务", list: [] },
      panelAd: { head: "广告赞助", list: [] },
      panelPoll: { head: "问卷调查", list: [] },
      searchValue: "",
      goddess: null,
      volplan: null,
      ads: null,
      polls: null,
      news: null,
      imageList: [],
      noticeText: "",
      mainKist: [
        {
          url: "../../static/img/vol.png",
          text: "志愿者",
          badge: "",
          pagePath: "/views/VolplanList",
          type: "error"
        },
        {
          url: "../../static/img/chat.png",
          text: "论坛",
          pagePath: "/views/ThreadListAll",
          badge: "",
          type: "error"
        },
        {
          url: "../../static/img/files3.png",
          text: "资讯",
          pagePath: "/views/NewsList",
          badge: "",
          type: "error"
        },
        {
          url: "../../static/img/fee8.png",
          text: "团费",
          pagePath: "/views/FeeplanList",
          badge: "",
          type: "error"
        }
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
      authSetting: ""
    };
  },
  onLoad() {
    console.log("Home onLoad");
  },
  onUnload() {
    console.log("Home onUnload");
  },
  computed: {
    panelData4() {
      return { head: `封面${this.goddess?.sex}神`, list: [] };
    }
  },
  async onShow() {
    const { noticeText, goddess, volplan, ads, polls, news } = await usePost(
      `/home_data?limit=2`
    );
    this.noticeText = noticeText;
    this.goddess = goddess[0];
    this.volplan = volplan[0];
    this.ads = ads;
    this.polls = polls;
    this.panelNews.list = news.map((e) => ({
      id: e.id,
      title: e.title,
      src: e.pics[0],
      desc1: e.content.slice(0, 50)
    }));
  },
  methods: {
    newsClick(e) {
      utils.gotoPage({ name: "NewsDetail", query: { id: e.id } });
    },
    gotoNewsPage() {
      utils.gotoPage("NewsList");
    },
    async onVolplanClick() {
      utils.gotoPage({
        url: "/views/VolplanDetail",
        query: { id: this.volplan.id }
      });
    },
    async onAdClick(e) {
      utils.gotoPage({
        url: "/views/AdDetail",
        query: { id: e.id }
      });
    },
    async onGoddessClick() {
      utils.gotoPage({
        url: "/views/GoddessDetail",
        query: { id: this.goddess.id }
      });
    },
    async onGoddessListClick() {
      utils.gotoPage({
        url: "/views/GoddessList"
      });
    },
    async onVolplanListClick() {
      utils.gotoPage({
        url: "/views/VolplanList"
      });
    },
    async getNoticeBar() {
      const { data } = await Http.get("/settings?key=notice_bar");
      return data;
    },
    async getAds() {
      const data = await usePost("/ad/records", {
        hide: false
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
        desc1: e.content.slice(0, 50)
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
        }
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
    }
  }
};
</script>

<style scoped>
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
