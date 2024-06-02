#!/bin/bash -x
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

_VERSION=0.0.1
FULL_NAME=$(basename "$0")
NAME=$(basename "$0"  | cut -d. -f1)

# GIT_AUR_PATH is used to use it as the location where the repos are located

aur_url="https://aur.archlinux.org/packages"

# Required scripts
MAKEPKG=/bin/makepkg
GIT=/bin/git
if [[ ! -x "${MAKEPKG}" ||
      ! -x "${GIT}" ]]; then
    echo "One or more tools required by this script are mising:" >&2
    echo "${MAKEPKG}, ${GIT}" >&2
    #exit 1
fi

# Tracking a package
track_pkg() {
    local pkg=$1
    local flags=$2
    local latest_rpm_ver
    local aur_pkg
    local aur_num_ver
    local latest_rpm_num_ver

    latest_rpm_ver=$( ./sft_ver.sh -v )
    aur_pkg=$( curl -sL "${aur_url}/${pkg}/" | grep -Po "${pkg} [\d+.-]+" )

    # Getting versions(as one single number)
    aur_num_ver=$( echo "${aur_pkg%-*}" | grep -oP "\d" | paste -sd '' )
    latest_rpm_num_ver=$( echo "${latest_rpm_ver}" |
                              grep -oP "\d" |
                              paste -sd '' )

    # Validate the rpm  is available
    #echo "${sft_repo}/rpm/stable/${BASE_OS}/${BASE_OS_VER}/x86_64/${sft_pkg}-${latest_ver}.x86_86.rpm"
    if [[ ${latest_rpm_num_ver} -gt ${aur_num_ver} ]]; then
        echo "${latest_rpm_ver}"
        return 1
    else
        return 0
    fi
}

# Help
print_help(){
    echo "Usage: ${FULL_NAME} [-h|-v]|[[-d][-r]] [[-c][-u][-s]]"
    grep -E "^#~" "$0" |
        sed -e "s/^#~//"
}


# AUR packages use RPMs, track RPM versions:
flags="-"
pkg=""
while getopts chsuv arg; do
    case ${arg} in
        c)
            pkg="scaleft-client-tools-bin"
            flags+="v"
            ;;
        u)
            pkg="scaleft-url-handler"
            flags+="v"
            ;;
        s)
            pkg="scaleft-server-tools-bin"
            flags+="v"
            ;;
        v)
            echo "${NAME} ${_VERSION}"
            exit 0
            ;;
        h|*)
            print_help
            exit 0
            ;;
    esac
done

get_sha() {
  source=${1}
  curl -s "${source}" |
    sha256sum |
    awk '{print $1}'
}

# AUR repo + pkg name
REPO_DIR="${GIT_AUR_PATH}/${pkg}"

if [[ -n "${pkg}" ]]; then
  newest_ver=$( track_pkg "${pkg}" "${flags}" )
  if [[ -n ${newest_ver} ]]; then
    ls -ld "${REPO_DIR}"
    if [[ ! -d "${REPO_DIR}" ]]; then
     echo "Error, git directory not found: ${REPO_DIR}" >&2
     exit 1
    fi
    pushd "${REPO_DIR}" || exit 1

    # Replace version
    sed -i "s/^\(pkgver=\).*/\1${newest_ver}/" PKGBUILD

    # Replace sha256sum
    if [[ -r PKGBUILD ]]; then
        # shellcheck source=/dev/null
        source PKGBUILD
    else
        echo "Error: No PKGBUILD found" >&2
        exit
    fi
    new_sha=$(get_sha "${source}")
    sed -i "s/^\(sha256sums=\).*/\1('${new_sha}')/" PKGBUILD

    makepkg --printsrcinfo | tee .SRCINFO
    makepkg --clean --force
    echo "git commit -m\"Updating package to v. ${newest_ver}\" ."
    echo git push origin
  fi
fi

exit 0
