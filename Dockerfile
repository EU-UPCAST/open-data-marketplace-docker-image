# syntax=docker/dockerfile:1
FROM drupal:latest
#RUN ln -sf /bin/bash /bin/sh
#RUN cp /opt/drupal/web/sites/default/default.settings.php  /opt/drupal/web/sites/default/settings.php 
WORKDIR /opt/drupal
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN <<EOF
composer require drush/drush
echo 'export PATH="/opt/drupal/vendor/bin:$PATH"' >> ~/.bashrc
EOF