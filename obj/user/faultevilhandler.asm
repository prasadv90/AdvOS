
obj/user/faultevilhandler:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 44 00 00 00       	call   800075 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	sys_page_alloc(0, (void*) (UXSTACKTOP - PGSIZE), PTE_P|PTE_U|PTE_W);
  800039:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  800040:	00 
  800041:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  800048:	ee 
  800049:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800050:	e8 53 01 00 00       	call   8001a8 <sys_page_alloc>
	sys_env_set_pgfault_upcall(0, (void*) 0xF0100020);
  800055:	c7 44 24 04 20 00 10 	movl   $0xf0100020,0x4(%esp)
  80005c:	f0 
  80005d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800064:	e8 8c 02 00 00       	call   8002f5 <sys_env_set_pgfault_upcall>
	*(int*)0 = 0;
  800069:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
  800070:	00 00 00 
}
  800073:	c9                   	leave  
  800074:	c3                   	ret    

00800075 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800075:	55                   	push   %ebp
  800076:	89 e5                	mov    %esp,%ebp
  800078:	56                   	push   %esi
  800079:	53                   	push   %ebx
  80007a:	83 ec 10             	sub    $0x10,%esp
  80007d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800080:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800083:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  80008a:	00 00 00 
	thisenv = &envs[ENVX(sys_getenvid())]; 
  80008d:	e8 d8 00 00 00       	call   80016a <sys_getenvid>
  800092:	25 ff 03 00 00       	and    $0x3ff,%eax
  800097:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80009a:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80009f:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000a4:	85 db                	test   %ebx,%ebx
  8000a6:	7e 07                	jle    8000af <libmain+0x3a>
		binaryname = argv[0];
  8000a8:	8b 06                	mov    (%esi),%eax
  8000aa:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8000af:	89 74 24 04          	mov    %esi,0x4(%esp)
  8000b3:	89 1c 24             	mov    %ebx,(%esp)
  8000b6:	e8 78 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  8000bb:	e8 07 00 00 00       	call   8000c7 <exit>
}
  8000c0:	83 c4 10             	add    $0x10,%esp
  8000c3:	5b                   	pop    %ebx
  8000c4:	5e                   	pop    %esi
  8000c5:	5d                   	pop    %ebp
  8000c6:	c3                   	ret    

008000c7 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000c7:	55                   	push   %ebp
  8000c8:	89 e5                	mov    %esp,%ebp
  8000ca:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000d4:	e8 3f 00 00 00       	call   800118 <sys_env_destroy>
}
  8000d9:	c9                   	leave  
  8000da:	c3                   	ret    

008000db <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000db:	55                   	push   %ebp
  8000dc:	89 e5                	mov    %esp,%ebp
  8000de:	57                   	push   %edi
  8000df:	56                   	push   %esi
  8000e0:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000e1:	b8 00 00 00 00       	mov    $0x0,%eax
  8000e6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000e9:	8b 55 08             	mov    0x8(%ebp),%edx
  8000ec:	89 c3                	mov    %eax,%ebx
  8000ee:	89 c7                	mov    %eax,%edi
  8000f0:	89 c6                	mov    %eax,%esi
  8000f2:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000f4:	5b                   	pop    %ebx
  8000f5:	5e                   	pop    %esi
  8000f6:	5f                   	pop    %edi
  8000f7:	5d                   	pop    %ebp
  8000f8:	c3                   	ret    

008000f9 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000f9:	55                   	push   %ebp
  8000fa:	89 e5                	mov    %esp,%ebp
  8000fc:	57                   	push   %edi
  8000fd:	56                   	push   %esi
  8000fe:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000ff:	ba 00 00 00 00       	mov    $0x0,%edx
  800104:	b8 01 00 00 00       	mov    $0x1,%eax
  800109:	89 d1                	mov    %edx,%ecx
  80010b:	89 d3                	mov    %edx,%ebx
  80010d:	89 d7                	mov    %edx,%edi
  80010f:	89 d6                	mov    %edx,%esi
  800111:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800113:	5b                   	pop    %ebx
  800114:	5e                   	pop    %esi
  800115:	5f                   	pop    %edi
  800116:	5d                   	pop    %ebp
  800117:	c3                   	ret    

00800118 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800118:	55                   	push   %ebp
  800119:	89 e5                	mov    %esp,%ebp
  80011b:	57                   	push   %edi
  80011c:	56                   	push   %esi
  80011d:	53                   	push   %ebx
  80011e:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800121:	b9 00 00 00 00       	mov    $0x0,%ecx
  800126:	b8 03 00 00 00       	mov    $0x3,%eax
  80012b:	8b 55 08             	mov    0x8(%ebp),%edx
  80012e:	89 cb                	mov    %ecx,%ebx
  800130:	89 cf                	mov    %ecx,%edi
  800132:	89 ce                	mov    %ecx,%esi
  800134:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800136:	85 c0                	test   %eax,%eax
  800138:	7e 28                	jle    800162 <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  80013a:	89 44 24 10          	mov    %eax,0x10(%esp)
  80013e:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800145:	00 
  800146:	c7 44 24 08 ca 10 80 	movl   $0x8010ca,0x8(%esp)
  80014d:	00 
  80014e:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800155:	00 
  800156:	c7 04 24 e7 10 80 00 	movl   $0x8010e7,(%esp)
  80015d:	e8 5b 02 00 00       	call   8003bd <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800162:	83 c4 2c             	add    $0x2c,%esp
  800165:	5b                   	pop    %ebx
  800166:	5e                   	pop    %esi
  800167:	5f                   	pop    %edi
  800168:	5d                   	pop    %ebp
  800169:	c3                   	ret    

0080016a <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80016a:	55                   	push   %ebp
  80016b:	89 e5                	mov    %esp,%ebp
  80016d:	57                   	push   %edi
  80016e:	56                   	push   %esi
  80016f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800170:	ba 00 00 00 00       	mov    $0x0,%edx
  800175:	b8 02 00 00 00       	mov    $0x2,%eax
  80017a:	89 d1                	mov    %edx,%ecx
  80017c:	89 d3                	mov    %edx,%ebx
  80017e:	89 d7                	mov    %edx,%edi
  800180:	89 d6                	mov    %edx,%esi
  800182:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800184:	5b                   	pop    %ebx
  800185:	5e                   	pop    %esi
  800186:	5f                   	pop    %edi
  800187:	5d                   	pop    %ebp
  800188:	c3                   	ret    

00800189 <sys_yield>:

