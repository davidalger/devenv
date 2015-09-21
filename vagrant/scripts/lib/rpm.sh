# rpm utilities
set -e

function install_rpm {
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "usage: install_rpm <rpm_url> <rpm_path>"
        exit 1;
    fi
    rpm_url="$1"
    rpm_path="$2"
    
    # download from remote and verify signature if not present in local cache
    if [[ ! -f "$rpm_path" ]]; then
        if [[ ! -d "$(dirname $rpm_path)" ]]; then
            mkdir -p "$(dirname $rpm_path)"
        fi
        wget -q "$rpm_url" -O "$rpm_path"
        rpm -K "$rpm_path"
    fi
    
    yum install -y "$rpm_path" || true
}
