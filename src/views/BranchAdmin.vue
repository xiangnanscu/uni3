<template>
  <page-layout>
    <x-title>支部管理</x-title>
    <div v-if="ready">
      <uni-list :border="false">
        <uni-list-item
          v-if="sysadminRole"
          title="邀请团县委管理员"
          thumb-size="lg"
          link
          to="/views/BranchPrincipalRegedit"
          :showArrow="false"
        />
        <uni-list-item
          v-if="sysadminRole"
          title="审核团县委管理员"
          thumb-size="lg"
          link
          to="/views/BranchPrincipalCheck"
          :showArrow="false"
        />
        <uni-list-item
          v-if="sysadminRole || principalRole"
          title="邀请下级管理员"
          thumb-size="lg"
          link
          to="/views/BranchAdminRegedit"
          :showArrow="false"
        />
        <uni-list-item
          v-if="sysadminRole || principalRole"
          title="审核下级管理员"
          thumb-size="lg"
          link
          to="/views/BranchAdminCheck"
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
const principalRole = ref();
const sysadminRole = ref();
onLoad(async () => {
  const roles = await helpers.getPassedRoles();
  sysadminRole.value = roles.sys_admin;
  principalRole.value = roles.branch_admin;
  ready.value = true;
});
</script>

<style scoped></style>
