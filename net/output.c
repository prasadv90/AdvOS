#include "ns.h"

extern union Nsipc nsipcbuf;

void
output(envid_t ns_envid)
{
	binaryname = "ns_output";

	// LAB 6: Your code here:
	// 	- read a packet from the network server
	//	- send the packet to the device driver
	int32_t val;
	
	while(1){
	val = ipc_recv(NULL,&nsipcbuf,NULL); 
	if ( val !=NSREQ_OUTPUT || thisenv->env_ipc_from != ns_envid)
	    continue;
	
	   while( (val=sys_env_e1000_packet_tx(nsipcbuf.pkt.jp_data,\
					 nsipcbuf.pkt.jp_len) )!=0 );
	}

}
