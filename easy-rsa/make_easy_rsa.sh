#!/bin/bash

path_to_easy_rsa_dir=~/projectVPN/easy-rsa

function checkwork {
	
	code=$?

	if [ $code -ne 0 ];
	then
		echo -e "\e[0;31mOшибка на этапе $1!\e[0m"
		case $1 in 
			1) 
				echo "Не удалось установить easy-rsa. Проверьте достпность установки пакетов!"
				;;
			2)
				echo "Проблема при настройке easy-rsa!"
				;;
			3)
				echo "Проблема при копировании файла из $path_to_easy_rsa_dir/vars в ~/easy-rsa!"
				;;
			4) 	
				echo "Пробелма при создании центра сертификации (CA)"
				;;
			*)
				;;
		esac
		exit 1
	else
		echo -e "\e[0;32mЭтап $1 прошел успешно!\n\e[0m"
	fi	
}


echo -e "\e[0;35m\nЭтап 1/4. Установка easy-rsa.\e[0m"
sudo apt-get update -y > /dev/null && sudo apt-get install easy-rsa -y > /dev/null
checkwork 1

echo -e "\e[0;35mЭтап 2/4. Настройка easy-rsa.\e[0m"
mkdir -p ~/easy-rsa && ln -sf /usr/share/easy-rsa/* ~/easy-rsa/ && cd ~/easy-rsa  && ./easyrsa init-pki
checkwork 2

echo -e "\e[0;35mЭтап 3/4. Копирование конфиграции vars для CA.\e[0m"
cp $path_to_easy_rsa_dir/vars .
checkwork 3

echo -e "\e[0;35mЭтап 4/4. Создание CA.\nЗдесь вам предложат ввести кодовую фразу, которую впоследствии нужно
вводить для получения доступа к вашему СA при совершении операций с cертификатами.\e[0m"
./easyrsa --batch build-ca

while [ $? -ne 0 ];
do
	echo -e "\e[0;31mПароли не совпадают, попробуйте еще раз!\n\e[0m"
	./easyrsa --batch build-ca
done
checkwork 4

echo -e "\e[0;32mУстановка и настройка easy-rsa прошла успешно!\n\e[0m"
echo -e "\e[0;32mГлавынй сертификат Центра Cертефикации (CA) -> ~/easy-rsa/pki/ca.crt\e[0m"
echo -e "\e[0;32mCекретный ключ CA для подписи сертификатов -> ~/easy-rsa/pki/private/ca.key\e[0m"
echo -e "\e[0;33mНе передавайте никому секретный ключ СA !!!\e[0m"
