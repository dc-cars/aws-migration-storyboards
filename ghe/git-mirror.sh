#!/usr/bin/env bash

# ########################################################################### #
#
#  ./git-mirror.sh \
#    git@github.nchub.net:cars-sm/ops-handbook.git \
#    git@cars-sm.github.com:cars-sm/ops-handbook.git \
#  ;
#
# ########################################################################### #


# ........................................................................... #
# turn on tracing of error, this will bubble up all the error codes
# basically this allows the ERR trap is inherited by shell functions
set -o errtrace;
# turn on quiting on first error
set -o errexit;
# error out on undefined variables
set -o nounset;
# propagate pipe errors
set -o pipefail;
# debugging
#set -o xtrace;


# ........................................................................... #
# get this scripts file name
SCRIPT_NAME=$(basename "${0}");
# get this scripts folder
SCRIPT_FOLDER="$(cd $(dirname "${0}") && pwd -P)";

TMP_FOLDER="${SCRIPT_FOLDER}/tmp"


# ........................................................................... #
function main {
  local source_uri="${1}";
  local target_uri="${2}";

  local target_name="$(basename "${source_uri}")";

  # create temporary repository folder path
  local target_folder="${TMP_FOLDER}/${target_name}";

  # remove any existing repository folder
  rm \
   --recursive \
   --force \
   "${target_folder}" \
  ;

  # make bare repositoru
  git init \
    --bare \
    ${target_folder} \
  ;

  # get all the refs besides HEAD and github pull
  # note, github pull refs is what stops from using basic mirror command
  refs=()
  while read ref; do
      refs+=("fetch = +${ref}/*:${ref}/*");
  done < <(
    git ls-remote \
      ${source_uri} \
    | cut -d$'\t' -f2 \
    | grep -v ^HEAD$ \
    | grep -v '^refs/pull/' \
    | cut -d'/' -f1,2 \
    | sort \
    | uniq \
  )

  # create origin mirror config
  cat << __EOF | sed 's/^  //g' | tee "${target_folder}/config" > /dev/null
  [remote "origin"]
    url = ${source_uri}
    mirror = true
__EOF

  # add refs to fetch
  for ref in "${refs[@]}"; do
    echo "  ${ref}" >> "${target_folder}/config";
  done

  # add ghe cloud config
  cat << __EOF | sed 's/^  //g' | tee -a "${target_folder}/config" > /dev/null
  [remote "cloud"]
    url = ${target_uri}
    mirror = true
    skipDefaultUpdate = true
__EOF

  # print config
  cat  "${target_folder}/config";

  # fetch to the cloud (use remote update to get all branches)
  git \
    -C "${target_folder}" \
    remote update \
  ;

  # push to the cloud
  git \
    -C "${target_folder}" \
    push \
      cloud \
  ;

}


# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@# #
main "$@";
