#!/bin/bash

# Copyright © 2016-2019 Mozg. All rights reserved.
# See LICENSE.txt for license details.

setVars () {
echo -e "${ONYELLOW} setVars ${NORMAL}"

WICH_7ZA=`which 7za`
WICH_TAR=`which tar`
WICH_MYSQL=`which mysql`
GIT=`which git` > /dev/null
PHP_BIN=`which php`
OS=`uname -s`
REV=`uname -r`
MACH=`uname -m`
WHOAMI=$(whoami &2>/dev/null)
FOLDER_UP="$(cd ../; pwd)"
BASE_PATH_USER=~
FOLDER_CACHE=$BASE_PATH_USER'/dados/softwares'

# Define text styles
#BOLD=`tput bold` # Error Heroku, tput: No value for $TERM and no -T specified
#NORMAL=`tput sgr0`
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
#BOLD=''
#NORMAL=''

# Reset
RESETCOLOR='\e[0m'       # Text Reset

# Regular Colors
BLACK='\e[0;30m'        # Black
RED='\e[0;31m'          # Red
GREEN='\e[0;32m'        # Green
YELLOW='\e[0;33m'       # Yellow
BLUE='\e[0;34m'         # Blue
PURPLE='\e[0;35m'       # Purple
CYAN='\e[0;36m'         # Cyan
WHITE='\e[0;37m'        # White

# Background
ONBLACK='\e[40m'       # Black
ONRED='\e[41m'         # Red
ONGREEN='\e[42m'       # Green
ONYELLOW='\e[43m'      # Yellow
ONBLUE='\e[44m'        # Blue
ONPURPLE='\e[45m'      # Purple
ONCYAN='\e[46m'        # Cyan
ONWHITE='\e[47m'       # White

# Nice defaults
NOW_2_FILE=$(date +%Y-%m-%d_%H-%M-%S)
DATE_EN_US=$(date '+%Y-%m-%d %H:%M:%S')
DATE_PT_BR=$(date '+%d/%m/%Y %H:%M:%S')

}

setVars

#

function_before () {
echo
}

function_after () {
echo
echo -e "${ONYELLOW}}${NORMAL}"
echo
}

