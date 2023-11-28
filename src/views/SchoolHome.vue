<template>
  <page-layout>
    <x-title> 智慧校园 </x-title>
    <uni-grid
      v-if="ready"
      :column="3"
      :show-border="false"
      :square="false"
      @change="change"
    >
      <template v-for="(item, index) in permissionMenu" :key="index">
        <uni-grid-item :index="index">
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
      </template>
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
    url: "../static/img/parent-child.png",
    text: "亲子登记",
    badge: "",
    pagePath: "/views/SchoolRegeditParentChild",
    type: "error",
  },
  {
    url: "../static/img/in-out.png",
    text: "校园进出",
    pagePath: "/views/SchoolStudentAccessLog",
    badge: "",
    type: "error",
  },
  {
    url: "../static/img/leave.png",
    text: "请销假",
    pagePath: "/views/SchoolLeave",
    badge: "",
    type: "error",
  },
  {
    url: "../static/img/notice.png",
    text: "通知事项",
    badge: "",
    pagePath: "/views/SchoolNotice",
    type: "error",
  },

  {
    url: "../static/img/score.png",
    text: "成绩管理",
    pagePath: "/views/SchoolStudentScore",
    badge: "",
    type: "error",
  },
  {
    url: "../static/img/homework.png",
    text: "家庭作业",
    pagePath: "/views/SchoolHomework",
    badge: "",
    type: "error",
  },
  {
    url: "../static/img/tableware.png",
    text: "食堂餐饮",
    badge: "",
    pagePath: "/views/Todo",
    type: "error",
  },
  {
    url: "../static/img/stat.png",
    text: "学生管理",
    badge: "",
    pagePath: "/views/SchoolStudentStat",
    type: "error",
    roles: ["sys_admin", "principal", "class_director"],
  },
  {
    url: "../static/img/adminor.png",
    text: "校方管理",
    badge: "",
    pagePath: "/views/SchoolAdmin",
    type: "error",
    roles: ["sys_admin", "principal", "class_director"],
  },
  // {
  //   url: "../static/img/stat.png",
  //   text: "管理员申请",
  //   badge: "",
  //   pagePath: "/views/Uform",
  //   type: "error",
  //   permission: 1,
  // },
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
