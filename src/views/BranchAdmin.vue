<template>
  <page-layout>
    <x-title>团组织管理</x-title>
    <div v-if="ready">
      <uni-list :border="false">
        <uni-list-item
          v-if="invitable"
          title="邀请团组织管理员"
          thumb-size="lg"
          link
          to="/views/BranchRegeditAdmin"
          :showArrow="false"
        />
        <uni-list-item
          v-if="invitable"
          title="审核团组织管理员"
          thumb-size="lg"
          link
          to="/views/BranchCheckAdmin"
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
const branchAdminRole = ref();
const sysadminRole = ref();
const invitable = computed(() => branchAdminRole.value || sysadminRole.value);
onLoad(async () => {
  const roles = await helpers.getPassedRoles();
  sysadminRole.value = roles.sys_admin;
  if (roles.branch_admin && roles.branch_admin.type !== "团支部") {
    branchAdminRole.value = roles.branch_admin;
  }
  ready.value = true;
});
</script>

<style scoped></style>
