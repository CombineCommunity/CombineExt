test:
	set -o pipefail && swift test -Xswiftc -suppress-warnings 2>&1 | mise x xcbeautify -- xcbeautify
format:
	mise x swiftformat -- swiftformat .
.PHONY: test format
