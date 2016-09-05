# Symfony2 + RabbitMQ + Supervisord + Jenkins auto consumers setup

In Capitalise.com we use RabbitMQ as queue system for async tasks and `php-amqplib/rabbitmq-bundle` in a Symfony app to consume those messages from RabbitMQ.

Aiming to automate all the steps of the deploy we needed a way to auto setup any new consumer, ideally in the jenkins deployment job.

For this, we took advantage of Symfony console to get the list of available consumers and using a template consumer with supervisord we setup all the new consumers.


## Setting up the environment

We start by setting up the environment for the deployment, for this we set some environment variables as shown: 

```
# PHP bin path
PHP=php

# Deploy environment
SYMFONY_ENVIRONMENT=prod
DEPLOYMENT_ENVIRONMENT=production

# Symfony project path (should be updated for Symfony3)
APPLICATION_PATH=/path/to/your/symfony/app
APPLICATION_CONSOLE=${APPLICATION_PATH}/app/console

# Path for supervisord configurations
SUPERVISORD_CONF_DIR=/etc/supervisor/conf.d
SUPERVISORD_LOG_DIR=/var/log/supervisor
SUPERVISORD_PREFIX=supervisord-${DEPLOYMENT_ENVIRONMENT}-
SUPERVISORD_SUFFIX=.conf
SUPERVISORD_USER=apache

# Consumers file name configuration
PROGNAME_PREFIX=${DEPLOYMENT_ENVIRONMENT}.projectname.app.consumers.
PROGNAME_SUFFIX=
```

## Create the consumers

With the environment ready for the consumers configuration, we have a post build task on jenkins which will fetch the list of consumers from the Symfony app and run the script that will generate the consumers configuration.

```
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
```



Finally we restart supervisord and we're good to go :)


# Contributors

[@tiagoblackcode](https://github.com/tiagoblackcode)
