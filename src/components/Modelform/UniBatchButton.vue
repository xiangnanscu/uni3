<script setup>
import { findDups } from "@/lib/utils.mjs";
import { Model } from "@/lib/model/model.mjs";

const store = useStore();
const emit = defineEmits(["findDuplicates", "uploadRows", "successPost"]);
const props = defineProps({
  model: { type: [Object, Function], required: true },
  rows: { type: Array },
  uploadUrl: { type: String },
  downloadUrl: { type: String },
  uniqueKey: { type: [String, Array] },
  names: { type: Array }
});
const batchModel = !props.model.__is_model_class__
  ? Model.create_model({ ...props.model })
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
    const label = batchModel.name_to_label[name];
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
      const [cleanedRows, columns] = batchModel.validate_create_data(
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
          response: { data, status }
        } = error;
        Notice.error(typeof data == "object" ? JSON.stringify(data) : data);
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
      ["#", ...names.map((k) => batchModel.name_to_label[k])],
      ...data.map((row, index) => [index + 1, ...names.map((k) => row[k])])
    ]
  });
  Notice.success("下载成功，请留意浏览器下载目录");
};
</script>
<template>
  <uni-tag
    style="cursor: pointer"
    text="下载"
    @click="downloadRows"
    :disabled="store.loading"
  ></uni-tag>
</template>
