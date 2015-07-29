#!/bin/sh
export SHLIB_DATE="date +%Y%m%d"
export SHLIB_TIME="date +%Y%m%d-%H%M%S"
export SHLIB_DEBUG=0
export SHLIB_MAX_KILL_TRIES=10
export SHLIB_KILL_THRES=8
export SHLIB_DELAY=1
export SHLIB_LOCKFILE="${HOME}/.lock_file"

####
## echo to stderr
##
echoe () {
	echo `${SHLIB_TIME}`  $@ 1>&2
}
debug () {
	[ ${SHLIB_DEBUG} -gt 0 ] && echoe $@
}


####
## Argument case helper
##
lowercase () {
        echo $1 | tr [:upper:] [:lower:]
}
uppercase () {
        echo $1 | tr [:lower:] [:upper:]
}

####
## Loads all files in the given directory as environment parameters.
##
load_config () {
	SHLIB_CONFDIR="$1"
        if [[ "${SHLIB_CONFDIR}" ]] && [ -d "${SHLIB_CONFDIR}" ]; then
		debug "Loading config from ${SHLIB_CONFDIR}"
                for c in `ls -1tr ${SHLIB_CONFDIR}`; do
                        MYCMD=`sed s/\#.*$// < ${SHLIB_CONFDIR}/${c} | xargs`
                        debug "SETCONF: ${c}=${MYCMD}"
                        export ${c}="${MYCMD}"
                done
        fi
}

####
## Asserts whether the given user is active. If not errorcode is returned.
##
assert_user () {
        if [ `whoami` == "$1" ]; then
		return 0
        else
                echoe "Please switch to $1 user !!!!"
		return 1
        fi
}

####
## Try to lock using the optionally given file.
## If lock exists this call blocks max 360 seconds and returns with error.
##
lock () {
	if [[ $1 ]]; then
		LF=$1
	else
		LF=${SHLIB_LOCKFILE}
	fi

        SECONDSTOWAIT=360
        while [ -f ${LF} ] && [ "${SECONDSTOWAIT}" -gt "0" ]; do
                LOCKPID=`cat ${LF}`
		if [ $$ == ${LOCKPID} ]; then
			echoe "Already locked $LF"
			return 0
		fi

                if kill -0 ${LOCKPID} 2>&1 >>/dev/null ; then
                        echoe "Process ${LOCKPID} is locking. Waiting ${SECONDSTOWAIT} secs ..."
                        sleep 5
                        SECONDSTOWAIT=$((${SECONDSTOWAIT} - 5))
                else
                        echoe "Locking process doesnt exist anymore. Removing lockfile."
                        unlock
                fi
        done

        if [ ${SECONDSTOWAIT} == "0" ]; then
                return 1;
        fi

        echo $$ > ${LF}
        debug "Locked $LF..."
	return 0
}

####
## unlock using the optionally given lock file
##
unlock () {
	if [[ $1 ]]; then
		LF=$1
	else
		LF=${SHLIB_LOCKFILE}
	fi

        if [ -f $LF ]; then
                rm $LF;
                debug "Unlocked $LF..."
        fi
}

####
## test status of a service pidfile
##
test_service_status() {
	[ -n "$1" ] && [ -f $1 ] && PID=`cat $1` && export PID && [ `ps --pid=${PID} -o pid | sed 1d | wc -l` -gt 0 ]
}

####
## start a service for the given pidfile
##
service_start() {
	if [ $# -lt 2 ]; then
		echoe "Please specifiy PIDFILE and SERVICECMD."
		return 1
	fi

	lock
	if test_service_status $1; then
		echoe "Service is already running at PID" `cat $1`
		unlock
		return 0
	fi

	while true; do ($2); sleep ${SHLIB_DELAY}; done &
	echo $! > $1
	sleep ${SHLIB_DELAY}
	unlock
	return 0
}

####
## stop a service for the given pidfile
##
service_stop() {
	lock
	COUNT=0
	while test_service_status $1 && [ ${COUNT} -le ${SHLIB_MAX_KILL_TRIES} ]; do
		PID=`cat $1`
		GRPIDS=`ps --pid=${PID} --ppid=${PID} -o pid | sed 1d | xargs`
		SIG=""
		if [ ${COUNT} -ge ${SHLIB_KILL_THRES} ]; then
			echo "Trying to kill services at PID ${GRPIDS}"
			SIG="-9"
		fi
		kill ${SIG} ${GRPIDS} 2>&1 >>/dev/null

		sleep ${SHLIB_DELAY}
		COUNT=$((${COUNT} + 1))
	done

	[ ${COUNT} -eq 0 ]&& echoe "Service is not running"
	[ ${COUNT} -le ${SHLIB_MAX_KILL_TRIES} ] && [ -f $1 ] && rm $1
	unlock

	[ ${COUNT} -gt ${SHLIB_MAX_KILL_TRIES} ] && echoe "Service could not be stopped." && return 1
	return 0
}

[ -d $1 ] && load_config $1
