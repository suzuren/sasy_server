#include <pthread.h>
#include <unistd.h>
#include <sys/file.h>
#include <sys/resource.h>
#include <unistd.h>
#include <signal.h>

#include "select.h"

#include "pbc/pbc.h"
#include "pbc/readfile.h"


#define threadcount 1024
static bool _runflag[threadcount];

#define IPADDRESS "127.0.0.1"
#define PORT 3002

struct tagparam_http
{
	int id;
	char * api;
	char * body; 
};

struct tagparam_telnet
{
	int id;
	char * data;
};

struct tagparam_gate
{
	int id;
};

// --------------------------------------------------------------------------------------------------------------------------

void * thread_http_socket(void *p)
{

	struct tagparam_http * s = p;
	int fd = socket_connect(IPADDRESS, PORT);

	char wbuffer[10846];
	memset(wbuffer, 0, sizeof(wbuffer));

	int id = s->id;
	char * api = s->api;
	char * body = s->body;
	
	char * ppack = http_build_post_head(api, body);
	int size_pack = strlen(ppack);
	memcpy(wbuffer, ppack, size_pack);
	free(ppack);

	//printf("pthread_self:%ld,api:%s,body:%s\n",pthread_self(),api, body);

	//printf("%s fd:%d,pthread_self:%ld,size_pack:%d,wbuffer:-\n%s\n-\n", getStrTime(), fd, pthread_self(),size_pack, wbuffer);

	int wlenght = 0;
	while(true)
	{
		int size_send = write(fd, wbuffer + wlenght, size_pack);

		if (size_send != size_pack)
		{
			printf("send buf error\n");
		}
		wlenght += size_send;
		size_pack-=size_send;
		if(size_pack==0)
		{
			break;
		}
	}
	
	char rbuffer[16384 * 5] = { 0 };
	int  rlenght = 0;

	for (;;)
	{
		ms_sleep(3);
		memset(rbuffer, 0, sizeof(rbuffer));
		int rsize = read(fd, rbuffer + rlenght, sizeof(rbuffer) - rlenght);
		//printf("read function - pthread_self:%ld,rsize:%d,errno:%d,EINTR:%d,EAGAIN:%d\n",pthread_self(),rsize,errno,EINTR,EAGAIN);
		if (rsize<0)
		{
			if (errno == EINTR) // 指操作被中断唤醒，需要重新读 / 写
			{
				continue;
			}
			if (errno == EAGAIN) // 现在没有数据可读请稍后再试
			{
				continue;
			}
			fprintf(stderr, "socket : read socket error-%d-%s.\n\n", errno,strerror(errno));
			close(fd);
			break;
		}
		if (rsize == 0)
		{
			close(fd);
			printf("read socket close.\n");
			break;
		}
		rlenght += rsize;
		printf("\n--------------------------\npid:%ld,fd:%d, rlenght:%d, rsize:%d,\nwbuffer:\n--------------------------\n%s\n--------------------------,\nrbuffer:\n--------------------------\n%s\n--------------------------\n", pthread_self(), fd, rlenght, rsize, wbuffer, rbuffer);
	}
	_runflag[id] = false;
	printf("pthread_self:%ld,id:%d,_runflag:%d,socket thread exit!\n",pthread_self(),id,_runflag[id]);
	return NULL;
}

// --------------------------------------------------------------------------------------------------------------------------