void
sys_yield(void)
{
  800189:	55                   	push   %ebp
  80018a:	89 e5                	mov    %esp,%ebp
  80018c:	57                   	push   %edi
  80018d:	56                   	push   %esi
  80018e:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80018f:	ba 00 00 00 00       	mov    $0x0,%edx
  800194:	b8 0a 00 00 00       	mov    $0xa,%eax
  800199:	89 d1                	mov    %edx,%ecx
  80019b:	89 d3                	mov    %edx,%ebx
  80019d:	89 d7                	mov    %edx,%edi
  80019f:	89 d6                	mov    %edx,%esi
  8001a1:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  8001a3:	5b                   	pop    %ebx
  8001a4:	5e                   	pop    %esi
  8001a5:	5f                   	pop    %edi
  8001a6:	5d                   	pop    %ebp
  8001a7:	c3                   	ret    

008001a8 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  8001a8:	55                   	push   %ebp
  8001a9:	89 e5                	mov    %esp,%ebp
  8001ab:	57                   	push   %edi
  8001ac:	56                   	push   %esi
  8001ad:	53                   	push   %ebx
  8001ae:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001b1:	be 00 00 00 00       	mov    $0x0,%esi
  8001b6:	b8 04 00 00 00       	mov    $0x4,%eax
  8001bb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8001be:	8b 55 08             	mov    0x8(%ebp),%edx
  8001c1:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001c4:	89 f7                	mov    %esi,%edi
  8001c6:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8001c8:	85 c0                	test   %eax,%eax
  8001ca:	7e 28                	jle    8001f4 <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  8001cc:	89 44 24 10          	mov    %eax,0x10(%esp)
  8001d0:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  8001d7:	00 
  8001d8:	c7 44 24 08 ca 10 80 	movl   $0x8010ca,0x8(%esp)
  8001df:	00 
  8001e0:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8001e7:	00 
  8001e8:	c7 04 24 e7 10 80 00 	movl   $0x8010e7,(%esp)
  8001ef:	e8 c9 01 00 00       	call   8003bd <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  8001f4:	83 c4 2c             	add    $0x2c,%esp
  8001f7:	5b                   	pop    %ebx
  8001f8:	5e                   	pop    %esi
  8001f9:	5f                   	pop    %edi
  8001fa:	5d                   	pop    %ebp
  8001fb:	c3                   	ret    

008001fc <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001fc:	55                   	push   %ebp
  8001fd:	89 e5                	mov    %esp,%ebp
  8001ff:	57                   	push   %edi
  800200:	56                   	push   %esi
  800201:	53                   	push   %ebx
  800202:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800205:	b8 05 00 00 00       	mov    $0x5,%eax
  80020a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80020d:	8b 55 08             	mov    0x8(%ebp),%edx
  800210:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800213:	8b 7d 14             	mov    0x14(%ebp),%edi
  800216:	8b 75 18             	mov    0x18(%ebp),%esi
  800219:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80021b:	85 c0                	test   %eax,%eax
  80021d:	7e 28                	jle    800247 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  80021f:	89 44 24 10          	mov    %eax,0x10(%esp)
  800223:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  80022a:	00 
  80022b:	c7 44 24 08 ca 10 80 	movl   $0x8010ca,0x8(%esp)
  800232:	00 
  800233:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80023a:	00 
  80023b:	c7 04 24 e7 10 80 00 	movl   $0x8010e7,(%esp)
  800242:	e8 76 01 00 00       	call   8003bd <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800247:	83 c4 2c             	add    $0x2c,%esp
  80024a:	5b                   	pop    %ebx
  80024b:	5e                   	pop    %esi
  80024c:	5f                   	pop    %edi
  80024d:	5d                   	pop    %ebp
  80024e:	c3                   	ret    

0080024f <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  80024f:	55                   	push   %ebp
  800250:	89 e5                	mov    %esp,%ebp
  800252:	57                   	push   %edi
  800253:	56                   	push   %esi
  800254:	53                   	push   %ebx
  800255:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800258:	bb 00 00 00 00       	mov    $0x0,%ebx
  80025d:	b8 06 00 00 00       	mov    $0x6,%eax
  800262:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800265:	8b 55 08             	mov    0x8(%ebp),%edx
  800268:	89 df                	mov    %ebx,%edi
  80026a:	89 de                	mov    %ebx,%esi
  80026c:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80026e:	85 c0                	test   %eax,%eax
  800270:	7e 28                	jle    80029a <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800272:	89 44 24 10          	mov    %eax,0x10(%esp)
  800276:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  80027d:	00 
  80027e:	c7 44 24 08 ca 10 80 	movl   $0x8010ca,0x8(%esp)
  800285:	00 
  800286:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80028d:	00 
  80028e:	c7 04 24 e7 10 80 00 	movl   $0x8010e7,(%esp)
  800295:	e8 23 01 00 00       	call   8003bd <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  80029a:	83 c4 2c             	add    $0x2c,%esp
  80029d:	5b                   	pop    %ebx
  80029e:	5e                   	pop    %esi
  80029f:	5f                   	pop    %edi
  8002a0:	5d                   	pop    %ebp
  8002a1:	c3                   	ret    

008002a2 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  8002a2:	55                   	push   %ebp
  8002a3:	89 e5                	mov    %esp,%ebp
  8002a5:	57                   	push   %edi
  8002a6:	56                   	push   %esi
  8002a7:	53                   	push   %ebx
  8002a8:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002ab:	bb 00 00 00 00       	mov    $0x0,%ebx
  8002b0:	b8 08 00 00 00       	mov    $0x8,%eax
  8002b5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8002b8:	8b 55 08             	mov    0x8(%ebp),%edx
  8002bb:	89 df                	mov    %ebx,%edi
  8002bd:	89 de                	mov    %ebx,%esi
  8002bf:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8002c1:	85 c0                	test   %eax,%eax
  8002c3:	7e 28                	jle    8002ed <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002c5:	89 44 24 10          	mov    %eax,0x10(%esp)
  8002c9:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  8002d0:	00 
  8002d1:	c7 44 24 08 ca 10 80 	movl   $0x8010ca,0x8(%esp)
  8002d8:	00 
  8002d9:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8002e0:	00 
  8002e1:	c7 04 24 e7 10 80 00 	movl   $0x8010e7,(%esp)
  8002e8:	e8 d0 00 00 00       	call   8003bd <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  8002ed:	83 c4 2c             	add    $0x2c,%esp
  8002f0:	5b                   	pop    %ebx
  8002f1:	5e                   	pop    %esi
  8002f2:	5f                   	pop    %edi
  8002f3:	5d                   	pop    %ebp
  8002f4:	c3                   	ret    

008002f5 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  8002f5:	55                   	push   %ebp
  8002f6:	89 e5                	mov    %esp,%ebp
  8002f8:	57                   	push   %edi
  8002f9:	56                   	push   %esi
  8002fa:	53                   	push   %ebx
  8002fb:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002fe:	bb 00 00 00 00       	mov    $0x0,%ebx
  800303:	b8 09 00 00 00       	mov    $0x9,%eax
  800308:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80030b:	8b 55 08             	mov    0x8(%ebp),%edx
  80030e:	89 df                	mov    %ebx,%edi
  800310:	89 de                	mov    %ebx,%esi
  800312:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800314:	85 c0                	test   %eax,%eax
  800316:	7e 28                	jle    800340 <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800318:	89 44 24 10          	mov    %eax,0x10(%esp)
  80031c:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800323:	00 
  800324:	c7 44 24 08 ca 10 80 	movl   $0x8010ca,0x8(%esp)
  80032b:	00 
  80032c:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800333:	00 
  800334:	c7 04 24 e7 10 80 00 	movl   $0x8010e7,(%esp)
  80033b:	e8 7d 00 00 00       	call   8003bd <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800340:	83 c4 2c             	add    $0x2c,%esp
  800343:	5b                   	pop    %ebx
  800344:	5e                   	pop    %esi
  800345:	5f                   	pop    %edi
  800346:	5d                   	pop    %ebp
  800347:	c3                   	ret    

00800348 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800348:	55                   	push   %ebp
  800349:	89 e5                	mov    %esp,%ebp
  80034b:	57                   	push   %edi
  80034c:	56                   	push   %esi
  80034d:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80034e:	be 00 00 00 00       	mov    $0x0,%esi
  800353:	b8 0b 00 00 00       	mov    $0xb,%eax
  800358:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80035b:	8b 55 08             	mov    0x8(%ebp),%edx
  80035e:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800361:	8b 7d 14             	mov    0x14(%ebp),%edi
  800364:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800366:	5b                   	pop    %ebx
  800367:	5e                   	pop    %esi
  800368:	5f                   	pop    %edi
  800369:	5d                   	pop    %ebp
  80036a:	c3                   	ret    

0080036b <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  80036b:	55                   	push   %ebp
  80036c:	89 e5                	mov    %esp,%ebp
  80036e:	57                   	push   %edi
  80036f:	56                   	push   %esi
  800370:	53                   	push   %ebx
  800371:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800374:	b9 00 00 00 00       	mov    $0x0,%ecx
  800379:	b8 0c 00 00 00       	mov    $0xc,%eax
  80037e:	8b 55 08             	mov    0x8(%ebp),%edx
  800381:	89 cb                	mov    %ecx,%ebx
  800383:	89 cf                	mov    %ecx,%edi
  800385:	89 ce                	mov    %ecx,%esi
  800387:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800389:	85 c0                	test   %eax,%eax
  80038b:	7e 28                	jle    8003b5 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  80038d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800391:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800398:	00 
  800399:	c7 44 24 08 ca 10 80 	movl   $0x8010ca,0x8(%esp)
  8003a0:	00 
  8003a1:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8003a8:	00 
  8003a9:	c7 04 24 e7 10 80 00 	movl   $0x8010e7,(%esp)
  8003b0:	e8 08 00 00 00       	call   8003bd <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  8003b5:	83 c4 2c             	add    $0x2c,%esp
  8003b8:	5b                   	pop    %ebx
  8003b9:	5e                   	pop    %esi
  8003ba:	5f                   	pop    %edi
  8003bb:	5d                   	pop    %ebp
  8003bc:	c3                   	ret    

008003bd <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8003bd:	55                   	push   %ebp
  8003be:	89 e5                	mov    %esp,%ebp
  8003c0:	56                   	push   %esi
  8003c1:	53                   	push   %ebx
  8003c2:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8003c5:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8003c8:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8003ce:	e8 97 fd ff ff       	call   80016a <sys_getenvid>
  8003d3:	8b 55 0c             	mov    0xc(%ebp),%edx
  8003d6:	89 54 24 10          	mov    %edx,0x10(%esp)
  8003da:	8b 55 08             	mov    0x8(%ebp),%edx
  8003dd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8003e1:	89 74 24 08          	mov    %esi,0x8(%esp)
  8003e5:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003e9:	c7 04 24 f8 10 80 00 	movl   $0x8010f8,(%esp)
  8003f0:	e8 c1 00 00 00       	call   8004b6 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8003f5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8003f9:	8b 45 10             	mov    0x10(%ebp),%eax
  8003fc:	89 04 24             	mov    %eax,(%esp)
  8003ff:	e8 51 00 00 00       	call   800455 <vcprintf>
	cprintf("\n");
  800404:	c7 04 24 1c 11 80 00 	movl   $0x80111c,(%esp)
  80040b:	e8 a6 00 00 00       	call   8004b6 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800410:	cc                   	int3   
  800411:	eb fd                	jmp    800410 <_panic+0x53>

00800413 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800413:	55                   	push   %ebp
  800414:	89 e5                	mov    %esp,%ebp
  800416:	53                   	push   %ebx
  800417:	83 ec 14             	sub    $0x14,%esp
  80041a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80041d:	8b 13                	mov    (%ebx),%edx
  80041f:	8d 42 01             	lea    0x1(%edx),%eax
  800422:	89 03                	mov    %eax,(%ebx)
  800424:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800427:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80042b:	3d ff 00 00 00       	cmp    $0xff,%eax
  800430:	75 19                	jne    80044b <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800432:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800439:	00 
  80043a:	8d 43 08             	lea    0x8(%ebx),%eax
  80043d:	89 04 24             	mov    %eax,(%esp)
  800440:	e8 96 fc ff ff       	call   8000db <sys_cputs>
		b->idx = 0;
  800445:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  80044b:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80044f:	83 c4 14             	add    $0x14,%esp
  800452:	5b                   	pop    %ebx
  800453:	5d                   	pop    %ebp
  800454:	c3                   	ret    

00800455 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800455:	55                   	push   %ebp
  800456:	89 e5                	mov    %esp,%ebp
  800458:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80045e:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800465:	00 00 00 
	b.cnt = 0;
  800468:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80046f:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800472:	8b 45 0c             	mov    0xc(%ebp),%eax
  800475:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800479:	8b 45 08             	mov    0x8(%ebp),%eax
  80047c:	89 44 24 08          	mov    %eax,0x8(%esp)
  800480:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800486:	89 44 24 04          	mov    %eax,0x4(%esp)
  80048a:	c7 04 24 13 04 80 00 	movl   $0x800413,(%esp)
  800491:	e8 a8 01 00 00       	call   80063e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800496:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  80049c:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004a0:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8004a6:	89 04 24             	mov    %eax,(%esp)
  8004a9:	e8 2d fc ff ff       	call   8000db <sys_cputs>

	return b.cnt;
}
  8004ae:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8004b4:	c9                   	leave  
  8004b5:	c3                   	ret    

