#!/bin/sh

log() {
    row=$1
    echo "$(date +%Y-%m-%dT%H:%M:%S) - ${row}"
}

# Cause filesize is simular always just delate last x% (default: 10) Files.
folder="."
if [ ! -z ${SPACEMONITORING_FOLDER} ]
	then 
		folder=${SPACEMONITORING_FOLDER}
fi

maxusedPercent=90
if [ ! -z ${SPACEMONITORING_MAXUSEDPERCENTE} ]
	then 
		maxusedPercent=${SPACEMONITORING_MAXUSEDPERCENTE}
fi

deletingIteration=10
if [ ! -z ${SPACEMONITORING_DELETINGITERATION} ]
	then 
		deletingIteration=${SPACEMONITORING_DELETINGITERATION}
fi

usedInodesPercent=$(df --output=ipcent ${folder} | sed -n '2p' | cut -d% -f1)
usedSpace=$(df --output=size,used,avail,pcent -h ${folder} | sed -n '2p' | cut -d% -f1)
usedSpacePercent=$( echo ${usedSpace} | awk '{print $4}')
usedSize=$( echo ${usedSpace} | awk '{print $2}')
availableSize=$( echo ${usedSpace} | awk '{print $3}')
totalSize=$( echo ${usedSpace} | awk '{print $1}')
fileCount=$(ls -p ${folder} -1t | grep -v / | wc -l)
deletingFileCount=$((fileCount / deletingIteration))

log "Current State: ${usedSpacePercent}% used, max allowed usage: ${maxusedPercent}%, inodes used: ${usedInodesPercent}%, existind files: ${fileCount}, total pvc size: ${totalSize}, used: ${usedSize}, available: ${availableSize}"

if [ ${usedInodesPercent} -ge ${maxusedPercent} -o ${usedSpacePercent} -ge ${maxusedPercent} ] && [ ${deletingFileCount} -gt 0 ] ; then
    log "More than ${maxusedPercent}% Space or Inodes are used -> removing ${deletingFileCount} files"
    ls -p ${folder} -1t | grep -v / | tail -${deletingFileCount} | awk -v prefix="${folder}/" '{print prefix $0}' | tr '\n' '\0' | xargs -0 rm 
    return 1
else
    log "No cleanup needed"
    return 0
fi