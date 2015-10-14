
obj/user/faultnostack:     file format elf32-i386


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
  80002c:	e8 28 00 00 00       	call   800059 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

void _pgfault_upcall();

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	sys_env_set_pgfault_upcall(0, (void*) _pgfault_upcall);
  800039:	c7 44 24 04 a1 03 80 	movl   $0x8003a1,0x4(%esp)
  800040:	00 
  800041:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800048:	e8 8c 02 00 00       	call   8002d9 <sys_env_set_pgfault_upcall>
	*(int*)0 = 0;
  80004d:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
  800054:	00 00 00 
}
  800057:	c9                   	leave  
  800058:	c3                   	ret    

00800059 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800059:	55                   	push   %ebp
  80005a:	89 e5                	mov    %esp,%ebp
  80005c:	56                   	push   %esi
  80005d:	53                   	push   %ebx
  80005e:	83 ec 10             	sub    $0x10,%esp
  800061:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800064:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800067:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  80006e:	00 00 00 
	thisenv = &envs[ENVX(sys_getenvid())]; 
  800071:	e8 d8 00 00 00       	call   80014e <sys_getenvid>
  800076:	25 ff 03 00 00       	and    $0x3ff,%eax
  80007b:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80007e:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800083:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800088:	85 db                	test   %ebx,%ebx
  80008a:	7e 07                	jle    800093 <libmain+0x3a>
		binaryname = argv[0];
  80008c:	8b 06                	mov    (%esi),%eax
  80008e:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800093:	89 74 24 04          	mov    %esi,0x4(%esp)
  800097:	89 1c 24             	mov    %ebx,(%esp)
  80009a:	e8 94 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80009f:	e8 07 00 00 00       	call   8000ab <exit>
}
  8000a4:	83 c4 10             	add    $0x10,%esp
  8000a7:	5b                   	pop    %ebx
  8000a8:	5e                   	pop    %esi
  8000a9:	5d                   	pop    %ebp
  8000aa:	c3                   	ret    

008000ab <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000ab:	55                   	push   %ebp
  8000ac:	89 e5                	mov    %esp,%ebp
  8000ae:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000b1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000b8:	e8 3f 00 00 00       	call   8000fc <sys_env_destroy>
}
  8000bd:	c9                   	leave  
  8000be:	c3                   	ret    

008000bf <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000bf:	55                   	push   %ebp
  8000c0:	89 e5                	mov    %esp,%ebp
  8000c2:	57                   	push   %edi
  8000c3:	56                   	push   %esi
  8000c4:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000c5:	b8 00 00 00 00       	mov    $0x0,%eax
  8000ca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000cd:	8b 55 08             	mov    0x8(%ebp),%edx
  8000d0:	89 c3                	mov    %eax,%ebx
  8000d2:	89 c7                	mov    %eax,%edi
  8000d4:	89 c6                	mov    %eax,%esi
  8000d6:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000d8:	5b                   	pop    %ebx
  8000d9:	5e                   	pop    %esi
  8000da:	5f                   	pop    %edi
  8000db:	5d                   	pop    %ebp
  8000dc:	c3                   	ret    

008000dd <sys_cgetc>:

