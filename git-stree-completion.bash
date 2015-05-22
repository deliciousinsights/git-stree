# bash completion support for Git STree
#
# http://tdd.github.io/git-stree
#
# Copyright (c) 2014 Christophe Porteneuve <christophe@delicious-insights.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Helper: produces a completion reply with a given suffix on every value
function __git_stree_build_completion {
  COMPREPLY=()
  local i=0 word
  for word in $1; do
    COMPREPLY[i++]="$word$2"
  done
}

# The main completion builder.
function __git_stree_complete {
  local index=$((COMP_CWORD - __GIT_STREE_COMPLETE_OFFSET))
  local cmd=${COMP_WORDS[$((1 + __GIT_STREE_COMPLETE_OFFSET))]}

  # Subcommand
  if [ 1 -eq $index ] || [ 2 -eq $index -a "help" == "$cmd" ] ; then
    __git_stree_build_completion "$(compgen -W "add clear help list pull push rm split" "$2" )" ' '
    return
  fi

  # These take no arguments
  if [ 'clear' == "$cmd" -o "help" == "$cmd" ]; then
    return
  fi

  if [ 2 -eq $index ]; then
    # add/split needs a new, unique name as second argument: can't complete on it
    if [ 'add' == "$cmd" -o 'split' == "$cmd" ]; then
      return
    fi

    if [ 'list' == "$cmd" ]; then
      COMPREPLY=(-v)
      return
    fi

    # Other commands expect a subtree name as second argument
    COMPREPLY=($(__git_stree_complete_list "$2"))
    return
  fi

  # 'pull' accepts 1 fixed extra argument: '--log=<n>'
  if [ 'pull' == "$cmd" ] && [ 3 -eq $index ] && [ '--log=' != "${COMP_WORDS[3]}" ]; then
    COMPREPLY=("--log=")
    return
  fi

  # Besides 'pull', only 'add' / 'split' take more than 1 extra argument
  [ 'add' == "$cmd" -o 'split' == "$cmd" ] || return

  # 3: -P mandatory option
  if [ 3 -eq $index ]; then
    COMPREPLY=("-P ")
  # 4: Mandatory value for the -P option.  Will be a directory (may not exist)
  elif [ 4 -eq $index -a '-P' == "$3" ]; then
    COMPREPLY=($(compgen -d -o nospace -S / "$2" | grep -v '^.git$'))
  # 5+: external URL and possible branch name; can't complete
  fi
}

# Helper. This is actually nearly a copy of git-stree's get_subtree_list helper function.
function __git_stree_complete_list {
  git config --local --get-regexp "remote\.stree-$1.*\.url" | sort | while read key _; do
    sed 's/remote\.stree-\|\.url//g' <<< "$key"
  done
}

# Wrapper: completion entry point when used as git-stree (single command).
function __git_stree_complete_main {
  __GIT_STREE_COMPLETE_OFFSET=0
  __git_stree_complete "$@"
}

# Wrapper: completion entry point when used as git stree (git subcommand).
function __git_stree_main {
  if [ "stree" == "${COMP_WORDS[1]}" ]; then
    __GIT_STREE_COMPLETE_OFFSET=1
    __git_stree_complete "$@"
  elif declare -F __git_wrap__git_main > /dev/null; then
    __git_wrap__git_main "$@"
  fi
}

# Register completion functions (and re-register git completion so we can inject
# stree subcommand completion).
complete -o nospace -F __git_stree_complete_main git-stree
complete -o bashdefault -o default -o nospace -F __git_stree_main git 2>/dev/null \
  || complete -o default -o nospace -F __git_stree_main git
