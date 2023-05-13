import { Buffer } from "buffer";
import Model from "@/model.mjs";

export { Model };
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
export const repr = (s) => JSON.stringify(s);
export const fromNow = (value) => {
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
  } else {
    return value.slice(0, 10);
  }
};
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
        return false
      }
    }
  }
  return true
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
  return objectContains(a, b) && objectContains(b, a)
}
const sizeTable = {
  k: 1024,
  m: 1024 * 1024,
  g: 1024 * 1024 * 1024,
  kb: 1024,
  mb: 1024 * 1024,
  gb: 1024 * 1024 * 1024
};
export function byteSizeParser(t) {
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