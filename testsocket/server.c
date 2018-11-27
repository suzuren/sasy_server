#include "select.h"

//select 模式最大的客户端一般为1024
#define MAX_CLIENT_COUNT 1024

static void accpet_client(int *clients_fd, int *iClientCount, int listen_fd);
static void recv_client_msg(int *clients_fd, int *iClientCount, fd_set *readfds, fd_set *writefds);
static void handle_client_msg(int fd, char *buf);

int main(int argc, char const *argv[])
{
	int clients_fd[MAX_CLIENT_COUNT] = { 0 };
	memset(clients_fd, -1, sizeof(clients_fd));
	

	int listen_fd = socket_bind("0.0.0.0", PORT);

	printf("socket_bind listen_fd:%d\n", listen_fd);

	int iClientCount = 0;

	int max_fd = -1;
	fd_set readfds;
	fd_set writefds;
	fd_set exceptionfds;

	FD_ZERO(&readfds);
	FD_ZERO(&writefds);
	FD_ZERO(&exceptionfds);


	struct timeval tvalue;
	tvalue.tv_sec = 0;
	tvalue.tv_usec = 500;

	while(1)
	{
		FD_ZERO(&readfds);
		FD_SET(listen_fd, &readfds);
		max_fd = listen_fd;

		for (size_t i = 0; i < MAX_CLIENT_COUNT; ++i)
		{
			if (clients_fd[i] != -1)
			{
				FD_SET(clients_fd[i], &readfds);
				max_fd = clients_fd[i] > max_fd ? clients_fd[i] : max_fd;
			}
		}

		int nready = select(max_fd + 1, &readfds, &writefds, &exceptionfds, &tvalue);
		if (nready == -1)
		{
			printf("select error.\n");
			return 1;
		}
		else if (nready == 0)
		{
			continue;
			//select 超时
			//超时处理 
		}
		else
		{
			if (FD_ISSET(listen_fd, &readfds))
			{
				accpet_client(clients_fd, &iClientCount, listen_fd);
			}
			recv_client_msg(clients_fd, &iClientCount, &readfds, &writefds);
		}
	}
}

static void accpet_client(int *clients_fd, int *iClientCount,int listen_fd)
{
	socklen_t client_len = 0;
	struct sockaddr_in client_addr;
	memset(&client_addr, 0, sizeof(struct sockaddr_in));

	int client_fd = accept(listen_fd, (struct sockaddr *)&client_addr, &client_len);
	if (client_fd == -1)
	{
		printf("accept failed: %s.\n", strerror(errno));
		return;
	}
	else
	{
		SetSocketNonblock(client_fd);

		int i = 0;
		for (; i < MAX_CLIENT_COUNT; ++i)
		{
			if (clients_fd[i] == -1)
			{
				clients_fd[i] = client_fd;
				(*iClientCount)++;
				break;
			}
		}
		if (i == MAX_CLIENT_COUNT)
		{
			close(client_fd);
			printf("too much clients\n");
		}

		printf("new client accpeted - client_fd:%d,*iClientCount:%d\n", client_fd, (*iClientCount));
	}
}


static void recv_client_msg(int *clients_fd, int *iClientCount, fd_set *readfds, fd_set *writefds)
{
	char buf[65535] = { 0 };

	for (size_t i = 0; i < MAX_CLIENT_COUNT; ++i)
	{
		if (clients_fd[i] == -1)
		{
			continue;
		}
		else if (FD_ISSET(clients_fd[i], readfds))
		{
			int n = read(clients_fd[i], buf, 65535);
			//printf("one socket close,n:%d,client_fd:%d\n", n,clients_fd[i]);

			if (n <= 0)
			{
				FD_CLR(clients_fd[i], readfds);
				printf("one socket close,client_fd:%d\n", clients_fd[i]);
				close(clients_fd[i]);
				clients_fd[i] = -1;
				(*iClientCount)--;
				continue;
			}
			handle_client_msg(clients_fd[i], buf);
		}
	}
}


static void handle_client_msg(int fd, char *buf)
{
	assert(buf);
	int len = strlen(buf);
	printf("recv len:%d,buf:%s", len, buf);
	write(fd, buf, len);
}
