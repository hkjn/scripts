# Golang git hooks, useful in constructing e.g. pre-commit, pre-push.

# Fail if any command fails (returns != 0).
set -e
set -o pipefail

function needs_gofmt() {
	echo "Checking if any files need gofmt.." >&2
	IFS=$'\n'
	if [ git rev-parse HEAD >/dev/null 2>&1 ]; then
		FILES=$(git diff --cached --name-only | grep -e '\.go$');
	else
		FILES=$(git ls-files -c | grep -e '\.go$');
	fi
	for file in $FILES; do
		badfile="$(gofmt -l "$file")"
		if test -n "$badfile" ; then
			echo "git pre-commit check failed: file needs gofmt: $file" >&2
			return 1
		fi
	done
	return 0
}

function prevent_dirty_tree() {
	if [ "$#" -ne 2 ]; then
		echo "Usage: prevent_dirty_tree [directory] [comment]" >&2
		return 1
	fi
	if [ $(git status --porcelain 2>/dev/null ${1} | grep "^ M" | wc -l) -ne "0" ]; then
		echo "Diff in ${1} - ${2}:" >&2
		echo $(git diff --numstat ${1})
		return 1
	fi
	return 0
}

function run_go_tests() {
	echo "Running all Go tests.." >&2
	passed=$(goapp test ./... >&2)
	return ${passed}
}

function update_bindata {
	if [ -d "bindata/" ]; then
		echo "Regenerating bindata.." >&2
		go-bindata -pkg="bindata" -o bindata/bin.go tmpl/
		# TODO: since go-bindata doesn't properly format its output, we need
		# to do it ourselves.
		gofmt -w bindata/bin.go
		dirty=$(prevent_dirty_tree bindata/ "commit bindata changes first")
		return ${dirty}
	fi
	return 0
}

function update_godep {
	if [ -d "Godeps/" ]; then
		echo "Updating godeps.." >&2
		godep update ...
		dirty=$(prevent_dirty_tree Godeps/ "commit dependency changes first")
		return ${dirty}
	fi
	return 0
}
