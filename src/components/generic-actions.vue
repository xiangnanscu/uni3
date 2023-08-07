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
    <uni-badge
      class="uni-badge-left-margin"
      :text="favCount"
      absolute="rightTop"
      type2="info"
      :inverted2="false"
      :custom-style2="{
        'font-size': '100%',
        color: '#515151',
        'background-color': 'transparent',
        border: '0'
      }"
      :offset2="[5, 5]"
      size="normal"
    >
      <image
        @click="onFav"
        :src="`../static/img/tabbar/fav${favStatus ? '_fill_yellow' : ''}.png`"
        class="actions"
      ></image>
    </uni-badge>

    <uni-badge
      class="uni-badge-left-margin"
      :text="likeCount"
      absolute="rightTop"
      size="normal"
      :custom-style="{
        'z-index': 3
      }"
      :offset2="[5, 5]"
    >
      <image
        @click="onLike"
        :src="`../static/img/tabbar/appreciate${
          likeStatus ? '_fill_yellow' : ''
        }.png`"
        class="actions"
      ></image>
    </uni-badge>

    <slot />
  </div>
</template>

<script setup>
const props = defineProps({
  targetModel: { type: String, required: true },
  target: { type: Object, required: true }
});
const {
  actionsReady,
  actionsMap,
  favStatus,
  shareStatus,
  likeStatus,
  favCount,
  likeCount,
  shareCount,
  onLike,
  onFav,
  onShare
} = useGenericActions({
  targetModel: props.targetModel,
  target: props.target
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
