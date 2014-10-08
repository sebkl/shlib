#!/bin/sh
export DATE="date +%Y%m%d"
export TIME="date +%Y%m%d-%H%M%S"
[ -z "${LOCKFILE}" ] && LOCKFILE="${HOME}/.lock_file"

####
## echo to stderr
##
echoe () {
	echo `$TIME`  $@ 1>&2
}

lowercase () {
        echoe $1 | tr [:upper:] [:lower:]
}

uppercase () {
        echoe $1 | tr [:lower:] [:upper:]
}

####
## Loads all files in the given directory as environment parameters.
##
load_config () {
	CONFDIR="$1"
        if [[ "$CONFDIR" ]] && [ -d "$CONFDIR" ]; then
		echoe "Loading config from $CONFDIR"
                for c in `ls -1tr $CONFDIR`; do
                        MYCMD=`cat ${CONFDIR}/${c} | sed /^[\s*]\#/d |xargs`
                        echoe "SETCONF: ${c}=${MYCMD}"
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
		LF=${LOCKFILE}
	fi

        SECONDSTOWAIT=360
        while [ -f ${LF} ] && [ "${SECONDSTOWAIT}" -gt "0" ]; do
                LOCKPID=`cat ${LF}`
		if [ $$ == ${LOCKPID} ]; then
			echoe "Already locked $LF"
			return 0
		fi

                if kill -0 ${LOCKPID} 2>&1 > /dev/null ; then
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
        echoe "Locked $LF..."
	return 0
}
####
## unlock using the optionally given lock file
##
unlock () {
	if [[ $1 ]]; then
		LF=$1
	else
		LF=${LOCKFILE}
	fi

        if [ -f $LF ]; then
                rm $LF;
                echoe "Unlocked $LF..."
        fi
}

[ -d $1 ] && load_config $1
