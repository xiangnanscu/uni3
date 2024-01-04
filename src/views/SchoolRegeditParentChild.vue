<template>
  <page-layout v-if="loaded">
    <x-title text="">亲子登记</x-title>
    <uni-card
      :title="`家长（${user.xm}）`"
      :border="false"
      :is-shadow="false"
      :is-full="true"
    >
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
              <image :src="s.avatar" mode="widthFix" style="width: 45px; height: 60px" />
              <div style="margin-left: 1em">{{ s.xm }}</div>
            </div>
            <div>
              <x-button
                style-string="padding: 0px 5px; font-size: 80%; margin-right: 1em"
                size="mini"
                @click="onClickEdit(s.id)"
              >
                编辑
              </x-button>
              <x-button
                style-string="padding: 0px 5px; font-size: 80%; color: red; border-color: red"
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
const session = useSession();
const user = session.user;
const loaded = ref(false);
const parent = ref({});
const students = ref([]);
const page = usePage();
const deleteConfirmRef = ref(null);
const studentIndex = ref(null);
const isProd = process.env.NODE_ENV === "production";
const currentStudent = computed(() =>
  studentIndex.value !== null ? students.value[studentIndex.value] : null,
);
const studentDeleteUrl = computed(
  () =>
    `/parent_student_relation/delete_by_both_ids?sync_to_hik=${isProd}&parent_id=${parent.value.id}&student_id=${currentStudent.value.id}`,
);
let ParentModel;
onLoad(async () => {
  helpers.checkRealName();
  parent.value = await usePost(`/parent/get_or_create`, [
    { usr_id: user.id },
    { usr_id: user.id },
    ["title", "id"],
  ]);
  const json = await useGet(`/parent/json`);
  json.field_names = ["title"];
  ParentModel = await Model.create_model_async(json);
  students.value = await usePost(`/student/parent/${parent.value.id}`);
  loaded.value = true;
});
const onSuccessStudentCreate = async (data) => {
  const insertRelations = await usePost(
    `/parent_student_relation/merge?key=parent_id&key=student_id`,
    [{ parent_id: parent.value.id, student_id: data.id }],
  );
  students.value.push(data);
  uni.showToast({
    title: "已保存",
    icon: "success",
    mask: true,
  });
};

const onClickEdit = async (sid) => {
  await utils.gotoPage({
    name: "SchoolStudentForm",
    query: { id: sid, redirect: page.value.$page.fullPath, parent_id: parent.value.id },
  });
};
const onClickCreate = async () => {
  await utils.gotoPage({
    name: "SchoolStudentForm",
    query: { redirect: page.value.$page.fullPath, parent_id: parent.value.id },
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
    uni.showToast({ title: "操作成功" });
  } else {
    uni.showToast({ title: "删除失败" });
  }
  studentIndex.value = null;
  deleteConfirmRef.value.close();
};
const actionUrlParent = computed(() =>
  parent.value ? `/parent/update/${parent.value.id}` : `/parent/create`,
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
<script>
export default {
  options: { styleIsolation: "shared" },
};
</script>
<style scoped>
.x-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
</style>
