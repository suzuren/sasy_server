


.PHONY : httpClient clean

httpClient : ./client/httpclient.o
	gcc -lpthread ./client/httpclient.o -o ./client/httpClient -Iclient

./client/httpclient.o : ./client/httpclient.c
	gcc  -g -Wall -c ./client/httpclient.c -o ./client/httpclient.o

	cd pbs && make
	cd luaclib-src && make

clean :
	cd pbs && make clean
	cd luaclib-src && make clean
	rm -f *.so
	rm -rf ./logs ./program_log/*.log ./program_log/*.pid
	rm -f ./client/*.o ./client/httpClient ./client/core.*