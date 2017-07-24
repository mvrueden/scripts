#!/bin/bash

DEV_ROOT="/Volumes/Daten/OpenNMS/dev/opennms"
DEV_USER="chris"
DEV_GROUP="staff"
OPENNMS_ROOT="/opt/opennms"

IFS=$'\n' options=( `find $DEV_ROOT/*/target -depth 1 -type d -name "opennms-*-SNAPSHOT"` )
PS3=">"

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

function usage () {
  echo "Usage: deploy.sh deploy|redeploy|rerun|start|status|stop|restart|clean"
}

function choose () {
  echo "**********************************************"
  echo "* OpenNMS deploy script                      *"
  echo "**********************************************"
  echo "Development root directory: $DEV_ROOT"
  echo "OpenNMS installation directory: $OPENNMS_ROOT"
  echo ""
  echo "Please select build to deploy:"

  select opt in "${options[@]}" "Quit"; do
    case "$REPLY" in

    $(( ${#options[@]}+1 )) ) echo "Goodbye!"
                              exit;;

    *) if [[ "$REPLY" != [0-9]* ]]; then
         echo "Invalid option. Try another one."
         continue
       fi
       if [ "$REPLY" -ge "1" ]; then
         if [ "$REPLY" -le "${#options[@]}" ]; then
           SOURCE="${options[$REPLY-1]}"
           break
         else
           echo "Invalid option. Try another one."
           continue
         fi
       else
         echo "Invalid option. Try another one."
         continue
       fi
    esac
  done
}

function start () {
  echo -n "-> "
  if [ -f $OPENNMS_ROOT/bin/opennms ]; then
    $OPENNMS_ROOT/bin/opennms -t start
  else
    echo "Warning: file 'bin/opennms' not found!"
  fi
}

function status () {
  echo "-> Checking OpenNMS status..."
  if [ -f $OPENNMS_ROOT/bin/opennms ]; then
    $OPENNMS_ROOT/bin/opennms -v status
  else
    echo "Warning: file 'bin/opennms' not found!"
  fi
}

function stop () {
  echo -n "-> "
  if [ -f $OPENNMS_ROOT/bin/opennms ]; then
    $OPENNMS_ROOT/bin/opennms stop
  else
    echo "Warning: file 'bin/opennms' not found!"
  fi
}

function restart () {
  echo -n "-> "
  if [ -f $OPENNMS_ROOT/bin/opennms ]; then
    $OPENNMS_ROOT/bin/opennms restart
  else
    echo "Warning: file 'bin/opennms' not found!"
  fi
}

function delete_directories () {
  echo "-> Deleting old directories..."
  rm $OPENNMS_ROOT/bin >>$OPENNMS_ROOT/deploy.log 2>&1
  rm $OPENNMS_ROOT/contrib >>$OPENNMS_ROOT/deploy.log 2>&1
  rm $OPENNMS_ROOT/docs >>$OPENNMS_ROOT/deploy.log 2>&1
  rm $OPENNMS_ROOT/jetty-webapps >>$OPENNMS_ROOT/deploy.log 2>&1
  rm $OPENNMS_ROOT/lib >>$OPENNMS_ROOT/deploy.log 2>&1
  rm $OPENNMS_ROOT/system >>$OPENNMS_ROOT/deploy.log 2>&1
  rm $OPENNMS_ROOT/deploy >>$OPENNMS_ROOT/deploy.log 2>&1
  rm -rf $OPENNMS_ROOT/etc >>$OPENNMS_ROOT/deploy.log 2>&1
  rm -rf $OPENNMS_ROOT/data >>$OPENNMS_ROOT/deploy.log 2>&1
  rm -rf $OPENNMS_ROOT/share >>$OPENNMS_ROOT/deploy.log 2>&1
  rm -rf $OPENNMS_ROOT/logs >>$OPENNMS_ROOT/deploy.log 2>&1
  rm -rf $OPENNMS_ROOT/instances >>$OPENNMS_ROOT/deploy.log 2>&1
}

function copy_configuration () {
  echo "-> Copying modified configuration files..."
  cp -pR $OPENNMS_ROOT/etc-template/* $OPENNMS_ROOT/etc/ >>$OPENNMS_ROOT/deploy.log 2>&1
}

function set_permissions () {
  chown $DEV_USER:$DEV_GROUP $OPENNMS_ROOT/bin >>$OPENNMS_ROOT/deploy.log 2>&1
  chown $DEV_USER:$DEV_GROUP $OPENNMS_ROOT/contrib >>$OPENNMS_ROOT/deploy.log 2>&1
  chown $DEV_USER:$DEV_GROUP $OPENNMS_ROOT/docs >>$OPENNMS_ROOT/deploy.log 2>&1
  chown $DEV_USER:$DEV_GROUP $OPENNMS_ROOT/jetty-webapps >>$OPENNMS_ROOT/deploy.log 2>&1
  chown $DEV_USER:$DEV_GROUP $OPENNMS_ROOT/lib >>$OPENNMS_ROOT/deploy.log 2>&1
  chown $DEV_USER:$DEV_GROUP $OPENNMS_ROOT/deploy >>$OPENNMS_ROOT/deploy.log 2>&1
  chown $DEV_USER:$DEV_GROUP $OPENNMS_ROOT/system >>$OPENNMS_ROOT/deploy.log 2>&1
}

function copy_directories () {
  echo "-> Copying directories..."
  cp -pR $SOURCE/etc $OPENNMS_ROOT/ >>$OPENNMS_ROOT/deploy.log 2>&1
  cp -pR $SOURCE/data $OPENNMS_ROOT/ >>$OPENNMS_ROOT/deploy.log 2>&1
  cp -pR $SOURCE/share $OPENNMS_ROOT/ >>$OPENNMS_ROOT/deploy.log 2>&1
  cp -pR $SOURCE/logs $OPENNMS_ROOT/ >>$OPENNMS_ROOT/deploy.log 2>&1
}

function link_directories () {
  echo "-> Linking directories..."
  ln -s $SOURCE/bin $OPENNMS_ROOT/ >>$OPENNMS_ROOT/deploy.log 2>&1
  ln -s $SOURCE/contrib $OPENNMS_ROOT/ >>$OPENNMS_ROOT/deploy.log 2>&1
  ln -s $SOURCE/docs $OPENNMS_ROOT/ >>$OPENNMS_ROOT/deploy.log 2>&1
  ln -s $SOURCE/jetty-webapps $OPENNMS_ROOT/ >>$OPENNMS_ROOT/deploy.log 2>&1
  ln -s $SOURCE/lib $OPENNMS_ROOT/ >>$OPENNMS_ROOT/deploy.log 2>&1
  ln -s $SOURCE/deploy $OPENNMS_ROOT/ >>$OPENNMS_ROOT/deploy.log 2>&1
  ln -s $SOURCE/system $OPENNMS_ROOT/ >>$OPENNMS_ROOT/deploy.log 2>&1
}

function alter_configuration () {
  echo "-> Altering etc/config.properties"
  echo "org.apache.aries.blueprint.synchronous=true" >>$OPENNMS_ROOT/etc/config.properties
  echo "opennms.poller.server.registryPort=10990" >>$OPENNMS_ROOT/etc/opennms.properties
}

function execute_runjava () {
  echo "-> Executing 'runjava -s'..."
  cd $OPENNMS_ROOT/bin
  ./runjava -s >>$OPENNMS_ROOT/deploy.log 2>&1
  cd $OPENNMS_ROOT
}

function execute_install () {
  echo "-> Executing 'install -disl /usr/local/lib'..."
  cd $OPENNMS_ROOT/bin
  ./install -disl /usr/local/libi:/opt/local/lib >>$OPENNMS_ROOT/deploy.log 2>&1
  cd $OPENNMS_ROOT
}

function drop_database () {
  echo "-> Dropping database..."
  export PGHOST=/tmp ; /Library/PostgreSQL/9.3/bin/psql --user postgres -c "DROP DATABASE opennms" >>$OPENNMS_ROOT/deploy.log 2>&1
}

function remove_deploy_log () {
  rm /opt/opennms/deploy.log &> /dev/null
}

function rerun () {
  cd $OPENNMS_ROOT/etc
  export FUTURE="`date -v+1M "+%H:%M"`"
  export HOUR="`echo $FUTURE | cut -f 1 -d: `"
  export MINUTE="`echo $FUTURE | cut -f 2 -d: `"
  echo "The vmware-requisition will run at $FUTURE"
  echo -n "The current time is: "
  date "+%H:%M"
  cat $OPENNMS_ROOT/etc-template/provisiond-configuration.xml | sed "s/MM/$MINUTE/g" | sed "s/HH/$HOUR/g" > $OPENNMS_ROOT/etc/provisiond-configuration.xml
  $OPENNMS_ROOT/bin/send-event.pl uei.opennms.org/internal/reloadDaemonConfig --parm 'daemonName Provisiond'
  cd $OPENNMS_ROOT
}

function remove_ssh_entry () {
  sed -i -e "/\[localhost\]:8101/d" /Users/$DEV_USER/.ssh/known_hosts
}

function open_browser () {
  open http://localhost:8980/opennms/
}

function info () {
  echo "-> Using build directory $SOURCE"
}

remove_deploy_log

case $1 in
  deploy)
    choose
    info
    stop
    delete_directories
    copy_directories
    link_directories
    set_permissions
    copy_configuration
    alter_configuration
    drop_database
    execute_runjava
    execute_install
    remove_ssh_entry
    start
    rerun
    open_browser

    exit 0;
    ;;
  clean)
    stop
    delete_directories

    exit 0;
    ;;
  redeploy)
    choose
    info
    stop
    delete_directories
    copy_directories
    link_directories
    set_permissions
    copy_configuration
    alter_configuration

    execute_runjava
    execute_install
    remove_ssh_entry
    start
    rerun
    open_browser

    exit 0;
    ;;
  rerun)
    rerun
    exit 0;
    ;;
  start)
    start
    exit 0;
    ;;
  status)
    status
    exit 0;
    ;;
  stop)
    stop
    exit 0;
    ;;
  restart)
    restart
    exit 0;
    ;;
  *)
    usage
    exit 2;
    ;;
esac
