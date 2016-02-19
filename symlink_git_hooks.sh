#!/bin/bash
#
# Symlinks in standard git hooks into current repo. Should be run from
# base of repo.
set -eo pipefail

cd .git/hooks/
SCRIPTS=$HOME/github.com/hkjn/scripts
ln -vs $SCRIPTS/pre-commit.sh pre-commit
ln -vs $SCRIPTS/pre-push.sh pre-push
