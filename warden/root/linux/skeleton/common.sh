#!/bin/bash

target="union"

function write() {
  [ -z "${1}" ] && return 1

  mkdir -p ${target}/$(dirname ${1})
  cat > ${target}/${1}
}

function chroot() {
  $(which chroot) ${target} env -i /bin/bash
}

# When the override file /etc/lsb-release exists, try getting codename there.
# Fall back to executing lsb_release.
function get_codename() {
  if [ -r /etc/lsb-release ]; then
    source /etc/lsb-release
    if [ -n "${DISTRIB_CODENAME}" ]; then
      echo ${DISTRIB_CODENAME}
      return 0
    fi
  else
    lsb_release -cs
  fi
}

function setup_fs() {
  mkdir -p rootfs ${target}

  codename=$(get_codename)

  case "${codename}" in

  lucid|natty|oneiric)
    echo "Mounting rootfs from ${1}"
    mount -n -t aufs -o br:rootfs=rw:${1}=ro+wh none ${target}
    ;;

  precise)
    mount -n -t overlayfs -o rw,upperdir=rootfs,lowerdir=${1} none ${target}
    ;;

  *)
    echo "Unsupported: '${codename}'"
    exit 1
    ;;

  esac
}

function teardown_fs() {
  umount ${target}
}
