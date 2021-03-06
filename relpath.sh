#!/bin/bash

if [[ $# -lt 1 ]] ; then
        echo -e "Compute relative path from a given DIR to given PATH\n Usage: relpath fromDIR toPATH"
        exit 1
fi

relpath() {
    #reported to speed up (x~2) regexes.  Disables Unicode support.
    export LC_ALL=C

    local from=$(readlink -f $1)/
    local to=$(readlink -f $2)
    prefix=$(printf "%s\n%s\n" "$from" "$to" | sed -e 'N;s/^\(.*\).*\n\1.*$/\1/')
    #clip off any partial dirnames (so /a/b/xyz/d and /a/b/xyj/e should go to /a/b/, not /a/b/xy)
    shopt -s extglob;
    prefix=${prefix/%+([!\/])/}
    local fromRemainder=${from#$prefix}
    local toRemainder=${to#$prefix}
    local fromDots=${fromRemainder//+([!\/])/..}

    echo "$fromDots$toRemainder"
}

relpath "$@"