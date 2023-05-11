if [ -z $APP_NAME ]; then
  read -p "please provide app name:" APP_NAME
fi
cat > /etc/logrotate.d/nginx << EOF
/root/$APP_NAME/logs/*.log {
  size 2M
  rotate 65535
  missingok
  notifempty
  compress
  sharedscripts
  postrotate
    [ ! -f /root/$APP_NAME/logs/nginx.pid ] || kill -USR1 \`cat /root/$APP_NAME/logs/nginx.pid\`
  endscript
}
EOF