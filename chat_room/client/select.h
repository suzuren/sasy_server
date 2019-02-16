#include <arpa/inet.h>
#include <assert.h>
#include <errno.h>
#include <netinet/in.h>
#include <stdio.h>  // standard IO
#include <stdlib.h> //standard  libary
#include <string.h>
#include <sys/socket.h>
#include <unistd.h> //unix standard

#include <sys/select.h> // select IO multiplexing model

#include <sys/types.h>
#include <pthread.h>
#include <arpa/inet.h>
#include <sys/time.h>

#include <sys/un.h>
#include <fcntl.h>
#include <netinet/tcp.h>
#include<sys/poll.h>

#include <stdbool.h>

#define IPADDRESS "127.0.0.1"
#define PORT 8001

bool SetSocketNonblock(int fd)
{
	//下面获取套接字的标志
	int flag = fcntl(fd, F_GETFL, 0);
	if (flag < 0)
	{
		printf("fcntl F_GETFL filed.flags:%d\n", flag);
		//错误处理
		return false;
	}
	//下面设置套接字为非阻塞
	flag = fcntl(fd, F_SETFL, flag | O_NONBLOCK);
	if (flag < 0)
	{
		//错误处理
		printf("fcntl F_SETFL filed.flags:%d\n", flag);
		return false;
	}
	return true;
}

int socket_connect(const char *ip, int port)
{
	int client_fd = socket(AF_INET, SOCK_STREAM, 0);
	if (client_fd == -1)
	{
		printf("create socket filed.\n");
		exit(1);
	}

	SetSocketNonblock(client_fd);

	struct sockaddr_in server_addr;
	memset(&server_addr, 0, sizeof(struct sockaddr_in));
	server_addr.sin_family = AF_INET;
	server_addr.sin_port = htons(port);
	server_addr.sin_addr.s_addr = inet_addr(ip);
	int ret = connect(client_fd, (struct sockaddr *)&server_addr, sizeof(server_addr));
	if (ret == -1 && errno != EINPROGRESS)
	{
		printf("connect server filed\n");
		exit(1);
	}
	if (0 == ret)
	{   //如果connect()返回0则连接已建立 
		//下面恢复套接字阻塞状态 
		//if (fcntl(client_fd, F_SETFL, flags) < 0)
		//{
		//	//错误处理 
		//}

		//下面是连接成功后要执行的代码 
		printf("connect success\n");
		return client_fd;
	}


	int max_fds = client_fd;

	fd_set rdevents;
	fd_set wrevents;
	fd_set exevents;

	FD_ZERO(&rdevents);
	FD_SET(client_fd, &rdevents);  //把先前的套接字加到读集合里面 
	wrevents = rdevents;   //写集合
	exevents = rdevents;   //异常集合

	struct timeval tvalue;
	tvalue.tv_sec = 5;
	tvalue.tv_usec = 0;

	while (1)
	{
		int retcode = select(max_fds + 1, &rdevents, &wrevents, &exevents, &tvalue);
		if (retcode < 0)
		{
			//select返回错误
			//错误处理 
		}
		else if (0 == retcode)
		{
			//select 超时
			//超时处理 
		}
		else
		{
			//套接字已经准备好 
			if (!FD_ISSET(client_fd, &rdevents) && !FD_ISSET(client_fd, &wrevents))
			{
				//connect()失败，进行错处理
				printf("1 connect failed\n");
				return -1;
			}
			int err = -1;
			unsigned int len = sizeof(err);
			int ret = getsockopt(client_fd, SOL_SOCKET, SO_ERROR, &err, &len);
			if (ret < 0)
			{
				//getsockopt()失败，进行错处理
				printf("2 connect failed\n");

				return -1;
			}
			if (err != 0)
			{
				//connect()失败，进行错处理 
				printf("3 connect failed\n");

				return -1;
			}
			//到这里说明connect()正确返回 
			//下面恢复套接字阻塞状态 
			int flags = 1;
			if (fcntl(client_fd, F_SETFL, flags) < 0)
			{
				//错误处理
				printf("4 connect failed\n");

				return -1;
			}
			//下面是连接成功后要执行的代码
			printf("connect success 2\n");
			return client_fd;
		}
	}
	return -1;
}

const char* getStrTime()
{
	time_t now = time(0);
	struct tm * pTime = localtime(&now);

	static char szDate[32] = { 0 };

	sprintf(szDate, "%.4d-%.2d-%.2d %.2d:%.2d:%.2d", pTime->tm_year + 1900, pTime->tm_mon + 1, pTime->tm_mday, pTime->tm_hour, pTime->tm_min, pTime->tm_sec);

	return szDate;
}



void ms_sleep(unsigned int msec)
{
	struct timespec tm;
	tm.tv_sec = msec / 1000;
	tm.tv_nsec = msec % 1000 * 1000000;
	nanosleep(&tm, 0);
}






