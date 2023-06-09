import { Buffer } from "buffer";
import pagesJson from "@/pages.json";

export function isWeixin() {
  var ua = navigator.userAgent.toLowerCase();
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
  var curTime = new Date();
  var postTime = new Date(value);
  //计算差值
  var timeDiff = curTime.getTime() - postTime.getTime();
  // 单位换算
  var min = 60 * 1000;
  var hour = min * 60;
  var day = hour * 24;
  // 计算发布时间距离当前时间的 天、时、分
  var exceedDay = Math.floor(timeDiff / day);
  var exceedHour = Math.floor(timeDiff / hour);
  var exceedMin = Math.floor(timeDiff / min);
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
  var already = {};
  var res = [];
  for (var i = 1; i <= arr.length; i++) {
    var e = arr[i - 1];
    var k = callback(e, i, arr);
    var a = already[k];
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
const toURLSearchParams = (obj) => {
  return Object.entries(obj)
    .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
    .join("&");
};
const appendAnimationParams = (opts) => {
  return { animationType: "pop-out", animationDuration: 200, ...opts };
};
export function getPage(delta = 0) {
  const pages = getCurrentPages();
  const page = pages[pages.length - delta - 1];
  return page;
}
export function getLastPageUrl() {
  const lastPage = getPage(1);
  // lastPage.$page.fullPath
  return lastPage ? "/" + lastPage.route : UNI_HOME_PAGE;
}

const tabbarPages = pagesJson.tabBar?.list;
const tabbarPagesMap = Object.fromEntries(
  tabbarPages.map((e) => [`/${e.pagePath}`, true])
);
export async function gotoPage(opts) {
  let url = opts.url;
  if (opts.query) {
    url = url + "?" + toURLSearchParams(opts.query); // % &=/@;$:+?#
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
    // console.log("tryGotoPage", getCurrentPages(), { lastUrl });
    return await gotoPage({
      url: lastUrl
    });
  }
  await gotoPage(opts);
}
