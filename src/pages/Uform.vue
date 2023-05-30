<template>
  <page-layout>
    <modelform-uni :model="testModel" @sendData="submit"> </modelform-uni>
  </page-layout>
</template>

<script setup>
const submit = (data) => {
  console.log("submit", data);
};
onMounted(async () => {
  console.log("Uform onMounted");
  const { header } = await uni.request({ url: "/h1" });
  console.log({ header });
});
const testModel = Model.createModel({
  fields: {
    tx: {
      label: "头像",
      size: "1M",
      type: "aliossImage"
    },
    xm: {
      label: "姓名",
      disabled: false
    },
    sfzh: { label: "身份证号", type: "sfzh" },
    dwmc: {
      label: "单位名称",
      choices: ["阳春镇人民政府", "江安镇便民中心"],
      autocomplete: true
    },
    ah: {
      label: "爱好",
      type: "array",
      max: 3,
      min: 1,
      choices: ["阅读", "吃", "游泳", "其他"]
    },
    grjl: {
      label: "个人简历",
      type: "table",
      model: Model.createModel({
        fields: {
          // ksny: { label: "开始年月", type: "yearMonth" },
          // jsny: { label: "结束年月", type: "yearMonth" },
          xq: { label: "详情", maxlength: 3 }
        }
      })
    },
    family: {
      label: "家人姓名",
      maxlength: 2,
      // arrayType: "boolean"
      type: "array"
    },
    xz: {
      label: "写真",
      required: false,
      type: "aliossImageList"
    },

    shsp: {
      label: "生活视频",
      required: false,
      size: "50M",
      mediaType: "video",
      type: "alioss"
    },
    bg: {
      label: "表格",
      required: false,
      size: "350M",
      type: "alioss"
    },

    age: { label: "年龄", type: "integer" },
    weight: { label: "体重", type: "float" },
    bj: {
      label: "班级",
      choices: ["一班", "二班"],
      autocomplete: true
    },
    xb: {
      label: "性别",
      tag: "radio",
      choices: ["男", "女"]
    },
    sf: {
      label: "是否",
      tag: "radio",
      type: "boolean"
    },
    csny: {
      label: "出生年月",
      type: "date"
    },
    dysj: {
      label: "打印时间",
      type: "datetime"
    },
    rxny: {
      label: "入学年月",
      type: "yearMonth"
    },
    bynf: {
      label: "毕业年份",
      type: "year"
    },
    zzmm: {
      label: "政治面貌",
      choices: ["中共党员", "共青团员", "其他"]
    },
    score: {
      label: "分数",
      type: "integer",
      min: 60,
      max: 90,
      tag: "slider",
      default: 60
    },
    password: {
      label: "密码",
      type2: "password"
    }
  }
});
</script>
