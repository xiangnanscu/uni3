<route lang="yaml"></route>
<script setup lang="jsx">
import { computed, ref, createVNode } from "vue";
import { ExclamationCircleOutlined, PlusOutlined } from "@ant-design/icons-vue";
import ModelBatchButton from "@/components/ModelBatchButton.vue";
import { Modal } from "ant-design-vue";
import "ant-design-vue/lib/modal/style/css";
import "ant-design-vue/lib/notification/style/css";

const props = defineProps({
  model: { type: [Object, Function], required: true },
  rows: { type: Array, default: () => [] },
});
const emit = defineEmits(["uploadRows", "deleteRow"]);
const adminModel = shallowRef(props.model);
const records = computed(() => props.rows);
const toAntdColumns = (names) => {
  return names.map((k) => ({
    title: adminModel.value.nameToLabel[k],
    dataIndex: k,
    field: adminModel.value.fields[k],
  }));
};

const columns = computed(() => [
  { title: "#", key: "#" },
  ...toAntdColumns(adminModel.value.admin?.listNames || adminModel.value.names),
  { title: "操作", key: "action" },
]);

const findDuplicates = (rows) => {
  console.log("findDuplicates", { rows });
};

const editId = ref(0);
const record = computed(
  () => records.value.find((e) => e.id === editId.value) || {}
);
const showUpdateForm = computed(() => editId.value !== 0);
const showCreateForm = ref(false);

const uniqueKey = computed(
  () => Object.values(adminModel.value.fields).find((f) => f.unique)?.name
);
const deleteRecord = (index) => {
  Modal.confirm({
    icon: createVNode(ExclamationCircleOutlined, { style: { color: "red" } }),
    content: "确认删除这条记录吗",
    okText: "删除",
    okType: "danger",
    onOk() {
      emit("deleteRow", index);
    },
    cancelText: "取消",
  });
};
const onSuccessCreate = (data) => {
  records.value.push(data);
  showCreateForm.value = false;
};
const onSuccessUpdate = (data) => {
  Object.assign(record.value, data);
  editId.value = 0;
};
const onClickEdit = async (record) => {
  editId.value = record.id;
};
const RenderImage = ({ value }) => {
  if (Array.isArray(value)) {
    return <img src={value[0].ossUrl} class="admin-list-avatar" />;
  } else {
    return <img src={value} class="admin-list-avatar" />;
  }
};
const tagColorArray = [
  "geekblue",
  "orange",
  "green",
  "cyan",
  "red",
  "blue",
  "purple",
];
</script>
<template>
  <a-row
    type="flex"
    justify="space-between"
  >
    <a-col>
      <a-modal
        v-model:visible="showCreateForm"
        title="创建"
        @cancel="showCreateForm = false"
        :maskClosable="false"
        closable
        width="800px"
      >
        <template #footer> </template>
        <model-form
          v-if="showCreateForm"
          :labelCol="6"
          @submit="onSuccessCreate"
          :model="adminModel"
          :values="adminModel.getDefaults()"
        ></model-form>
      </a-modal>
      <a-modal
        v-model:visible="showUpdateForm"
        title="编辑"
        @cancel="editId = 0"
        :maskClosable="false"
        closable
        width="800px"
      >
        <template #footer> </template>
        <model-form
          v-if="showUpdateForm"
          :labelCol="6"
          @submit="onSuccessUpdate"
          :model="adminModel"
          :values="record"
        ></model-form>
      </a-modal>

      <model-batch-button
        v-if="adminModel"
        @findDuplicates="findDuplicates"
        @uploadRows="emit('uploadRows', $event)"
        :uniqueKey="uniqueKey"
        :model="adminModel"
        :rows="props.rows"
      ></model-batch-button>
      <a-button @click.prevent="showCreateForm = true">
        <plus-outlined></plus-outlined>
        添加
      </a-button></a-col>
  </a-row>
  <a-table
    :dataSource="records"
    :columns="columns"
    :pagination="{ hideOnSinglePage: true, pageSize: 10000 }"
  >
    <template #bodyCell="{ column, index, record, text, value }">
      <template v-if="column?.key === '#'">{{ index + 1 }}</template>
      <template v-else-if="column?.field?.type === 'foreignkey'">
        {{
          typeof value == "object" ? value[column.field.referenceColumn] : value
        }}
      </template>
      <template v-else-if="column?.field?.type === 'aliossImage'">
        <RenderImage :value="value" />
      </template>
      <template v-else-if="column?.field?.type === 'array'">
        <div
          v-for="(e, i) in value"
          :key="i"
          style="margin-bottom: 2px"
        >
          <a-tag :color="tagColorArray[i % tagColorArray.length]">
            {{ `${i + 1}. ` + e }}
          </a-tag>
        </div>
      </template>
      <template v-else-if="column?.key === 'action'">
        <span>
          <a-button
            type="link"
            size="small"
            @click.prevent="onClickEdit(record)"
          >
            编辑
          </a-button>
          <a-button
            type="link"
            size="small"
            style="color: red"
            @click.prevent="deleteRecord(index)"
          >删除</a-button>
        </span>
      </template>
    </template>
  </a-table>
</template>

<style scoped>
.admin-list-avatar {
  max-width: 100px;
  max-height: 100px;
}
</style>
