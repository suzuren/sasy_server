#include "select.h"

#include "packetmacro.h"

int main(int argc, char const *argv[])
{
	int client_fd = socket_connect(IPADDRESS, PORT);

	printf("socket_connect client_fd:%d\n", client_fd);

	int iCount = 0;
	PACKETDATA data;
	while (1)
	{
		data.header.uin = data.header.cmd;
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

		char read_buf[65535] = { 0 };
		int nread = read(client_fd, read_buf, sizeof(read_buf));
		//printf("read function - nread:%d, client_fd:%d, read_buf:%s",nread, client_fd, read_buf);
		if (nread == 0)
		{
			close(client_fd);
			printf("read buf error\n");
			break;
		}
		else if (nread < 0 && (errno == EAGAIN || errno == EWOULDBLOCK))// || errno == EINTR))
		{
			// EINTR 加上这个忽略 select 模式的服务端就会收不到read=0不知道为什么

			// EAGAIN 提示你的应用程序现在没有数据可读请稍后再试。
			// EWOULDBLOCK 用于非阻塞模式，不需要重新读或者写
			// EINTR 指操作被中断唤醒，需要重新读 / 写
			continue;
		}
		else
		{
			PACKETDATA * pdata = (PACKETDATA *)read_buf;
			printf("client_fd:%d,nread:%d,uin:%d,cmd:%d,len:%d,buf:%s\n", client_fd, nread, pdata->header.uin, pdata->header.cmd,pdata->header.len,pdata->buf);
		}
		ms_sleep(3000);
	}
}



