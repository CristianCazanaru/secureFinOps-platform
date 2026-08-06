#!/bin/bash
exec /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@"