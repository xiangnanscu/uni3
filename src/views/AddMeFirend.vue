<template>
  <page-layout>
    <div style="text-align: center; margin-top: 4em">
      <image
        :src="user.avatar"
        mode="scaleToFill"
        style="width: 50px; height: 50px; border-radius: 25px"
      />
      <div style="margin-bottom: 2em">{{ user.nickname }}</div>
      <div
        style="text-align: center; width: 200px; height: 200px; margin: auto"
      >
        <canvas
          id="qrcode"
          canvas-id="qrcode"
          style="width: 200px; height: 200px"
        ></canvas>
      </div>
      <div style="margin-top: 2em; color: #666">扫码加我为好友</div>
    </div>
  </page-layout>
</template>

<script setup>
import UQRCode from "uqrcodejs";

const user = useUser();
const assessQRCode = ref("");
onReady(async () => {
  // assessQRCode.value = await QRCode.toDataURL(
  //   `https://jaqn.jahykj.cn/friends/apply/${user.id}`
  // );
  var qr = new UQRCode();
  // 设置二维码内容
  qr.data = `https://jaqn.jahykj.cn/test/${user.id}`;
  // 设置二维码大小，必须与canvas设置的宽高一致
  qr.size = 200;
  // 调用制作二维码方法
  qr.make();
  // 获取canvas上下文
  var canvasContext = uni.createCanvasContext("qrcode", getCurrentInstance()); // 如果是组件，this必须传入
  // 设置uQRCode实例的canvas上下文
  qr.canvasContext = canvasContext;
  // 调用绘制方法将二维码图案绘制到canvas上
  qr.drawCanvas();
});
</script>

<style scoped></style>
