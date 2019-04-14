#!/bin/bash

# Copyright © 2016-2019 Mozg. All rights reserved.

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
#set -Eeuxo pipefail
set -Eeu
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
function error() {
    JOB="$0"              # job name
    LASTLINE="$1"         # line of error occurrence
    LASTERR="$2"          # error code
    echo "ERROR in ${JOB} : line ${LASTLINE} with exit code ${LASTERR}"
    exit 1
}
trap 'error ${LINENO} ${?}' ERR

#

function setVars {

  RED='\033[0;31m'
  NC='\033[0m' # No Color
  echo -e "${RED} ${FUNCNAME[0]} ${NC}"

  SOURCE_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
  echo "SOURCE_DIR: $SOURCE_DIR"
  echo "SHELL: $SHELL"
  echo "TERM: $TERM"

  # Define text styles
  BOLD=''
  NORMAL=''
  [ -z ${TERM} ] || {
    #BOLD=`tput bold` # Error Heroku, tput: No value for $TERM and no -T specified
    #NORMAL=`tput sgr0`
    BOLD=$(tput bold)
    NORMAL=$(tput sgr0)
  }

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

function echio {
  local MESSAGE="$1"
  echo -e "${GREEN}${MESSAGE}${RESETCOLOR}"
}

function fnc_before {
  local _FUNCNAME="$1 {"
  echo -e "${ONBLUE}${_FUNCNAME}${RESETCOLOR}"
}

function fnc_after {
  echo -e "${ONBLUE}}${RESETCOLOR}"
}

# methods

function mysql_select_admin_user {

  fnc_before ${FUNCNAME[0]}

  MYSQL_SELECT_ADMIN_USER=`mysql -h "${RDS_HOSTNAME}" -P "${RDS_PORT}" -u "${RDS_USERNAME}" -p"${RDS_PASSWORD}" "${RDS_DB_NAME}" -N -e "SELECT * FROM admin_user"`

  echio "-"

  #echo $MYSQL_SELECT_ADMIN_USER

  fnc_after

}

function release_host {

  fnc_before ${FUNCNAME[0]}

  echio "Check local.xml"

  pwd

  echio "check n98-magerun"

  timeProg=`which n98-magerun`

  [[ "$(command -v n98-magerun)" ]] || { echo "n98-magerun is not installed" 1>&2 ; }
  [[ -f "./n98-magerun.phar" ]] || { echo "n98-magerun local installed" 1>&2 ; }

  if [ ! -f "./n98-magerun.phar" ]; then # -z String, True if string is empty.
  echio "n98-magerun"
  wget https://files.magerun.net/n98-magerun.phar
  chmod +x ./n98-magerun.phar
fi

./n98-magerun.phar --version

./n98-magerun.phar --root-dir=magento local-config:generate "$RDS_HOSTNAME:$RDS_PORT" "$RDS_USERNAME" "$RDS_PASSWORD" "$RDS_DB_NAME" "files" "admin" "secret" -vvv

fnc_after

}

function magento_sample_data_import_haifeng {

  fnc_before ${FUNCNAME[0]}

  #grep -ri 'LOCK TABLE' magento/vendor/mozgbrasil/magento-sample-data-1.9.2.4/magento_sample_data_for_1.9.2.4.sql

  # FIX Heroku: permission, LOCK TABLE
  awk '/LOCK TABLE/{n=1}; n {n--; next}; 1' < magento/vendor/mozgbrasil/magento-sample-data-1.9.2.4/magento_sample_data_for_1.9.2.4.sql > magento/vendor/mozgbrasil/magento-sample-data-1.9.2.4/magento_sample_data_for_1.9.2.4_unlock.sql

  #grep -ri 'LOCK TABLE' magento/vendor/mozgbrasil/magento-sample-data-1.9.2.4/magento_sample_data_for_1.9.2.4_unlock.sql

  echio "Importando..."

  if [ -f ".env" ] ; then # if file exits, only local
  echio ".env" "$ONRED"
  MYSQL_IMPORT=`mysql -h "${RDS_HOSTNAME}" -P "${RDS_PORT}" -u "${RDS_USERNAME}" -p"${RDS_PASSWORD}" "${RDS_DB_NAME}" < 'magento/vendor/mozgbrasil/magento-sample-data-1.9.2.4/magento_sample_data_for_1.9.2.4_unlock.sql'` # Heroku, Error R10 (Boot timeout) -> Web process failed to bind to $PORT within 60 seconds of launch
  echio "MYSQL_IMPORT=${MYSQL_IMPORT}" "$ONRED"
fi

#

#php bin/worker.php "$STRING_MYSQL_IMPORT" # heroku[run.8223]: Awaiting client, : Starting process with command

fnc_after

}

function is_folder_magento {

  fnc_before ${FUNCNAME[0]}

  if [ ! -f "mage" ] ; then # if file not exits
    echio "mage not exists"
    exit
  fi

  fnc_after

}

function magento_install {

  fnc_before ${FUNCNAME[0]}

  is_folder_magento

  echio "install.php"

  php -f install.php -- \
  --license_agreement_accepted "yes" \
  --locale "pt_BR" \
  --timezone "America/Sao_Paulo" \
  --default_currency "BRL" \
  --db_host "${RDS_HOSTNAME}:${RDS_PORT}" \
  --db_name "${RDS_DB_NAME}" \
  --db_user "${RDS_USERNAME}" \
  --db_pass "${RDS_PASSWORD}" \
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

  echio "magento/index.php"

  php index.php

  echio "shell"

  echio "compiler.php --state"

  php shell/compiler.php --state

  echio "log.php --clean"

  php shell/log.php --clean

  echio "indexer.php --status"

  php shell/indexer.php --status

  echio "indexer.php --info"

  php shell/indexer.php --info

  echio "indexer.php --reindexall"

  php shell/indexer.php --reindexall

  echio "mage"

  chmod +x mage

  bash ./mage

  echio "mage-setup"

  bash ./mage mage-setup

  echio "sync"

  bash ./mage sync

  echio "list-installed"

  bash ./mage list-installed

  echio "list-upgrades"

  bash ./mage list-upgrades

  echio "n98-magerun.phar"

  ../n98-magerun.phar config:set dev/template/allow_symlink 1

  fnc_after

}

function release {

  fnc_before ${FUNCNAME[0]}


  fnc_after

}

function post_update_cmd { # post-update-cmd: occurs after the update command has been executed, or after the install command has been executed without a lock file present.
# Na heroku o Mysql ainda não foi instalado nesse ponto

  fnc_before ${FUNCNAME[0]}

  echio "path"

  pwd

  echio "du"

  du -hsx ./* | sort -rh | head -10
  du -hsx magento/vendor/* | sort -rh | head -10

  echio "cp"

  if [ -d magento/vendor/mozgbrasil/magento-sample-data-1.9.2.4/media ]; then
    echio "mozgbrasil/magento-sample-data-1.9.2.4"
    echio "FIX: Heroku, Compiled slug size: 823M is too large (max is 500M)."
    cp -fr magento/vendor/mozgbrasil/magento-sample-data-1.9.2.4/media/* magento/media/
    cp -fr magento/vendor/mozgbrasil/magento-sample-data-1.9.2.4/skin/* magento/skin/
  fi

  if [ -d magento/vendor/ceckoslab/ceckoslab_quicklogin ]; then
    echio "ceckoslab/ceckoslab_quicklogin"
    cp -fr magento/vendor/ceckoslab/ceckoslab_quicklogin/app/* magento/app/
  fi

  mkdir backdoor

  if [ -d magento/vendor/prasathmani/tinyfilemanager ]; then
    echio "prasathmani/tinyfilemanager"
    cp -fr magento/vendor/prasathmani/tinyfilemanager/ backdoor
  fi

  if [ -d magento/vendor/maycowa/commando ]; then
    echio "maycowa/commando"
    cp -fr magento/vendor/maycowa/commando/ backdoor
  fi

  profile

  fnc_after

}

function post_install_cmd { # post-install-cmd: occurs after the install command has been executed with a lock file present.

fnc_before ${FUNCNAME[0]}

post_update_cmd

fnc_after

}

function postdeploy { # postdeploy command. Use this to run any one-time setup tasks that make the app, and any databases, ready and useful for testing.

fnc_before ${FUNCNAME[0]}

post_update_cmd # post-update-cmd: occurs after the update command has been executed, or after the install command has been executed without a lock file present.

fnc_after

}

function profile { # Heroku, During startup, the container starts a bash shell that runs any code in $HOME/.profile before executing the dyno’s command. You can put bash code in this file to manipulate the initial environment, at runtime, for all dyno types in your app.

fnc_before ${FUNCNAME[0]}

echio "path"

pwd
cd $SOURCE_DIR/magento
pwd

echio "Aplicando permissões"
# https://devdocs.magento.com/guides/m1x/install/installer-privilegesfnc_after.html

#chmod 777 -R /home/marcio/dados/mozgbrasil/magento/magento/var

if [ -f .env ] ; then # if file exits
  echio ".env" "$ONRED"
  # Ubuntu local
  chown -R $USER:www-data .
fi

echio "pwd && ls -lah magento/app/etc"

pwd && ls -lah magento/app/etc

echio "check mysql"

if type mysql >/dev/null 2>&1; then

  echio "mysql installed"

  if [ -f ".env" ] ; then # if file exits, only local
  if [ ! -f "magento/app/etc/local.xml" ] ; then # if file not exits
  magento_sample_data_import_haifeng
  magento_install
fi
fi

else
  echio "mysql not installed" "$ONRED"
fi

echio "-"

if [ ! -f ".env" ] ; then # if file not exits, only heroku ...
if [ ! -f "magento/app/etc/local.xml" ] ; then # if file not exits
release_host
fi
fi

fnc_after

}

function test {
  fnc_before ${FUNCNAME[0]}
  echio "SUCCESS"
  fnc_after
}

#

echio "env RDS_"
env | grep ^RDS_ || true

echio ".env loading in the shell"

function dotenv {
  set -a
  [ -f "$1" ] && . "$1"
  set +a
}

dotenv ".env"

echio "env RDS_"
env | grep ^RDS_ || true

#

METHOD=${1}

if [ ! -z $METHOD ]; then # -z String, True if string is empty.
  $METHOD
fi