008004b6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8004b6:	55                   	push   %ebp
  8004b7:	89 e5                	mov    %esp,%ebp
  8004b9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8004bc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8004bf:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004c3:	8b 45 08             	mov    0x8(%ebp),%eax
  8004c6:	89 04 24             	mov    %eax,(%esp)
  8004c9:	e8 87 ff ff ff       	call   800455 <vcprintf>
	va_end(ap);

	return cnt;
}
  8004ce:	c9                   	leave  
  8004cf:	c3                   	ret    

008004d0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8004d0:	55                   	push   %ebp
  8004d1:	89 e5                	mov    %esp,%ebp
  8004d3:	57                   	push   %edi
  8004d4:	56                   	push   %esi
  8004d5:	53                   	push   %ebx
  8004d6:	83 ec 3c             	sub    $0x3c,%esp
  8004d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8004dc:	89 d7                	mov    %edx,%edi
  8004de:	8b 45 08             	mov    0x8(%ebp),%eax
  8004e1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004e4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8004e7:	89 c3                	mov    %eax,%ebx
  8004e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8004ec:	8b 45 10             	mov    0x10(%ebp),%eax
  8004ef:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8004f2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8004f7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004fa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8004fd:	39 d9                	cmp    %ebx,%ecx
  8004ff:	72 05                	jb     800506 <printnum+0x36>
  800501:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800504:	77 69                	ja     80056f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800506:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800509:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80050d:	83 ee 01             	sub    $0x1,%esi
  800510:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800514:	89 44 24 08          	mov    %eax,0x8(%esp)
  800518:	8b 44 24 08          	mov    0x8(%esp),%eax
  80051c:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800520:	89 c3                	mov    %eax,%ebx
  800522:	89 d6                	mov    %edx,%esi
  800524:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800527:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80052a:	89 54 24 08          	mov    %edx,0x8(%esp)
  80052e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800532:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800535:	89 04 24             	mov    %eax,(%esp)
  800538:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80053b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80053f:	e8 ec 08 00 00       	call   800e30 <__udivdi3>
  800544:	89 d9                	mov    %ebx,%ecx
  800546:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80054a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80054e:	89 04 24             	mov    %eax,(%esp)
  800551:	89 54 24 04          	mov    %edx,0x4(%esp)
  800555:	89 fa                	mov    %edi,%edx
  800557:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80055a:	e8 71 ff ff ff       	call   8004d0 <printnum>
  80055f:	eb 1b                	jmp    80057c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800561:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800565:	8b 45 18             	mov    0x18(%ebp),%eax
  800568:	89 04 24             	mov    %eax,(%esp)
  80056b:	ff d3                	call   *%ebx
  80056d:	eb 03                	jmp    800572 <printnum+0xa2>
  80056f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800572:	83 ee 01             	sub    $0x1,%esi
  800575:	85 f6                	test   %esi,%esi
  800577:	7f e8                	jg     800561 <printnum+0x91>
  800579:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80057c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800580:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800584:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800587:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80058a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80058e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800592:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800595:	89 04 24             	mov    %eax,(%esp)
  800598:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80059b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80059f:	e8 bc 09 00 00       	call   800f60 <__umoddi3>
  8005a4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005a8:	0f be 80 1e 11 80 00 	movsbl 0x80111e(%eax),%eax
  8005af:	89 04 24             	mov    %eax,(%esp)
  8005b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8005b5:	ff d0                	call   *%eax
}
  8005b7:	83 c4 3c             	add    $0x3c,%esp
  8005ba:	5b                   	pop    %ebx
  8005bb:	5e                   	pop    %esi
  8005bc:	5f                   	pop    %edi
  8005bd:	5d                   	pop    %ebp
  8005be:	c3                   	ret    

008005bf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8005bf:	55                   	push   %ebp
  8005c0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8005c2:	83 fa 01             	cmp    $0x1,%edx
  8005c5:	7e 0e                	jle    8005d5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8005c7:	8b 10                	mov    (%eax),%edx
  8005c9:	8d 4a 08             	lea    0x8(%edx),%ecx
  8005cc:	89 08                	mov    %ecx,(%eax)
  8005ce:	8b 02                	mov    (%edx),%eax
  8005d0:	8b 52 04             	mov    0x4(%edx),%edx
  8005d3:	eb 22                	jmp    8005f7 <getuint+0x38>
	else if (lflag)
  8005d5:	85 d2                	test   %edx,%edx
  8005d7:	74 10                	je     8005e9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8005d9:	8b 10                	mov    (%eax),%edx
  8005db:	8d 4a 04             	lea    0x4(%edx),%ecx
  8005de:	89 08                	mov    %ecx,(%eax)
  8005e0:	8b 02                	mov    (%edx),%eax
  8005e2:	ba 00 00 00 00       	mov    $0x0,%edx
  8005e7:	eb 0e                	jmp    8005f7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8005e9:	8b 10                	mov    (%eax),%edx
  8005eb:	8d 4a 04             	lea    0x4(%edx),%ecx
  8005ee:	89 08                	mov    %ecx,(%eax)
  8005f0:	8b 02                	mov    (%edx),%eax
  8005f2:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8005f7:	5d                   	pop    %ebp
  8005f8:	c3                   	ret    

008005f9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8005f9:	55                   	push   %ebp
  8005fa:	89 e5                	mov    %esp,%ebp
  8005fc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8005ff:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800603:	8b 10                	mov    (%eax),%edx
  800605:	3b 50 04             	cmp    0x4(%eax),%edx
  800608:	73 0a                	jae    800614 <sprintputch+0x1b>
		*b->buf++ = ch;
  80060a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80060d:	89 08                	mov    %ecx,(%eax)
  80060f:	8b 45 08             	mov    0x8(%ebp),%eax
  800612:	88 02                	mov    %al,(%edx)
}
  800614:	5d                   	pop    %ebp
  800615:	c3                   	ret    

00800616 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800616:	55                   	push   %ebp
  800617:	89 e5                	mov    %esp,%ebp
  800619:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  80061c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80061f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800623:	8b 45 10             	mov    0x10(%ebp),%eax
  800626:	89 44 24 08          	mov    %eax,0x8(%esp)
  80062a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80062d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800631:	8b 45 08             	mov    0x8(%ebp),%eax
  800634:	89 04 24             	mov    %eax,(%esp)
  800637:	e8 02 00 00 00       	call   80063e <vprintfmt>
	va_end(ap);
}
  80063c:	c9                   	leave  
  80063d:	c3                   	ret    

