<template>
  <page-layout>
    <view class="search-bar">
      <uni-easyinput
        suffixIcon="search"
        v-model="searchValue"
        placeholder="请输入查找内容~"
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
      v-if="panelData3.list.length > 0"
      @click="newsClick"
      :panelData="panelData3"
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
      v-if="goddess"
      @click="onGoddessClick"
      :panelData="panelData4"
      :width="150"
      :height="120"
      :marginTop="24"
      :size="25"
      :descSize="26"
    >
      <fui-card>
        <view class="fui-list__item">
          <image style="width: 100%" :src="goddess.pics[0]" mode="widthFix" />
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
    </fui-panel>
    <!-- <ThreadList :records="threads"></ThreadList> -->
  </page-layout>
</template>

<script>
// panelData3: {
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
      panelData3: { head: "青年新闻", list: [] },
      panelData4: { head: "封面女神", list: [] },
      searchValue: "",
      goddess: null,
      imageList: [],
      threads: [],
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
      authSetting: "",
      profile: ""
      // user: {},
    };
  },
  onLoad() {
    console.log("Home onLoad");
  },
  onUnload() {
    console.log("Home onUnload");
  },
  computed: {},
  async onShow() {
    console.log("Home.vue onShow");
    this.threads = [];
    this.noticeText = await this.getNoticeBar();
    // this.threads = await this.getThreads();
    this.goddess = await this.getCoverGoddess();
    this.panelData3.list = await this.getNews();
  },
  methods: {
    newsClick(e) {
      utils.gotoPage({ name: "NewsDetail", query: { id: e.id } });
    },
    gotoNewsPage() {
      utils.gotoPage("NewsList");
    },
    async onGoddessClick() {
      utils.gotoPage({
        url: "/views/GoddessDetail",
        query: { id: this.goddess.id }
      });
    },
    async getNoticeBar() {
      const { data } = await Http.get("/settings?key=notice_bar");
      return data;
    },
    async getCoverGoddess() {
      const { data } = await Http.post("/goddess/cover");
      console.log({ data });
      return data[0];
    },
    async getNews() {
      const {
        data: { records: news }
      } = await Http.post("/news?pagesize=2", {});
      console.log({ news });
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
    },
    getUserProfile() {
      console.log("call uni.getUserProfile");
      uni.getUserProfile({
        desc: "用于完善会员资料",
        fail(err) {
          console.log("uni.getUserProfile fail", err);
        },
        success: (infoRes) => {
          console.log(infoRes, `用户昵称为2：${infoRes.userInfo.nickName}`);
          this.profile = JSON.stringify(infoRes);
        }
      });
    },
    wxUserLogin() {
      uni.login({
        provider: "weixin",
        timeout: 1000,
        fail(res) {
          console.log("uni.login:", res);
          this.log_err = JSON.stringify(res);
        },
        success: async (res) => {
          const { data } = await Http.post("/wx_login", {
            code: res.code
          });
          this.openid = data.openid;
          this.session_key = data.session_key;
        }
      });
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
  height: 385rpx;
  position: relative;
  background: #eee;
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
  font-size: 70%;
  text-align: center;
}
.banner-image {
  width: 120upx;
  height: 120upx;
}
</style>