int
sys_cgetc(void)
{
  8000dd:	55                   	push   %ebp
  8000de:	89 e5                	mov    %esp,%ebp
  8000e0:	57                   	push   %edi
  8000e1:	56                   	push   %esi
  8000e2:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000e3:	ba 00 00 00 00       	mov    $0x0,%edx
  8000e8:	b8 01 00 00 00       	mov    $0x1,%eax
  8000ed:	89 d1                	mov    %edx,%ecx
  8000ef:	89 d3                	mov    %edx,%ebx
  8000f1:	89 d7                	mov    %edx,%edi
  8000f3:	89 d6                	mov    %edx,%esi
  8000f5:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000f7:	5b                   	pop    %ebx
  8000f8:	5e                   	pop    %esi
  8000f9:	5f                   	pop    %edi
  8000fa:	5d                   	pop    %ebp
  8000fb:	c3                   	ret    

008000fc <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000fc:	55                   	push   %ebp
  8000fd:	89 e5                	mov    %esp,%ebp
  8000ff:	57                   	push   %edi
  800100:	56                   	push   %esi
  800101:	53                   	push   %ebx
  800102:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800105:	b9 00 00 00 00       	mov    $0x0,%ecx
  80010a:	b8 03 00 00 00       	mov    $0x3,%eax
  80010f:	8b 55 08             	mov    0x8(%ebp),%edx
  800112:	89 cb                	mov    %ecx,%ebx
  800114:	89 cf                	mov    %ecx,%edi
  800116:	89 ce                	mov    %ecx,%esi
  800118:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80011a:	85 c0                	test   %eax,%eax
  80011c:	7e 28                	jle    800146 <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  80011e:	89 44 24 10          	mov    %eax,0x10(%esp)
  800122:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800129:	00 
  80012a:	c7 44 24 08 ea 10 80 	movl   $0x8010ea,0x8(%esp)
  800131:	00 
  800132:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800139:	00 
  80013a:	c7 04 24 07 11 80 00 	movl   $0x801107,(%esp)
  800141:	e8 66 02 00 00       	call   8003ac <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800146:	83 c4 2c             	add    $0x2c,%esp
  800149:	5b                   	pop    %ebx
  80014a:	5e                   	pop    %esi
  80014b:	5f                   	pop    %edi
  80014c:	5d                   	pop    %ebp
  80014d:	c3                   	ret    

0080014e <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80014e:	55                   	push   %ebp
  80014f:	89 e5                	mov    %esp,%ebp
  800151:	57                   	push   %edi
  800152:	56                   	push   %esi
  800153:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800154:	ba 00 00 00 00       	mov    $0x0,%edx
  800159:	b8 02 00 00 00       	mov    $0x2,%eax
  80015e:	89 d1                	mov    %edx,%ecx
  800160:	89 d3                	mov    %edx,%ebx
  800162:	89 d7                	mov    %edx,%edi
  800164:	89 d6                	mov    %edx,%esi
  800166:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800168:	5b                   	pop    %ebx
  800169:	5e                   	pop    %esi
  80016a:	5f                   	pop    %edi
  80016b:	5d                   	pop    %ebp
  80016c:	c3                   	ret    

0080016d <sys_yield>:

void
sys_yield(void)
{
  80016d:	55                   	push   %ebp
  80016e:	89 e5                	mov    %esp,%ebp
  800170:	57                   	push   %edi
  800171:	56                   	push   %esi
  800172:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800173:	ba 00 00 00 00       	mov    $0x0,%edx
  800178:	b8 0a 00 00 00       	mov    $0xa,%eax
  80017d:	89 d1                	mov    %edx,%ecx
  80017f:	89 d3                	mov    %edx,%ebx
  800181:	89 d7                	mov    %edx,%edi
  800183:	89 d6                	mov    %edx,%esi
  800185:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800187:	5b                   	pop    %ebx
  800188:	5e                   	pop    %esi
  800189:	5f                   	pop    %edi
  80018a:	5d                   	pop    %ebp
  80018b:	c3                   	ret    

0080018c <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  80018c:	55                   	push   %ebp
  80018d:	89 e5                	mov    %esp,%ebp
  80018f:	57                   	push   %edi
  800190:	56                   	push   %esi
  800191:	53                   	push   %ebx
  800192:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800195:	be 00 00 00 00       	mov    $0x0,%esi
  80019a:	b8 04 00 00 00       	mov    $0x4,%eax
  80019f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8001a2:	8b 55 08             	mov    0x8(%ebp),%edx
  8001a5:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001a8:	89 f7                	mov    %esi,%edi
  8001aa:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8001ac:	85 c0                	test   %eax,%eax
  8001ae:	7e 28                	jle    8001d8 <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  8001b0:	89 44 24 10          	mov    %eax,0x10(%esp)
  8001b4:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  8001bb:	00 
  8001bc:	c7 44 24 08 ea 10 80 	movl   $0x8010ea,0x8(%esp)
  8001c3:	00 
  8001c4:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8001cb:	00 
  8001cc:	c7 04 24 07 11 80 00 	movl   $0x801107,(%esp)
  8001d3:	e8 d4 01 00 00       	call   8003ac <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  8001d8:	83 c4 2c             	add    $0x2c,%esp
  8001db:	5b                   	pop    %ebx
  8001dc:	5e                   	pop    %esi
  8001dd:	5f                   	pop    %edi
  8001de:	5d                   	pop    %ebp
  8001df:	c3                   	ret    

008001e0 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001e0:	55                   	push   %ebp
  8001e1:	89 e5                	mov    %esp,%ebp
  8001e3:	57                   	push   %edi
  8001e4:	56                   	push   %esi
  8001e5:	53                   	push   %ebx
  8001e6:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001e9:	b8 05 00 00 00       	mov    $0x5,%eax
  8001ee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8001f1:	8b 55 08             	mov    0x8(%ebp),%edx
  8001f4:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001f7:	8b 7d 14             	mov    0x14(%ebp),%edi
  8001fa:	8b 75 18             	mov    0x18(%ebp),%esi
  8001fd:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8001ff:	85 c0                	test   %eax,%eax
  800201:	7e 28                	jle    80022b <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800203:	89 44 24 10          	mov    %eax,0x10(%esp)
  800207:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  80020e:	00 
  80020f:	c7 44 24 08 ea 10 80 	movl   $0x8010ea,0x8(%esp)
  800216:	00 
  800217:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80021e:	00 
  80021f:	c7 04 24 07 11 80 00 	movl   $0x801107,(%esp)
  800226:	e8 81 01 00 00       	call   8003ac <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  80022b:	83 c4 2c             	add    $0x2c,%esp
  80022e:	5b                   	pop    %ebx
  80022f:	5e                   	pop    %esi
  800230:	5f                   	pop    %edi
  800231:	5d                   	pop    %ebp
  800232:	c3                   	ret    

00800233 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800233:	55                   	push   %ebp
  800234:	89 e5                	mov    %esp,%ebp
  800236:	57                   	push   %edi
  800237:	56                   	push   %esi
  800238:	53                   	push   %ebx
  800239:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80023c:	bb 00 00 00 00       	mov    $0x0,%ebx
  800241:	b8 06 00 00 00       	mov    $0x6,%eax
  800246:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800249:	8b 55 08             	mov    0x8(%ebp),%edx
  80024c:	89 df                	mov    %ebx,%edi
  80024e:	89 de                	mov    %ebx,%esi
  800250:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800252:	85 c0                	test   %eax,%eax
  800254:	7e 28                	jle    80027e <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800256:	89 44 24 10          	mov    %eax,0x10(%esp)
  80025a:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800261:	00 
  800262:	c7 44 24 08 ea 10 80 	movl   $0x8010ea,0x8(%esp)
  800269:	00 
  80026a:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800271:	00 
  800272:	c7 04 24 07 11 80 00 	movl   $0x801107,(%esp)
  800279:	e8 2e 01 00 00       	call   8003ac <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  80027e:	83 c4 2c             	add    $0x2c,%esp
  800281:	5b                   	pop    %ebx
  800282:	5e                   	pop    %esi
  800283:	5f                   	pop    %edi
  800284:	5d                   	pop    %ebp
  800285:	c3                   	ret    

00800286 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800286:	55                   	push   %ebp
  800287:	89 e5                	mov    %esp,%ebp
  800289:	57                   	push   %edi
  80028a:	56                   	push   %esi
  80028b:	53                   	push   %ebx
  80028c:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80028f:	bb 00 00 00 00       	mov    $0x0,%ebx
  800294:	b8 08 00 00 00       	mov    $0x8,%eax
  800299:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80029c:	8b 55 08             	mov    0x8(%ebp),%edx
  80029f:	89 df                	mov    %ebx,%edi
  8002a1:	89 de                	mov    %ebx,%esi
  8002a3:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8002a5:	85 c0                	test   %eax,%eax
  8002a7:	7e 28                	jle    8002d1 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002a9:	89 44 24 10          	mov    %eax,0x10(%esp)
  8002ad:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  8002b4:	00 
  8002b5:	c7 44 24 08 ea 10 80 	movl   $0x8010ea,0x8(%esp)
  8002bc:	00 
  8002bd:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8002c4:	00 
  8002c5:	c7 04 24 07 11 80 00 	movl   $0x801107,(%esp)
  8002cc:	e8 db 00 00 00       	call   8003ac <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  8002d1:	83 c4 2c             	add    $0x2c,%esp
  8002d4:	5b                   	pop    %ebx
  8002d5:	5e                   	pop    %esi
  8002d6:	5f                   	pop    %edi
  8002d7:	5d                   	pop    %ebp
  8002d8:	c3                   	ret    

008002d9 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  8002d9:	55                   	push   %ebp
  8002da:	89 e5                	mov    %esp,%ebp
  8002dc:	57                   	push   %edi
  8002dd:	56                   	push   %esi
  8002de:	53                   	push   %ebx
  8002df:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002e2:	bb 00 00 00 00       	mov    $0x0,%ebx
  8002e7:	b8 09 00 00 00       	mov    $0x9,%eax
  8002ec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8002ef:	8b 55 08             	mov    0x8(%ebp),%edx
  8002f2:	89 df                	mov    %ebx,%edi
  8002f4:	89 de                	mov    %ebx,%esi
  8002f6:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8002f8:	85 c0                	test   %eax,%eax
  8002fa:	7e 28                	jle    800324 <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002fc:	89 44 24 10          	mov    %eax,0x10(%esp)
  800300:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800307:	00 
  800308:	c7 44 24 08 ea 10 80 	movl   $0x8010ea,0x8(%esp)
  80030f:	00 
  800310:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800317:	00 
  800318:	c7 04 24 07 11 80 00 	movl   $0x801107,(%esp)
  80031f:	e8 88 00 00 00       	call   8003ac <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800324:	83 c4 2c             	add    $0x2c,%esp
  800327:	5b                   	pop    %ebx
  800328:	5e                   	pop    %esi
  800329:	5f                   	pop    %edi
  80032a:	5d                   	pop    %ebp
  80032b:	c3                   	ret    

0080032c <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  80032c:	55                   	push   %ebp
  80032d:	89 e5                	mov    %esp,%ebp
  80032f:	57                   	push   %edi
  800330:	56                   	push   %esi
  800331:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800332:	be 00 00 00 00       	mov    $0x0,%esi
  800337:	b8 0b 00 00 00       	mov    $0xb,%eax
  80033c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80033f:	8b 55 08             	mov    0x8(%ebp),%edx
  800342:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800345:	8b 7d 14             	mov    0x14(%ebp),%edi
  800348:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  80034a:	5b                   	pop    %ebx
  80034b:	5e                   	pop    %esi
  80034c:	5f                   	pop    %edi
  80034d:	5d                   	pop    %ebp
  80034e:	c3                   	ret    

0080034f <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  80034f:	55                   	push   %ebp
  800350:	89 e5                	mov    %esp,%ebp
  800352:	57                   	push   %edi
  800353:	56                   	push   %esi
  800354:	53                   	push   %ebx
  800355:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800358:	b9 00 00 00 00       	mov    $0x0,%ecx
  80035d:	b8 0c 00 00 00       	mov    $0xc,%eax
  800362:	8b 55 08             	mov    0x8(%ebp),%edx
  800365:	89 cb                	mov    %ecx,%ebx
  800367:	89 cf                	mov    %ecx,%edi
  800369:	89 ce                	mov    %ecx,%esi
  80036b:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80036d:	85 c0                	test   %eax,%eax
  80036f:	7e 28                	jle    800399 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800371:	89 44 24 10          	mov    %eax,0x10(%esp)
  800375:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  80037c:	00 
  80037d:	c7 44 24 08 ea 10 80 	movl   $0x8010ea,0x8(%esp)
  800384:	00 
  800385:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80038c:	00 
  80038d:	c7 04 24 07 11 80 00 	movl   $0x801107,(%esp)
  800394:	e8 13 00 00 00       	call   8003ac <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800399:	83 c4 2c             	add    $0x2c,%esp
  80039c:	5b                   	pop    %ebx
  80039d:	5e                   	pop    %esi
  80039e:	5f                   	pop    %edi
  80039f:	5d                   	pop    %ebp
  8003a0:	c3                   	ret    

008003a1 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  8003a1:	54                   	push   %esp
	movl _pgfault_handler, %eax
  8003a2:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  8003a7:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  8003a9:	83 c4 04             	add    $0x4,%esp

008003ac <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8003ac:	55                   	push   %ebp
  8003ad:	89 e5                	mov    %esp,%ebp
  8003af:	56                   	push   %esi
  8003b0:	53                   	push   %ebx
  8003b1:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8003b4:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8003b7:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8003bd:	e8 8c fd ff ff       	call   80014e <sys_getenvid>
  8003c2:	8b 55 0c             	mov    0xc(%ebp),%edx
  8003c5:	89 54 24 10          	mov    %edx,0x10(%esp)
  8003c9:	8b 55 08             	mov    0x8(%ebp),%edx
  8003cc:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8003d0:	89 74 24 08          	mov    %esi,0x8(%esp)
  8003d4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003d8:	c7 04 24 18 11 80 00 	movl   $0x801118,(%esp)
  8003df:	e8 c1 00 00 00       	call   8004a5 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8003e4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8003e8:	8b 45 10             	mov    0x10(%ebp),%eax
  8003eb:	89 04 24             	mov    %eax,(%esp)
  8003ee:	e8 51 00 00 00       	call   800444 <vcprintf>
	cprintf("\n");
  8003f3:	c7 04 24 3b 11 80 00 	movl   $0x80113b,(%esp)
  8003fa:	e8 a6 00 00 00       	call   8004a5 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8003ff:	cc                   	int3   
  800400:	eb fd                	jmp    8003ff <_panic+0x53>

00800402 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800402:	55                   	push   %ebp
  800403:	89 e5                	mov    %esp,%ebp
  800405:	53                   	push   %ebx
  800406:	83 ec 14             	sub    $0x14,%esp
  800409:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80040c:	8b 13                	mov    (%ebx),%edx
  80040e:	8d 42 01             	lea    0x1(%edx),%eax
  800411:	89 03                	mov    %eax,(%ebx)
  800413:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800416:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80041a:	3d ff 00 00 00       	cmp    $0xff,%eax
  80041f:	75 19                	jne    80043a <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800421:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800428:	00 
  800429:	8d 43 08             	lea    0x8(%ebx),%eax
  80042c:	89 04 24             	mov    %eax,(%esp)
  80042f:	e8 8b fc ff ff       	call   8000bf <sys_cputs>
		b->idx = 0;
  800434:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  80043a:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80043e:	83 c4 14             	add    $0x14,%esp
  800441:	5b                   	pop    %ebx
  800442:	5d                   	pop    %ebp
  800443:	c3                   	ret    

00800444 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800444:	55                   	push   %ebp
  800445:	89 e5                	mov    %esp,%ebp
  800447:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80044d:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800454:	00 00 00 
	b.cnt = 0;
  800457:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80045e:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800461:	8b 45 0c             	mov    0xc(%ebp),%eax
  800464:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800468:	8b 45 08             	mov    0x8(%ebp),%eax
  80046b:	89 44 24 08          	mov    %eax,0x8(%esp)
  80046f:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800475:	89 44 24 04          	mov    %eax,0x4(%esp)
  800479:	c7 04 24 02 04 80 00 	movl   $0x800402,(%esp)
  800480:	e8 a9 01 00 00       	call   80062e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800485:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  80048b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80048f:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800495:	89 04 24             	mov    %eax,(%esp)
  800498:	e8 22 fc ff ff       	call   8000bf <sys_cputs>

	return b.cnt;
}
  80049d:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8004a3:	c9                   	leave  
  8004a4:	c3                   	ret    

008004a5 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8004a5:	55                   	push   %ebp
  8004a6:	89 e5                	mov    %esp,%ebp
  8004a8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8004ab:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8004ae:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004b2:	8b 45 08             	mov    0x8(%ebp),%eax
  8004b5:	89 04 24             	mov    %eax,(%esp)
  8004b8:	e8 87 ff ff ff       	call   800444 <vcprintf>
	va_end(ap);

	return cnt;
}
  8004bd:	c9                   	leave  
  8004be:	c3                   	ret    
  8004bf:	90                   	nop

