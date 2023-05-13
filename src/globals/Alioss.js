import { nanoid } from "nanoid"
import { Axios } from "@/globals/Axios";

const ALIOSS_PAYLOAD_URL = process.env.ALIOSS_PAYLOAD_URL;
const ALIOSS_SIZE = process.env.ALIOSS_SIZE;
const ALIOSS_LIFETIME = process.env.ALIOSS_LIFETIME;
const ALIOSS_UPLOAD_PREFIX = process.env.ALIOSS_UPLOAD_PREFIX;
const ALIOSS_URL = process.env.ALIOSS_URL;

const imgExtMap = {
  "image/bmp": "bmp",
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/tiff": "tif",
  "image/webp": "webp",
  "image/vnd.microsoft.icon": "ico",
};
const videoExtMap = {
  "video/mp4": "mp4",
  "video/x-msvideo": "avi",
  "video/quicktime": "mov",
  "video/x-ms-wmv": "wmv",
  "video/x-flv": "flv",
  "video/mpeg": "mpeg",
  "video/webm": "webm",
  "video/x-matroska": "mkv",
  "video/3gpp": "3gp",
  "video/ogg": "ogg"
}
// interface aliossOpts {
//   size?: string | number;
//   key?: string;
//   lifetime?: string | number;
//   key_id?: string;
//   key_secret?: string;
// }
// interface aliossAntdImage {
//   uid: string;
//   type: keyof typeof imgExtMap;
//   name: string;
//   ossUrl?: string;
// }
// interface File extends Blob {
//   readonly lastModified: number;
//   readonly name: string;
//   readonly webkitRelativePath: string;
// }
class Alioss {
  static getPayload = async (opts) => {
    const { data } = await Axios.post(ALIOSS_PAYLOAD_URL, {
      size: ALIOSS_SIZE,
      lifetime: ALIOSS_LIFETIME,
      ...opts,
    });
    return data;
  };
  static getOssVideoKey = (file) => {
    return `${ALIOSS_UPLOAD_PREFIX}/video/${nanoid()}.${videoExtMap[file.type] || file.name.split(".").pop()
      }`
  }
  static async uploadVideo({ file, url, data, config, size }) {
    const formData = new FormData();
    const ossKey = Alioss.getOssVideoKey(file)
    for (const [key, value] of Object.entries({ ...data, ...await Alioss.getPayload({ size }), key: ossKey, file })) {
      formData.append(key, value)
    }
    await Axios.post(
      url || ALIOSS_URL,
      formData,
      {
        method: "POST",
        headers: { "X-Requested-With": "XMLHttpRequest", 'Content-Type': 'multipart/form-data' },
        params: {
          t: new Date().getTime(),
        },
        responseType: "json", // 'arraybuffer', 'document', 'json', 'text', 'stream','blob'
        responseEncoding: "utf8",
        ...config,
      });
    return `${ALIOSS_URL}${ossKey}`
  }
  static antdDataCallback = async (file) => {
    const ext = imgExtMap[file.type] || file.name.split(".").pop()
    const key = `${ALIOSS_UPLOAD_PREFIX}/${file.uid}.${ext}`;
    const payload = await this.getPayload({
      key,
      size: ALIOSS_SIZE,
      lifetime: ALIOSS_LIFETIME,
    });
    payload.key = key;
    file.ossUrl = `${ALIOSS_URL}${key}`;
    return payload;
  };
  static makeAntdDataCallback = (field) => async (file) => {
    const ext = imgExtMap[file.type] || file.name.split(".").pop()
    const key = `${ALIOSS_UPLOAD_PREFIX}/${file.uid}.${ext}`;
    const payload = await this.getPayload({
      key,
      size: field.size || ALIOSS_SIZE,
      lifetime: field.lifetime || ALIOSS_LIFETIME,
    });
    payload.key = key;
    file.ossUrl = `${ALIOSS_URL}${key}`;
    return payload;
  };
}

export { Alioss };
