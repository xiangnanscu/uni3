<template>
  <page-layout>
    <model-form-uni :model="testModel">

    </model-form-uni>
  </page-layout>
</template>
<script setup>
const testModel = Model.createModel({
  fieldNames: ['xm', 'sfzh'],
  fields: {
    xm: { label: "姓名" },
    sfzh: { label: "身份证号", type: 'sfzh' }
  }
})
</script>
<style scoped></style>