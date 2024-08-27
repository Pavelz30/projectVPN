#!/bin/bash 

# Installation OpenVPN Exporter 
# https://github.com/kumina/openvpn_exporter

projectdir=~/projectVPN/monitoring/prometheus/exporters
systemddir=/etc/systemd/system

if [ "$(ps -p 1 -o comm=)" != "systemd" ];
then
	echo "Вы не используете systemd!"
	exit 1
fi

if [ -f /usr/local/bin/openvpn_exporter ] || [ -f $systemddir/openvpn_exporter.service ];
then
	echo -n "Возможно, у вас уже установлен OpenVPN Exporter. Введите 'force' чтобы удалить все конфликтующие файлы, иначе 'none': "
	read var
	if [ "$var" == "force" ];
	then
		sudo rm -rf /usr/local/bin/openvpn_exporter
	else
		echo -e "\nУстраните конфликтующие файлы и перезапустите скрипт!"
		echo -e "$systemddir/openvpn_exporter.service\n/usr/local/bin/openvpn_exporter"
		exit 1
	fi
fi

cd $projectdir && sudo cp -f ./openvpn_exporter /usr/local/bin

sudo cp $projectdir/openvpn_exporter.service $systemddir/ 
sudo systemctl enable openvpn_exporter.service &> /dev/null && \
       	sudo systemctl start openvpn_exporter.service &> /dev/null && \
	sudo systemctl daemon-reload

echo -e "\nSystemd-unit для OpenVPN Exporter -> $systemddir/openvpn_exporter.service"
echo -e "Используй 'sudo systemctl status openvpn_exporter.service' для проверки состояния сервиса!"
