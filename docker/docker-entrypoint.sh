#!/bin/bash

set -e

# Set job control so we can bg/fg processes
set -m

php artisan key:check || exit 1

# If the "start-website" argument was provided, start the web server
if [ "$1" = "start-website" ] ; then
   echo "Starting Apache..."

  # Start Apache under the current user, in case the current user isn't www-data.  Kubernetes-based systems
  # typically run under a random user.  We start Apache before running the install scripts so the system can
  # begin collecting submissions while database migrations run.  Apache starts in the background so the
  # container gets killed if the migrations fail.
  if [ "$BASE_IMAGE" = "debian" ] ; then
    APACHE_RUN_USER=$(id -u -n) /usr/sbin/apache2ctl -D FOREGROUND
  elif [ "$BASE_IMAGE" = "ubi" ]; then
    /usr/libexec/s2i/run
  fi & # & puts Apache in the background

  if [ "$DEVELOPMENT_BUILD" = "1" ]; then
    bash /cdash/install.sh --dev --initial-docker-install
  else
    bash /cdash/install.sh --initial-docker-install
  fi

  # Bring Apache to the foreground so the container fails if Apache fails after this point.
  fg

# If the start-worker argument was provided, start a worker process instead
elif [ "$1" = "start-worker" ] ; then
  php artisan queue:work

# Otherwise, throw an error...
else
  echo "Unknown argument(s) provided: $*"
  echo "Use 'start-website' to start the CDash website, or 'start-worker' to start a worker process."
  exit 1
fi
