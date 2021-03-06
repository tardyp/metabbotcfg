#! /bin/bash

# startup script for the `linux` worker, which is composed of two DB containers
# and a (customized) worker container.  All DB names, users, and paswords are 'bbtest'.
# That's OK because access to the DB's is limited by docker linking.

set -e

if [ -z "${BUILDMASTER}" ]; then
    echo "set BUILDMASTER to the master name"
    exit 1
fi

if [ -z "${WORKERNAME}" ]; then
    echo "set WORKERNAME to the worker name"
    exit 1
fi

if [ -z "${WORKERPASS}" ]; then
    echo "set WORKERPASS to the worker password"
    exit 1
fi

if [ -z "${WORKERSUFFIX}" ]; then
    echo "No WORKERSUFFIX defaulting to -buildbot"
    export WORKERSUFFIX=""
fi


stop() {
    docker stop $1 || true
    docker rm $1 || true
}

stop bbtest-postgres${WORKERSUFFIX}
stop bbtest-mysql${WORKERSUFFIX}
stop bbtest${WORKERSUFFIX}

docker run -d --name bbtest-postgres${WORKERSUFFIX} \
    -e POSTGRES_USER=bbtest \
    -e POSTGRES_PASSWORD=bbtest \
    postgres:9.5

docker run -d --name bbtest-mysql${WORKERSUFFIX} \
    -e MYSQL_RANDOM_ROOT_PASSWORD=1 \
    -e MYSQL_DATABASE=bbtest \
    -e MYSQL_USER=bbtest \
    -e MYSQL_PASSWORD=bbtest \
    mysql/mysql-server:5.6 --character-set-server=utf8 --collation-server=utf8_general_ci 

docker run -d --name bbtest${WORKERSUFFIX} \
    -e BUILDMASTER=$BUILDMASTER \
    -e BUILDMASTER_PORT=9989 \
    -e WORKERNAME=$WORKERNAME \
    -e WORKERPASS=$WORKERPASS \
    --link bbtest-mysql${WORKERSUFFIX}:mysql \
    --link bbtest-postgres${WORKERSUFFIX}:postgresql \
    -d buildbot/metaworker:latest
