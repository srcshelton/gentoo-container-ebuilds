#! /bin/sh

set -eu

debug="${DEBUG:-}"
trace="${TRACE:-}"

die() {
	: $(( rc = ${?} ))
	msg="FATAL: ${*:-"Unknown error"}"
	if [ $(( rc )) -gt 0 ]; then
		msg="${msg} (${rc})"
	fi
	echo >&2 "${msg}"
	exit 1
}

# Populate these values and uncomment the three lines below!
#
#token='<token>'
#dm='<dm_id>'
#chat_monitoring='<chat_id>'

if [ -z "${*:-}" ] || echo " ${*} " | grep -Eq ' -(h|-help) '; then
	echo "Usage: $( basename "${0}" ) [--to=<chat_id>] [--host=<host>]" \
		"[--eventtype=<event>] [message]"
	exit 0
fi

[ -n "${trace:-}" ] && set -o xtrace

command -V curl >/dev/null ||
	die "Command 'curl' (net-misc/curl) must be installed"

chat_id=''
origin='ZXTM'
message=''
haseventtype=0
result=''
rc=0

arg=''
next=''
for arg in "${@}"; do
	if [ -n "${next:-}" ]; then
		arg="${next}=${arg}"
		next=''
	fi

	case "${arg}" in
		--to*)
			if [ "${arg}" = '--to' ]; then
				next="${arg}"
			else
				chat_id="${arg#*=}"
				case "${chat_id}" in
					'dm')
						chat_id="${dm}"
						;;
					'monitoring')
						chat_id="${chat_monitoring}"
						;;
				esac
			fi
			;;
		--host*)
			if [ "${arg}" = '--host' ]; then
				next="${arg}"
			else
				origin="${arg#*=}"
			fi
			;;
		--eventtype*)
			if [ "${arg}" = '--eventtype' ]; then
				next="${arg}"
			else
				haseventtype=1
				message="${origin:-}: ${arg#*=} -${message:-}"
			fi
			;;
		*)
			if [ -n "${arg:-}" ]; then
				if [ -n "${message:-}" ]; then
					message="${message} ${arg}"
				else
					message="${arg}"
				fi
				haseventtype=0
			fi
			;;
	esac
done

[ -n "${chat_id:-}" ] ||
	die "No chat_id set, cannot post"

if [ -n "${message:-}" ]; then
	message="$( echo "${message}" | sed 's/\s+/ /g ; s/^ //' )"
	if [ $(( haseventtype )) -ne 0 ]; then
		message="$( echo "${message}" | sed 's/ =$//' )"
	fi
fi

result="$( # <- Syntax
	curl -fsSLX POST \
			-H 'Content-Type: application/json' \
			-d "{\"chat_id\": \"${chat_id}\", \"text\": \"${message}\", \"disable_notification\": false}" \
		"https://api.telegram.org/bot${token}/sendMessage"
)" || die "POST failed: ${?}"

if [ -n "${debug:-}" ] && command -V jq >/dev/null; then
	echo "${result}" | jq -rC .
fi

exit 0