void * thread_telnet_socket(void *p)
{
	struct tagparam_telnet * s = p;

	int id = s->id;
	int fd = socket_connect(IPADDRESS, 3003);

	char wbuffer[512];
	memset(wbuffer, 0, sizeof(wbuffer));
	strcat(wbuffer, s->data);
	int size_pack = strlen(wbuffer);
	//printf("%s fd:%d,pthread_self:%ld,size_pack:%d,wbuffer:-\n%s\n-\n", getStrTime(), fd, pthread_self(),size_pack, wbuffer);

	int wlenght = 0;
	while(true)
	{
		int size_send = write(fd, wbuffer + wlenght, size_pack);

		if (size_send != size_pack)
		{
			printf("send buf error\n");
		}
		wlenght += size_send;
		size_pack -= size_send;
		if(size_pack == 0)
		{
			break;
		}
	}

	char rbuffer[16384 * 5] = { 0 };
	int  rlenght = 0;

	const char * ptail = "TELNET_OK\n";

	for (;;)
	{
		ms_sleep(3);
		//memset(rbuffer, 0, sizeof(rbuffer));
		int rsize = read(fd, rbuffer + rlenght, sizeof(rbuffer) - rlenght);
		//printf("read function - pthread_self:%ld,rsize:%d,errno:%d,EINTR:%d,EAGAIN:%d\n",pthread_self(),rsize,errno,EINTR,EAGAIN);
		if (rsize<0)
		{
			if (errno == EINTR) // 指操作被中断唤醒，需要重新读 / 写
			{
				continue;
			}
			if (errno == EAGAIN) // 现在没有数据可读请稍后再试
			{
				continue;
			}
			fprintf(stderr, "socket : read socket error-%d-%s.\n\n", errno,strerror(errno));
			close(fd);
			break;
		}
		if (rsize == 0)
		{
			close(fd);
			printf("read socket close.\n");
			break;
		}
		rlenght += rsize;
		
		if(rlenght >= strlen(ptail))
		{
			char * ptemp = rbuffer + (rlenght - strlen(ptail));
			int ret = strcmp(ptemp, ptail);
			//printf("++++ret:%d, ptemp:%s, ptail:%s\n",ret,ptemp, ptail);
			if(ret == 0)
			{
				break;
			}
		}
	}
	
	printf("\n--------------------------\npthread_self:%ld,fd:%d, rlenght:%d, \nwbuffer:\n--------------------------\n%s\n--------------------------,\nrbuffer:\n--------------------------\n%s--------------------------\n",	pthread_self(), fd, rlenght, wbuffer, rbuffer);

	_runflag[id] = false;
	printf("pthread_self:%ld,id:%d,_runflag:%d,socket thread exit!\n",pthread_self(),id,_runflag[id]);
	return NULL;
}

// --------------------------------------------------------------------------------------------------------------------------

struct pbc_env * getpbc_env(const char * file)
{
	struct pbc_slice slice;
	read_file(file, &slice);
	if (slice.buffer == NULL)
	{
		printf("read_file:%s error\n",file);
		return NULL;
	}
	struct pbc_env * env = pbc_new();
	int ret = pbc_register(env, &slice);
	if (ret)
	{
		printf("file:%s,Error : %s\n",file, pbc_error(env));
		return NULL;
	}
	free(slice.buffer);
	return env;
}

struct pbc_wmessage * getpbc_data(struct pbc_env * env, const char *type_name)
{
	struct pbc_wmessage* w_msg = pbc_wmessage_new(env, type_name);
	return w_msg;
}


int get_loginServer_heartBeat_c2s_HeartBeat_pbc_slice(struct pbc_slice *slice)
{
	const char * file_path = "../pbs/loginServer.heartBeat.c2s.pb";
	const char * type_name = "loginServer.heartBeat.c2s.HeartBeat";

	read_file(file_path, slice);
	if (slice->buffer == NULL)
	{
		printf("file_path:%s, read_file error\n",file_path);
		return 0;
	}
	//printf("read_file - len:%d, buffer:%p\n", slice->len, slice->buffer);

	struct pbc_env * env = pbc_new();
	if(env == NULL)
	{
		printf("file_path:%s, pbc_new error\n",file_path);
		return 0;
	}
	int ret = pbc_register(env, slice);
	if (ret)
	{
		printf("file_path:%s, Error : %s\n",file_path, pbc_error(env));
		return 0;
	}
	//printf("pbc_register - len:%d, buffer:%p\n", slice->len, slice->buffer);
	
	DELETE_SLICE_BUFFFER(slice);
	
	//printf("DELETE_BUFFFER - len:%d, buffer:%p\n", slice->len, slice->buffer);

	struct pbc_wmessage* w_msg = pbc_wmessage_new(env, type_name);
	if(w_msg == NULL)
	{
		printf("read_file:%s, pbc_wmessage_new error:%s\n",file_path,pbc_error(env));
		return 0;
	}

	pbc_wmessage_buffer(w_msg, slice);
	//printf("pbc_wmessage_buffer - len:%d, buffer:%p\n", slice->len, slice->buffer);
	pbc_wmessage_delete(w_msg);
	pbc_delete(env);

	return 1;
}

