#include <kern/e1000.h>


// LAB 6: Your driver code here


//Global declaration of Transmit descriptor array and buffer
struct tx_desc tx_desc_array[E1000_TX_DESCRIPTORS] __attribute__ ((aligned (16)));
struct tx_packet tx_buffer[E1000_TX_DESCRIPTORS];

//Global declaration of Receive descriptor array and buffer
struct rx_desc rx_desc_array[E1000_RX_DESCRIPTORS] __attribute__ ((aligned (16)));
struct rx_packet rx_buffer[E1000_RX_DESCRIPTORS];


int e1000_NIC_attach(struct pci_func *f){


	//Enable E1000 Network Card
 	pci_func_enable(f);
	
	//Create  virtual memory mapping for E1000
	e1000_va = mmio_map_region( (physaddr_t )f->reg_base[0],\
						(size_t )f->reg_size[0]);
	
	// test E1000 memory mapping by printing device status reg.
	cprintf("Checking virtual addr \n");
	cprintf("device status register 0x%08x \n",e1000_va[E1000_STATUS]);
	
	//Transmit Initialize
	tx_init();
	
	//Receive Initialize
	rx_init();

	return 0;
}
void tx_init(){
		uint32_t i;
/*Transmit Initialization Setup*/
	
	//Initialize buffer
	memset(tx_desc_array, 0x0, sizeof(struct tx_desc) * E1000_TX_DESCRIPTORS);
	memset(tx_buffer, 0x0, sizeof(struct tx_packet) * E1000_TX_DESCRIPTORS);
	
	for(i=0; i<E1000_TX_DESCRIPTORS;i++ ){
		tx_desc_array[i].addr = PADDR(tx_buffer[i].buffer);
	//cprintf("Buffer addr 0x%08x \n",tx_desc_array[i].addr);
		tx_desc_array[i].status |=E1000_TXD_STAT_DD ;	
	}

	/*Transmit Descriptor Base Address registers */
	e1000_va[E1000_TDBAL] = PADDR(tx_desc_array); //lower 32-bit addr
	e1000_va[E1000_TDBAH] = 0; //higher 32-bit add (only for 64bit addr space)
	e1000_va[E1000_TDLEN] = (E1000_TX_DESCRIPTORS*sizeof(struct tx_desc)) ; // desc ring len =1024
		
	//Set descriptor head and tail initialized to 0b
	e1000_va[E1000_TDH] = 0;
	e1000_va[E1000_TDT] = 0;

	//Initialize Transmit Control Reg.
	e1000_va[E1000_TCTL] |= E1000_TCTL_EN; //Enable
	e1000_va[E1000_TCTL] |= E1000_TCTL_PSP; //pad short packets.
	e1000_va[E1000_TCTL] &= ~(E1000_TCTL_CT) ; //clear Collision Thrshld val
	

	e1000_va[E1000_TCTL] |= (0x10) << 4;
	e1000_va[E1000_TCTL] &= ~E1000_TCTL_COLD;
	e1000_va[E1000_TCTL] |= (0x40) << 12;
	
	
		
	/*e1000_va[E1000_TCTL] |= 0x00000100; //CT set to 10h
 	e1000_va[E1000_TCTL] &= ~(E1000_TCTL_COLD);//clear coll dist val
	e1000_va[E1000_TCTL] |= 0x00040000 ; // set coll dist to 40h=>full duplex
 	*/
	/*TIPG,use the IEEE 802.3 standard IPG
	IPGT =10 ; IPGR1 = 4 ; IPGR2 = 6 */
	e1000_va[E1000_TIPG] = 0x0; //clear
	//e1000_va[E1000_TIPG] |= 0x0060040A;
	e1000_va[E1000_TIPG] |= (0x6) << 20; // IPGR2 
	e1000_va[E1000_TIPG] |= (0x4) << 10; // IPGR1
	e1000_va[E1000_TIPG] |= 0xA; // IPGR

	/*Testing transmit with sample data
	char sample[] ="111111111111111111111111111111111111111111111111111111";
	e1000_data_transmit(sample,sizeof(sample));
	*/

}

