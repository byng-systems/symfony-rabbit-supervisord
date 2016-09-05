# Current list of consumers
CONFIGURATION_FILE_LIST=$(find ${SUPERVISORD_CONF_DIR} -type f -name "${SUPERVISORD_PREFIX}*" -name "*${SUPERVISORD_SUFFIX}");

# Consumers listed in the Symfony App
CONSUMER_LIST="$(${PHP} ${APPLICATION_CONSOLE} platfi:rabbitmq:consumers --env=${SYMFONY_ENVIRONMENT})";


# Remove all the configuration files for the current environment.
for CONFIGURATION_FILE in ${CONFIGURATION_FILE_LIST};
do
    echo "Removing configuration file ${CONFIGURATION_FILE#$SUPERVISORD_CONF_DIR/}";
    rm ${CONFIGURATION_FILE};
done

# Re-generate all the configuration files for the current environment.
for CONSUMER_NAME in ${CONSUMER_LIST};
do
    CONF_FILE="${SUPERVISORD_PREFIX}${CONSUMER_NAME}${SUPERVISORD_SUFFIX}";

    echo "Creating configuration file ${CONF_FILE}";
    cat > "${SUPERVISORD_CONF_DIR}/${CONF_FILE}" <<EOF
# Configuration generated automatically
# DO NOT CHANGE - Will be updated on each deployment
[program:${PROGNAME_PREFIX}${CONSUMER_NAME}${PROGNAME_SUFFIX}]
user=${SUPERVISORD_USER}
command=${PHP} -dmemory_limit=128M ${APPLICATION_CONSOLE} rabbitmq:consumer -w ${CONSUMER_NAME} --env=${SYMFONY_ENVIRONMENT}
process_name=worker-%(process_num)02d
numprocs=1
autostart=true
autorestart=true
log_stdout=true
redirect_stderr=true
stdout_file=${SUPERVISORD_LOG_DIR}/${DEPLOYMENT_ENVIRONMENT}-${CONSUMER_NAME}-%(process_num)02d
stdout_logfile_maxbytes=20MB
stdout_logfile_backups=5
EOF

done

# Update supervisor with the new configuration
supervisorctl update all;

# Restart consumers one by one (consumers that have not changed will not be restarted with the command above)
for CONSUMER_NAME in ${CONSUMER_LIST};
do
    supervisorctl restart ${PROGNAME_PREFIX}${CONSUMER_NAME}${PROGNAME_SUFFIX}:*;
done