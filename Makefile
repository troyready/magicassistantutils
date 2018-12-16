clean:
	rm -rf build/
	rm -rf dist/

test:
	PIPENV_IGNORE_VIRTUALENVS=1 pipenv sync -d --three
	pipenv run flake8 magicassistantutils
	pipenv run mypy magicassistantutils
	pipenv run python setup.py test
