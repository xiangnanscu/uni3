<script setup>
// onShareTimeline
// onShareAppMessage
useWxShare({
  title: "智慧校园通知",
  desc: "",
});
const modelName = "school_notice";
const ready = ref(false);
const hideDelete = ref(false);
const hideEdit = ref(true);
const session = useSession();
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
const attachSchoolClass = ({ data, model }) => {};
let RecordModel;
onLoad(async () => {
  await helpers.autoLogin();
  roles.value = await helpers.getPassedRoles();
  if (roles.value.class_director || roles.value.principal || roles.value.sys_admin) {
    showFloatPlus.value = true;
    const RecordJson = await useGet(`/${modelName}/json`);
    RecordModel = await Model.create_model_async(RecordJson);
    const sf = RecordModel.fields.school_id;
    const cf = RecordModel.fields.class_id;
    //TODO:需要厘清多学校情形下, 确定学校后如何只返回该学校的班级.要有联动机制
    if (roles.value.principal) {
      const school_id = roles.value.principal.school_id;
      sf.choices = sf.choices.filter((c) => c.value === school_id);
      sf.default = school_id;
      sf.disabled = true;
    } else if (roles.value.class_director) {
      const school_id = roles.value.class_director.school_id;
      const class_id = roles.value.class_director.class_id;
      sf.choices = sf.choices.filter((c) => c.value === school_id);
      cf.choices = cf.choices.filter((c) => c.value === class_id);
      sf.default = school_id;
      cf.default = class_id;
      sf.disabled = true;
      cf.disabled = true;
    }
  }
  records.value = await usePost(`/${modelName}/records`);
  ready.value = true;
});
const onSuccessCreate = async (data) => {
  log("onSuccessCreate", data);
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
</script>
<template>
  <div v-if="ready">
    <x-title> 学校通知</x-title>
    <uni-card title="" :border="false" :is-shadow="false" :is-full="true">
      <x-alert v-if="!records.length" title="没有记录"></x-alert>
      <uni-list>
        <uni-list-item
          v-for="(r, index) in records"
          :key="r.id"
          :title="r.title"
          :right-text="utils.getWeChatMessageTime(r.ctime)"
          show-arrow
          :to="`/views/SchoolNoticeDetail?id=${r.id}`"
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
          submit-button-text="提交"
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
