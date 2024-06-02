#!/bin/bash
# Get and validate the sft latest packages
# Tony G. <aur at tonyskapunk dot net>
#
#~ Options:
#~   -a    Query all.
#~   -c    Query client packages.
#~   -h    Print this help.
#~   -s    Query server packages.
#~   -u    Query url-handler packages.
#~   -v    Print the latest version of the packages.
#~   -V    Print the Version.

_VERSION=1.0.0
FULL_NAME=$(basename "$0")
NAME=$(basename "$0"  | cut -d. -f1)
BASE_OS=centos
BASE_OS_VER=9
ARCH=x86_64
SFT_REPO=https://dist.scaleft.com/repos
SFT_URL=${SFT_REPO}/rpm/stable/${BASE_OS}/${BASE_OS_VER}/${ARCH}/

sft_client=scaleft-client-tools
sft_handler=scaleft-url-handler
sft_server=scaleft-server-tools

# Latest version
get_latest_version() {
    local latest_ver
    latest_ver=$( curl -s ${SFT_URL} 2>/dev/null |
                    grep -Po '>(\d+\.?){3}<' |
                    grep -Po "(\d+\.?){3}" |
                    sort -V |
                    tail -1
                )
    echo "${latest_ver}"
}

# Latest packages
get_latest_pkg() {
    local sft_pkg="$1"
    local latest_ver
    latest_ver=$(get_latest_version)
    if curl -s -o /dev/null -w "%{response_code}" "${SFT_URL}" | grep -q "200"; then
        echo "${sft_pkg}-${latest_ver}.${ARCH}.rpm"
    else
        echo "Error: ${sft_pkg} not found in version ${latest_ver}" >&2
        exit 1
    fi
}

# Help
print_help(){
    echo "Usage: ${FULL_NAME} [-h|-V]|[[-a][-c][-u][-s][-v]]"
    grep -E "^#~" "$0" |
      sed -e "s/^#~//"
}


# Main
while getopts achsuvV arg; do
    case ${arg} in
        a)
            get_latest_pkg ${sft_client}
            get_latest_pkg ${sft_handler}
            get_latest_pkg ${sft_server}
            
            ;;
        c)
            get_latest_pkg ${sft_client}
            ;;
        u)
            get_latest_pkg ${sft_handler}
            ;;
        s)
            get_latest_pkg ${sft_server}
            ;;
        V)
            echo "${NAME} ${_VERSION}"
            exit 0
            ;;
        v)
            get_latest_version
            ;;
        h|*)
            print_help
            exit 0
            ;;
    esac
done

exit 0