0080063e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80063e:	55                   	push   %ebp
  80063f:	89 e5                	mov    %esp,%ebp
  800641:	57                   	push   %edi
  800642:	56                   	push   %esi
  800643:	53                   	push   %ebx
  800644:	83 ec 3c             	sub    $0x3c,%esp
  800647:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80064a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80064d:	eb 14                	jmp    800663 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80064f:	85 c0                	test   %eax,%eax
  800651:	0f 84 b3 03 00 00    	je     800a0a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800657:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80065b:	89 04 24             	mov    %eax,(%esp)
  80065e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800661:	89 f3                	mov    %esi,%ebx
  800663:	8d 73 01             	lea    0x1(%ebx),%esi
  800666:	0f b6 03             	movzbl (%ebx),%eax
  800669:	83 f8 25             	cmp    $0x25,%eax
  80066c:	75 e1                	jne    80064f <vprintfmt+0x11>
  80066e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800672:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800679:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800680:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800687:	ba 00 00 00 00       	mov    $0x0,%edx
  80068c:	eb 1d                	jmp    8006ab <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80068e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  800690:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800694:	eb 15                	jmp    8006ab <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800696:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800698:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80069c:	eb 0d                	jmp    8006ab <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80069e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8006a1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8006a4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006ab:	8d 5e 01             	lea    0x1(%esi),%ebx
  8006ae:	0f b6 0e             	movzbl (%esi),%ecx
  8006b1:	0f b6 c1             	movzbl %cl,%eax
  8006b4:	83 e9 23             	sub    $0x23,%ecx
  8006b7:	80 f9 55             	cmp    $0x55,%cl
  8006ba:	0f 87 2a 03 00 00    	ja     8009ea <vprintfmt+0x3ac>
  8006c0:	0f b6 c9             	movzbl %cl,%ecx
  8006c3:	ff 24 8d e0 11 80 00 	jmp    *0x8011e0(,%ecx,4)
  8006ca:	89 de                	mov    %ebx,%esi
  8006cc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8006d1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  8006d4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  8006d8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8006db:	8d 58 d0             	lea    -0x30(%eax),%ebx
  8006de:	83 fb 09             	cmp    $0x9,%ebx
  8006e1:	77 36                	ja     800719 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8006e3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8006e6:	eb e9                	jmp    8006d1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8006e8:	8b 45 14             	mov    0x14(%ebp),%eax
  8006eb:	8d 48 04             	lea    0x4(%eax),%ecx
  8006ee:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8006f1:	8b 00                	mov    (%eax),%eax
  8006f3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006f6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8006f8:	eb 22                	jmp    80071c <vprintfmt+0xde>
  8006fa:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8006fd:	85 c9                	test   %ecx,%ecx
  8006ff:	b8 00 00 00 00       	mov    $0x0,%eax
  800704:	0f 49 c1             	cmovns %ecx,%eax
  800707:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80070a:	89 de                	mov    %ebx,%esi
  80070c:	eb 9d                	jmp    8006ab <vprintfmt+0x6d>
  80070e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800710:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  800717:	eb 92                	jmp    8006ab <vprintfmt+0x6d>
  800719:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  80071c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800720:	79 89                	jns    8006ab <vprintfmt+0x6d>
  800722:	e9 77 ff ff ff       	jmp    80069e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800727:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80072a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80072c:	e9 7a ff ff ff       	jmp    8006ab <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800731:	8b 45 14             	mov    0x14(%ebp),%eax
  800734:	8d 50 04             	lea    0x4(%eax),%edx
  800737:	89 55 14             	mov    %edx,0x14(%ebp)
  80073a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80073e:	8b 00                	mov    (%eax),%eax
  800740:	89 04 24             	mov    %eax,(%esp)
  800743:	ff 55 08             	call   *0x8(%ebp)
			break;
  800746:	e9 18 ff ff ff       	jmp    800663 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80074b:	8b 45 14             	mov    0x14(%ebp),%eax
  80074e:	8d 50 04             	lea    0x4(%eax),%edx
  800751:	89 55 14             	mov    %edx,0x14(%ebp)
  800754:	8b 00                	mov    (%eax),%eax
  800756:	99                   	cltd   
  800757:	31 d0                	xor    %edx,%eax
  800759:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80075b:	83 f8 09             	cmp    $0x9,%eax
  80075e:	7f 0b                	jg     80076b <vprintfmt+0x12d>
  800760:	8b 14 85 40 13 80 00 	mov    0x801340(,%eax,4),%edx
  800767:	85 d2                	test   %edx,%edx
  800769:	75 20                	jne    80078b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80076b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80076f:	c7 44 24 08 36 11 80 	movl   $0x801136,0x8(%esp)
  800776:	00 
  800777:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80077b:	8b 45 08             	mov    0x8(%ebp),%eax
  80077e:	89 04 24             	mov    %eax,(%esp)
  800781:	e8 90 fe ff ff       	call   800616 <printfmt>
  800786:	e9 d8 fe ff ff       	jmp    800663 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80078b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80078f:	c7 44 24 08 3f 11 80 	movl   $0x80113f,0x8(%esp)
  800796:	00 
  800797:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80079b:	8b 45 08             	mov    0x8(%ebp),%eax
  80079e:	89 04 24             	mov    %eax,(%esp)
  8007a1:	e8 70 fe ff ff       	call   800616 <printfmt>
  8007a6:	e9 b8 fe ff ff       	jmp    800663 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007ab:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8007ae:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8007b1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8007b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8007b7:	8d 50 04             	lea    0x4(%eax),%edx
  8007ba:	89 55 14             	mov    %edx,0x14(%ebp)
  8007bd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  8007bf:	85 f6                	test   %esi,%esi
  8007c1:	b8 2f 11 80 00       	mov    $0x80112f,%eax
  8007c6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  8007c9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  8007cd:	0f 84 97 00 00 00    	je     80086a <vprintfmt+0x22c>
  8007d3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  8007d7:	0f 8e 9b 00 00 00    	jle    800878 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  8007dd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8007e1:	89 34 24             	mov    %esi,(%esp)
  8007e4:	e8 cf 02 00 00       	call   800ab8 <strnlen>
  8007e9:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8007ec:	29 c2                	sub    %eax,%edx
  8007ee:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  8007f1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8007f5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8007f8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8007fb:	8b 75 08             	mov    0x8(%ebp),%esi
  8007fe:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800801:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800803:	eb 0f                	jmp    800814 <vprintfmt+0x1d6>
					putch(padc, putdat);
  800805:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800809:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80080c:	89 04 24             	mov    %eax,(%esp)
  80080f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800811:	83 eb 01             	sub    $0x1,%ebx
  800814:	85 db                	test   %ebx,%ebx
  800816:	7f ed                	jg     800805 <vprintfmt+0x1c7>
  800818:	8b 75 d8             	mov    -0x28(%ebp),%esi
  80081b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80081e:	85 d2                	test   %edx,%edx
  800820:	b8 00 00 00 00       	mov    $0x0,%eax
  800825:	0f 49 c2             	cmovns %edx,%eax
  800828:	29 c2                	sub    %eax,%edx
  80082a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80082d:	89 d7                	mov    %edx,%edi
  80082f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800832:	eb 50                	jmp    800884 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800834:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800838:	74 1e                	je     800858 <vprintfmt+0x21a>
  80083a:	0f be d2             	movsbl %dl,%edx
  80083d:	83 ea 20             	sub    $0x20,%edx
  800840:	83 fa 5e             	cmp    $0x5e,%edx
  800843:	76 13                	jbe    800858 <vprintfmt+0x21a>
					putch('?', putdat);
  800845:	8b 45 0c             	mov    0xc(%ebp),%eax
  800848:	89 44 24 04          	mov    %eax,0x4(%esp)
  80084c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800853:	ff 55 08             	call   *0x8(%ebp)
  800856:	eb 0d                	jmp    800865 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800858:	8b 55 0c             	mov    0xc(%ebp),%edx
  80085b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80085f:	89 04 24             	mov    %eax,(%esp)
  800862:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800865:	83 ef 01             	sub    $0x1,%edi
  800868:	eb 1a                	jmp    800884 <vprintfmt+0x246>
  80086a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80086d:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800870:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800873:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800876:	eb 0c                	jmp    800884 <vprintfmt+0x246>
  800878:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80087b:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80087e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800881:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800884:	83 c6 01             	add    $0x1,%esi
  800887:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80088b:	0f be c2             	movsbl %dl,%eax
  80088e:	85 c0                	test   %eax,%eax
  800890:	74 27                	je     8008b9 <vprintfmt+0x27b>
  800892:	85 db                	test   %ebx,%ebx
  800894:	78 9e                	js     800834 <vprintfmt+0x1f6>
  800896:	83 eb 01             	sub    $0x1,%ebx
  800899:	79 99                	jns    800834 <vprintfmt+0x1f6>
  80089b:	89 f8                	mov    %edi,%eax
  80089d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8008a0:	8b 75 08             	mov    0x8(%ebp),%esi
  8008a3:	89 c3                	mov    %eax,%ebx
  8008a5:	eb 1a                	jmp    8008c1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8008a7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8008ab:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8008b2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8008b4:	83 eb 01             	sub    $0x1,%ebx
  8008b7:	eb 08                	jmp    8008c1 <vprintfmt+0x283>
  8008b9:	89 fb                	mov    %edi,%ebx
  8008bb:	8b 75 08             	mov    0x8(%ebp),%esi
  8008be:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8008c1:	85 db                	test   %ebx,%ebx
  8008c3:	7f e2                	jg     8008a7 <vprintfmt+0x269>
  8008c5:	89 75 08             	mov    %esi,0x8(%ebp)
  8008c8:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8008cb:	e9 93 fd ff ff       	jmp    800663 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8008d0:	83 fa 01             	cmp    $0x1,%edx
  8008d3:	7e 16                	jle    8008eb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  8008d5:	8b 45 14             	mov    0x14(%ebp),%eax
  8008d8:	8d 50 08             	lea    0x8(%eax),%edx
  8008db:	89 55 14             	mov    %edx,0x14(%ebp)
  8008de:	8b 50 04             	mov    0x4(%eax),%edx
  8008e1:	8b 00                	mov    (%eax),%eax
  8008e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8008e6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8008e9:	eb 32                	jmp    80091d <vprintfmt+0x2df>
	else if (lflag)
  8008eb:	85 d2                	test   %edx,%edx
  8008ed:	74 18                	je     800907 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  8008ef:	8b 45 14             	mov    0x14(%ebp),%eax
  8008f2:	8d 50 04             	lea    0x4(%eax),%edx
  8008f5:	89 55 14             	mov    %edx,0x14(%ebp)
  8008f8:	8b 30                	mov    (%eax),%esi
  8008fa:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8008fd:	89 f0                	mov    %esi,%eax
  8008ff:	c1 f8 1f             	sar    $0x1f,%eax
  800902:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800905:	eb 16                	jmp    80091d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  800907:	8b 45 14             	mov    0x14(%ebp),%eax
  80090a:	8d 50 04             	lea    0x4(%eax),%edx
  80090d:	89 55 14             	mov    %edx,0x14(%ebp)
  800910:	8b 30                	mov    (%eax),%esi
  800912:	89 75 e0             	mov    %esi,-0x20(%ebp)
  800915:	89 f0                	mov    %esi,%eax
  800917:	c1 f8 1f             	sar    $0x1f,%eax
  80091a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80091d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800920:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800923:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800928:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80092c:	0f 89 80 00 00 00    	jns    8009b2 <vprintfmt+0x374>
				putch('-', putdat);
  800932:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800936:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80093d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800940:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800943:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800946:	f7 d8                	neg    %eax
  800948:	83 d2 00             	adc    $0x0,%edx
  80094b:	f7 da                	neg    %edx
			}
			base = 10;
  80094d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800952:	eb 5e                	jmp    8009b2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800954:	8d 45 14             	lea    0x14(%ebp),%eax
  800957:	e8 63 fc ff ff       	call   8005bf <getuint>
			base = 10;
  80095c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800961:	eb 4f                	jmp    8009b2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800963:	8d 45 14             	lea    0x14(%ebp),%eax
  800966:	e8 54 fc ff ff       	call   8005bf <getuint>
			base = 8;
  80096b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800970:	eb 40                	jmp    8009b2 <vprintfmt+0x374>
			
		// pointer
		case 'p':
			putch('0', putdat);
  800972:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800976:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80097d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800980:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800984:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80098b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80098e:	8b 45 14             	mov    0x14(%ebp),%eax
  800991:	8d 50 04             	lea    0x4(%eax),%edx
  800994:	89 55 14             	mov    %edx,0x14(%ebp)
			
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800997:	8b 00                	mov    (%eax),%eax
  800999:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80099e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8009a3:	eb 0d                	jmp    8009b2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8009a5:	8d 45 14             	lea    0x14(%ebp),%eax
  8009a8:	e8 12 fc ff ff       	call   8005bf <getuint>
			base = 16;
  8009ad:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8009b2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  8009b6:	89 74 24 10          	mov    %esi,0x10(%esp)
  8009ba:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8009bd:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8009c1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8009c5:	89 04 24             	mov    %eax,(%esp)
  8009c8:	89 54 24 04          	mov    %edx,0x4(%esp)
  8009cc:	89 fa                	mov    %edi,%edx
  8009ce:	8b 45 08             	mov    0x8(%ebp),%eax
  8009d1:	e8 fa fa ff ff       	call   8004d0 <printnum>
			break;
  8009d6:	e9 88 fc ff ff       	jmp    800663 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8009db:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8009df:	89 04 24             	mov    %eax,(%esp)
  8009e2:	ff 55 08             	call   *0x8(%ebp)
			break;
  8009e5:	e9 79 fc ff ff       	jmp    800663 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8009ea:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8009ee:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8009f5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8009f8:	89 f3                	mov    %esi,%ebx
  8009fa:	eb 03                	jmp    8009ff <vprintfmt+0x3c1>
  8009fc:	83 eb 01             	sub    $0x1,%ebx
  8009ff:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  800a03:	75 f7                	jne    8009fc <vprintfmt+0x3be>
  800a05:	e9 59 fc ff ff       	jmp    800663 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800a0a:	83 c4 3c             	add    $0x3c,%esp
  800a0d:	5b                   	pop    %ebx
  800a0e:	5e                   	pop    %esi
  800a0f:	5f                   	pop    %edi
  800a10:	5d                   	pop    %ebp
  800a11:	c3                   	ret    

