if [ -e "/app-files/firsttime" ];
then
    mkdir -p ${OTRS_ROOT}
    cp -rfp /app-files/otrs/* ${OTRS_ROOT}
    su -c "${OTRS_ROOT}bin/otrs.Console.pl Maint::Config::Rebuild" -s /bin/bash otrs
    su -c "${OTRS_ROOT}bin/otrs.Console.pl Maint::Cache::Delete" -s /bin/bash otrs
    ${OTRS_ROOT}bin/otrs.SetPermissions.pl --znuny-user=otrs --web-group=nginx ${OTRS_ROOT}
    rm -fr /app-files/firsttime
fi

/usr/bin/supervisord -c /etc/supervisord.conf&

trap 'kill ${!}; term_handler' SIGTERM

# wait forever
while true
do
 tail -f /dev/null & wait ${!}
done