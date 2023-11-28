// import postgres from "postgres";
export const IS_PG_KEYWORDS = {
  EQ: true,
  NOTIN: true,
  CONTAINS: true,
  STARTSWITH: true,
  ENDSWITH: true,
  LT: true,
  LTE: true,
  GT: true,
  GTE: true,
  NE: true,
  ALL: true,
  ANALYSE: true,
  ANALYZE: true,
  AND: true,
  ANY: true,
  ARRAY: true,
  AS: true,
  ASC: true,
  ASYMMETRIC: true,
  AUTHORIZATION: true,
  BINARY: true,
  BOTH: true,
  CASE: true,
  CAST: true,
  CHECK: true,
  COLLATE: true,
  COLLATION: true,
  COLUMN: true,
  CONCURRENTLY: true,
  CONSTRAINT: true,
  CREATE: true,
  CROSS: true,
  CURRENT_CATALOG: true,
  CURRENT_DATE: true,
  CURRENT_ROLE: true,
  CURRENT_SCHEMA: true,
  CURRENT_TIME: true,
  CURRENT_TIMESTAMP: true,
  CURRENT_USER: true,
  DEFAULT: true,
  DEFERRABLE: true,
  DESC: true,
  DISTINCT: true,
  DO: true,
  ELSE: true,
  END: true,
  EXCEPT: true,
  FALSE: true,
  FETCH: true,
  FOR: true,
  FOREIGN: true,
  FREEZE: true,
  FROM: true,
  FULL: true,
  GRANT: true,
  GROUP: true,
  HAVING: true,
  ILIKE: true,
  IN: true,
  INITIALLY: true,
  INNER: true,
  INTERSECT: true,
  INTO: true,
  IS: true,
  ISNULL: true,
  JOIN: true,
  LATERAL: true,
  LEADING: true,
  LEFT: true,
  LIKE: true,
  LIMIT: true,
  LOCALTIME: true,
  LOCALTIMESTAMP: true,
  NATURAL: true,
  NOT: true,
  NOTNULL: true,
  NULL: true,
  OFFSET: true,
  ON: true,
  ONLY: true,
  OR: true,
  ORDER: true,
  OUTER: true,
  OVERLAPS: true,
  PLACING: true,
  PRIMARY: true,
  REFERENCES: true,
  RETURNING: true,
  RIGHT: true,
  SELECT: true,
  SESSION_USER: true,
  SIMILAR: true,
  SOME: true,
  SYMMETRIC: true,
  TABLE: true,
  TABLESAMPLE: true,
  THEN: true,
  TO: true,
  TRAILING: true,
  TRUE: true,
  UNION: true,
  UNIQUE: true,
  USER: true,
  USING: true,
  VARIADIC: true,
  VERBOSE: true,
  WHEN: true,
  WHERE: true,
  WINDOW: true,
  WITH: true,
};
export function _prefix_with_V(column) {
  return "V." + column;
}
export function dict(t1, t2) {
  return { ...t1, ...t2 };
}
export const capitalize = (s) => s.charAt(0).toUpperCase() + s.slice(1);
export const unique = (arr) => {
  return arr.filter((e, i) => arr.indexOf(e) === i);
};
export const getenv = (key) => "";
export const clone = (o) => (Array.isArray(o) ? [...o] : { ...o });
export const string_format = (s, ...varargs) => {
  let status = 0;
  const res = [];
  let j = -1;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (c === "%") {
      if (status === 0) {
        status = 1;
      } else if (status === 1) {
        status = 0;
        res.push("%");
      }
    } else if (c === "s" && status === 1) {
      j = j + 1;
      res.push(varargs[j]);
      status = 0;
    } else {
      res.push(c);
    }
  }
  return res.join("");
};
export function assert(bool, err_msg) {
  if (!bool) {
    throw new Error(err_msg);
  } else {
    return bool;
  }
}
export function next(obj) {
  for (const key in obj) {
    return key;
  }
}

export function make_token(s) {
  function raw_token() {
    return s;
  }
  Object.freeze(raw_token);
  return raw_token;
}

export const NULL = make_token("NULL");
export const DEFAULT = make_token("DEFAULT");

const sizeTable = {
  k: 1024,
  m: 1024 * 1024,
  g: 1024 * 1024 * 1024,
  kb: 1024,
  mb: 1024 * 1024,
  gb: 1024 * 1024 * 1024,
};
export function parse_size(t) {
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

export const FK_TYPE_NOT_DEFIEND = Object.freeze(Symbol("FK_TYPE_NOT_DEFIEND"));

export function get_localtime(date = new Date()) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  const seconds = String(date.getSeconds()).padStart(2, "0");

  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
}
export const ngx_localtime = get_localtime;
export const is_empty_object = (obj) => {
  for (var i in obj) {
    return false;
  }
  return true;
};

export function Query(options) {
  const postgres = () => [];
  options = Object.fromEntries(
    Object.entries(options).map(([k, v]) => [k.toLowerCase(), v]),
  );
  // console.log({ options });
  const sql_query = postgres({
    host: options.host || "localhost",
    port: options.port || "5432",
    database: options.database || "postgres",
    user: options.user || "postgres",
    password: options.password || "postgres",
    max: options.max || 20,
    idle_timeout: options.idle_timeout || 20,
    connect_timeout: options.connect_timeout || 2,
  });
  return async (statement) => {
    // console.log(statement);
    const result = await sql_query.unsafe(statement);
    // console.log(result);
    return result;
  };
}