008004c0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8004c0:	55                   	push   %ebp
  8004c1:	89 e5                	mov    %esp,%ebp
  8004c3:	57                   	push   %edi
  8004c4:	56                   	push   %esi
  8004c5:	53                   	push   %ebx
  8004c6:	83 ec 3c             	sub    $0x3c,%esp
  8004c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8004cc:	89 d7                	mov    %edx,%edi
  8004ce:	8b 45 08             	mov    0x8(%ebp),%eax
  8004d1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004d4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8004d7:	89 c3                	mov    %eax,%ebx
  8004d9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8004dc:	8b 45 10             	mov    0x10(%ebp),%eax
  8004df:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8004e2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8004e7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004ea:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8004ed:	39 d9                	cmp    %ebx,%ecx
  8004ef:	72 05                	jb     8004f6 <printnum+0x36>
  8004f1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8004f4:	77 69                	ja     80055f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8004f6:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8004f9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8004fd:	83 ee 01             	sub    $0x1,%esi
  800500:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800504:	89 44 24 08          	mov    %eax,0x8(%esp)
  800508:	8b 44 24 08          	mov    0x8(%esp),%eax
  80050c:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800510:	89 c3                	mov    %eax,%ebx
  800512:	89 d6                	mov    %edx,%esi
  800514:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800517:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80051a:	89 54 24 08          	mov    %edx,0x8(%esp)
  80051e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800522:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800525:	89 04 24             	mov    %eax,(%esp)
  800528:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80052b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80052f:	e8 1c 09 00 00       	call   800e50 <__udivdi3>
  800534:	89 d9                	mov    %ebx,%ecx
  800536:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80053a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80053e:	89 04 24             	mov    %eax,(%esp)
  800541:	89 54 24 04          	mov    %edx,0x4(%esp)
  800545:	89 fa                	mov    %edi,%edx
  800547:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80054a:	e8 71 ff ff ff       	call   8004c0 <printnum>
  80054f:	eb 1b                	jmp    80056c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800551:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800555:	8b 45 18             	mov    0x18(%ebp),%eax
  800558:	89 04 24             	mov    %eax,(%esp)
  80055b:	ff d3                	call   *%ebx
  80055d:	eb 03                	jmp    800562 <printnum+0xa2>
  80055f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800562:	83 ee 01             	sub    $0x1,%esi
  800565:	85 f6                	test   %esi,%esi
  800567:	7f e8                	jg     800551 <printnum+0x91>
  800569:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80056c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800570:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800574:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800577:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80057a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80057e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800582:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800585:	89 04 24             	mov    %eax,(%esp)
  800588:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80058b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80058f:	e8 ec 09 00 00       	call   800f80 <__umoddi3>
  800594:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800598:	0f be 80 3d 11 80 00 	movsbl 0x80113d(%eax),%eax
  80059f:	89 04 24             	mov    %eax,(%esp)
  8005a2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8005a5:	ff d0                	call   *%eax
}
  8005a7:	83 c4 3c             	add    $0x3c,%esp
  8005aa:	5b                   	pop    %ebx
  8005ab:	5e                   	pop    %esi
  8005ac:	5f                   	pop    %edi
  8005ad:	5d                   	pop    %ebp
  8005ae:	c3                   	ret    

008005af <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8005af:	55                   	push   %ebp
  8005b0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8005b2:	83 fa 01             	cmp    $0x1,%edx
  8005b5:	7e 0e                	jle    8005c5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8005b7:	8b 10                	mov    (%eax),%edx
  8005b9:	8d 4a 08             	lea    0x8(%edx),%ecx
  8005bc:	89 08                	mov    %ecx,(%eax)
  8005be:	8b 02                	mov    (%edx),%eax
  8005c0:	8b 52 04             	mov    0x4(%edx),%edx
  8005c3:	eb 22                	jmp    8005e7 <getuint+0x38>
	else if (lflag)
  8005c5:	85 d2                	test   %edx,%edx
  8005c7:	74 10                	je     8005d9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8005c9:	8b 10                	mov    (%eax),%edx
  8005cb:	8d 4a 04             	lea    0x4(%edx),%ecx
  8005ce:	89 08                	mov    %ecx,(%eax)
  8005d0:	8b 02                	mov    (%edx),%eax
  8005d2:	ba 00 00 00 00       	mov    $0x0,%edx
  8005d7:	eb 0e                	jmp    8005e7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8005d9:	8b 10                	mov    (%eax),%edx
  8005db:	8d 4a 04             	lea    0x4(%edx),%ecx
  8005de:	89 08                	mov    %ecx,(%eax)
  8005e0:	8b 02                	mov    (%edx),%eax
  8005e2:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8005e7:	5d                   	pop    %ebp
  8005e8:	c3                   	ret    

008005e9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8005e9:	55                   	push   %ebp
  8005ea:	89 e5                	mov    %esp,%ebp
  8005ec:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8005ef:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8005f3:	8b 10                	mov    (%eax),%edx
  8005f5:	3b 50 04             	cmp    0x4(%eax),%edx
  8005f8:	73 0a                	jae    800604 <sprintputch+0x1b>
		*b->buf++ = ch;
  8005fa:	8d 4a 01             	lea    0x1(%edx),%ecx
  8005fd:	89 08                	mov    %ecx,(%eax)
  8005ff:	8b 45 08             	mov    0x8(%ebp),%eax
  800602:	88 02                	mov    %al,(%edx)
}
  800604:	5d                   	pop    %ebp
  800605:	c3                   	ret    

00800606 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800606:	55                   	push   %ebp
  800607:	89 e5                	mov    %esp,%ebp
  800609:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  80060c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80060f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800613:	8b 45 10             	mov    0x10(%ebp),%eax
  800616:	89 44 24 08          	mov    %eax,0x8(%esp)
  80061a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80061d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800621:	8b 45 08             	mov    0x8(%ebp),%eax
  800624:	89 04 24             	mov    %eax,(%esp)
  800627:	e8 02 00 00 00       	call   80062e <vprintfmt>
	va_end(ap);
}
  80062c:	c9                   	leave  
  80062d:	c3                   	ret    

