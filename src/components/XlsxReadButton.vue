<script setup>
import { read, utils } from "xlsx";
import { UploadOutlined } from "@ant-design/icons-vue";

const emit = defineEmits(["read"]);
const reading = ref(false);

const onAntdUpload = ({ file, fileList, event }) => {
  // https://antdv.com/components/upload/#FAQ
  // beforeUpload 返回false的时候file就是原始的file, 否则需要通过originFileObj获取
  var reader = new FileReader();
  reader.onload = function (event) {
    reading.value = true;
    var binary = "";
    var bytes = new Uint8Array(event.target.result);
    var length = bytes.byteLength;
    for (var i = 0; i < length; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    var workbook = read(binary, { type: "binary" });
    var n = workbook.SheetNames.length;
    if (n !== 1) {
      emit("read", {
        ok: false,
        message: `上传的电子文档只能包含1个工作表，当前${n}个`,
      });
      reading.value = false;
      return;
    }
    var sheet = workbook.Sheets[workbook.SheetNames[0]];
    // ** 这里转换的时候,有时候空白单元格不会转换为空字符串, 而是直接忽略, 不知是什么原因
    var rows = utils.sheet_to_json(sheet, { defval: "" });
    emit("read", { ok: true, rows });
    reading.value = false;
  };
  reader.readAsArrayBuffer(file);
};
</script>
<template>
  <a-upload
    list-type="picture"
    @change="onAntdUpload"
    :max-count="1"
    :showUploadList="false"
    :beforeUpload="() => false"
  >
    <a-button>
      <upload-outlined></upload-outlined>
      上传名单
    </a-button>
  </a-upload>
</template>
