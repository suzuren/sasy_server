#include <pthread.h>
#include <unistd.h>
#include <sys/file.h>
#include <sys/resource.h>

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


int GenCoreDumpFile(size_t size)
{
	struct rlimit flimit;
	flimit.rlim_cur = size;
	flimit.rlim_max = size;
	if (setrlimit(RLIMIT_CORE, &flimit) != 0)
	{
		return errno;
	}
	return 0;
}

static bool _runflag = true;

static void create_thread(pthread_t *thread, void *(*start_routine) (void *), void *arg)
{
	if (pthread_create(thread, NULL, start_routine, arg))
	{
		fprintf(stderr, "Create thread failed");
		exit(1);
	}
}

struct sockarg
{
	int fd;
};

static void * thread_socket(void *p)
{
	struct sockarg * s = p;	
	int client_fd = s->fd;
	char rbuffer[16384 * 5] = { 0 };
	int  rlenght = 0;
	for (;;)
	{
		ms_sleep(3);
		int rsize = read(client_fd, rbuffer + rlenght, sizeof(rbuffer) - rlenght);
		if (rsize<0)
		{
			if (errno == EINTR)
			{
				continue;
			}
			fprintf(stderr, "socket : read socket error:%s.\n", strerror(errno));
			close(client_fd);
			break;
		}
		if (rsize == 0)
		{
			_runflag = false;
			close(client_fd);
			printf("read socket close.\n");
			break;
		}
		rlenght += rsize;
		struct packet_data * phead = (struct packet_data *)rbuffer;
		while(rlenght >= sizeof(struct packet_header))
		{
			if(rlenght - sizeof(struct packet_header) >= phead->header.len)
			{
				int pack_size = sizeof(struct packet_header) + phead->header.len;
				char tbuffer[16384] = { 0 };
				memcpy(tbuffer, rbuffer, pack_size);
				struct packet_data * pdata = (struct packet_data *)tbuffer;
				printf("client_fd:%d,rlenght:%d,pack_size:%d,uin:%d,cmd:%d,len:%d,buf:%s\n", client_fd,rlenght, pack_size, pdata->header.uin, pdata->header.cmd, pdata->header.len, pdata->buf);
				rlenght -= pack_size;
				memmove(rbuffer, rbuffer + pack_size, rlenght);
			}
		}
	}
	printf("socket thread exit!\n");
	return NULL;
}

char* itoa_parser(int num, int radix)
{
	static char str[32];
	memset(str, 0, sizeof(str));
	static char index[17] = "0123456789ABCDEF";
	unsigned unum;
	int i = 0, j, k;
	if (radix == 10 && num < 0)
	{
		unum = (unsigned)-num;
		str[i++] = '-';
	}
	else
	{
		unum = (unsigned)num;
	}
	do
	{
		str[i++] = index[unum % (unsigned)radix];
		unum /= radix;
	} while (unum);
	str[i] = '\0';
	if (str[0] == '-')
	{
		k = 1;
	}
	else
	{
		k = 0;
	}
	char temp;
	for (j = k; j <= (i - 1) / 2; j++)
	{
		temp = str[j];
		str[j] = str[i - 1 + k - j];
		str[i - 1 + k - j] = temp;
	}
	return str;
}


char * http_build_post_head(const char * api,const char * body)
{
	static char buffer[1024];
	memset(buffer, 0, sizeof(buffer));
	strcat(buffer, "POST /pokebot/");strcat(buffer, api);strcat(buffer, " HTTP/1.1\r\n");
	strcat(buffer, "Host: 127.0.0.1:3002\r\n");
	strcat(buffer, "Content-Type: application/x-www-form-urlencoded\r\n");
	strcat(buffer, "Content-Length: ");	strcat(buffer, itoa_parser(strlen(body), 10));	strcat(buffer, "\r\n");
	strcat(buffer, "Connection: Keep-Alive\r\n\r\n");
	strcat(buffer, body);
	return buffer;
}

#define IPADDRESS "127.0.0.1"
#define PORT 3002

int main(int argc, char const *argv[])
{
	GenCoreDumpFile((uint32_t)(1024UL * 1024 * 1024 * 2));
	int client_fd = socket_connect(IPADDRESS, PORT);
	pid_t main_pid = getpid();
	_runflag = true;
	printf("socket_connect pid:%d,client_fd:%d\n", main_pid, client_fd);
	pthread_t pid;
	struct sockarg arg;
	arg.fd = client_fd;
	create_thread(&pid, thread_socket, &arg);

	int iCount = 0;
	char wbuffer[10846];
	memset(wbuffer, 0, sizeof(wbuffer));
	while (1)
	{
		if(!_runflag)
		{
			break;
		}
		memset(wbuffer, 0, sizeof(wbuffer));
		const char * papi = "register";
		const char * pbody = "mac_address=FC-AA-14-D3-A4-E7";
		char * phead = http_build_post_head(papi, pbody);
		int size_pack = strlen(phead);
		memcpy(wbuffer, phead, size_pack);

		int size_send = write(client_fd, wbuffer, size_pack);
		if (size_send != size_pack)
		{
			printf("send buf error\n");
			break;
		}

		printf("%s iCount:%d,size_pack:%d,size_send:%d,size_pack:%d,wbuffer:-\n%s\n-\n", getStrTime(), iCount++, size_pack, size_send, size_pack, wbuffer);

		ms_sleep(3000);
	}
	printf("main thread exit!\n");
}



