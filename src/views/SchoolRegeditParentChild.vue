<template>
  <page-layout v-if="loaded">
    <x-alert title="智慧校园"> </x-alert>
    <uni-card
      :title="`家长（${user.xm}）`"
      :border="false"
      :is-shadow="false"
      :is-full="true"
    >
      <!-- <fui-preview :previewData="previewData"></fui-preview> -->
      <modelform-uni
        :model="ParentModel"
        :values="parent"
        :sync-values="true"
        @success-post="successPostParent"
        :action-url="actionUrlParent"
        submit-button-text="保存"
      ></modelform-uni>
    </uni-card>
    <template v-if="parent.id">
      <uni-card title="子女" :border="false" :is-shadow="false" :is-full="true">
        <uni-group v-for="(s, sindex) in students" :key="s.id" mode="card">
          <div class="x-row">
            <div class="x-row">
              <image :src="s.avatar" mode="widthFix" style="width: 45px" />
              <div style="margin-left: 1em">{{ s.xm }}</div>
            </div>
            <div>
              <x-button
                styleString="padding: 0px 5px; font-size: 80%;margin-right:1em"
                size="mini"
                @click="onClickEdit(s.id)"
              >
                编辑
              </x-button>
              <x-button
                styleString="padding: 0px 5px; font-size: 80%; color: red; border-color:red"
                size="mini"
                @click="onClickDelete(sindex)"
              >
                删除
              </x-button>
            </div>
          </div>
        </uni-group>
        <x-button styleString="display:block;" @click="onClickCreate">
          添加子女
        </x-button>
      </uni-card>
    </template>
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
          :action-url="studentCreateUrl"
          @successPost="onSuccessStudentCreate"
          :model="StudentModel"
          submit-button-text="保存"
          :values="StudentModel.get_defaults()"
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
          :action-url="studentUpdateUrl"
          @successPost="onSuccessUpdate"
          :model="StudentModel"
          submit-button-text="保存"
          :values="currentStudent"
        ></modelform-uni>
      </div>
    </uni-popup>
    <uni-popup ref="deleteConfirmRef" type="dialog">
      <uni-popup-dialog
        mode="base"
        :title="`确定删除${currentStudent?.xm}吗?`"
        confirmText="删除"
        :duration="1000"
        :before-close="true"
        @close="deleteConfirmRef.close()"
        @confirm="onDeleteConfirm"
      >
      </uni-popup-dialog>
    </uni-popup>
  </page-layout>
</template>
<script setup>
// onShareTimeline
// onShareAppMessage
useWxShare({
  title: "智慧校园亲子登记",
  desc: "",
});
const { session } = useSession();
const user = session.user;
const loaded = ref(false);
const parent = ref({});
const students = ref([]);
const page = usePage();
const createFormRef = ref(null);
const showCreateForm = ref(false);
const updateFormRef = ref(null);
const showUpdateForm = ref(false);
const deleteConfirmRef = ref(null);
const studentIndex = ref(null);
const isProd = process.env.NODE_ENV === "production";
const currentStudent = computed(() =>
  studentIndex.value !== null ? students.value[studentIndex.value] : null,
);
const studentCreateUrl = computed(
  () => `/student/register?sync_to_hik=${isProd}&parent_id=${parent.value.id}`,
);
const studentUpdateUrl = computed(
  () => `/student/update/${currentStudent.value.id}?sync_to_hik=${isProd}`,
);
const studentDeleteUrl = computed(
  () =>
    `/parent_student_relation/delete_by_both_ids?sync_to_hik=${isProd}&parent_id=${parent.value.id}&student_id=${currentStudent.value.id}`,
);
let ParentModel;
let previewData;
let StudentModel;
onLoad(async () => {
  if (!user.username) {
    return utils.gotoPage({
      url: "/views/RealNameCert",
      query: { message: "此操作需要先实名认证", redirect: utils.getFullPath() },
      redirect: true,
    });
  }
  previewData = {
    list: [
      {
        label: "姓名",
        value: user.xm,
      },
      {
        label: "身份证号",
        value: user.username,
      },
    ],
  };
  parent.value = await usePost(`/parent/get_or_create`, [
    { usr_id: user.id },
    { usr_id: user.id },
    ["title", "id"],
  ]);
  console.log({ parent });
  ParentModel = await Model.create_model_async(await useGet(`/parent/json`));
  // StudentModel = await Model.create_model_async(await useGet(`/student/json`));
  students.value = await usePost(`/student/parent/${parent.value.id}`);
  loaded.value = true;
});
const onSuccessStudentCreate = async (data) => {
  const insertRelations = await usePost(
    `/parent_student_relation/merge?key=parent_id&key=student_id`,
    [{ parent_id: parent.value.id, student_id: data.id }],
  );
  students.value.push(data);
  createFormRef.value.close();
  showCreateForm.value = false;
  uni.showToast({
    title: "已保存",
    icon: "success",
    mask: true,
  });
};
const onSuccessUpdate = (data) => {
  console.log("onSuccessUpdate", data);
  Object.assign(currentStudent.value, data); //取消, 后端无法控制更新后的school_id__name
  currentStudent.value;
  updateFormRef.value.close();
  showUpdateForm.value = false;
  studentIndex.value = null;
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
const onClickEdit = async (sid) => {
  // studentIndex.value = sindex;
  // updateFormRef.value.open();
  // showUpdateForm.value = true;
  await utils.gotoPage({
    name: "SchoolStudentForm",
    query: { id: sid, redirect: page.value.$page.fullPath },
  });
};
const onClickCreate = async () => {
  // createFormRef.value.open();
  // showCreateForm.value = true;
  await utils.gotoPage({
    name: "SchoolStudentForm",
    query: { redirect: page.value.$page.fullPath },
  });
};
const onClickDelete = (sindex) => {
  studentIndex.value = sindex;
  deleteConfirmRef.value.open();
};

const onDeleteConfirm = async () => {
  const { affected_rows } = await usePost(studentDeleteUrl.value);
  if (affected_rows === 1) {
    students.value.splice(studentIndex.value, 1);
    studentIndex.value = null;
    deleteConfirmRef.value.close();
    uni.showToast({ title: "操作成功" });
  } else {
    uni.showToast({ title: "删除失败" });
  }
};
const actionUrlParent = computed(() =>
  parent.value.id ? `/parent/update/${parent.value.id}` : `/parent/create`,
);
const successPostParent = async (user) => {
  Object.assign(parent.value, user);
  uni.showToast({
    title: "已保存",
    icon: "success",
    mask: true,
  });
};
</script>
<style scoped>
.x-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
</style>
