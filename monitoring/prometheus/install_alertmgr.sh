#!/bin/bash

# Installation AlertManager

if [ $# -ne 1 ];
then
        echo "Требуется один параметр - версия Alertmanager!"
        exit 1
fi

version=$1
workdir=~/alertmanager-$version.linux-amd64
etcdir=/etc/alertmanager
libdir=/var/lib/prometheus/alertmanager
projectdir=~/projectVPN/monitoring/prometheus
systemddir=/etc/systemd/system

if [ "$(ps -p 1 -o comm=)" != "systemd" ];
then
        echo "Вы не используете systemd!"
        exit 1
fi

if [ -d $etcdir ] || [ -d $libdir ] || [ -f /usr/local/bin/alertmanager ] || [ -f /etc/systemd/system/alertmanager.service ];
then
        echo -n "Возможно, у вас уже установлен Alertmanager. Введите 'force' чтобы удалить все конфликтующие файлы, иначе 'none': "
        read var
	if [ "$var" == "force" ];
        then
                sudo rm -rf $etcdir \
                        $libdir \
			$systemddir/alertmanager.service \
			/usr/local/bin/{alertmanager,amtool}
                sudo systemctl daemon-reload && sudo systemctl reset-failed
        else
                echo -e "\nУстраните конфликтующие файлы и перезапустите скрипт!"
                echo -e "$etcdir\n$libdir\n$systemddir/alertmanager.service\n/usr/local/bin/{alertmanager,amtool}"
                exit 1
        fi
fi

cd ~/ && wget https://github.com/prometheus/alertmanager/releases/download/v$version/alertmanager-$version.linux-amd64.tar.gz &> /dev/null || (echo "Не удалось скачать архив, проверьте введенную версию!" && exit 1)

tar -xf alertmanager-$version.linux-amd64.tar.gz && rm -rf alertmanager-$version.linux-amd64.tar.gz

sudo mkdir -p $etcdir $libdir
sudo cp $workdir/alertmanager $workdir/amtool /usr/local/bin/ && \
       sudo cp $projectdir/alertmanager.yml $etcdir

grep -w alertmanager /etc/passwd > /dev/null
if [ $? -ne 0 ];
then
	sudo useradd --no-create-home --shell /bin/false alertmanager
fi

sudo chown -R alertmanager:alertmanager $etcdir $libdir && \
	sudo chown alertmanager:alertmanager /usr/local/bin/{alertmanager,amtool}

sudo cp $projectdir/alertmanager.service $systemddir/
sudo systemctl enable alertmanager.service &> /dev/null && sudo systemctl start alertmanager.service &> /dev/null

if [ $? -eq 0 ];
then
        rm -rf $workdir
fi

echo -e "\nКонфигурация Alertmanager -> $etcdir"
echo -e "Systemd-unit для Alertmanager -> $systemddir/alertmanager.service"
echo -e "Используй 'sudo systemctl status alertmanager.service' для проверки состояния сервиса!"
