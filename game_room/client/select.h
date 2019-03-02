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
#include <ctype.h>

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
			/*
			int flags = 1;
			if (fcntl(client_fd, F_SETFL, flags) < 0)
			{
				//错误处理
				printf("4 connect failed\n");

				return -1;
			}
			*/
			//下面是连接成功后要执行的代码
			//printf("connect success 2\n");
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


#define NANOSEC 1000000000
#define MICROSEC 1000000

unsigned long long get_millisecond()
{
	struct timespec ti;
	clock_gettime(CLOCK_MONOTONIC, &ti);
	unsigned long long millisecond = ti.tv_sec * 1000 + ti.tv_nsec / 1000 / 1000;
	return millisecond;
}

void ms_sleep(unsigned int msec)
{
	struct timespec tm;
	tm.tv_sec = msec / 1000;
	tm.tv_nsec = msec % 1000 * 1000000;
	nanosleep(&tm, 0);
}


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
	//static char buffer[1024];
	int size = 512 + 8192;
	char * buffer = malloc(size);
	memset(buffer, 0, size);
	strcat(buffer, "POST /");strcat(buffer, api);strcat(buffer, " HTTP/1.1\r\n");
	strcat(buffer, "Host: 127.0.0.1:3002\r\n");
	strcat(buffer, "Content-Type: application/x-www-form-urlencoded\r\n");
	strcat(buffer, "Content-Length: ");	strcat(buffer, itoa_parser(strlen(body), 10));	strcat(buffer, "\r\n");
	strcat(buffer, "Connection: Keep-Alive\r\n\r\n");
	strcat(buffer, body);
	return buffer;
}

void string_table(const char *W, int * parr, int len)
{
	int pos = 2;
	int cnd = 0;
	parr[0] = -1;
	parr[1] = 0;
	while (pos < len)
	{
		if (W[pos - 1] == W[cnd])
		{
			cnd++;
			parr[pos] = cnd;
			pos++;
		}
		else if (cnd >0)
		{
			cnd = parr[cnd];
		}
		else
		{
			parr[pos] = 0;
			pos++;
		}
	}
}


int string_search(const char * psrc, int len_s, const char * pdes, int len_d)
{
	if (psrc == NULL || pdes == NULL || len_s < 2 || len_d < 2)
	{
		return -1;
	}
	int len_src = len_s;
	int len_des = len_d;

	int m = 0;
	int i = 0;
	int arr[len_des];

	string_table(pdes, arr, len_des);

	while (m + i < len_src)
	{
		if (pdes[i] == psrc[m + i])
		{
			if (i == len_des - 1)
			{
				return m;
			}
			i++;
		}
		else
		{
			m = m + i - arr[i];
			if (arr[i] > -1)
			{
				i = arr[i];
			}
			else
			{
				i = 0;
			}
		}
	}
	return -1;
}


int get_http_response_body(char * pdata, int len_data, char *pbuff, int len_buff,int * len_http_data)
{
	int len_body = -1;
	char *pLineFeed = (char *)"\r\n\r\n";
	int len_line_feed = (int)strlen(pLineFeed);
	int pos_line_feed = string_search(pdata, len_data, pLineFeed, len_line_feed);
	// all head data pack
	if (pos_line_feed > 0)
	{
		char *pContent = (char *)"content-length: ";
		int len_content = (int)strlen(pContent);
		int pos_content = string_search(pdata, len_data, pContent, len_content);
		if (pos_content > 0)
		{
			char * pLenght = pdata + pos_content + len_content;
			int index = 0;
			char ltemp[8] = { 0 };
			bool bbody_flag = true;
			while (true)
			{
				if ((pLenght + index) != NULL)
				{
					char ch = (*(pLenght + index));
					if (isdigit(ch))
					{
						ltemp[index] = ch;
						index++;
					}
					else
					{
						break;
					}
					if (pos_content + len_content + index >= len_data)
					{
						bbody_flag = false;
						break;
					}
					if (index == 8)
					{
						bbody_flag = false;
						break;
					}
				}
				else
				{
					bbody_flag = false;
				}
			}
			int len_temp = atoi(ltemp);
			if (bbody_flag && len_temp > 0)
			{
				int len_src_body = len_data - (pos_line_feed + len_line_feed);
				int pos_body_start = pos_line_feed + len_line_feed;

				if (pos_line_feed > 0 && len_src_body == len_temp && pos_body_start + len_src_body == len_data)
				{
					len_body = len_temp;
					*len_http_data = pos_body_start + len_temp;
					if (len_buff >= len_temp)
					{
						memcpy(pbuff, pdata + pos_body_start, len_temp);
					}
					else
					{
						len_body = 0;
					}
					
				}
			}
		}
	}
	return len_body;
}


static void create_thread(pthread_t *thread, void *(*start_routine) (void *), void *arg)
{
	if (pthread_create(thread, NULL, start_routine, arg))
	{
		fprintf(stderr, "Create thread failed");
		exit(1);
	}
}


#define DELETE_SLICE_BUFFFER(slice)\
    do \
    { \
		if(slice != NULL && slice->buffer != NULL)\
		{ \
			free(slice->buffer); \
			slice->buffer = NULL; \
		} \
		slice->len = 0; \
    } while(0);


#define DELETE_SLICE_STRUCT(slice)\
    do \
    { \
		if(slice.buffer != NULL)\
		{ \
			free(slice.buffer); \
			slice.buffer = NULL; \
		} \
		slice.len = 0; \
    } while(0);


