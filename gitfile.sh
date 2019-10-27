#!/usr/bin/env bash

set -euo pipefail

function cloneRepo
{
  SOURCE=${1}
  VERSION=${2}
  GIT_CLONE_PATH=${3//\~/$HOME}
  if [ ! -d "${GIT_CLONE_PATH}" ]; then
    git clone "${SOURCE}" ${GIT_CLONE_PATH} -q
  fi
  (
    cd ${GIT_CLONE_PATH}
    if [ -n "$(git status --porcelain)" ]; then
      echo "[SKIP] local changes detected"
      return
    fi
    sed -i -e "s|url =.*.git\$|url = ${SOURCE}|" ./.git/config
    git fetch -q
    git checkout ${VERSION} -q
    git pull origin ${VERSION} -q
  )
}

function parseYaml
{
  YAML_FILE_CONTENT=$(cat ${1} | egrep -v "^\s*#")
  DEFAULT_GIT_CLONE_PATH=${2}
  LAST_LINE_NUMBER="$(echo "${YAML_FILE_CONTENT}" | wc -l | awk '{print $1}')"
  mapfile -t LINE_NUMBERS < <(echo "${YAML_FILE_CONTENT}" | cat -n | egrep -v "source:|version:|path:" | egrep "[0-9]{1,10}.*:\s*$" | awk '{print $1}')
  mapfile -t DIR_NAMES  < <(echo "${YAML_FILE_CONTENT}" | cat -n | egrep -v "source:|version:|path:" | egrep "[0-9]{1,10}.*:\s*$" | awk '{print $2}')
  for (( i=0; i < ${#LINE_NUMBERS[@]}; ++i ))
  do
    FROM=$(expr ${LINE_NUMBERS[$i]} + 1)
    TO=$(expr ${LAST_LINE_NUMBER} + 1)
    if [ "$i" -ne "$(expr ${#LINE_NUMBERS[@]} - 1 )" ]; then
      TO=$(expr ${LINE_NUMBERS[$i + 1]} - 1)
    fi
    SOURCE=$(echo "${YAML_FILE_CONTENT}" | sed -n "${FROM},${TO}p" | grep "source:" | awk '{print $2}' | cut -d'"' -f2)
    VERSION=$(echo "${YAML_FILE_CONTENT}" | sed -n "${FROM},${TO}p" | grep "version:" | awk '{print $2}' | cut -d'"' -f2 || echo "master")
    GIT_CLONE_PATH=$(echo "${YAML_FILE_CONTENT}" | sed -n "${FROM},${TO}p" | grep "path:" | awk '{print $2}' | cut -d'"' -f2 || echo "${DEFAULT_GIT_CLONE_PATH}")
    cloneRepo ${SOURCE} ${VERSION} ${GIT_CLONE_PATH%/}/${DIR_NAMES[$i]%:}
  done
}

DEFAULT_GIT_CLONE_PATH="."
if [ "$#" -eq 1 ]; then
  DEFAULT_GIT_CLONE_PATH=${1%/}
fi


YAML_FILE="./.gitfile"
if [ "$#" -eq 2 ]; then
  YAML_FILE="${2}"
fi

if [ ! -f "${YAML_FILE}" ]; then
  echo "[ERROR] '${YAML_FILE}' does not exist"
  exit 1
fi

cd "$(dirname "${YAML_FILE}")"
YAML_FILE="./$(echo ${YAML_FILE} | rev | cut -d "/" -f 1 | rev)"
parseYaml ${YAML_FILE} ${DEFAULT_GIT_CLONE_PATH}
