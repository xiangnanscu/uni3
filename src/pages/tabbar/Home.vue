<template>
  <page-layout>
    <view class="search-bar">
      <uni-easyinput
        suffixIcon="search"
        v-model="searchValue"
        placeholder="请输入查找内容~"
        @iconClick="onClick"
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
            <image class="image logo" :src="item.url" mode="aspectFit" />
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
    <uni-card v-if="goddess" @click="onGoddessClick" :is-full="false">
      <template v-slot:cover>
        <image
          @click="onGoddessClick"
          style="width: 100%"
          :src="goddess.pics[0]"
        />
      </template>

      <text class="uni-body">{{ goddess.content }}</text>
      <!-- <template v-slot:actions>
          <view class="card-actions">
            <view class="card-actions-item" @click="actionsClick('分享')">
              <uni-icons type="pengyouquan" size="18" color="#999"></uni-icons>
              <text class="card-actions-item-text">分享</text>
            </view>
            <view class="card-actions-item" @click="actionsClick('点赞')">
              <uni-icons type="heart" size="18" color="#999"></uni-icons>
              <text class="card-actions-item-text">点赞</text>
            </view>
            <view class="card-actions-item" @click="actionsClick('评论')">
              <uni-icons type="chatbubble" size="18" color="#999"></uni-icons>
              <text class="card-actions-item-text">评论</text>
            </view>
          </view>
        </template> -->
    </uni-card>
    <ThreadList :records="threads"></ThreadList>
  </page-layout>
</template>

<script>
// console.log({ ThreadList });
export default {
  watch: {
    imageList(res) {}
  },
  data() {
    return {
      searchValue: "",
      goddess: null,
      imageList: [],
      threads: [],
      noticeText: "",
      mainKist: [
        {
          url: "../../static/img/volunteer.png",
          text: "志愿者",
          badge: "",
          pagePath: "/pages/VolplanList",
          type: "error"
        },
        {
          url: "../../static/img/chat.png",
          text: "论坛",
          pagePath: "/pages/ThreadListAll",
          badge: "",
          type: "error"
        },
        {
          url: "../../static/img/files3.png",
          text: "资讯",
          pagePath: "/pages/NewsList",
          badge: "",
          type: "error"
        },
        {
          url: "../../static/img/fee8.png",
          text: "团费",
          pagePath: "/pages/FeeplanList",
          badge: "",
          type: "error"
        }
        // {
        //   url: "../../static/img/fee8.png",
        //   text: "缴费",
        //   pagePath: "/pages/fee",
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
    this.threads = await this.getThreads();
    this.goddess = await this.getCoverGoddess();
  },
  methods: {
    onClick() {},
    async onGoddessClick() {
      utils.gotoPage({
        url: "/pages/GoddessDetail",
        query: { id: this.goddess.id }
      });
    },
    async getNoticeBar() {
      const { data } = await Http.get("/settings?key=notice_bar");
      return data;
    },
    async getCoverGoddess() {
      const {
        data: [goddess]
      } = await Http.get("/goddess/cover");
      return goddess;
    },
    async getThreads() {
      const {
        data: { records: threads }
      } = await Http.get("/thread", {
        data: {
          pagesize: 3
        }
      });
      console.log({ threads });
      return threads;
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

<style>
.card-actions {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
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
.thread-item {
  font-size: 60%;
}
.image {
  width: 120upx;
  height: 120upx;
}
.content {
  padding: 8px;
  margin-top: 20upx;
}
</style>
