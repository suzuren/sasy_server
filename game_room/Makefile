


.PHONY : depend httpclient clean

httpclient : ./client/httpclient.o depend
	gcc -lpthread -lrt ./client/httpclient.o -o ./client/httpclient -Iclient -L./luaclib-src/pbc/build  -lpbc

./client/httpclient.o : ./client/httpclient.c
	gcc  -g -Wall -c ./client/httpclient.c -o ./client/httpclient.o -I./luaclib-src

depend :
	cd pbs && make
	cd luaclib-src && make



clean :
	cd pbs && make clean
	cd luaclib-src && make clean
	rm -f *.so core.*
	rm -rf ./logs ./program_log/*.log ./program_log/*.pid
	rm -f ./client/*.o ./client/httpclient ./client/core.*