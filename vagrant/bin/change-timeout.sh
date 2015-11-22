#!/usr/bin/env bash
set -e

## Default values
RESET=
TIMEOUT_LENGTH=3600

## Verify pre-requisites
if [[ ! -f /etc/.vagranthost ]]; then
    >&2 echo "Error: This script should be run from the host machine."
    exit 1
fi

## Argument parsing
for arg in "$@"; do
    case $arg in
        --length=*)
            TIMEOUT_LENGTH="${arg#*=}"
            if [[ ! "${TIMEOUT_LENGTH}" =~ ^[0-9]+$ ]]; then
                >&2 echo "Error: Invalid length given --length=${TIMEOUT_LENGTH}"
                exit -1
            fi
            ;;
        -r|--reset)
            RESET=1
            ;;
        --help)
            echo "Usage: $(basename $0) [--length=<timeout in seconds>] [--reset]"
            echo "Change MySQL wait_timeout, PHP mysql.connect_timeout and default_socket_timeout, and Nginx proxy_read_timeout values."
            echo "Useful for long-running PHP debugging sessions."
            echo ""
            echo "       --length       Timeout length in seconds (defaults to ${TIMEOUT_LENGTH})"
            echo "  -r : --reset        Reset timeouts to system defaults"
            echo ""
            exit -1
            ;;
        *)
            >&2 echo "Error: Unrecognized argument $arg"
            exit -1
            ;;
    esac
done

vagrant ssh web -- "
## If flag is set, reset settings to default
if [[ \"${RESET}\" -ne 0 ]]; then
    if [[ -f /etc/nginx/default.d/proxy.conf.bak ]]; then
        # Put original file back in place
        sudo cp /etc/nginx/default.d/proxy.conf.bak /etc/nginx/default.d/proxy.conf
        sudo rm -f /etc/nginx/default.d/proxy.conf.bak
    fi
    sudo rm -f /etc/php.d/60-customtimeout.ini
    sudo service httpd restart > /dev/null
    sudo service nginx restart > /dev/null
    echo 'Reset PHP/Nginx timeouts to system defaults.'
    exit
fi

printf \"mysql.connect_timeout = '${TIMEOUT_LENGTH}'\ndefault_socket_timeout = '${TIMEOUT_LENGTH}'\" | sudo tee /etc/php.d/60-customtimeout.ini > /dev/null

# Create backup before editing in place
if [[ ! -f /etc/nginx/default.d/proxy.conf.bak ]]; then
    sudo cp /etc/nginx/default.d/proxy.conf /etc/nginx/default.d/proxy.conf.bak
fi

sudo perl -ibak -pe \"s/proxy_read_timeout [0-9]*/proxy_read_timeout ${TIMEOUT_LENGTH}/g\" /etc/nginx/default.d/proxy.conf

# Restart for settings to take effect
sudo service httpd restart > /dev/null
sudo service nginx restart > /dev/null

echo \"Changed PHP/Nginx timeouts to ${TIMEOUT_LENGTH} seconds.\"
";

vagrant ssh db -- "
## If flag is set, reset settings to default
if [[ \"${RESET}\" -ne 0 ]]; then
    sudo rm -f /etc/my.cnf.d/customtimeout.cnf
    sudo service mysqld restart &> /dev/null
    echo 'Reset MySQL wait_timeout to system defaults.'
    exit
fi

printf \"[mysqld]\nwait_timeout = ${TIMEOUT_LENGTH}\" | sudo tee /etc/my.cnf.d/customtimeout.cnf > /dev/null

sudo service mysqld restart &> /dev/null

echo \"Changed MySQL wait_timeout to ${TIMEOUT_LENGTH} seconds.\"
";