#!/usr/bin/env bash

set -euo pipefail

function printHelpText
{
  echo "Usage:"
  echo "  ${0} [OPTIONS]"
  echo ""
  echo "application Options:"
  echo "  -p, --default-clone-path= Default path to git clone into (default: ./)"
  echo "  -f, --gitfile= File path to the Gitfile (default: ./.gitfile)"
  echo ""
  echo "Help Options:"
  echo "  -h, --help            Show this help message and exit"
  echo ""
  exit 0
}

function cloneRepo
{
  SOURCE=${1}
  VERSION=${2}
  GIT_CLONE_PATH=${3//\~/$HOME}
  echo "${SOURCE}"
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
  YAML_FILE_CONTENT=$(cat ${1} | grep -E -v "^\s*#")
  DEFAULT_GIT_CLONE_PATH=${2}
  LAST_LINE_NUMBER="$(echo "${YAML_FILE_CONTENT}" | wc -l | awk '{print $1}')"
  mapfile -t LINE_NUMBERS < <(echo "${YAML_FILE_CONTENT}" | cat -n | grep -E -v "source:|version:|path:" | grep -E "[0-9]{1,10}.*:\s*$" | awk '{print $1}')
  mapfile -t DIR_NAMES  < <(echo "${YAML_FILE_CONTENT}" | cat -n | grep -E -v "source:|version:|path:" | grep -E "[0-9]{1,10}.*:\s*$" | awk '{print $2}')
  for (( i=0; i < ${#LINE_NUMBERS[@]}; ++i ))
  do
    FROM=$(expr ${LINE_NUMBERS[$i]} + 1)
    TO=$(expr ${LAST_LINE_NUMBER} + 1)
    if [ "$i" -ne "$(expr ${#LINE_NUMBERS[@]} - 1 )" ]; then
      TO=$(expr ${LINE_NUMBERS[$i + 1]} - 1)
    fi
    SOURCE=$(echo "${YAML_FILE_CONTENT}" | sed -n "${FROM},${TO}p" | grep "source:" | awk '{print $2}' | cut -d'"' -f2)
    VERSION=$(echo "${YAML_FILE_CONTENT}" | sed -n "${FROM},${TO}p" | grep "version:" | awk '{print $2}' | cut -d'"' -f2 || echo "main")
    GIT_CLONE_PATH=$(echo "${YAML_FILE_CONTENT}" | sed -n "${FROM},${TO}p" | grep "path:" | awk '{print $2}' | cut -d'"' -f2 || echo "${DEFAULT_GIT_CLONE_PATH}")
    cloneRepo ${SOURCE} ${VERSION} ${GIT_CLONE_PATH%/}/${DIR_NAMES[$i]%:}
  done
}

DEFAULT_GIT_CLONE_PATH="."
YAML_FILE="./.gitfile"
while [ "$#" -gt 0 ]; do
  case "$1" in
    -p) DEFAULT_GIT_CLONE_PATH="${2%/}"; shift 2;;
    -f) YAML_FILE="$2"; shift 2;;

    --default-clone-path=*) DEFAULT_GIT_CLONE_PATH="${1#*=}"; shift 1;;
    --gitfile=*) YAML_FILE="${1#*=}"; shift 1;;
    --default-clone-path|--gitfile) echo "$1 requires an argument" >&2; exit 1;;

    -h) printHelpText;;
    --help) printHelpText;;

    -*) echo "unknown option: $1" >&2; exit 1;;
    *) handle_argument "$1"; shift 1;;
  esac
done

if [ ! -f "${YAML_FILE}" ]; then
  echo "[ERROR] '${YAML_FILE}' does not exist"
  exit 1
fi

cd "$(dirname "${YAML_FILE}")"
YAML_FILE="./$(echo ${YAML_FILE} | rev | cut -d "/" -f 1 | rev)"
parseYaml ${YAML_FILE} ${DEFAULT_GIT_CLONE_PATH}
