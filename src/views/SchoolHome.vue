<template>
  <page-layout>
    <x-title> 智慧校园 </x-title>
    <uni-grid :column="3" :show-border="false" :square="false" @change="change">
      <template v-for="(item, index) in permissionMenu" :key="index">
        <uni-grid-item :index="index">
          <view class="grid-item-box" style="text-align: center; margin-top: 2em">
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
      </template>
    </uni-grid>
  </page-layout>
</template>

<script setup>
const user = useUser();
const mainKist = [
  {
    url: "../static/img/in-out.png",
    text: "校园进出",
    pagePath: "/views/Todo",
    badge: "",
    type: "error",
  },
  {
    url: "../static/img/leave.png",
    text: "请销假",
    pagePath: "/views/Todo",
    badge: "",
    type: "error",
  },
  {
    url: "../static/img/homework.png",
    text: "家庭作业",
    pagePath: "/views/Todo",
    badge: "",
    type: "error",
  },
  {
    url: "../static/img/parent-child.png",
    text: "亲子登记",
    badge: "",
    pagePath: "/views/SchoolParentChildRegedit",
    type: "error",
  },
  {
    url: "../static/img/parent-child.png",
    text: "登记情况",
    badge: "",
    pagePath: "/views/SchoolStudentStat",
    type: "error",
    permission: 1,
  },
];
const permissionMenu = computed(() =>
  mainKist.filter((e) => !e.permission || e.permission >= user.permission),
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
