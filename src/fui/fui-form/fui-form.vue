<template>
	<view class="fui-form__wrap"
		:style="{paddingTop:padding[0] || 0,paddingRight:padding[1] || 0,paddingBottom:padding[2] || padding[0] || 0,paddingLeft:padding[3] || padding[1] || 0}">
		<slot></slot>
		<view class="fui-form__msg-wrap"
			:style="{top:top+'px',left:left+'rpx',right:right+'rpx',background:getBgColor,borderRadius:radius+'rpx'}"
			v-if="show" :class="{'fui-form__msg-bg':!getBgColor,'fui-form__msg-show':errorMsg}"><text
				class="fui-form__text" :style="{fontSize:size+'rpx',color:color}">{{errorMsg}}</text></view>
		<view class="fui-form__mask" v-if="disabled"></view>
	</view>
</template>

<script>
	import form from './fui-validator.js'
	export default {
		name: "fui-form",
		props: {
			model: {
				type: Object,
				default () {
					return {};
				}
			},
			//表单padding值（上，右，下，左），同css顺序
			padding: {
				type: Array,
				default () {
					return []
				}
			},
			//是否显示校验错误信息，设置false时，则触发formItem校验
			show: {
				type: Boolean,
				default: true
			},
			//是否禁用该表单内的所有组件,透明遮罩层
			disabled: {
				type: Boolean,
				default: false
			},
			//提示框top值 px
			top: {
				type: [Number, String],
				// #ifdef H5
				default: 44
				// #endif
				// #ifndef H5
				default: 0
				// #endif
			},
			left: {
				type: [Number, String],
				default: 24
			},
			right: {
				type: [Number, String],
				default: 24
			},
			//错误提示框背景色
			background: {
				type: String,
				default: ''
			},
			//错误提示字体大小
			size: {
				type: [Number, String],
				default: 28
			},
			//错误提示字体颜色
			color: {
				type: String,
				default: '#fff'
			},
			//错误提示框圆角值
			radius: {
				type: [Number, String],
				default: 16
			},
			//错误消息显示时间 ms
			duration: {
				type: Number,
				default: 2000
			},
			//form-item标题字体大小 默认使用全局设置值
			labelSize: {
				type: [Number, String],
				default: 0
			},
			labelColor: {
				type: String,
				default: ''
			},
			//form-item label宽度,单位rpx 默认使用全局设置值
			labelWidth: {
				type: [Number, String],
				default: 0
			},
			//label 对齐方式：left，right
			labelAlign: {
				type: String,
				default: ''
			},
			labelWeight: {
				type: [Number, String],
				default: 0
			},
			// form-item 必填项星号颜色
			asteriskColor: {
				type: String,
				default: ''
			},
			//left,right
			asteriskPosition: {
				type: String,
				default: ''
			},
			//v2.1.0+ 1-absolute 2-relative
			errorPosition: {
				type: [Number, String],
				default: 1
			},
			//v2.1.0+ left/center/right
			errorAlign: {
				type: String,
				default: 'center'
			}
		},
		provide() {
			return {
				form: this
			}
		},
		computed: {
			getBgColor() {
				let color = this.background;
				// #ifdef APP-NVUE
				if (!color || color === true) {
					const app = uni && uni.$fui && uni.$fui.color;
					color = (app && app.danger) || '#FF2B2B';
				}
				// #endif
				return color;
			}
		},
		watch: {
			/* // 备用方案，暂时未启用
			model: {
				handler: function(vals, oldVal) {
					if (this.children && vals && !this.show) {
						this.children.forEach(item => {
							if (item.prop && item.prop !== true) {
								item.setValue(vals[item] || '')
							}
						})
					}
				},
				deep: true
			},
			*/
			show(val) {
				if (this.children && this.children.length > 0) {
					this.children.forEach(item => {
						item.showError = val ? false : true
					})
				}
			}
		},
		data() {
			return {
				errorMsg: '',
				timer: null,
				rules: []
			};
		},
		created() {
			this.children = []
		},
		// #ifndef VUE3
		beforeDestroy() {
			this.clearTimer()
		},
		// #endif
		// #ifdef VUE3
		beforeUnmount() {
			this.clearTimer()
		},
		// #endif
		methods: {
			clearTimer() {
				this.children = null
				clearTimeout(this.timer)
				this.timer = null;
			},
			/*
			 @param model 表单数据对象
			 @param rules 表单验证规则
			 @param checkAll 校验所有元素，结合FormItem组件显示校验提示时必须传true
			*/
			validator(model, rules, checkAll = false) {
				return new Promise((resolve, reject) => {
					try {
						let res = form.validator(model, rules, checkAll);
						if (!res.isPassed) {
							let errors = res.errorMsg;
							if (this.show) {
								this.clearTimer()
								if (checkAll) {
									errors = errors[0].msg
								}
								this.errorMsg = errors;
								this.timer = setTimeout(() => {
									this.errorMsg = ''
								}, this.duration)
							} else {
								if (checkAll) {
									//formItem 显示提示
									if (this.children && this.children.length > 0) {
										this.children.forEach(item => {
											const index = errors.findIndex(err => err.name === item.prop)
											if (item.prop && item.prop !== true && ~index) {
												item.errorMsg = errors[index].msg
												item.itemValue = this.model[item.prop]
											}
										})
									}
								}
							}
						}
						resolve(res)
					} catch (e) {
						reject({
							isPassed: false,
							errorMsg: '校验出错，请检查传入的数据格式是否有误！'
						})
					}
				})
			},
			//v2.1.0+ 通知formItem组件重置props参数
			resetFormItemParam() {
				if (this.children && this.children.length > 0) {
					this.children.forEach(item => {
						item.initParam(true)
					})
				}
			},
			//v2.1.0+ 通知formItem组件开启实时校验
			switchRealTimeValidator(isOpen, rules = []) {
				if (this.children && this.children.length > 0) {
					if (isOpen) {
						this.rules = rules || []
					}
					this.children.forEach(item => {
						item.switchRealTimeValidator(isOpen)
					})
				}
			},
			//内部方法，提供给FormItem组件使用
			realTimeValidator(prop) {
				return new Promise((resolve, reject) => {
					try {
						let res = form.validator(this.model, this.rules, true);
						if (!res.isPassed) {
							//formItem 显示提示
							let errors = res.errorMsg;
							const index = errors.findIndex(err => err.name === prop)
							if (~index) {
								res.errorMsg = errors[index].msg
							} else {
								res.isPassed = true
								res.errorMsg = ''
							}
						}
						resolve(res)
					} catch (e) {
						reject({
							isPassed: false,
							errorMsg: '校验出错，请检查传入的数据格式是否有误！'
						})
					}
				})
			}
		}
	}
