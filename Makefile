.PHONY: test test-default test-instances destroy

test: test-default test-instances destroy

test-default:
	${MOLECULE} test -s default

test-instances:
	${MOLECULE} test -s with_instances

destroy:
	${MOLECULE} destroy -s default
	${MOLECULE} destroy -s with_instances
