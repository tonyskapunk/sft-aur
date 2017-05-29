#!/bin/bash
# Getting the latest version for sft packages.
# Tony G. <aur at tonyskapunk dot net>
#
#~ Options:
#~   -a    Query all.
#~   -c    Query client packages.
#~   -d    Query "deb" packages.
#~   -D    Query all "deb" packages.
#~   -h    Print this help.
#~   -r    Query "rpm" packages.
#~   -r    Query all "rpm" packages.
#~   -s    Query server packages.
#~   -u    Query url-handler packages.
#~   -v    Print the Version.

_VERSION=0.0.1
FULL_NAME=$(basename $0)
NAME=$(basename $0  | cut -d. -f1)

sft_repo=https://pkg.scaleft.com
sft_client=scaleft-client-tools
sft_handler=scaleft-url-handler
sft_server=scaleft-server-tools

# Latest clients
get_latest_rpm_client() {
  local latest_pkg=$( curl -s ${sft_repo}/rpm/ 2>/dev/null |
                        grep -Po "${sft_client}[\w-\d.]*" |
                        sort -V |
                        tail -1
                    )
  echo ${latest_pkg}
}

get_latest_deb_client() {
  local deb_pkg=pool/linux/main/s/${sft_client}
  local latest_pkg=$( curl -s ${sft_repo}/deb/${deb_pkg}/ 2>/dev/null |
                        grep -Po 'scale[\w-\d.]*' |
                        sort -V |
                        tail -1
                    )
  echo ${latest_pkg}
}


# Latest handlers
get_latest_rpm_handler() {
  local latest_pkg=$( curl -s ${sft_repo}/rpm/ 2>/dev/null |
                        grep -Po "${sft_handler}[\w-\d.]*" |
                        sort -V |
                        tail -1
              )
  echo ${latest_pkg}
}

get_latest_deb_handler() {
  local deb_pkg=pool/linux/main/s/${sft_handler}
  local latest_pkg=$( curl -s ${sft_repo}/deb/${deb_pkg}/ 2>/dev/null |
                        grep -Po 'scale[\w-\d.]*' |
                        sort -V |
                        tail -1
                    )
  echo ${latest_pkg}
}


# Latest server
get_latest_rpm_server() {
  local latest_pkg=$( curl -s ${sft_repo}/rpm/ |
                        grep -Po "${sft_server}[\w-\d.]*" 2>/dev/null |
                        sort -V |
                        tail -1
              )
  echo ${latest_pkg}
}

get_latest_deb_server() {
  local deb_pkg=pool/linux/main/s/${sft_server}
  local latest_pkg=$( curl -s ${sft_repo}/deb/${deb_pkg}/ 2>/dev/null |
                        grep -Po 'scale[\w-\d.]*' |
                        sort -V |
                        tail -1
              )
  echo ${latest_pkg}
}


# Help
print_help(){
  echo "Usage: ${FULL_NAME} [-h|-v]|[[-d][-r]] [[-c][-u][-s]]"
  grep -E '^#~' $0|sed -e 's/^#~//'
}


# Main
get_deb=0
get_rpm=0
get_client=0
get_urlhandler=0
get_server=0
while getopts acDdhsRruv arg; do
  case ${arg} in
    a)
      get_deb=1
      get_rpm=1
      get_client=1
      get_urlhandler=1
      get_server=1
      ;;
    h)
      print_help
      exit 0
      ;;
    d)
      get_deb=1
      ;;
    r)
      get_rpm=1
      ;;
    D)
      get_deb=1
      get_client=1
      get_urlhandler=1
      get_server=1
      ;;
    R)
      get_rpm=1
      get_client=1
      get_urlhandler=1
      get_server=1
      ;;
 
    c)
      get_client=1
      ;;
    u)
      get_urlhandler=1
      ;;
    s)
      get_server=1
      ;;
    v)
      echo "${NAME} ${_VERSION}"
      exit 0
      ;;
   esac
done

if [[ ${get_deb} == 0 &&
      ${get_rpm} == 0 ]]; then
   echo "Need at least one kind of package -r(rpm) or -d(deb)."
   exit 1
fi
if [[ ${get_client} == 0 &&
      ${get_urlhandler} == 0 &&
      ${get_server} == 0 ]]; then
   echo "Need at least one type of package -c(client) or -u(handler) or"\
        "-s(server)."
   exit 1
fi



if [[ ${get_deb} == 1 ]]; then
  if [[ ${get_client} == 1 ]]; then
    get_latest_deb_client
  fi
  if [[ ${get_urlhandler} == 1 ]]; then
    get_latest_deb_handler
  fi
  if [[ ${get_server} == 1 ]]; then
    get_latest_deb_server
  fi
fi
if [[ ${get_rpm} == 1 ]]; then
  if [[ ${get_client} == 1 ]]; then
    get_latest_rpm_client
  fi
  if [[ ${get_urlhandler} == 1 ]]; then
    get_latest_rpm_handler
  fi
  if [[ ${get_server} == 1 ]]; then
    get_latest_rpm_server
  fi

fi

exit 0
