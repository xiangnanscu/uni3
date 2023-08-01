<template>
  <page-layout>
    <h1 style="text-align: center">团建E家</h1>
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
  </page-layout>
</template>

<script setup>
const mainKist = [
  {
    url: "../static/img/party-class.png",
    text: "三会两制一课",
    badge: "",
    pagePath: "/views/VolplanList",
    type: "error"
  },
  {
    url: "../static/img/fee8.png",
    text: "交团费",
    pagePath: "/views/FeeplanList",
    badge: "",
    type: "error"
  },
  {
    url: "../static/img/work-open.png",
    text: "团务公开",
    pagePath: "/views/NewsList",
    badge: "",
    type: "error"
  },
  {
    url: "../static/img/manual.png",
    text: "团务手册",
    pagePath: "/views/ThreadListAll",
    badge: "",
    type: "error"
  },
  {
    url: "../static/img/law.png",
    text: "团章",
    badge: "",
    pagePath: "/views/VolplanList",
    type: "error"
  }
];
</script>

<style scoped>
.banner-image {
  width: 120upx;
  height: 120upx;
}
</style>
