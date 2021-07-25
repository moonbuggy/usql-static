#! /bin/bash

#NOOP='true'
#DO_PUSH='true'
#NO_BUILD='true'

DOCKER_REPO="${DOCKER_REPO:-moonbuggy2000/usql-static}"

all_tags='latest-base latest-all latest-most latest-mysql latest-mypost latest-openxpki latest-postgres latest-sqlite3'
default_tag='latest-all'

. "hooks/.build.sh"
