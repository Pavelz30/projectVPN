#!/bin/bash

path_to_openvpn_dir=~/projectVPN/openVPN
max=-1
cur=1

echo -ne "\nВведите 'along', если сервис openvpn будет на машине с центром сертификации, иначе введите 'none': "

read mode

while [ "$mode" != "along" ];
do
	if [ "$mode" == "none" ];
       	then
	       break
      	else
		echo -e "\e[0;31mНеправльный ввод!\e[0m"
		exit 1
	fi		
done

if [ "$mode" == "along" ];
then
       	max=9
else
       	max=8
fi

function checkwork {
	
	code=$?

	if [ $code -ne 0 ];
	then
		echo -e "\e[0;31mOшибка на этапе $1!\e[0m"
                exit 1
	else
		echo -e "\e[0;32mЭтап $1 прошел успешно!\n\e[0m"
	fi	
}


echo -e "\e[0;35m\nЭтап $cur/$max. Установка openVPN.\e[0m"
sudo apt-get update -y > /dev/null && sudo apt-get install openvpn -y > /dev/null
checkwork $cur
cur=$(( cur + 1 ))


if [ "$mode" != "along" ];
then
	echo -e "\e[0;35m\nЭтап $cur/$max. Установка и настройка easy-rsa.\e[0m"
	sudo apt-get update -y > /dev/null && sudo apt-get install easy-rsa -y > /dev/null && \
	mkdir -p ~/easy-rsa && ln -sf /usr/share/easy-rsa/* ~/easy-rsa/ && cd ~/easy-rsa  && ./easyrsa init-pki && \
	cp $path_to_openvpn_dir/vars . &&  echo -e "\e[0;32mЭтап $1 прошел успешно!\n\e[0m" || echo "\e[0;31mOшибка на этапе $cur!\e[0m"
	cur=$(( cur + 1 ))
else
	cd ~/easy-rsa
fi

echo -e "\e[0;35mЭтап $cur/$max. Создание запроса на сертификат и ключa для сервера.\e[0m"
./easyrsa --batch gen-req server nopass 
checkwork $cur
cur=$(( cur + 1 ))

echo -e "\e[0;35mЭтап $cur/$max Генерация tls-ключа для дополнительной безопасности.\e[0m"
openvpn --genkey --secret ta.key
checkwork $cur
cur=$(( cur + 1 ))

if [ "$mode" == "along" ];
then
	echo -e "\e[0;35mЭтап $cur/$max. Подпись сертификата удостоверяющим центром.
Здесь потребуется ввести фразу, заданную при генерации корневого сертификата СA.\e[0m"
	./easyrsa --batch sign-req server server
	checkwork $cur
	cur=$(( cur + 1 ))

	echo -e "\e[0;35mЭтап $cur/$max. Копирование сертификата CA и сертификата сервера в /etc/openvpn/server.\e[0m"
	sudo cp ./pki/ca.crt /etc/openvpn/server/ && \
	sudo cp ./pki/issued/server.crt /etc/openvpn/server/
	checkwork $cur
	cur=$(( cur + 1 ))
fi

echo -e "\e[0;35mЭтап $cur/$max. Копирование секретного ключа сервера и дополнительного ключа ta.key в /etc/openvpn/server.\e[0m"
sudo cp ./pki/private/server.key /etc/openvpn/server && \
	sudo cp ./ta.key /etc/openvpn/server/
checkwork $cur
cur=$(( cur + 1 ))

echo -e "\e[0;35mЭтап $cur/$max Настройка openVPN и маршрутизации.\e[0m"
sudo cp $path_to_openvpn_dir/server.conf /etc/openvpn/server && \
	sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf && \
	sudo sysctl -p
checkwork $cur
cur=$(( cur + 1 ))

echo -e "\e[0;35mЭтап $cur/$max. Настройка iptables.\e[0m"
sudo apt-get install iptables -y > /dev/null && \
	int=$(ip a | grep -e "eth.:" | awk -F: '{print $2}' | sed 's/ //') && \
	proto=$(sudo cat /etc/openvpn/server/server.conf | grep ^proto | awk '{print $2}') && \
	port=$(sudo cat /etc/openvpn/server/server.conf | grep ^port | awk '{print $2}') && \
	sudo chmod +x $path_to_openvpn_dir/iptables.sh && \
	sudo $path_to_openvpn_dir/iptables.sh $int $proto $port && sudo iptables-save	
checkwork $cur
cur=$(( cur + 1 ))


echo -e "\e[0;35mЭтап $cur/$max Запуск openVPN.\e[0m"
sudo systemctl -f enable openvpn-server@server.service
if [ "$mode" == "along" ];
then
        sudo systemctl start openvpn-server@server.service
fi
checkwork $cur

echo -e "\e[0;32mУстановка и настройка openvpn прошла успешно!\n\e[0m"
echo -e "\e[0;32mДополнительный ключ для обеспечения защиты -> ~/easy-rsa/ta.key\e[0m"
echo -e "\e[0;32mЗапрос на получение сертифката для сервера openvpn -> ~/easy-rsa/pki/reqs/server.req\e[0m"
echo -e "\e[0;32mCекретный ключ для подписи запроса -> ~/easy-rsa/pki/private/server.key\e[0m"
echo -e "\e[0;33mНе передавайте никому секретный ключ СA !!!\e[0m"

if [ $mode == "along" ];
then
	
        echo -e "\e[0;32m\nПодписанный сертификат для сервера -> ~/easy-rsa/pki/issued/server.crt\e[0m"
else
	echo -e "\nПередайте запрос на полечение сертификата в Удостоверяющий Центр (CA)."
        echo -e "Запросите у удостоверяющего центра ca.crt и server.crt."
	echo -e "\e[0;33mПоложите полученные файлы в /etc/openvpn/server/ 
Запустите сервис openvpn: sudo systemctl start openvpn-server@server.service"
fi
