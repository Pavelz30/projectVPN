#!/bin/bash -e 

# Installation Node Exporter

if [ $# -ne 1 ];
then
	echo "Требуется один параметр - версия Node Exporter!"
	echo "https://prometheus.io/download/"
	exit 1
fi

version=$1
workdir=~/node_exporter-$version.linux-amd64
projectdir=~/projectVPN/monitoring/prometheus/exporters
systemddir=/etc/systemd/system

if [ "$(ps -p 1 -o comm=)" != "systemd" ];
then
	echo "Вы не используете systemd!"
	exit 1
fi

if [ -f /usr/local/bin/node_exporter ] || [ -f $systemddir/node_exporter.service ];
then
	echo -n "Возможно, у вас уже установлен Node Exporter. Введите 'force' чтобы удалить все конфликтующие файлы, иначе 'none': "
	read var
	if [ "$var" == "force" ];
	then
		sudo rm -rf /usr/local/bin/node_exporter
	else
		echo -e "\nУстраните конфликтующие файлы и перезапустите скрипт!"
		echo -e "$systemddir/node_exporter.service\n/usr/local/bin/node_exporter"
		exit 1
	fi
fi

cd ~/ && wget https://github.com/prometheus/node_exporter/releases/download/v$version/node_exporter-$version.linux-amd64.tar.gz &> /dev/null || (echo "Не удалось скачать файл, проверьте введенную версию версию!" && exit 1)

tar -xf node_exporter-$version.linux-amd64.tar.gz && rm -rf node_exporter-$version.linux-amd64.tar.gz

sudo cp -f $workdir/node_exporter /usr/local/bin

grep -w nodeusr /etc/passwd > /dev/null
if [ $? -ne 0 ];
then	
	sudo useradd --no-create-home --shell /bin/false nodeusr
fi

sudo chown -R nodeusr:nodeusr /usr/local/bin/node_exporter

sudo cp $projectdir/node_exporter.service $systemddir/ 
sudo systemctl enable node_exporter.service &> /dev/null && \
       	sudo systemctl start node_exporter.service &> /dev/null && \
	sudo systemctl daemon-reload

if [ $? -eq 0 ];
then
	rm -rf $workdir
fi

echo -e "\nSystemd-unit для Node Exporter -> $systemddir/node_exporter.service"
echo -e "Используй 'sudo systemctl status node_exporter.service' для проверки состояния сервиса!"