00800a12 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800a12:	55                   	push   %ebp
  800a13:	89 e5                	mov    %esp,%ebp
  800a15:	83 ec 28             	sub    $0x28,%esp
  800a18:	8b 45 08             	mov    0x8(%ebp),%eax
  800a1b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800a1e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800a21:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800a25:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800a28:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800a2f:	85 c0                	test   %eax,%eax
  800a31:	74 30                	je     800a63 <vsnprintf+0x51>
  800a33:	85 d2                	test   %edx,%edx
  800a35:	7e 2c                	jle    800a63 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800a37:	8b 45 14             	mov    0x14(%ebp),%eax
  800a3a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800a3e:	8b 45 10             	mov    0x10(%ebp),%eax
  800a41:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a45:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800a48:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a4c:	c7 04 24 f9 05 80 00 	movl   $0x8005f9,(%esp)
  800a53:	e8 e6 fb ff ff       	call   80063e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800a58:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800a5b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800a5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800a61:	eb 05                	jmp    800a68 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800a63:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800a68:	c9                   	leave  
  800a69:	c3                   	ret    

00800a6a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800a6a:	55                   	push   %ebp
  800a6b:	89 e5                	mov    %esp,%ebp
  800a6d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800a70:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800a73:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800a77:	8b 45 10             	mov    0x10(%ebp),%eax
  800a7a:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a7e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a81:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a85:	8b 45 08             	mov    0x8(%ebp),%eax
  800a88:	89 04 24             	mov    %eax,(%esp)
  800a8b:	e8 82 ff ff ff       	call   800a12 <vsnprintf>
	va_end(ap);

	return rc;
}
  800a90:	c9                   	leave  
  800a91:	c3                   	ret    
  800a92:	66 90                	xchg   %ax,%ax
  800a94:	66 90                	xchg   %ax,%ax
  800a96:	66 90                	xchg   %ax,%ax
  800a98:	66 90                	xchg   %ax,%ax
  800a9a:	66 90                	xchg   %ax,%ax
  800a9c:	66 90                	xchg   %ax,%ax
  800a9e:	66 90                	xchg   %ax,%ax

00800aa0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800aa0:	55                   	push   %ebp
  800aa1:	89 e5                	mov    %esp,%ebp
  800aa3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800aa6:	b8 00 00 00 00       	mov    $0x0,%eax
  800aab:	eb 03                	jmp    800ab0 <strlen+0x10>
		n++;
  800aad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800ab0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800ab4:	75 f7                	jne    800aad <strlen+0xd>
		n++;
	return n;
}
  800ab6:	5d                   	pop    %ebp
  800ab7:	c3                   	ret    

00800ab8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800ab8:	55                   	push   %ebp
  800ab9:	89 e5                	mov    %esp,%ebp
  800abb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800abe:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800ac1:	b8 00 00 00 00       	mov    $0x0,%eax
  800ac6:	eb 03                	jmp    800acb <strnlen+0x13>
		n++;
  800ac8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800acb:	39 d0                	cmp    %edx,%eax
  800acd:	74 06                	je     800ad5 <strnlen+0x1d>
  800acf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800ad3:	75 f3                	jne    800ac8 <strnlen+0x10>
		n++;
	return n;
}
  800ad5:	5d                   	pop    %ebp
  800ad6:	c3                   	ret    

00800ad7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800ad7:	55                   	push   %ebp
  800ad8:	89 e5                	mov    %esp,%ebp
  800ada:	53                   	push   %ebx
  800adb:	8b 45 08             	mov    0x8(%ebp),%eax
  800ade:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800ae1:	89 c2                	mov    %eax,%edx
  800ae3:	83 c2 01             	add    $0x1,%edx
  800ae6:	83 c1 01             	add    $0x1,%ecx
  800ae9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800aed:	88 5a ff             	mov    %bl,-0x1(%edx)
  800af0:	84 db                	test   %bl,%bl
  800af2:	75 ef                	jne    800ae3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800af4:	5b                   	pop    %ebx
  800af5:	5d                   	pop    %ebp
  800af6:	c3                   	ret    

00800af7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800af7:	55                   	push   %ebp
  800af8:	89 e5                	mov    %esp,%ebp
  800afa:	53                   	push   %ebx
  800afb:	83 ec 08             	sub    $0x8,%esp
  800afe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800b01:	89 1c 24             	mov    %ebx,(%esp)
  800b04:	e8 97 ff ff ff       	call   800aa0 <strlen>
	strcpy(dst + len, src);
  800b09:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b0c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800b10:	01 d8                	add    %ebx,%eax
  800b12:	89 04 24             	mov    %eax,(%esp)
  800b15:	e8 bd ff ff ff       	call   800ad7 <strcpy>
	return dst;
}
  800b1a:	89 d8                	mov    %ebx,%eax
  800b1c:	83 c4 08             	add    $0x8,%esp
  800b1f:	5b                   	pop    %ebx
  800b20:	5d                   	pop    %ebp
  800b21:	c3                   	ret    

00800b22 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800b22:	55                   	push   %ebp
  800b23:	89 e5                	mov    %esp,%ebp
  800b25:	56                   	push   %esi
  800b26:	53                   	push   %ebx
  800b27:	8b 75 08             	mov    0x8(%ebp),%esi
  800b2a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b2d:	89 f3                	mov    %esi,%ebx
  800b2f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800b32:	89 f2                	mov    %esi,%edx
  800b34:	eb 0f                	jmp    800b45 <strncpy+0x23>
		*dst++ = *src;
  800b36:	83 c2 01             	add    $0x1,%edx
  800b39:	0f b6 01             	movzbl (%ecx),%eax
  800b3c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800b3f:	80 39 01             	cmpb   $0x1,(%ecx)
  800b42:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800b45:	39 da                	cmp    %ebx,%edx
  800b47:	75 ed                	jne    800b36 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800b49:	89 f0                	mov    %esi,%eax
  800b4b:	5b                   	pop    %ebx
  800b4c:	5e                   	pop    %esi
  800b4d:	5d                   	pop    %ebp
  800b4e:	c3                   	ret    

00800b4f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800b4f:	55                   	push   %ebp
  800b50:	89 e5                	mov    %esp,%ebp
  800b52:	56                   	push   %esi
  800b53:	53                   	push   %ebx
  800b54:	8b 75 08             	mov    0x8(%ebp),%esi
  800b57:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b5a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800b5d:	89 f0                	mov    %esi,%eax
  800b5f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800b63:	85 c9                	test   %ecx,%ecx
  800b65:	75 0b                	jne    800b72 <strlcpy+0x23>
  800b67:	eb 1d                	jmp    800b86 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800b69:	83 c0 01             	add    $0x1,%eax
  800b6c:	83 c2 01             	add    $0x1,%edx
  800b6f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800b72:	39 d8                	cmp    %ebx,%eax
  800b74:	74 0b                	je     800b81 <strlcpy+0x32>
  800b76:	0f b6 0a             	movzbl (%edx),%ecx
  800b79:	84 c9                	test   %cl,%cl
  800b7b:	75 ec                	jne    800b69 <strlcpy+0x1a>
  800b7d:	89 c2                	mov    %eax,%edx
  800b7f:	eb 02                	jmp    800b83 <strlcpy+0x34>
  800b81:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800b83:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800b86:	29 f0                	sub    %esi,%eax
}
  800b88:	5b                   	pop    %ebx
  800b89:	5e                   	pop    %esi
  800b8a:	5d                   	pop    %ebp
  800b8b:	c3                   	ret    

