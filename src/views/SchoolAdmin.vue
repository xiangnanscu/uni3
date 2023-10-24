<template>
  <page-layout>
    <x-title>校方管理</x-title>
    <div v-if="ready">
      <uni-list :border="false">
        <uni-list-item
          title="录入学生"
          thumb-size="lg"
          link
          to="/views/SchoolStudentRegedit"
          :showArrow="false"
        />
        <!-- <uni-list-item
          title="设定校领导"
          thumb-size="lg"
          link
          to="/views/SchoolHome"
          :showArrow="false"
        />
        <uni-list-item
          title="设定年级主任"
          thumb-size="lg"
          link
          to="/views/SchoolHome"
          :showArrow="false"
        /> -->
        <uni-list-item
          v-if="godRole || sysadminRole"
          title="设定学校管理员"
          thumb-size="lg"
          link
          to="/views/SchoolRegeditPrincipal"
          :showArrow="false"
        />
        <uni-list-item
          v-if="godRole || sysadminRole || principalRole"
          title="设定班主任"
          thumb-size="lg"
          link
          to="/views/SchoolTeacherRegedit"
          :showArrow="false"
        />
        <uni-list-item
          v-if="godRole || sysadminRole || principalRole"
          title="设定门卫"
          thumb-size="lg"
          link
          to="/views/SchoolHome"
          :showArrow="false"
        />
      </uni-list>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script setup>
const ready = ref(false);
const { session } = useSession();
const user = session.user;
const query = useQuery();
const page = usePage();
const godRole = ref(user.permission >= process.env.GOD_PERMISSION ? user : null);
const principalRole = ref();
const sysadminRole = ref();
onLoad(async () => {
  sysadminRole.value = (await usePost(`/sys_admin/records`, { usr_id: user.id }))[0];
  principalRole.value = (await usePost(`/principal/records`, { usr_id: user.id }))[0];
  ready.value = true;
});
</script>

<style scoped></style>
