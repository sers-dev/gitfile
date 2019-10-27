all:
	${MAKE} test
	${MAKE} install

test:
		docker-compose up --exit-code-from test test

install:
		cp ./gitfile.sh /usr/local/bin/gitfile