0080062e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80062e:	55                   	push   %ebp
  80062f:	89 e5                	mov    %esp,%ebp
  800631:	57                   	push   %edi
  800632:	56                   	push   %esi
  800633:	53                   	push   %ebx
  800634:	83 ec 3c             	sub    $0x3c,%esp
  800637:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80063a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80063d:	eb 14                	jmp    800653 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80063f:	85 c0                	test   %eax,%eax
  800641:	0f 84 b3 03 00 00    	je     8009fa <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800647:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80064b:	89 04 24             	mov    %eax,(%esp)
  80064e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800651:	89 f3                	mov    %esi,%ebx
  800653:	8d 73 01             	lea    0x1(%ebx),%esi
  800656:	0f b6 03             	movzbl (%ebx),%eax
  800659:	83 f8 25             	cmp    $0x25,%eax
  80065c:	75 e1                	jne    80063f <vprintfmt+0x11>
  80065e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800662:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800669:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800670:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800677:	ba 00 00 00 00       	mov    $0x0,%edx
  80067c:	eb 1d                	jmp    80069b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80067e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  800680:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800684:	eb 15                	jmp    80069b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800686:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800688:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80068c:	eb 0d                	jmp    80069b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80068e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800691:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800694:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80069b:	8d 5e 01             	lea    0x1(%esi),%ebx
  80069e:	0f b6 0e             	movzbl (%esi),%ecx
  8006a1:	0f b6 c1             	movzbl %cl,%eax
  8006a4:	83 e9 23             	sub    $0x23,%ecx
  8006a7:	80 f9 55             	cmp    $0x55,%cl
  8006aa:	0f 87 2a 03 00 00    	ja     8009da <vprintfmt+0x3ac>
  8006b0:	0f b6 c9             	movzbl %cl,%ecx
  8006b3:	ff 24 8d 00 12 80 00 	jmp    *0x801200(,%ecx,4)
  8006ba:	89 de                	mov    %ebx,%esi
  8006bc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8006c1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  8006c4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  8006c8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8006cb:	8d 58 d0             	lea    -0x30(%eax),%ebx
  8006ce:	83 fb 09             	cmp    $0x9,%ebx
  8006d1:	77 36                	ja     800709 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8006d3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8006d6:	eb e9                	jmp    8006c1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8006d8:	8b 45 14             	mov    0x14(%ebp),%eax
  8006db:	8d 48 04             	lea    0x4(%eax),%ecx
  8006de:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8006e1:	8b 00                	mov    (%eax),%eax
  8006e3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006e6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8006e8:	eb 22                	jmp    80070c <vprintfmt+0xde>
  8006ea:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8006ed:	85 c9                	test   %ecx,%ecx
  8006ef:	b8 00 00 00 00       	mov    $0x0,%eax
  8006f4:	0f 49 c1             	cmovns %ecx,%eax
  8006f7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006fa:	89 de                	mov    %ebx,%esi
  8006fc:	eb 9d                	jmp    80069b <vprintfmt+0x6d>
  8006fe:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800700:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  800707:	eb 92                	jmp    80069b <vprintfmt+0x6d>
  800709:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  80070c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800710:	79 89                	jns    80069b <vprintfmt+0x6d>
  800712:	e9 77 ff ff ff       	jmp    80068e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800717:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80071a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80071c:	e9 7a ff ff ff       	jmp    80069b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800721:	8b 45 14             	mov    0x14(%ebp),%eax
  800724:	8d 50 04             	lea    0x4(%eax),%edx
  800727:	89 55 14             	mov    %edx,0x14(%ebp)
  80072a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80072e:	8b 00                	mov    (%eax),%eax
  800730:	89 04 24             	mov    %eax,(%esp)
  800733:	ff 55 08             	call   *0x8(%ebp)
			break;
  800736:	e9 18 ff ff ff       	jmp    800653 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80073b:	8b 45 14             	mov    0x14(%ebp),%eax
  80073e:	8d 50 04             	lea    0x4(%eax),%edx
  800741:	89 55 14             	mov    %edx,0x14(%ebp)
  800744:	8b 00                	mov    (%eax),%eax
  800746:	99                   	cltd   
  800747:	31 d0                	xor    %edx,%eax
  800749:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80074b:	83 f8 09             	cmp    $0x9,%eax
  80074e:	7f 0b                	jg     80075b <vprintfmt+0x12d>
  800750:	8b 14 85 60 13 80 00 	mov    0x801360(,%eax,4),%edx
  800757:	85 d2                	test   %edx,%edx
  800759:	75 20                	jne    80077b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80075b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80075f:	c7 44 24 08 55 11 80 	movl   $0x801155,0x8(%esp)
  800766:	00 
  800767:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80076b:	8b 45 08             	mov    0x8(%ebp),%eax
  80076e:	89 04 24             	mov    %eax,(%esp)
  800771:	e8 90 fe ff ff       	call   800606 <printfmt>
  800776:	e9 d8 fe ff ff       	jmp    800653 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80077b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80077f:	c7 44 24 08 5e 11 80 	movl   $0x80115e,0x8(%esp)
  800786:	00 
  800787:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80078b:	8b 45 08             	mov    0x8(%ebp),%eax
  80078e:	89 04 24             	mov    %eax,(%esp)
  800791:	e8 70 fe ff ff       	call   800606 <printfmt>
  800796:	e9 b8 fe ff ff       	jmp    800653 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80079b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80079e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8007a1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8007a4:	8b 45 14             	mov    0x14(%ebp),%eax
  8007a7:	8d 50 04             	lea    0x4(%eax),%edx
  8007aa:	89 55 14             	mov    %edx,0x14(%ebp)
  8007ad:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  8007af:	85 f6                	test   %esi,%esi
  8007b1:	b8 4e 11 80 00       	mov    $0x80114e,%eax
  8007b6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  8007b9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  8007bd:	0f 84 97 00 00 00    	je     80085a <vprintfmt+0x22c>
  8007c3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  8007c7:	0f 8e 9b 00 00 00    	jle    800868 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  8007cd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8007d1:	89 34 24             	mov    %esi,(%esp)
  8007d4:	e8 cf 02 00 00       	call   800aa8 <strnlen>
  8007d9:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8007dc:	29 c2                	sub    %eax,%edx
  8007de:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  8007e1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8007e5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8007e8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8007eb:	8b 75 08             	mov    0x8(%ebp),%esi
  8007ee:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8007f1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8007f3:	eb 0f                	jmp    800804 <vprintfmt+0x1d6>
					putch(padc, putdat);
  8007f5:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007f9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8007fc:	89 04 24             	mov    %eax,(%esp)
  8007ff:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800801:	83 eb 01             	sub    $0x1,%ebx
  800804:	85 db                	test   %ebx,%ebx
  800806:	7f ed                	jg     8007f5 <vprintfmt+0x1c7>
  800808:	8b 75 d8             	mov    -0x28(%ebp),%esi
  80080b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80080e:	85 d2                	test   %edx,%edx
  800810:	b8 00 00 00 00       	mov    $0x0,%eax
  800815:	0f 49 c2             	cmovns %edx,%eax
  800818:	29 c2                	sub    %eax,%edx
  80081a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80081d:	89 d7                	mov    %edx,%edi
  80081f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800822:	eb 50                	jmp    800874 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800824:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800828:	74 1e                	je     800848 <vprintfmt+0x21a>
  80082a:	0f be d2             	movsbl %dl,%edx
  80082d:	83 ea 20             	sub    $0x20,%edx
  800830:	83 fa 5e             	cmp    $0x5e,%edx
  800833:	76 13                	jbe    800848 <vprintfmt+0x21a>
					putch('?', putdat);
  800835:	8b 45 0c             	mov    0xc(%ebp),%eax
  800838:	89 44 24 04          	mov    %eax,0x4(%esp)
  80083c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800843:	ff 55 08             	call   *0x8(%ebp)
  800846:	eb 0d                	jmp    800855 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800848:	8b 55 0c             	mov    0xc(%ebp),%edx
  80084b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80084f:	89 04 24             	mov    %eax,(%esp)
  800852:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800855:	83 ef 01             	sub    $0x1,%edi
  800858:	eb 1a                	jmp    800874 <vprintfmt+0x246>
  80085a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80085d:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800860:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800863:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800866:	eb 0c                	jmp    800874 <vprintfmt+0x246>
  800868:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80086b:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80086e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800871:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800874:	83 c6 01             	add    $0x1,%esi
  800877:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80087b:	0f be c2             	movsbl %dl,%eax
  80087e:	85 c0                	test   %eax,%eax
  800880:	74 27                	je     8008a9 <vprintfmt+0x27b>
  800882:	85 db                	test   %ebx,%ebx
  800884:	78 9e                	js     800824 <vprintfmt+0x1f6>
  800886:	83 eb 01             	sub    $0x1,%ebx
  800889:	79 99                	jns    800824 <vprintfmt+0x1f6>
  80088b:	89 f8                	mov    %edi,%eax
  80088d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800890:	8b 75 08             	mov    0x8(%ebp),%esi
  800893:	89 c3                	mov    %eax,%ebx
  800895:	eb 1a                	jmp    8008b1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800897:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80089b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8008a2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8008a4:	83 eb 01             	sub    $0x1,%ebx
  8008a7:	eb 08                	jmp    8008b1 <vprintfmt+0x283>
  8008a9:	89 fb                	mov    %edi,%ebx
  8008ab:	8b 75 08             	mov    0x8(%ebp),%esi
  8008ae:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8008b1:	85 db                	test   %ebx,%ebx
  8008b3:	7f e2                	jg     800897 <vprintfmt+0x269>
  8008b5:	89 75 08             	mov    %esi,0x8(%ebp)
  8008b8:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8008bb:	e9 93 fd ff ff       	jmp    800653 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8008c0:	83 fa 01             	cmp    $0x1,%edx
  8008c3:	7e 16                	jle    8008db <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  8008c5:	8b 45 14             	mov    0x14(%ebp),%eax
  8008c8:	8d 50 08             	lea    0x8(%eax),%edx
  8008cb:	89 55 14             	mov    %edx,0x14(%ebp)
  8008ce:	8b 50 04             	mov    0x4(%eax),%edx
  8008d1:	8b 00                	mov    (%eax),%eax
  8008d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8008d6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8008d9:	eb 32                	jmp    80090d <vprintfmt+0x2df>
	else if (lflag)
  8008db:	85 d2                	test   %edx,%edx
  8008dd:	74 18                	je     8008f7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  8008df:	8b 45 14             	mov    0x14(%ebp),%eax
  8008e2:	8d 50 04             	lea    0x4(%eax),%edx
  8008e5:	89 55 14             	mov    %edx,0x14(%ebp)
  8008e8:	8b 30                	mov    (%eax),%esi
  8008ea:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8008ed:	89 f0                	mov    %esi,%eax
  8008ef:	c1 f8 1f             	sar    $0x1f,%eax
  8008f2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8008f5:	eb 16                	jmp    80090d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  8008f7:	8b 45 14             	mov    0x14(%ebp),%eax
  8008fa:	8d 50 04             	lea    0x4(%eax),%edx
  8008fd:	89 55 14             	mov    %edx,0x14(%ebp)
  800900:	8b 30                	mov    (%eax),%esi
  800902:	89 75 e0             	mov    %esi,-0x20(%ebp)
  800905:	89 f0                	mov    %esi,%eax
  800907:	c1 f8 1f             	sar    $0x1f,%eax
  80090a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80090d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800910:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800913:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800918:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80091c:	0f 89 80 00 00 00    	jns    8009a2 <vprintfmt+0x374>
				putch('-', putdat);
  800922:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800926:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80092d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800930:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800933:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800936:	f7 d8                	neg    %eax
  800938:	83 d2 00             	adc    $0x0,%edx
  80093b:	f7 da                	neg    %edx
			}
			base = 10;
  80093d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800942:	eb 5e                	jmp    8009a2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800944:	8d 45 14             	lea    0x14(%ebp),%eax
  800947:	e8 63 fc ff ff       	call   8005af <getuint>
			base = 10;
  80094c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800951:	eb 4f                	jmp    8009a2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800953:	8d 45 14             	lea    0x14(%ebp),%eax
  800956:	e8 54 fc ff ff       	call   8005af <getuint>
			base = 8;
  80095b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800960:	eb 40                	jmp    8009a2 <vprintfmt+0x374>
			
		// pointer
		case 'p':
			putch('0', putdat);
  800962:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800966:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80096d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800970:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800974:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80097b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80097e:	8b 45 14             	mov    0x14(%ebp),%eax
  800981:	8d 50 04             	lea    0x4(%eax),%edx
  800984:	89 55 14             	mov    %edx,0x14(%ebp)
			
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800987:	8b 00                	mov    (%eax),%eax
  800989:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80098e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800993:	eb 0d                	jmp    8009a2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800995:	8d 45 14             	lea    0x14(%ebp),%eax
  800998:	e8 12 fc ff ff       	call   8005af <getuint>
			base = 16;
  80099d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8009a2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  8009a6:	89 74 24 10          	mov    %esi,0x10(%esp)
  8009aa:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8009ad:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8009b1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8009b5:	89 04 24             	mov    %eax,(%esp)
  8009b8:	89 54 24 04          	mov    %edx,0x4(%esp)
  8009bc:	89 fa                	mov    %edi,%edx
  8009be:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c1:	e8 fa fa ff ff       	call   8004c0 <printnum>
			break;
  8009c6:	e9 88 fc ff ff       	jmp    800653 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8009cb:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8009cf:	89 04 24             	mov    %eax,(%esp)
  8009d2:	ff 55 08             	call   *0x8(%ebp)
			break;
  8009d5:	e9 79 fc ff ff       	jmp    800653 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8009da:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8009de:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8009e5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8009e8:	89 f3                	mov    %esi,%ebx
  8009ea:	eb 03                	jmp    8009ef <vprintfmt+0x3c1>
  8009ec:	83 eb 01             	sub    $0x1,%ebx
  8009ef:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8009f3:	75 f7                	jne    8009ec <vprintfmt+0x3be>
  8009f5:	e9 59 fc ff ff       	jmp    800653 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8009fa:	83 c4 3c             	add    $0x3c,%esp
  8009fd:	5b                   	pop    %ebx
  8009fe:	5e                   	pop    %esi
  8009ff:	5f                   	pop    %edi
  800a00:	5d                   	pop    %ebp
  800a01:	c3                   	ret    