show_vars () {

function_before
echo -e "${ONYELLOW} show_vars () { ${NORMAL}"

echo -e "${ONYELLOW} date ${NORMAL}"

echo $(date +%Y-%m-%d_%H-%M-%S)

echo -e "${ONYELLOW} pwd ${NORMAL}"

pwd && ls

#df -h

du -hsx ./* | sort -rh | head -10

echo -e "${ONYELLOW} whoami - print effective userid ${NORMAL}"

whoami

##echo -e "${ONYELLOW} printenv - print all or part of environment ${NORMAL}"

#printenv

#echo -e "${ONYELLOW} ps - report a snapshot of the current processes ${NORMAL}"

#ps aux

#echo -e "${ONYELLOW} will list all the commands you could run. ${NORMAL}"

#compgen -A function -abck

function_after

}

mysql_select_admin_user () {

function_before
echo -e "${ONYELLOW} mysql_select_admin_user () { ${NORMAL}"

MYSQL_SELECT_ADMIN_USER=`mysql -h "${MAGE_DB_HOST}" -P "${MAGE_DB_PORT}" -u "${MAGE_DB_USER}" -p"${MAGE_DB_PASS}" "${MAGE_DB_NAME}" -N -e "SELECT * FROM admin_user"`

echo -e "${ONPURPLE} - ${NORMAL}"

#echo $MYSQL_SELECT_ADMIN_USER

function_after

}

magento_config_xml () {

function_before
echo -e "${ONYELLOW} magento_config_xml () { ${NORMAL}"

echo -e "${ONYELLOW} Check local.xml ${NORMAL}"

pwd

echo -e "${ONYELLOW} check n98-magerun ${NORMAL}"

timeProg=`which n98-magerun`

[[ "$(command -v n98-magerun)" ]] || { echo "n98-magerun is not installed" 1>&2 ; }
[[ -f "./n98-magerun.phar" ]] || { echo "n98-magerun local installed" 1>&2 ; }

if [ ! -f "./n98-magerun.phar" ]; then # -z String, True if string is empty.
  echo -e "${ONYELLOW} n98-magerun ${NORMAL}"
  wget https://files.magerun.net/n98-magerun.phar
  chmod +x ./n98-magerun.phar
fi

./n98-magerun.phar --version

./n98-magerun.phar --root-dir=magento local-config:generate "$MAGE_DB_HOST:$MAGE_DB_PORT" "$MAGE_DB_USER" "$MAGE_DB_PASS" "$MAGE_DB_NAME" "files" "admin" "secret" -vvv

function_after

}

magento_sample_data_import_haifeng () {

function_before
echo -e "${ONYELLOW} magento_sample_data_import_haifeng () { ${NORMAL}"

#grep -ri 'LOCK TABLE' magento/vendor/haifeng-ben-zhang/magento1.9.2.4-sample-data/magento_sample_data_for_1.9.2.4.sql

# FIX Heroku: permission, LOCK TABLE
awk '/LOCK TABLE/{n=1}; n {n--; next}; 1' < magento/vendor/haifeng-ben-zhang/magento1.9.2.4-sample-data/magento_sample_data_for_1.9.2.4.sql > magento/vendor/haifeng-ben-zhang/magento1.9.2.4-sample-data/magento_sample_data_for_1.9.2.4_unlock.sql

#grep -ri 'LOCK TABLE' magento/vendor/haifeng-ben-zhang/magento1.9.2.4-sample-data/magento_sample_data_for_1.9.2.4_unlock.sql

echo -e "${ONYELLOW} Importando... ${NORMAL}"

if [ -f ".env" ] ; then # if file not exits, only local
    echo -e "${RED} .env ${NORMAL}"
    MYSQL_IMPORT=`mysql -h "${MAGE_DB_HOST}" -P "${MAGE_DB_PORT}" -u "${MAGE_DB_USER}" -p"${MAGE_DB_PASS}" "${MAGE_DB_NAME}" < 'magento/vendor/haifeng-ben-zhang/magento1.9.2.4-sample-data/magento_sample_data_for_1.9.2.4_unlock.sql'` # Heroku, Error R10 (Boot timeout) -> Web process failed to bind to $PORT within 60 seconds of launch
    echo -e "${RED} MYSQL_IMPORT=${MYSQL_IMPORT} ${NORMAL}"
fi

#

#php bin/worker.php "$STRING_MYSQL_IMPORT" # heroku[run.8223]: Awaiting client, : Starting process with command

function_after

}

magento_install () {

function_before
echo -e "${ONYELLOW} magento_install () { ${NORMAL}"

echo -e "${ONYELLOW} pwd ${NORMAL}"

pwd && ls -lah

echo -e "${ONYELLOW} cd magento ${NORMAL}"

cd magento
pwd && ls -lah

#echo -e "${ONYELLOW} Aplicando permissões ${NORMAL}"

#chmod 777 -R .

echo -e "${ONYELLOW} install.php ${NORMAL}"

php -f install.php -- \
--license_agreement_accepted "yes" \
--locale "pt_BR" \
--timezone "America/Sao_Paulo" \
--default_currency "BRL" \
--db_host "${MAGE_DB_HOST}:${MAGE_DB_PORT}" \
--db_name "${MAGE_DB_NAME}" \
--db_user "${MAGE_DB_USER}" \
--db_pass "${MAGE_DB_PASS}" \
--url "$MAGE_URL" \
--skip_url_validation "yes" \
--use_rewrites "yes" \
--use_secure "no" \
--secure_base_url "" \
--use_secure_admin "no" \
--admin_firstname "Marcio" \
--admin_lastname "Amorim" \
--admin_email "mailer@mozg.com.br" \
--admin_username "admin" \
--admin_password "123456a"

echo -e "${ONYELLOW} magento/index.php ${NORMAL}"

php index.php

echo -e "${ONYELLOW} shell ${NORMAL}"

echo -e "${ONYELLOW} compiler.php --state ${NORMAL}"

php shell/compiler.php --state

echo -e "${ONYELLOW} log.php --clean ${NORMAL}"

php shell/log.php --clean

echo -e "${ONYELLOW} indexer.php --status ${NORMAL}"

php shell/indexer.php --status

echo -e "${ONYELLOW} indexer.php --info ${NORMAL}"

php shell/indexer.php --info

echo -e "${ONYELLOW} indexer.php --reindexall ${NORMAL}"

php shell/indexer.php --reindexall

echo -e "${ONYELLOW} mage ${NORMAL}"

chmod +x mage

bash ./mage

echo -e "${ONYELLOW} mage-setup ${NORMAL}"

bash ./mage mage-setup

echo -e "${ONYELLOW} sync ${NORMAL}"

bash ./mage sync

echo -e "${ONYELLOW} list-installed ${NORMAL}"

bash ./mage list-installed

echo -e "${ONYELLOW} list-upgrades ${NORMAL}"

bash ./mage list-upgrades

echo -e "${ONYELLOW} - ${NORMAL}"

cd ..

echo -e "${ONYELLOW} - ${NORMAL}"

function_after

}

release () {

function_before
echo -e "${ONYELLOW} release () { ${NORMAL}"


function_after

}

post_update_cmd () { # post-update-cmd: occurs after the update command has been executed, or after the install command has been executed without a lock file present.
# Na heroku o Mysql ainda não foi instalado nesse ponto

function_before
echo -e "${ONYELLOW} post_update_cmd () { ${NORMAL}"

echo -e "${ONYELLOW} - ${NORMAL}"

pwd

echo -e "${ONYELLOW} - ${NORMAL}"

du -hsx ./* | sort -rh | head -10

echo -e "${ONYELLOW} - ${NORMAL}"

du -hsx magento/vendor/* | sort -rh | head -10

echo -e "${ONYELLOW} - ${NORMAL}"

if [ -d magento/vendor/haifeng-ben-zhang/magento1.9.2.4-sample-data/media ]; then
    echo -e "${ONYELLOW} haifeng-ben-zhang/magento1.9.2.4-sample-data ${NORMAL}"
    cp -fr magento/vendor/haifeng-ben-zhang/magento1.9.2.4-sample-data/media/* magento/media/
    cp -fr magento/vendor/haifeng-ben-zhang/magento1.9.2.4-sample-data/skin/* magento/skin/
fi

if [ -d magento/vendor/ceckoslab/ceckoslab_quicklogin ]; then
    echo -e "${ONYELLOW} ceckoslab/ceckoslab_quicklogin ${NORMAL}"
    cp -fr magento/vendor/ceckoslab/ceckoslab_quicklogin/app/* magento/app/
fi

echo -e "${ONYELLOW} - ${NORMAL}"

rm -fr magento/vendor/haifeng-ben-zhang/magento1.9.2.4-sample-data/media
rm -fr magento/vendor/haifeng-ben-zhang/magento1.9.2.4-sample-data/skin

# FIX: Heroku, Compiled slug size: xM is too large (max is 500M).

du -hsx ./magento/media/* | sort -rh | head -10
rm -fr ./magento/media/downloadable
du -hsx ./magento/media/catalog/product/* | sort -rh | head -10
rm -fr ./magento/media/catalog/product/p
rm -fr ./magento/media/catalog/product/cache

echo -e "${ONYELLOW} - ${NORMAL}"

du -hsx ./* | sort -rh | head -10

echo -e "${ONYELLOW} - ${NORMAL}"

du -hsx magento/vendor/* | sort -rh | head -10

echo -e "${ONYELLOW} - ${NORMAL}"

show_vars

profile

##

echo -e "${ONYELLOW} - ${NORMAL}"

function_after

}

post_install_cmd () { # post-install-cmd: occurs after the install command has been executed with a lock file present.

function_before
echo -e "${ONYELLOW} post_install_cmd () { ${NORMAL}"

post_update_cmd

function_after

}

postdeploy () { # postdeploy command. Use this to run any one-time setup tasks that make the app, and any databases, ready and useful for testing.

function_before
echo -e "${ONYELLOW} postdeploy () { ${NORMAL}"

post_update_cmd # post-update-cmd: occurs after the update command has been executed, or after the install command has been executed without a lock file present.

function_after

}

profile () { # Heroku, During startup, the container starts a bash shell that runs any code in $HOME/.profile before executing the dyno’s command. You can put bash code in this file to manipulate the initial environment, at runtime, for all dyno types in your app.

function_before
echo -e "${ONYELLOW} profile () { ${NORMAL}"

echo -e "${ONYELLOW} check mysql: 00:52:00 ${NORMAL}"

if type mysql >/dev/null 2>&1; then

  echo "mysql installed"

  if [ ! -f "magento/app/etc/local.xml" ] ; then # if file not exits
    echo -e "${RED} local.xml = null ${NORMAL}"
    if [ -f ".env" ] ; then # if file exits
      echo -e "${RED} .env ${NORMAL}"
      magento_sample_data_import_haifeng
      magento_install
    fi    
  fi

  if [ ! -f "magento/app/etc/local.xml" ] ; then # if file not exits
    magento_config_xml
  fi

else
    echo "mysql not installed"
fi

function_after

}

#

echo -e "${ONYELLOW} .env loading in the shell ${NORMAL}"

dotenv () {
  set -a
  [ -f .env ] && . .env
  set +a
}

dotenv

echo -e "${ONYELLOW} env MAGE_ ${NORMAL}"

env | grep ^MAGE_

#

METHOD=${1}

if [ "$METHOD" ]; then
  $METHOD
else
  echo -e "${ONRED} abort () { ${NORMAL}"
fi

# 

#curl --request POST "https://fleep.io/hook/OLuIRi0JRt2yv5OQisX6tg" --data $1