00800b8c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800b8c:	55                   	push   %ebp
  800b8d:	89 e5                	mov    %esp,%ebp
  800b8f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b92:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800b95:	eb 06                	jmp    800b9d <strcmp+0x11>
		p++, q++;
  800b97:	83 c1 01             	add    $0x1,%ecx
  800b9a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800b9d:	0f b6 01             	movzbl (%ecx),%eax
  800ba0:	84 c0                	test   %al,%al
  800ba2:	74 04                	je     800ba8 <strcmp+0x1c>
  800ba4:	3a 02                	cmp    (%edx),%al
  800ba6:	74 ef                	je     800b97 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800ba8:	0f b6 c0             	movzbl %al,%eax
  800bab:	0f b6 12             	movzbl (%edx),%edx
  800bae:	29 d0                	sub    %edx,%eax
}
  800bb0:	5d                   	pop    %ebp
  800bb1:	c3                   	ret    

00800bb2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800bb2:	55                   	push   %ebp
  800bb3:	89 e5                	mov    %esp,%ebp
  800bb5:	53                   	push   %ebx
  800bb6:	8b 45 08             	mov    0x8(%ebp),%eax
  800bb9:	8b 55 0c             	mov    0xc(%ebp),%edx
  800bbc:	89 c3                	mov    %eax,%ebx
  800bbe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800bc1:	eb 06                	jmp    800bc9 <strncmp+0x17>
		n--, p++, q++;
  800bc3:	83 c0 01             	add    $0x1,%eax
  800bc6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800bc9:	39 d8                	cmp    %ebx,%eax
  800bcb:	74 15                	je     800be2 <strncmp+0x30>
  800bcd:	0f b6 08             	movzbl (%eax),%ecx
  800bd0:	84 c9                	test   %cl,%cl
  800bd2:	74 04                	je     800bd8 <strncmp+0x26>
  800bd4:	3a 0a                	cmp    (%edx),%cl
  800bd6:	74 eb                	je     800bc3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800bd8:	0f b6 00             	movzbl (%eax),%eax
  800bdb:	0f b6 12             	movzbl (%edx),%edx
  800bde:	29 d0                	sub    %edx,%eax
  800be0:	eb 05                	jmp    800be7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800be2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800be7:	5b                   	pop    %ebx
  800be8:	5d                   	pop    %ebp
  800be9:	c3                   	ret    

00800bea <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800bea:	55                   	push   %ebp
  800beb:	89 e5                	mov    %esp,%ebp
  800bed:	8b 45 08             	mov    0x8(%ebp),%eax
  800bf0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800bf4:	eb 07                	jmp    800bfd <strchr+0x13>
		if (*s == c)
  800bf6:	38 ca                	cmp    %cl,%dl
  800bf8:	74 0f                	je     800c09 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800bfa:	83 c0 01             	add    $0x1,%eax
  800bfd:	0f b6 10             	movzbl (%eax),%edx
  800c00:	84 d2                	test   %dl,%dl
  800c02:	75 f2                	jne    800bf6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800c04:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800c09:	5d                   	pop    %ebp
  800c0a:	c3                   	ret    

00800c0b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800c0b:	55                   	push   %ebp
  800c0c:	89 e5                	mov    %esp,%ebp
  800c0e:	8b 45 08             	mov    0x8(%ebp),%eax
  800c11:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800c15:	eb 07                	jmp    800c1e <strfind+0x13>
		if (*s == c)
  800c17:	38 ca                	cmp    %cl,%dl
  800c19:	74 0a                	je     800c25 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800c1b:	83 c0 01             	add    $0x1,%eax
  800c1e:	0f b6 10             	movzbl (%eax),%edx
  800c21:	84 d2                	test   %dl,%dl
  800c23:	75 f2                	jne    800c17 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800c25:	5d                   	pop    %ebp
  800c26:	c3                   	ret    

00800c27 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800c27:	55                   	push   %ebp
  800c28:	89 e5                	mov    %esp,%ebp
  800c2a:	57                   	push   %edi
  800c2b:	56                   	push   %esi
  800c2c:	53                   	push   %ebx
  800c2d:	8b 7d 08             	mov    0x8(%ebp),%edi
  800c30:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800c33:	85 c9                	test   %ecx,%ecx
  800c35:	74 36                	je     800c6d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800c37:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800c3d:	75 28                	jne    800c67 <memset+0x40>
  800c3f:	f6 c1 03             	test   $0x3,%cl
  800c42:	75 23                	jne    800c67 <memset+0x40>
		c &= 0xFF;
  800c44:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800c48:	89 d3                	mov    %edx,%ebx
  800c4a:	c1 e3 08             	shl    $0x8,%ebx
  800c4d:	89 d6                	mov    %edx,%esi
  800c4f:	c1 e6 18             	shl    $0x18,%esi
  800c52:	89 d0                	mov    %edx,%eax
  800c54:	c1 e0 10             	shl    $0x10,%eax
  800c57:	09 f0                	or     %esi,%eax
  800c59:	09 c2                	or     %eax,%edx
  800c5b:	89 d0                	mov    %edx,%eax
  800c5d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800c5f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800c62:	fc                   	cld    
  800c63:	f3 ab                	rep stos %eax,%es:(%edi)
  800c65:	eb 06                	jmp    800c6d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800c67:	8b 45 0c             	mov    0xc(%ebp),%eax
  800c6a:	fc                   	cld    
  800c6b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800c6d:	89 f8                	mov    %edi,%eax
  800c6f:	5b                   	pop    %ebx
  800c70:	5e                   	pop    %esi
  800c71:	5f                   	pop    %edi
  800c72:	5d                   	pop    %ebp
  800c73:	c3                   	ret    

00800c74 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800c74:	55                   	push   %ebp
  800c75:	89 e5                	mov    %esp,%ebp
  800c77:	57                   	push   %edi
  800c78:	56                   	push   %esi
  800c79:	8b 45 08             	mov    0x8(%ebp),%eax
  800c7c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c7f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800c82:	39 c6                	cmp    %eax,%esi
  800c84:	73 35                	jae    800cbb <memmove+0x47>
  800c86:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800c89:	39 d0                	cmp    %edx,%eax
  800c8b:	73 2e                	jae    800cbb <memmove+0x47>
		s += n;
		d += n;
  800c8d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800c90:	89 d6                	mov    %edx,%esi
  800c92:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800c94:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800c9a:	75 13                	jne    800caf <memmove+0x3b>
  800c9c:	f6 c1 03             	test   $0x3,%cl
  800c9f:	75 0e                	jne    800caf <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800ca1:	83 ef 04             	sub    $0x4,%edi
  800ca4:	8d 72 fc             	lea    -0x4(%edx),%esi
  800ca7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800caa:	fd                   	std    
  800cab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800cad:	eb 09                	jmp    800cb8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800caf:	83 ef 01             	sub    $0x1,%edi
  800cb2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800cb5:	fd                   	std    
  800cb6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800cb8:	fc                   	cld    
  800cb9:	eb 1d                	jmp    800cd8 <memmove+0x64>
  800cbb:	89 f2                	mov    %esi,%edx
  800cbd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800cbf:	f6 c2 03             	test   $0x3,%dl
  800cc2:	75 0f                	jne    800cd3 <memmove+0x5f>
  800cc4:	f6 c1 03             	test   $0x3,%cl
  800cc7:	75 0a                	jne    800cd3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800cc9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800ccc:	89 c7                	mov    %eax,%edi
  800cce:	fc                   	cld    
  800ccf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800cd1:	eb 05                	jmp    800cd8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800cd3:	89 c7                	mov    %eax,%edi
  800cd5:	fc                   	cld    
  800cd6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800cd8:	5e                   	pop    %esi
  800cd9:	5f                   	pop    %edi
  800cda:	5d                   	pop    %ebp
  800cdb:	c3                   	ret    

00800cdc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800cdc:	55                   	push   %ebp
  800cdd:	89 e5                	mov    %esp,%ebp
  800cdf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800ce2:	8b 45 10             	mov    0x10(%ebp),%eax
  800ce5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ce9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800cec:	89 44 24 04          	mov    %eax,0x4(%esp)
  800cf0:	8b 45 08             	mov    0x8(%ebp),%eax
  800cf3:	89 04 24             	mov    %eax,(%esp)
  800cf6:	e8 79 ff ff ff       	call   800c74 <memmove>
}
  800cfb:	c9                   	leave  
  800cfc:	c3                   	ret    

00800cfd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800cfd:	55                   	push   %ebp
  800cfe:	89 e5                	mov    %esp,%ebp
  800d00:	56                   	push   %esi
  800d01:	53                   	push   %ebx
  800d02:	8b 55 08             	mov    0x8(%ebp),%edx
  800d05:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d08:	89 d6                	mov    %edx,%esi
  800d0a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800d0d:	eb 1a                	jmp    800d29 <memcmp+0x2c>
		if (*s1 != *s2)
  800d0f:	0f b6 02             	movzbl (%edx),%eax
  800d12:	0f b6 19             	movzbl (%ecx),%ebx
  800d15:	38 d8                	cmp    %bl,%al
  800d17:	74 0a                	je     800d23 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800d19:	0f b6 c0             	movzbl %al,%eax
  800d1c:	0f b6 db             	movzbl %bl,%ebx
  800d1f:	29 d8                	sub    %ebx,%eax
  800d21:	eb 0f                	jmp    800d32 <memcmp+0x35>
		s1++, s2++;
  800d23:	83 c2 01             	add    $0x1,%edx
  800d26:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800d29:	39 f2                	cmp    %esi,%edx
  800d2b:	75 e2                	jne    800d0f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800d2d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800d32:	5b                   	pop    %ebx
  800d33:	5e                   	pop    %esi
  800d34:	5d                   	pop    %ebp
  800d35:	c3                   	ret    

00800d36 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800d36:	55                   	push   %ebp
  800d37:	89 e5                	mov    %esp,%ebp
  800d39:	8b 45 08             	mov    0x8(%ebp),%eax
  800d3c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800d3f:	89 c2                	mov    %eax,%edx
  800d41:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800d44:	eb 07                	jmp    800d4d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800d46:	38 08                	cmp    %cl,(%eax)
  800d48:	74 07                	je     800d51 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800d4a:	83 c0 01             	add    $0x1,%eax
  800d4d:	39 d0                	cmp    %edx,%eax
  800d4f:	72 f5                	jb     800d46 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800d51:	5d                   	pop    %ebp
  800d52:	c3                   	ret    

