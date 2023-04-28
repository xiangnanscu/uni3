// 本文件由FirstUI授权予江安红云智慧科技有限公司（手机号：1  9 9600  90  76   0，身份证尾号： 49 7   824）专用，请尊重知识产权，勿私下传播，违者追究法律责任。
/*
  组件属性全局配置文件。优先级：全局配置文件props < 直接设置组件props
  目前支持配置的组件：fui-button、fui-icon、fui-text、fui-input、fui-form-item
*/

const fuiConfig = {
	//组件名称，小驼峰命名
	//如fui-button写成fuiButton
	fuiButton: {
		//组件属性值
		height: '96rpx',
		size: 32,
		radius: '16rpx'
	},
	fuiIcon: {
		size: 64,
		unit: 'rpx'
	},
	fuiText: {
		size: 32,
		unit: 'rpx'
	},
	fuiInput: {
		labelSize: 32,
		size: 32
	},
	fuiFormItem: {
		labelSize: 32,
		labelWidth: 160,
		labelRight: 30,
		labelAlign: 'left',
		asteriskPosition: 'left'
	}
}

export default fuiConfig