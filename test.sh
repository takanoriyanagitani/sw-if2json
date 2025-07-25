#!/bin/sh

numcpus=16
jobs=$((numcpus - 1))

swift \
	test \
	--jobs ${jobs} \
	--parallel
