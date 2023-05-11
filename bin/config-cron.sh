if [ -z $APP_NAME ]; then
  read -p "please provide app name:" APP_NAME
fi
echo -e "10 5 * * * root cd ~/$APP_NAME && bin/pg-backup.py\n" >> /etc/crontab
echo -e "20 5 * * * root cd ~/$APP_NAME && bin/goaccess-stat.sh\n" >> /etc/crontab
# echo "cron.* /var/log/cron.log" >> cron.* /var/log/cron.log
# service rsyslog restart
service cron reload