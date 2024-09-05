#!/bin/bash

. ./functions.sh

VOLUME_DIR=${ZNUNY_ROOT:-/opt/otrs}

wait_for_db

# Verificar se o diretório do volume existe
if [ -d "$VOLUME_DIR" ]; then
    # Verificar se existem arquivos ou diretórios dentro do diretório do volume
    if [ "$(ls -A $VOLUME_DIR)" ]; then
        print_info "O ambiente já foi configurado anteriormente."
    else
        print_info "O ambiente ainda não foi configurado."
        # Coloque aqui o código para executar a configuração inicial do ambiente
        print_info "Starting \e[${ZNUNY_ASCII_COLOR_BLUE}m ((OTRS))\e[0m \e[31m${ZNUNY_VERSION}\e[0m \e[${ZNUNY_ASCII_COLOR_BLUE}mCommunity Edition\e[0m \e[0m\n"
        if [ -e "${ZNUNY_CONFIG_MOUNT_DIR}/var/tmp/firsttime" ]; then
            #Load default install
            load_defaults
            #Set default admin user password
            print_info "Setting password for default admin account \e[${ZNUNY_ASCII_COLOR_BLUE}mroot@localhost\e[0m to: \e[31m**********\e[0m"
            su -c "${ZNUNY_ROOT}/bin/otrs.Console.pl Admin::User::SetPassword root@localhost ${ZNUNY_ROOT_PASSWORD}" -s /bin/bash otrs
            rm -fr ${ZNUNY_ROOT}/var/tmp/firsttime
        fi          
    fi
    install_modules ${ZNUNY_ADDONS_PATH}
fi

/usr/bin/supervisord -c /etc/supervisord.conf&

trap 'kill ${!}; term_handler' SIGTERM

# wait forever
while true
do
 tail -f /dev/null & wait ${!}
done