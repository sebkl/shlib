#!/bin/sh
export DATE="date +%Y%m%d"
export TIME="date +%Y%m%d-%H%M%S"

if [ -z "${LOCKFILE}" ]; then
	LOCKFILE="${HOME}/.lock_file"
fi

echoe () {
	echo `$TIME`  $1 1>&2
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

assert_user () {
        if [ `whoami` == "$1" ]; then
		return 0
        else
                echoe "Please switch to $1 user !!!!"
		return 1
        fi
}

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

if [ -d $1 ]; then
	load_config $1
fi


