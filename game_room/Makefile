

root_dir=$(cd `dirname $0`; pwd)

.PHONY : all clean

all : 
	cd pbs && make
	cd ${root_dir}
	cd luaclib-src && make
	cd ${root_dir}
clean :
	cd pbs && make clean
	cd ${root_dir}
	cd luaclib-src && make clean
	cd ${root_dir}
	rm -f *.so
	rm -rf ./logs ./program_log/*.log ./program_log/*.pid