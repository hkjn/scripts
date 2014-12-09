#!/bin/bash
#
# Symlinks in standard git hooks into current repo. Should be run from
# base of repo.

cd .git/hooks/
ln -vs ~/src/pre-commit.sh pre-commit
ln -vs ~/src/pre-push.sh pre-push
