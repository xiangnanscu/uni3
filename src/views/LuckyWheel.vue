<template>
  <div v-if="lottery" class="content">
    <div class="t-bg" :style="{ 'background-image': `url(${urls.page_bg})` }">
      <image class="t-wan" :src="urls.lucky_wheel_name"></image>
      <image class="t-wan-lp" :src="urls.lucky_text"></image>
      <div
        class="t-choujiang t-flex-row"
        :style="{ 'background-image': `url(${urls.wheel_bg})` }"
      >
        <div
          :animation="rotate"
          class="t-zp"
          :style="{ 'background-image': `url(${urls.wheel_pic})` }"
        ></div>
        <image @click="start" class="t-start" :src="urls.start"></image>
      </div>
    </div>
    <!-- 规则部分 -->
    <div class="t-bottom">
      <div class="t-luck-wrapper">
        <div
          class="t-jh t-flex-row"
          :style="{ 'background-image': `url(${urls.chance_text_bg})` }"
        >
          您还有{{ luckDrawTimes }}次机会
        </div>
        <div class="t-line"></div>
        <div class="t-r-title t-flex-row">抽奖规则</div>
        <div class="t-rule">
          <text>1.无门槛参与：凡是授权获取电话号码的小程序用户均可参与抽奖；</text>
          <text
            >2.每个用户每天默认有一次抽奖资格，用户可以通过以下方式复活继续参与抽奖：
            （1）通过观看品牌视频5秒钟每天获取一次复活资格
            （2）通过一键分享朋友圈（且有人点击）获取复活资格，每分享一个新的朋友，获取一次复活资格，复活次数上不封顶；</text
          >
          <text
            >3.中奖奖品以现金的形式下发用户微信零钱，到账时间不超过24小时,具体到账时间以微信支付通知为准（因微信官方要求，微信实名认证用户方可收到奖金）；</text
          >
          <text>4.中奖记录在个人中心-我的红包中查看。</text>
        </div>
      </div>
    </div>
    <!-- 抽奖结束弹窗 -->
    <kevy-mask :show="isShowAwd" @click="toConfirmAwd">
      <div class="t-full t-flex-row">
        <div class="t-tk-modal">
          <div
            class="t-tk-bg t-bg-full"
            :style="{ 'background-image': `url(${urls.award_bg})` }"
          >
            <div v-if="drawIdx != null && !noRewards" class="t-tk-zj t-flex-col-s">
              <image class="t-tk-zj-tip" :src="urls.congrats_text"></image>
              <div class="t-tk-zj-desc t-flex-col">
                <image
                  class="t-zj-jp"
                  :src="'../static/luck/' + drawIdx + '.png'"
                  mode="widthFix"
                ></image>
                <div class="t-zj-jp-desc">{{ items[drawIdx].name }}</div>
              </div>
            </div>
            <div v-if="drawIdx != null && noRewards" class="t-xxcy t-flex-col-s">
              <image :src="urls.thanks_text"></image>
              <div class="t-xxcy-ts t-flex-row">很遗憾，没有中奖</div>
            </div>
          </div>
          <div
            @click="toConfirmAwd"
            class="t-tk-btn t-bg-full"
            :style="{ 'background-image': `url(${urls.confirm_bg})` }"
          >
            {{ !noRewards ? "领取" : "确定" }}
          </div>
        </div>
      </div>
    </kevy-mask>
  </div>
</template>

<script>
var animation = uni.createAnimation({
  duration: 4000,
  timingFunction: "ease-out",
});

