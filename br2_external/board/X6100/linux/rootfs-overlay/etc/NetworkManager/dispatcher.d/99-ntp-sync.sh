#!/bin/sh

interface=$1 status=$2
case "$status" in
  up)
    /usr/bin/ntpdate -u time.nist.gov >> /var/log/ntpdate.log  2>&1
    ;;
esac
