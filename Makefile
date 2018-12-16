clean:
	rm -rf build/
	rm -rf dist/

test:
	pipenv run flake8 magicassistantutils
	pipenv run mypy magicassistantutils
	pipenv run python setup.py test
