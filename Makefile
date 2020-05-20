archive:
	make project
	scripts/carthage-archive.sh
project:
	scripts/make_project.rb
clean:
	rm -rf CombineExt.xcodeproj
test:
	swift test -Xswiftc -suppress-warnings | xcpretty -c

.PHONY: clean