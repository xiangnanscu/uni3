<template>
  <div style="padding-bottom: 5em" v-if="query.stage_id">
    <div class="title" style="text-align: center; margin: 1em 0; font-size: 130%">
      江安县“青年人才驿站”入住手册
    </div>
    <fui-card
      v-for="(p, i) in hints"
      :key="i"
      shadow="0 2rpx 4rpx 0 white"
      :border="false"
    >
      <div>
        <div v-if="p.title" class="title">{{ p.title }}</div>
        <x-text v-if="p.hello" :text="p.hello"></x-text>
        <x-text :text="p.content" indent="2em"></x-text>
      </div>
    </fui-card>
  </div>
  <fui-button @click="utils.redirect('StageApply', query)" class="agree-btn"
    >我已阅读并同意</fui-button
  >
</template>

<script setup>
const query = useQuery();
const hints = [
  {
    title: "",
    content: `江安县“青年人才驿站”主要为来江就业创业、见习调研的青年人才提供免费最长不超过14天住宿服务。`,
  },
  {
    title: "一、入住条件",
    content: `1.大专及以上高校在读生。

2.35周岁以下，大专文凭及以上青年。

3.非江安县户籍且在江安县内没有住房，来江旅游、求职、创业青年人才。

4.每人每年只可申请免费入住一次驿站，超过一次享受5折优惠。`,
  },
  {
    title: "二、保障方式",
    content: `1.青年人才考试期间免费住宿安排

申请条件：在江安县参加考试的属非江安县户籍，凭考试报名表可以申请免费入住青年人才驿站不超过1晚2天。

2.青年人才求职期间免费安排住宿

申请条件：在江安县企业求职面试期间，能够提供江安县内企业、行政事业单位面试通知书或其他佐证，可以申请享受免费入住青年人才驿站不超过2晚3天优惠政策。

3.青年人才入职或创业免费安排住宿

申请条件：在江安县用人单位成功入职就业（以签订劳动合同或行政事业单位聘用合同日期为准），或自主创业（以《营业执照》《社会团体法人登记证书》或《民办非企业登记证书》登记日期为准）1个月以内，属非江安县户籍，可以申请免费入住青年人才驿站不超过14晚15天。

4.青年大学生旅游5折优惠安排住宿

申请条件：非江安县户籍在读大学生在江安旅游期间，可以凭学生证申请5折优惠入住青年人才驿站。`,
  },
  {
    title: "三、入住流程",
    content: `1.通过“江安青年”公众号，进入“青年人才驿站”项目。

2.在“青年人才驿站”项目，填写个人资料并上传相关佐证图片后，等待后台审核。

3.审核通过后，通过手机短信，将入住信息反馈到申请人。

4.申请成功后，申请人需在规定时间内凭入住信息到青年人才驿站办理入住登记，超时间办理或者不入住，将取消该申请人所申请服务，且不能再次申请。

5.申请人在提出申请后至入驿站前，因个人原因需要取消申请或者入住，需在驿站入住登记前，在“江安青年”上进行服务取消。

6.申请人需于申请服务期内退房。

注：最终解释权归江安县青年志愿者协会。江安青年驿站将于2023年11月10日向大众开放。`,
  },
];
</script>

<style>
page {
  background-color: #fff;
}
</style>
<style scoped>
.agree-btn {
  position: fixed;
  bottom: 0;
  left: 0;
  width: 100%;
}
.title {
  font-size: 120%;
  font-weight: bold;
}
</style>
