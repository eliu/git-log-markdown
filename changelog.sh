#!/usr/bin/env bash
#
# Copyright 2020-2023 eliu (eliuhy@163.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ############################################################
# 版本     日期         发布者    发布日志
# ------  ----------  -------  -------------------------------
# v1.0.0  2020/06/18  eliu     初版
# v1.0.1  2020/06/19  eliu     允许只提供 --since 参数
# v1.0.2  2022/12/18  eliu     应用 Google Style Guide
# v1.0.3  2020/12/23  eliu     使用 --no-merges 来过滤合并提交记录
# v1.0.4  2023/11/21  eliu     完善帮助命令 --help
# ############################################################
set -o errexit

export VERSION_FROM   # 拉取日志的提交ID下限
export VERSION_TO     # 拉取日志的提交ID上限
export COMMIT_RANGE   # 拉取日志的提交范围
export CHANGELOG_FILE # 变更日志文件名称
export PREFIX="."    # Git 仓库目录名称前缀 

readonly PROG=$(basename $0)
readonly VERSION="v1.0.4"
readonly GRN="\e[32m" # green color
readonly YLW="\e[33m" # yellow color
readonly RED="\e[91m" # red color
readonly RST="\e[39m" # reset color

# --- common functions definition ---
logger::info() {
  echo -e "$GRN[INFO]$RST" $@
}
logger::warn() {
  echo -e "$YLW[WARN]$RST" $@
}
logger::error() {
  echo -e "$RED[FATA]$RST" $@ >&2
  exit 1
}
sys_already_installed() {
  command -v $@ >/dev/null
}

show_help() {
  echo -e "
USAGE
    ${GRN}${PROG}${RST} ${YLW}[--since [VERSION]]${RST} ${YLW}[--until [VERSION]]${RST}

OPTIONS
    -h | --help)      Print help
    -v | --version)   Print version info
    -p | --prefix)    If provided, search all sub-folders with this prefix. 
                      Otherwise process current directory.
    -s | --since)     Commit id from
    -u | --until)     Commit id to

EXAMPLES
    1. Generate all change logs between 1.0.1 and 1.0.2
    
        \$ $PROG --since 1.0.1 --until 1.0.2

    2. Generate all change logs of version 1.0.2 from the very beginning

        \$ $PROG --until 1.0.2
    
    3. Generate all change logs since version 1.0.2

        \$ $PROG --since 1.0.2
"
  exit 0
}

print_version() {
  echo $VERSION
  exit $?
}

# --- Calculate commit range for git-log ---
init_variables() {
  if [ -z "$VERSION_FROM" ]; then
    COMMIT_RANGE="$VERSION_TO"
    CHANGELOG_FILE="CHANGELOG-${VERSION_TO}.md"
  elif [ -z "$VERSION_TO" ]; then
    COMMIT_RANGE="$VERSION_FROM..HEAD"
    CHANGELOG_FILE="CHANGELOG-${VERSION_FROM}-HEAD.md"
  else
    COMMIT_RANGE="$VERSION_FROM..$VERSION_TO"
    CHANGELOG_FILE="CHANGELOG-${VERSION_FROM}-${VERSION_TO}.md"
  fi
}

# --- Print change logs ---
write_changelog() {
  local repo=$1

  CHANGELOG="$(git log --no-merges --format="| %h | %ad | %an | %s |" --date=short $COMMIT_RANGE 2>/dev/null || true)"
  if [ -n "$CHANGELOG" ]; then
    echo "### CHANGELOG FOR $repo"
    echo "-----------------------"
    echo "| COMMIT ID | COMMIT DATE | AUTHOR | COMMIT MSG. |"
    echo "| --- | --- | --- | --- |"
    echo "$CHANGELOG"
  fi
}

# --- Print git log ---
print_command() {
  echo "\`git log --no-merges --format=\"%h %ad %an %s\" --date=short $COMMIT_RANGE\`"
  echo ""
}

find_subdirectories() {
  local pattern=$1
  ls -F | grep -e "^$pattern.*/$" | sed 's /  g'
}

is_git() {
  [ -d ".git" ]
}

# --- Main entrypoint ---
{
  [ $# -gt 0 ] || logger::error "No option found. Try '${GRN}${0}${RST} ${YLW}--help${RST}' for more details."
  while [ $# -gt 0 ]; do
    case "$1" in
    -h | --help) show_help ;;
    -v | --version) print_version ;;
    -p | --prefix)
      PREFIX=$2
      shift
      shift || true
      ;;
    -s | --since)
      VERSION_FROM=$2
      shift
      shift || true
      ;;
    -u | --until)
      VERSION_TO=$2
      shift
      shift || true
      ;;
    *) logger::error "Invalid option '$1'. Try '${GRN}${0}${RST} ${YLW}--help${RST}' for more details." ;;
    esac
  done
  [ -n "$VERSION_FROM" -o -n "$VERSION_TO" ] ||
    logger::error "Invalid options -> No value for '${GRN}--until${RST}' or '${GRN}--since${RST}'"

  init_variables

  logger::info "CHANGELOG will be written to file $CHANGELOG_FILE"
  print_command > "$CHANGELOG_FILE"

  is_git && write_changelog `basename "$PWD"` >> "$CHANGELOG_FILE"
  
  if [ ! -z "$PREFIX" ]; then
    for repo in $(find_subdirectories $PREFIX); do
      cd $repo
      if is_git; then
        logger::info "appending change logs for $repo ..."
        write_changelog $repo >> "../$CHANGELOG_FILE"
      fi
      cd ..
    done
  fi
}
