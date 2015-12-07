#include "ns.h"

extern union Nsipc nsipcbuf;

void
input(envid_t ns_envid)
{
	binaryname = "ns_input";
	
	// LAB 6: Your code here:
	// 	- read a packet from the device driver
	//	- send it to the network server
	// Hint: When you IPC a page to the network server, it will be
	// reading from it for a while, so don't immediately receive
	// another packet in to the same physical page.

	#define REC_BUFFER_SIZE 2048
	char buf[REC_BUFFER_SIZE];
	int len,r;
	len=REC_BUFFER_SIZE -1;
	while(1){
		//cprintf("Input helper env running\n");
		while( (r=sys_env_e1000_packet_rx(buf,&len) ) < 0 )
		    sys_yield();
	// Whenever a new page is allocated, old will be deallocated
	// by page_insert automatically.
		while ((r = sys_page_alloc(0, &nsipcbuf, PTE_P|PTE_U|PTE_W)) < 0);
		  
	nsipcbuf.pkt.jp_len =len;
	memcpy(nsipcbuf.pkt.jp_data,buf,len);	
	ipc_send(ns_envid,NSREQ_INPUT,&nsipcbuf, PTE_P|PTE_U|PTE_W);
	//while ((r = sys_ipc_try_send(ns_envid, NSREQ_INPUT, &nsipcbuf, PTE_P|PTE_U|PTE_W)) < 0);
	}
}
