<route lang="yaml"></route>
<script setup lang="jsx">
import { computed, ref } from "vue";

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
  (props.field.columns || adminModel.admin?.list_names || adminModel.names).map(
    (name, index) => ({
      index,
      name,
      label: adminModel.name_to_label[name],
      field: adminModel.fields[name]
    })
  )
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
  <uni-popup ref="createFormRef" type="bottom" background-color="#fff">
    <modelform-uni
      v-if="showCreateForm"
      @sendData="onSuccessCreate"
      :model="adminModel"
      :values="adminModel.getDefaults()"
      style="padding: 1em"
    ></modelform-uni>
  </uni-popup>
  <uni-popup ref="updateFormRef" type="bottom" background-color="#fff">
    <modelform-uni
      v-if="showUpdateForm"
      @sendData="onSuccessUpdate"
      :model="adminModel"
      :values="currentRow"
      style="padding: 1em"
    ></modelform-uni>
  </uni-popup>
  <x-button size="mini" @click="openCreateForm">
    <uni-icons type="plusempty" style="color: #fff"></uni-icons>
    添加{{ field.label }}
  </x-button>
  <uni-table
    v-if="props.modelValue.length"
    class="uni-table"
    stripe
    emptyText="点击上方添加按钮"
    style="width: 100%"
  >
    <uni-tr>
      <uni-th class="compact-td">#</uni-th>
      <uni-th
        class="compact-td"
        v-for="col in tableColumns"
        :key="col.index"
        align="center"
      >
        {{ col.label }}
      </uni-th>
      <uni-th class="compact-td">操作</uni-th>
    </uni-tr>
    <uni-tr v-for="(row, index) in props.modelValue" :key="index">
      <uni-td class="compact-td">{{ index + 1 }}</uni-td>
      <uni-td
        class="compact-td"
        v-for="col in tableColumns"
        :key="col.index"
        align="center"
      >
        <template v-if="col.field.type === 'foreignkey'">
          {{
            typeof row[col.name] == "object"
              ? row[col.name][col.field.reference_column]
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
      <uni-td class="compact-td">
        <span>
          <modelform-uni-mini-button
            style="margin-right: 2px"
            @click="onClickEdit(index)"
          >
            编辑
          </modelform-uni-mini-button>
          <modelform-uni-mini-button
            style="color: red"
            @click.prevent="deleteRecord(index)"
          >
            删除
          </modelform-uni-mini-button>
        </span>
      </uni-td>
    </uni-tr>
  </uni-table>
</template>

<style scoped lang="scss">
:deep(.compact-td) {
  padding: 0;
  margin: 0;
  border: none;
}
.admin-list-avatar {
  max-width: 100px;
  max-height: 100px;
}
</style>
