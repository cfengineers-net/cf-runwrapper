#!/bin/sh

# CONTROLWORD is the first bundle in the bundlesequence. It should be on the following format
# [PROMISES|UPDATE|FAILSAFE]_[QUIET|VERBOSE|INFORM]_[DRYRUN|NODRYRUN]_[NOLOCK|LOCK]
# eg.
#    PROMISES_VERBOSE_NODRYRUN_NOLOCK

PROGNAME=`basename $0`
CONTROLWORD=""
OPTIONS=""
BUNDLES=""
COMMAND=""
TYPE="PROMISES"
OUTPUT="QUIET"
DRYRUN="NODRYRUN"
LOCK="LOCK"
WORKDIR=""
UID=0

if [ -x "/var/cfengine/bin/cf-agent" ]; then
	COMMAND="/var/cfengine/bin/cf-agent"
elif [ -x "/usr/local/sbin/cf-agent" ]; then
	COMMAND="/usr/local/sbin/cf-agent"
elif [ -x "/usr/local/bin/cf-agent" ]; then
	COMMAND="/usr/local/bin/cf-agent"
else
	exit 1
fi

if [ $UID -eq 0 ]; then
	WORKDIR="/var/cfengine"
else
	WORKDIR="$HOME/.cfagent"
fi

# getopts string I-: is for the script to accept --inform and -I that might get
# automatically added by cf-serverd/cf-runagent

while getopts b:D:I-: arg; do
	case $arg in
		b)
			BUNDLES_PASSED=$OPTARG
			;;
		D)
			CLASSES_PASSED=$OPTARG
			;;
		\?)
			#echo "ERROR - invalid arg"
			#exit 1
			;;
	esac
done

OLDIFS=$IFS
IFS=","
ITER=0
for i in $BUNDLES_PASSED; do
	if [ $ITER -gt 0 ]; then
		if [ "x${BUNDLES}" = "x" ]; then
			BUNDLES=$i
		else
			BUNDLES="$BUNDLES,$i"	
		fi
	else
		CONTROLWORD=$i
	fi
	ITER=`expr $ITER + 1`
done
IFS=$OLDIFS

if [ "x${BUNDLES}" != "x" ]; then
	OPTIONS="$OPTIONS --bundlesequence $BUNDLES"
fi

if [ "x${CLASSES_PASSED}" != "x" ]; then
	OPTIONS="$OPTIONS --define $CLASSES_PASSED"
fi

OLDIFS=$IFS
IFS="_"
ITER=0

for i in $CONTROLWORD; do
	if [ $ITER -eq 0 ]; then
		TYPE=$i
	elif [ $ITER -eq 1 ]; then
		OUTPUT=$i
	elif [ $ITER -eq 2 ]; then
		DRYRUN=$i
	elif [ $ITER -eq 3 ]; then
		LOCK=$i
	fi
	ITER=`expr $ITER + 1`
done
IFS=$OLDIFS

case $TYPE in
	UPDATE)
		if [ -f "$WORKDIR/inputs/update.cf" ]; then
			OPTIONS="$OPTIONS --file update.cf" 
		else
			exit 1
		fi
		;;
	FAILSAFE)
		if [ -f "$WORKDIR/inputs/failsafe.cf" ]; then
			OPTIONS="$OPTIONS --file failsafe.cf" 
		else
			exit 1
		fi
		;;
	PROMISES)
		if [ -f "$WORKDIR/inputs/promises.cf" ]; then
			OPTIONS="$OPTIONS" 
		else
			exit 1
		fi
		;;
	*)
		exit 1
		;;
esac

case $OUTPUT in
	VERBOSE)
		OPTIONS="$OPTIONS --verbose" 
		;;
	INFORM)
		OPTIONS="$OPTIONS --inform" 
		;;
	QUIET)
		;;
	*)
		exit 1
		;;
esac

case $DRYRUN in
	DRYRUN)
		OPTIONS="$OPTIONS --dry-run" 
		;;
	NODRYRUN)
		;;
	*)
		exit 1
		;;
esac

case $LOCK in
	NOLOCK)
		OPTIONS="$OPTIONS --no-lock" 
		;;
	LOCK)
		;;
	*)
		exit 1
		;;
esac
$COMMAND $OPTIONS
