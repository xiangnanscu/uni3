<template>
  <page-layout>
    <x-title> 团建E家 </x-title>
    <uni-grid
      v-if="ready"
      :column="3"
      :show-border="false"
      :square="false"
      @change="change"
    >
      <uni-grid-item v-for="(item, index) in permissionMenu" :index="index" :key="index">
        <view class="grid-item-box" style="text-align: center; margin-top: 2em">
          <x-navigator
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
          </x-navigator>
        </view>
      </uni-grid-item>
    </uni-grid>
  </page-layout>
</template>

<script setup>
const user = useUser();
const ready = ref(false);
const roles = ref();
onLoad(async () => {
  roles.value = await helpers.getPassedRoles();
  ready.value = true;
});
const mainKist = [
  {
    url: "../static/img/party-class.png",
    text: "三会两制一课",
    badge: "",
    pagePath: "/views/ShyListkMy",
    type: "error",
  },
  {
    url: "../static/img/fee8.png",
    text: "交团费",
    pagePath: "/views/FeeplanList",
    badge: "",
    type: "error",
  },
  {
    url: "../static/img/work-open.png",
    text: "团务公开",
    pagePath: "/views/NewsList?type=团务公开",
    badge: "",
    type: "error",
  },
  {
    url: "../static/img/manual.png",
    text: "团务手册",
    pagePath: "/views/NewsList?type=团务手册",
    badge: "",
    type: "error",
  },
  {
    url: "../static/img/law.png",
    text: "团章",
    badge: "",
    pagePath: "/views/NewsList?type=团章",
    type: "error",
  },
  {
    url: "../static/img/zchb.png",
    text: "政策汇编",
    pagePath: "/views/NewsList?type=政策汇编",
    badge: "",
    type: "error",
  },
  {
    url: "../static/img/adminor.png",
    text: "管理员",
    badge: "",
    pagePath: "/views/BranchAdmin",
    type: "error",
    roles: ["sys_admin", "branch_admin"],
  },
];
const permissionMenu = computed(() =>
  mainKist.filter((menu) => !menu.roles || menu.roles.some((role) => roles.value[role])),
);
</script>

<style scoped>
.logo-text {
  font-size: 90%;
}
.banner-image {
  width: 80upx;
  height: 80upx;
}
</style>
