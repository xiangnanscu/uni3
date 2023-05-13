<route lang="yaml"></route>
<script setup >
import { computed, ref, createVNode } from "vue";
import { useRoute, useRouter } from "vue-router";
import { ExclamationCircleOutlined, PlusOutlined } from "@ant-design/icons-vue";
import { Axios } from "@/globals/Axios";
import ModelBatchButton from "@/components/ModelBatchButton.vue";
import { Modal } from "ant-design-vue";
import "ant-design-vue/lib/modal/style/css";
import { notification } from "ant-design-vue";
import "ant-design-vue/lib/notification/style/css";


const route = useRoute();
const router = useRouter();
const props = defineProps({
  model: { type: [Object, Function], required: true },
  rowKey: { type: [String, Function], default: "id" },
  // searchInputValue: { type: [String, Array], default: "" },
  // searchSelectName: { type: [String, Array], default: "" },
  // page: { type: [Number, String], default: 1 },
  // pagesize: { type: [Number, String], default: Number(import.meta.env.VITE_ADMIN_PAGESIZE || 20) },
  getListUrl: { type: Function, default: (modelName) => `/admin/model/${modelName}/list` },
  getCreateUrl: { type: Function, default: (modelName) => `/admin/model/${modelName}/create` },
  getUpdateUrl: { type: Function, default: (modelName, id) => `/admin/model/${modelName}/update/${id}` },
  getDeleteUrl: { type: Function, default: (modelName, id) => `/admin/model/${modelName}/delete/${id}` },
  getDetailUrl: { type: Function, default: (modelName, id) => `/admin/model/${modelName}/detail/${id}` },
})
const alwaysArray = (v) => (typeof v == "string" && v)
  ? [v]
  : Array.isArray(v)
    ? [...v]
    : []
const getLast = (arr) => arr[arr.length - 1]
const sameNames = (a, b) => {
  a = !Array.isArray(a) ? [a] : a;
  b = !Array.isArray(b) ? [b] : b;
  if (a.length !== b.length) {
    return false;
  }
  for (let index = 0; index < a.length; index++) {
    if (a[index] !== b[index]) {
      return false;
    }
  }
  return true;
};
const searchTypes = new Set(["string", "email", "text", "sfzh"]);
const searchableField = (f) => {
  return searchTypes.has(f.type);
};
const adminModel = shallowRef(props.model);
const modelName = computed(() => adminModel.value.tableName);
const currentPage = ref(Number(props.page || route.query.page || 1));
const pagesize = ref(Number(props.pagesize || route.query.pagesize || import.meta.env.VITE_ADMIN_PAGESIZE || 20));
const searchSelectName = computed(() => alwaysArray(route.query.k))
const searchInputValue = computed(() => alwaysArray(route.query.v))
// const searchSelectName = ref(alwaysArray(route.query.k))
// const searchInputValue = ref(alwaysArray(route.query.v))
const records = ref([]);
const total = ref(0);
const searchChoices = computed(() => {
  if (!adminModel.value) {
    return [];
  } else {
    return adminModel.value.fieldNames
      .map((name) => adminModel.value.fields[name])
      .filter((f) => searchableField(f))
      .map((f) => ({ label: f.label, value: f.name }));
  }
});
const currentSearchSelectName = ref(getLast(searchSelectName.value) || searchChoices.value[0]?.value || "")
const currentSearchInputValue = ref(getLast(searchInputValue.value) || "")
const setRecordsByPage = async (page, old) => {
  const { data } = await Axios.post(
    props.getListUrl(modelName.value),
    {
      key: searchSelectName.value,
      value: searchInputValue.value,
    },
    {
      params: {
        page,
        pagesize: pagesize.value,
      },
    }
  );
  records.value = data.records;
  total.value = data.total;
};
watch(
  currentPage,
  async (page, old) => {
    await setRecordsByPage(page, old);
  },
  { immediate: true }
);

