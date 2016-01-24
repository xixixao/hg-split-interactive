#!/bin/bash

if [ "$1" = "--help" ] || [ "$1" = "help" ]; then
  echo "hg-split-interactive [OPTIONS] [HG_SPLIT_OPTIONS] [HG_COMMIT_OPTIONS]"
  echo ""
  echo "split current commit into two by interactively selecting changed files"
  echo ""
  echo "    Use up and down arrow keys to select files which have changed in"
  echo "    current commit. Hit Enter to mark the file as included. Hit"
  echo "    CTRL-Z or Y to move the selected file changes to a new, sibling"
  echo "    commit. Hit Q, CTRL-C or Esc to exit without making any changes."
  echo ""
  echo "    For example:"
  echo ""
  echo "        hg-split-interactive --shelve -n -b other-mark -m \"Others\""
  echo ""
  echo "    commits the changes made to selected files in this commit as a new"
  echo "    commit which has the same parent. Also sets bookmark 'other-mark'"
  echo "    to this new commit. If there are uncommited changes,"
  echo "    shelves them and unshelves them at the original commit at the end."
  echo "    If there are no uncommited changes, updates to 'other-mark'. The"
  echo "    new commit has a message: \"Others\"."
  echo ""
  echo "OPTIONS can be any of:"
  echo "    --help    shows this help listing"
  exit
fi

# Get path to our node module
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# 0 if dirty
is_dirty=$([[ ! -z `hg status | grep -v '^?'` ]] ; echo $?) &&

# Exit early
if [[ $is_dirty -eq 0 ]] && [[ ! $@ =~ "--shelve" ]]; then
  echo "abort: uncommitted changes"
  exit
fi &&

# read picked files and remove colors and marks and join into a list
picked_files=`hg --color=always status --change . |
  "$DIR/node_modules/.bin/pick-lines" |
  perl -pe 's/\e\[?.*?[\@-~]//g' |
  sed 's/^. //' |
  tr '\n' ' '` &&

[[ ${#picked_files} -ne 0 ]] &&
"$DIR/node_modules/.bin/hg-split" "$@" --dirty $is_dirty -- ${picked_files[@]}
