#!/bin/bash

# node bin/make-env.js > conf/env.json
# resty -I ./lualib bin/make_env_snippet.lua > conf/env.conf
# resty -I ./lualib bin/make_set_snippet.lua > conf/set.conf
yarn resty bin/make_conf.lua |grep -Ev "^\\s*#[^#]*$" |grep -Ev "^\\s*$"|grep -Ev "^\\$" > conf/nginx.conf
