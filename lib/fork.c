// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	pte_t fault_pte; 
	fault_pte = uvpt[PGNUM(addr)];
	if ( !(err & FEC_WR) || !(fault_pte & PTE_COW) )
	    panic("Invalid access to a page in lib/fork.c \n");
	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
        // LAB 4: Your code here.
	
	//allocate a new map and map it a temp location PFTEMP

	if ((r=sys_page_alloc(0, (void *)PFTEMP, \
							PTE_P|PTE_U|PTE_W)) <0)
	    panic("sys_page_alloc:%e in lib/fork.c \n",r);

	//copy data from old page to new page
	addr = ROUNDDOWN(addr,PGSIZE);
	memmove(PFTEMP,addr,PGSIZE);

	//move new page 
	
	if ((r=sys_page_map(0, (void *)PFTEMP,\
		      0, addr ,PTE_P|PTE_U|PTE_W ) ) < 0 )
	    panic("sys_page_map:%e in lib/fork.c \n",r);

	if ((r = sys_page_unmap(0, (void*)PFTEMP)) < 0)
		panic("sys_page_unmap: %e", r);
	//panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	pte_t pte;

	// LAB 4: Your code here.
	//panic("duppage not implemented");
	pte =uvpt[pn];
	uint32_t va = pn * PGSIZE ; // equivalent to ( pn << PGSHIFT)

	// Check if the va is not from userspace
	if ( va > UTOP){ 
	    panic("Invalid memory address \n");
	    //return -E_INVAL;
	}

	//Check if va address is from exception stack
	if ( ( (va < UXSTACKTOP) && ( va >=(UXSTACKTOP-PGSIZE) ) )){
	   panic("Cannot map address from exception stack \n");
	   //return -E_INVAL;
	}
	//Check if page is present 
	if ( (pte & PTE_P) ){
   
	// Check if PTE_SHARE is set.
	    if (pte & PTE_SHARE) {
	// Set new mapping as PTE_SHARE	 
	        if ( (r=sys_page_map(0, (void *)va,envid,(void*)va, (pte & PTE_SYSCALL)) ) < 0 )
	            panic("duppage MAP COW error, sys_page_map:%e in lib/fork.c \n",r);
 	             	
	        
	    }//Check permissions of pte is write or copy-on-write
	    else if ( ((pte & PTE_W) || (pte & PTE_COW)) ){ // mapping must be marked copy-on-write
	      // Set new mapping as copy-on-write	 
	         if ( (r=sys_page_map(0, (void *)va,envid,(void*)va, PTE_COW|PTE_U|PTE_P) ) < 0 )
	             panic("duppage MAP COW error, sys_page_map:%e in lib/fork.c \n",r);
 	           	
	        //our mapping of page must also be remarked as copy-on-write.
	         if ( (r=sys_page_map(0, (void *)va,0,(void*)va, PTE_COW|PTE_U|PTE_P) ) < 0 )
	             panic("duppage remmap error,sys_page_map:%e in lib/fork.c \n",r);	             
	    }
	    else {
	//No PTE_W or PTE_COW on pte,so map new page with same permissions as old page.
	        if ( (r=sys_page_map(0,(void *)va,envid,(void*)(va), pte & PTE_U ) )<0)
	            panic(" duppage MAP Read Only error, sys_page_map:%e in lib/fork.c \n",r);
	         
	     }
	
	}	
	return 0;

}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{	
	// LAB 4: Your code here.
	//panic("fork not implemented");
	
	envid_t envid;
	uint32_t pgdir;
	uint32_t pgt;
	unsigned pgno;
	int r;
	

	//The parent installs pgfault() as the C-level page fault handler, 
	//using the set_pgfault_handler() function.
	set_pgfault_handler(pgfault);

	//parent calls sys_exofork() to create a child environment
	envid = sys_exofork();
	
	if (envid < 0)
		panic("sys_exofork: %e", envid);
	
	if (envid == 0) {
		// We're the child.
		// The copied value of the global variable 'thisenv'
		// is no longer valid (it refers to the parent!).
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}
	//We are in the parent.

	// Map our entire address space into the child.
	//parent calls duppage for each copy-on-write and writable page
		
	for (pgdir = 0; pgdir != PDX(UTOP); pgdir++){
		if ( !(uvpd[pgdir] & PTE_P) )
		   continue;
		for (pgt = 0; pgt !=NPTENTRIES ; pgt++){
		   //construct pgno from pg dir and pte
		    pgno = (pgdir << 10) | pgt ;
		   //Do not copy user exception stack into child space  
		    if ( pgno != PGNUM(UXSTACKTOP - PGSIZE)){
	        	duppage(envid, pgno);
		    } 
		}
	}
	// setup user pg fault entry point  for child just like parent 
	if ((r = sys_env_set_pgfault_upcall(envid, \
					thisenv->env_pgfault_upcall)) < 0)
		panic("sys_env_set_pgfault_upcall: error %e\n", r);

	// Allocate a page for child user exception stack
	if ((r = sys_page_alloc(envid, (void*)(UXSTACKTOP-PGSIZE),\
						 PTE_P | PTE_U | PTE_W)) < 0)
		panic("sys_page_alloc: error %e\n", r);
	
	// Start the child environment running
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
		panic("sys_env_set_status: %e", r);
	
	return envid;	
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