int e1000_data_transmit(char *data,int len){
	uint32_t td_tail;
	 	
	td_tail = e1000_va[E1000_TDT];
	//cprintf("packet len %d \n",len);
	// check packet length
	if (len > E1000_TX_BUF_SIZE)	
	    return -E_MAX_PCKT_LEN;
	
	//Check it's safe to recycle that descriptor
	if( (tx_desc_array[td_tail].status & E1000_TXD_STAT_DD) ){
	
	    memcpy(tx_buffer[td_tail].buffer,data,len); //copy data into pck buf 	
	    tx_desc_array[td_tail].length = len; //set packet len

	    tx_desc_array[td_tail].status &= ~(E1000_TXD_STAT_DD); //clear descriptor done
	    tx_desc_array[td_tail].cmd |= E1000_TXD_CMD_RS; //set report status
	    tx_desc_array[td_tail].cmd |= E1000_TXD_CMD_EOP; //indicate end of packet
		
	    e1000_va[E1000_TDT] =(td_tail+1 )%E1000_TX_DESCRIPTORS;
	}	    
	else
	    return -E_TX_DESC_QUEUE_FULL; //TX queue full, no free tx desc avail
	return 0;
}

void rx_init(){
	uint32_t i;
	//Initialize buffer
	memset(rx_desc_array, 0x0, sizeof(struct rx_desc) * E1000_RX_DESCRIPTORS);
	memset(rx_buffer, 0x0, sizeof(struct rx_packet) * E1000_RX_DESCRIPTORS);

	for(i=0; i<E1000_RX_DESCRIPTORS;i++ ){
		rx_desc_array[i].buffer_addr = PADDR(rx_buffer[i].buffer);
		//rx_desc_array[i].status &= ~E1000_RXD_STAT_DD;
	}
	
	e1000_va[E1000_MTA] = 0; //Initialize MTA to 0b
	
        //Program (RAL/RAH) with the desired Ethernet MAC addresses.
	
	e1000_va[E1000_RA_RAL] |= 0x12005452;  //52:54:00:12
 	e1000_va[E1000_RA_RAH] |= 0x5634;  //34:56
	e1000_va[E1000_RA_RAH] |= E1000_RAH_AV;  //Enable Address Valid

	/*Recieve Descriptor Base Address registers */	
	e1000_va[E1000_RDBAL] = PADDR(rx_desc_array);     
	e1000_va[E1000_RDBAH] = 0;
	e1000_va[E1000_RDLEN] = sizeof(struct rx_desc) * E1000_RX_DESCRIPTORS ;
	
	// Set the Receive Descriptor Head and Tail Registers
	e1000_va[E1000_RDH] = 0;
	//e1000_va[E1000_RDT] = 0;
	e1000_va[E1000_RDT] = E1000_RX_DESCRIPTORS -1;
	
	/*Receive Control (RCTL) register*/
	e1000_va[E1000_RCTL] =0;
	e1000_va[E1000_RCTL] |= E1000_RCTL_EN ;  //Enable receive
	e1000_va[E1000_RCTL] &= ~E1000_RCTL_LPE; //disable long packet
	e1000_va[E1000_RCTL] |= E1000_RCTL_LBM_NO ; //no loopback mode
 	e1000_va[E1000_RCTL] |= E1000_RCTL_SZ_2048 ; //buffer size 2048bytes
	e1000_va[E1000_RCTL] &= ~E1000_RCTL_BSEX ;  //no size extension
	e1000_va[E1000_RCTL] |= E1000_RCTL_BAM ; // receive broadcast msgs	
	e1000_va[E1000_RCTL] |= E1000_RCTL_SECRC;  //Strip CRC from incoming packet
	e1000_va[E1000_RCTL] |= E1000_RCTL_RDMTS_HALF;
	e1000_va[E1000_RCTL] |= E1000_RCTL_MO_0;

}


int e1000_data_receive(char *data){

	uint32_t rd_tail;
	uint32_t rd_head;
	 	
	rd_tail = e1000_va[E1000_RDT];
	rd_head = e1000_va[E1000_RDH];
	rd_tail = (rd_tail+1)%E1000_RX_DESCRIPTORS ;
	//cprintf("Head is at %d\n",rd_head);
	//cprintf("Tail is at %d\n",rd_tail);
	if( rx_desc_array[rd_tail].status & E1000_RXD_STAT_DD){

	    if (!(rx_desc_array[rd_tail].status & E1000_RXD_STAT_EOP)) {
			panic("Don't allow extended frames!\n");
		}
	    cprintf("receive function executed\n");	
	    memcpy(data,rx_buffer[rd_tail].buffer,rx_desc_array[rd_tail].length );
	    rx_desc_array[rd_tail].status &= ~E1000_RXD_STAT_DD;
	    rx_desc_array[rd_tail].status &= ~E1000_RXD_STAT_EOP;
	    e1000_va[E1000_RDT] = (rd_tail);
	    return rx_desc_array[rd_tail].length;	
	}	
	else
	    return -E_RX_EMPTY; // receive buffer empty

}