00800d53 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800d53:	55                   	push   %ebp
  800d54:	89 e5                	mov    %esp,%ebp
  800d56:	57                   	push   %edi
  800d57:	56                   	push   %esi
  800d58:	53                   	push   %ebx
  800d59:	8b 55 08             	mov    0x8(%ebp),%edx
  800d5c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800d5f:	eb 03                	jmp    800d64 <strtol+0x11>
		s++;
  800d61:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800d64:	0f b6 0a             	movzbl (%edx),%ecx
  800d67:	80 f9 09             	cmp    $0x9,%cl
  800d6a:	74 f5                	je     800d61 <strtol+0xe>
  800d6c:	80 f9 20             	cmp    $0x20,%cl
  800d6f:	74 f0                	je     800d61 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800d71:	80 f9 2b             	cmp    $0x2b,%cl
  800d74:	75 0a                	jne    800d80 <strtol+0x2d>
		s++;
  800d76:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800d79:	bf 00 00 00 00       	mov    $0x0,%edi
  800d7e:	eb 11                	jmp    800d91 <strtol+0x3e>
  800d80:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800d85:	80 f9 2d             	cmp    $0x2d,%cl
  800d88:	75 07                	jne    800d91 <strtol+0x3e>
		s++, neg = 1;
  800d8a:	8d 52 01             	lea    0x1(%edx),%edx
  800d8d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800d91:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800d96:	75 15                	jne    800dad <strtol+0x5a>
  800d98:	80 3a 30             	cmpb   $0x30,(%edx)
  800d9b:	75 10                	jne    800dad <strtol+0x5a>
  800d9d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800da1:	75 0a                	jne    800dad <strtol+0x5a>
		s += 2, base = 16;
  800da3:	83 c2 02             	add    $0x2,%edx
  800da6:	b8 10 00 00 00       	mov    $0x10,%eax
  800dab:	eb 10                	jmp    800dbd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800dad:	85 c0                	test   %eax,%eax
  800daf:	75 0c                	jne    800dbd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800db1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800db3:	80 3a 30             	cmpb   $0x30,(%edx)
  800db6:	75 05                	jne    800dbd <strtol+0x6a>
		s++, base = 8;
  800db8:	83 c2 01             	add    $0x1,%edx
  800dbb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800dbd:	bb 00 00 00 00       	mov    $0x0,%ebx
  800dc2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800dc5:	0f b6 0a             	movzbl (%edx),%ecx
  800dc8:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800dcb:	89 f0                	mov    %esi,%eax
  800dcd:	3c 09                	cmp    $0x9,%al
  800dcf:	77 08                	ja     800dd9 <strtol+0x86>
			dig = *s - '0';
  800dd1:	0f be c9             	movsbl %cl,%ecx
  800dd4:	83 e9 30             	sub    $0x30,%ecx
  800dd7:	eb 20                	jmp    800df9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800dd9:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800ddc:	89 f0                	mov    %esi,%eax
  800dde:	3c 19                	cmp    $0x19,%al
  800de0:	77 08                	ja     800dea <strtol+0x97>
			dig = *s - 'a' + 10;
  800de2:	0f be c9             	movsbl %cl,%ecx
  800de5:	83 e9 57             	sub    $0x57,%ecx
  800de8:	eb 0f                	jmp    800df9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800dea:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800ded:	89 f0                	mov    %esi,%eax
  800def:	3c 19                	cmp    $0x19,%al
  800df1:	77 16                	ja     800e09 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800df3:	0f be c9             	movsbl %cl,%ecx
  800df6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800df9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800dfc:	7d 0f                	jge    800e0d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800dfe:	83 c2 01             	add    $0x1,%edx
  800e01:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800e05:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800e07:	eb bc                	jmp    800dc5 <strtol+0x72>
  800e09:	89 d8                	mov    %ebx,%eax
  800e0b:	eb 02                	jmp    800e0f <strtol+0xbc>
  800e0d:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800e0f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800e13:	74 05                	je     800e1a <strtol+0xc7>
		*endptr = (char *) s;
  800e15:	8b 75 0c             	mov    0xc(%ebp),%esi
  800e18:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800e1a:	f7 d8                	neg    %eax
  800e1c:	85 ff                	test   %edi,%edi
  800e1e:	0f 44 c3             	cmove  %ebx,%eax
}
  800e21:	5b                   	pop    %ebx
  800e22:	5e                   	pop    %esi
  800e23:	5f                   	pop    %edi
  800e24:	5d                   	pop    %ebp
  800e25:	c3                   	ret    
  800e26:	66 90                	xchg   %ax,%ax
  800e28:	66 90                	xchg   %ax,%ax
  800e2a:	66 90                	xchg   %ax,%ax
  800e2c:	66 90                	xchg   %ax,%ax
  800e2e:	66 90                	xchg   %ax,%ax

00800e30 <__udivdi3>:
  800e30:	55                   	push   %ebp
  800e31:	57                   	push   %edi
  800e32:	56                   	push   %esi
  800e33:	83 ec 0c             	sub    $0xc,%esp
  800e36:	8b 44 24 28          	mov    0x28(%esp),%eax
  800e3a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800e3e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800e42:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800e46:	85 c0                	test   %eax,%eax
  800e48:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800e4c:	89 ea                	mov    %ebp,%edx
  800e4e:	89 0c 24             	mov    %ecx,(%esp)
  800e51:	75 2d                	jne    800e80 <__udivdi3+0x50>
  800e53:	39 e9                	cmp    %ebp,%ecx
  800e55:	77 61                	ja     800eb8 <__udivdi3+0x88>
  800e57:	85 c9                	test   %ecx,%ecx
  800e59:	89 ce                	mov    %ecx,%esi
  800e5b:	75 0b                	jne    800e68 <__udivdi3+0x38>
  800e5d:	b8 01 00 00 00       	mov    $0x1,%eax
  800e62:	31 d2                	xor    %edx,%edx
  800e64:	f7 f1                	div    %ecx
  800e66:	89 c6                	mov    %eax,%esi
  800e68:	31 d2                	xor    %edx,%edx
  800e6a:	89 e8                	mov    %ebp,%eax
  800e6c:	f7 f6                	div    %esi
  800e6e:	89 c5                	mov    %eax,%ebp
  800e70:	89 f8                	mov    %edi,%eax
  800e72:	f7 f6                	div    %esi
  800e74:	89 ea                	mov    %ebp,%edx
  800e76:	83 c4 0c             	add    $0xc,%esp
  800e79:	5e                   	pop    %esi
  800e7a:	5f                   	pop    %edi
  800e7b:	5d                   	pop    %ebp
  800e7c:	c3                   	ret    
  800e7d:	8d 76 00             	lea    0x0(%esi),%esi
  800e80:	39 e8                	cmp    %ebp,%eax
  800e82:	77 24                	ja     800ea8 <__udivdi3+0x78>
  800e84:	0f bd e8             	bsr    %eax,%ebp
  800e87:	83 f5 1f             	xor    $0x1f,%ebp
  800e8a:	75 3c                	jne    800ec8 <__udivdi3+0x98>
  800e8c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800e90:	39 34 24             	cmp    %esi,(%esp)
  800e93:	0f 86 9f 00 00 00    	jbe    800f38 <__udivdi3+0x108>
  800e99:	39 d0                	cmp    %edx,%eax
  800e9b:	0f 82 97 00 00 00    	jb     800f38 <__udivdi3+0x108>
  800ea1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ea8:	31 d2                	xor    %edx,%edx
  800eaa:	31 c0                	xor    %eax,%eax
  800eac:	83 c4 0c             	add    $0xc,%esp
  800eaf:	5e                   	pop    %esi
  800eb0:	5f                   	pop    %edi
  800eb1:	5d                   	pop    %ebp
  800eb2:	c3                   	ret    
  800eb3:	90                   	nop
  800eb4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800eb8:	89 f8                	mov    %edi,%eax
  800eba:	f7 f1                	div    %ecx
  800ebc:	31 d2                	xor    %edx,%edx
  800ebe:	83 c4 0c             	add    $0xc,%esp
  800ec1:	5e                   	pop    %esi
  800ec2:	5f                   	pop    %edi
  800ec3:	5d                   	pop    %ebp
  800ec4:	c3                   	ret    
  800ec5:	8d 76 00             	lea    0x0(%esi),%esi
  800ec8:	89 e9                	mov    %ebp,%ecx
  800eca:	8b 3c 24             	mov    (%esp),%edi
  800ecd:	d3 e0                	shl    %cl,%eax
  800ecf:	89 c6                	mov    %eax,%esi
  800ed1:	b8 20 00 00 00       	mov    $0x20,%eax
  800ed6:	29 e8                	sub    %ebp,%eax
  800ed8:	89 c1                	mov    %eax,%ecx
  800eda:	d3 ef                	shr    %cl,%edi
  800edc:	89 e9                	mov    %ebp,%ecx
  800ede:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800ee2:	8b 3c 24             	mov    (%esp),%edi
  800ee5:	09 74 24 08          	or     %esi,0x8(%esp)
  800ee9:	89 d6                	mov    %edx,%esi
  800eeb:	d3 e7                	shl    %cl,%edi
  800eed:	89 c1                	mov    %eax,%ecx
  800eef:	89 3c 24             	mov    %edi,(%esp)
  800ef2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800ef6:	d3 ee                	shr    %cl,%esi
  800ef8:	89 e9                	mov    %ebp,%ecx
  800efa:	d3 e2                	shl    %cl,%edx
  800efc:	89 c1                	mov    %eax,%ecx
  800efe:	d3 ef                	shr    %cl,%edi
  800f00:	09 d7                	or     %edx,%edi
  800f02:	89 f2                	mov    %esi,%edx
  800f04:	89 f8                	mov    %edi,%eax
  800f06:	f7 74 24 08          	divl   0x8(%esp)
  800f0a:	89 d6                	mov    %edx,%esi
  800f0c:	89 c7                	mov    %eax,%edi
  800f0e:	f7 24 24             	mull   (%esp)
  800f11:	39 d6                	cmp    %edx,%esi
  800f13:	89 14 24             	mov    %edx,(%esp)
  800f16:	72 30                	jb     800f48 <__udivdi3+0x118>
  800f18:	8b 54 24 04          	mov    0x4(%esp),%edx
  800f1c:	89 e9                	mov    %ebp,%ecx
  800f1e:	d3 e2                	shl    %cl,%edx
  800f20:	39 c2                	cmp    %eax,%edx
  800f22:	73 05                	jae    800f29 <__udivdi3+0xf9>
  800f24:	3b 34 24             	cmp    (%esp),%esi
  800f27:	74 1f                	je     800f48 <__udivdi3+0x118>
  800f29:	89 f8                	mov    %edi,%eax
  800f2b:	31 d2                	xor    %edx,%edx
  800f2d:	e9 7a ff ff ff       	jmp    800eac <__udivdi3+0x7c>
  800f32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f38:	31 d2                	xor    %edx,%edx
  800f3a:	b8 01 00 00 00       	mov    $0x1,%eax
  800f3f:	e9 68 ff ff ff       	jmp    800eac <__udivdi3+0x7c>
  800f44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f48:	8d 47 ff             	lea    -0x1(%edi),%eax
  800f4b:	31 d2                	xor    %edx,%edx
  800f4d:	83 c4 0c             	add    $0xc,%esp
  800f50:	5e                   	pop    %esi
  800f51:	5f                   	pop    %edi
  800f52:	5d                   	pop    %ebp
  800f53:	c3                   	ret    
  800f54:	66 90                	xchg   %ax,%ax
  800f56:	66 90                	xchg   %ax,%ax
  800f58:	66 90                	xchg   %ax,%ax
  800f5a:	66 90                	xchg   %ax,%ax
  800f5c:	66 90                	xchg   %ax,%ax
  800f5e:	66 90                	xchg   %ax,%ax

