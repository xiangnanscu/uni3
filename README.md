# xodel

- wget https://raw.githubusercontent.com/xiangnanscu/wsl/master/pre-install.sh && chmod a+x pre-install.sh && ./pre-install.sh
- wget https://raw.githubusercontent.com/xiangnanscu/wsl/master/install.sh && chmod a+x install.sh && ./install.sh

```
<template>
  <page-layout>
    <!-- #ifdef MP-WEIXIN -->
    <LoginWx />
    <!-- #endif -->
    <!-- #ifdef H5 -->
    <LoginH5 />
    <!-- #endif -->
  </page-layout>
</template>

<script setup>
import LoginH5 from "./LoginH5.vue";
import LoginWx from "./LoginWx.vue";
const store = useStore();
store.message = "请先登陆";
</script>

```

# win10 配置 yarn script 使用 bash shell

```
yarn config set script-shell /usr/bin/bash
```

# 日志解析

# GIT

insert into usr(xm,username,nickname,password,permission) values ('项楠','51152319870713001X','NAN','1111',3);

## 从历史中删除某个文件

```sh
git filter-branch --index-filter  'git rm -rf --cached --ignore-unmatch lualib/xodel/model.lua' HEAD
```

## 一键解析远程服务器的 LOG

```sh
ssh root@jarsj.cn 'zcat /root/works/logs/access*.gz' | goaccess --log-format='%h [%d:%t %^] "%r" %s %b "%R" "%u" %T' --date-format=%d/%b/%Y --time-format=%T -o dist/stat.html
```

## 本地解析

```sh
cat /root/works/logs/access.log | goaccess --log-format='%h [%d:%t %^] "%r" %s %b "%R" "%u" %T' --date-format=%d/%b/%Y --time-format=%T -o dist/localstat.html
```

## 重置 win10 网络条件

突然 git 和 sshuttle 各种不好使了, 例如 git kex_exchange_identification: Connection closed by remote host, 网上搜了一下,运行下列命令, 重启电脑, 搞定

```sh
netsh winsock reset
netsh int ip reset
ipconfig /release
ipconfig /renew
ipconfig /flushdns
```

## let's encrypt

```
sudo apt update
sudo apt install snapd -y
sudo snap install core; sudo snap refresh core
apt-get remove certbot -y
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
certbot certonly --webroot -w /root/jaqn/dist -d gqtjaxw.cn
sudo certbot renew --dry-run
```

### 相关定时文件

/etc/systemd/system/snap.certbot.renew.service

```
[Unit]
# Auto-generated, DO NOT EDIT
Description=Service for snap application certbot.renew
Requires=snap-certbot-2913.mount
Wants=network.target
After=snap-certbot-2913.mount network.target snapd.apparmor.service
X-Snappy=yes

[Service]
EnvironmentFile=-/etc/environment
ExecStart=/usr/bin/snap run --timer="00:00~24:00/2" certbot.renew
SyslogIdentifier=certbot.renew
Restart=no
WorkingDirectory=/var/snap/certbot/2913
TimeoutStopSec=30
Type=oneshot
```

/etc/systemd/system/snap.certbot.renew.timer

```
[Unit]
# Auto-generated, DO NOT EDIT
Description=Timer renew for snap application certbot.renew
Requires=snap-certbot-2913.mount
After=snap-certbot-2913.mount
X-Snappy=yes

[Timer]
Unit=snap.certbot.renew.service
OnCalendar=*-*-* 07:49
OnCalendar=*-*-* 15:48

[Install]
WantedBy=timers.target

```

## 企业微信内网穿透

安装

```
wget https://dldir1.qq.com/wework/wwopen/developer/wecom-tunnel/linux-x64/tunnel.gz
gzip -d tunnel.gz
./tunnel config set auth sqXwAcIapccAkn-lGEaFl9HeaPprtIGpZYvx-d9InSAhwofvu0N7Y4VEoW5V0yq
./tunnel config set port 8000
./tunnel config set commandCallback /wxqy_directives
./tunnel config set dataCallback /wxqy_events
```

配置

```
{
	"auth": "sqXwAcIapccAkn-lGEaFl9HeaPprtIGpZYvx-d9InSAhwofvu0N7Y4VEoW5V0yq",
	"ip": "127.0.0.1",
	"port": "8000",
	"dataCallback": "/wxqy_events",
	"commandCallback": "/wxqy_directives",
	"debug": "false"
}
```
