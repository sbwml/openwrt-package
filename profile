Sysinfo() {

	[ -z "${TARGET_PROFILE}" ] && local TARGET_PROFILE=$(jsonfilter -e '@.model.id' < /etc/board.json | tr ',' '_')
	local IP_Address=$(ifconfig -a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk '{print $2}' | tr -d "addr:" | awk 'NR==1')
	local Overlay_Available="$(df -h | grep ":/overlay" | awk '{print $4}' | awk 'NR==1')"
	local Tmp_Available="$(df -h | grep "/tmp" | awk '{print $4}' | awk 'NR==1')"
	local TEMP=$(sensors 2>/dev/null | grep 'Core 0' | awk '{print $3}')
cat <<EOF
$(echo -e "${Yellow}$(uname -n)/${TARGET_PROFILE}${White}")
FIRWare Ver:	$(uname -rs)$([ -n "${TEMP}" ] && echo -e "${TEMP}")
IP  Address:	${IP_Address}
OverlaySIZE:	${Overlay_Available} / ${Tmp_Available}
---------------------------------

EOF
}

export White="\e[0m"
export Yellow="\e[33m"
export Red="\e[31m"
export Blue="\e[34m"
export Skyb="\e[36m"

clear
[ -e /tmp/.failsafe ] && export FAILSAFE=1
[ -f /etc/banner ] && echo -e "${Skyb}$(cat /etc/banner)${White}"
[ -n "$FAILSAFE" ] && cat /etc/banner.failsafe

fgrep -sq '/ overlay ro,' /proc/mounts && {
	echo -e "${Red}Your JFFS2-partition seems full and overlayfs is mounted read-only."
	echo -e "Please try to remove files from /overlay/upper/... and reboot!${}"
}

export PATH="/usr/sbin:/usr/bin:/sbin:/bin"
export HOME=$(grep -e "^${USER:-root}:" /etc/passwd | cut -d ":" -f 6)
export HOME=${HOME:-/root}
export PS1='\u@\h:\w\$ '
export ENV=/etc/shinit

case "$TERM" in
	xterm*|rxvt*)
		export PS1='\[\e]0;\u@\h: \w\a\]'$PS1
		;;
esac

[ -n "$FAILSAFE" ] || {
	for FILE in /etc/profile.d/*.sh; do
		[ -e "$FILE" ] && . "$FILE"
	done
	unset FILE
}

if ( grep -qs '^root::' /etc/shadow && \
     [ -z "$FAILSAFE" ] )
then
cat << EOF
=== WARNING! ====================
There is no root password defined on this device!
Use the "passwd" command to set up a new password
in order to prevent unauthorized SSH logins.
---------------------------------
EOF
fi
Sysinfo
