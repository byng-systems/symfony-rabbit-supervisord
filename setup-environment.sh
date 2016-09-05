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