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
	//char * pdata = NULL;
	//int ldata = 0;
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
		if(data.header.cmd == 0x7FFFFFFF)
		{
			data.header.cmd = 0;
		}
		data.header.cmd++;

		memset(data.buf, 0, sizeof(data.buf));
		sprintf(data.buf, "%s %d\n", "hello world", iCount++);

		data.header.len = strlen(data.buf);
		int size_pack = sizeof(struct packet_header) + data.header.len;

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



