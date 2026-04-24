#! /usr/bin/env bash
#
# chkconfig: - 99 87
#
# description: Correctly unmount yas3fs mounts before going reboot or halt (a workaround for https://github.com/libfuse/libfuse/issues/1)
#

# how many seconds to wait for yas3fs queues flushing
TIMER=${TIMER:-60}

if [ -d /var/lock/subsys ]; then
    lockdir=/var/lock/subsys
else
    lockdir=/run/lock/subsys
fi
lockfile=${lockdir}/unmount-yas3fs

fstab_decode=${FSTAB_DECODE:-}
if [ -z "$fstab_decode" ]; then
    for candidate in /usr/sbin/fstab-decode /sbin/fstab-decode /usr/local/sbin/fstab-decode.py /usr/local/sbin/fstab-decode; do
        if [ -x "$candidate" ]; then
            fstab_decode="$candidate"
            break
        fi
    done
fi
if [ -z "$fstab_decode" ] && command -v fstab-decode >/dev/null 2>&1; then
    fstab_decode="$(command -v fstab-decode)"
fi

start() {
    /bin/mkdir -p "$lockdir"
    /bin/touch "$lockfile"
}

stop() {
    logger -t "unmount-yas3fs" "Unmounting yas3fs volumes..."
    echo "unmount-yas3fs: Unmounting yas3fs volumes..."
    awk '$1 ~ /^yas3fs$/ { print $2 }' \
        /proc/mounts | sort -r | \
    while IFS= read -r line; do
        if [ -n "$fstab_decode" ]; then
            "$fstab_decode" /bin/umount -f "$line"
        else
            /bin/umount -f "$line"
        fi
    done

    logger -t "unmount-yas3fs" "Waiting for yas3fs queues get flushed..."
    echo -n "unmount-yas3fs: Waiting for yas3fs queues get flushed"
    c=0
    while pgrep -x yas3fs >/dev/null 2>&1; do
        if [ "$c" -gt "$TIMER" ]; then
            logger -t "unmount-yas3fs" "Wasn't able to complete in $TIMER seconds, exiting forcefully..."
            echo
            echo "unmount-yas3fs: Wasn't able to complete in $TIMER seconds, exiting forcefully..."
            /bin/rm -f "$lockfile"
            exit 0
        fi
        echo -n "."
        sleep 1
        c=$((c+1))
    done
    logger -t "unmount-yas3fs" "done"
    echo -n "done"
    echo
    /bin/rm -f "$lockfile"
}

case "$1" in
    start) start;;
    stop) stop;;
    *)
        echo $"Usage: $0 {start|stop}"
        exit 1
esac

exit 0