00800a02 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800a02:	55                   	push   %ebp
  800a03:	89 e5                	mov    %esp,%ebp
  800a05:	83 ec 28             	sub    $0x28,%esp
  800a08:	8b 45 08             	mov    0x8(%ebp),%eax
  800a0b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800a0e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800a11:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800a15:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800a18:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800a1f:	85 c0                	test   %eax,%eax
  800a21:	74 30                	je     800a53 <vsnprintf+0x51>
  800a23:	85 d2                	test   %edx,%edx
  800a25:	7e 2c                	jle    800a53 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800a27:	8b 45 14             	mov    0x14(%ebp),%eax
  800a2a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800a2e:	8b 45 10             	mov    0x10(%ebp),%eax
  800a31:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a35:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800a38:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a3c:	c7 04 24 e9 05 80 00 	movl   $0x8005e9,(%esp)
  800a43:	e8 e6 fb ff ff       	call   80062e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800a48:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800a4b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800a4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800a51:	eb 05                	jmp    800a58 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800a53:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800a58:	c9                   	leave  
  800a59:	c3                   	ret    

00800a5a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800a5a:	55                   	push   %ebp
  800a5b:	89 e5                	mov    %esp,%ebp
  800a5d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800a60:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800a63:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800a67:	8b 45 10             	mov    0x10(%ebp),%eax
  800a6a:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a6e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a71:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a75:	8b 45 08             	mov    0x8(%ebp),%eax
  800a78:	89 04 24             	mov    %eax,(%esp)
  800a7b:	e8 82 ff ff ff       	call   800a02 <vsnprintf>
	va_end(ap);

	return rc;
}
  800a80:	c9                   	leave  
  800a81:	c3                   	ret    
  800a82:	66 90                	xchg   %ax,%ax
  800a84:	66 90                	xchg   %ax,%ax
  800a86:	66 90                	xchg   %ax,%ax
  800a88:	66 90                	xchg   %ax,%ax
  800a8a:	66 90                	xchg   %ax,%ax
  800a8c:	66 90                	xchg   %ax,%ax
  800a8e:	66 90                	xchg   %ax,%ax

00800a90 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800a90:	55                   	push   %ebp
  800a91:	89 e5                	mov    %esp,%ebp
  800a93:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800a96:	b8 00 00 00 00       	mov    $0x0,%eax
  800a9b:	eb 03                	jmp    800aa0 <strlen+0x10>
		n++;
  800a9d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800aa0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800aa4:	75 f7                	jne    800a9d <strlen+0xd>
		n++;
	return n;
}
  800aa6:	5d                   	pop    %ebp
  800aa7:	c3                   	ret    

00800aa8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800aa8:	55                   	push   %ebp
  800aa9:	89 e5                	mov    %esp,%ebp
  800aab:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800aae:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800ab1:	b8 00 00 00 00       	mov    $0x0,%eax
  800ab6:	eb 03                	jmp    800abb <strnlen+0x13>
		n++;
  800ab8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800abb:	39 d0                	cmp    %edx,%eax
  800abd:	74 06                	je     800ac5 <strnlen+0x1d>
  800abf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800ac3:	75 f3                	jne    800ab8 <strnlen+0x10>
		n++;
	return n;
}
  800ac5:	5d                   	pop    %ebp
  800ac6:	c3                   	ret    

00800ac7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800ac7:	55                   	push   %ebp
  800ac8:	89 e5                	mov    %esp,%ebp
  800aca:	53                   	push   %ebx
  800acb:	8b 45 08             	mov    0x8(%ebp),%eax
  800ace:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800ad1:	89 c2                	mov    %eax,%edx
  800ad3:	83 c2 01             	add    $0x1,%edx
  800ad6:	83 c1 01             	add    $0x1,%ecx
  800ad9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800add:	88 5a ff             	mov    %bl,-0x1(%edx)
  800ae0:	84 db                	test   %bl,%bl
  800ae2:	75 ef                	jne    800ad3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800ae4:	5b                   	pop    %ebx
  800ae5:	5d                   	pop    %ebp
  800ae6:	c3                   	ret    

00800ae7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800ae7:	55                   	push   %ebp
  800ae8:	89 e5                	mov    %esp,%ebp
  800aea:	53                   	push   %ebx
  800aeb:	83 ec 08             	sub    $0x8,%esp
  800aee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800af1:	89 1c 24             	mov    %ebx,(%esp)
  800af4:	e8 97 ff ff ff       	call   800a90 <strlen>
	strcpy(dst + len, src);
  800af9:	8b 55 0c             	mov    0xc(%ebp),%edx
  800afc:	89 54 24 04          	mov    %edx,0x4(%esp)
  800b00:	01 d8                	add    %ebx,%eax
  800b02:	89 04 24             	mov    %eax,(%esp)
  800b05:	e8 bd ff ff ff       	call   800ac7 <strcpy>
	return dst;
}
  800b0a:	89 d8                	mov    %ebx,%eax
  800b0c:	83 c4 08             	add    $0x8,%esp
  800b0f:	5b                   	pop    %ebx
  800b10:	5d                   	pop    %ebp
  800b11:	c3                   	ret    

00800b12 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800b12:	55                   	push   %ebp
  800b13:	89 e5                	mov    %esp,%ebp
  800b15:	56                   	push   %esi
  800b16:	53                   	push   %ebx
  800b17:	8b 75 08             	mov    0x8(%ebp),%esi
  800b1a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b1d:	89 f3                	mov    %esi,%ebx
  800b1f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800b22:	89 f2                	mov    %esi,%edx
  800b24:	eb 0f                	jmp    800b35 <strncpy+0x23>
		*dst++ = *src;
  800b26:	83 c2 01             	add    $0x1,%edx
  800b29:	0f b6 01             	movzbl (%ecx),%eax
  800b2c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800b2f:	80 39 01             	cmpb   $0x1,(%ecx)
  800b32:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800b35:	39 da                	cmp    %ebx,%edx
  800b37:	75 ed                	jne    800b26 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800b39:	89 f0                	mov    %esi,%eax
  800b3b:	5b                   	pop    %ebx
  800b3c:	5e                   	pop    %esi
  800b3d:	5d                   	pop    %ebp
  800b3e:	c3                   	ret    

00800b3f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800b3f:	55                   	push   %ebp
  800b40:	89 e5                	mov    %esp,%ebp
  800b42:	56                   	push   %esi
  800b43:	53                   	push   %ebx
  800b44:	8b 75 08             	mov    0x8(%ebp),%esi
  800b47:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b4a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800b4d:	89 f0                	mov    %esi,%eax
  800b4f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800b53:	85 c9                	test   %ecx,%ecx
  800b55:	75 0b                	jne    800b62 <strlcpy+0x23>
  800b57:	eb 1d                	jmp    800b76 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800b59:	83 c0 01             	add    $0x1,%eax
  800b5c:	83 c2 01             	add    $0x1,%edx
  800b5f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800b62:	39 d8                	cmp    %ebx,%eax
  800b64:	74 0b                	je     800b71 <strlcpy+0x32>
  800b66:	0f b6 0a             	movzbl (%edx),%ecx
  800b69:	84 c9                	test   %cl,%cl
  800b6b:	75 ec                	jne    800b59 <strlcpy+0x1a>
  800b6d:	89 c2                	mov    %eax,%edx
  800b6f:	eb 02                	jmp    800b73 <strlcpy+0x34>
  800b71:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800b73:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800b76:	29 f0                	sub    %esi,%eax
}
  800b78:	5b                   	pop    %ebx
  800b79:	5e                   	pop    %esi
  800b7a:	5d                   	pop    %ebp
  800b7b:	c3                   	ret    

00800b7c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800b7c:	55                   	push   %ebp
  800b7d:	89 e5                	mov    %esp,%ebp
  800b7f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b82:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800b85:	eb 06                	jmp    800b8d <strcmp+0x11>
		p++, q++;
  800b87:	83 c1 01             	add    $0x1,%ecx
  800b8a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800b8d:	0f b6 01             	movzbl (%ecx),%eax
  800b90:	84 c0                	test   %al,%al
  800b92:	74 04                	je     800b98 <strcmp+0x1c>
  800b94:	3a 02                	cmp    (%edx),%al
  800b96:	74 ef                	je     800b87 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800b98:	0f b6 c0             	movzbl %al,%eax
  800b9b:	0f b6 12             	movzbl (%edx),%edx
  800b9e:	29 d0                	sub    %edx,%eax
}
  800ba0:	5d                   	pop    %ebp
  800ba1:	c3                   	ret    

