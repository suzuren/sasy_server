
#ifndef __PACKET_MACRO_H_
#define __PACKET_MACRO_H_

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


#endif

