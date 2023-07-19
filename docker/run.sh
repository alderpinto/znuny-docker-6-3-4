#!/bin/bash

function prepare_znuny () {
    echo "Preparing znuny..."
    cp -rfp /app-files/znuny/* ${OTRS_ROOT}
    su -c "${OTRS_ROOT}bin/znuny.Console.pl Maint::Config::Rebuild" -s /bin/bash znuny
    su -c "${OTRS_ROOT}bin/znuny.Console.pl Maint::Cache::Delete" -s /bin/bash znuny
    ${OTRS_ROOT}bin/znuny.SetPermissions.pl --znuny-user=znuny --web-group=nginx ${OTRS_ROOT}
    rm -fr /app-files/znuny   
}

VOLUME_DIR=${OTRS_ROOT:-/opt/znuny/}

# Verificar se o diretório do volume existe
if [ -d "$VOLUME_DIR" ]; then
    # Verificar se existem arquivos ou diretórios dentro do diretório do volume
    if [ "$(ls -A $VOLUME_DIR)" ]; then
        echo "O ambiente já foi configurado anteriormente."
    else
        echo "O ambiente ainda não foi configurado."
        # Coloque aqui o código para executar a configuração inicial do ambiente
        prepare_znuny     
    fi
else
    echo "O volume ainda não foi criado."
    # Coloque aqui o código para criar o volume e executar a configuração inicial do ambiente
    mkdir -p ${OTRS_ROOT}
    prepare_znuny  
fi

/usr/bin/supervisord -c /etc/supervisord.conf&

trap 'kill ${!}; term_handler' SIGTERM

# wait forever
while true
do
 tail -f /dev/null & wait ${!}
done