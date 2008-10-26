# Build script for ltrace

do_print_filename() {
    echo "ltrace-${CT_LTRACE_VERSION}.orig"
}

do_debug_ltrace_get() {
    CT_GetFile "ltrace_${CT_LTRACE_VERSION}.orig" {ftp,http}://ftp.de.debian.org/debian/pool/main/l/ltrace/
    # Create a link so that the following steps are easier to do:
    cd "${CT_TARBALLS_DIR}"
    ltrace_ext=$(CT_GetFileExtension "ltrace_${CT_LTRACE_VERSION}.orig")
    ln -sf "ltrace_${CT_LTRACE_VERSION}.orig${ltrace_ext}" "ltrace-${CT_LTRACE_VERSION}${ltrace_ext}"
}

do_debug_ltrace_extract() {
    CT_ExtractAndPatch "ltrace-${CT_LTRACE_VERSION}"
}

do_debug_ltrace_build() {
    CT_DoStep INFO "Installing ltrace"
    mkdir -p "${CT_BUILD_DIR}/build-ltrace"
    CT_Pushd "${CT_BUILD_DIR}/build-ltrace"

    CT_DoLog EXTRA "Copying sources to build dir"
    (cd "${CT_SRC_DIR}/ltrace-${CT_LTRACE_VERSION}"; tar cf - .)| tar xvf - |CT_DoLog ALL

    CT_DoLog EXTRA "Configuring ltrace"
    CT_DoExecLog ALL        \
    ./configure"            \
        --build=${CT_BUILD} \
        --host=${CT_TARGET} \
        --prefix=/usr

    CT_DoLog EXTRA "Building ltrace"
    CT_DoExecLog ALL make

    CT_DoLog EXTRA "Installing ltrace"
    CT_DoExecLog ALL make DESTDIR="${CT_DEBUG_INSTALL_DIR}" install

    CT_Popd
    CT_EndStep
}

