#!/usr/bin/env bash
set -e

function warning {
    if [[ $opt_quiet = 0 ]]
    then
        echo "cloudflare-nginx: $@">&2
    fi
}

function init_variables {
    export CLOUDFLARE_IP4=https://www.cloudflare.com/ips-v4
    export CLOUDFLARE_IP6=https://www.cloudflare.com/ips-v6
    export TARGET=/etc/nginx.d/cloudflare.conf
    export WGET_BIN=$(which wget)
    export TEMP_FILE=/tmp/cloudflare.$$.tmp
    export opt_debug=0
    export opt_quiet=0
    export opt_show_diff=0
    export opt_real_run=0
    export opt_backup=1
    export opt_x_forwarded_for=x
}

function parse_basic_options {
    local OPTIND
    while getopts ":46dvsxrqnhc:" opt; do
        case $opt in
            d)
                warning "-d Enabling debug mode."
                opt_debug=1
            ;;
            q)
                opt_quiet=1
            ;;
            r)
                warning "-r Enabling real run. Overwrite original files!"
                opt_real_run=1
            ;;
            s)
                warning "-s Enabling showing of diffs."
                opt_show_diff=1
            ;;
            n)
                warning "-n Disabling backups."
                opt_backup=0
            ;;
            4)
                warning "-4 Disabling IPV4 IPs."
                CLOUDFLARE_IP4=""
            ;;
            6)
                warning "-6 Disabling IPV6 IPs."
                CLOUDFLARE_IP6=""
            ;;
            c)
                warning "-c Using CF-Connecting-IP header instead of the default X-Forwarded-For."
                opt_x_forwarded_for=c
            ;;
            x)
                warning "-h Disabling adding real_ip_header directive."
                opt_x_forwarded_for=""
            ;;
            h)
                cat $(dirname $BASH_SOURCE)/README.md
                return 1
            ;;
            \?)
                warning "Invalid option: -$OPTARG"
                return 1
            ;;
        esac
    done
    shift $((OPTIND-1))
    if [[ "$@" != "" ]]
    then
        export TARGET="$@"
    fi
    warning "Output file: $TARGET"
    if [[ "${CLOUDFLARE_IP4}${CLOUDFLARE_IP6}" = "" ]]
    then
        warning "Both IPV4 and IPV6 ips can not be disabled in the same time."
        return 1
    fi
    return 0
}

function main_work {
    if [[ $opt_debug = 0 ]]
    then
        export WGET_BIN="$WGET_BIN -q"
    fi
    $WGET_BIN $CLOUDFLARE_IP4 $CLOUDFLARE_IP6 -O $TEMP_FILE
    for i in $(cat $TEMP_FILE)
    do
        if [[ $i =~ ^[0-9./:a-fA-F]*$ ]];
        then
            echo "set_real_ip_from $i;"
        else
            warning "Unrecognised lines in source files: $i"
            rm $TEMP_FILE
            return 1
        fi
    done >$TEMP_FILE.2
    if [[ $opt_x_forwarded_for = "c" ]]
    then
        echo "real_ip_header CF-Connecting-IP;" >>$TEMP_FILE.2
    fi;
    if [[ $opt_x_forwarded_for = "x" ]]
    then
        echo "real_ip_header X-Forwarded-For;" >>$TEMP_FILE.2
    fi
    if [[ $opt_show_diff = 1 ]]
    then
        if [[ -s $TARGET ]]
        then
            diff -uwb $TARGET $TEMP_FILE.2 && opt_real_run=0 && warning "There are no changes."
        else
            warning "Original file does not exist, showing diff is not possible."
        fi
    fi
    if [[ $opt_real_run = 1 ]]
    then
        if [[ $opt_backup = 1 ]]
        then
            if [[ -s $TARGET ]]
            then
                warning "Backing up the original file."
                cp -a $TARGET $TARGET.bak
            else
                warning "Original file does not exist or empty, backing up is not possible."
            fi
        fi
        warning "Overwriting original file."
        cat $TEMP_FILE.2 > $TARGET
    fi
    warning "Removing temporary files."
    rm $TEMP_FILE.2 $TEMP_FILE
    warning "All done."
}

init_variables
parse_basic_options "$@"
retval=$?

if [[ $retval == 0 ]]
then
    main_work
    retval=$?
fi

if [[ "$SHUNIT_VERSION" = "" ]]
then
    exit $retval
else
    return $retval
fi
