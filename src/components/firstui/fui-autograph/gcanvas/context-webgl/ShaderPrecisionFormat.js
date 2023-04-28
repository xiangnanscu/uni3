// 本文件由FirstUI授权予江安红云智慧科技有限公司（手机号：19  9  6 0  09 0 76 0，身份证尾号：4   978 2 4）专用，请尊重知识产权，勿私下传播，违者追究法律责任。
export default class WebGLShaderPrecisionFormat {
    className = 'WebGLShaderPrecisionFormat';

    constructor({
        rangeMin, rangeMax, precision
    }) {
        this.rangeMin = rangeMin;
        this.rangeMax = rangeMax;
        this.precision = precision;
    }
}