00800ba2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800ba2:	55                   	push   %ebp
  800ba3:	89 e5                	mov    %esp,%ebp
  800ba5:	53                   	push   %ebx
  800ba6:	8b 45 08             	mov    0x8(%ebp),%eax
  800ba9:	8b 55 0c             	mov    0xc(%ebp),%edx
  800bac:	89 c3                	mov    %eax,%ebx
  800bae:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800bb1:	eb 06                	jmp    800bb9 <strncmp+0x17>
		n--, p++, q++;
  800bb3:	83 c0 01             	add    $0x1,%eax
  800bb6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800bb9:	39 d8                	cmp    %ebx,%eax
  800bbb:	74 15                	je     800bd2 <strncmp+0x30>
  800bbd:	0f b6 08             	movzbl (%eax),%ecx
  800bc0:	84 c9                	test   %cl,%cl
  800bc2:	74 04                	je     800bc8 <strncmp+0x26>
  800bc4:	3a 0a                	cmp    (%edx),%cl
  800bc6:	74 eb                	je     800bb3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800bc8:	0f b6 00             	movzbl (%eax),%eax
  800bcb:	0f b6 12             	movzbl (%edx),%edx
  800bce:	29 d0                	sub    %edx,%eax
  800bd0:	eb 05                	jmp    800bd7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800bd2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800bd7:	5b                   	pop    %ebx
  800bd8:	5d                   	pop    %ebp
  800bd9:	c3                   	ret    

00800bda <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800bda:	55                   	push   %ebp
  800bdb:	89 e5                	mov    %esp,%ebp
  800bdd:	8b 45 08             	mov    0x8(%ebp),%eax
  800be0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800be4:	eb 07                	jmp    800bed <strchr+0x13>
		if (*s == c)
  800be6:	38 ca                	cmp    %cl,%dl
  800be8:	74 0f                	je     800bf9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800bea:	83 c0 01             	add    $0x1,%eax
  800bed:	0f b6 10             	movzbl (%eax),%edx
  800bf0:	84 d2                	test   %dl,%dl
  800bf2:	75 f2                	jne    800be6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800bf4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800bf9:	5d                   	pop    %ebp
  800bfa:	c3                   	ret    

00800bfb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800bfb:	55                   	push   %ebp
  800bfc:	89 e5                	mov    %esp,%ebp
  800bfe:	8b 45 08             	mov    0x8(%ebp),%eax
  800c01:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800c05:	eb 07                	jmp    800c0e <strfind+0x13>
		if (*s == c)
  800c07:	38 ca                	cmp    %cl,%dl
  800c09:	74 0a                	je     800c15 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800c0b:	83 c0 01             	add    $0x1,%eax
  800c0e:	0f b6 10             	movzbl (%eax),%edx
  800c11:	84 d2                	test   %dl,%dl
  800c13:	75 f2                	jne    800c07 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800c15:	5d                   	pop    %ebp
  800c16:	c3                   	ret    

00800c17 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800c17:	55                   	push   %ebp
  800c18:	89 e5                	mov    %esp,%ebp
  800c1a:	57                   	push   %edi
  800c1b:	56                   	push   %esi
  800c1c:	53                   	push   %ebx
  800c1d:	8b 7d 08             	mov    0x8(%ebp),%edi
  800c20:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800c23:	85 c9                	test   %ecx,%ecx
  800c25:	74 36                	je     800c5d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800c27:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800c2d:	75 28                	jne    800c57 <memset+0x40>
  800c2f:	f6 c1 03             	test   $0x3,%cl
  800c32:	75 23                	jne    800c57 <memset+0x40>
		c &= 0xFF;
  800c34:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800c38:	89 d3                	mov    %edx,%ebx
  800c3a:	c1 e3 08             	shl    $0x8,%ebx
  800c3d:	89 d6                	mov    %edx,%esi
  800c3f:	c1 e6 18             	shl    $0x18,%esi
  800c42:	89 d0                	mov    %edx,%eax
  800c44:	c1 e0 10             	shl    $0x10,%eax
  800c47:	09 f0                	or     %esi,%eax
  800c49:	09 c2                	or     %eax,%edx
  800c4b:	89 d0                	mov    %edx,%eax
  800c4d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800c4f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800c52:	fc                   	cld    
  800c53:	f3 ab                	rep stos %eax,%es:(%edi)
  800c55:	eb 06                	jmp    800c5d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800c57:	8b 45 0c             	mov    0xc(%ebp),%eax
  800c5a:	fc                   	cld    
  800c5b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800c5d:	89 f8                	mov    %edi,%eax
  800c5f:	5b                   	pop    %ebx
  800c60:	5e                   	pop    %esi
  800c61:	5f                   	pop    %edi
  800c62:	5d                   	pop    %ebp
  800c63:	c3                   	ret    

00800c64 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800c64:	55                   	push   %ebp
  800c65:	89 e5                	mov    %esp,%ebp
  800c67:	57                   	push   %edi
  800c68:	56                   	push   %esi
  800c69:	8b 45 08             	mov    0x8(%ebp),%eax
  800c6c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c6f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800c72:	39 c6                	cmp    %eax,%esi
  800c74:	73 35                	jae    800cab <memmove+0x47>
  800c76:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800c79:	39 d0                	cmp    %edx,%eax
  800c7b:	73 2e                	jae    800cab <memmove+0x47>
		s += n;
		d += n;
  800c7d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800c80:	89 d6                	mov    %edx,%esi
  800c82:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800c84:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800c8a:	75 13                	jne    800c9f <memmove+0x3b>
  800c8c:	f6 c1 03             	test   $0x3,%cl
  800c8f:	75 0e                	jne    800c9f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800c91:	83 ef 04             	sub    $0x4,%edi
  800c94:	8d 72 fc             	lea    -0x4(%edx),%esi
  800c97:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800c9a:	fd                   	std    
  800c9b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800c9d:	eb 09                	jmp    800ca8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800c9f:	83 ef 01             	sub    $0x1,%edi
  800ca2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800ca5:	fd                   	std    
  800ca6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800ca8:	fc                   	cld    
  800ca9:	eb 1d                	jmp    800cc8 <memmove+0x64>
  800cab:	89 f2                	mov    %esi,%edx
  800cad:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800caf:	f6 c2 03             	test   $0x3,%dl
  800cb2:	75 0f                	jne    800cc3 <memmove+0x5f>
  800cb4:	f6 c1 03             	test   $0x3,%cl
  800cb7:	75 0a                	jne    800cc3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800cb9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800cbc:	89 c7                	mov    %eax,%edi
  800cbe:	fc                   	cld    
  800cbf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800cc1:	eb 05                	jmp    800cc8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800cc3:	89 c7                	mov    %eax,%edi
  800cc5:	fc                   	cld    
  800cc6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800cc8:	5e                   	pop    %esi
  800cc9:	5f                   	pop    %edi
  800cca:	5d                   	pop    %ebp
  800ccb:	c3                   	ret    

00800ccc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800ccc:	55                   	push   %ebp
  800ccd:	89 e5                	mov    %esp,%ebp
  800ccf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800cd2:	8b 45 10             	mov    0x10(%ebp),%eax
  800cd5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800cd9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800cdc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ce0:	8b 45 08             	mov    0x8(%ebp),%eax
  800ce3:	89 04 24             	mov    %eax,(%esp)
  800ce6:	e8 79 ff ff ff       	call   800c64 <memmove>
}
  800ceb:	c9                   	leave  
  800cec:	c3                   	ret    

00800ced <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800ced:	55                   	push   %ebp
  800cee:	89 e5                	mov    %esp,%ebp
  800cf0:	56                   	push   %esi
  800cf1:	53                   	push   %ebx
  800cf2:	8b 55 08             	mov    0x8(%ebp),%edx
  800cf5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cf8:	89 d6                	mov    %edx,%esi
  800cfa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800cfd:	eb 1a                	jmp    800d19 <memcmp+0x2c>
		if (*s1 != *s2)
  800cff:	0f b6 02             	movzbl (%edx),%eax
  800d02:	0f b6 19             	movzbl (%ecx),%ebx
  800d05:	38 d8                	cmp    %bl,%al
  800d07:	74 0a                	je     800d13 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800d09:	0f b6 c0             	movzbl %al,%eax
  800d0c:	0f b6 db             	movzbl %bl,%ebx
  800d0f:	29 d8                	sub    %ebx,%eax
  800d11:	eb 0f                	jmp    800d22 <memcmp+0x35>
		s1++, s2++;
  800d13:	83 c2 01             	add    $0x1,%edx
  800d16:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800d19:	39 f2                	cmp    %esi,%edx
  800d1b:	75 e2                	jne    800cff <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800d1d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800d22:	5b                   	pop    %ebx
  800d23:	5e                   	pop    %esi
  800d24:	5d                   	pop    %ebp
  800d25:	c3                   	ret    

00800d26 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800d26:	55                   	push   %ebp
  800d27:	89 e5                	mov    %esp,%ebp
  800d29:	8b 45 08             	mov    0x8(%ebp),%eax
  800d2c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800d2f:	89 c2                	mov    %eax,%edx
  800d31:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800d34:	eb 07                	jmp    800d3d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800d36:	38 08                	cmp    %cl,(%eax)
  800d38:	74 07                	je     800d41 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800d3a:	83 c0 01             	add    $0x1,%eax
  800d3d:	39 d0                	cmp    %edx,%eax
  800d3f:	72 f5                	jb     800d36 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800d41:	5d                   	pop    %ebp
  800d42:	c3                   	ret    

