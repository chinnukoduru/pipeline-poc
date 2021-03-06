#!/bin/sh

set -eux

SCRIPT_DIR=$(dirname "$0")
source ${SCRIPT_DIR}/mvn-tools.sh

FINAL_VERSION=$(cat final-version/version)
FULL_FINAL_VERSION="${FINAL_VERSION}${FINAL_VERSION_SUFFIX}"

NEXT_VERSION=$(cat next-version/version)
FULL_NEXT_VERSION="${NEXT_VERSION}${NEXT_VERSION_SUFFIX}"

if [ -z ${RELEASE_BRANCH} ]; then
    echo "The RELEASE_BRANCH parameter is required"
    exit 2
fi

git clone source updated-source

cd updated-source
    # Produce release notes
    last_tag=$(git describe --tags $(git rev-list --tags --max-count=1))

    echo "## Changes since release ${last_tag}:" > release.md
    git log ${last_tag}..HEAD --reverse --pretty=format:'- [%s](${GITHUB_PROJECT_PAGE}/commit/%H)' | grep -v 'ci skip' >> release.md

    git config user.email "wings@pivotal.io"
    git config user.name "Concourse CI"

    git checkout -b version-bump
    set_revision_to_pom ${FULL_FINAL_VERSION}

    git add pom.xml && git commit -m "[ci skip] Finalize POM version for release to ${FULL_FINAL_VERSION}" 
    git tag "v${FINAL_VERSION}"

    set_revision_to_pom ${FULL_NEXT_VERSION}
    git add pom.xml && git commit -m "[ci skip] Bump POM version for next build to ${FULL_NEXT_VERSION}" 

    git checkout ${RELEASE_BRANCH}
    git merge version-bump
    git branch -d version-bump
cd -