# Golang git hooks, useful in constructing e.g. pre-commit, pre-push.

function has_conflicts() {
		echo "Checking for merge conflicts.." >&2
		conflicts=$(git diff --cached --name-only -S'<<<<<< HEAD')
		if [ -n "$conflicts" ]; then
				echo "Unresolved merge conflicts in this commit:" >&2
				echo $conflicts >&2
				return 1
		fi
		return 0
}

function needs_gofmt() {
	echo "Checking if any files need gofmt.." >&2
	IFS=$'\n'
	if [ git rev-parse HEAD >/dev/null 2>&1 ]; then
		FILES=$(git diff --cached --name-only | grep -e '\.go$');
	else
		FILES=$(git ls-files -c | grep -e '\.go$');
	fi
	failed=0
	for file in $FILES; do
		if [ ! -e "$file" ]; then
			# If a cached file doesn't exist it must be about to be deleted
			# in this commit, so no need to check it.
			continue
		fi
		badfile="$(gofmt -l "$file")"
		if test -n "$badfile" ; then
			echo "git pre-commit check failed: file needs gofmt: $file" >&2
			failed=1
		fi
	done
	if [ $failed -ne 0 ]; then
		return 1
	fi
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

function prevent_hacks() {
	echo "Checking for strings indicating hacks.." >&2
	if [ git rev-parse HEAD >/dev/null 2>&1 ]; then
		FILES=$(git diff --cached --name-only)
	else
		FILES=$(git ls-files -c)
	fi
	failed=0
	if grep -ir "FIXME" $FILES 2>/dev/null; then
		echo "Please remove offending string." >&2
		failed=1
	fi
	if grep -ir "DO NOT SUBMIT" $FILES; then
		echo "Please remove offending string." >&2
		failed=1
	fi
	if [ $failed -ne 0 ]; then
		return 1
	fi
	return 0
}

function run_go_tests() {
	echo "Running all Go tests.." >&2
	local testBinary=go
	if which goapp 1>/dev/null; then
		testBinary=goapp
	fi
	output=$($testBinary test ./... 2>&1)
	if [ $? -eq 0 ]; then
		return 0
	fi
	if echo "$output" | grep "matched no packages" >/dev/null; then
		# Special case for "there's no packages in this repo", which is fine.
		return 0
	fi
	echo "Go tests failed:\n$output" >&2
	return 1
}

function update_bindata {
	if [ -d "bindata/" ]; then
		echo "Checking if bindata needs regenerating.." >&2
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
		echo "Checking for godeps updates.." >&2
		godep update ...
		dirty=$(prevent_dirty_tree Godeps/ "commit dependency changes first")
		return ${dirty}
	fi
	return 0
}
