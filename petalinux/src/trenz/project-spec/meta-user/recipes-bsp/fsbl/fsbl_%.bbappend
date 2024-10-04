SRC_URI_append = " \
        file://0001-te0720.patch \
        "

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

#Add debug for FSBL(optional)
XSCTH_BUILD_DEBUG = "0"

#Enable appropriate FSBL debug flags
#YAML_COMPILER_FLAGS_append = " -DFSBL_DEBUG_INFO"

