
#ifndef __PACKET_MACRO_H_
#define __PACKET_MACRO_H_

#pragma  pack(1)

typedef struct packet_header
{
    int       uin;
	int       cmd;
	int       len;   //消息数据长度(不包括包头)
}PACKETHEADER;


typedef struct packet_data
{
	PACKETHEADER header;
	char      buf[2048];
}PACKETDATA;

#pragma pack()


#endif

