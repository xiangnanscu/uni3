import { Axios } from "@/globals/Axios";

const ALIOSS_PAYLOAD_URL = process.env.ALIOSS_PAYLOAD_URL;
const ALIOSS_SIZE = process.env.ALIOSS_SIZE;
const ALIOSS_LIFETIME = process.env.ALIOSS_LIFETIME;
const ALIOSS_UPLOAD_PREFIX = process.env.ALIOSS_UPLOAD_PREFIX;
const ALIOSS_URL = process.env.ALIOSS_URL;

const extMap = {
  "image/bmp": "bmp",
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/tiff": "tif",
  "image/webp": "webp",
  "image/vnd.microsoft.icon": "ico",
};
interface aliossOpts {
  size?: string | number;
  key?: string;
  lifetime?: string | number;
  key_id?: string;
  key_secret?: string;
}
interface aliossFile {
  uid: string;
  type: keyof typeof extMap;
  name: string;
  ossUrl?: string;
}
class Alioss {
  static getPayload = async (opts: aliossOpts) => {
    const { data } = await Axios.post(ALIOSS_PAYLOAD_URL, {
      size: ALIOSS_SIZE,
      lifetime: ALIOSS_LIFETIME,
      ...opts,
    });
    return data;
  };
  static antdDataCallback = async (file: aliossFile) => {
    const key = `${ALIOSS_UPLOAD_PREFIX}/${file.uid}.${
      extMap[file.type] || file.name.split(".").pop()
    }`;
    const payload = await this.getPayload({
      key,
      size: ALIOSS_SIZE,
      lifetime: ALIOSS_LIFETIME,
    });
    payload.key = key;
    file.ossUrl = `${ALIOSS_URL}${key}`;
    return payload;
  };
}

export { Alioss };
