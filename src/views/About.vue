<template>
  <page-layout> {{ version }}11 </page-layout>
</template>

<script>
import { version } from "../../package.json";

export default {
  data() {
    return {
      version
    };
  },
  onLoad() {
    // #ifdef MP-WEIXIN
    this.updateApp();
    // #endif
  },
  methods: {
    updateApp() {
      const updateManager = uni.getUpdateManager();

      updateManager.onCheckForUpdate(function (res) {
        // 请求完新版本信息的回调
        console.log(res, res.hasUpdate);
      });

      updateManager.onUpdateReady(function (res) {
        uni.showModal({
          title: "更新提示",
          content: "新版本已经准备好，是否重启应用？",
          success(res) {
            if (res.confirm) {
              // 新的版本已经下载好，调用 applyUpdate 应用新版本并重启
              updateManager.applyUpdate();
            }
          }
        });
      });

      updateManager.onUpdateFailed(function (res) {
        // 新的版本下载失败
        console.log("新的版本下载失败", res);
      });
    },
    async fetchData(query) {
      const { data: ad } = await Http.get(`/ad/detail/${query.id}`);
      this.record = ad;
    }
  }
};
</script>

<style scoped></style>
