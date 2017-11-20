#!/bin/bash
# Compare the versions of available sft packages vs AUR.
# Tony G. <aur at tonyskapunk dot net>
#
#~ Options:
#~   -c    Track client packages.
#~   -h    Print this help.
#~   -s    Track server packages.
#~   -u    Track url-handler packages.
#~   -v    Print the Version.
#~
#~ NOTE: AUR packages make use of RPMs.
#~ Define env GIT_AUR_PATH with the path where the aur repos are located

_VERSION=0.0.1
FULL_NAME=$(basename $0)
NAME=$(basename $0  | cut -d. -f1)
# GIT_AUR_PATH is used to use it as the location where the repos are located

aur_url="https://aur.archlinux.org/packages"

# Required scripts
UPDPKGSUMS=/bin/updpkgsums
MAKEPKG=/bin/makepkg
GIT=/bin/git
if [[ ! -x "${UPDPKGSUMS}" ||
      ! -x "${MAKEPKG}" ||
      ! -x "${GIT}" ]]; then
  echo "One or more tools required by this script are mising:" >&2
  echo "${UPDPKGSUMS}, ${MAKEPKG}, ${GIT}" >&2
  #exit 1
fi

# Tracking a package
track_pkg() {
  local pkg=$1
  local flags=$2
  local latest_rpm_pkg=$( ./sft_ver.sh ${flags} )
  local aur_pkg=$( curl -s ${aur_url}/${pkg}/ | grep -Po "${pkg} [\d+.-]+" )
  # Getting versions(as one single number)
  local aur_num_ver=$( echo ${aur_pkg%-*} | grep -oP "\d" | paste -sd '' )
  local latest_rpm_num_ver=$( echo ${latest_rpm_pkg%-*} |
                                grep -oP "\d" |
                                paste -sd '' )
  if [[ ${latest_rpm_num_ver} -gt ${aur_num_ver} ]]; then
    echo "${latest_rpm_pkg%-*}" | sed -e 's/^.*-//'
    return 1
  else
    return 0
  fi
}

# Help
print_help(){
  echo "Usage: ${FULL_NAME} [-h|-v]|[[-d][-r]] [[-c][-u][-s]]"
  grep -E '^#~' $0|sed -e 's/^#~//'
}


# AUR packages use RPMs, track RPM versions:
flags="-r"
pkg=""
while getopts chsuv arg; do
  case ${arg} in
    h)
      print_help
      exit 0
      ;;
    c)
      pkg="scaleft-client-tools"
      flags+="c"
      ;;
    u)
      pkg="scaleft-url-handler"
      flags+="u"
      ;;
    s)
      pkg="scaleft-server-tools"
      flags+="s"
      ;;
    v)
      echo "${NAME} ${_VERSION}"
      exit 0
      ;;
   esac
done

if [[ ! -z "${pkg}" ]]; then
  newest_ver=$( track_pkg "${pkg}" "${flags}" )
  if [[ -n ${newest_ver} ]]; then
    ls -ld "${GIT_AUR_PATH}/${pkg}"
    if [[ ! -d "${GIT_AUR_PATH}/${pkg}" ]]; then
     echo "Error, git directory not found: ${GIT_AUR_PATH}/${pkg}" >&2
     exit 1
    fi
    pushd ${GIT_AUR_PATH}/${pkg}
    sed -i "s/^\(pkgver=\).*/\1${newest_ver}/" PKGBUILD
    updpkgsums
    ${MAKEPKG} --force --clean
    ${MAKEPKG} --printsrcinfo  > .SRCINFO
    echo === Commiting changes ===
    echo cd "${GIT_AUR_PATH}/${pkg}"
    echo 'git commit -m"Updating package to v. '${newest_ver}'" .'
    echo git push origin
  fi
fi

exit 0
