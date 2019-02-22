#include <pthread.h>
#include <unistd.h>
#include <sys/file.h>
#include <sys/resource.h>
#include <unistd.h>
#include <signal.h>
#include "select.h"


#pragma  pack(1)

struct packet_header
{
    int       uin;
	int       cmd;
	int       len;   //消息数据长度(不包括包头)
};


struct packet_data
{
	struct packet_header header;
	char      buf[2048];
};

#pragma pack()

#define threadcount 1024
static bool _runflag[threadcount];


#define IPADDRESS "127.0.0.1"
#define PORT 3002

static void create_thread(pthread_t *thread, void *(*start_routine) (void *), void *arg)
{
	if (pthread_create(thread, NULL, start_routine, arg))
	{
		fprintf(stderr, "Create thread failed");
		exit(1);
	}
}

struct tagparam
{
	int id;
	char * api;
	char * body; 
};

static void * thread_socket(void *p)
{
	struct tagparam * s = p;
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

	while(true)
	{
		int size_send = write(fd, wbuffer, size_pack);

		if (size_send != size_pack)
		{
			printf("send buf error\n");
			break;
		}

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
		//printf("read function - pthread_self:%ld,rsize:%d,errno:%d,EINTR:%d\n",pthread_self(),rsize,errno,EINTR);
		if (rsize<0)
		{
			if (errno == EINTR)
			{
				continue;
			}
			fprintf(stderr, "socket : read socket error:%s.\n", strerror(errno));
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
		printf("pthread_self:%ld,fd:%d, rlenght:%d, rsize:%d, \nrbuffer:\n--------------------------\n%s\n--------------------------\n",\
			pthread_self(), fd, rlenght, rsize, rbuffer);
	}
	_runflag[id] = false;
	printf("pthread_self:%ld,id:%d,_runflag:%d,socket thread exit!\n",pthread_self(),id,_runflag[id]);
	return NULL;
}

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
	pid_t main_pid = getpid();
	
	printf("pid:%d\n", main_pid);

	int count = 0;	
	char * param[1024] = { 0 };

	param[count++] = "interface";
	param[count++] = "type=ping";
	
	param[count++] = "interface";
	param[count++] = "type=onlineView";

	int index = 0;
	struct tagparam arg[2];
	for(int i=0; i<2; i ++)
	{
		if(_runflag[i])
		{
			continue;
		}
		_runflag[i] = true;
		pthread_t pid;
		arg[i].id = i;
		arg[i].api = param[index++];
		arg[i].body = param[index++];
		create_thread(&pid, thread_socket, &arg[i]);
		//printf("i:%d, main_pid:%d, pid:%ld,api:%s,body:%s\n", i, main_pid, pid,arg[i].api, arg[i].body);
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