int get_loginServer_heartBeat_c2s_HeartBeat_wbuffer(char * buffer,int size)
{
	struct pbc_slice slice;
	int ret = get_loginServer_heartBeat_c2s_HeartBeat_pbc_slice(&slice);
	if(!ret)
	{
		return 0;
	}
	if(slice.len + 6 > size)
	{
		return 0;
	}

	unsigned int uProtoNo = 0x000000;
	unsigned short pack_size = 4 + slice.len;
	
	buffer[0] = (pack_size >> 8) & 0xff;
	buffer[1] = pack_size & 0xff;
	buffer[2] = 0;
	buffer[3] = (uProtoNo >> 16) & 0xff;
	buffer[4] = (uProtoNo >> 8) & 0xff;
	buffer[5] = uProtoNo & 0xff;

	memcpy(buffer + 6, slice.buffer, slice.len);
	pack_size += 2;
	
	return pack_size;
}


int get_loginServer_heartBeat_s2c_HeartBeat_rbuffer(char * pdata,int len, struct pbc_slice *slice)
{
	const char * file_path = "../pbs/loginServer.heartBeat.s2c.pb";
	const char * type_name = "loginServer.heartBeat.s2c.HeartBeat";

	read_file(file_path, slice);
	if (slice->buffer == NULL)
	{
		printf("file_path:%s, read_file error\n", file_path);
		return 0;
	}
	//printf("read_file - len:%d, buffer:%p\n", slice->len, slice->buffer);

	struct pbc_env * env = pbc_new();
	if (env == NULL)
	{
		printf("file_path:%s, pbc_new error\n", file_path);
		return 0;
	}
	int ret = pbc_register(env, slice);
	if (ret)
	{
		printf("file_path:%s, Error : %s\n", file_path, pbc_error(env));
		return 0;
	}
	//printf("pbc_register - len:%d, buffer:%p\n", slice->len, slice->buffer);

	if (slice->len >= len)
	{
		memcpy(slice->buffer, pdata, len);
	}
	else
	{
		printf("slice_error - len%d, pdata:%p, slice_len:%d, buffer:%p\n", len, pdata, slice->len, slice->buffer);
	}

	struct pbc_rmessage * r_msg = pbc_rmessage_new(env, type_name, slice);
	if (r_msg == NULL)
	{
		printf("read_file:%s, pbc_wmessage_new error:%s\n", file_path, pbc_error(env));
		return 0;
	}
	//printf("pbc_wmessage_buffer - len:%d, buffer:%p\n", slice->len, slice->buffer);
	pbc_delete(env);
	DELETE_SLICE_BUFFFER(slice);

	return 1;
}


