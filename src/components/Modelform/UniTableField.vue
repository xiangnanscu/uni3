<route lang="yaml"></route>
<script setup lang="jsx">
import { computed, ref } from "vue";

const emit = defineEmits(["update:modelValue", "update:error"]);
const uniForm = inject("uniForm", null);
const uniFormItem = inject("uniFormItem", null);

const props = defineProps({
  field: { type: Object, required: true },
  modelValue: { required: true },
  error: {},
});

const adminModel = props.field.model;

const tableColumns = computed(() =>
  (props.field.columns || adminModel.admin?.list_names || adminModel.names).map(
    (name, index) => ({
      index,
      name,
      label: adminModel.name_to_label[name],
      field: adminModel.fields[name],
    }),
  ),
);

const findDuplicates = (rows) => {
  console.log("findDuplicates", { rows });
};

const currentRow = ref(null);
const createFormRef = ref(null);
const updateFormRef = ref(null);
const deleteConfirmRef = ref(null);
const showCreateForm = ref(false);
const showUpdateForm = ref(false);
const deleteIndex = ref(null);

const uniqueKey = computed(
  () => Object.values(adminModel.fields).find((f) => f.unique)?.name,
);
const reportValue = (newRows) => {
  emit("update:modelValue", newRows);
};
const deleteRecord = (splitIndex) => {
  const newRows = [
    ...props.modelValue.slice(0, splitIndex),
    ...props.modelValue.slice(splitIndex + 1),
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
const openDeletePrompt = (index) => {
  deleteConfirmRef.value.open();
  deleteIndex.value = index;
};
const onDeleteConfirm = () => {
  deleteRecord(deleteIndex.value);
  deleteIndex.value = -1;
  deleteConfirmRef.value.close();
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
    ...props.modelValue.slice(splitIndex + 1),
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
const tagColorArray = ["geekblue", "orange", "green", "cyan", "red", "blue", "purple"];
</script>
<template>
  <x-button size="mini" @click="openCreateForm">
    <uni-icons type="plusempty" style="color: #fff"></uni-icons>
    添加{{ field.label }}
  </x-button>
  <table
    v-if="props.modelValue.length"
    class="x-table"
    stripe
    emptyText="点击上方添加按钮"
    style="width: 100%"
  >
    <tr class="x-tr">
      <th class="x-th compact-td">#</th>
      <th
        class="x-th compact-td"
        v-for="col in tableColumns"
        :key="col.index"
        align="center"
      >
        {{ col.label }}
      </th>
      <th class="x-th compact-td">操作</th>
    </tr>
    <tr class="x-tr" v-for="(row, index) in props.modelValue" :key="index">
      <td class="x-td compact-td">{{ index + 1 }}</td>
      <td
        class="x-td compact-td"
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
        <template v-else-if="col.field.type === 'alioss_image'">
          <image
            :src="
              row[col.name] instanceof Array ? row[col.name][0].ossUrl : row[col.name]
            "
            mode="aspectFit"
            style="width: 50px; height: 50px"
          />
        </template>
        <template v-else-if="col.field.type === 'array'">
          <div v-for="(e, i) in row[col.name]" :key="i" style="margin-bottom: 2px">
            <uni-tag :color="tagColorArray[i % tagColorArray.length]">
              {{ `${i + 1}. ` + e }}
            </uni-tag>
          </div>
        </template>
        <template v-else>
          {{ row[col.name] }}
        </template>
      </td>
      <td class="x-td compact-td">
        <span>
          <div>
            <x-button
              styleString="padding: 0px 5px; font-size: 80%;"
              size="mini"
              @click="onClickEdit(index)"
            >
              编辑
            </x-button>
          </div>
          <div>
            <x-button
              styleString="padding: 0px 5px; font-size: 80%; color: red; border-color:red"
              size="mini"
              @click="openDeletePrompt(index)"
            >
              删除
            </x-button>
          </div>
        </span>
      </td>
    </tr>
  </table>
  <uni-popup
    ref="createFormRef"
    :is-mask-click="true"
    type="bottom"
    background-color="#fff"
  >
    <div style="padding: 1em">
      <modelform-uni
        v-if="showCreateForm"
        @sendData="onSuccessCreate"
        :model="adminModel"
        :values="adminModel.get_defaults()"
      ></modelform-uni>
    </div>
  </uni-popup>
  <uni-popup
    ref="updateFormRef"
    :is-mask-click="true"
    type="bottom"
    background-color="#fff"
  >
    <div style="padding: 1em">
      <modelform-uni
        v-if="showUpdateForm"
        @sendData="onSuccessUpdate"
        :model="adminModel"
        :values="currentRow"
        style="padding: 1em"
      ></modelform-uni>
    </div>
  </uni-popup>
  <uni-popup
    ref="deleteConfirmRef"
    :is-mask-click="true"
    type="bottom"
    background-color="#fff"
  >
    <uni-popup-dialog
      style="margin: auto"
      mode="base"
      :title="`确定删除第${deleteIndex + 1}条吗?`"
      confirmText="删除"
      :duration="2000"
      :before-close="true"
      @close="deleteConfirmRef.close()"
      @confirm="onDeleteConfirm"
    >
    </uni-popup-dialog>
  </uni-popup>
</template>

<style scoped lang="scss">
.x-table {
  width: 100%;
  border-radius: 8rpx;
  display: table;
  border-collapse: collapse;

  .x-th {
    text-align: center;
    padding: 20rpx 0;
    display: table-cell;
  }

  .x-td {
    text-align: center;
    background: #ffffff;
    padding: 20rpx 0;
    display: table-cell;
  }

  .x-tr {
    display: table-row;
  }
}
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
