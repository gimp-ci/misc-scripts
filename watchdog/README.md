# Watchdog scripts

Here are scripts designed to be run from within the watchdog daemon.  watchdog
is a daemon which will watch running processes and if they fail certain test
conditions (such as exiting), then it will automatically restart them.

# Install watchdog on Debian GNU/Linux stretch/sid

    sudo apt-get install watchdog

# How watchdog works

The [`watchdog(8)`][man8_watchdog] daemon will execute scripts in
`/etc/watchdog.d` with the argument `test` or `repair`. (see `TEST DIRECTORY`
section of `watchdog(8)` man page). Your watchdog script handles those two
arguments when it checks to see if a process is running and takes an action to
repair it.

You can configure watchdog by modifying `/etc/watchdog.conf` (See
[`watchdog.conf(5)`][man5_watchdog.conf]).

# Example `watchdog.d` script

For a real world example, see [`watch_jenkins.sh`](./watch_jenkins.sh).

```
#!/bin/bash

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
  exit 0
fi

if ${runRepair}; then
  #take an action to repair the affected item
  #use a case statement on $repairExitCode to handle different failure cases
  exit 0
fi
```

# Configuring watchdog

`/etc/watchdog.conf` and `/etc/defaults/watchdog` are places to configure
watchdog.  See [`watchdog.conf(5)`][man5_watchdog.conf].

One thing to note is user scripts are executed once every second by default. I
recommend increasing this to at least 30 seconds unless you have a need for more
realtime checking. Adjust the `interval` setting in `watchdog.conf`.

# Troubleshooting

You may need to create the `/etc/watchdog.d` directory before your script.

`/var/log/watchdog/*` contains watchdog related logs and errors. If your script
outputs to stdout or stderr then it will be written there. On my system I notice
my script executes `test` or `repair` roughly once every second. If you use
`echo` in your script it should only be temporary for debugging purposes only.
Otherwise, discarding output is recommended except in the case of errors.

If your script is not running at all then check the permissions:

    ls -l /etc/watchdog.d

[man5_watchdog.conf]: https://manpages.debian.org/cgi-bin/man.cgi?query=watchdog.conf&sektion=5&apropos=0&manpath=Debian+testing+stretch&locale=en
[man8_watchdog]: https://manpages.debian.org/cgi-bin/man.cgi?query=watchdog&apropos=0&sektion=8&manpath=Debian+testing+stretch&format=html&locale=en
