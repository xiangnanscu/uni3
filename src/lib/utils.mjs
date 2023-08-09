import { Buffer } from "buffer";
import pagesJson from "@/pages.json";
import { useSession } from "@/store/session";

export function isWeixin() {
  const ua = navigator.userAgent.toLowerCase();
  if (ua.match(/MicroMessenger/i) == "micromessenger") {
    return true;
  } else {
    return false;
  }
}
export function chunk(elements, n = 1) {
  const res = [];
  let unit = [];
  for (const e of elements) {
    if (unit.length === n) {
      res.push(unit);
      unit = [e];
    } else {
      unit.push(e);
    }
  }
  res.push(unit);
  return res;
}

export const capitalize = (s) => s.charAt(0).toUpperCase() + s.slice(1);
export const encodeBase64 = (s) =>
  Buffer.from(s, "utf-8")
    .toString("base64")
    .replace(/\//g, "_")
    .replace(/\+/g, "-");
export const decodeBase64 = (s) =>
  Buffer.from(s.replace(/_/g, "/").replace(/-/g, "+"), "base64").toString(
    "utf-8"
  );
export const repr = (s) => {
  const res = JSON.stringify(s);
  console.log(res);
  return res;
};
export const fromNow = (value) => {
  if (!value) {
    return "";
  }
  // 拿到当前时间戳和发布时的时间戳
  const curTime = new Date();
  const postTime = new Date(value);
  //计算差值
  const timeDiff = curTime.getTime() - postTime.getTime();
  // 单位换算
  const min = 60 * 1000;
  const hour = min * 60;
  const day = hour * 24;
  // 计算发布时间距离当前时间的 天、时、分
  const exceedDay = Math.floor(timeDiff / day);
  const exceedHour = Math.floor(timeDiff / hour);
  const exceedMin = Math.floor(timeDiff / min);
  // 最后判断时间差
  if (exceedDay < 1) {
    if (exceedHour < 24 && exceedHour > 0) {
      return exceedHour + "小时前";
    } else if (exceedMin < 60 && exceedMin > 0) {
      return exceedMin + "分钟前";
    } else {
      return "刚刚";
    }
  } else if (exceedDay < 7) {
    return `${exceedDay}天前`;
  } else if (curTime.getFullYear() == postTime.getFullYear()) {
    return value.slice(5, 10);
  } else {
    return value.slice(0, 10);
  }
};
export function uuid() {
  let timestamp = new Date().getTime();
  let perforNow =
    (typeof performance !== "undefined" &&
      performance.now &&
      performance.now() * 1000) ||
    0;
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    let random = Math.random() * 16;
    if (timestamp > 0) {
      random = (timestamp + random) % 16 | 0;
      timestamp = Math.floor(timestamp / 16);
    } else {
      random = (perforNow + random) % 16 | 0;
      perforNow = Math.floor(perforNow / 16);
    }
    return (c === "x" ? random : (random & 0x3) | 0x8).toString(16);
  });
}
const FIRST_DUP_ADDED = {};
export const findDups = (arr, callback) => {
  const already = {};
  const res = [];
  for (let i = 1; i <= arr.length; i++) {
    const e = arr[i - 1];
    const k = callback(e, i, arr);
    const a = already[k];
    if (a !== undefined) {
      if (a != FIRST_DUP_ADDED) {
        res.push(a);
        already[k] = FIRST_DUP_ADDED;
      }
      res.push(e);
    } else {
      already[k] = e;
    }
  }
  return res;
};
export function objectContains(a, b) {
  for (const key in b) {
    if (Object.hasOwnProperty.call(b, key)) {
      if (!isSame(a[key], b[key])) {
        return false;
      }
    }
  }
  return true;
}
export function isSame(a, b) {
  if (typeof a !== typeof b) {
    return false;
  }
  if (typeof a !== "object") {
    return a === b;
  }
  if (a instanceof Array && b instanceof Array) {
    if (a.length !== b.length) {
      return false;
    }
    for (let i = a.length - 1; i >= 0; i--) {
      if (!isSame(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  if (a instanceof Array || b instanceof Array) {
    return false;
  }
  return objectContains(a, b) && objectContains(b, a);
}
const sizeTable = {
  k: 1024,
  m: 1024 * 1024,
  g: 1024 * 1024 * 1024,
  kb: 1024,
  mb: 1024 * 1024,
  gb: 1024 * 1024 * 1024
};
export function parseSize(t) {
  if (typeof t === "string") {
    const unit = t.replace(/^(\d+)([^\d]+)$/, "$2").toLowerCase();
    const ts = t.replace(/^(\d+)([^\d]+)$/, "$1").toLowerCase();
    const bytes = sizeTable[unit];
    if (!bytes) throw new Error("invalid size unit: " + unit);
    const num = parseFloat(ts);
    if (isNaN(num)) throw new Error("can't convert `" + ts + "` to a number");
    return num * bytes;
  } else if (typeof t === "number") {
    return t;
  } else {
    throw new Error("invalid type: " + typeof t);
  }
}
const UNI_HOME_PAGE = process.env.UNI_HOME_PAGE;
export const toQueryString = (obj) => {
  return Object.entries(obj)
    .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
    .join("&");
};
const appendAnimationParams = (opts) => {
  return { animationType: "zoom-out", animationDuration: 200, ...opts };
};
export function getPage(delta = 0) {
  const pages = getCurrentPages();
  const page = pages[pages.length - delta - 1];
  return page;
}
export function getFullPath(delta = 0) {
  const page = getPage(delta);
  return page.$page?.fullPath;
}
export function getLastPageUrl() {
  const lastPage = getPage(1);
  return lastPage ? "/" + lastPage.route : UNI_HOME_PAGE;
}

const tabbarPages = pagesJson.tabBar?.list;
const tabbarPagesMap = Object.fromEntries(
  tabbarPages.map((e) => [`/${e.pagePath}`, true])
);
export const isTabbarPage = (url) => {
  if (!url) {
    const page = getPage();
    url = "/" + page.route;
  }
  return tabbarPagesMap[url];
};
const pagesMap = {};
for (const page of pagesJson.pages) {
  const name = page.path.split("/").pop();
  pagesMap[name] = "/" + page.path;
}
export async function gotoPage(params) {
  if (typeof params == "string") {
    params = params[0] == "/" ? { url: params } : { name: params };
  }
  const opts = { ...params };
  let url = opts.url;
  if (!url && opts.name) {
    url = pagesMap[opts.name];
  }
  if (!url) {
    throw new Error(`无效的页面参数:` + JSON.stringify(opts));
  }
  opts.url = url;
  if (opts.query) {
    url = url + "?" + toQueryString(opts.query); // % &=/@;$:+?#
  }
  const navParams = appendAnimationParams({ url });
  try {
    if (tabbarPagesMap[opts.url]) {
      await uni.switchTab(navParams);
    } else if (opts.redirect) {
      await uni.redirectTo(navParams);
    } else {
      await uni.navigateTo(navParams);
    }
    return true;
  } catch (error) {
    console.error("gotoPage error", error);
    // await uni.switchTab(tabbarPages[0]);
    return false;
  }
}
export async function tryGotoPage(opts) {
  if (!opts?.url) {
    if (opts?.redirect) {
      return await gotoPage({
        url: opts.redirect
      });
    }
    const lastUrl = getLastPageUrl();
    return await gotoPage({
      url: lastUrl
    });
  }
  await gotoPage(opts);
}
export const snakeToCamel = (s) => {
  return s.replace(/(_[a-zA-Z])/g, (c) => {
    return c[1].toUpperCase();
  });
};

export const toModelName = (s) => {
  return capitalize(snakeToCamel(s));
};

export const textDigest = (s, n = 10) => {
  return s.length <= n ? s : s.slice(0, n) + "...";
};

export const isLogin = () => {
  const sessionCookie = uni.getStorageSync("cookie_session");
  if (!sessionCookie) {
    return false;
  }
  const { session } = useSession();
  if (!session?.user?.id) {
    return false;
  }
  return true;
};

// 格式化数字，确保为两位数
function formatDigits(num) {
  return num < 10 ? `0${num}` : num;
}

export function getWeChatMessageTime(messageTime, now) {
  if (typeof messageTime == "string") {
    messageTime = new Date(messageTime);
  }
  now = now || new Date();
  const messageMonth = messageTime.getMonth();
  const year = messageTime.getFullYear();
  const hours = messageTime.getHours();
  const minutes = messageTime.getMinutes();
  const month = messageTime.getMonth() + 1;
  const day = messageTime.getDate();
  const period = hours < 12 ? "上午" : "下午";
  const currentDate = now.getDate();
  const currentMonth = now.getMonth();
  const currentYear = now.getFullYear();
  const hourMinutesText = `${formatDigits(hours)}:${formatDigits(minutes)}`;
  // 检查是否为今天
  if (
    day === currentDate &&
    messageMonth === currentMonth &&
    year === currentYear
  ) {
    return hourMinutesText;
  }
  // 检查是否为昨天
  const yesterday = new Date(now);
  yesterday.setDate(currentDate - 1);
  if (
    day === yesterday.getDate() &&
    messageMonth === yesterday.getMonth() &&
    year === yesterday.getFullYear()
  ) {
    return `昨天 ${hourMinutesText}`;
  }

  // 检查是否为今年内的其他日期
  if (year === currentYear) {
    // 添加上午、下午信息
    return `${month}月${day}日 ${period}${hourMinutesText}`;
  }
  return `${year}年${month}月${day}日 ${period}${hourMinutesText}`;
}
