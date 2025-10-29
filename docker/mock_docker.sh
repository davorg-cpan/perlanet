#!/bin/sh
cd "$(dirname "$0")"
ver=`perl -nE '/\@v([\d\.]+)/ and print $1 and exit' Dockerfile`
echo "Building version $ver"
# Simulate docker build with explicit exit code
exit 0
