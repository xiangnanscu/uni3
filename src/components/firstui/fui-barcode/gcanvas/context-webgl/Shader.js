// 本文件由FirstUI授权予江安红云智慧科技有限公司（手机号： 1996  0 0     90 760，身份证尾号：4 9   7 824）专用，请尊重知识产权，勿私下传播，违者追究法律责任。
import {getTransferedObjectUUID} from './classUtils';

const name = 'WebGLShader';

function uuid(id) {
    return getTransferedObjectUUID(name, id);
}

export default class WebGLShader {
    className = name;

    constructor(id, type) {
        this.id = id;
        this.type = type;
    }

    static uuid = uuid;

    uuid() {
        return uuid(this.id);
    }
}