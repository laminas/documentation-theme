#!/bin/bash
# - Based on https://github.com/peaceiris/actions-gh-pages
#   Copyright (c) 2019 Shohei Ueda (peaceiris)
# @copyright 2020 Laminas Project

set -e

function print_error() {
    echo -e "\e[31mERROR: ${1}\e[m"
}

function print_info() {
    echo -e "\e[36mINFO: ${1}\e[m"
}

function skip() {
    print_info "No changes detected, skipping deployment"
    exit 0
}


if [ ! -f "${GITHUB_WORKSPACE}/mkdocs.yml" ];then
    print_info "No documentation detected; skipping"
    exit 0
fi

# check values
if [ -n "${ACTIONS_DEPLOY_KEY}" ]; then

    print_info "setup with ACTIONS_DEPLOY_KEY"

    if [ -n "${SCRIPT_MODE}" ]; then
        print_info "run as SCRIPT_MODE"
        SSH_DIR="${HOME}/.ssh"
    else
        SSH_DIR="/root/.ssh"
    fi
    mkdir "${SSH_DIR}"
    ssh-keyscan -t rsa github.com > "${SSH_DIR}/known_hosts"
    echo "${ACTIONS_DEPLOY_KEY}" > "${SSH_DIR}/id_rsa"
    chmod 400 "${SSH_DIR}/id_rsa"

    remote_repo="git@github.com:${PUBLISH_REPOSITORY}.git"

else
    print_error "ACTIONS_DEPLOY_KEY not found"
    exit 1
fi

site_url=${INPUT_SITE_URL}
if [[ "${site_url}" == "" ]]; then
    if [[ "$GITHUB_REPOSITORY" =~ "^laminas" ]]; then
        site_url=https://docs.laminas.dev
    elif [[ "$GITHUB_REPOSITORY" =~ "^mezzio/" ]]; then
        site_url=https://docs.mezzio.dev
    else
        site_url=https://docs.laminas.dev
    fi
fi

PUBLISH_REPOSITORY=${GITHUB_REPOSITORY}
PUBLISH_BRANCH=gh-pages

print_info "Deploy to ${PUBLISH_REPOSITORY}@${PUBLISH_BRANCH} from directory ${INPUT_PUBLISH_DIR}"

print_info "Cloning documentation theme"
git clone git://github.com/laminas/documentation-theme.git ${GITHUB_WORKSPACE}/documentation-theme

print_info "Building documentation"
(cd ${GITHUB_WORKSPACE} ; ./documentation-theme/build.sh -u ${site_url})

print_info "Deploying documentation"
remote_branch="${PUBLISH_BRANCH}"
local_dir="${HOME}/ghpages_${RANDOM}"

if git clone --depth=1 --single-branch --branch "${remote_branch}" "${remote_repo}" "${local_dir}"; then
    cd "${local_dir}"

    git rm -r --ignore-unmatch '*'

    find "${GITHUB_WORKSPACE}/${INPUT_PUBLISH_DIR}" -maxdepth 1 -not -name ".git" -not -name ".github" | \
        tail -n +2 | \
        xargs -I % cp -rf % "${local_dir}/"
else
    cd "${INPUT_PUBLISH_DIR}"
    git init
    git checkout --orphan "${remote_branch}"
fi

# push to publishing branch
if [[ -n "${INPUT_USERNAME}" ]]; then
    git config user.name "${INPUT_USERNAME}"
else
    git config user.name "${GITHUB_ACTOR}"
fi
if [[ -n "${INPUT_USEREMAIL}" ]]; then
    git config user.email "${INPUT_USEREMAIL}"
else
    git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
fi
git remote rm origin || true
git remote add origin "${remote_repo}"
git add --all

print_info "Allowing empty commits: ${INPUT_EMPTYCOMMITS}"
COMMIT_MESSAGE="Automated deployment: $(date -u) ${GITHUB_SHA}"
if [[ ${INPUT_EMPTYCOMMITS} == "false" ]]; then
    git commit -m "${COMMIT_MESSAGE}" || skip
else
    git commit --allow-empty -m "${COMMIT_MESSAGE}"
fi

git push origin "${remote_branch}"

print_info "${GITHUB_SHA} was successfully deployed"
