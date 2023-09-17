<script setup lang="ts">
import { onLaunch, onShow, onHide } from "@dcloudio/uni-app";
onLaunch(() => {
  console.log("App Launch");
});
onShow(async () => {
  const res = await useGet("/test");
  console.log(res.filter((e) => e));
  console.log("App Show");
});
onHide(() => {
  console.log("App Hide");
});
</script>
<style>
/* uni.showModal 格式覆盖,只对H5有效 */
:deep(.uni-modal__hd) {
  color: #333;
}
:deep(.uni-modal__bd) {
  color: #333;
}
page {
  /* 行为相关颜色 */
  --fui-color-primary: #465cff;
  --fui-color-success: #09be4f;
  --fui-color-warning: #ffb703;
  --fui-color-danger: #ff2b2b;
  --fui-color-purple: #6831ff;

  /* 文字基本颜色、其他辅助色 */
  /* 用于重量级文字信息、标题 */
  --fui-color-title: #181818;
  /* 用于普通级段落信息、引导词 */
  --fui-color-section: #333333;
  /* 用于次要标题内容 */
  --fui-color-subtitle: #7f7f7f;
  /* 用于底部标签、描述、次要文字信息 */
  --fui-color-label: #b2b2b2;
  /* 用于辅助、次要信息、禁用文字等。如：待输入状态描述文字，已点击按钮文字 */
  --fui-color-minor: #cccccc;
  --fui-color-white: #ffffff;
  /* 链接颜色 */
  --fui-color-link: #465cff;

  /* 背景颜色 */
  --fui-bg-color: #ffffff;
  /* 页面背景底色 */
  --fui-bg-color-grey: #f1f4fa;
  /* 内容模块底色 */
  --fui-bg-color-content: #f8f8f8;
  --fui-bg-color-red: rgba(255, 43, 43, 0.05);
  --fui-bg-color-yellow: rgba(255, 183, 3, 0.1);
  --fui-bg-color-purple: rgba(104, 49, 255, 0.05);
  --fui-bg-color-green: rgba(9, 190, 79, 0.05);
  /* 点击背景色 */
  --fui-bg-color-hover: rgba(0, 0, 0, 0.2);
  /* 遮罩颜色 */
  --fui-bg-color-mask: rgba(0, 0, 0, 0.6);

  /* 边框颜色 */
  --fui-color-border: #eeeeee;

  /* 阴影颜色 */
  --fui-color-shadow: rgba(2, 4, 38, 0.05);

  /*禁用态的透明度 */
  --fui-opacity-disabled: 0.5;

  /* 图标尺寸 */
  --fui-img-size-sm: 48rpx;
  --fui-img-size-base: 56rpx;
  --fui-img-size-middle: 64rpx;
  --fui-img-size-lg: 96rpx;

  /* 图片尺寸 */
  --fui-img-sm: 60rpx;
  --fui-img-base: 120rpx;
  --fui-img-lg: 240rpx;

  /* Border Radius */
  --fui-border-radius-sm: 16rpx;
  --fui-border-radius-base: 24rpx;
  --fui-border-radius-lg: 48rpx;
  --fui-border-radius-circle: 50%;

  /* 水平间距 */
  --fui-spacing-row-sm: 16rpx;
  --fui-spacing-row-base: 24rpx;
  --fui-spacing-row-lg: 32rpx;

  /* 垂直间距 */
  --fui-spacing-col-sm: 8rpx;
  --fui-spacing-col-base: 16rpx;
  --fui-spacing-col-lg: 24rpx;
}
</style>
