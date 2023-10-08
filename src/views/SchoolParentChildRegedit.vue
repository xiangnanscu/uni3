<template>
  <page-layout v-if="loaded">
    <x-alert title="红云智慧校园"> </x-alert>
    <uni-card title="家长" :border="false" :is-shadow="false">
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
      <uni-card title="子女" :border="false" :is-shadow="false">
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
                @click="onClickEdit(sindex)"
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
        <x-button styleString="display:block;" @click="openCreateForm">
          添加子女
        </x-button>
      </uni-card>
    </template>
    <uni-popup
      ref="createFormRef"
      :is-mask-click="true"
      type="bottom"
      background-color="#fff"
    >
      <div style="padding: 1em">
        <modelform-uni
          v-if="showCreateForm"
          :action-url="studentCreateUrl"
          @successPost="onSuccessStudentCreate"
          :model="StudentModel"
          :values="StudentModel.get_defaults()"
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
          :action-url="studentUpdateUrl"
          @successPost="onSuccessUpdate"
          :model="StudentModel"
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
  () => `/student/create?sync_to_hik=${isProd}&parent_id=${parent.value.id}`,
);
const studentUpdateUrl = computed(
  () => `/student/update/${currentStudent.value.id}?sync_to_hik=${isProd}`,
);
const studentDeleteUrl = computed(
  () =>
    `/parent_student_relation/delete_by_both_ids?sync_to_hik=${isProd}&parent_id=${parent.value.id}&student_id=${currentStudent.value.id}`,
);
const onSuccessStudentCreate = (data) => {
  students.value.push(data);
  createFormRef.value.close();
  showCreateForm.value = false;
};
const onSuccessUpdate = (data) => {
  Object.assign(currentStudent.value, data);
  updateFormRef.value.close();
  showUpdateForm.value = false;
  studentIndex.value = null;
};
const onClickEdit = async (sindex) => {
  studentIndex.value = sindex;
  updateFormRef.value.open();
  showUpdateForm.value = true;
  // await utils.gotoPage({
  //   redirect: true,
  //   name: "SchoolStudentForm",
  //   query: { id: sid, redirect: page.value.$page.fullPath },
  // });
};
const openCreateForm = () => {
  createFormRef.value.open();
  showCreateForm.value = true;
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
let ParentModel;
let StudentModel;
onLoad(async () => {
  ParentModel = Model.create_model(await useGet(`/parent/json`));
  StudentModel = Model.create_model(await useGet(`/student/json`));
  let parentCond = { sfzh: user.username };
  // #ifdef MP-WEIXIN
  parentCond = { openid: user.openid };
  // #endif
  const [parentData] = await usePost(`/parent/records`, parentCond);
  if (parentData) {
    parentData.openid = user.openid;
    parent.value = parentData;
    const children = await usePost(`/parent_student_relation/query`, {
      where: { parent_id: parent.value.id },
      select: ["id"],
      load_fk_array: ["student_id", "*"],
    });
    students.value = children.map((c) => c.student_id);
  } else {
    parent.value = { openid: user.openid };
  }
  loaded.value = true;
});
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
