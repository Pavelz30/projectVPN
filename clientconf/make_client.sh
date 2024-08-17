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

if [ ! -f ~/easy-rsa/ta.key ];
then
	echo "~/easy-rsa/ta.key не обнаружен.\nЗапросите ключ у сервера openVPN!"
	exit 0
fi

path_to_clientconf_dir=~/projectVPN/clientconf

echo -e "\e[0;34m\nЭтап 1/3. Генерация сертификатов и ключей для пользователя $1.\e[0m"
mkdir -p ~/clients/keys && \
	cd ~/easy-rsa && \
	./easyrsa --batch gen-req $1 nopass && \
	./easyrsa --batch sign-req client $1 && \
	mkdir -p ~/clients/files
checkwork 1

echo -e "\e[0;34mЭтап 2/3. Копирование файлов.\e[0m"
cp pki/private/$1.key ~/clients/keys/ && \
	cp ta.key ~/clients/keys/ && \
	sudo cp ~/easy-rsa/pki/ca.crt ~/clients/keys/ && \
	cp pki/issued/$1.crt ~/clients/keys/ && \
	cp $path_to_clientconf_dir/base.conf  ~/clients/ && \
	sed -i -r "s/remote ([0-9]{1,3}[\.]){3}[0-9]{1,3} 1194/remote $(curl -s ifconfig.co) 1194/" ~/clients/base.conf && \
	cp $path_to_clientconf_dir/make_config.sh ~/clients/ && \
	sudo chown -R $USER:$USER ~/clients/*
checkwork 2

echo -e "\e[0;34mЭтап 3/3. Создание сертификата для клиента $1.\e[0m"
cd ~/clients && \
	./make_config.sh $1
checkwork 3
echo -e "\nСертификат клиента '$1' -> ~/clients/files/$1.ovpn.\nПерешлите его клиенту вместе с ключом ~/clients/keys/ta.key." 

