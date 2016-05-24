#!/bin/sh
### BEGIN INIT INFO
# Provides:       minecraft_server
# Required-Start: $remote_fs $syslog
# Required-Stop:  $remote_fs $syslog
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# chkconfig:      345 50 50
# Description:    Minecraft Server Control Script
### END INIT INFO
#
# startscript for spigot minecraft server
#
# (c) 2015-2016 nimmis <kjell.havneskold@gmail.com>


# Revised for Docker Projects 
# May 20th 2016 - Brian Eilber <brian.eilber@gmail.com>
#
# Removed Server Creation and JAR build as this will be
# contained in the image.
#
#

MC_USER=minecraft       # User name running the minecraft server
MC_PROC='FTBServer-1.7.10-1614.jar'   # name of minecraft jar file
MC_DIR=/data # Directory where the server should run
MC_JAVA_OPS='-Xms${MEM} -Xmx${MEM} -XX:MaxPermSize=256m -Dfml.queryResult=confirm'   # java options for minecraft server

JAVACMD=$(which java)

USAGE=$(cat <<EOF
Usage:  $0 <option>

Options:

  start
    Start the Minecraft server.

  stop
    Stop the Minecraft server.

  restart
    Restart the Minecraft server.

  status
    Give the status of the server

  accept-eula
    Accepts Mojangs EULA and set eula.txt correct

  send "<command>"
    Sends a command to the Minecraft server

  log
    show output log from the Minecraft server

  backup
    Makes a backup of the world
EOF
)

#
# get the PID for minecraft server pocess
#

getPID() {
  local PID
  PID=$( ps -f -u $MC_USER | grep "$MC_PROC" | grep -v "sh -c" |  grep -v grep | awk '{print $2}' )
  printf "%d\n" $PID
}

#
# return 1 if the minecraft server is running othervise 0
#

isRunning() {
  if [  $(getPID) -eq 0 ] ; then
	echo 0
  else
	echo 1
  fi
}

# execute command as minecraft user

execCMD() {
	# if running as root, switch to defined user

	if [ $(id -u) -eq 0 ]; then
		su -s /bin/sh -c "$1" $MC_USER $2
	else
		sh -c "$1" $2
	fi
}

#
# setProp
#
# setProp <filename> <property> <value>
#
#
setProp() {

  grep -q "^$2\s*\=" $1

  if [ $? -ne 0 ] ; then
	echo "$prop=$val" >> $1
  else
    sed -i "/^$2\s*=/ c $2=$3" $1
  fi

}

#
# send a command to the running minecraft server
sendCMD() {
  echo $1 >> $MC_DIR/input.con
}

#
# create eula.txt if it does not exist
#

createEULA() {

  if [ ! -f $MC_DIR/eula.txt  ] ; then
       execCMD "echo '#EULA file created by minecraft script\neula=false' > $MC_DIR/eula.txt"
  fi

}

#
# EULA accepted (0) or not (1)
#

acceptEULA() {
  local OK=1
  grep eula $MC_DIR/eula.txt |  grep -q 'true' && OK=0
  echo "$OK"
}

# 
# check that all is ok the start server
#

checkOK() {

  # check that the directory exists

  if [ ! -d $MC_DIR ] ; then
	echo "$MC_DIR does not exist" ;
	exit 1
  fi

  # and there are a jar file in it

  if [ ! -f $MC_DIR/$MC_PROC ] ; then
	echo "the minecraftfile $MC_DIR/$MC_PROC does not exist."
	exit 1
  fi 

  # check to see that minecraft user can write in the

  execCMD "touch $MC_DIR/testfile 2> /dev/null"
  if [ ! -f $MC_DIR/testfile ] ; then
	echo "the user $MC_USER has not write access to directory $MC_DIR"
	exit 1
  else
    rm $MC_DIR/testfile
  fi

  # check if EULA accepted

  createEULA

  if [ $(acceptEULA) -eq 1 ] ; then
	echo "you must accept Mojangs EULA, either set eula=true in $MC_DIR/eula.txt"
	echo "or set Environment Variable EULA=true"
	exit 1
  fi
	
}


