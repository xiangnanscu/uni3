<template>
	<view class="fui-timeaxis__node-wrap"><!--todo: 待修改-->
		<view class="fui-timeaxis__left" :style="{width:leftWidth+'rpx'}">
			<slot name="left"></slot>
		</view>
		<view class="fui-timeaxis__node-box" :style="{width:width+'rpx'}">
			<view class="fui-timeaxis__node">
				<slot></slot>
			</view>
			<view class="fui-timeaxis__line" :style="{background:lineColor,width:lineWidth+'px'}" v-if="lined"></view>
		</view>
		<view class="fui-timeaxis__content">
			<slot name="right"></slot>
		</view>
	</view>
</template>

<script>
	export default {
		name: "fui-timeaxis-node",
		inject: ['timeaxis'],
		props: {
			lined: {
				type: Boolean,
				default: true
			},
			lineColor: {
				type: String,
				default: '#ccc'// 2021-5-6变更
			}
		},
		data() {
			return {
				lineWidth: 1,
				width: 48,
				leftWidth: 0
			};
		},
		created() {
			this.init()
		},
		methods: {
			init() {
				if (this.timeaxis) {
					this.width = this.timeaxis.width
					this.lineWidth = this.timeaxis.lineWidth
					this.leftWidth = this.timeaxis.leftWidth
					this.timeaxis.children.push(this)
				}
			}
		}
	}// 功能需要优化
</script>

<style scoped>
	.fui-timeaxis__node-wrap {
		position: relative;
		/* #ifndef APP-NVUE */
		width: 100%;
		display: flex;
		/* #endif */
		flex-direction: row;
	}

	.fui-timeaxis__line {
		/* #ifdef APP-NVUE */
		width: 0.5px;
		/* #endif */
		/* #ifndef APP-NVUE */
		width: 1px;
		transform: scaleX(.5) translateZ(0);
		transform-origin: center center;
		/* #endif */
		flex: 1;
	}

	.fui-timeaxis__node-box {
		/* #ifndef APP-NVUE */
		display: flex;
		flex-shrink: 0;
		/* #endif */
		flex-direction: column;
		align-items: center;
		overflow: hidden;/* todo: 待修改 */ 
	}

	.fui-timeaxis__node {
		/* #ifndef APP-NVUE */
		display: flex;
		/* #endif */
		align-items: center;
		justify-content: center;
	}

	.fui-timeaxis__left {
		/* #ifndef APP-NVUE */
		flex-shrink: 0;
		/* #endif */
		overflow: hidden;
	}

	.fui-timeaxis__content {
		/* #ifndef APP-NVUE */
		width: 100%;
		/* #endif */
		flex: 1;/* 功能需要优化 */ 
	}
</style>