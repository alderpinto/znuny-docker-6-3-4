#!/bin/bash
# Startup script for this OTRS container.
#
# The script by default loads a fresh OTRS install ready to be customized through
# the admin web interface.
#
# If the environment variable ZNUNY_INSTALL is set to yes, then the default web
# installer can be run from localhost/otrs/installer.pl.
#
# If the environment variable ZNUNY_INSTALL="restore", then the configuration backup
# files will be loaded from ${ZNUNY_ROOT}/backups. This means you need to build
# the image with the backup files (sql and Confg.pm) you want to use, or, mount a
# host volume to map where you store the backup files to ${ZNUNY_ROOT}/backups.
#
# To change the default database and admin interface user passwords you can define
# the following env vars too:
# - ZNUNY_DB_PASSWORD to set the database password
# - ZNUNY_ROOT_PASSWORD to set the admin user 'root@localhost' password.
#
. /util_functions.sh
. /znuny_ascii_logo.sh

function enable_debug_mode () {
  print_info "Preparing debug mode..."
  yum install -y telnet dig
  [ $? -gt 0 ] && print_error "ERROR: Could not intall debug tools." && exit 1
  print_info "Done."
  env
  set -x
}

if [ "$ZNUNY_DEBUG" == "yes" ];then
  enable_debug_mode
fi

function random_string() {
  echo `cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`
}

function apply_docker_secrets() {
  print_info "Apply docker secrets..."
  if [ -f $ZNUNY_SECRETS_FILE ]; then
    . $ZNUNY_SECRETS_FILE
    return 0
  else
    print_warning "Secrets file $ZNUNY_SECRETS_FILE not found"
  fi
}

#Default configuration values
DEFAULT_ZNUNY_ROOT_PASSWORD="changeme"
DEFAULT_ZNUNY_DB_PASSWORD="changeme"
DEFAULT_ZNUNY_DB_ROOT_PASSWORD="changeme"
DEFAULT_ZNUNY_DB_NAME="otrs"
DEFAULT_ZNUNY_DB_USER="otrs"
DEFAULT_ZNUNY_DB_ROOT_USER="root"
DEFAULT_ZNUNY_DB_HOST="mariadb"
DEFAULT_ZNUNY_DB_PORT=3306
DEFAULT_ZNUNY_BACKUP_TIME="0 4 * * *"
DEFAULT_BACKUP_SCRIPT="/ZNUNY_backup.sh"
DEFAULT_ZNUNY_CRON_BACKUP_SCRIPT="/etc/cron.d/ZNUNY_backup"
ZNUNY_BACKUP_DIR="/var/otrs/backups"
ZNUNY_CONFIG_DIR="${ZNUNY_ROOT}/Kernel/"
ZNUNY_CONFIG_FILE="${ZNUNY_CONFIG_DIR}Config.pm"
ZNUNY_CONFIG_MOUNT_DIR="/otrs"
WAIT_TIMEOUT=2
ZNUNY_ASCII_COLOR_BLUE="38;5;31"
ZNUNY_ASCII_COLOR_RED="31"
ZNUNY_BACKUP_SCRIPT="${ZNUNY_BACKUP_SCRIPT:-/ZNUNY_backup.sh}"
ZNUNY_CRON_BACKUP_SCRIPT="${ZNUNY_CRON_BACKUP_SCRIPT:-/etc/cron.d/ZNUNY_backup}"
ZNUNY_ARTICLE_STORAGE_TYPE="${ZNUNY_ARTICLE_STORAGE_TYPE:-ArticleStorageDB}"
ZNUNY_UPGRADE="${ZNUNY_UPGRADE:-no}"
ZNUNY_UPGRADE_BACKUP="${ZNUNY_UPGRADE_BACKUP:-yes}"
ZNUNY_ADDONS_PATH="${ZNUNY_ROOT}/addons/"
INSTALLED_ADDONS_DIR="${ZNUNY_ADDONS_PATH}/installed"
ZNUNY_UPGRADE_SQL_FILES="${ZNUNY_ROOT}/db_upgrade"
ZNUNY_UPGRADE_XML_FILES="${ZNUNY_UPGRADE_XML_FILES:-no}"
ZNUNY_DISABLE_EMAIL_FETCH="${ZNUNY_DISABLE_EMAIL_FETCH:-no}"
ZNUNY_SET_PERMISSIONS="${ZNUNY_SET_PERMISSIONS:-yes}"
ZNUNY_ALLOW_NOT_VERIFIED_PACKAGES="${ZNUNY_ALLOW_NOT_VERIFIED_PACKAGES:-no}"
_MINOR_VERSION_UPGRADE=false

