.PHONY: test test-default test-instances test-pkgbase test-tarball destroy

test: test-default test-instances test-pkgbase test-tarball destroy

test-default:
	molecule test -s default

test-instances:
	molecule test -s with_instances

test-pkgbase:
	molecule test -s pkgbase

test-tarball:
	molecule test -s tarball

destroy:
	molecule destroy -s default
	molecule destroy -s with_instances
	molecule destroy -s pkgbase
	molecule destroy -s tarball
