#!/bin/sh -e

# Check parameters.
if [ $# -ne 1 ]; then
	echo "usage: configinit configdata"
	exit 1
fi
CONFDATA=$1

# Check that the file exists.
if ! [ -f ${CONFDATA} ]; then
	echo "Config file does not exist: ${CONFDATA}"
	exit 1
fi

# If the first two bytes are '#!', make it executable and run it.
if [ "`head -c 2 ${CONFDATA}`" = '#!' ]; then
	chmod +x ${CONFDATA}
	${CONFDATA}
	exit 0
fi

# If the first two bytes are '>/', the first line contains a path for the
# rest of the file to be written into.
if [ "`head -c 2 ${CONFDATA}`" = '>/' ]; then
	TARGETFILE=`head -1 ${CONFDATA} | cut -c 2-`
	mkdir -p `dirname ${TARGETFILE}`
	tail +2 ${CONFDATA} > ${TARGETFILE}
	exit 0
fi

# If the first three bytes are '>>/', the first line contains a path for the
# rest of the file to be appended into.
if [ "`head -c 3 ${CONFDATA}`" = '>>/' ]; then
	TARGETFILE=`head -1 ${CONFDATA} | cut -c 3-`
	mkdir -p `dirname ${TARGETFILE}`
	tail +2 ${CONFDATA} >> ${TARGETFILE}
	exit 0
fi

# Otherwise, hope this is an archive containing more files for us to process.
D=`mktemp -d "${TMPDIR:-/tmp}/configinit.XXXXXX"`
trap 'rm -r "$D"' EXIT
tar -xf ${CONFDATA} -C ${D}

# Process files in lexicographical order
find ${D} -type f |
    sort |
    while read F; do
	sh $0 ${F}
done
