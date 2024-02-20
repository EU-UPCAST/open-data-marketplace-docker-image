#!/bin/bash

# function Copied from MariaDB official image 2019-11-01
#
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	echo "setting $var"
	export "$var"="$val"
	unset "$fileVar"
}

# Setup all env vars either from original env variable or FILE_
# suffixed env for docker secrets support
file_env 'DRUPAL_DB_HOST'
file_env 'DRUPAL_DB_USER'
file_env 'DRUPAL_DB_PASSWORD'
file_env 'MYSQL_DATABASE'

echo "$@"

# Execute original command
exec "$@"