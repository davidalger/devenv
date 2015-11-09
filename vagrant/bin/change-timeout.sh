#!/usr/bin/env bash
set -e

## Default values
RESET=
TIMEOUT_LENGTH=7200

## verify pre-requisites
if [[ -f /etc/.vagranthost ]]; then
    >&2 echo "Error: This script should be run from within the vagrant machine. Please vagrant ssh, then retry"
    exit 1
fi

## argument parsing
for arg in "$@"; do
    case $arg in
        --length=*)
            TIMEOUT_LENGTH="${arg#*=}"
            if [[ ! "$TIMEOUT_LENGTH" =~ ^[0-9]+$ ]]; then
                >&2 echo "Error: Invalid length given --length=$TIMEOUT_LENGTH"
                exit -1
            fi
            ;;
        -r|--reset)
            RESET=1
            ;;
        --help)
            echo "Usage: $(basename $0) [--length=<timeout in seconds>] [--reset]"
            echo "Change MySQL and Nginx timeouts. Useful for long-running PHP debugging sessions."
            echo ""
            echo "       --length       Timeout length in seconds (defaults to 7200)"
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

## If flag is set, reset settings to default
if [[ $RESET ]]; then
    if [[ -f /etc/nginx/default.d/proxy.conf.bak ]]; then
        # Put original file back in place
        sudo cp /etc/nginx/default.d/proxy.conf.bak /etc/nginx/default.d/proxy.conf
        sudo rm -f /etc/nginx/default.d/proxy.conf.bak
    fi
    sudo rm -f /etc/php.d/60-customtimeout.ini
    sudo service httpd restart
    sudo service nginx restart
    echo "Succesfully reset timeouts to system defaults."
    exit 1
fi

printf "mysql.connect_timeout = '$TIMEOUT_LENGTH'\ndefault_socket_timeout = '$TIMEOUT_LENGTH'" | sudo tee /etc/php.d/60-customtimeout.ini > /dev/null

# Create backup before editing in place
if [[ ! -f /etc/nginx/default.d/proxy.conf.bak ]]; then
    sudo cp /etc/nginx/default.d/proxy.conf /etc/nginx/default.d/proxy.conf.bak
fi
sudo perl -ibak -pe "s/proxy_read_timeout [0-9]*/proxy_read_timeout $TIMEOUT_LENGTH/g" /etc/nginx/default.d/proxy.conf

# Restart for settings to take effect
sudo service httpd restart
sudo service nginx restart

echo "Succesfully changed timeout to $TIMEOUT_LENGTH seconds."
