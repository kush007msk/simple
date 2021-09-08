#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);

cd $SCRIPT_DIR

# Install java/maven with sdkman
# ./install.sh 11.0.1.hs-adpt 3.8.1 no noq
# 11.0.11.hs-adpt,11.0.10.hs-adpt,11.0.9.hs-adpt

export SDKMAN_DIR="$HOME/.sdkman"

if [ -z ${SDKMAN_DIR+x} ] || [[ ! -d "$SDKMAN_DIR" ]] ; then
    echo "sdkman not detected, installing it"
    curl -s "https://get.sdkman.io?rcupdate=false" | bash
else
  echo "Sdkman! already installed."
fi
# Bring 'sdk' function into scope
source "$SDKMAN_DIR/bin/sdkman-init.sh"

# get latest available sdkman java version
LATEST_SDKMAN_JAVA_VER=$(sdk ls java | grep .hs-adpt | grep 11. -m1 | cut -c 62-)

# sdk list maven | grep 3. | head -n 1

JAVA_VER=${1:-$LATEST_SDKMAN_JAVA_VER} # "default"
MAVEN_VER=${2:-3.8.2} # "latest"
SET_JAVA_VER_DEFAULT=${3:-no}
SET_MAVEN_VER_DEFAULT=${4:-no}

#echo $JAVA_VER
#exit 1

if [ ! -z "$JAVA_VER" ]; then
  echo "Installing Java: $JAVA_VER"
else
    echo "Specify Java version"
    exit 1
fi

if [ ! -z "$MAVEN_VER" ]; then
   echo "Installing Maven: $MAVEN_VER"
else
    echo "Specify Maven version"
    exit 1
fi

# install $JAVA_VER if not installed
if [ "$(sdk list java | grep -v "local only" | grep "$JAVA_VER" | grep -v "sdk install" | grep -v "installed" | wc -l)" == "1" ]; then
  echo $SET_JAVA_VER_DEFAULT | sdk install java $JAVA_VER
fi

# if not already set, use java $JAVA_VER in this shell
if [ "$(sdk current java | grep -c "$JAVA_VER")" != "1" ]; then
  sdk use java $JAVA_VER
fi

#  if needed, set $JAVA_VER as default
if [ "$SET_JAVA_VER_DEFAULT" == "yes" ]; then
  sdk default java $JAVA_VER
fi

# install $MAVEN_VER if not installed
if [ "$(sdk list maven | grep -v "local only" | grep "$MAVEN_VER" | grep -v "*" | grep -v "+" | wc -l)" == "1" ]; then
  echo $SET_MAVEN_VER_DEFAULT | sdk install maven $MAVEN_VER
fi

# if not already set, use maven $MAVEN_VER in this shell
if [ "$(sdk current maven | grep -c "$MAVEN_VER")" != "1" ]; then
  sdk use maven $MAVEN_VER
fi

# if needed, set $MAVEN_VER as default
if [ "$SET_MAVEN_VER_DEFAULT" == "yes" ]; then
  sdk default maven $MAVEN_VER
fi

delete_for_each() {
  versions=$*;
  for version in $versions
  do
    sdk uninstall java "$version"
  done
}

install_for_each() {
  versions=$*;
  for version in $versions
  do
    install_java_using_sdk "$version"
  done
}

# Use SDKMAN to install something using a partial version match
sdk_install() {
    local install_type=$1
    local requested_version=$2
    local prefix=$3
    local suffix="${4:-"\\s*"}"
    local full_version_check=${5:-".*-[a-z]+"}
    if [ "${requested_version}" = "none" ]; then return; fi
    # Blank will install latest stable AdoptOpenJDK version
    if [ "${requested_version}" = "lts" ] || [ "${requested_version}" = "default" ]; then
         requested_version=""
    elif echo "${requested_version}" | grep -oE "${full_version_check}" > /dev/null 2>&1; then
        echo "${requested_version}"
    else
        local regex="${prefix}\\K[0-9]+\\.[0-9]+\\.[0-9]+${suffix}"
        local version_list="$(. ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk list ${install_type} 2>&1 | grep -oP "${regex}" | tr -d ' ' | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ]; then
            requested_version="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            requested_version="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
        if [ -z "${requested_version}" ] || ! echo "${version_list}" | grep "^${requested_version//./\\.}$" > /dev/null 2>&1; then
            echo -e "Version $2 not found. Available versions:\n${version_list}" >&2
            exit 1
        fi
    fi
    "${SDKMAN_DIR}/bin/sdkman-init.sh && sdk install ${install_type} ${requested_version} && sdk flush archives && sdk flush temp"
}

#sdk_install maven ${MAVEN_VER} '\s\s' '\s\s' '^[0-9]+\.[0-9]+\.[0-9]+$'
#sdk_install java ${JAVA_VERSION} "\\s*" "(\\.[a-z0-9]+)?-adpt\\s*" ".*-[a-z]+$"

#versions_to_delete=$(sdk list java | grep "local only" | cut -c 62-)
#java_versions_to_install=$(sdk list java | grep -v "local only" | grep "hs-adpt" | grep -v "sdk install" | grep -v "installed" | cut -c 62-)
#delete_for_each "$versions_to_delete"
#install_for_each "$java_versions_to_install"

sdk current
echo $JAVA_HOME
java -version
mvn -version

cd $LAUNCH_DIR