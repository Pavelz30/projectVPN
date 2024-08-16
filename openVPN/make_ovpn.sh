#!/bin/bash

function checkwork {
	
	code=$?

	if [ $# -ne 1 ];
	then
		echo "Нужно передаеть один аргумент!"
		exit 1
	fi

	if [ $code -ne 0 ];
	then
		echo -e "\e[0;31mЧто-то пошло не так на этапе $1!\e[0m"
		exit 1
	else
		echo -e "\e[0;32mЭтап $1 прошел успешно!\n\e[0m"
	fi	
}

path_to_openvpn_dir=~/projectVPN/openVPN

echo -e "\e[0;34m\nЭтап 1/8. Скачивание openVPN.\e[0m"
sudo apt-get update -y > /dev/null && sudo apt-get install openvpn -y > /dev/null && cd ~/easy-rsa
checkwork 1

echo -e "\e[0;34mЭтап 2/8. Создание запроса на сертификат и ключ для сервера.\e[0m"
./easyrsa --batch gen-req server nopass 
checkwork 2

echo -e "\e[0;34mЭтап 3/8. Подпись сертификата удостоверяющим центром.
Здесь потребуется ввести пароль, заданный при генерации корневого сертефиката СA.\e[0m"
./easyrsa --batch sign-req server server
checkwork 3

echo -e "\e[0;34mЭтап 4/8 Генерация tls-ключа для дополнительной безопасности.\e[0m"
openvpn --genkey --secret ta.key
checkwork 4

echo -e "\e[0;34mЭтап 5/8. Копирование необходимых файлов в /etc/openvpn/server.\e[0m"
sudo cp ./pki/private/server.key /etc/openvpn/server && \
	sudo cp ./pki/ca.crt /etc/openvpn/server/ && \
	sudo cp ./pki/issued/server.crt /etc/openvpn/server/ && \
	sudo cp ./ta.key /etc/openvpn/server/
checkwork 5

echo -e "\e[0;34mЭтап 6/8 Настройка openVPN и маршрутизации.\e[0m"
sudo cp $path_to_openvpn_dir/server.conf /etc/openvpn/server && \
	sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf && \
	sudo sysctl -p
checkwork 6

echo -e "\e[0;34mЭтап 7/8. Настройка iptables.\e[0m"
sudo apt-get install iptables -y > /dev/null && \
	int=$(ip a | grep -e "eth.:" | awk -F: '{print $2}' | sed 's/ //') && \
	proto=$(sudo cat /etc/openvpn/server/server.conf | grep ^proto | awk '{print $2}') && \
	port=$(sudo cat /etc/openvpn/server/server.conf | grep ^port | awk '{print $2}') && \
	sudo chmod +x $path_to_openvpn_dir/iptables.sh && \
	sudo $path_to_openvpn_dir/iptables.sh $int $proto $port && sudo iptables-save	
checkwork 7

echo -e "\e[0;34mЭтап 8/8 Запуск openVPN.\e[0m"
sudo systemctl -f enable openvpn-server@server.service && \
	sudo systemctl start openvpn-server@server.service 
checkwork 8
