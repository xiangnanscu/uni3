const fs = require("fs");
const path = require("path");
const os = require("os");
const packageJson = require("../package.json");

const version = packageJson.version;

const LINE =
  /(?:^|^)\s*(?:export\s+)?([\w.-]+)(?:\s*=\s*?|:\s+?)(\s*'(?:\\'|[^'])*'|\s*"(?:\\"|[^"])*"|\s*`(?:\\`|[^`])*`|[^#\r\n]+)?\s*(?:#.*)?(?:$|$)/gm;

// Parser src into an Object
function parse(src) {
  const obj = {};

  // Convert buffer to string
  let lines = src.toString();

  // Convert line breaks to same format
  lines = lines.replace(/\r\n?/gm, "\n");

  let match;
  while ((match = LINE.exec(lines)) != null) {
    const key = match[1];

    // Default undefined or null to empty string
    let value = match[2] || "";

    // Remove whitespace
    value = value.trim();

    // Check if double quoted
    const maybeQuote = value[0];

    // Remove surrounding quotes
    value = value.replace(/^(['"`])([\s\S]*)\1$/gm, "$2");

    // Expand newlines if double quoted
    if (maybeQuote === '"') {
      value = value.replace(/\\n/g, "\n");
      value = value.replace(/\\r/g, "\r");
    }

    // Add to object
    obj[key] = value;
  }

  return obj;
}

function _log(message) {
  console.log(`[dotenv@${version}][DEBUG] ${message}`);
}

function _resolveHome(envPath) {
  return envPath[0] === "~"
    ? path.join(os.homedir(), envPath.slice(1))
    : envPath;
}

// Populates process.env from .env file
function config(options) {
  let dotenvPath = path.resolve(process.cwd(), ".env");
  let encoding = "utf8";
  const debug = Boolean(options && options.debug);
  const override = Boolean(options && options.override);

  if (options) {
    if (options.path != null) {
      dotenvPath = _resolveHome(options.path);
    }
    if (options.encoding != null) {
      encoding = options.encoding;
    }
  }

  try {
    // Specifying an encoding returns a string instead of a buffer
    const parsed = DotenvModule.parse(
      fs.readFileSync(dotenvPath, { encoding })
    );

    Object.keys(parsed).forEach(function (key) {
      if (!Object.prototype.hasOwnProperty.call(process.env, key)) {
        process.env[key] = parsed[key];
      } else {
        if (override === true) {
          process.env[key] = parsed[key];
        }

        if (debug) {
          if (override === true) {
            _log(
              `"${key}" is already defined in \`process.env\` and WAS overwritten`
            );
          } else {
            _log(
              `"${key}" is already defined in \`process.env\` and was NOT overwritten`
            );
          }
        }
      }
    });

    return expand({ parsed });
  } catch (e) {
    if (debug) {
      _log(`Failed to load ${dotenvPath} ${e.message}`);
    }

    return { error: e };
  }
}

const DotenvModule = {
  config,
  parse,
};

function _interpolate(envValue, environment, config) {
  const matches = envValue.match(/(.?\${*[\w]*(?::-[\w/]*)?}*)/g) || [];
  return matches.reduce(function (newEnv, match, index) {
    const parts = /(.?)\${*([\w]*(?::-[\w/]*)?)?}*/g.exec(match);
    if (!parts || parts.length === 0) {
      return newEnv;
    }
    const prefix = parts[1];

    let value, replacePart;

    if (prefix === "\\") {
      replacePart = parts[0];
      value = replacePart.replace("\\$", "$");
    } else {
      const keyParts = parts[2].split(":-");
      const key = keyParts[0];
      replacePart = parts[0].substring(prefix.length);
      // process.env value 'wins' over .env file's value
      value = Object.prototype.hasOwnProperty.call(environment, key)
        ? environment[key]
        : config.parsed[key] || keyParts[1] || "";

      // If the value is found, remove nested expansions.
      if (keyParts.length > 1 && value) {
        const replaceNested = matches[index + 1];
        matches[index + 1] = "";

        newEnv = newEnv.replace(replaceNested, "");
      }
      // Resolve recursive interpolations
      value = _interpolate(value, environment, config);
    }

    return newEnv.replaceAll(replacePart, value);
  }, envValue);
}

function expand(config) {
  // if ignoring process.env, use a blank object
  const environment = config.ignoreProcessEnv ? {} : process.env;

  for (const configKey in config.parsed) {
    const value = Object.prototype.hasOwnProperty.call(environment, configKey)
      ? environment[configKey]
      : config.parsed[configKey];

    config.parsed[configKey] = _interpolate(value, environment, config);
  }

  for (const processKey in config.parsed) {
    environment[processKey] = config.parsed[processKey];
  }

  return config;
}

console.log(config());
module.exports.expand = expand;
module.exports.config = DotenvModule.config;
module.exports.parse = DotenvModule.parse;
module.exports = DotenvModule;