static void * thread_gate_socket(void *p)
{
	struct tagparam_gate * s = p;

	int id = s->id;
	int fd = socket_connect(IPADDRESS, 3001);

	while (true)
	{
		int wlenght = 0;
		char wbuffer[16384] = { 0 };
		unsigned short pack_size = get_loginServer_heartBeat_c2s_HeartBeat_wbuffer(wbuffer, 512);
		//printf("%s fd:%d,pid:%ld,pack_size:%d,wbuffer:-\n%s\n-\n", getStrTime(), fd, pthread_self(), pack_size, wbuffer);
		if (pack_size == 0)
		{
			printf("fd:%d,pid:%ld,get_loginServer_HeartBeat_c2s_HeartBeat_wbuffer error!\n", fd, pthread_self());
			goto exit_thread_gate;
		}
		while (true)
		{
			int send_size = write(fd, wbuffer + wlenght, pack_size - wlenght);
			if (send_size != pack_size)
			{
				printf("send buf error\n");
			}
			wlenght += send_size;
			if (wlenght == pack_size)
			{
				break;
			}
		}

		static const int max_read_szie = 65535;
		char rbuffer[max_read_szie];
		memset(rbuffer, 0, max_read_szie);

		int  rlenght = 0;
		while (true)
		{
			ms_sleep(3);
			int rsize = read(fd, rbuffer + rlenght, sizeof(rbuffer) - rlenght);
			//printf("read function - pthread_self:%ld,rsize:%d,errno:%d,EINTR:%d,EAGAIN:%d\n",pthread_self(),rsize,errno,EINTR,EAGAIN);
			if (rsize < 0)
			{
				if (errno == EINTR)
				{
					continue;
				}
				if (errno == EAGAIN)
				{
					continue;
				}
				fprintf(stderr, "socket : read socket error-%d-%s.\n\n", errno, strerror(errno));
				goto exit_thread_gate;
			}
			if (rsize == 0)
			{
				printf("read socket close.\n");
				goto exit_thread_gate;
			}
			rlenght += rsize;

			// 解包
			if (rlenght >= 2)
			{
				unsigned char tempbuf[2] = { 0 };
				tempbuf[0] = rbuffer[0];
				tempbuf[1] = rbuffer[1];
				int plenght = (int)tempbuf[0] << 8 | (int)tempbuf[1];
				if (plenght < 4 || plenght > max_read_szie)
				{
					printf("packet error lenght.\n");
					goto exit_thread_gate;
				}
				int alenght = plenght + 2;
				if (rlenght >= alenght)
				{
					unsigned int uProtoNo = ((unsigned char)rbuffer[3] << 16) | ((unsigned char)rbuffer[4] << 8) | (unsigned char)rbuffer[5];
					char * pdata = rbuffer + 6;
					int len = rlenght - 6;
					struct pbc_slice slice;
					int ret = get_loginServer_heartBeat_s2c_HeartBeat_rbuffer(pdata, len, &slice);
					printf("read - alenght:%d,uProtoNo:0x%06d,pdata:%p,ret:%d\n", alenght, uProtoNo, pdata, ret);
					break;
				}
			}
		}

		ms_sleep(3000);
	}
	
	//printf("\n--------------------------\npthread_self:%ld,fd:%d, rlenght:%d, \nwbuffer:\n--------------------------\n%s\n--------------------------,\nrbuffer:\n--------------------------\n%s--------------------------\n",pthread_self(), fd, rlenght, wbuffer, rbuffer);


exit_thread_gate:
	close(fd);
	_runflag[id] = false;
	printf("pthread_self:%ld,id:%d,_runflag:%d,socket thread exit!\n",pthread_self(),id,_runflag[id]);
	return NULL;
}

// --------------------------------------------------------------------------------------------------------------------------

