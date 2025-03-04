#!/usr/bin/env bash
set -eu -o pipefail

# Add git.drupal.org to known_hosts
mkdir -p ~/.ssh
host=git.drupal.org
SSHKey=$(ssh-keyscan $host 2>/dev/null)
echo "$SSHKey" >>~/.ssh/known_hosts

# Ignore specific directories during Drupal core development
cp "${APP_ROOT}"/.gitpod/drupal/templates/git-exclude.template "${APP_ROOT}"/.git/info/exclude

# Get the required repo ready
if [ "$DP_PROJECT_TYPE" == "project_core" ]; then
    # Find if requested core version is dev or stable
    d="$DP_CORE_VERSION"
    case $d in
    *.x)
        # If dev - use git checkout origin/*
        checkout_type=origin
        ;;
    *)
        # stable - use git checkout tags/*
        checkout_type=tags
        ;;
    esac

    # Use origin or tags in git checkout command
    cd "${APP_ROOT}"/repos/drupal &&
        git fetch origin &&
        git fetch --all --tags &&
        git checkout "$checkout_type"/"$DP_CORE_VERSION"

    # Ignore specific directories during Drupal core development
    cp "${APP_ROOT}"/.gitpod/drupal/templates/git-exclude.template "${APP_ROOT}"/repos/drupal/.git/info/exclude
else
    # If not core - clone selected project into /repos and remove drupal core
    rm -rf "${APP_ROOT}"/repos/drupal
    if [ ! -d repos/"${DP_PROJECT_NAME}" ]; then
        mkdir -p repos
        cd "${APP_ROOT}"/repos && time git clone https://git.drupalcode.org/project/"$DP_PROJECT_NAME".git
    fi
fi

# Set WORK_DIR
export WORK_DIR="${APP_ROOT}"/repos/$DP_PROJECT_NAME

# Dynamically generate .gitmodules file
cat <<GITMODULESEND >"${APP_ROOT}"/.gitmodules
# This file was dynamically generated by a script
[submodule "$DP_PROJECT_NAME"]
path = repos/$DP_PROJECT_NAME
url = https://git.drupalcode.org/project/$DP_PROJECT_NAME.git
ignore = dirty
GITMODULESEND

# Checkout specific branch only if there's issue_branch
if [ -n "$DP_ISSUE_BRANCH" ]; then
    # If branch already exist only run checkout,
    if cd "${WORK_DIR}" && git show-ref -q --heads "$DP_ISSUE_BRANCH"; then
        cd "${WORK_DIR}" && git checkout "$DP_ISSUE_BRANCH"
    else
        cd "${WORK_DIR}" && git remote add "$DP_ISSUE_FORK" https://git.drupalcode.org/issue/"$DP_ISSUE_FORK".git
        cd "${WORK_DIR}" && git fetch "$DP_ISSUE_FORK"
        cd "${WORK_DIR}" && git checkout -b "$DP_ISSUE_BRANCH" --track "$DP_ISSUE_FORK"/"$DP_ISSUE_BRANCH"
    fi
elif [ -n "$DP_MODULE_VERSION" ] && [ "$DP_PROJECT_TYPE" != "project_core" ]; then
    cd "${WORK_DIR}" && git checkout "$DP_MODULE_VERSION"
fi
