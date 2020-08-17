#!/bin/bash
# - Based on https://github.com/peaceiris/actions-gh-pages
#   Copyright (c) 2019 Shohei Ueda (peaceiris)
# @copyright 2020 Laminas Project

set -e

export TOP_PID=$$
trap "exit 0" TERM
trap "exit 1" KILL

function print_error() {
    echo -e "\e[31mERROR: ${1}\e[m"
}

function print_info() {
    echo -e "\e[36mINFO: ${1}\e[m"
}

function skip() {
    print_info "No changes detected, skipping deployment"
    kill -s TERM $TOP_PID
}

# checkout the repository
git clone git://github.com/${GITHUB_REPOSITORY}.git ${GITHUB_WORKSPACE}

if [ ! -f "${GITHUB_WORKSPACE}/mkdocs.yml" ];then
    print_info "No documentation detected; skipping"
    kill -s TERM $TOP_PID
fi

# check values
remote_repo=""
if [ -n "${DOCS_DEPLOY_KEY}" ]; then

    print_info "setup with DOCS_DEPLOY_KEY"

    SSH_DIR="/root/.ssh"
    mkdir "${SSH_DIR}"
    ssh-keyscan -t rsa github.com > "${SSH_DIR}/known_hosts"
    echo "${DOCS_DEPLOY_KEY}" > "${SSH_DIR}/id_rsa"
    chmod 400 "${SSH_DIR}/id_rsa"

    remote_repo="git@github.com:${GITHUB_REPOSITORY}.git"
else
    print_error "DOCS_DEPLOY_KEY not found"
    kill -s KILL $TOP_PID
fi
print_info "Publishing to ${remote_repo}"

site_url=${INPUT_SITE_URL}
if [[ "${site_url}" == "" ]]; then
    if [[ "$GITHUB_REPOSITORY" =~ ^mezzio/ ]]; then
        site_url=https://docs.mezzio.dev/${GITHUB_REPOSITORY#*/}
    else
        site_url=https://docs.laminas.dev/${GITHUB_REPOSITORY#*/}
    fi
fi
print_info "Using site URL ${site_url}"

PUBLISH_REPOSITORY=${GITHUB_REPOSITORY}
PUBLISH_BRANCH=gh-pages
PUBLISH_DIR=`grep 'site_dir:' mkdocs.yml | awk '{print $2}'`

print_info "Deploy to ${PUBLISH_REPOSITORY}@${PUBLISH_BRANCH} from directory ${PUBLISH_DIR}"

print_info "Cloning documentation theme"
git clone git://github.com/laminas/documentation-theme.git ${GITHUB_WORKSPACE}/documentation-theme

print_info "Building documentation"
(cd ${GITHUB_WORKSPACE} ; ./documentation-theme/build.sh -u ${site_url})

print_info "Deploying documentation"
remote_branch="${PUBLISH_BRANCH}"
local_dir="${HOME}/ghpages_${RANDOM}"

if git clone --depth=1 --single-branch --branch "${remote_branch}" "${remote_repo}" "${local_dir}"; then
    print_info "- Cloning branch ${remote_branch} from ${remote_repo} to ${local_dir} and removing previous files"
    cd "${local_dir}"

    git rm -r --ignore-unmatch '*'
else
    print_info "- Creating new ${remote_branch} branch on ${remote_repo} in ${local_dir}"
    git clone --depth=1 --single-branch --branch master "${remote_repo}" "${local_dir}"
    cd "${local_dir}"
    git checkout --orphan "${remote_branch}"
    git rm -rf .
fi

find "${GITHUB_WORKSPACE}/${PUBLISH_DIR}" -maxdepth 1 -not -name ".git" -not -name ".github" | \
    tail -n +2 | \
    xargs -I % cp -rf % "${local_dir}/"

print_info "- Adding user and email to local clone for purposes of commit"
if [[ -n "${INPUT_USERNAME}" ]]; then
    cd "${local_dir}" && git config user.name "${INPUT_USERNAME}"
else
    cd "${local_dir}" && git config user.name "${GITHUB_ACTOR}"
fi
if [[ -n "${INPUT_USEREMAIL}" ]]; then
    cd "${local_dir}" && git config user.email "${INPUT_USEREMAIL}"
else
    cd "${local_dir}" && git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
fi
cd "${local_dir}" && git remote rm origin || true
cd "${local_dir}" && git remote add origin "${remote_repo}"
cd "${local_dir}" && git add --all

print_info "Allowing empty commits: ${INPUT_EMPTYCOMMITS}"
COMMIT_MESSAGE="Automated deployment: $(date -u) ${GITHUB_SHA}"
if [[ ${INPUT_EMPTYCOMMITS} == "false" ]]; then
    cd "${local_dir}" && git commit -m "${COMMIT_MESSAGE}" || skip
else
    cd "${local_dir}" && git commit --allow-empty -m "${COMMIT_MESSAGE}"
fi

# push to publishing branch
print_info "- Pushing from ${local_dir} to ${remote_branch}"
cd "${local_dir}" && git push origin "${remote_branch}"

print_info "${GITHUB_SHA} was successfully deployed"
