<route lang="yaml"></route>
<script setup lang="jsx">
import { computed, ref, createVNode } from "vue";

const emit = defineEmits(["update:modelValue", "update:error"]);
const uniForm = inject("uniForm", null);
const uniFormItem = inject("uniFormItem", null);

const props = defineProps({
  field: { type: Object, required: true },
  modelValue: { required: true },
  error: {}
});

const adminModel = props.field.model;

const tableColumns = computed(() =>
  (adminModel.admin?.listNames || adminModel.names).map((name, index) => ({
    index,
    name,
    label: adminModel.nameToLabel[name],
    field: adminModel.fields[name]
  }))
);

const findDuplicates = (rows) => {
  console.log("findDuplicates", { rows });
};

const currentRow = ref(null);
const createFormRef = ref(null);
const updateFormRef = ref(null);
const showCreateForm = ref(false);
const showUpdateForm = ref(false);

const uniqueKey = computed(
  () => Object.values(adminModel.fields).find((f) => f.unique)?.name
);
const reportValue = (newRows) => {
  emit("update:modelValue", newRows);
};
const deleteRecord = (splitIndex) => {
  const newRows = [
    ...props.modelValue.slice(0, splitIndex),
    ...props.modelValue.slice(splitIndex + 1)
  ];
  reportValue(newRows);
};
const openCreateForm = () => {
  createFormRef.value.open();
  showCreateForm.value = true;
};
const openUpdateForm = () => {
  updateFormRef.value.open();
  showUpdateForm.value = true;
};
const onSuccessCreate = (data) => {
  reportValue([...props.modelValue, data]);
  createFormRef.value.close();
  showCreateForm.value = false;
};
const onSuccessUpdate = (data) => {
  const splitIndex = props.modelValue.findIndex((e) => e === currentRow.value);
  const newRows = [
    ...props.modelValue.slice(0, splitIndex),
    data,
    ...props.modelValue.slice(splitIndex + 1)
  ];
  reportValue(newRows);
  updateFormRef.value.close();
  showUpdateForm.value = false;
  currentRow.value = null;
};
const onClickEdit = (index) => {
  currentRow.value = props.modelValue.find((e, i) => i === index);
  openUpdateForm();
};
const tagColorArray = [
  "geekblue",
  "orange",
  "green",
  "cyan",
  "red",
  "blue",
  "purple"
];
</script>
<template>
  <uni-row type="flex" justify="space-between">
    <uni-col>
      <uni-popup ref="createFormRef" type="bottom" background-color="#fff">
        <model-form-uni
          v-if="showCreateForm"
          @submit="onSuccessCreate"
          :model="adminModel"
          :values="adminModel.getDefaults()"
        ></model-form-uni>
      </uni-popup>
      <uni-popup ref="updateFormRef" type="bottom" background-color="#fff">
        <model-form-uni
          v-if="showUpdateForm"
          @submit="onSuccessUpdate"
          :model="adminModel"
          :values="currentRow"
        ></model-form-uni>
      </uni-popup>
      <model-form-uni-batch-button
        @findDuplicates="findDuplicates"
        @uploadRows="emit('uploadRows', $event)"
        :uniqueKey="uniqueKey"
        :model="adminModel"
        :rows="props.modelValue"
      ></model-form-uni-batch-button>
      <uni-tag style="cursor: pointer" text="添加" @click="openCreateForm">
      </uni-tag>
    </uni-col>
  </uni-row>
  <uni-table class="uni-table" stripe emptyText="点击上方添加按钮">
    <uni-tr>
      <uni-th>#</uni-th>
      <uni-th v-for="col in tableColumns" :key="col.index" align="center">
        {{ col.label }}
      </uni-th>
      <uni-th>操作</uni-th>
    </uni-tr>
    <uni-tr v-for="(row, index) in props.modelValue" :key="index">
      <uni-td>{{ index + 1 }}</uni-td>
      <uni-td v-for="col in tableColumns" :key="col.index" align="center">
        <template v-if="col.field.type === 'foreignkey'">
          {{
            typeof row[col.name] == "object"
              ? row[col.name][col.field.referenceColumn]
              : row[col.name]
          }}
        </template>
        <template v-else-if="col.field.type === 'aliossImage'">
          <img
            :src="
              row[col.name] instanceof Array
                ? row[col.name][0].ossUrl
                : row[col.name]
            "
            style="width: 50px"
          />
        </template>
        <template v-else-if="col.field.type === 'array'">
          <div
            v-for="(e, i) in row[col.name]"
            :key="i"
            style="margin-bottom: 2px"
          >
            <uni-tag :color="tagColorArray[i % tagColorArray.length]">
              {{ `${i + 1}. ` + e }}
            </uni-tag>
          </div>
        </template>
        <template v-else>
          {{ row[col.name] }}
        </template>
      </uni-td>
      <uni-td>
        <span>
          <button
            type="primary"
            size="mini"
            @click.prevent="onClickEdit(index)"
          >
            编辑
          </button>
          <button
            type="primary"
            size="mini"
            style="color: red"
            @click.prevent="deleteRecord(index)"
          >
            删除
          </button>
        </span>
      </uni-td>
    </uni-tr>
  </uni-table>
</template>

<style scoped lang="scss">
:deep(.uni-table) {
  th,
  td {
    padding: 0;
    margin: 0;
    border: none;
  }
}
.admin-list-avatar {
  max-width: 100px;
  max-height: 100px;
}
</style>
