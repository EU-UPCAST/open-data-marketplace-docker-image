# syntax=docker/dockerfile:1
FROM drupal:latest
RUN ln -sf /usr/bin/bash /bin/sh
WORKDIR /opt/drupal
ENV COMPOSER_ALLOW_SUPERUSER=1
COPY ./entrypoint.sh /opt/entrypoint.sh
COPY ./profile/odm /opt/drupal/web/profiles/odm
RUN <<EOF
composer require drush/drush
echo 'export PATH="/opt/drupal/vendor/bin:$PATH"' >> ~/.bashrc
apt update
apt install nano
if ! test -f /opt/drupal/web/sites/default/settings.php; then

  cp /opt/drupal/web/sites/default/default.settings.php  /opt/drupal/web/sites/default/settings.php 
 
 echo "
  \$databases['default']['default'] = array (
    'database' => getenv('MYSQL_DATABASE'),
    'username' => getenv('DRUPAL_DB_USER'),
    'password' => getenv('DRUPAL_DB_PASSWORD'),
    'prefix' => '',
    'host' => getenv('DRUPAL_DB_HOST'),
    'port' => '3306',
    'isolation_level' => 'READ COMMITTED',
    'namespace' => 'Drupal\\\\mysql\\\\Driver\\\\Database\\\\mysql',
    'driver' => 'mysql',
    'autoload' => 'core/modules/mysql/src/Driver/Database/mysql/',
  );
  ">> /opt/drupal/web/sites/default/settings.php
  echo "\$settings['hash_salt'] = \"$(drush php-eval 'echo \Drupal\Component\Utility\Crypt::randomBytesBase64(55)')\";
  " >> /opt/drupal/web/sites/default/settings.php
  
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
CMD ["bash", "-c","source /opt/entrypoint.sh; echo $DRUPAL_DB_PASSWORD; /usr/local/bin/apache2-foreground;"]