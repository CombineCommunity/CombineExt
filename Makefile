archive:
	make project
	scripts/carthage-archive.sh
project:
	scripts/make_project.rb
clean:
	rm -rf CombineExt.xcodeproj
test:
	set -o pipefail && swift test -Xswiftc -suppress-warnings 2>&1 | mise x xcbeautify -- xcbeautify
format:
	mise x swiftformat -- swiftformat .
.PHONY: clean
