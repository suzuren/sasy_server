#include <pthread.h>
#include <unistd.h>
#include <sys/file.h>
#include <sys/resource.h>

#include "select.h"

#include "packetmacro.h"

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
	char * pdata = NULL;
	int ldata = 0;
	for (;;)
	{
		char rbuffer[65535] = { 0 };
		int rsize = read(client_fd, rbuffer, sizeof(rbuffer));
		if (rsize<0)
		{
			if (errno == EINTR)
			{
				continue;
			}
			fprintf(stderr, "socket : read socket error:%s.\n", strerror(errno));
			break;
		}
		if (rsize == 0)
		{
			_runflag = false;
			close(client_fd);
			printf("read socket close.\n");
			break;
		}
		char * ptemp = pdata;
		pdata = malloc(sizeof(char) * rsize + ldata);
		
		if(ldata>0)
		{
			memcpy(pdata, ptemp, ldata);
			memcpy(pdata + ldata, rbuffer, rsize);
		}
		else
		{
			memcpy(pdata, rbuffer, rsize);
		}
		ldata += rsize;
		struct packet_data * ppack = (struct packet_data *)pdata;
		if(ptemp)
		{
			free(ptemp);
			ptemp = NULL;
		}
		if(ldata >= sizeof(struct packet_header) )
		{
			
			if(ldata - sizeof(struct packet_header) >= ppack->header.len)
			{
				printf("client_fd:%d,rsize:%d,uin:%d,cmd:%d,len:%d,buf:%s\n", client_fd, rsize, ppack->header.uin, ppack->header.cmd, ppack->header.len, ppack->buf);
				int pack_size = sizeof(struct packet_header) + ppack->header.len;
				ldata -= pack_size;
				if(ldata == 0)
				{
					free(pdata);
					pdata = NULL;
				}
				else
				{
					ptemp = pdata;
					pdata = malloc(ldata);
					memcpy(pdata, ptemp+pack_size, ldata);
					free(ptemp);
					ptemp = NULL;
				}
			}
		}
	}
	printf("socket thread exit!\n");
	return NULL;
}

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
	struct packet_data data;
	memset(&data, 0, sizeof(data));
	while (1)
	{
		if(!_runflag)
		{
			break;
		}
		data.header.uin = main_pid;
		data.header.cmd++;
		memset(data.buf, 0, sizeof(data.buf));
		sprintf(data.buf, "%s %d\n", "hello world", iCount++);

		data.header.len = strlen(data.buf);
		int size_pack = sizeof(PACKETHEADER) + data.header.len;

		int size_send = write(client_fd, &data, size_pack);
		if (size_send != size_pack)
		{
			printf("send buf error\n");
		}

		printf("%s size_pack:%d,size_send:%d,uid:%d,cmd:%d,buf:%s\n", getStrTime(), size_pack, size_send, data.header.uin, data.header.cmd,data.buf);

		ms_sleep(300);
	}
	printf("main thread exit!\n");
}



