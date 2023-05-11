<script setup>
import { onMounted } from "vue";

const router = useRouter();
const route = useRoute();

onMounted(() => {
  const { logout } = useSession();
  logout();
  router.push(route.query.redirect || "/");
});
</script>

<template>正在退出。。。</template>
