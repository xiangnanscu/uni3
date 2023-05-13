<route lang="yaml"></route>
<script setup>
// 这里加上lang="jsx"的时候,onMounted不会执行
import { RouterLink, RouterView, useRoute } from "vue-router";

const modelName = useRoute().query.modelName;
const models = ref([]);
onMounted(async () => {
  const { data } = await Axios.get("/admin/model_list");
  models.value = data;
});
const siderKeys = ref([modelName]);
const modelList = computed(() => {
  return models.value.map((model) => {
    return {
      query: { modelName: model.name },
      label: model.label,
      modelName: model.name,
    };
  });
});
</script>

<template>
  <a-layout-sider>
    <a-menu
      v-model:selectedKeys="siderKeys"
      mode="inline"
      :style="{ height: '100%', borderRight: 0 }"
    >
      <!-- <a-menu-item v-bind="{ key: 'JsonForm' }">
        <router-link :to="{ path: '/' }"><span>首页</span></router-link>
      </a-menu-item> -->
      <a-menu-item
        v-for="(item, i) of modelList"
        :key="item.modelName"
      >
        <router-link :to="{ name: 'AdminListModel', query: item.query }">
          <span>{{ item.label }}</span>
        </router-link>
      </a-menu-item>
    </a-menu>
  </a-layout-sider>
  <a-layout-content>
    <router-view />
  </a-layout-content>
</template>

<style></style>