00800d43 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800d43:	55                   	push   %ebp
  800d44:	89 e5                	mov    %esp,%ebp
  800d46:	57                   	push   %edi
  800d47:	56                   	push   %esi
  800d48:	53                   	push   %ebx
  800d49:	8b 55 08             	mov    0x8(%ebp),%edx
  800d4c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800d4f:	eb 03                	jmp    800d54 <strtol+0x11>
		s++;
  800d51:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800d54:	0f b6 0a             	movzbl (%edx),%ecx
  800d57:	80 f9 09             	cmp    $0x9,%cl
  800d5a:	74 f5                	je     800d51 <strtol+0xe>
  800d5c:	80 f9 20             	cmp    $0x20,%cl
  800d5f:	74 f0                	je     800d51 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800d61:	80 f9 2b             	cmp    $0x2b,%cl
  800d64:	75 0a                	jne    800d70 <strtol+0x2d>
		s++;
  800d66:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800d69:	bf 00 00 00 00       	mov    $0x0,%edi
  800d6e:	eb 11                	jmp    800d81 <strtol+0x3e>
  800d70:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800d75:	80 f9 2d             	cmp    $0x2d,%cl
  800d78:	75 07                	jne    800d81 <strtol+0x3e>
		s++, neg = 1;
  800d7a:	8d 52 01             	lea    0x1(%edx),%edx
  800d7d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800d81:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800d86:	75 15                	jne    800d9d <strtol+0x5a>
  800d88:	80 3a 30             	cmpb   $0x30,(%edx)
  800d8b:	75 10                	jne    800d9d <strtol+0x5a>
  800d8d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800d91:	75 0a                	jne    800d9d <strtol+0x5a>
		s += 2, base = 16;
  800d93:	83 c2 02             	add    $0x2,%edx
  800d96:	b8 10 00 00 00       	mov    $0x10,%eax
  800d9b:	eb 10                	jmp    800dad <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800d9d:	85 c0                	test   %eax,%eax
  800d9f:	75 0c                	jne    800dad <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800da1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800da3:	80 3a 30             	cmpb   $0x30,(%edx)
  800da6:	75 05                	jne    800dad <strtol+0x6a>
		s++, base = 8;
  800da8:	83 c2 01             	add    $0x1,%edx
  800dab:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800dad:	bb 00 00 00 00       	mov    $0x0,%ebx
  800db2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800db5:	0f b6 0a             	movzbl (%edx),%ecx
  800db8:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800dbb:	89 f0                	mov    %esi,%eax
  800dbd:	3c 09                	cmp    $0x9,%al
  800dbf:	77 08                	ja     800dc9 <strtol+0x86>
			dig = *s - '0';
  800dc1:	0f be c9             	movsbl %cl,%ecx
  800dc4:	83 e9 30             	sub    $0x30,%ecx
  800dc7:	eb 20                	jmp    800de9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800dc9:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800dcc:	89 f0                	mov    %esi,%eax
  800dce:	3c 19                	cmp    $0x19,%al
  800dd0:	77 08                	ja     800dda <strtol+0x97>
			dig = *s - 'a' + 10;
  800dd2:	0f be c9             	movsbl %cl,%ecx
  800dd5:	83 e9 57             	sub    $0x57,%ecx
  800dd8:	eb 0f                	jmp    800de9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800dda:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800ddd:	89 f0                	mov    %esi,%eax
  800ddf:	3c 19                	cmp    $0x19,%al
  800de1:	77 16                	ja     800df9 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800de3:	0f be c9             	movsbl %cl,%ecx
  800de6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800de9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800dec:	7d 0f                	jge    800dfd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800dee:	83 c2 01             	add    $0x1,%edx
  800df1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800df5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800df7:	eb bc                	jmp    800db5 <strtol+0x72>
  800df9:	89 d8                	mov    %ebx,%eax
  800dfb:	eb 02                	jmp    800dff <strtol+0xbc>
  800dfd:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800dff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800e03:	74 05                	je     800e0a <strtol+0xc7>
		*endptr = (char *) s;
  800e05:	8b 75 0c             	mov    0xc(%ebp),%esi
  800e08:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800e0a:	f7 d8                	neg    %eax
  800e0c:	85 ff                	test   %edi,%edi
  800e0e:	0f 44 c3             	cmove  %ebx,%eax
}
  800e11:	5b                   	pop    %ebx
  800e12:	5e                   	pop    %esi
  800e13:	5f                   	pop    %edi
  800e14:	5d                   	pop    %ebp
  800e15:	c3                   	ret    

00800e16 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  800e16:	55                   	push   %ebp
  800e17:	89 e5                	mov    %esp,%ebp
  800e19:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler == 0) {
  800e1c:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  800e23:	75 1c                	jne    800e41 <set_pgfault_handler+0x2b>
		// First time through!
		// LAB 4: Your code here.
		panic("set_pgfault_handler not implemented");
  800e25:	c7 44 24 08 88 13 80 	movl   $0x801388,0x8(%esp)
  800e2c:	00 
  800e2d:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
  800e34:	00 
  800e35:	c7 04 24 ac 13 80 00 	movl   $0x8013ac,(%esp)
  800e3c:	e8 6b f5 ff ff       	call   8003ac <_panic>
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  800e41:	8b 45 08             	mov    0x8(%ebp),%eax
  800e44:	a3 08 20 80 00       	mov    %eax,0x802008
}
  800e49:	c9                   	leave  
  800e4a:	c3                   	ret    
  800e4b:	66 90                	xchg   %ax,%ax
  800e4d:	66 90                	xchg   %ax,%ax
  800e4f:	90                   	nop

00800e50 <__udivdi3>:
  800e50:	55                   	push   %ebp
  800e51:	57                   	push   %edi
  800e52:	56                   	push   %esi
  800e53:	83 ec 0c             	sub    $0xc,%esp
  800e56:	8b 44 24 28          	mov    0x28(%esp),%eax
  800e5a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800e5e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800e62:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800e66:	85 c0                	test   %eax,%eax
  800e68:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800e6c:	89 ea                	mov    %ebp,%edx
  800e6e:	89 0c 24             	mov    %ecx,(%esp)
  800e71:	75 2d                	jne    800ea0 <__udivdi3+0x50>
  800e73:	39 e9                	cmp    %ebp,%ecx
  800e75:	77 61                	ja     800ed8 <__udivdi3+0x88>
  800e77:	85 c9                	test   %ecx,%ecx
  800e79:	89 ce                	mov    %ecx,%esi
  800e7b:	75 0b                	jne    800e88 <__udivdi3+0x38>
  800e7d:	b8 01 00 00 00       	mov    $0x1,%eax
  800e82:	31 d2                	xor    %edx,%edx
  800e84:	f7 f1                	div    %ecx
  800e86:	89 c6                	mov    %eax,%esi
  800e88:	31 d2                	xor    %edx,%edx
  800e8a:	89 e8                	mov    %ebp,%eax
  800e8c:	f7 f6                	div    %esi
  800e8e:	89 c5                	mov    %eax,%ebp
  800e90:	89 f8                	mov    %edi,%eax
  800e92:	f7 f6                	div    %esi
  800e94:	89 ea                	mov    %ebp,%edx
  800e96:	83 c4 0c             	add    $0xc,%esp
  800e99:	5e                   	pop    %esi
  800e9a:	5f                   	pop    %edi
  800e9b:	5d                   	pop    %ebp
  800e9c:	c3                   	ret    
  800e9d:	8d 76 00             	lea    0x0(%esi),%esi
  800ea0:	39 e8                	cmp    %ebp,%eax
  800ea2:	77 24                	ja     800ec8 <__udivdi3+0x78>
  800ea4:	0f bd e8             	bsr    %eax,%ebp
  800ea7:	83 f5 1f             	xor    $0x1f,%ebp
  800eaa:	75 3c                	jne    800ee8 <__udivdi3+0x98>
  800eac:	8b 74 24 04          	mov    0x4(%esp),%esi
  800eb0:	39 34 24             	cmp    %esi,(%esp)
  800eb3:	0f 86 9f 00 00 00    	jbe    800f58 <__udivdi3+0x108>
  800eb9:	39 d0                	cmp    %edx,%eax
  800ebb:	0f 82 97 00 00 00    	jb     800f58 <__udivdi3+0x108>
  800ec1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ec8:	31 d2                	xor    %edx,%edx
  800eca:	31 c0                	xor    %eax,%eax
  800ecc:	83 c4 0c             	add    $0xc,%esp
  800ecf:	5e                   	pop    %esi
  800ed0:	5f                   	pop    %edi
  800ed1:	5d                   	pop    %ebp
  800ed2:	c3                   	ret    
  800ed3:	90                   	nop
  800ed4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ed8:	89 f8                	mov    %edi,%eax
  800eda:	f7 f1                	div    %ecx
  800edc:	31 d2                	xor    %edx,%edx
  800ede:	83 c4 0c             	add    $0xc,%esp
  800ee1:	5e                   	pop    %esi
  800ee2:	5f                   	pop    %edi
  800ee3:	5d                   	pop    %ebp
  800ee4:	c3                   	ret    
  800ee5:	8d 76 00             	lea    0x0(%esi),%esi
  800ee8:	89 e9                	mov    %ebp,%ecx
  800eea:	8b 3c 24             	mov    (%esp),%edi
  800eed:	d3 e0                	shl    %cl,%eax
  800eef:	89 c6                	mov    %eax,%esi
  800ef1:	b8 20 00 00 00       	mov    $0x20,%eax
  800ef6:	29 e8                	sub    %ebp,%eax
  800ef8:	89 c1                	mov    %eax,%ecx
  800efa:	d3 ef                	shr    %cl,%edi
  800efc:	89 e9                	mov    %ebp,%ecx
  800efe:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800f02:	8b 3c 24             	mov    (%esp),%edi
  800f05:	09 74 24 08          	or     %esi,0x8(%esp)
  800f09:	89 d6                	mov    %edx,%esi
  800f0b:	d3 e7                	shl    %cl,%edi
  800f0d:	89 c1                	mov    %eax,%ecx
  800f0f:	89 3c 24             	mov    %edi,(%esp)
  800f12:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800f16:	d3 ee                	shr    %cl,%esi
  800f18:	89 e9                	mov    %ebp,%ecx
  800f1a:	d3 e2                	shl    %cl,%edx
  800f1c:	89 c1                	mov    %eax,%ecx
  800f1e:	d3 ef                	shr    %cl,%edi
  800f20:	09 d7                	or     %edx,%edi
  800f22:	89 f2                	mov    %esi,%edx
  800f24:	89 f8                	mov    %edi,%eax
  800f26:	f7 74 24 08          	divl   0x8(%esp)
  800f2a:	89 d6                	mov    %edx,%esi
  800f2c:	89 c7                	mov    %eax,%edi
  800f2e:	f7 24 24             	mull   (%esp)
  800f31:	39 d6                	cmp    %edx,%esi
  800f33:	89 14 24             	mov    %edx,(%esp)
  800f36:	72 30                	jb     800f68 <__udivdi3+0x118>
  800f38:	8b 54 24 04          	mov    0x4(%esp),%edx
  800f3c:	89 e9                	mov    %ebp,%ecx
  800f3e:	d3 e2                	shl    %cl,%edx
  800f40:	39 c2                	cmp    %eax,%edx
  800f42:	73 05                	jae    800f49 <__udivdi3+0xf9>
  800f44:	3b 34 24             	cmp    (%esp),%esi
  800f47:	74 1f                	je     800f68 <__udivdi3+0x118>
  800f49:	89 f8                	mov    %edi,%eax
  800f4b:	31 d2                	xor    %edx,%edx
  800f4d:	e9 7a ff ff ff       	jmp    800ecc <__udivdi3+0x7c>
  800f52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f58:	31 d2                	xor    %edx,%edx
  800f5a:	b8 01 00 00 00       	mov    $0x1,%eax
  800f5f:	e9 68 ff ff ff       	jmp    800ecc <__udivdi3+0x7c>
  800f64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f68:	8d 47 ff             	lea    -0x1(%edi),%eax
  800f6b:	31 d2                	xor    %edx,%edx
  800f6d:	83 c4 0c             	add    $0xc,%esp
  800f70:	5e                   	pop    %esi
  800f71:	5f                   	pop    %edi
  800f72:	5d                   	pop    %ebp
  800f73:	c3                   	ret    
  800f74:	66 90                	xchg   %ax,%ax
  800f76:	66 90                	xchg   %ax,%ax
  800f78:	66 90                	xchg   %ax,%ax
  800f7a:	66 90                	xchg   %ax,%ax
  800f7c:	66 90                	xchg   %ax,%ax
  800f7e:	66 90                	xchg   %ax,%ax