00800f60 <__umoddi3>:
  800f60:	55                   	push   %ebp
  800f61:	57                   	push   %edi
  800f62:	56                   	push   %esi
  800f63:	83 ec 14             	sub    $0x14,%esp
  800f66:	8b 44 24 28          	mov    0x28(%esp),%eax
  800f6a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800f6e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800f72:	89 c7                	mov    %eax,%edi
  800f74:	89 44 24 04          	mov    %eax,0x4(%esp)
  800f78:	8b 44 24 30          	mov    0x30(%esp),%eax
  800f7c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800f80:	89 34 24             	mov    %esi,(%esp)
  800f83:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800f87:	85 c0                	test   %eax,%eax
  800f89:	89 c2                	mov    %eax,%edx
  800f8b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800f8f:	75 17                	jne    800fa8 <__umoddi3+0x48>
  800f91:	39 fe                	cmp    %edi,%esi
  800f93:	76 4b                	jbe    800fe0 <__umoddi3+0x80>
  800f95:	89 c8                	mov    %ecx,%eax
  800f97:	89 fa                	mov    %edi,%edx
  800f99:	f7 f6                	div    %esi
  800f9b:	89 d0                	mov    %edx,%eax
  800f9d:	31 d2                	xor    %edx,%edx
  800f9f:	83 c4 14             	add    $0x14,%esp
  800fa2:	5e                   	pop    %esi
  800fa3:	5f                   	pop    %edi
  800fa4:	5d                   	pop    %ebp
  800fa5:	c3                   	ret    
  800fa6:	66 90                	xchg   %ax,%ax
  800fa8:	39 f8                	cmp    %edi,%eax
  800faa:	77 54                	ja     801000 <__umoddi3+0xa0>
  800fac:	0f bd e8             	bsr    %eax,%ebp
  800faf:	83 f5 1f             	xor    $0x1f,%ebp
  800fb2:	75 5c                	jne    801010 <__umoddi3+0xb0>
  800fb4:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800fb8:	39 3c 24             	cmp    %edi,(%esp)
  800fbb:	0f 87 e7 00 00 00    	ja     8010a8 <__umoddi3+0x148>
  800fc1:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800fc5:	29 f1                	sub    %esi,%ecx
  800fc7:	19 c7                	sbb    %eax,%edi
  800fc9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800fcd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800fd1:	8b 44 24 08          	mov    0x8(%esp),%eax
  800fd5:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800fd9:	83 c4 14             	add    $0x14,%esp
  800fdc:	5e                   	pop    %esi
  800fdd:	5f                   	pop    %edi
  800fde:	5d                   	pop    %ebp
  800fdf:	c3                   	ret    
  800fe0:	85 f6                	test   %esi,%esi
  800fe2:	89 f5                	mov    %esi,%ebp
  800fe4:	75 0b                	jne    800ff1 <__umoddi3+0x91>
  800fe6:	b8 01 00 00 00       	mov    $0x1,%eax
  800feb:	31 d2                	xor    %edx,%edx
  800fed:	f7 f6                	div    %esi
  800fef:	89 c5                	mov    %eax,%ebp
  800ff1:	8b 44 24 04          	mov    0x4(%esp),%eax
  800ff5:	31 d2                	xor    %edx,%edx
  800ff7:	f7 f5                	div    %ebp
  800ff9:	89 c8                	mov    %ecx,%eax
  800ffb:	f7 f5                	div    %ebp
  800ffd:	eb 9c                	jmp    800f9b <__umoddi3+0x3b>
  800fff:	90                   	nop
  801000:	89 c8                	mov    %ecx,%eax
  801002:	89 fa                	mov    %edi,%edx
  801004:	83 c4 14             	add    $0x14,%esp
  801007:	5e                   	pop    %esi
  801008:	5f                   	pop    %edi
  801009:	5d                   	pop    %ebp
  80100a:	c3                   	ret    
  80100b:	90                   	nop
  80100c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801010:	8b 04 24             	mov    (%esp),%eax
  801013:	be 20 00 00 00       	mov    $0x20,%esi
  801018:	89 e9                	mov    %ebp,%ecx
  80101a:	29 ee                	sub    %ebp,%esi
  80101c:	d3 e2                	shl    %cl,%edx
  80101e:	89 f1                	mov    %esi,%ecx
  801020:	d3 e8                	shr    %cl,%eax
  801022:	89 e9                	mov    %ebp,%ecx
  801024:	89 44 24 04          	mov    %eax,0x4(%esp)
  801028:	8b 04 24             	mov    (%esp),%eax
  80102b:	09 54 24 04          	or     %edx,0x4(%esp)
  80102f:	89 fa                	mov    %edi,%edx
  801031:	d3 e0                	shl    %cl,%eax
  801033:	89 f1                	mov    %esi,%ecx
  801035:	89 44 24 08          	mov    %eax,0x8(%esp)
  801039:	8b 44 24 10          	mov    0x10(%esp),%eax
  80103d:	d3 ea                	shr    %cl,%edx
  80103f:	89 e9                	mov    %ebp,%ecx
  801041:	d3 e7                	shl    %cl,%edi
  801043:	89 f1                	mov    %esi,%ecx
  801045:	d3 e8                	shr    %cl,%eax
  801047:	89 e9                	mov    %ebp,%ecx
  801049:	09 f8                	or     %edi,%eax
  80104b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80104f:	f7 74 24 04          	divl   0x4(%esp)
  801053:	d3 e7                	shl    %cl,%edi
  801055:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801059:	89 d7                	mov    %edx,%edi
  80105b:	f7 64 24 08          	mull   0x8(%esp)
  80105f:	39 d7                	cmp    %edx,%edi
  801061:	89 c1                	mov    %eax,%ecx
  801063:	89 14 24             	mov    %edx,(%esp)
  801066:	72 2c                	jb     801094 <__umoddi3+0x134>
  801068:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  80106c:	72 22                	jb     801090 <__umoddi3+0x130>
  80106e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801072:	29 c8                	sub    %ecx,%eax
  801074:	19 d7                	sbb    %edx,%edi
  801076:	89 e9                	mov    %ebp,%ecx
  801078:	89 fa                	mov    %edi,%edx
  80107a:	d3 e8                	shr    %cl,%eax
  80107c:	89 f1                	mov    %esi,%ecx
  80107e:	d3 e2                	shl    %cl,%edx
  801080:	89 e9                	mov    %ebp,%ecx
  801082:	d3 ef                	shr    %cl,%edi
  801084:	09 d0                	or     %edx,%eax
  801086:	89 fa                	mov    %edi,%edx
  801088:	83 c4 14             	add    $0x14,%esp
  80108b:	5e                   	pop    %esi
  80108c:	5f                   	pop    %edi
  80108d:	5d                   	pop    %ebp
  80108e:	c3                   	ret    
  80108f:	90                   	nop
  801090:	39 d7                	cmp    %edx,%edi
  801092:	75 da                	jne    80106e <__umoddi3+0x10e>
  801094:	8b 14 24             	mov    (%esp),%edx
  801097:	89 c1                	mov    %eax,%ecx
  801099:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  80109d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  8010a1:	eb cb                	jmp    80106e <__umoddi3+0x10e>
  8010a3:	90                   	nop
  8010a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8010a8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  8010ac:	0f 82 0f ff ff ff    	jb     800fc1 <__umoddi3+0x61>
  8010b2:	e9 1a ff ff ff       	jmp    800fd1 <__umoddi3+0x71>
