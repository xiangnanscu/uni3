<script setup></script>
<template>
  <span class="mini-btn">
    <slot />
  </span>
</template>
<style scoped>
.mini-btn {
  cursor: pointer;
  text-decoration: underline;
  color: #007bff;
  font-size: 0.8em;
}
</style>