00800f80 <__umoddi3>:
  800f80:	55                   	push   %ebp
  800f81:	57                   	push   %edi
  800f82:	56                   	push   %esi
  800f83:	83 ec 14             	sub    $0x14,%esp
  800f86:	8b 44 24 28          	mov    0x28(%esp),%eax
  800f8a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800f8e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800f92:	89 c7                	mov    %eax,%edi
  800f94:	89 44 24 04          	mov    %eax,0x4(%esp)
  800f98:	8b 44 24 30          	mov    0x30(%esp),%eax
  800f9c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800fa0:	89 34 24             	mov    %esi,(%esp)
  800fa3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800fa7:	85 c0                	test   %eax,%eax
  800fa9:	89 c2                	mov    %eax,%edx
  800fab:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800faf:	75 17                	jne    800fc8 <__umoddi3+0x48>
  800fb1:	39 fe                	cmp    %edi,%esi
  800fb3:	76 4b                	jbe    801000 <__umoddi3+0x80>
  800fb5:	89 c8                	mov    %ecx,%eax
  800fb7:	89 fa                	mov    %edi,%edx
  800fb9:	f7 f6                	div    %esi
  800fbb:	89 d0                	mov    %edx,%eax
  800fbd:	31 d2                	xor    %edx,%edx
  800fbf:	83 c4 14             	add    $0x14,%esp
  800fc2:	5e                   	pop    %esi
  800fc3:	5f                   	pop    %edi
  800fc4:	5d                   	pop    %ebp
  800fc5:	c3                   	ret    
  800fc6:	66 90                	xchg   %ax,%ax
  800fc8:	39 f8                	cmp    %edi,%eax
  800fca:	77 54                	ja     801020 <__umoddi3+0xa0>
  800fcc:	0f bd e8             	bsr    %eax,%ebp
  800fcf:	83 f5 1f             	xor    $0x1f,%ebp
  800fd2:	75 5c                	jne    801030 <__umoddi3+0xb0>
  800fd4:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800fd8:	39 3c 24             	cmp    %edi,(%esp)
  800fdb:	0f 87 e7 00 00 00    	ja     8010c8 <__umoddi3+0x148>
  800fe1:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800fe5:	29 f1                	sub    %esi,%ecx
  800fe7:	19 c7                	sbb    %eax,%edi
  800fe9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800fed:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800ff1:	8b 44 24 08          	mov    0x8(%esp),%eax
  800ff5:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800ff9:	83 c4 14             	add    $0x14,%esp
  800ffc:	5e                   	pop    %esi
  800ffd:	5f                   	pop    %edi
  800ffe:	5d                   	pop    %ebp
  800fff:	c3                   	ret    
  801000:	85 f6                	test   %esi,%esi
  801002:	89 f5                	mov    %esi,%ebp
  801004:	75 0b                	jne    801011 <__umoddi3+0x91>
  801006:	b8 01 00 00 00       	mov    $0x1,%eax
  80100b:	31 d2                	xor    %edx,%edx
  80100d:	f7 f6                	div    %esi
  80100f:	89 c5                	mov    %eax,%ebp
  801011:	8b 44 24 04          	mov    0x4(%esp),%eax
  801015:	31 d2                	xor    %edx,%edx
  801017:	f7 f5                	div    %ebp
  801019:	89 c8                	mov    %ecx,%eax
  80101b:	f7 f5                	div    %ebp
  80101d:	eb 9c                	jmp    800fbb <__umoddi3+0x3b>
  80101f:	90                   	nop
  801020:	89 c8                	mov    %ecx,%eax
  801022:	89 fa                	mov    %edi,%edx
  801024:	83 c4 14             	add    $0x14,%esp
  801027:	5e                   	pop    %esi
  801028:	5f                   	pop    %edi
  801029:	5d                   	pop    %ebp
  80102a:	c3                   	ret    
  80102b:	90                   	nop
  80102c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801030:	8b 04 24             	mov    (%esp),%eax
  801033:	be 20 00 00 00       	mov    $0x20,%esi
  801038:	89 e9                	mov    %ebp,%ecx
  80103a:	29 ee                	sub    %ebp,%esi
  80103c:	d3 e2                	shl    %cl,%edx
  80103e:	89 f1                	mov    %esi,%ecx
  801040:	d3 e8                	shr    %cl,%eax
  801042:	89 e9                	mov    %ebp,%ecx
  801044:	89 44 24 04          	mov    %eax,0x4(%esp)
  801048:	8b 04 24             	mov    (%esp),%eax
  80104b:	09 54 24 04          	or     %edx,0x4(%esp)
  80104f:	89 fa                	mov    %edi,%edx
  801051:	d3 e0                	shl    %cl,%eax
  801053:	89 f1                	mov    %esi,%ecx
  801055:	89 44 24 08          	mov    %eax,0x8(%esp)
  801059:	8b 44 24 10          	mov    0x10(%esp),%eax
  80105d:	d3 ea                	shr    %cl,%edx
  80105f:	89 e9                	mov    %ebp,%ecx
  801061:	d3 e7                	shl    %cl,%edi
  801063:	89 f1                	mov    %esi,%ecx
  801065:	d3 e8                	shr    %cl,%eax
  801067:	89 e9                	mov    %ebp,%ecx
  801069:	09 f8                	or     %edi,%eax
  80106b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80106f:	f7 74 24 04          	divl   0x4(%esp)
  801073:	d3 e7                	shl    %cl,%edi
  801075:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801079:	89 d7                	mov    %edx,%edi
  80107b:	f7 64 24 08          	mull   0x8(%esp)
  80107f:	39 d7                	cmp    %edx,%edi
  801081:	89 c1                	mov    %eax,%ecx
  801083:	89 14 24             	mov    %edx,(%esp)
  801086:	72 2c                	jb     8010b4 <__umoddi3+0x134>
  801088:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  80108c:	72 22                	jb     8010b0 <__umoddi3+0x130>
  80108e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801092:	29 c8                	sub    %ecx,%eax
  801094:	19 d7                	sbb    %edx,%edi
  801096:	89 e9                	mov    %ebp,%ecx
  801098:	89 fa                	mov    %edi,%edx
  80109a:	d3 e8                	shr    %cl,%eax
  80109c:	89 f1                	mov    %esi,%ecx
  80109e:	d3 e2                	shl    %cl,%edx
  8010a0:	89 e9                	mov    %ebp,%ecx
  8010a2:	d3 ef                	shr    %cl,%edi
  8010a4:	09 d0                	or     %edx,%eax
  8010a6:	89 fa                	mov    %edi,%edx
  8010a8:	83 c4 14             	add    $0x14,%esp
  8010ab:	5e                   	pop    %esi
  8010ac:	5f                   	pop    %edi
  8010ad:	5d                   	pop    %ebp
  8010ae:	c3                   	ret    
  8010af:	90                   	nop
  8010b0:	39 d7                	cmp    %edx,%edi
  8010b2:	75 da                	jne    80108e <__umoddi3+0x10e>
  8010b4:	8b 14 24             	mov    (%esp),%edx
  8010b7:	89 c1                	mov    %eax,%ecx
  8010b9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  8010bd:	1b 54 24 04          	sbb    0x4(%esp),%edx
  8010c1:	eb cb                	jmp    80108e <__umoddi3+0x10e>
  8010c3:	90                   	nop
  8010c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8010c8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  8010cc:	0f 82 0f ff ff ff    	jb     800fe1 <__umoddi3+0x61>
  8010d2:	e9 1a ff ff ff       	jmp    800ff1 <__umoddi3+0x71>
