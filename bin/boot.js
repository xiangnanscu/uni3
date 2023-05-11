const fs = require("fs");
const util = require("util");
const exec = util.promisify(require("child_process").exec);
const path = require("path");

const execIgnoreError = async (s) => {
  try {
    return await exec(s);
  } catch (error) {
    console.log("execIgnoreError:", error.message);
    return false;
  }
};
const random = (length = 8) => {
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let str = "";
  for (let i = 0; i < length; i++) {
    str += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return str;
};

const renderTemplate = (src, dest, ctx) => {
  let srcString = fs.readFileSync(src, { flag: "r" }).toString();
  for (const [key, value] of Object.entries(ctx)) {
    const reg = "\\{\\{\\s*" + key + "\\s*\\}\\}";
    srcString = srcString.replaceAll(new RegExp(reg, "g"), value);
  }
  srcString = srcString
    .split("\n")
    .map((line) => line.replaceAll(/^\s*\/\/.+$/g, ""))
    .filter((line) => line)
    .join("\n");
  if (dest) {
    fs.writeFileSync(dest, srcString);
  }
  return srcString;
};

// console.log("process.env.NODE_ENV", process.env.NODE_ENV)
const appName = path.basename(process.cwd());
const isProduction = process.env.NODE_ENV == "production";
async function main() {
  if (isProduction) {
    await exec("cp bin/template/post-receive .git/hooks");
    await exec("cp .git/hooks/post-receive .git/hooks/post-merge");
  }
  const pgCtx = {
    VITE_APP_NAME: appName,
    PGUSER: process.env.PGUSER || "postgres",
    PGPASSWORD:
      process.env.PGPASSWORD ||
      (process.env.PG_USE_RANDOM ? random(20) : "postgres"),
    PGDATABASE: process.env.PGDATABASE || appName,
  };
  renderTemplate("bin/template/.env", ".env", {
    ...pgCtx,
  });
  renderTemplate("bin/template/.env.local", ".env.local", {
    ...pgCtx,
    ALI_PAY_KEY: "",
    ALI_PAY_SECRET: "",
    ALIOSS_KEY: "",
    ALIOSS_SECRET: "",
    ALI_DM_KEY: "",
    ALI_DM_SECRET: "",
    ALI_SMS_KEY: "",
    ALI_SMS_SECRET: "",
    NGINX_client_max_body_size: "10m",
    NGINX_client_body_buffer_size: "10m",
    NGINX_USE_HTTPS:
      process.env.NGINX_USE_HTTPS || (isProduction ? "on" : "off"),
    NGINX_server_name:
      process.env.NGINX_server_name ||
      (isProduction ? `${appName}.jahykj.cn` : "localhost"),
    NGINX_encrypted_session_key: random(32),
    NGINX_encrypted_session_iv: random(16),
    NGINX_encrypted_session_expires:
      process.env.NGINX_encrypted_session_expires ||
      (isProduction ? "30d" : "300d"),
    NGINX_worker_connections:
      process.env.NGINX_worker_connections || (isProduction ? 10240 : 1024),
    NGINX_lua_code_cache:
      process.env.NGINX_lua_code_cache || (isProduction ? "on" : "off"),
    NGINX_listen: process.env.NGINX_listen || (isProduction ? "80" : "8000"),
    NGINX_RATE_LIMIT:
      process.env.NGINX_RATE_LIMIT || (isProduction ? "20" : "8000"),
  });
  // renderTemplate("bin/template/pg.sql", "bin/pg.sql", pgCtx);
  //   await execIgnoreError(`sudo -u postgres psql -w postgres <<EOF
  //     ALTER USER postgres PASSWORD 'postgres';
  // EOF`);
  await execIgnoreError("mkdir logs");
  await execIgnoreError("echo '{}' > settings.json");
  return "done";
}

main().then((res) => {
  console.log(res);
});