int main(int argc, char const *argv[])
{
	for(int i=0; i<threadcount; i++)
	{
		_runflag[i] = false;
	}
	struct sigaction sa;
	sa.sa_handler = SIG_IGN;
	sigaction(SIGPIPE, &sa, 0);

	GenCoreDumpFile((uint32_t)(1024UL * 1024 * 1024 * 2));
	//pid_t main_pid = getpid();	
	//printf("pid:%d\n", main_pid);

	int postcount = 0;
	int ithread=0;
	int argindex = 0;
/*
	int count = 0;	
	char * param[1024] = { 0 };

	//http://127.0.0.1:3002/interface/type=onlineQuery&uidlist=12345,67890
	param[count++] = "interface";
	param[count++] = "type=onlineQuery&uidlist=12345,67890";

	param[count++] = "interface";
	param[count++] = "type=ping";
	
	param[count++] = "interface";
	param[count++] = "type=onlineView";

	param[count++] = "uniformpay";
	param[count++] = "appid=355&serverid=954&ts=1550913857&sign=9710fe234bf0ad65ca9d38cd91a9fa86&event={\"test\":\"hello world\"}";

	param[count++] = "uniformother";
	param[count++] = "appid=355&serverid=954&ts=1550913857&sign=9710fe234bf0ad65ca9d38cd91a9fa86&event={\"test\":\"hello world\"}";

	postcount += 5;

	int index = 0;
	struct tagparam_http arg_http[5];	
	for(; ithread < postcount; ithread++)
	{
		if(_runflag[ithread])
		{
			continue;
		}
		_runflag[ithread] = true;
		pthread_t pid;
		arg_http[argindex].id = ithread;
		arg_http[argindex].api = param[index++];
		arg_http[argindex].body = param[index++];
		create_thread(&pid, thread_http_socket, &arg_http[argindex]);
		//printf("i:%d, main_pid:%d, pid:%ld,api:%s,body:%s\n", ithread, getpid(), pid,arg_http[argindex].api, arg_http[argindex].body);
		argindex++;
	}

	ms_sleep(1000);


	//const char * ptail = "TELNET_OK";
	//char * py = "0000001aTELNET_OK";
	//printf("++++strlen(py):%d,strlen(ptail):%d,py:%s\n",strlen(py),strlen(ptail),py + (strlen(py) - strlen(ptail)));


	param[count++] = "help\n";	
	param[count++] = "list\n";
	param[count++] = "stat\n";
	param[count++] = "info :00000004\n";
	param[count++] = "exit :0000000d\n";
	param[count++] = "mem\n";
	param[count++] = "gc\n";
	param[count++] = "service\n";
	param[count++] = "task :0000000e\n";
	param[count++] = "cmem\n";
	param[count++] = "shrtbl\n";	
	//param[count++] = "shutdown\n";

	postcount += 11;
	struct tagparam_telnet arg_telnet[11];
	argindex = 0;
	for(; ithread < postcount; ithread++)
	{
		if(_runflag[ithread])
		{
			continue;
		}
		_runflag[ithread] = true;
		pthread_t pid;
		arg_telnet[argindex].id = ithread;
		arg_telnet[argindex].data = param[index++];
		create_thread(&pid, thread_telnet_socket, &arg_telnet[argindex]);
		printf("i:%d, main_pid:%d, pid:%ld,data:%s\n", ithread, getpid(), pid,arg_telnet[argindex].data);
		argindex++;
	}

	ms_sleep(1000);
*/
	postcount += 1;
	struct tagparam_gate arg_gate[1];
	argindex = 0;
	for(; ithread < postcount; ithread++)
	{
		if(_runflag[ithread])
		{
			continue;
		}
		_runflag[ithread] = true;
		pthread_t pid;
		arg_gate[argindex].id = ithread;
		create_thread(&pid, thread_gate_socket, &arg_gate[argindex]);
		printf("i:%d, main_pid:%d, pid:%ld\n", ithread, getpid(), pid);
		argindex++;
	}


	while (true)
	{
		bool brun = false;
		for(int i=0; i<threadcount; i++)
		{
			if(_runflag[i])
			{
				//printf("threadcount - i:%d\n",i);
				brun = true;
				break;
			}
		}
		if(brun)
		{
			ms_sleep(300);
		}
		else
		{
			printf("all thread is exit!\n");
			break;
		}
	}
	printf("main thread exit!\n");
}



