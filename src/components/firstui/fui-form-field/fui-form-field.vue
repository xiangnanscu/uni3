<!--本文件由FirstUI授权予江安红云智慧科技有限公司（手机号：19   9 60  09 07 6  0，身份证尾号：49 78   2 4）专用，请尊重知识产权，勿私下传播，违者追究法律责任。-->
<template>
	<view :class="{'fui-form__field':hidden}">
		<slot></slot>
	</view>
</template>

<script>
	//此组件只为form表单提交传递数据使用，暂时用于微信小程序/百度小程序/QQ小程序
	export default {
		name: "fui-form-field",
		// #ifndef VUE3
		behaviors: ['uni://form-field'],
		// #endif
		props: {
			//是否为隐藏域
			hidden: {
				type: Boolean,
				default: false
			}
		}
	}
</script>

<style scoped>
	.fui-form__field {
		display: none;
		opacity: 0;
	}
</style>