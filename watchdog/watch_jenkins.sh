#!/bin/bash
#Created by Sam Gleske (GitHub user samrocketman)
#Mon Dec 12 15:25:50 PST 2016
#Debian GNU/Linux stretch/sid

#TEST exit codes
#  0 - success, no action required
#  2 - Jenkins not running; start Jenkins
#  3 - Jenkins frontend unhealthy

#ENVIRONMENT vars in /etc/default/watch_jenkins
#  DISABLE_JENKINS_WATCHDOG - non-zero length string means disable
#  HTTP_URL - URL for testing HTTP status
#  HEALTHY_HTTP_STATUS - Expected HTTP status code from URL testing
#  targetuser - target user in which jenkins runs

if [ ! -e /etc/default/watch_jenkins ]; then
cat > /etc/default/watch_jenkins <<'EOF'
#non-zero length string means disable
#DISABLE_JENKINS_WATCHDOG=1

#URL for testing HTTP status
#HTTP_URL=https://build.gimp.org/

#Expected HTTP status code from URL testing
#HEALTHY_HTTP_STATUS=200

#target user in which jenkins runs
#targetuser=jenkins
EOF
fi

#read user-defined settings
[ -r /etc/default/watch_jenkins ] && source /etc/default/watch_jenkins

#set defaults for user-defined settings
targetuser="${targetuser:-jenkins}"
HTTP_URL="${HTTP_URL:-https://build.gimp.org/}"
HEALTHY_HTTP_STATUS="${HEALTHY_HTTP_STATUS:-200}"

if [ -n "${DISABLE_JENKINS_WATCHDOG}" ]; then
  exit 0
fi

runTest=false
runRepair=false

case $1 in
  test)
    runTest=true
  ;;
  repair)
    runRepair=true
    repairExitCode=$2
  ;;
  *)
    echo 'Error: script needs to be run by watchdog' 1>&2
    exit 1
  ;;
esac

if ${runTest}; then
  #run a test here which will tell the status of your process
  #the exit code of this script will be the repairExitCode if it is non-zero
  if ! pgrep -u jenkins java &> /dev/null; then
    #Jenkins not running; notify watchdog to repair
    exit 2
  elif [ "${HEALTHY_HTTP_STATUS}" != "$(curl -siI -w "%{http_code}\\n" -o /dev/null "${HTTP_URL}")" ]; then
    exit 3
  else
    #all conditions pass running; no action necessary
    exit 0
  fi
fi

if ${runRepair}; then
  #take an action to repair the affected item
  #use a case statement on $repairExitCode to handle different failure cases
  RESULT=0
  case ${repairExitCode} in
    2)
      /etc/init.d/jenkins start
      echo "$(date) watchdog started jenkins because jenkins not started"
      RESULT=$?
    ;;
    3)
      /etc/init.d/jenkins restart
      echo "$(date) watchdog restarted jenkins because frontend not healthy"
      RESULT=$?
    ;;
  esac
  exit $RESULT
fi