watch(
  // () => [searchSelectName.value, searchInputValue.value],
  () => [route.query.k, route.query.v],
  async ([k, v], [k2, v2]) => {
    console.log(JSON.stringify([k, v, k2, v2]))
    if (!k?.length || !v?.length) {
      // 从A model的搜索页面跳转到B model时, k, v皆为空
      return
    }
    // 确保查询框发起查询时都会重置页码
    if (!sameNames(v, v2) || !sameNames(k, k2)) {
      await setRecordsByPage(1);
    }
  },
  { deep: true }
);
const toAntdColumns = (names) => {
  return names.map((k) => ({
    title: adminModel.value.nameToLabel[k],
    dataIndex: k,
    field: adminModel.value.fields[k],
    key: k,
  }));
};
const tableColumns = computed(() =>
  adminModel.value
    ? [
      { title: "#", key: "#" },
      ...toAntdColumns(
        adminModel.value.admin?.listNames || adminModel.value.names
      ),
      { title: "操作", key: "action" },
    ]
    : []
);

const findDuplicates = (rows) => {
  console.log("findDuplicates", { rows });
};

const editId = ref(0);
const editRecord = computed(
  () => records.value.find((e) => e.id === editId.value) || {}
);
const showUpdateForm = computed(() => editId.value !== 0);
const showCreateForm = ref(false);
const createUrl = computed(() => props.getCreateUrl(modelName.value));
const updateUrl = computed(() => props.getUpdateUrl(modelName.value, editId.value));
const uniqueKey = computed(() =>
  adminModel.value
    ? Object.values(adminModel.value.fields).find((f) => f.unique)?.name
    : "id"
);
const deleteRecord = (row) => {
  Modal.confirm({
    title: `${row[uniqueKey.value] || ""}`,
    icon: createVNode(ExclamationCircleOutlined, { style: { color: "red" } }),
    content: "确认删除这条记录吗",
    okText: "删除",
    okType: "danger",
    async onOk() {
      const { data } = await Axios.post(props.getDeleteUrl(modelName.value, row.id));
      records.value = records.value.filter((r) => r.id !== row.id);
      notification.success({ message: `成功删除${data.affected_rows}条记录` });
    },
    cancelText: "取消",
  });
};
const onSuccessCreate = ({ response }) => {
  const { data } = response;
  records.value.unshift(data);
  showCreateForm.value = false;
};
const onSuccessUpdate = ({ data }) => {
  Object.assign(editRecord.value, data);
  editId.value = 0;
};
const onClickEdit = async (record) => {
  const { data } = await Axios.get(props.getDetailUrl(modelName.value, record.id));
  Object.assign(record, data);
  editId.value = record.id;
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
const makePageRoute = ({ page, key, value }) => {
  const query = {
    modelName: modelName.value,
    page,
    pagesize: pagesize.value,
    k: key ?? searchSelectName.value,
    v: value ?? searchInputValue.value,
  }
  const res = { name: route.name, query, }
  return res;
};
const resetSearch = () => {
  currentSearchInputValue.value = ""
  router.push(
    makePageRoute({
      modelName: modelName.value,
      page: 1,
      key: [],
      value: [],
    })
  );
}
const search = async () => {
  if (!currentSearchInputValue.value || !currentSearchSelectName.value) {
    return;
  }
  const nameIndex = searchSelectName.value.findIndex(e => e === currentSearchSelectName.value)
  if (nameIndex !== -1) {
    searchInputValue.value[nameIndex] = currentSearchInputValue.value
    router.push(
      makePageRoute({
        modelName: modelName.value,
        page: 1,
        key: searchSelectName.value,
        value: searchInputValue.value,
      })
    );
  } else {
    router.push(
      makePageRoute({
        modelName: modelName.value,
        page: 1,
        key: [...searchSelectName.value, currentSearchSelectName.value],
        value: [...searchInputValue.value, currentSearchInputValue.value],
      })
    );
  }
  // 放到这里不会生效, watch里面才能观测到searchInputValue的变化从而发起查询
  // await setRecordsByPage(1);
};
</script>
<template>
  <a-row
    type="flex"
    justify="space-between"
  >
    <a-col>
      <model-batch-button
        v-if="adminModel"
        @findDuplicates="findDuplicates"
        :uniqueKey="uniqueKey"
        :upload-url="`/admin/model/${modelName}/merge?key=${uniqueKey}`"
        :download-url="`/admin/model/${modelName}/download`"
        :model="adminModel"
      ></model-batch-button>
      <a-button @click.prevent="showCreateForm = true">
        <plus-outlined></plus-outlined>
        添加
      </a-button></a-col>
    <a-col>
      <a-row>
        <a-col v-if="searchSelectName.length">
          <a-button @click="resetSearch">重置搜索</a-button>
        </a-col>
        <a-col>
          <a-select
            v-model:value="currentSearchSelectName"
            placeholder="选择查找字段"
            style="width: 150px"
          >
            <a-select-option
              v-for="(c, i) in searchChoices"
              :value="c.value"
              :key="i"
            >{{ c.label }}</a-select-option>
          </a-select></a-col>
        <a-col>
          <a-input
            v-model:value="currentSearchInputValue"
            @keyup.enter="search"
          /></a-col>
        <a-col>
          <a-button @click="search">查找</a-button>
        </a-col>
      </a-row>
    </a-col>
  </a-row>
  <a-row v-if="total > pagesize">
    <a-col style="margin: auto">
      <a-pagination
        v-model:current="currentPage"
        :total="total"
        :showSizeChanger="false"
        :page-size="pagesize"
      >
        <template #itemRender="{ type, page, originalElement }">
          <router-link
            v-if="type === 'page'"
            :to="makePageRoute({ page })"
          >{{
            page
          }}</router-link>
          <component
            :is="originalElement"
            v-else
          ></component>
        </template>
      </a-pagination>
    </a-col>
  </a-row>
  <a-table
    :rowKey="props.rowKey"
    :dataSource="records"
    :columns="tableColumns"
    :pagination="{ hideOnSinglePage: true, pageSize: pagesize }"
  >
    <template #bodyCell="{ column, index, record, text, value }">
      <template v-if="column?.key === '#'">{{
        record.id ?? index + 1
      }}</template>
      <template v-else-if="column?.field?.type === 'foreignkey'">
        {{
          typeof value == "object" ? value[column.field.referenceColumn] : value
        }}
      </template>
      <template v-else-if="column?.field?.type === 'text'">
        <pre>{{ value }}</pre>
      </template>
      <template v-else-if="column?.field?.type === 'aliossImage'">
        <img
          :src="Array.isArray(value) ? value[0].ossUrl : value"
          class="admin-list-avatar"
        />
      </template>
      <template v-else-if="column?.field?.mediaType === 'video'">
        <video
          controls
          width="250"
        >
          <source :src="value">
        </video>
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
            @click.prevent="deleteRecord(record)"
          >删除</a-button>
        </span>
      </template>
    </template>
  </a-table>
  <a-row v-if="total > pagesize">
    <a-col style="margin: auto">
      <a-pagination
        v-model:current="currentPage"
        :total="total"
        :page-size="pagesize"
        :showSizeChanger="false"
      >
        <template #itemRender="{ type, page, originalElement }">
          <router-link
            v-if="type === 'page'"
            :to="makePageRoute({ page })"
          >{{
            page
          }}</router-link>
          <component
            :is="originalElement"
            v-else
          ></component>
        </template>
      </a-pagination>
    </a-col>
  </a-row>
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
      @successPost="onSuccessCreate"
      :model="adminModel"
      :values="adminModel.getDefaults()"
      :action-url="createUrl"
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
      @successPost="onSuccessUpdate"
      :model="adminModel"
      :values="editRecord"
      :action-url="updateUrl"
    ></model-form>
  </a-modal>
</template>

<style scoped>
.admin-list-avatar {
  max-width: 100px;
  max-height: 100px;
}
</style>