[ ! -z "${ZNUNY_SECRETS_FILE}" ] && apply_docker_secrets
[ -z "${ZNUNY_INSTALL}" ] && ZNUNY_INSTALL="no"
[ -z "${ZNUNY_DB_NAME}" ] && print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mZNUNY_DB_NAME\e[0m not set, setting value to \e[${ZNUNY_ASCII_COLOR_RED}m${DEFAULT_ZNUNY_DB_NAME}\e[0m" && ZNUNY_DB_NAME=${DEFAULT_ZNUNY_DB_NAME}
[ -z "${ZNUNY_DB_USER}" ] && print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mZNUNY_DB_USER\e[0m not set, setting value to \e[${ZNUNY_ASCII_COLOR_RED}m${DEFAULT_ZNUNY_DB_USER}\e[0m" && ZNUNY_DB_USER=${DEFAULT_ZNUNY_DB_USER}
[ -z "${ZNUNY_DB_HOST}" ] && print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mDZNUNY_DB_HOST\e[0m not set, setting value to \e[${ZNUNY_ASCII_COLOR_RED}m${DEFAULT_ZNUNY_DB_HOST}\e[0m" && ZNUNY_DB_HOST=${DEFAULT_ZNUNY_DB_HOST}
[ -z "${ZNUNY_DB_PORT}" ] && print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mZNUNY_DB_PORT\e[0m not set, setting value to \e[${ZNUNY_ASCII_COLOR_RED}m${DEFAULT_ZNUNY_DB_PORT}\e[0m" && ZNUNY_DB_PORT=${DEFAULT_ZNUNY_DB_PORT}
[ -z "${SHOW_ZNUNY_LOGO}" ] && SHOW_ZNUNY_LOGO="yes"
[ -z "${ZNUNY_HOSTNAME}" ] && ZNUNY_HOSTNAME="otrs-`random_string`" && print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mZNUNY_HOSTNAME\e[0m not set, setting hostname to '${ZNUNY_HOSTNAME}'"
[ -z "${ZNUNY_DB_PASSWORD}" ] && print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mZNUNY_DB_PASSWORD\e[0m not set, setting password to \e[${ZNUNY_ASCII_COLOR_RED}m${DEFAULT_ZNUNY_DB_PASSWORD}\e[0m" && ZNUNY_DB_PASSWORD=${DEFAULT_ZNUNY_DB_PASSWORD}
[ -z "${ZNUNY_ROOT_PASSWORD}" ] && print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mZNUNY_ROOT_PASSWORD\e[0m not set, setting password to \e[${ZNUNY_ASCII_COLOR_RED}m${DEFAULT_ZNUNY_ROOT_PASSWORD}\e[0m" && ZNUNY_ROOT_PASSWORD=${DEFAULT_ZNUNY_ROOT_PASSWORD}
[ -z "${ZNUNY_DB_ROOT_PASSWORD}" ] && print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mZNUNY_DB_ROOT_PASSWORD\e[0m not set, setting password to \e[${ZNUNY_ASCII_COLOR_RED}m${DEFAULT_ZNUNY_DB_ROOT_PASSWORD}\e[0m" && ZNUNY_DB_ROOT_PASSWORD=${DEFAULT_ZNUNY_DB_ROOT_PASSWORD}
[ -z "${ZNUNY_DB_ROOT_USER}" ] && print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mZNUNY_DB_ROOT_USER\e[0m not set, setting user to \e[${ZNUNY_ASCII_COLOR_RED}m${DEFAULT_ZNUNY_DB_ROOT_USER}\e[0m" && ZNUNY_DB_ROOT_USER=${DEFAULT_ZNUNY_DB_ROOT_USER}
[ -z "${ZNUNY_BACKUP_TIME}" ] && print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mZNUNY_BACKUP_TIME\e[0m not set, setting value to \e[${ZNUNY_ASCII_COLOR_RED}m${DEFAULT_ZNUNY_BACKUP_TIME}\e[0m" && ZNUNY_BACKUP_TIME=${DEFAULT_ZNUNY_BACKUP_TIME}
[ ! -z "${ZNUNY_CRON_BACKUP_SCRIPT}" ] && print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mSetting ZNUNY_CRON_BACKUP_SCRIPT\e[0m to \e[${ZNUNY_ASCII_COLOR_RED}m${ZNUNY_CRON_BACKUP_SCRIPT}\e[0m"
[ ! -z "${ZNUNY_ARTICLE_STORAGE_TYPE}" ] && print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mSetting ZNUNY_ARTICLE_STORAGE_TYPE\e[0m to \e[${ZNUNY_ASCII_COLOR_RED}m${ZNUNY_ARTICLE_STORAGE_TYPE}\e[0m"

mysqlcmd="mysql -u${ZNUNY_DB_ROOT_USER} -h ${ZNUNY_DB_HOST} -P ${ZNUNY_DB_PORT} -p${ZNUNY_DB_ROOT_PASSWORD} "
psqlcmd="psql postgresql://${ZNUNY_DB_ROOT_USER}:${ZNUNY_DB_ROOT_PASSWORD}@${ZNUNY_DB_HOST}:${ZNUNY_DB_PORT} "

function wait_for_db() {
  db=${ZNUNY_DB_TYPE}
  case $db in
    mysql)
      while [ ! "$(mysqladmin ping -h ${ZNUNY_DB_HOST} -P ${ZNUNY_DB_PORT} -u ${ZNUNY_DB_ROOT_USER} \
                  --password="${ZNUNY_DB_ROOT_PASSWORD}" --silent --connect_timeout=3)" ]; do
        print_info "Database server is not available. Waiting ${WAIT_TIMEOUT} seconds..."
        sleep ${WAIT_TIMEOUT}
      done
      print_info "Database server is up !"
    ;;
    postgresql|pgsql)
      while pg_isready -h ${ZNUNY_DB_HOST} -p ${ZNUNY_DB_PORT} -U ${ZNUNY_DB_ROOT_USER} > /dev/null;[ $? -ne 0 ];do
        print_info "Database server is not available. Waiting ${WAIT_TIMEOUT} seconds..."
        sleep ${WAIT_TIMEOUT}
      done
      print_info "Database server is up !"
    ;;
  esac
}

function create_db() {
  db=${ZNUNY_DB_TYPE}
  case $db in
    mysql)
      print_info "Creating OTRS database..."
      $mysqlcmd -e "CREATE DATABASE IF NOT EXISTS ${ZNUNY_DB_NAME};"
      [ $? -gt 0 ] && print_error "Couldn't create OTRS database !!" && exit 1
      $mysqlcmd -e " GRANT ALL ON ${ZNUNY_DB_NAME}.* to '${ZNUNY_DB_USER}'@'%' identified by '${ZNUNY_DB_PASSWORD}'";
      [ $? -gt 0 ] && print_error "Couldn't create database user !!" && exit 1
    ;;
    postgresql|pgsql)
      print_info "Creating OTRS database..."
      $psqlcmd -tc "SELECT 1 FROM pg_database WHERE datname = '${ZNUNY_DB_NAME}'" | grep -q 1  
      [ $? -eq 0 ] && print_error "OTRS database, exist !!" && exit 1
      $psqlcmd -c "CREATE ROLE ${ZNUNY_DB_USER} WITH LOGIN PASSWORD '${ZNUNY_DB_PASSWORD}'" 2>/dev/null
      [ $? -gt 0 ] && print_error "Couldn't create database user !!" && exit 1
      $psqlcmd -c "CREATE DATABASE ${ZNUNY_DB_NAME} OWNER=${ZNUNY_DB_USER} ENCODING 'utf-8'" 2>/dev/null
      [ $? -gt 0 ] && print_error "Couldn't create OTRS database !!" && exit 1
    ;;
  esac
}

function restore_backup_mysql() {
  [ -z $1 ] && print_error "ZNUNY_BACKUP_DATE not set." && exit 1
  #Check if a host-mounted volume for configuration storage was added to this
  #container
  check_host_mount_dir
  add_config_value "DatabaseUser" ${ZNUNY_DB_USER}
  add_config_value "DatabasePw" ${ZNUNY_DB_PASSWORD} true
  add_config_value "DatabaseHost" ${ZNUNY_DB_HOST}
  add_config_value "DatabasePort" ${ZNUNY_DB_PORT}
  add_config_value "Database" ${ZNUNY_DB_NAME}

  #Check first that the backup file exists
  restore_file="${ZNUNY_BACKUP_DIR}/${ZNUNY_BACKUP_DATE}"
  if [ -f ${restore_file} ]; then
    #Check file integrity
    if (! tar tf ${restore_file} &> /dev/null) || (! tar xOf ${restore_file} &> /dev/null); then
      print_error "Backup file is corrupt !!" && exit 1
    fi
    # Uncompress file
    temp_dir=$(mktemp -d )
    cd ${temp_dir}
    tar zxvf ${restore_file}
    [ $? -gt 0 ] && print_error "Could not uncompress main backup file !!" && exit 1
    cd ..
    restore_dir="$(ls -t ${temp_dir}|head -n1)"

  elif [[ -d ${restore_file} ]]; then
    restore_dir="${restore_file}/"
  else
    print_error "Backup file does not exist !!" && exit 1
  fi

  #As this is a restore, drop database first.
  $mysqlcmd -e "use ${ZNUNY_DB_NAME}"
  if [ $? -eq 0  ]; then
    if [ "${ZNUNY_DROP_DATABASE}" == "yes" ]; then
      print_info "\e[${ZNUNY_ASCII_COLOR_BLUE}mZNUNY_DROP_DATABASE=\e[0m\e[${ZNUNY_ASCII_COLOR_RED}m${ZNUNY_DROP_DATABASE}\e[0m, Dropping existing database\n"
      $mysqlcmd -e "drop database ${ZNUNY_DB_NAME}"
    else
      print_error "Couldn't load OTRS backup, databse already exists !!" && exit 1
    fi
  fi

  create_db
  #Make a copy of installed skins so they aren't overwritten by the backup.
  tmpdir=`mktemp -d`
  [ ! -z $ZNUNY_AGENT_SKIN ] && cp -rp ${SKINS_PATH}Agent $tmpdir/
  [ ! -z $ZNUNY_CUSTOMER_SKIN ] && cp -rp ${SKINS_PATH}Customer $tmpdir/

  restore_dir=${temp_dir}/${restore_dir}
  ${ZNUNY_ROOT}/scripts/restore.pl -b ${restore_dir} -d ${ZNUNY_ROOT}
  [ $? -gt 0 ] && print_error "Couldn't load OTRS backup !!" && exit 1

  backup_version=`tar -xOf ${restore_dir}/Application.tar.gz ./RELEASE|grep -o 'VERSION = [^,]*' | cut -d '=' -f2 |tr -d '[[:space:]]'`
  [ $? -gt 0 ] && print_error "Couldn't get installed OTRS version !!" && exit 1
  ZNUNY_INSTALLED_VERSION=`echo $ZNUNY_VERSION|cut -d '-' -f1`
  print_warning "OTRS version of backup being restored: \e[1;31m$backup_version\e[1;0m"
  print_warning "OTRS version of this container: \e[1;31m$ZNUNY_INSTALLED_VERSION\e[1;0m"

  check_version ${ZNUNY_INSTALLED_VERSION} $backup_version
  if [ $? -eq 1 ]; then
    print_warning "Backup version different than current OTRS version, fixing..."
    #Update version on ${ZNUNY_ROOT}/RELEASE so it the website shows the correct version.
    sed -i -r "s/(VERSION *= *).*/\1${ZNUNY_INSTALLED_VERSION}/" ${ZNUNY_ROOT}/RELEASE
    print_info "Done."
  fi

  #Restore configured password overwritten by restore
  setup_znuny_config

  #Copy back skins over restored files
  [ ! -z ${ZNUNY_CUSTOMER_SKIN} ] && cp -rfp ${tmpdir}/* ${SKINS_PATH} && rm -fr ${tmpdir}

  #Update the skin preferences  in the users from the backup
  set_users_skin
}

# return 0 if program version is equal or greater than check version
check_version() {
    local version=$1 check=${2}
    local winner=$(echo -e "$version\n$check" | sed '/^$/d' | sort -nr | head -1)
    [[ "$winner" = "$version" ]] && return 0
    return 1
}

function add_config_value() {
  local key=${1}
  local value=${2}
  local mask=${3:-false}

  if [ "${mask}" == true ]; then
    print_value="**********"
  else
    print_value=${value}
  fi

  grep -qE "\{[^}]*${key}[^}]*\}.*=" ${ZNUNY_CONFIG_FILE}
  if [ $? -eq 0 ]
  then
    print_info "Updating configuration option \e[${ZNUNY_ASCII_COLOR_BLUE}m${key}\e[0m with value: \e[31m${print_value}\e[0m"
    sed  -i -r "s/($Self->\{*$key*\} *= *).*/\1\"${value}\";/" ${ZNUNY_CONFIG_FILE}
  else
    print_info "Adding configuration option \e[${ZNUNY_ASCII_COLOR_BLUE}m${key}\e[0m with value: \e[31m${print_value}\e[0m"
    sed -i "/$Self->{Home} = '\/opt\/otrs';/a \
    \$Self->{'${key}'} = '${value}';" ${ZNUNY_CONFIG_FILE}
  fi
}

function change_database_type() {
 db=${ZNUNY_DB_TYPE}
  case $db in
    mysql)
      sed -i '/^.*\$Self->{DatabaseDSN}.*DBI:Pg:dbname=\$Self->{Database};host=\$Self->{DatabaseHost}/ s/^/#/' ${ZNUNY_CONFIG_FILE}
      sed -i '/^\#.*\$Self->{DatabaseDSN}.*DBI:mysql:database=\$Self->{Database};host=\$Self->{DatabaseHost}/ s/^#//' ${ZNUNY_CONFIG_FILE}
    ;;
    postgresql|pgsql)
      sed -i '/^.*\$Self->{DatabaseDSN}.*DBI:mysql:database=\$Self->{Database};host=\$Self->{DatabaseHost}/ s/^/#/' ${ZNUNY_CONFIG_FILE}
      sed -i '/^\#.*\$Self->{DatabaseDSN}.*DBI:Pg:dbname=\$Self->{Database};host=\$Self->{DatabaseHost}/ s/^#//' ${ZNUNY_CONFIG_FILE}
    ;;
  esac
}


# Sets default configuration options on $ZNUNY_ROOT/Kernel/Config.pm. Options set
# here can't be modified via sysConfig later.
function setup_znuny_config() {
  #Set type database
  change_database_type
  #Set database configuration
  add_config_value "DatabaseUser" ${ZNUNY_DB_USER}
  add_config_value "DatabasePw" ${ZNUNY_DB_PASSWORD} true
  add_config_value "DatabaseHost" ${ZNUNY_DB_HOST}
  add_config_value "DatabasePort" ${ZNUNY_DB_PORT}
  add_config_value "Database" ${ZNUNY_DB_NAME}
  #Set general configuration values
  [ ! -z "${ZNUNY_LANGUAGE}" ] && add_config_value "DefaultLanguage" ${ZNUNY_LANGUAGE}
  [ ! -z "${ZNUNY_TIMEZONE}" ] && add_config_value "OTRSTimeZone" ${ZNUNY_TIMEZONE} && add_config_value "UserDefaultTimeZone" ${ZNUNY_TIMEZONE}
  add_config_value "FQDN" ${ZNUNY_HOSTNAME}
  #Set email SMTP configuration

  [ ! -z "${ZNUNY_SENDMAIL_MODULE}" ] && add_config_value "SendmailModule" "Kernel::System::Email::${ZNUNY_SENDMAIL_MODULE}"
  [ ! -z "${ZNUNY_SMTP_SERVER}" ] && add_config_value "SendmailModule::Host" "${ZNUNY_SMTP_SERVER}"
  [ ! -z "${ZNUNY_SMTP_PORT}" ] && add_config_value "SendmailModule::Port" "${ZNUNY_SMTP_PORT}"
  [ ! -z "${ZNUNY_SMTP_USERNAME}" ] && add_config_value "SendmailModule::AuthUser" "${ZNUNY_SMTP_USERNAME}"
  [ ! -z "${ZNUNY_SMTP_PASSWORD}" ] && add_config_value "SendmailModule::AuthPassword" "${ZNUNY_SMTP_PASSWORD}" true
  add_config_value "SecureMode" "1"
  # Configure automatic backups
  setup_backup_cron
  # Reinstall any existing addons
  reinstall_modules
}

function load_defaults() {
  local current_version_file="${ZNUNY_CONFIG_MOUNT_DIR}/current_version"

  # Check if OTRS minor version changed and do a minor version upgrade
  if [ -e ${current_version_file} ] && [ ${ZNUNY_UPGRADE} != "yes" ]; then
    current_version=$(cat ${current_version_file})
    new_version=$(echo ${ZNUNY_VERSION}|cut -d'-' -f1)
    print_info "Current installed OTRS version: \e[1;31m$current_version\e[1;0m"
    print_info "Starting up container with OTRS version: \e[1;31m$new_version\e[1;0m"
    check_version ${current_version} ${new_version}
    if [ $? -eq 1 ]; then
      print_info "Doing minor version upgrade from \e[${ZNUNY_ASCII_COLOR_BLUE}m${current_version}\e[0m to \e[${ZNUNY_ASCII_COLOR_RED}m${new_version}\e[0m"
      upgrade_minor_version
      upgrade_modules
      _MINOR_VERSION_UPGRADE=true
      echo ${new_version} > ${current_version_file}
    fi
  else
    current_version=$(cat ${ZNUNY_CONFIG_MOUNT_DIR}/RELEASE |grep VERSION|cut -d'=' -f2)
    current_version="${current_version## }"
    echo "${current_version}" > "${current_version_file}"
  fi

  #Check if a host-mounted volume for configuration storage was added to this
  #container
  check_host_mount_dir
  #check_custom_skins_dir
  #Setup OTRS configuration
  setup_znuny_config

  #Check if database doesn't exists yet (it could if this is a container redeploy)
  db=${ZNUNY_DB_TYPE}
  case $db in
    mysql)
      $mysqlcmd -e "use ${ZNUNY_DB_NAME}"
      if [ $? -gt 0 ]; then
        create_db

        #Check that a backup isn't being restored
        if [ "$ZNUNY_INSTALL" == "no" ]; then
          print_info "Loading default db schemas..."
          $mysqlcmd ${ZNUNY_DB_NAME} < ${ZNUNY_ROOT}/scripts/database/otrs-schema.mysql.sql
          [ $? -gt 0 ] && print_error "\n\e[1;31mERROR:\e[0m Couldn't load schema.mysql.sql schema !!\n" && exit 1
          print_info "Loading initial db inserts..."
          $mysqlcmd ${ZNUNY_DB_NAME} < ${ZNUNY_ROOT}/scripts/database/otrs-initial_insert.mysql.sql
          [ $? -gt 0 ] && print_error "\n\e[1;31mERROR:\e[0m Couldn't load OTRS database initial inserts !!\n" && exit 1
          print_info "Loading initial schema constraints..."
          $mysqlcmd ${ZNUNY_DB_NAME} < ${ZNUNY_ROOT}/scripts/database/otrs-schema-post.mysql.sql
          [ $? -gt 0 ] && print_error "\n\e[1;31mERROR:\e[0m Couldn't load schema-post.mysql.sql schema !!\n" && exit 1
        fi
      else
        print_warning "otrs database already exists, Ok."
      fi
    ;;
    postgresql|pgsql)
      $psqlcmd -tc "SELECT 1 FROM pg_database WHERE datname = '${ZNUNY_DB_NAME}'" | grep -q 1
      if [ $? -gt 0 ]; then
        create_db

        #Check that a backup isn't being restored
        if [ "$ZNUNY_INSTALL" == "no" ]; then
          psqldbcmd="psql postgresql://${ZNUNY_DB_USER}:${ZNUNY_DB_PASSWORD}@${ZNUNY_DB_HOST}:${ZNUNY_DB_PORT}/${ZNUNY_DB_NAME} " 
          print_info "Loading default db schemas..."
          $psqldbcmd < ${ZNUNY_ROOT}/scripts/database/otrs-schema.postgresql.sql
          [ $? -gt 0 ] && print_error "\n\e[1;31mERROR:\e[0m Couldn't load schema.postgresql.sql schema !!\n" && exit 1
          print_info "Loading initial db inserts..."
          $psqldbcmd < ${ZNUNY_ROOT}/scripts/database/otrs-initial_insert.postgresql.sql
          [ $? -gt 0 ] && print_error "\n\e[1;31mERROR:\e[0m Couldn't load OTRS database initial inserts !!\n" && exit 1
          print_info "Loading initial schema constraints..."
          $psqldbcmd < ${ZNUNY_ROOT}/scripts/database/otrs-schema-post.postgresql.sql
          [ $? -gt 0 ] && print_error "\n\e[1;31mERROR:\e[0m Couldn't load schema.postgresql.sql schema !!\n" && exit 1
        fi
      else
        print_warning "otrs database already exists, Ok."
      fi
    ;;
  esac
}

function set_ticket_counter() {
  if [ ! -z "${ZNUNY_TICKET_COUNTER}" ]; then
    print_info "Setting the start of the ticket counter to: \e[${ZNUNY_ASCII_COLOR_BLUE}m'${ZNUNY_TICKET_COUNTER}'\e[0m"
    echo "${ZNUNY_TICKET_COUNTER}" > ${ZNUNY_ROOT}/var/log/TicketCounter.log
  fi
  if [ ! -z $ZNUNY_NUMBER_GENERATOR ]; then
    add_config_value "Ticket::NumberGenerator" "Kernel::System::Ticket::Number::${ZNUNY_NUMBER_GENERATOR}"
  fi
}

function set_skins() {
  if [ ! -z ${ZNUNY_AGENT_SKIN} ]; then
    add_config_value "Loader::Agent::DefaultSelectedSkin" ${ZNUNY_AGENT_SKIN}
    print_info "Setting Agent interface custom logo..."
    # Remove AgentLogo option to disable default logo so the skin one is picked up
    sed -i '/AgentLogo/,/;/d' ${ZNUNY_CONFIG_DIR}/Config/Files/ZZZAAuto.pm
    # Also disable default value of sysconfig so XML/Framework.xml AgentLogo is valid=0
    $mysqlcmd -e "UPDATE sysconfig_default SET is_valid = 0 WHERE name = 'AgentLogo'" otrs
  fi
  [ ! -z ${ZNUNY_AGENT_SKIN} ] &&  add_config_value "Loader::Customer::SelectedSkin" ${ZNUNY_CUSTOMER_SKIN}
}

function set_users_skin() {
  print_info "Updating default skin for users in backup..."
  $mysqlcmd -e "UPDATE user_preferences SET preferences_value = '${ZNUNY_AGENT_SKIN}' WHERE preferences_key = 'UserSkin'" otrs
  [ $? -gt 0 ] && print_error "Couldn't change default skin for existing users !!\n"
}

function check_host_mount_dir() {
  #Copy the configuration from /otrs (put there by the Dockerfile) to $ZNUNY_CONFIG_MOUNT_DIR
  #to be able to use host-mounted volumes. copy only if ${ZNUNY_CONFIG_MOUNT_DIR} doesn't exist
  #if ([ "$(ls -A ${ZNUNY_ROOT})" ] && [ ! "$(ls -A ${ZNUNY_CONFIG_DIR})" ]);
  if [ ! "$(ls -A ${ZNUNY_ROOT})" ] || [ "${ZNUNY_UPGRADE}" == "yes" ] || [ ${_MINOR_VERSION_UPGRADE} == true ];
  then
    print_info "Found empty \e[${ZNUNY_ASCII_COLOR_BLUE}m${ZNUNY_ROOT}e[0m, copying default configuration to it..."
    mkdir -p ${ZNUNY_ROOT}
    cp -rfp ${ZNUNY_CONFIG_MOUNT_DIR}/* ${ZNUNY_ROOT}
    if [ $? -eq 0 ];
      then
        print_info "Done."
      else
        print_error "Can't move OTRS configuration directory to ${ZNUNY_ROOT}" && exit 1
    fi
  else
    print_info "Found existing configuration directory, Ok."
  fi
}

function check_custom_skins_dir() {
  #Copy the default skins from /skins (put there by the Dockerfile) to $SKINS_PATH
  #to be able to use host-mounted volumes.
  print_info "Copying default skins..."
  mkdir -p ${SKINS_PATH}
  cp -rfp ${ZNUNY_SKINS_MOUNT_DIR}/* ${SKINS_PATH}
  if [ $? -eq 0 ];
    then
      print_info "Done."
    else
      print_error "Can't copy default skins to ${SKINS_PATH}" && exit 1
  fi
}

ERROR_CODE="ERROR"
OK_CODE="OK"
INFO_CODE="INFO"
WARN_CODE="WARNING"

function write_log () {
  message="$1"
  code="$2"

  echo "$[ 1 + $[ RANDOM % 1000 ]]" >> ${BACKUP_LOG_FILE}
  echo "Status=$code,Message=$message" >> ${BACKUP_LOG_FILE}
}

function reinstall_modules () {
  if [ "${ZNUNY_UPGRADE}" != "yes" ]; then
    print_info "Reinstalling OTRS addons..."
    su -c "$ZNUNY_ROOT/bin/otrs.Console.pl Admin::Package::ReinstallAll > /dev/null 2>&1" -s /bin/bash otrs

    if [ $? -gt 0 ]; then
      print_error "Could not reinstall OTRS addons, try to do it manually with the Package Manager in the admin section of the web interface."
    else
      print_info "Done."
    fi
  fi
}

function upgrade_modules () {
    print_info "Upgrading OTRS addons..."
    su -c "$ZNUNY_ROOT/bin/otrs.Console.pl Admin::Package::UpgradeAll > /dev/null 2>&1" -s /bin/bash otrs

    if [ $? -gt 0 ]; then
      print_error "Could not upgrade OTRS addons, try to do it manually with the Package Manager in the admin section of the web interface."
    else
      print_info "Done."
    fi
}


function install_modules () {
  location=${1}
  mkdir -p ${INSTALLED_ADDONS_DIR}

  print_info "Installing OTRS addons..."
  if [ "${location}" != "" ]; then
    packages="$(ls ${location}/*.opm 2> /dev/null)"
    if [ "${packages}" != "" ]; then

      for i in ${packages}; do
        print_info "Installing addon: ${i}"
        su -c "$ZNUNY_ROOT/bin/otrs.Console.pl Admin::Package::Install ${i}> /dev/null 2>&1" -s /bin/bash otrs
        if [ $? -gt 0 ]; then
          print_error "Could not install OTRS addon: ${i}, try to do it manually with the Package Manager in the admin section of the web interface."
        else
          mv ${i} ${INSTALLED_ADDONS_DIR}
        fi
      done
      print_info "Done."
    else
      print_info "No addons found to install."
    fi
  else
    print_info "No directory with addons to install."
  fi
}


# SIGTERM-handler
function term_handler () {
 systemctl stop supervisord
 pkill -SIGTERM anacron
 su -c "${ZNUNY_ROOT}/bin/otrs.Daemon.pl stop" -s /bin/bash otrs
 exit 143; # 128 + 15 -- SIGTERM
}

function stop_all_services () {
  print_info "Stopping all OTRS services..."
  supervisorctl stop all
  su -c "${ZNUNY_ROOT}/bin/Cron.sh stop" -s /bin/bash otrs
  su -c "${ZNUNY_ROOT}/bin/otrs.Daemon.pl stop" -s /bin/bash otrs
}

function start_all_services () {
  print_info "Starting all OTRS services..."
  supervisorctl start all
  su -c "${ZNUNY_ROOT}/bin/otrs.Daemon.pl start" -s /bin/bash otrs
  su -c "${ZNUNY_ROOT}/bin/Cron.sh start" -s /bin/bash otrs
}

function fix_database_upgrade_mysql() {
  print_info "[*] Running database pre-upgrade scripts..." | tee -a ${upgrade_log}
  $mysqlcmd -e "use ${ZNUNY_DB_NAME}"
  if [ $? -eq 0  ]; then
    sql_files="$(ls ${ZNUNY_UPGRADE_SQL_FILES/*.sql})"

    #Get all sql files and load them into the database
    if [[ "${sql_files}" != "" ]]; then
      for i in ${sql_files}; do
        print_info "Loading SQL file: ${i}"
        $mysqlcmd otrs < ${ZNUNY_UPGRADE_SQL_FILES}/${i} | tee -a ${upgrade_log}
        if [ $? -gt 0  ]; then
          print_error "Cannot load sql file: ${ZNUNY_UPGRADE_SQL_FILES}/${i}" | tee -a ${upgrade_log} && exit 1
        fi
        print_info "Done"
      done
    else
      print_info "No additional SQL files to load were found."
    fi
  else
    print_error "Database does not exist!" && exit 1
  fi
}

function upgrade_cleanup_configuration (){
  # Remove old, deprecated settings which are not present in any of the install files in Kernel/Config/Files/XML/

  print_info "[*] Cleaning up configuration: Removing old unsupported settings..." | tee -a ${upgrade_log}
  su -c "${ZNUNY_ROOT}/bin/otrs.Console.pl Maint::Config::Rebuild --cleanup" -s /bin/bash otrs | tee -a ${upgrade_log}
  if [ $? -gt 0  ]; then
    print_error "Cannot cleanup configuration!" | tee -a ${upgrade_log} && exit 1
  fi
}

function upgrade_minor_version() {
  # Upgrade database
  print_info "[*] Doing minor version upgrade, running DBUpdate-to-6.pl script..." | tee -a ${upgrade_log}

  # Cleanup configuration
  upgrade_cleanup_configuration

  $mysqlcmd -e "use ${ZNUNY_DB_NAME}"
  if [ $? -eq 0  ]; then
    su -c "${ZNUNY_ROOT}/scripts/DBUpdate-to-6.pl --non-interactive" -s /bin/bash otrs | tee -a ${upgrade_log}
    if [ $? -gt 0  ]; then
      print_error "Cannot migrate database" | tee -a ${upgrade_log} && exit 1
    fi
  else
    print_error "Database does not exist!" && exit 1
  fi
}

function upgrade_database() {
  # Upgrade database
  print_info "[*] Doing database migration..." | tee -a ${upgrade_log}
  $mysqlcmd -e "use ${ZNUNY_DB_NAME}"
  if [ $? -eq 0  ]; then
    su -c "/opt/otrs//scripts/DBUpdate-to-6.pl" -s /bin/bash otrs | tee -a ${upgrade_log}
    if [ $? -gt 0  ]; then
      print_error "Cannot migrate database" | tee -a ${upgrade_log} && exit 1
    fi
    grep -q "Not possible to complete migration" ${upgrade_log}
    if [ $? -eq 0 ]; then
      print_error "[2] Cannot migrate database" | tee -a ${upgrade_log}
      print_error "Please connect to the databse container and fix the issues\
  listed in the previous error message and follow the provided instructions\
  to fix them.\n\nWhen you have run the fixes restart the upgrade process.\n\n" | tee -a ${upgrade_log}
  exit 1
    fi
  else
    print_error "Database does not exist!" && exit 1
  fi
}

function upgrade () {
  print_warning "\e[${ZNUNY_ASCII_COLOR_BLUE}m****************************************************************************\e[0m\n"
  print_warning "\t\t\t\t\e[${ZNUNY_ASCII_COLOR_RED}m OTRS MAJOR VERSION UPGRADE\e[0m\n"
  print_warning "\t\tPress ctrl-C if you want to CANCEL !! (you have 10 seconds)\n"
  print_warning "\e[${ZNUNY_ASCII_COLOR_BLUE}m****************************************************************************\e[0m\n"
  sleep 10

  local version_blacklist="5.0.91\n5.0.92"
  local ZNUNY_PKG_REPO="https://ftp.otrs.org/pub/otrs/packages/"
  local upgrade_log="/tmp/upgrade.log"
  tmp_dir="/tmp/upgrade/"
  mkdir -p ${tmp_dir}
  echo -e ${version_blacklist} > ${tmp_dir}/blacklist.txt

  print_info "Staring OTRS major version upgrade to version \e[${ZNUNY_ASCII_COLOR_BLUE}m${ZNUNY_VERSION}\e[0m...\n" | tee -a ${upgrade_log}

  # Update configuration files
  check_host_mount_dir
  #Setup OTRS configuration
  setup_znuny_config

  # Backup
  if [ "${ZNUNY_UPGRADE_BACKUP}" == "yes" ]; then
    print_info "[*] Backing up container prior to upgrade..." | tee -a ${upgrade_log}
    /ZNUNY_backup.sh &> ${upgrade_log}

    if [ ! $? -eq 143  ]; then
      print_error "Cannot create backup" | tee -a ${upgrade_log} && exit 1
    fi
  fi

  #Update installed packages
  print_info "[*] Updating installed packages..." | tee -a ${upgrade_log}
  upgrade_modules

  # Cleanup configuration
  upgrade_cleanup_configuration

  if [[ "${ZNUNY_UPGRADE_XML_FILES}" == "yes" ]]; then
    # Upgrade XML config files
    print_info "[*] Converting configuration files to new XML format ..." | tee -a ${upgrade_log}
    su -c "${ZNUNY_ROOT}/bin/otrs.Console.pl Dev::Tools::Migrate::ConfigXMLStructure --source-directory ${ZNUNY_ROOT}/Kernel/Config/Files" -s /bin/bash otrs &> ${upgrade_log}
    if [ $? -gt 0  ]; then
      print_warning "Cannot convert configuration files"  | tee -a ${upgrade_log}
    fi
  fi

  # Run any sql file to fix any issues before starting the update. For ex the
  # sql commands that are asked to be run by the db upgrade script bellow,
  # which are needed to be be executed before the upgrade to be able to complete
  # the uupgrade.
  fix_database_upgrade

  # Run db upgrade script
  upgrade_database

  rm -fr ${tmp_dir}
  print_info "[*] Major version upgrade finished !!"  | tee -a ${upgrade_log}
}

function setup_backup_cron() {
  if [ "${ZNUNY_BACKUP_TIME}" != "" ] && [ "${ZNUNY_BACKUP_TIME}" != "disable" ]; then

    # Store in a file env vars so they can be sourced from the backup cronjob
    export -p | sed -e "s/\"/'/g" | grep -E "^declare -x ZNUNY_" > /.backup.env

    # Set cron entry
    print_info "Setting backup time to: ${ZNUNY_BACKUP_TIME}"

    if [ ! -f ${ZNUNY_BACKUP_SCRIPT} ]; then
      print_warning "Custom backup script: ${ZNUNY_BACKUP_SCRIPT} does not exist, using default one: ${DEFAULT_BACKUP_SCRIPT}"
      ZNUNY_BACKUP_SCRIPT=${DEFAULT_BACKUP_SCRIPT}
    fi

    if [ ! -f ${ZNUNY_CRON_BACKUP_SCRIPT} ]; then
      print_warning "Custom cron script: ${ZNUNY_CRON_BACKUP_SCRIPT} does not exist, creating default one: ${DEFAULT_ZNUNY_CRON_BACKUP_SCRIPT}"
      ZNUNY_CRON_BACKUP_SCRIPT=${DEFAULT_ZNUNY_CRON_BACKUP_SCRIPT}
    fi

    echo "${ZNUNY_BACKUP_TIME} root . /.backup.env; ${ZNUNY_BACKUP_SCRIPT}" > ${ZNUNY_CRON_BACKUP_SCRIPT}

  elif [ "${ZNUNY_BACKUP_TIME}" == "disable" ]; then
    print_warning "Disabling automated backups !!"
    rm /etc/cron.d/ZNUNY_backup
  fi
}

# Useful while testing or setting up a new instance.
function disable_email_fetch() {
  print_info "Disabling Email Accounts fetching..."  | tee -a ${upgrade_log}
  su -c "${ZNUNY_ROOT}bin/otrs.Console.pl Admin::Config::Update --setting-name Daemon::SchedulerCronTaskManager::Task###MailAccountFetch --valid 0" -s /bin/bash otrs

}

function enable_email_fetch() {
  print_info "Enabling Email Accounts fetching..."  | tee -a ${upgrade_log}
  su -c "${ZNUNY_ROOT}bin/otrs.Console.pl Admin::Config::Update --setting-name Daemon::SchedulerCronTaskManager::Task###MailAccountFetch --valid 1" -s /bin/bash otrs
}

function not_allowed_pkgs_install() {
  local _allow=0
  print_info "Setting the installation of \e[${ZNUNY_ASCII_COLOR_BLUE}mPackage::AllowNotVerifiedPackages\e[0m to: \e[${ZNUNY_ASCII_COLOR_RED}m${ZNUNY_ALLOW_NOT_VERIFIED_PACKAGES}\e[0m"  | tee -a ${upgrade_log}
  if [ "${ZNUNY_ALLOW_NOT_VERIFIED_PACKAGES}" == "yes" ]; then
    _allow=1
  fi
  su -c "${ZNUNY_ROOT}bin/otrs.Console.pl Admin::Config::Update --setting-name Package::AllowNotVerifiedPackages --value=${_allow}" -s /bin/bash otrs
  if [ $? -gt 0  ]; then
    print_warning "Cannot enable Package::AllowNotVerifiedPackages"  | tee -a ${upgrade_log}
  fi
}

function switch_article_storage_type() {
  if [ "${ZNUNY_ARTICLE_STORAGE_TYPE}" != "ArticleStorageFS" ] && [ "${ZNUNY_ARTICLE_STORAGE_TYPE}" != "ArticleStorageDB" ]; then
    print_warning "Unsupported article storage type."
  else
    print_info "Swtiching Article Storage Type to: \e[${ZNUNY_ASCII_COLOR_RED}m${ZNUNY_ARTICLE_STORAGE_TYPE}\e[0m ..."  | tee -a ${upgrade_log}

    current_type=$(su -c "${ZNUNY_ROOT}/bin/otrs.Console.pl Admin::Config::Read --setting-name Ticket::Article::Backend::MIMEBase::ArticleStorage" -s /bin/bash otrs|grep Kernel|cut -d':' -f 13)

    if [ ${current_type} != ${ZNUNY_ARTICLE_STORAGE_TYPE} ];then
      # First switch Ticket::Article::Backend::MIMEBase::CheckAllStorageBackends setting
      su -c "${ZNUNY_ROOT}/bin/otrs.Console.pl Admin::Config::Update --setting-name Ticket::Article::Backend::MIMEBase::ArticleStorage --value Kernel::System::Ticket::Article::Backend::MIMEBase::${ZNUNY_ARTICLE_STORAGE_TYPE}" -s /bin/bash otrs
      if [ $? -eq 0 ]; then
        if [ "${ZNUNY_ARTICLE_STORAGE_TYPE}" == "ArticleStorageFS" ]; then
          print_info "Swtiching Article Storage Type: Moving ticket articles from database to filesystem..."  | tee -a ${upgrade_log}
          #statements
        elif [ "${ZNUNY_ARTICLE_STORAGE_TYPE}" == "ArticleStorageDB" ]; then
          print_info "Swtiching Article Storage Type: Moving ticket articles from filesystem to database..."  | tee -a ${upgrade_log}
        fi
        # Then do the switch
        su -c "${ZNUNY_ROOT}/bin/otrs.Console.pl Admin::Article::StorageSwitch --target ${ZNUNY_ARTICLE_STORAGE_TYPE}" -s /bin/bash otrs
      fi
    else
      print_info "Current Article storage type already configured to: \e[${ZNUNY_ASCII_COLOR_RED}m${ZNUNY_ARTICLE_STORAGE_TYPE}\e[0m"
    fi
  fi
}
