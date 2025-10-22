current_patch_number := $(shell git tag --list "v0.0.*" | sort -V | tail -n 1 | cut -c 6-)
next_patch_number := $(shell echo $$(($(current_patch_number)+1)))
next_version_tag := v0.0.$(next_patch_number)

build:
	docker build -t coderbot .

print_next_version_tag:
	@echo $(next_version_tag) | tr -d '\n'