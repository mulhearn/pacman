.PHONY: test clean lint

test:
	python -m unittest discover -s test -p "test_*.py" -v

lint:
	flake8 asic --ignore=E501

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +

