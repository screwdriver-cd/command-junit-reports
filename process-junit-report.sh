#######################################
#
# Script to invoke junit parser
# Note:   If ruby is not found, this script
#         attempts to install
# Input:  none
# Output: none
#
#######################################
#!/bin/sh
  
set -e

if [ $# -ne 2 ] || ! [ -d "$1" ]; then
  echo "Usage: $0 <path-to-junit-reports> <update-sd-ui [true | false]>" >&2
  exit -1
fi

if ! [ -f "/usr/bin/ruby" ]; then
  echo "Installing ruby rpm..."
  sudo yum install --debuglevel=1 -y ruby
fi
# One more check for ruby
command -v ruby >/dev/null 2>&1 || { echo >&2 "ruby is required but it's not installed. Aborting!"; exit 1; }
# Clone tools
git clone --single-branch --branch master git@github.com:screwdriver-cd/junit-reports.git /tmp/junit-tools
if [ $? -ne 0 ]; then
  echo "Unable to find parser.Aborting!"
  exit -1
fi

echo "Using ruby installation at `which ruby`"
set +e
ruby /tmp/junit-tools/scripts/junit.rb $@
NUM_FAILED_TESTS=$?
if [ "$NUM_FAILED_TESTS" != "0" ]; then
  curl -X PUT -H "Authorization: Bearer $SD_TOKEN" -H "Content-Type: application/json" -d '{"status": "UNSTABLE", "statusMessage": "this build is unstable"}' "${SD_BUILD_URL}"
  exit $NUM_FAILED_TESTS
fi