#
# prepare console files
#

ResetConsoleFiles() {

	rm -f $MC_DIR/input.con
	rm -f $MC_DIR/output.con
	
	if [ -f $MC_DIR/input.con ]; then
		echo "$MC_DIR/input.con could not be removed"
		exit 1
	fi

       	if [ -f $MC_DIR/output.con ]; then
                echo "$MC_DIR/output.con could not be removed"
                exit 1
        fi

	execCMD "touch $MC_DIR/input.con"
	execCMD "touch $MC_DIR/output.con"

	if [ ! -f $MC_DIR/input.con ]; then
		echo "$MC_DIR/input.con could not be created by $MC_USER"
		exit 1
	fi

        if [ ! -f $MC_DIR/output.con ]; then
                echo "$MC_DIR/output.con could not be created by $MC_USER"
                exit 1
        fi

}


#
# On each Server start, we redeploy the pack to /data
#

DeployModPack() {
	echo "Deploying Mod Pack from Image..."
	if [ -d "${MC_DIR}/mods" ] ; then
		rm -Rf ${MC_DIR}/mods
		echo "Purging Mods Present Mods..."
	fi
	cp -R /server/* /data/
	chown -R minecraft.minecraft /data/
	echo "Deployment Complete!"
}

#
# start the minecraft server
#

start() {
   echo -n "Starting minecraft server as user $MC_USER..."

   DeployModPack

   checkOK 

   ResetConsoleFiles

   # be in right working directory when starting 
   cd $MC_DIR

   execCMD "tail -f --pid=\$$ $MC_DIR/input.con | { $JAVACMD $MC_JAVA_OPS -jar $MC_DIR/$MC_PROC nogui | tee $MC_DIR/output.con ; kill \$$ ; } "

#   # check if the command wait OK
#
#   if [ $? -ne 0 ]; then
#     echo "Could not start $MC_DIR/$MC_PROC.\n"
#     exit 1
#   fi
#
#   # wait 2 seconds to see if the process survived
#
#   sleep 2
#
#   if [ $(isRunning) -eq 1 ] ; then
#     echo "Started"
#   else
#     echo "stopped again"
#     exit 1
#   fi

}

stop() {
  local i

  echo -n "Stopping minecraft server..."

  sendCMD "stop"

  # wait for 10 seconds until killing it
  i=0

  while [ $i -lt 10  -a $(isRunning) -eq 1 ]
  do
    echo -n "."
    sleep 1
    i=`expr $i + 1`
  done

  if [ $(isRunning) -eq 1 ] ; then
     echo -n  "(need to kill it)..."
     kill  $(getPID)
     # give it time to die
     sleep 2
  fi

  if [ $(isRunning) -eq 1 ] ; then
     echo "Could not stop it"
     exit 1
  else
     echo "Stopped" 
  fi

}
seteula() {
    
    # make sure that we have an eula.txt file to modifie

    createEULA

    setProp $MC_DIR/eula.txt "eula" "true"

    echo "EULA accepted"

}

case "$1" in

  start)
    if [ $(isRunning) -eq 1 ] ; then

	echo -n "$MC_PROC is already running with PID "
        getPID
	exit 1

    fi
    start
  ;;

  stop)
    if [ $(isRunning) -eq 1 ] ; then
       stop
    else
      echo "$MC_PROC is not running" 
    fi
  ;;

  restart)

     stop
     start
  ;;

  status)
    if [ $(isRunning) -eq 1 ] ; then
        echo -n "$MC_PROC is running with PID "
        getPID
    else
	echo "$MC_PROC is not running"
    fi

  ;;

  accept-eula)

    seteula

  ;;
  send)
     sendCMD "$2"
  ;;

  log)
     echo "Abort with CTRL-C"
     tail -f $MC_DIR/output.con
  ;;

  console)

  ;;

  backup)

  ;;

  *)
    printf "$USAGE\n"
    exit 1
  ;;

esac

exit 0