# syntax=docker/dockerfile:1
FROM drupal:latest
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN ln -sf /usr/bin/bash /bin/sh
WORKDIR /opt/drupal
ENV COMPOSER_ALLOW_SUPERUSER=1
COPY ./entrypoint.sh /opt/entrypoint.sh
COPY ./wait-for-it.sh /opt/wait-for-it.sh
COPY ./profile/odm /opt/odm
RUN <<EOF
docker-php-ext-install bcmath

composer config minimum-stability dev
composer config prefer-stable true

composer config repositories.odm path ../odm
composer config repositories.assets composer https://asset-packagist.org
composer config repositories.jsoneditor --json  '{"type":"package","package":{"name":"josdejong\/jsoneditor","version":"v5.29.1","type":"drupal-library","dist":{"url":"https:\/\/github.com\/josdejong\/jsoneditor\/archive\/v5.29.1.zip","type":"zip"},"source":{"url":"https:\/\/github.com\/josdejong\/jsoneditor","type":"git","reference":"v5.29.1"}}}'
composer config repositories.jsonview --json  '{"type":"package","package":{"name":"yesmeck\/jquery-jsonview","version":"v1.2.3","type":"drupal-library","dist":{"url":"https:\/\/github.com\/yesmeck\/jquery-jsonview\/archive\/v1.2.3.zip","type":"zip"},"source":{"url":"https:\/\/github.com\/yesmeck\/jquery-jsonview","type":"git","reference":"v1.2.3"}}}'
composer config --no-interaction allow-plugins.cweagans/composer-patches true
composer config --no-interaction allow-plugins.oomphinc/composer-installers-extender true
composer config --no-interaction extra.enable-patching true
composer config --no-interaction extra.patches --json '{"drupal\/core":{"2893933: claimItem in the database and memory queues does not use expire correctly":"https:\/\/www.drupal.org\/files\/issues\/2023-01-10\/2893933-drupal-queue-claim-9.5.x-58.patch"}}'
composer config --no-interaction extra.installer-types --json '["bower-asset", "npm-asset"]'
composer config --no-interaction extra.installer-paths.web/libraries/{\$name} --json '["type:drupal-library","type:bower-asset","type:npm-asset"]'

composer require -n drupal/odm @dev


composer require drush/drush
echo 'export PATH="/opt/drupal/vendor/bin:$PATH"' >> ~/.bashrc
apt update
apt install nano git jq -y
if ! test -f /opt/drupal/web/sites/default/settings.php; then

  cp /opt/drupal/web/sites/default/default.settings.php  /opt/drupal/web/sites/default/settings.php 
 
 echo "
  \$databases['default']['default'] = array (
    'database' => getenv('MYSQL_DATABASE'),
    'username' => getenv('DRUPAL_DB_USER'),
    'password' => getenv('DRUPAL_DB_PASSWORD'),
    'prefix' => '',
    'host' => getenv('DRUPAL_DB_HOST'),
    'port' => getenv('MYSQL_PORT_3306_TCP'),
    'isolation_level' => 'READ COMMITTED',
    'namespace' => 'Drupal\\\\mysql\\\\Driver\\\\Database\\\\mysql',
    'driver' => 'mysql',
    'autoload' => 'core/modules/mysql/src/Driver/Database/mysql/',
  );
  ">> /opt/drupal/web/sites/default/settings.php
  echo "\$settings['hash_salt'] = \"$(drush php-eval 'echo \Drupal\Component\Utility\Crypt::randomBytesBase64(55)')\";
  " >> /opt/drupal/web/sites/default/settings.php


  echo "\$settings['trusted_host_patterns'] = [
    '^'.getenv('DRUPAL_TRUSTED_HOST').'\$',
  ];" >> /opt/drupal/web/sites/default/settings.php

  
  echo "\$settings['config_sync_directory'] = '/opt/config/sync';" >> /opt/drupal/web/sites/default/settings.php
fi

chown -R  www-data:www-data /opt/drupal/web/sites/default


chown -R www-data:www-data /opt/drupal/web/profiles/odm
chmod -R 555 /opt/drupal/web/profiles/odm

mkdir -p /opt/config/sync
chown -R www-data:www-data /opt/config/sync
chmod -R 775 /opt/config/sync

mkdir -p /opt/drupal/web/sites/default/files
chown -R www-data:www-data /opt/drupal/web/sites/default/files
chmod -R 775 /opt/drupal/web/sites/default/files/

mkdir -p /opt/drupal/web/sites/default/files/translations/
chmod -R 555 /opt/drupal/web/sites/default/files/translations/
chown -R www-data:www-data /opt/drupal/web/sites/default/files/translations



EOF



ADD ./entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh
CMD ["bash", "-c","source /opt/entrypoint.sh; /opt/wait-for-it.sh ${DRUPAL_DB_HOST}:${MYSQL_PORT_3306_TCP}  -- /usr/local/bin/apache2-foreground;"]