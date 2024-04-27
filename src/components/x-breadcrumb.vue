<template>
  <div style="display: flex; flex-direction: row; align-items: center">
    <template v-for="(route, i) in routes" :key="i">
      <span v-if="i > 0" class="splitter">/</span>
      <navigator v-if="route.to" :url="route.to" open-type="navigate">
        <span class="route-item clickable">{{ route.name }}</span>
      </navigator>
      <span v-else class="route-item">{{ route.name }}</span>
    </template>
  </div>
</template>

<script setup>
const props = defineProps(["routes", "fontSize", "underline", "color"]);
const fontSize = props.fontSize || "100%";
const underline = props.underline || "underline";
const color = props.color || "blue";
</script>

<style scoped>
.route-item {
  font-weight: thin;
  font-size: v-bind(fontSize);
}
.clickable {
  color: v-bind(color);
  text-decoration: v-bind(underline);
}
.splitter {
  margin: 0 0.5em;
}
</style>
