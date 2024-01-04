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
          v-if="sysadminRole"
          title="邀请学校管理员"
          thumb-size="lg"
          link
          to="/views/SchoolRegeditPrincipal"
          :showArrow="false"
        />
        <uni-list-item
          v-if="sysadminRole"
          title="审核学校管理员"
          thumb-size="lg"
          link
          to="/views/SchoolCheckPrincipal"
          :showArrow="false"
        />
        <uni-list-item
          v-if="sysadminRole || principalRole"
          title="邀请班主任"
          thumb-size="lg"
          link
          to="/views/SchoolRegeditClassDirector"
          :showArrow="false"
        />
        <uni-list-item
          v-if="sysadminRole || principalRole"
          title="审核班主任"
          thumb-size="lg"
          link
          to="/views/SchoolCheckClassDirector"
          :showArrow="false"
        />
        <uni-list-item
          v-if="sysadminRole || principalRole"
          title="邀请门卫"
          thumb-size="lg"
          link
          to="/views/SchoolRegeditGuard"
          :showArrow="false"
        />
        <uni-list-item
          v-if="sysadminRole || principalRole"
          title="审核门卫"
          thumb-size="lg"
          link
          to="/views/SchoolCheckGuard"
          :showArrow="false"
        />
        <uni-list-item
          title="家长订阅"
          thumb-size="lg"
          link
          to="/views/SchoolSubscribeHint"
          :showArrow="false"
        />
      </uni-list>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script setup>
const ready = ref(false);
const session = useSession();
const user = session.user;
const query = useQuery();
const principalRole = ref();
const sysadminRole = ref();
onLoad(async () => {
  const roles = await helpers.getPassedRoles();
  sysadminRole.value = roles.sys_admin;
  principalRole.value = roles.principal;
  ready.value = true;
});
</script>

<style scoped></style>
