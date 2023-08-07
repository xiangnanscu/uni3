<template>
  <page-layout>
    <!-- {{ JSON.stringify($store.state) }} -->
    <uni-list :border="false">
      <uni-list-chat
        :avatar-circle="true"
        :title="nickname"
        :avatar="avatar"
        :note="intro"
      >
        <navigator
          url="/views/AddMeFirend"
          open-type="navigate"
          hover-class="navigator-hover"
        >
          <image
            style="width: 24px; height: 24px"
            src="../../static/img/qrcode.png"
            mode="scaleToFill"
          />
        </navigator>
      </uni-list-chat>
    </uni-list>
    <uni-list>
      <uni-list-item
        title="我的帖子"
        link="navigateTo"
        to="/views/ThreadListMy"
        :show-extra-icon="true"
        :extra-icon="{ color: '#666', size: '32', type: 'chatboxes-filled' }"
      >
      </uni-list-item>
      <uni-list-item
        title="最近浏览"
        link="navigateTo"
        to="/views/ActionsListMy?current=0"
        :show-extra-icon="true"
        :extra-icon="{ color: '#666', size: '32', type: 'eye-filled' }"
      >
      </uni-list-item>
      <uni-list-item
        title="我的收藏"
        link="navigateTo"
        to="/views/ActionsListMy?current=1"
        :show-extra-icon="true"
        :extra-icon="{ color: '#666', size: '32', type: 'star-filled' }"
      >
      </uni-list-item>
      <uni-list-item
        title="我的点赞"
        link="navigateTo"
        to="/views/ActionsListMy?current=2"
        :show-extra-icon="true"
        :extra-icon="{ color: '#666', size: '32', type: 'hand-up-filled' }"
      >
      </uni-list-item>
      <uni-list-item
        title="志愿服务"
        link="navigateTo"
        to="/views/VolplanListMy?current=0"
        :show-extra-icon="true"
        :extra-icon="{ color: '#666', size: '32', type: 'heart-filled' }"
      >
      </uni-list-item>
      <uni-list-item
        title="个人信息"
        link="navigateTo"
        to="/views/ProfileForm"
        :show-extra-icon="true"
        :extra-icon="{ color: '#666', size: '32', type: 'person-filled' }"
      >
      </uni-list-item>
      <uni-list-item
        title="实名认证"
        link="navigateTo"
        to="/views/RealNameCert"
        :show-extra-icon="true"
        :extra-icon="{ color: '#666', size: '32', type: 'contact-filled' }"
      >
      </uni-list-item>
      <uni-list-item
        title="设置密码"
        link="navigateTo"
        to="/views/PasswordSet"
        :show-extra-icon="true"
        :extra-icon="{ color: '#666', size: '32', type: 'locked-filled' }"
      >
      </uni-list-item>
      <uni-list-item
        title="缴费记录"
        link="navigateTo"
        to="/views/OrdersList"
        :show-extra-icon="true"
        :extra-icon="{ color: '#666', size: '32', type: 'list' }"
      >
      </uni-list-item>
      <uni-list-item
        title="江安“新青年”"
        link="navigateTo"
        to="/views/GoddessAdd"
        :show-extra-icon="true"
        :extra-icon="{ color: '#666', size: '32', type: 'personadd-filled' }"
      >
      </uni-list-item>
      <uni-list-item
        title="关于"
        link="navigateTo"
        to="/views/About"
        :show-extra-icon="true"
        :extra-icon="{ color: '#666', size: '32', type: 'more-filled' }"
      >
      </uni-list-item>
      <uni-list-item
        v-if="user.id"
        title="退出登录"
        link="switchTab"
        :to="UNI_HOME_PAGE"
        :show-extra-icon="true"
        :extra-icon="{ color: 'red', size: '32', type: 'info' }"
        @click="logoutToHomePage($event, 1)"
      >
      </uni-list-item>
      <uni-list-item
        v-else
        title="登录"
        link="navigateTo"
        :to="UNI_LOGIN_PAGE"
        :show-extra-icon="true"
        :extra-icon="{ color: 'green', size: '32', type: 'info' }"
      >
      </uni-list-item>
    </uni-list>
    <!-- <uni-list>
        <uni-list-item title="列表文字" note="列表描述信息"></uni-list-item>
        <uni-list-item title="列表禁用状态"></uni-list-item>
        <uni-list-item title="列表右侧显示角标" :show-badge="true" badge-text="12"></uni-list-item>
        <uni-list-item title="列表右侧显示 switch" :show-switch="true" @switchChange="switchChange"></uni-list-item>
        <uni-list-item title="列表左侧带略缩图" note="列表描述信息"
          thumb="https://vkceyugu.cdn.bspapp.com/VKCEYUGU-dc-site/460d46d0-4fcc-11eb-8ff1-d5dcf8779628.png"
          thumb-size="lg" rightText="右侧文字"></uni-list-item>
        <uni-list-item :show-extra-icon="true" :extra-icon="extraIcon1" title="列表左侧带扩展图标"></uni-list-item>
      </uni-list> -->
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      UNI_LOGIN_PAGE: process.env.UNI_LOGIN_PAGE,
      UNI_HOME_PAGE: process.env.UNI_HOME_PAGE,
      title: "Hello",
      profile: null
    };
  },
  onLoad(options) {
    console.log("my onLoad", options);
  },
  async onShow() {
    if (this.isLogin) {
      const { data: profile } = await Http.get("/usr/profile/my");
      this.profile = profile;
    }
  },
  computed: {
    isLogin() {
      return this.user.id;
    },
    avatar() {
      return this.isLogin ? this.user.avatar : "";
    },
    nickname() {
      return this.isLogin ? this.user.nickname : "游客";
    },
    intro() {
      return this.isLogin ? this.profile?.intro : "";
    }
  },
  methods: {
    logoutToHomePage(event) {
      const { logout } = useSession();
      logout();
    },
    toCertPage(event) {
      console.log("toCertPage:", event);
    }
  }
};
</script>

<style>
.content {
  padding: 50upx;
}
</style>