export default {
  data() {
    return {
      rotate: 0, //度数-抽奖动画
      turning: false, //转盘是否正在转
      luckDrawTimes: 5, //抽奖机会，5代表可以抽5次
      isShowAwd: false, //是否显示奖品弹框，抽奖后提示，要么中奖奖品，要么谢谢参与
      drawIdx: null, //抽到的奖品下标，用于指定中奖奖品并旋转转盘到对应奖品处。例如共5个奖品，下标3代表第4个奖品，下标从0开始
      lottery: null,
      items: [],
      resetCall: null,
    };
  },
  computed: {
    urls() {
      return {
        wheel_pic:
          "https://lzwlkj.oss-cn-shenzhen.aliyuncs.com/jahy/vc-upload-1700788995748-5.png",
        page_bg:
          "https://lzwlkj.oss-cn-shenzhen.aliyuncs.com/jahy/vc-upload-1700748996560-5.png",
        lucky_wheel_name:
          "https://lzwlkj.oss-cn-shenzhen.aliyuncs.com/jahy/vc-upload-1700748996560-8.png",
        lucky_text:
          "https://lzwlkj.oss-cn-shenzhen.aliyuncs.com/jahy/vc-upload-1700754130137-3.png",
        wheel_bg:
          "https://lzwlkj.oss-cn-shenzhen.aliyuncs.com/jahy/vc-upload-1700748996560-14.png",
        start:
          "https://lzwlkj.oss-cn-shenzhen.aliyuncs.com/jahy/vc-upload-1700754130137-5.png",
        chance_text_bg:
          "https://lzwlkj.oss-cn-shenzhen.aliyuncs.com/jahy/vc-upload-1700748996560-16.png",
        award_bg:
          "https://lzwlkj.oss-cn-shenzhen.aliyuncs.com/jahy/vc-upload-1700748996560-7.png",
        congrats_text:
          "https://lzwlkj.oss-cn-shenzhen.aliyuncs.com/jahy/vc-upload-1700754130137-7.png",
        thanks_text:
          "https://lzwlkj.oss-cn-shenzhen.aliyuncs.com/jahy/vc-upload-1700754130137-9.png",
        confirm_bg:
          "https://lzwlkj.oss-cn-shenzhen.aliyuncs.com/jahy/vc-upload-1700748996560-18.png",
        ...this.lottery,
      };
    },
    unitRotate() {
      return 360 / this.items.length;
    },
    noRewards() {
      if (this.drawIdx === null) {
        return true;
      }
      return !this.items[this.drawIdx]?.name;
    },
  },
  async onLoad(query) {
    await helpers.autoLogin();
    // const init = await usePost(`/lucky/init`);
    const lottery = await useGet(`/lottery/detail/${query.id}`);
    this.lottery = lottery;
    this.items = lottery.prize_list;
    // this.luckDrawTimes = init.luckDrawTimes;
  },
  methods: {
    /**
     * 抽奖按钮点击
     */
    start() {
      const self = this;
      const luckDrawTimes = self.luckDrawTimes;
      if (luckDrawTimes < 1) {
        uni.showToast({
          title: "抽奖机会已用完",
          icon: "none",
        });
        return;
      }
      if (!self.turning) {
        self.turning = true;
        self.$nextTick(async () => {
          //这里去请求服务器，生成中奖信息，其中awardIdx为中奖
          // uni.request({
          // })
          //以下为模拟请求返回数据，awardIdx从0开始，0代表谢谢参与，其他代表剩余的奖品，这里随机一个数（0-4之间）
          const res = {
            awardIdx: 2, // Math.floor(Math.random() * 5),
          };
          const { index: awardIdx } = await usePost(`/lucky/index`);
          //计算旋转角度
          const rdm = self.computeRotateAward(awardIdx);
          animation.rotate(rdm).step();
          self.rotate = animation.export();
          self.luckDrawTimes = self.luckDrawTimes <= 0 ? 0 : self.luckDrawTimes - 1;
          setTimeout(() => {
            const animation1 = uni.createAnimation({
              duration: 100,
              timingFunction: "linear",
            });
            animation1.rotate(0).step();
            self.drawIdx = awardIdx;
            self.isShowAwd = true;
            self.resetCall = () => {
              self.rotate = animation1.export();
              self.turning = false;
            };
          }, 4350);
        });
      }
    },
    /**
     * 根据后台返回中奖奖品索引计算旋转角度
     * @param {*} idx 中奖奖品下标，从0开始
     * @param {*} type 1-计算角度 2-计算奖品
     */
    computeRotateAward(idx) {
      //这里6代表6圈，你可以设置为你想要的
      return 6 * 360 + idx * this.unitRotate;
    },

    /**
     * 确认奖品按钮点击事件
     */
    toConfirmAwd() {
      //这里中奖信息关闭弹框
      this.isShowAwd = false;
      this.resetCall();
    },
  },
};
</script>

<style scoped>
.content {
  width: 100%;
  box-sizing: border-box;
}

.t-bg {
  width: 100%;
  box-sizing: border-box;
  background-size: 100% 100%;
  background-repeat: no-repeat;
  position: relative;
  overflow-x: hidden;
  height: 1200rpx;
  padding-top: 345rpx;
  /* margin-top: 40rpx; */
}

.t-overlay {
  width: 100vw;
  height: 100vh;
  position: fixed;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 9999;
  background: rgba(0, 0, 0, 0.3);
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: row;
  transition: all 0.5s;
}

.t-wan {
  position: absolute;
  width: 100%;
  height: 283rpx;
  top: 12rpx;
  left: 0;
  z-index: 1;
}

.t-wan-lp {
  position: absolute;
  width: 370rpx;
  height: 130rpx;
  top: 223rpx;
  z-index: 0;
  left: calc(50% - 185rpx);
}

.t-choujiang {
  width: 630rpx;
  height: 630rpx;
  background-size: 100% 100%;
  background-repeat: no-repeat;
  margin: 0rpx auto;
  position: relative;
}

.t-zp {
  width: 577rpx;
  height: 577rpx;
  background-size: 100% 100%;
  background-repeat: no-repeat;
}

.t-start {
  width: 146rpx;
  height: 171rpx;
  position: absolute;
  z-index: 1;
}

.t-jh {
  width: 456rpx;
  height: 120rpx;
  margin: 0 auto;
  background-size: 100% 100%;
  background-repeat: no-repeat;
  font-size: 40rpx;
  color: #980100;
}

