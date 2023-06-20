<template>
  <div v-if="actionsReady" class="actions-container">
    <button
      open-type="share"
      size="mini"
      class="actions"
      style="
        display: inline-block;
        margin: 0;
        padding: 0;
        background-color: transparent;
        border: 0;
      "
    >
      <image
        @click="onShare"
        src="../static/img/tabbar/share-tpp.png"
        class="actions"
      ></image>
    </button>

    <image
      @click="onFav"
      :src="`../static/img/tabbar/fav${favStatus ? '_fill' : ''}.png`"
      class="actions"
    ></image>
    <image
      @click="onLike"
      :src="`../static/img/tabbar/appreciate${likeStatus ? '_fill' : ''}.png`"
      class="actions"
    ></image>
  </div>
</template>

<script setup>
const props = defineProps({
  targetModel: { type: String, required: true },
  targetId: { type: Number, required: true }
});
const {
  actionsReady,
  actionsMap,
  favStatus,
  shareStatus,
  likeStatus,
  onLike,
  onFav,
  onShare
} = useGenericActions({
  target_model: props.targetModel,
  target_id: props.targetId
});
</script>

<style lang="scss" scoped>
.actions {
  width: 25px;
  height: 25px;
}
.actions-container {
  width: 100%;
  margin-top: 0.5em;
  display: flex;
  justify-content: space-around;
}
button::after {
  border: 0;
}
</style>
