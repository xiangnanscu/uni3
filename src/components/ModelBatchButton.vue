<script setup>
import { DownloadOutlined } from "@ant-design/icons-vue";
import XlsxReadButton from "@/components/XlsxReadButton.vue";
import { findDups } from "@/globals/Utils";
import { Model } from "@/lib/model.mjs";

const store = useStore();
const emit = defineEmits(["findDuplicates", "uploadRows", "successPost"]);
const props = defineProps({
  model: { type: [Object, Function], required: true },
  rows: { type: Array },
  uploadUrl: { type: String },
  downloadUrl: { type: String },
  uniqueKey: { type: [String, Array] },
  // tableName: { type: String },
  // primaryKey: { type: String },
  names: { type: Array },
  // fieldNames: { type: Array, default: () => [] },
  // fields: { type: Object, default: () => ({}) },
  // labelToName: { type: Object, default: () => ({}) },
  // nameToLabel: { type: Object, default: () => ({}) },
});
// console.log("props.model.__isModelClass__", props.model.__isModelClass__);
const batchModel = !props.model.__isModelClass__
  ? Model.createModel({ disableAutoPrimaryKey: true, ...props.model })
  : props.model;

const names = props.names || batchModel.names;
const ensureUnique = (rows) => {
  const key = props.uniqueKey;
  if (key) {
    const uniqueCallback =
      typeof key == "string"
        ? (row) => row[key]
        : (row) => key.map((k) => row[k]).join("|");
    const dups = findDups(rows, uniqueCallback);
    if (dups.length) {
      emit("findDuplicates", dups);
      throw new Error("上传名单存在重复项");
    }
  }
  return rows;
};
const prepareForDb = (row) => {
  const dbRow = {};
  for (const name of names) {
    const label = batchModel.nameToLabel[name];
    const value = row[label];
    if (value === undefined) {
      continue;
    }
    dbRow[name] = value;
  }
  return dbRow;
};
const onXlsxRead = async ({ ok, message, rows }) => {
  if (!ok) {
    Notice.error(message);
  } else {
    try {
      const [cleanedRows, columns] = batchModel.validateCreateData(
        ensureUnique(rows.map(prepareForDb))
      );
      emit("uploadRows", cleanedRows);
      if (!props.rows) {
        const response = await Http.post(props.uploadUrl, cleanedRows);
        emit("successPost", { response });
        Notice.success("操作成功");
      }
    } catch (error) {
      if (error.name == "AxiosError") {
        const {
          response: { data, status },
        } = error;
        Notice.error(typeof data == 'object' ? JSON.stringify(data) : data);
      } else if (error instanceof Model.ValidateBatchError) {
        Notice.error(
          `第${error.index + 1}行“${error.label}”错误：${error.message}`
        );
      } else {
        Notice.error(error.message);
      }
    }
  }
};
const downloadRows = async () => {
  const { data } = props.rows
    ? { data: props.rows }
    : await Http.get(props.downloadUrl);
  Xlsx.arrayToFile({
    filename: `${batchModel.label}-${new Date().getTime()}`,
    data: [
      ["#", ...names.map((k) => batchModel.nameToLabel[k])],
      ...data.map((row, index) => [index + 1, ...names.map((k) => row[k])]),
    ],
  });
  Notice.success("下载成功，请留意浏览器下载目录");
};
</script>
<template>
  <xlsx-read-button @read="onXlsxRead"></xlsx-read-button>
  <a-button
    @click="downloadRows"
    :disabled="store.loading"
  >
    <download-outlined></download-outlined>
    下载名单
  </a-button>
</template>