.t-fuhuo-text {
  font-size: 30rpx;
  color: #980100;
  width: 100%;
  height: 42rpx;
  margin-top: 14rpx;
}

.t-fh-fs {
  width: 580rpx;
  height: 100rpx;
  margin: 20rpx auto 0rpx;
}

.t-fh-fs div {
  width: 250rpx;
  height: 100rpx;
  background-image: linear-gradient(180deg, #df0236 0%, #dd0227 100%);
  border-radius: 10rpx;
  font-size: 30rpx;
  color: #ffffff;
}

.t-share {
  width: 250rpx;
  height: 100rpx;
  background-image: linear-gradient(180deg, #df0236 0%, #dd0227 100%);
  border-radius: 10rpx;
  font-size: 30rpx;
  color: #ffffff;
}

.t-bottom {
  position: relative;
  width: 100%;
  box-sizing: border-box;
  opacity: 0.99;
  background: #fdc469;
}

.t-luck-wrapper {
  position: relative;
  box-sizing: border-box;
  top: -219rpx;
}

.t-line {
  width: 580rpx;
  height: 1rpx;
  margin: 50rpx auto 0rpx;
  background: #980100;
}

.t-r-title {
  font-size: 28rpx;
  color: #980100;
  height: 40rpx;
  width: 100%;
  margin: 30rpx auto 0rpx;
  width: 585rpx;
}

.t-rule {
  margin: 10rpx auto 0rpx;
  width: 585rpx;
}

.t-rule text {
  font-size: 28rpx;
  color: #980100;
  text-align: justify;
  display: block;
}

.t-wrapper {
  width: 100%;
  height: 100%;
  position: relative;
  top: 0rpx;
}

.t-video-con {
  width: 100%;
  height: 422rpx;
  background: #fff;
  position: relative;
}

.t-video {
  width: 100%;
  height: 100%;
}

.t-close {
  position: absolute;
  top: 0rpx;
  right: 0rpx;
  width: 34rpx;
  height: 34rpx;
  padding: 30rpx;
  z-index: 9999;
}

.t-nocice {
  position: fixed;
  left: 0rpx;
  top: 0rpx;
  z-index: 999;
  width: 100%;
  height: 40rpx !important;
  box-sizing: border-box;
  font-size: 30rpx;
}

.t-tk-modal {
  width: 632rpx;
  /* height: 588rpx; */
  position: relative;
  box-sizing: border-box;
}

.t-tk-bg {
  width: 100%;
  /* height: 528rpx; */
  background-size: 100% 100%;
  padding-bottom: 5rem;
}

.t-tk-btn {
  width: 336rpx;
  height: 120rpx;
  position: absolute;
  bottom: -50rpx;
  left: calc(50% - 168rpx);
  font-size: 40rpx;
  color: #980100;
  line-height: 120rpx;
  text-align: center;
  background-size: 100% 100%;
}

.t-flex-row {
  display: flex;
  flex-direction: row;
  justify-content: center;
  align-items: center;
}

.t-flex-row-sa {
  display: flex;
  flex-direction: row;
  justify-content: space-around;
  align-items: center;
}

.t-flex-row-sb {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
}

.t-flex-row-s {
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  align-items: center;
}

.t-flex-row-s-s {
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  align-items: flex-start;
}

.t-flex-row-s-e {
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  align-items: flex-end;
}

.t-flex-row-e {
  display: flex;
  flex-direction: row;
  justify-content: flex-end;
  align-items: center;
  line-height: 60rpx;
}

.t-flex-col {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.t-flex-col-sa {
  display: flex;
  flex-direction: column;
  justify-content: space-around;
  align-items: center;
}

.t-flex-col-sb {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
}

.t-flex-col-s {
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: center;
}

.t-flex-col-s-s {
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: flex-start;
}

.t-flex-col-s-e {
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: flex-end;
}

.t-flex-col-e {
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  align-items: center;
}

.t-xxcy image {
  width: 400rpx;
  height: 148rpx;
  margin-top: 139rpx;
}

.t-xxcy-ts {
  width: 510rpx;
  height: 100rpx;
  background: #fef2cd;
  border-radius: 20rpx;
  font-size: 30rpx;
  color: #d93637;
  margin-top: 43rpx;
}

.t-tk-zj {
}

.t-tk-zj-tip {
  width: 347rpx;
  height: 106rpx;
  margin-top: 44rpx;
}

.t-tk-zj-desc {
  width: 474rpx;
  /* height: 281rpx; */
  background: #fef2cd;
  border-radius: 20rpx;
  margin-top: 2rpx;
  padding-bottom: 0.5rem;
}

.t-zj-jp {
  width: 264rpx;
  /* height: 157rpx; */
}

.t-zj-jp-desc {
  font-size: 28rpx;
  font-weight: bold;
  color: #d93637;
  text-align: center;
  width: 420rpx;
}

.t-click-class {
  opacity: 0.7;
}
</style>
