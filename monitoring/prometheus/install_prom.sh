#!/bin/bash 

# Installation Prometheus 

if [ $# -ne 1 ];
then
	echo "Требуется один параметр - версия Prometheus!"
	exit 1
fi

version=$1
workdir=~/prometheus-$version.linux-amd64
etcdir=/etc/prometheus
libdir=/var/lib/prometheus
projectdir=~/projectVPN/monitoring/prometheus
systemddir=/etc/systemd/system


if [ "$(ps -p 1 -o comm=)" != "systemd" ];
then
	echo "Вы не используете systemd!"
	exit 1
fi

if [ -d $etcdir ] || [ -d $libdir ] || [ -f /usr/local/bin/prometheus ] || [ -f $systemddir/prometheus.service ];
then
	echo -n "Возможно, у вас уже установлен Prometheus. Введите 'force' чтобы удалить все конфликтующие файлы, иначе 'none': "
	read var
	if [ "$var" == "force" ];
	then
		sudo rm -rf $etcdir \
			$libdir \
			/usr/local/bin/{prometheus,promtool}
		sudo systemctl daemon-reload && sudo systemctl reset-failed
	else
		echo -e "\nУстраните конфликтующие файлы и перезапустите скрипт!"
		echo -e "$etcdir\n$libdir\n$systemddir/prometheus.service\n/usr/local/bin/{prometheus,promtool}"
		exit 1
	fi
fi

cd ~/ && wget https://github.com/prometheus/prometheus/releases/download/v$version/prometheus-$version.linux-amd64.tar.gz &> /dev/null || (echo "Не удалось скачать файл, проверьте введенную версию версию!" && exit 1)

tar -xf prometheus-$version.linux-amd64.tar.gz && rm -rf prometheus-$version.linux-amd64.tar.gz

sudo mkdir -p $etcdir $libdir
sudo cp -r $workdir/consoles $workdir/console_libraries $projectdir/prometheus.yml $etcdir && \
	sudo cp -f $workdir/prometheus $workdir/promtool /usr/local/bin

grep -w prometheus /etc/passwd > /dev/null
if [ $? -ne 0 ];
then	
	sudo useradd --no-create-home --shell /bin/false prometheus
fi

sudo chown -R prometheus:prometheus $etcdir $libdir && \
	sudo chown prometheus:prometheus /usr/local/bin/{prometheus,promtool}

sudo cp -f $projectdir/prometheus.service $systemddir/ 
sudo systemctl enable prometheus.service &> /dev/null && \
	sudo systemctl start prometheus.service &> /dev/null && \
	sudo systemctl daemon-reload

if [ $? -eq 0 ];
then
	rm -rf $workdir
fi

echo -e "\nКонфигурация Prometheus -> $etcdir"
echo -e "Systemd-unit для Prometheus -> $systemddir/prometheus.service"
echo -e "Используй 'sudo systemctl status prometheus.service' для проверки состояния сервиса!"
