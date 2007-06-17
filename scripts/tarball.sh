#!/bin/bash

# This scripts makes a tarball of the configured toolchain
# Pre-requisites:
#  - crosstool-NG is configured
#  - components tarball are available
#  - toolchain is built successfully

# We need the functions first:
. "${CT_TOP_DIR}/scripts/functions"

# Don't care about any log file
exec >/dev/null
rm -f "${tmp_log_file}"

# Parse the configuration file:
. ${CT_TOP_DIR}/.config

CT_DoBuildTargetTriplet

# Kludge: if any of the config options needs either CT_TARGET or CT_TOP_DIR,
# re-parse them:
. "${CT_TOP_DIR}/.config"

# Build a one-line list of files to include
CT_DoStep DEBUG "Building list of tarballs to add"
CT_TARBALLS_DIR="${CT_TOP_DIR}/targets/tarballs"
CT_TARBALLS=""
for dir in '' tools debug; do
    CT_DoStep DEBUG "Scanning directory \"${dir}\""
    for script in "${CT_TOP_DIR}/scripts/build/${dir}/"*.sh; do
        CT_DoStep DEBUG "Testing component \"${script}\""
        [ -n "${script}" ] || continue
        unset do_print_file_name
        . "${script}"
        for file in `do_print_filename`; do
            CT_DoLog DEBUG "Finding tarball for \"${file}\""
            [ -n "${file}" ] || continue
            ext=`CT_GetFileExtension "${file}"`
            CT_TestOrAbort "Missing tarball for: \"${file}\"" -f "${CT_TOP_DIR}/targets/tarballs/${file}${ext}"
            CT_DoLog DEBUG "Found \"${file}${ext}\""
            CT_TARBALLS="${CT_TARBALLS} ${file}${ext}"
        done
        CT_EndStep
    done
    CT_EndStep
done    
CT_EndStep

# We need to emulate a build directory:
CT_BUILD_DIR="${CT_TOP_DIR}/targets/${CT_TARGET}/build"
mkdir -p "${CT_BUILD_DIR}"
CT_MktempDir tempdir

# Save crosstool-ng, as it is configured for the current toolchain.
topdir=`basename "${CT_TOP_DIR}"`
CT_Pushd "${CT_TOP_DIR}/.."

botdir=`pwd`

# Build the list of files to exclude
CT_DoLog DEBUG "Building list of files to exclude"
exclude_list="${tempdir}/${CT_TARGET}.list"
{ echo ".svn";                                                  \
  echo "${topdir}/log.*";                                       \
  echo "${topdir}/targets/src";                                 \
  echo "${topdir}/targets/tst";                                 \
  echo "${topdir}/targets/*-*-*-*";                             \
  for t in `ls -1 "${topdir}/targets/tarballs/"`; do            \
      case " ${CT_TARBALLS} " in                                \
          *" ${t} "*) ;;                                        \
          *)          echo "${topdir}/targets/tarballs/${t}";;  \
      esac;                                                     \
  done;                                                         \
} >"${exclude_list}"

# Render the install directory writable
chmod u+w "${CT_PREFIX_DIR}"

CT_DoLog INFO "Saving crosstool-ng into the toolchain directory"
tar cvjf "${CT_PREFIX_DIR}/${topdir}.${CT_TARGET}.tar.bzip2"    \
    --no-wildcards-match-slash                                  \
    -X "${exclude_list}"                                        \
    "${topdir}"                                                 2>&1 |CT_DoLog ALL

CT_Popd

CT_DoLog INFO "Saving the toolchain"
tar cvjf "${botdir}/${CT_TARGET}.tar.bz2" "${CT_PREFIX_DIR}"    2>&1 |CT_DoLog ALL

CT_DoLog DEBUG "Getting rid of working directories"
rm -f "${CT_PREFIX_DIR}/${topdir}.${CT_TARGET}.tar.bzip2"
rm -rf "${tempdir}"

if [ "${CT_INSTALL_DIR_RO}" = "y" ]; then
    # Render the install directory non-writable
    chmod u-w "${CT_PREFIX_DIR}"
fi
