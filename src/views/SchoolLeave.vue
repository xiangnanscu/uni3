<script setup>
// onShareTimeline
// onShareAppMessage
useWxShare({
  title: "智慧校园请销假",
  desc: "",
});
const modelName = "student_leave_log";
const ready = ref(false);
const hideDelete = ref(false);
const hideEdit = ref(true);
const { session } = useSession();
const user = session.user;
const records = ref([]);
const students = ref([]);
const page = usePage();
const roles = ref({});
const showFloatPlus = ref(false);
const createFormRef = ref(null);
const updateFormRef = ref(null);
const showCreateForm = ref(false);
const showUpdateForm = ref(false);
const deleteConfirmRef = ref(null);
const recordIndex = ref(null);
const isProd = process.env.NODE_ENV === "production";
const currentRecord = computed(() =>
  recordIndex.value !== null ? records.value[recordIndex.value] : null,
);
const recordCreateUrl = computed(() => `/${modelName}/create`);
const recordUpdateUrl = computed(() => `/${modelName}/update/${currentRecord.value.id}`);
const recordDeleteUrl = computed(() => `/${modelName}/delete/${currentRecord.value.id}`);
const attachSchoolClass = ({ data, model }) => {
  const choice = model.fields.student_id.choices.find((c) => c.value === data.student_id);
  if (choice) {
    return { school_id: choice.school_id, class_id: choice.class_id };
  }
};
let RecordModel;
onLoad(async () => {
  await helpers.autoLogin();
  roles.value = await helpers.getRoles({ status: "通过" });
  if (roles.value.parent) {
    students.value = await usePost(`/student/parent/${roles.value.parent.id}`);
    if (students.value.length) {
      showFloatPlus.value = true;
      const RecordJson = await useGet(`/${modelName}/json`);
      RecordJson.field_names = ["student_id", "reason"];
      RecordJson.fields.student_id.choices = students.value.map((e) => ({
        school_id: e.school_id,
        class_id: e.class_id,
        value: e.id,
        label: e.xm,
      }));
      RecordModel = await Model.create_model_async(RecordJson);
      const f = RecordModel.fields.student_id;
      if (f.choices.length === 1) {
        f.default = f.choices[0].value;
      }
    }
  }
  records.value = await usePost(`/${modelName}/records`);
  ready.value = true;
});
const onSuccessCreate = async (data) => {
  log("onSuccessCreate", data);
  const choice = RecordModel.fields.student_id.choices.find(
    (c) => c.value === data.student_id,
  );
  data.student_id__xm = choice.label;
  records.value.unshift(data);
  createFormRef.value.close();
  showCreateForm.value = false;
  uni.showToast({
    title: "已创建",
    icon: "success",
    mask: true,
  });
};
const onSuccessUpdate = (data) => {
  console.log("onSuccessUpdate", data);
  Object.assign(currentRecord.value, Array.isArray(data) ? data[0] : data);
  currentRecord.value;
  updateFormRef.value.close();
  showUpdateForm.value = false;
  recordIndex.value = null;
  uni.showToast({
    title: "已保存",
    icon: "success",
    mask: true,
  });
};
const createMaskClick = () => {
  showCreateForm.value = false;
};
const updateMaskClick = () => {
  showUpdateForm.value = false;
};
const onClickEdit = async (index) => {
  recordIndex.value = index;
  updateFormRef.value.open();
  showUpdateForm.value = true;
};
const onClickCreate = async () => {
  createFormRef.value.open();
  showCreateForm.value = true;
};
const onClickDelete = (sindex) => {
  recordIndex.value = sindex;
  deleteConfirmRef.value.open();
};

const onDeleteConfirm = async () => {
  const { affected_rows } = await usePost(recordDeleteUrl.value);
  if (affected_rows === 1) {
    records.value.splice(recordIndex.value, 1);
    recordIndex.value = null;
    deleteConfirmRef.value.close();
    uni.showToast({ title: "操作成功" });
  } else {
    uni.showToast({ title: "删除失败" });
  }
};
const getLeaveTitle = (r) => {
  return `${r.student_id__xm}（${r.status}）`;
};
</script>
<template>
  <div v-if="ready">
    <x-title> 请销假</x-title>
    <uni-card title="" :border="false" :is-shadow="false" :is-full="true">
      <x-alert v-if="!records.length" title="没有记录"></x-alert>
      <uni-list>
        <uni-list-item
          v-for="(r, index) in records"
          :key="r.id"
          :title="getLeaveTitle(r)"
          :right-text="utils.getWeChatMessageTime(r.ctime)"
          show-arrow
          :note="utils.textDigest(r.reason, 10)"
          :to="`/views/SchoolLeaveDetail?id=${r.id}`"
        >
        </uni-list-item>
      </uni-list>
      <fui-fab
        v-if="showFloatPlus"
        :distance="30"
        position="right"
        :isDrag="true"
        @click="onClickCreate"
      ></fui-fab>
    </uni-card>
    <uni-popup
      ref="createFormRef"
      :is-mask-click="true"
      type="bottom"
      background-color="#fff"
      @maskClick="createMaskClick"
    >
      <div style="padding: 1em">
        <modelform-uni
          v-if="showCreateForm"
          :action-url="recordCreateUrl"
          :values-hook="attachSchoolClass"
          @successPost="onSuccessCreate"
          :model="RecordModel"
          submit-button-text="请假"
          :values="RecordModel.get_defaults()"
        ></modelform-uni>
      </div>
    </uni-popup>
    <uni-popup
      ref="updateFormRef"
      :is-mask-click="true"
      type="bottom"
      background-color="#fff"
      @maskClick="updateMaskClick"
    >
      <div style="padding: 1em">
        <modelform-uni
          v-if="showUpdateForm"
          :action-url="recordUpdateUrl"
          @successPost="onSuccessUpdate"
          :model="RecordModel"
          submit-button-text="请假"
          :values="currentRecord"
        ></modelform-uni>
      </div>
    </uni-popup>
    <uni-popup ref="deleteConfirmRef" type="dialog">
      <uni-popup-dialog
        mode="base"
        :title="`确定删除${currentRecord?.name || '这条记录'}吗?`"
        confirmText="删除"
        :duration="1000"
        :before-close="true"
        @close="deleteConfirmRef.close()"
        @confirm="onDeleteConfirm"
      >
      </uni-popup-dialog>
    </uni-popup>
  </div>
</template>
<style scoped>
.x-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
</style>
