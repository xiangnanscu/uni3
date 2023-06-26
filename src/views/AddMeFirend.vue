<template>
  <page-layout>
    <div>
      <uni-list :border="false">
        <uni-list-chat
          :avatar-circle="true"
          :title="user.nickname"
          :avatar="user.avatar"
          :note="user.intro"
        ></uni-list-chat>
        <div style="text-align: center; margin-top: 3em">
          <img v-if="assessQRCode" :src="assessQRCode" />
          <div>扫码加我为好友</div>
        </div>
      </uni-list>
    </div>
  </page-layout>
</template>

<script setup>
import QRCode from "qrcode";

const user = useUser();
const assessQRCode = ref("");
onLoad(async () => {
  assessQRCode.value = await QRCode.toDataURL(
    `https://jaqn.jahykj.cn/friends/apply/${user.id}`
  );
});
</script>

<style scoped></style>