</script>

<style scoped>
	.fui-form__wrap {
		/* #ifndef APP-NVUE */
		width: 100%;
		box-sizing: border-box;
		/* #endif */
		flex: 1;
		position: relative;
	}

	.fui-form__msg-wrap {
		padding: 24rpx;
		position: fixed;
		z-index: 900;
		text-align: center;
		/* #ifndef APP-NVUE */
		box-sizing: border-box;
		display: flex;
		word-break: break-all;
		/* #endif */
		align-items: center;
		justify-content: center;
		opacity: 0;

		/* #ifdef APP-NVUE */
		transform: translateY(-100%);
		transition-property: transform, opacity;
		/* #endif */
		/* #ifndef APP-NVUE */
		transform: translate3d(0, -100%, 0);
		visibility: hidden;
		transition-property: all;
		/* #endif */
		transition-duration: 0.25s;
		transition-delay: 0s;
		transition-timing-function: ease-in-out;
	}

	/* #ifndef APP-NVUE */
	.fui-form__msg-bg {
		background: var(--fui-color-danger, #FF2B2B) !important;
	}

	/* #endif */

	.fui-form__text {
		text-align: center;
	}

	.fui-form__msg-show {
		/* #ifndef APP-NVUE */
		visibility: visible;
		transform: translate3d(0, 0, 0);
		/* #endif */
		/* #ifdef APP-NVUE */
		transform: translateY(0);
		/* #endif */
		opacity: 1;
	}

	.fui-form__mask {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: rgba(0, 0, 0, 0);
		z-index: 99;
	}
</style>