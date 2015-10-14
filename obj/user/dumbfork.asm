
obj/user/dumbfork:     file format elf32-i386


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
  80002c:	e8 1d 02 00 00       	call   80024e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	66 90                	xchg   %ax,%ax
  800035:	66 90                	xchg   %ax,%ax
  800037:	66 90                	xchg   %ax,%ax
  800039:	66 90                	xchg   %ax,%ax
  80003b:	66 90                	xchg   %ax,%ax
  80003d:	66 90                	xchg   %ax,%ax
  80003f:	90                   	nop

00800040 <duppage>:
	}
}

void
duppage(envid_t dstenv, void *addr)
{
  800040:	55                   	push   %ebp
  800041:	89 e5                	mov    %esp,%ebp
  800043:	56                   	push   %esi
  800044:	53                   	push   %ebx
  800045:	83 ec 20             	sub    $0x20,%esp
  800048:	8b 75 08             	mov    0x8(%ebp),%esi
  80004b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	int r;

	// This is NOT what you should do in your fork.
	if ((r = sys_page_alloc(dstenv, addr, PTE_P|PTE_U|PTE_W)) < 0)
  80004e:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  800055:	00 
  800056:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80005a:	89 34 24             	mov    %esi,(%esp)
  80005d:	e8 91 0d 00 00       	call   800df3 <sys_page_alloc>
  800062:	85 c0                	test   %eax,%eax
  800064:	79 20                	jns    800086 <duppage+0x46>
		panic("sys_page_alloc: %e", r);
  800066:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80006a:	c7 44 24 08 a0 12 80 	movl   $0x8012a0,0x8(%esp)
  800071:	00 
  800072:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
  800079:	00 
  80007a:	c7 04 24 b3 12 80 00 	movl   $0x8012b3,(%esp)
  800081:	e8 2e 02 00 00       	call   8002b4 <_panic>
	if ((r = sys_page_map(dstenv, addr, 0, UTEMP, PTE_P|PTE_U|PTE_W)) < 0)
  800086:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  80008d:	00 
  80008e:	c7 44 24 0c 00 00 40 	movl   $0x400000,0xc(%esp)
  800095:	00 
  800096:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80009d:	00 
  80009e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8000a2:	89 34 24             	mov    %esi,(%esp)
  8000a5:	e8 9d 0d 00 00       	call   800e47 <sys_page_map>
  8000aa:	85 c0                	test   %eax,%eax
  8000ac:	79 20                	jns    8000ce <duppage+0x8e>
		panic("sys_page_map: %e", r);
  8000ae:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000b2:	c7 44 24 08 c3 12 80 	movl   $0x8012c3,0x8(%esp)
  8000b9:	00 
  8000ba:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
  8000c1:	00 
  8000c2:	c7 04 24 b3 12 80 00 	movl   $0x8012b3,(%esp)
  8000c9:	e8 e6 01 00 00       	call   8002b4 <_panic>
	memmove(UTEMP, addr, PGSIZE);
  8000ce:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  8000d5:	00 
  8000d6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8000da:	c7 04 24 00 00 40 00 	movl   $0x400000,(%esp)
  8000e1:	e8 8e 0a 00 00       	call   800b74 <memmove>
	if ((r = sys_page_unmap(0, UTEMP)) < 0)
  8000e6:	c7 44 24 04 00 00 40 	movl   $0x400000,0x4(%esp)
  8000ed:	00 
  8000ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000f5:	e8 a0 0d 00 00       	call   800e9a <sys_page_unmap>
  8000fa:	85 c0                	test   %eax,%eax
  8000fc:	79 20                	jns    80011e <duppage+0xde>
		panic("sys_page_unmap: %e", r);
  8000fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800102:	c7 44 24 08 d4 12 80 	movl   $0x8012d4,0x8(%esp)
  800109:	00 
  80010a:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
  800111:	00 
  800112:	c7 04 24 b3 12 80 00 	movl   $0x8012b3,(%esp)
  800119:	e8 96 01 00 00       	call   8002b4 <_panic>
}
  80011e:	83 c4 20             	add    $0x20,%esp
  800121:	5b                   	pop    %ebx
  800122:	5e                   	pop    %esi
  800123:	5d                   	pop    %ebp
  800124:	c3                   	ret    

00800125 <dumbfork>:

envid_t
dumbfork(void)
{
  800125:	55                   	push   %ebp
  800126:	89 e5                	mov    %esp,%ebp
  800128:	56                   	push   %esi
  800129:	53                   	push   %ebx
  80012a:	83 ec 20             	sub    $0x20,%esp
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  80012d:	b8 07 00 00 00       	mov    $0x7,%eax
  800132:	cd 30                	int    $0x30
  800134:	89 c6                	mov    %eax,%esi
	// The kernel will initialize it with a copy of our register state,
	// so that the child will appear to have called sys_exofork() too -
	// except that in the child, this "fake" call to sys_exofork()
	// will return 0 instead of the envid of the child.
	envid = sys_exofork();
	if (envid < 0)
  800136:	85 c0                	test   %eax,%eax
  800138:	79 20                	jns    80015a <dumbfork+0x35>
		panic("sys_exofork: %e", envid);
  80013a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80013e:	c7 44 24 08 e7 12 80 	movl   $0x8012e7,0x8(%esp)
  800145:	00 
  800146:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
  80014d:	00 
  80014e:	c7 04 24 b3 12 80 00 	movl   $0x8012b3,(%esp)
  800155:	e8 5a 01 00 00       	call   8002b4 <_panic>
  80015a:	89 c3                	mov    %eax,%ebx
	if (envid == 0) {
  80015c:	85 c0                	test   %eax,%eax
  80015e:	75 1e                	jne    80017e <dumbfork+0x59>
		// We're the child.
		// The copied value of the global variable 'thisenv'
		// is no longer valid (it refers to the parent!).
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
  800160:	e8 50 0c 00 00       	call   800db5 <sys_getenvid>
  800165:	25 ff 03 00 00       	and    $0x3ff,%eax
  80016a:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80016d:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800172:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  800177:	b8 00 00 00 00       	mov    $0x0,%eax
  80017c:	eb 71                	jmp    8001ef <dumbfork+0xca>
	}

	// We're the parent.
	// Eagerly copy our entire address space into the child.
	// This is NOT what you should do in your fork implementation.
	for (addr = (uint8_t*) UTEXT; addr < end; addr += PGSIZE)
  80017e:	c7 45 f4 00 00 80 00 	movl   $0x800000,-0xc(%ebp)
  800185:	eb 13                	jmp    80019a <dumbfork+0x75>
		duppage(envid, addr);
  800187:	89 54 24 04          	mov    %edx,0x4(%esp)
  80018b:	89 1c 24             	mov    %ebx,(%esp)
  80018e:	e8 ad fe ff ff       	call   800040 <duppage>
	}

	// We're the parent.
	// Eagerly copy our entire address space into the child.
	// This is NOT what you should do in your fork implementation.
	for (addr = (uint8_t*) UTEXT; addr < end; addr += PGSIZE)
  800193:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
  80019a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  80019d:	81 fa 08 20 80 00    	cmp    $0x802008,%edx
  8001a3:	72 e2                	jb     800187 <dumbfork+0x62>
		duppage(envid, addr);

	// Also copy the stack we are currently running on.
	duppage(envid, ROUNDDOWN(&addr, PGSIZE));
  8001a5:	8d 45 f4             	lea    -0xc(%ebp),%eax
  8001a8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  8001ad:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001b1:	89 34 24             	mov    %esi,(%esp)
  8001b4:	e8 87 fe ff ff       	call   800040 <duppage>

	// Start the child environment running
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
  8001b9:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  8001c0:	00 
  8001c1:	89 34 24             	mov    %esi,(%esp)
  8001c4:	e8 24 0d 00 00       	call   800eed <sys_env_set_status>
  8001c9:	85 c0                	test   %eax,%eax
  8001cb:	79 20                	jns    8001ed <dumbfork+0xc8>
		panic("sys_env_set_status: %e", r);
  8001cd:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001d1:	c7 44 24 08 f7 12 80 	movl   $0x8012f7,0x8(%esp)
  8001d8:	00 
  8001d9:	c7 44 24 04 4c 00 00 	movl   $0x4c,0x4(%esp)
  8001e0:	00 
  8001e1:	c7 04 24 b3 12 80 00 	movl   $0x8012b3,(%esp)
  8001e8:	e8 c7 00 00 00       	call   8002b4 <_panic>

	return envid;
  8001ed:	89 f0                	mov    %esi,%eax
}
  8001ef:	83 c4 20             	add    $0x20,%esp
  8001f2:	5b                   	pop    %ebx
  8001f3:	5e                   	pop    %esi
  8001f4:	5d                   	pop    %ebp
  8001f5:	c3                   	ret    

008001f6 <umain>:

envid_t dumbfork(void);

void
umain(int argc, char **argv)
{
  8001f6:	55                   	push   %ebp
  8001f7:	89 e5                	mov    %esp,%ebp
  8001f9:	56                   	push   %esi
  8001fa:	53                   	push   %ebx
  8001fb:	83 ec 10             	sub    $0x10,%esp
	envid_t who;
	int i;

	// fork a child process
	who = dumbfork();
  8001fe:	e8 22 ff ff ff       	call   800125 <dumbfork>
  800203:	89 c6                	mov    %eax,%esi

	// print a message and yield to the other a few times
	for (i = 0; i < (who ? 10 : 20); i++) {
  800205:	bb 00 00 00 00       	mov    $0x0,%ebx
  80020a:	eb 28                	jmp    800234 <umain+0x3e>
		cprintf("%d: I am the %s!\n", i, who ? "parent" : "child");
  80020c:	b8 15 13 80 00       	mov    $0x801315,%eax
  800211:	eb 05                	jmp    800218 <umain+0x22>
  800213:	b8 0e 13 80 00       	mov    $0x80130e,%eax
  800218:	89 44 24 08          	mov    %eax,0x8(%esp)
  80021c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800220:	c7 04 24 1b 13 80 00 	movl   $0x80131b,(%esp)
  800227:	e8 81 01 00 00       	call   8003ad <cprintf>
		sys_yield();
  80022c:	e8 a3 0b 00 00       	call   800dd4 <sys_yield>

	// fork a child process
	who = dumbfork();

	// print a message and yield to the other a few times
	for (i = 0; i < (who ? 10 : 20); i++) {
  800231:	83 c3 01             	add    $0x1,%ebx
  800234:	85 f6                	test   %esi,%esi
  800236:	75 0a                	jne    800242 <umain+0x4c>
  800238:	83 fb 13             	cmp    $0x13,%ebx
  80023b:	7e cf                	jle    80020c <umain+0x16>
  80023d:	8d 76 00             	lea    0x0(%esi),%esi
  800240:	eb 05                	jmp    800247 <umain+0x51>
  800242:	83 fb 09             	cmp    $0x9,%ebx
  800245:	7e cc                	jle    800213 <umain+0x1d>
		cprintf("%d: I am the %s!\n", i, who ? "parent" : "child");
		sys_yield();
	}
}
  800247:	83 c4 10             	add    $0x10,%esp
  80024a:	5b                   	pop    %ebx
  80024b:	5e                   	pop    %esi
  80024c:	5d                   	pop    %ebp
  80024d:	c3                   	ret    

0080024e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80024e:	55                   	push   %ebp
  80024f:	89 e5                	mov    %esp,%ebp
  800251:	56                   	push   %esi
  800252:	53                   	push   %ebx
  800253:	83 ec 10             	sub    $0x10,%esp
  800256:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800259:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80025c:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800263:	00 00 00 
	thisenv = &envs[ENVX(sys_getenvid())]; 
  800266:	e8 4a 0b 00 00       	call   800db5 <sys_getenvid>
  80026b:	25 ff 03 00 00       	and    $0x3ff,%eax
  800270:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800273:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800278:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  80027d:	85 db                	test   %ebx,%ebx
  80027f:	7e 07                	jle    800288 <libmain+0x3a>
		binaryname = argv[0];
  800281:	8b 06                	mov    (%esi),%eax
  800283:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800288:	89 74 24 04          	mov    %esi,0x4(%esp)
  80028c:	89 1c 24             	mov    %ebx,(%esp)
  80028f:	e8 62 ff ff ff       	call   8001f6 <umain>

	// exit gracefully
	exit();
  800294:	e8 07 00 00 00       	call   8002a0 <exit>
}
  800299:	83 c4 10             	add    $0x10,%esp
  80029c:	5b                   	pop    %ebx
  80029d:	5e                   	pop    %esi
  80029e:	5d                   	pop    %ebp
  80029f:	c3                   	ret    

008002a0 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8002a0:	55                   	push   %ebp
  8002a1:	89 e5                	mov    %esp,%ebp
  8002a3:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8002a6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8002ad:	e8 b1 0a 00 00       	call   800d63 <sys_env_destroy>
}
  8002b2:	c9                   	leave  
  8002b3:	c3                   	ret    

008002b4 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8002b4:	55                   	push   %ebp
  8002b5:	89 e5                	mov    %esp,%ebp
  8002b7:	56                   	push   %esi
  8002b8:	53                   	push   %ebx
  8002b9:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8002bc:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8002bf:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8002c5:	e8 eb 0a 00 00       	call   800db5 <sys_getenvid>
  8002ca:	8b 55 0c             	mov    0xc(%ebp),%edx
  8002cd:	89 54 24 10          	mov    %edx,0x10(%esp)
  8002d1:	8b 55 08             	mov    0x8(%ebp),%edx
  8002d4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8002d8:	89 74 24 08          	mov    %esi,0x8(%esp)
  8002dc:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002e0:	c7 04 24 38 13 80 00 	movl   $0x801338,(%esp)
  8002e7:	e8 c1 00 00 00       	call   8003ad <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8002ec:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8002f0:	8b 45 10             	mov    0x10(%ebp),%eax
  8002f3:	89 04 24             	mov    %eax,(%esp)
  8002f6:	e8 51 00 00 00       	call   80034c <vcprintf>
	cprintf("\n");
  8002fb:	c7 04 24 2b 13 80 00 	movl   $0x80132b,(%esp)
  800302:	e8 a6 00 00 00       	call   8003ad <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800307:	cc                   	int3   
  800308:	eb fd                	jmp    800307 <_panic+0x53>

0080030a <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80030a:	55                   	push   %ebp
  80030b:	89 e5                	mov    %esp,%ebp
  80030d:	53                   	push   %ebx
  80030e:	83 ec 14             	sub    $0x14,%esp
  800311:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800314:	8b 13                	mov    (%ebx),%edx
  800316:	8d 42 01             	lea    0x1(%edx),%eax
  800319:	89 03                	mov    %eax,(%ebx)
  80031b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80031e:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800322:	3d ff 00 00 00       	cmp    $0xff,%eax
  800327:	75 19                	jne    800342 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800329:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800330:	00 
  800331:	8d 43 08             	lea    0x8(%ebx),%eax
  800334:	89 04 24             	mov    %eax,(%esp)
  800337:	e8 ea 09 00 00       	call   800d26 <sys_cputs>
		b->idx = 0;
  80033c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800342:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800346:	83 c4 14             	add    $0x14,%esp
  800349:	5b                   	pop    %ebx
  80034a:	5d                   	pop    %ebp
  80034b:	c3                   	ret    

0080034c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80034c:	55                   	push   %ebp
  80034d:	89 e5                	mov    %esp,%ebp
  80034f:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800355:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80035c:	00 00 00 
	b.cnt = 0;
  80035f:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800366:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800369:	8b 45 0c             	mov    0xc(%ebp),%eax
  80036c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800370:	8b 45 08             	mov    0x8(%ebp),%eax
  800373:	89 44 24 08          	mov    %eax,0x8(%esp)
  800377:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80037d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800381:	c7 04 24 0a 03 80 00 	movl   $0x80030a,(%esp)
  800388:	e8 b1 01 00 00       	call   80053e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80038d:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800393:	89 44 24 04          	mov    %eax,0x4(%esp)
  800397:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80039d:	89 04 24             	mov    %eax,(%esp)
  8003a0:	e8 81 09 00 00       	call   800d26 <sys_cputs>

	return b.cnt;
}
  8003a5:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8003ab:	c9                   	leave  
  8003ac:	c3                   	ret    

008003ad <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8003ad:	55                   	push   %ebp
  8003ae:	89 e5                	mov    %esp,%ebp
  8003b0:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8003b3:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8003b6:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003ba:	8b 45 08             	mov    0x8(%ebp),%eax
  8003bd:	89 04 24             	mov    %eax,(%esp)
  8003c0:	e8 87 ff ff ff       	call   80034c <vcprintf>
	va_end(ap);

	return cnt;
}
  8003c5:	c9                   	leave  
  8003c6:	c3                   	ret    
  8003c7:	66 90                	xchg   %ax,%ax
  8003c9:	66 90                	xchg   %ax,%ax
  8003cb:	66 90                	xchg   %ax,%ax
  8003cd:	66 90                	xchg   %ax,%ax
  8003cf:	90                   	nop

008003d0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8003d0:	55                   	push   %ebp
  8003d1:	89 e5                	mov    %esp,%ebp
  8003d3:	57                   	push   %edi
  8003d4:	56                   	push   %esi
  8003d5:	53                   	push   %ebx
  8003d6:	83 ec 3c             	sub    $0x3c,%esp
  8003d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003dc:	89 d7                	mov    %edx,%edi
  8003de:	8b 45 08             	mov    0x8(%ebp),%eax
  8003e1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003e4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003e7:	89 c3                	mov    %eax,%ebx
  8003e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8003ec:	8b 45 10             	mov    0x10(%ebp),%eax
  8003ef:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8003f2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8003f7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8003fa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8003fd:	39 d9                	cmp    %ebx,%ecx
  8003ff:	72 05                	jb     800406 <printnum+0x36>
  800401:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800404:	77 69                	ja     80046f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800406:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800409:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80040d:	83 ee 01             	sub    $0x1,%esi
  800410:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800414:	89 44 24 08          	mov    %eax,0x8(%esp)
  800418:	8b 44 24 08          	mov    0x8(%esp),%eax
  80041c:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800420:	89 c3                	mov    %eax,%ebx
  800422:	89 d6                	mov    %edx,%esi
  800424:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800427:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80042a:	89 54 24 08          	mov    %edx,0x8(%esp)
  80042e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800432:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800435:	89 04 24             	mov    %eax,(%esp)
  800438:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80043b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80043f:	e8 cc 0b 00 00       	call   801010 <__udivdi3>
  800444:	89 d9                	mov    %ebx,%ecx
  800446:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80044a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80044e:	89 04 24             	mov    %eax,(%esp)
  800451:	89 54 24 04          	mov    %edx,0x4(%esp)
  800455:	89 fa                	mov    %edi,%edx
  800457:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80045a:	e8 71 ff ff ff       	call   8003d0 <printnum>
  80045f:	eb 1b                	jmp    80047c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800461:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800465:	8b 45 18             	mov    0x18(%ebp),%eax
  800468:	89 04 24             	mov    %eax,(%esp)
  80046b:	ff d3                	call   *%ebx
  80046d:	eb 03                	jmp    800472 <printnum+0xa2>
  80046f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800472:	83 ee 01             	sub    $0x1,%esi
  800475:	85 f6                	test   %esi,%esi
  800477:	7f e8                	jg     800461 <printnum+0x91>
  800479:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80047c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800480:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800484:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800487:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80048a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80048e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800492:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800495:	89 04 24             	mov    %eax,(%esp)
  800498:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80049b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80049f:	e8 9c 0c 00 00       	call   801140 <__umoddi3>
  8004a4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004a8:	0f be 80 5c 13 80 00 	movsbl 0x80135c(%eax),%eax
  8004af:	89 04 24             	mov    %eax,(%esp)
  8004b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8004b5:	ff d0                	call   *%eax
}
  8004b7:	83 c4 3c             	add    $0x3c,%esp
  8004ba:	5b                   	pop    %ebx
  8004bb:	5e                   	pop    %esi
  8004bc:	5f                   	pop    %edi
  8004bd:	5d                   	pop    %ebp
  8004be:	c3                   	ret    

008004bf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8004bf:	55                   	push   %ebp
  8004c0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8004c2:	83 fa 01             	cmp    $0x1,%edx
  8004c5:	7e 0e                	jle    8004d5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8004c7:	8b 10                	mov    (%eax),%edx
  8004c9:	8d 4a 08             	lea    0x8(%edx),%ecx
  8004cc:	89 08                	mov    %ecx,(%eax)
  8004ce:	8b 02                	mov    (%edx),%eax
  8004d0:	8b 52 04             	mov    0x4(%edx),%edx
  8004d3:	eb 22                	jmp    8004f7 <getuint+0x38>
	else if (lflag)
  8004d5:	85 d2                	test   %edx,%edx
  8004d7:	74 10                	je     8004e9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8004d9:	8b 10                	mov    (%eax),%edx
  8004db:	8d 4a 04             	lea    0x4(%edx),%ecx
  8004de:	89 08                	mov    %ecx,(%eax)
  8004e0:	8b 02                	mov    (%edx),%eax
  8004e2:	ba 00 00 00 00       	mov    $0x0,%edx
  8004e7:	eb 0e                	jmp    8004f7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8004e9:	8b 10                	mov    (%eax),%edx
  8004eb:	8d 4a 04             	lea    0x4(%edx),%ecx
  8004ee:	89 08                	mov    %ecx,(%eax)
  8004f0:	8b 02                	mov    (%edx),%eax
  8004f2:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8004f7:	5d                   	pop    %ebp
  8004f8:	c3                   	ret    

008004f9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8004f9:	55                   	push   %ebp
  8004fa:	89 e5                	mov    %esp,%ebp
  8004fc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8004ff:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800503:	8b 10                	mov    (%eax),%edx
  800505:	3b 50 04             	cmp    0x4(%eax),%edx
  800508:	73 0a                	jae    800514 <sprintputch+0x1b>
		*b->buf++ = ch;
  80050a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80050d:	89 08                	mov    %ecx,(%eax)
  80050f:	8b 45 08             	mov    0x8(%ebp),%eax
  800512:	88 02                	mov    %al,(%edx)
}
  800514:	5d                   	pop    %ebp
  800515:	c3                   	ret    

00800516 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800516:	55                   	push   %ebp
  800517:	89 e5                	mov    %esp,%ebp
  800519:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  80051c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80051f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800523:	8b 45 10             	mov    0x10(%ebp),%eax
  800526:	89 44 24 08          	mov    %eax,0x8(%esp)
  80052a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80052d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800531:	8b 45 08             	mov    0x8(%ebp),%eax
  800534:	89 04 24             	mov    %eax,(%esp)
  800537:	e8 02 00 00 00       	call   80053e <vprintfmt>
	va_end(ap);
}
  80053c:	c9                   	leave  
  80053d:	c3                   	ret    

0080053e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80053e:	55                   	push   %ebp
  80053f:	89 e5                	mov    %esp,%ebp
  800541:	57                   	push   %edi
  800542:	56                   	push   %esi
  800543:	53                   	push   %ebx
  800544:	83 ec 3c             	sub    $0x3c,%esp
  800547:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80054a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80054d:	eb 14                	jmp    800563 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80054f:	85 c0                	test   %eax,%eax
  800551:	0f 84 b3 03 00 00    	je     80090a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800557:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80055b:	89 04 24             	mov    %eax,(%esp)
  80055e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800561:	89 f3                	mov    %esi,%ebx
  800563:	8d 73 01             	lea    0x1(%ebx),%esi
  800566:	0f b6 03             	movzbl (%ebx),%eax
  800569:	83 f8 25             	cmp    $0x25,%eax
  80056c:	75 e1                	jne    80054f <vprintfmt+0x11>
  80056e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800572:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800579:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800580:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800587:	ba 00 00 00 00       	mov    $0x0,%edx
  80058c:	eb 1d                	jmp    8005ab <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80058e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  800590:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800594:	eb 15                	jmp    8005ab <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800596:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800598:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80059c:	eb 0d                	jmp    8005ab <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80059e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8005a1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8005a4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ab:	8d 5e 01             	lea    0x1(%esi),%ebx
  8005ae:	0f b6 0e             	movzbl (%esi),%ecx
  8005b1:	0f b6 c1             	movzbl %cl,%eax
  8005b4:	83 e9 23             	sub    $0x23,%ecx
  8005b7:	80 f9 55             	cmp    $0x55,%cl
  8005ba:	0f 87 2a 03 00 00    	ja     8008ea <vprintfmt+0x3ac>
  8005c0:	0f b6 c9             	movzbl %cl,%ecx
  8005c3:	ff 24 8d 20 14 80 00 	jmp    *0x801420(,%ecx,4)
  8005ca:	89 de                	mov    %ebx,%esi
  8005cc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8005d1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  8005d4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  8005d8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8005db:	8d 58 d0             	lea    -0x30(%eax),%ebx
  8005de:	83 fb 09             	cmp    $0x9,%ebx
  8005e1:	77 36                	ja     800619 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8005e3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8005e6:	eb e9                	jmp    8005d1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8005e8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005eb:	8d 48 04             	lea    0x4(%eax),%ecx
  8005ee:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8005f1:	8b 00                	mov    (%eax),%eax
  8005f3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005f6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8005f8:	eb 22                	jmp    80061c <vprintfmt+0xde>
  8005fa:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8005fd:	85 c9                	test   %ecx,%ecx
  8005ff:	b8 00 00 00 00       	mov    $0x0,%eax
  800604:	0f 49 c1             	cmovns %ecx,%eax
  800607:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80060a:	89 de                	mov    %ebx,%esi
  80060c:	eb 9d                	jmp    8005ab <vprintfmt+0x6d>
  80060e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800610:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  800617:	eb 92                	jmp    8005ab <vprintfmt+0x6d>
  800619:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  80061c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800620:	79 89                	jns    8005ab <vprintfmt+0x6d>
  800622:	e9 77 ff ff ff       	jmp    80059e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800627:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80062a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80062c:	e9 7a ff ff ff       	jmp    8005ab <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800631:	8b 45 14             	mov    0x14(%ebp),%eax
  800634:	8d 50 04             	lea    0x4(%eax),%edx
  800637:	89 55 14             	mov    %edx,0x14(%ebp)
  80063a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80063e:	8b 00                	mov    (%eax),%eax
  800640:	89 04 24             	mov    %eax,(%esp)
  800643:	ff 55 08             	call   *0x8(%ebp)
			break;
  800646:	e9 18 ff ff ff       	jmp    800563 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80064b:	8b 45 14             	mov    0x14(%ebp),%eax
  80064e:	8d 50 04             	lea    0x4(%eax),%edx
  800651:	89 55 14             	mov    %edx,0x14(%ebp)
  800654:	8b 00                	mov    (%eax),%eax
  800656:	99                   	cltd   
  800657:	31 d0                	xor    %edx,%eax
  800659:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80065b:	83 f8 09             	cmp    $0x9,%eax
  80065e:	7f 0b                	jg     80066b <vprintfmt+0x12d>
  800660:	8b 14 85 80 15 80 00 	mov    0x801580(,%eax,4),%edx
  800667:	85 d2                	test   %edx,%edx
  800669:	75 20                	jne    80068b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80066b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80066f:	c7 44 24 08 74 13 80 	movl   $0x801374,0x8(%esp)
  800676:	00 
  800677:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80067b:	8b 45 08             	mov    0x8(%ebp),%eax
  80067e:	89 04 24             	mov    %eax,(%esp)
  800681:	e8 90 fe ff ff       	call   800516 <printfmt>
  800686:	e9 d8 fe ff ff       	jmp    800563 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80068b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80068f:	c7 44 24 08 7d 13 80 	movl   $0x80137d,0x8(%esp)
  800696:	00 
  800697:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80069b:	8b 45 08             	mov    0x8(%ebp),%eax
  80069e:	89 04 24             	mov    %eax,(%esp)
  8006a1:	e8 70 fe ff ff       	call   800516 <printfmt>
  8006a6:	e9 b8 fe ff ff       	jmp    800563 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006ab:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8006ae:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8006b1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8006b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b7:	8d 50 04             	lea    0x4(%eax),%edx
  8006ba:	89 55 14             	mov    %edx,0x14(%ebp)
  8006bd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  8006bf:	85 f6                	test   %esi,%esi
  8006c1:	b8 6d 13 80 00       	mov    $0x80136d,%eax
  8006c6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  8006c9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  8006cd:	0f 84 97 00 00 00    	je     80076a <vprintfmt+0x22c>
  8006d3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  8006d7:	0f 8e 9b 00 00 00    	jle    800778 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  8006dd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8006e1:	89 34 24             	mov    %esi,(%esp)
  8006e4:	e8 cf 02 00 00       	call   8009b8 <strnlen>
  8006e9:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8006ec:	29 c2                	sub    %eax,%edx
  8006ee:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  8006f1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8006f5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8006f8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8006fb:	8b 75 08             	mov    0x8(%ebp),%esi
  8006fe:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800701:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800703:	eb 0f                	jmp    800714 <vprintfmt+0x1d6>
					putch(padc, putdat);
  800705:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800709:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80070c:	89 04 24             	mov    %eax,(%esp)
  80070f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800711:	83 eb 01             	sub    $0x1,%ebx
  800714:	85 db                	test   %ebx,%ebx
  800716:	7f ed                	jg     800705 <vprintfmt+0x1c7>
  800718:	8b 75 d8             	mov    -0x28(%ebp),%esi
  80071b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80071e:	85 d2                	test   %edx,%edx
  800720:	b8 00 00 00 00       	mov    $0x0,%eax
  800725:	0f 49 c2             	cmovns %edx,%eax
  800728:	29 c2                	sub    %eax,%edx
  80072a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80072d:	89 d7                	mov    %edx,%edi
  80072f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800732:	eb 50                	jmp    800784 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800734:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800738:	74 1e                	je     800758 <vprintfmt+0x21a>
  80073a:	0f be d2             	movsbl %dl,%edx
  80073d:	83 ea 20             	sub    $0x20,%edx
  800740:	83 fa 5e             	cmp    $0x5e,%edx
  800743:	76 13                	jbe    800758 <vprintfmt+0x21a>
					putch('?', putdat);
  800745:	8b 45 0c             	mov    0xc(%ebp),%eax
  800748:	89 44 24 04          	mov    %eax,0x4(%esp)
  80074c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800753:	ff 55 08             	call   *0x8(%ebp)
  800756:	eb 0d                	jmp    800765 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800758:	8b 55 0c             	mov    0xc(%ebp),%edx
  80075b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80075f:	89 04 24             	mov    %eax,(%esp)
  800762:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800765:	83 ef 01             	sub    $0x1,%edi
  800768:	eb 1a                	jmp    800784 <vprintfmt+0x246>
  80076a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80076d:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800770:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800773:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800776:	eb 0c                	jmp    800784 <vprintfmt+0x246>
  800778:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80077b:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80077e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800781:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800784:	83 c6 01             	add    $0x1,%esi
  800787:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80078b:	0f be c2             	movsbl %dl,%eax
  80078e:	85 c0                	test   %eax,%eax
  800790:	74 27                	je     8007b9 <vprintfmt+0x27b>
  800792:	85 db                	test   %ebx,%ebx
  800794:	78 9e                	js     800734 <vprintfmt+0x1f6>
  800796:	83 eb 01             	sub    $0x1,%ebx
  800799:	79 99                	jns    800734 <vprintfmt+0x1f6>
  80079b:	89 f8                	mov    %edi,%eax
  80079d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8007a0:	8b 75 08             	mov    0x8(%ebp),%esi
  8007a3:	89 c3                	mov    %eax,%ebx
  8007a5:	eb 1a                	jmp    8007c1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8007a7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007ab:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8007b2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8007b4:	83 eb 01             	sub    $0x1,%ebx
  8007b7:	eb 08                	jmp    8007c1 <vprintfmt+0x283>
  8007b9:	89 fb                	mov    %edi,%ebx
  8007bb:	8b 75 08             	mov    0x8(%ebp),%esi
  8007be:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8007c1:	85 db                	test   %ebx,%ebx
  8007c3:	7f e2                	jg     8007a7 <vprintfmt+0x269>
  8007c5:	89 75 08             	mov    %esi,0x8(%ebp)
  8007c8:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8007cb:	e9 93 fd ff ff       	jmp    800563 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8007d0:	83 fa 01             	cmp    $0x1,%edx
  8007d3:	7e 16                	jle    8007eb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  8007d5:	8b 45 14             	mov    0x14(%ebp),%eax
  8007d8:	8d 50 08             	lea    0x8(%eax),%edx
  8007db:	89 55 14             	mov    %edx,0x14(%ebp)
  8007de:	8b 50 04             	mov    0x4(%eax),%edx
  8007e1:	8b 00                	mov    (%eax),%eax
  8007e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8007e6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8007e9:	eb 32                	jmp    80081d <vprintfmt+0x2df>
	else if (lflag)
  8007eb:	85 d2                	test   %edx,%edx
  8007ed:	74 18                	je     800807 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  8007ef:	8b 45 14             	mov    0x14(%ebp),%eax
  8007f2:	8d 50 04             	lea    0x4(%eax),%edx
  8007f5:	89 55 14             	mov    %edx,0x14(%ebp)
  8007f8:	8b 30                	mov    (%eax),%esi
  8007fa:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8007fd:	89 f0                	mov    %esi,%eax
  8007ff:	c1 f8 1f             	sar    $0x1f,%eax
  800802:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800805:	eb 16                	jmp    80081d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  800807:	8b 45 14             	mov    0x14(%ebp),%eax
  80080a:	8d 50 04             	lea    0x4(%eax),%edx
  80080d:	89 55 14             	mov    %edx,0x14(%ebp)
  800810:	8b 30                	mov    (%eax),%esi
  800812:	89 75 e0             	mov    %esi,-0x20(%ebp)
  800815:	89 f0                	mov    %esi,%eax
  800817:	c1 f8 1f             	sar    $0x1f,%eax
  80081a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80081d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800820:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800823:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800828:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80082c:	0f 89 80 00 00 00    	jns    8008b2 <vprintfmt+0x374>
				putch('-', putdat);
  800832:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800836:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80083d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800840:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800843:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800846:	f7 d8                	neg    %eax
  800848:	83 d2 00             	adc    $0x0,%edx
  80084b:	f7 da                	neg    %edx
			}
			base = 10;
  80084d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800852:	eb 5e                	jmp    8008b2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800854:	8d 45 14             	lea    0x14(%ebp),%eax
  800857:	e8 63 fc ff ff       	call   8004bf <getuint>
			base = 10;
  80085c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800861:	eb 4f                	jmp    8008b2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800863:	8d 45 14             	lea    0x14(%ebp),%eax
  800866:	e8 54 fc ff ff       	call   8004bf <getuint>
			base = 8;
  80086b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800870:	eb 40                	jmp    8008b2 <vprintfmt+0x374>
			
		// pointer
		case 'p':
			putch('0', putdat);
  800872:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800876:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80087d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800880:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800884:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80088b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80088e:	8b 45 14             	mov    0x14(%ebp),%eax
  800891:	8d 50 04             	lea    0x4(%eax),%edx
  800894:	89 55 14             	mov    %edx,0x14(%ebp)
			
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800897:	8b 00                	mov    (%eax),%eax
  800899:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80089e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8008a3:	eb 0d                	jmp    8008b2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8008a5:	8d 45 14             	lea    0x14(%ebp),%eax
  8008a8:	e8 12 fc ff ff       	call   8004bf <getuint>
			base = 16;
  8008ad:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8008b2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  8008b6:	89 74 24 10          	mov    %esi,0x10(%esp)
  8008ba:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8008bd:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8008c1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8008c5:	89 04 24             	mov    %eax,(%esp)
  8008c8:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008cc:	89 fa                	mov    %edi,%edx
  8008ce:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d1:	e8 fa fa ff ff       	call   8003d0 <printnum>
			break;
  8008d6:	e9 88 fc ff ff       	jmp    800563 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8008db:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8008df:	89 04 24             	mov    %eax,(%esp)
  8008e2:	ff 55 08             	call   *0x8(%ebp)
			break;
  8008e5:	e9 79 fc ff ff       	jmp    800563 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8008ea:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8008ee:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8008f5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8008f8:	89 f3                	mov    %esi,%ebx
  8008fa:	eb 03                	jmp    8008ff <vprintfmt+0x3c1>
  8008fc:	83 eb 01             	sub    $0x1,%ebx
  8008ff:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  800903:	75 f7                	jne    8008fc <vprintfmt+0x3be>
  800905:	e9 59 fc ff ff       	jmp    800563 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  80090a:	83 c4 3c             	add    $0x3c,%esp
  80090d:	5b                   	pop    %ebx
  80090e:	5e                   	pop    %esi
  80090f:	5f                   	pop    %edi
  800910:	5d                   	pop    %ebp
  800911:	c3                   	ret    

00800912 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800912:	55                   	push   %ebp
  800913:	89 e5                	mov    %esp,%ebp
  800915:	83 ec 28             	sub    $0x28,%esp
  800918:	8b 45 08             	mov    0x8(%ebp),%eax
  80091b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80091e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800921:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800925:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800928:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80092f:	85 c0                	test   %eax,%eax
  800931:	74 30                	je     800963 <vsnprintf+0x51>
  800933:	85 d2                	test   %edx,%edx
  800935:	7e 2c                	jle    800963 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800937:	8b 45 14             	mov    0x14(%ebp),%eax
  80093a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80093e:	8b 45 10             	mov    0x10(%ebp),%eax
  800941:	89 44 24 08          	mov    %eax,0x8(%esp)
  800945:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800948:	89 44 24 04          	mov    %eax,0x4(%esp)
  80094c:	c7 04 24 f9 04 80 00 	movl   $0x8004f9,(%esp)
  800953:	e8 e6 fb ff ff       	call   80053e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800958:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80095b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80095e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800961:	eb 05                	jmp    800968 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800963:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800968:	c9                   	leave  
  800969:	c3                   	ret    

0080096a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80096a:	55                   	push   %ebp
  80096b:	89 e5                	mov    %esp,%ebp
  80096d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800970:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800973:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800977:	8b 45 10             	mov    0x10(%ebp),%eax
  80097a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80097e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800981:	89 44 24 04          	mov    %eax,0x4(%esp)
  800985:	8b 45 08             	mov    0x8(%ebp),%eax
  800988:	89 04 24             	mov    %eax,(%esp)
  80098b:	e8 82 ff ff ff       	call   800912 <vsnprintf>
	va_end(ap);

	return rc;
}
  800990:	c9                   	leave  
  800991:	c3                   	ret    
  800992:	66 90                	xchg   %ax,%ax
  800994:	66 90                	xchg   %ax,%ax
  800996:	66 90                	xchg   %ax,%ax
  800998:	66 90                	xchg   %ax,%ax
  80099a:	66 90                	xchg   %ax,%ax
  80099c:	66 90                	xchg   %ax,%ax
  80099e:	66 90                	xchg   %ax,%ax

008009a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8009a0:	55                   	push   %ebp
  8009a1:	89 e5                	mov    %esp,%ebp
  8009a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8009a6:	b8 00 00 00 00       	mov    $0x0,%eax
  8009ab:	eb 03                	jmp    8009b0 <strlen+0x10>
		n++;
  8009ad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8009b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8009b4:	75 f7                	jne    8009ad <strlen+0xd>
		n++;
	return n;
}
  8009b6:	5d                   	pop    %ebp
  8009b7:	c3                   	ret    

008009b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8009b8:	55                   	push   %ebp
  8009b9:	89 e5                	mov    %esp,%ebp
  8009bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009be:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8009c1:	b8 00 00 00 00       	mov    $0x0,%eax
  8009c6:	eb 03                	jmp    8009cb <strnlen+0x13>
		n++;
  8009c8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8009cb:	39 d0                	cmp    %edx,%eax
  8009cd:	74 06                	je     8009d5 <strnlen+0x1d>
  8009cf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  8009d3:	75 f3                	jne    8009c8 <strnlen+0x10>
		n++;
	return n;
}
  8009d5:	5d                   	pop    %ebp
  8009d6:	c3                   	ret    

008009d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8009d7:	55                   	push   %ebp
  8009d8:	89 e5                	mov    %esp,%ebp
  8009da:	53                   	push   %ebx
  8009db:	8b 45 08             	mov    0x8(%ebp),%eax
  8009de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8009e1:	89 c2                	mov    %eax,%edx
  8009e3:	83 c2 01             	add    $0x1,%edx
  8009e6:	83 c1 01             	add    $0x1,%ecx
  8009e9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8009ed:	88 5a ff             	mov    %bl,-0x1(%edx)
  8009f0:	84 db                	test   %bl,%bl
  8009f2:	75 ef                	jne    8009e3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8009f4:	5b                   	pop    %ebx
  8009f5:	5d                   	pop    %ebp
  8009f6:	c3                   	ret    

008009f7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8009f7:	55                   	push   %ebp
  8009f8:	89 e5                	mov    %esp,%ebp
  8009fa:	53                   	push   %ebx
  8009fb:	83 ec 08             	sub    $0x8,%esp
  8009fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800a01:	89 1c 24             	mov    %ebx,(%esp)
  800a04:	e8 97 ff ff ff       	call   8009a0 <strlen>
	strcpy(dst + len, src);
  800a09:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a0c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800a10:	01 d8                	add    %ebx,%eax
  800a12:	89 04 24             	mov    %eax,(%esp)
  800a15:	e8 bd ff ff ff       	call   8009d7 <strcpy>
	return dst;
}
  800a1a:	89 d8                	mov    %ebx,%eax
  800a1c:	83 c4 08             	add    $0x8,%esp
  800a1f:	5b                   	pop    %ebx
  800a20:	5d                   	pop    %ebp
  800a21:	c3                   	ret    

00800a22 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800a22:	55                   	push   %ebp
  800a23:	89 e5                	mov    %esp,%ebp
  800a25:	56                   	push   %esi
  800a26:	53                   	push   %ebx
  800a27:	8b 75 08             	mov    0x8(%ebp),%esi
  800a2a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a2d:	89 f3                	mov    %esi,%ebx
  800a2f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a32:	89 f2                	mov    %esi,%edx
  800a34:	eb 0f                	jmp    800a45 <strncpy+0x23>
		*dst++ = *src;
  800a36:	83 c2 01             	add    $0x1,%edx
  800a39:	0f b6 01             	movzbl (%ecx),%eax
  800a3c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800a3f:	80 39 01             	cmpb   $0x1,(%ecx)
  800a42:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a45:	39 da                	cmp    %ebx,%edx
  800a47:	75 ed                	jne    800a36 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800a49:	89 f0                	mov    %esi,%eax
  800a4b:	5b                   	pop    %ebx
  800a4c:	5e                   	pop    %esi
  800a4d:	5d                   	pop    %ebp
  800a4e:	c3                   	ret    

00800a4f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800a4f:	55                   	push   %ebp
  800a50:	89 e5                	mov    %esp,%ebp
  800a52:	56                   	push   %esi
  800a53:	53                   	push   %ebx
  800a54:	8b 75 08             	mov    0x8(%ebp),%esi
  800a57:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a5a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800a5d:	89 f0                	mov    %esi,%eax
  800a5f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800a63:	85 c9                	test   %ecx,%ecx
  800a65:	75 0b                	jne    800a72 <strlcpy+0x23>
  800a67:	eb 1d                	jmp    800a86 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800a69:	83 c0 01             	add    $0x1,%eax
  800a6c:	83 c2 01             	add    $0x1,%edx
  800a6f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800a72:	39 d8                	cmp    %ebx,%eax
  800a74:	74 0b                	je     800a81 <strlcpy+0x32>
  800a76:	0f b6 0a             	movzbl (%edx),%ecx
  800a79:	84 c9                	test   %cl,%cl
  800a7b:	75 ec                	jne    800a69 <strlcpy+0x1a>
  800a7d:	89 c2                	mov    %eax,%edx
  800a7f:	eb 02                	jmp    800a83 <strlcpy+0x34>
  800a81:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800a83:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800a86:	29 f0                	sub    %esi,%eax
}
  800a88:	5b                   	pop    %ebx
  800a89:	5e                   	pop    %esi
  800a8a:	5d                   	pop    %ebp
  800a8b:	c3                   	ret    

00800a8c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800a8c:	55                   	push   %ebp
  800a8d:	89 e5                	mov    %esp,%ebp
  800a8f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a92:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800a95:	eb 06                	jmp    800a9d <strcmp+0x11>
		p++, q++;
  800a97:	83 c1 01             	add    $0x1,%ecx
  800a9a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800a9d:	0f b6 01             	movzbl (%ecx),%eax
  800aa0:	84 c0                	test   %al,%al
  800aa2:	74 04                	je     800aa8 <strcmp+0x1c>
  800aa4:	3a 02                	cmp    (%edx),%al
  800aa6:	74 ef                	je     800a97 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800aa8:	0f b6 c0             	movzbl %al,%eax
  800aab:	0f b6 12             	movzbl (%edx),%edx
  800aae:	29 d0                	sub    %edx,%eax
}
  800ab0:	5d                   	pop    %ebp
  800ab1:	c3                   	ret    

00800ab2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800ab2:	55                   	push   %ebp
  800ab3:	89 e5                	mov    %esp,%ebp
  800ab5:	53                   	push   %ebx
  800ab6:	8b 45 08             	mov    0x8(%ebp),%eax
  800ab9:	8b 55 0c             	mov    0xc(%ebp),%edx
  800abc:	89 c3                	mov    %eax,%ebx
  800abe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800ac1:	eb 06                	jmp    800ac9 <strncmp+0x17>
		n--, p++, q++;
  800ac3:	83 c0 01             	add    $0x1,%eax
  800ac6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800ac9:	39 d8                	cmp    %ebx,%eax
  800acb:	74 15                	je     800ae2 <strncmp+0x30>
  800acd:	0f b6 08             	movzbl (%eax),%ecx
  800ad0:	84 c9                	test   %cl,%cl
  800ad2:	74 04                	je     800ad8 <strncmp+0x26>
  800ad4:	3a 0a                	cmp    (%edx),%cl
  800ad6:	74 eb                	je     800ac3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800ad8:	0f b6 00             	movzbl (%eax),%eax
  800adb:	0f b6 12             	movzbl (%edx),%edx
  800ade:	29 d0                	sub    %edx,%eax
  800ae0:	eb 05                	jmp    800ae7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800ae2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800ae7:	5b                   	pop    %ebx
  800ae8:	5d                   	pop    %ebp
  800ae9:	c3                   	ret    

00800aea <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800aea:	55                   	push   %ebp
  800aeb:	89 e5                	mov    %esp,%ebp
  800aed:	8b 45 08             	mov    0x8(%ebp),%eax
  800af0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800af4:	eb 07                	jmp    800afd <strchr+0x13>
		if (*s == c)
  800af6:	38 ca                	cmp    %cl,%dl
  800af8:	74 0f                	je     800b09 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800afa:	83 c0 01             	add    $0x1,%eax
  800afd:	0f b6 10             	movzbl (%eax),%edx
  800b00:	84 d2                	test   %dl,%dl
  800b02:	75 f2                	jne    800af6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800b04:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b09:	5d                   	pop    %ebp
  800b0a:	c3                   	ret    

00800b0b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800b0b:	55                   	push   %ebp
  800b0c:	89 e5                	mov    %esp,%ebp
  800b0e:	8b 45 08             	mov    0x8(%ebp),%eax
  800b11:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800b15:	eb 07                	jmp    800b1e <strfind+0x13>
		if (*s == c)
  800b17:	38 ca                	cmp    %cl,%dl
  800b19:	74 0a                	je     800b25 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800b1b:	83 c0 01             	add    $0x1,%eax
  800b1e:	0f b6 10             	movzbl (%eax),%edx
  800b21:	84 d2                	test   %dl,%dl
  800b23:	75 f2                	jne    800b17 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800b25:	5d                   	pop    %ebp
  800b26:	c3                   	ret    

00800b27 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800b27:	55                   	push   %ebp
  800b28:	89 e5                	mov    %esp,%ebp
  800b2a:	57                   	push   %edi
  800b2b:	56                   	push   %esi
  800b2c:	53                   	push   %ebx
  800b2d:	8b 7d 08             	mov    0x8(%ebp),%edi
  800b30:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800b33:	85 c9                	test   %ecx,%ecx
  800b35:	74 36                	je     800b6d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800b37:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b3d:	75 28                	jne    800b67 <memset+0x40>
  800b3f:	f6 c1 03             	test   $0x3,%cl
  800b42:	75 23                	jne    800b67 <memset+0x40>
		c &= 0xFF;
  800b44:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800b48:	89 d3                	mov    %edx,%ebx
  800b4a:	c1 e3 08             	shl    $0x8,%ebx
  800b4d:	89 d6                	mov    %edx,%esi
  800b4f:	c1 e6 18             	shl    $0x18,%esi
  800b52:	89 d0                	mov    %edx,%eax
  800b54:	c1 e0 10             	shl    $0x10,%eax
  800b57:	09 f0                	or     %esi,%eax
  800b59:	09 c2                	or     %eax,%edx
  800b5b:	89 d0                	mov    %edx,%eax
  800b5d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800b5f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800b62:	fc                   	cld    
  800b63:	f3 ab                	rep stos %eax,%es:(%edi)
  800b65:	eb 06                	jmp    800b6d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800b67:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b6a:	fc                   	cld    
  800b6b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800b6d:	89 f8                	mov    %edi,%eax
  800b6f:	5b                   	pop    %ebx
  800b70:	5e                   	pop    %esi
  800b71:	5f                   	pop    %edi
  800b72:	5d                   	pop    %ebp
  800b73:	c3                   	ret    

00800b74 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800b74:	55                   	push   %ebp
  800b75:	89 e5                	mov    %esp,%ebp
  800b77:	57                   	push   %edi
  800b78:	56                   	push   %esi
  800b79:	8b 45 08             	mov    0x8(%ebp),%eax
  800b7c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b7f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800b82:	39 c6                	cmp    %eax,%esi
  800b84:	73 35                	jae    800bbb <memmove+0x47>
  800b86:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800b89:	39 d0                	cmp    %edx,%eax
  800b8b:	73 2e                	jae    800bbb <memmove+0x47>
		s += n;
		d += n;
  800b8d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800b90:	89 d6                	mov    %edx,%esi
  800b92:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b94:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800b9a:	75 13                	jne    800baf <memmove+0x3b>
  800b9c:	f6 c1 03             	test   $0x3,%cl
  800b9f:	75 0e                	jne    800baf <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800ba1:	83 ef 04             	sub    $0x4,%edi
  800ba4:	8d 72 fc             	lea    -0x4(%edx),%esi
  800ba7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800baa:	fd                   	std    
  800bab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800bad:	eb 09                	jmp    800bb8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800baf:	83 ef 01             	sub    $0x1,%edi
  800bb2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800bb5:	fd                   	std    
  800bb6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800bb8:	fc                   	cld    
  800bb9:	eb 1d                	jmp    800bd8 <memmove+0x64>
  800bbb:	89 f2                	mov    %esi,%edx
  800bbd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800bbf:	f6 c2 03             	test   $0x3,%dl
  800bc2:	75 0f                	jne    800bd3 <memmove+0x5f>
  800bc4:	f6 c1 03             	test   $0x3,%cl
  800bc7:	75 0a                	jne    800bd3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800bc9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800bcc:	89 c7                	mov    %eax,%edi
  800bce:	fc                   	cld    
  800bcf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800bd1:	eb 05                	jmp    800bd8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800bd3:	89 c7                	mov    %eax,%edi
  800bd5:	fc                   	cld    
  800bd6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800bd8:	5e                   	pop    %esi
  800bd9:	5f                   	pop    %edi
  800bda:	5d                   	pop    %ebp
  800bdb:	c3                   	ret    

00800bdc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800bdc:	55                   	push   %ebp
  800bdd:	89 e5                	mov    %esp,%ebp
  800bdf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800be2:	8b 45 10             	mov    0x10(%ebp),%eax
  800be5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800be9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800bec:	89 44 24 04          	mov    %eax,0x4(%esp)
  800bf0:	8b 45 08             	mov    0x8(%ebp),%eax
  800bf3:	89 04 24             	mov    %eax,(%esp)
  800bf6:	e8 79 ff ff ff       	call   800b74 <memmove>
}
  800bfb:	c9                   	leave  
  800bfc:	c3                   	ret    

00800bfd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800bfd:	55                   	push   %ebp
  800bfe:	89 e5                	mov    %esp,%ebp
  800c00:	56                   	push   %esi
  800c01:	53                   	push   %ebx
  800c02:	8b 55 08             	mov    0x8(%ebp),%edx
  800c05:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c08:	89 d6                	mov    %edx,%esi
  800c0a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c0d:	eb 1a                	jmp    800c29 <memcmp+0x2c>
		if (*s1 != *s2)
  800c0f:	0f b6 02             	movzbl (%edx),%eax
  800c12:	0f b6 19             	movzbl (%ecx),%ebx
  800c15:	38 d8                	cmp    %bl,%al
  800c17:	74 0a                	je     800c23 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800c19:	0f b6 c0             	movzbl %al,%eax
  800c1c:	0f b6 db             	movzbl %bl,%ebx
  800c1f:	29 d8                	sub    %ebx,%eax
  800c21:	eb 0f                	jmp    800c32 <memcmp+0x35>
		s1++, s2++;
  800c23:	83 c2 01             	add    $0x1,%edx
  800c26:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c29:	39 f2                	cmp    %esi,%edx
  800c2b:	75 e2                	jne    800c0f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800c2d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800c32:	5b                   	pop    %ebx
  800c33:	5e                   	pop    %esi
  800c34:	5d                   	pop    %ebp
  800c35:	c3                   	ret    

00800c36 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800c36:	55                   	push   %ebp
  800c37:	89 e5                	mov    %esp,%ebp
  800c39:	8b 45 08             	mov    0x8(%ebp),%eax
  800c3c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800c3f:	89 c2                	mov    %eax,%edx
  800c41:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800c44:	eb 07                	jmp    800c4d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800c46:	38 08                	cmp    %cl,(%eax)
  800c48:	74 07                	je     800c51 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c4a:	83 c0 01             	add    $0x1,%eax
  800c4d:	39 d0                	cmp    %edx,%eax
  800c4f:	72 f5                	jb     800c46 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c51:	5d                   	pop    %ebp
  800c52:	c3                   	ret    

00800c53 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c53:	55                   	push   %ebp
  800c54:	89 e5                	mov    %esp,%ebp
  800c56:	57                   	push   %edi
  800c57:	56                   	push   %esi
  800c58:	53                   	push   %ebx
  800c59:	8b 55 08             	mov    0x8(%ebp),%edx
  800c5c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c5f:	eb 03                	jmp    800c64 <strtol+0x11>
		s++;
  800c61:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c64:	0f b6 0a             	movzbl (%edx),%ecx
  800c67:	80 f9 09             	cmp    $0x9,%cl
  800c6a:	74 f5                	je     800c61 <strtol+0xe>
  800c6c:	80 f9 20             	cmp    $0x20,%cl
  800c6f:	74 f0                	je     800c61 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800c71:	80 f9 2b             	cmp    $0x2b,%cl
  800c74:	75 0a                	jne    800c80 <strtol+0x2d>
		s++;
  800c76:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800c79:	bf 00 00 00 00       	mov    $0x0,%edi
  800c7e:	eb 11                	jmp    800c91 <strtol+0x3e>
  800c80:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800c85:	80 f9 2d             	cmp    $0x2d,%cl
  800c88:	75 07                	jne    800c91 <strtol+0x3e>
		s++, neg = 1;
  800c8a:	8d 52 01             	lea    0x1(%edx),%edx
  800c8d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800c91:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800c96:	75 15                	jne    800cad <strtol+0x5a>
  800c98:	80 3a 30             	cmpb   $0x30,(%edx)
  800c9b:	75 10                	jne    800cad <strtol+0x5a>
  800c9d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800ca1:	75 0a                	jne    800cad <strtol+0x5a>
		s += 2, base = 16;
  800ca3:	83 c2 02             	add    $0x2,%edx
  800ca6:	b8 10 00 00 00       	mov    $0x10,%eax
  800cab:	eb 10                	jmp    800cbd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800cad:	85 c0                	test   %eax,%eax
  800caf:	75 0c                	jne    800cbd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800cb1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800cb3:	80 3a 30             	cmpb   $0x30,(%edx)
  800cb6:	75 05                	jne    800cbd <strtol+0x6a>
		s++, base = 8;
  800cb8:	83 c2 01             	add    $0x1,%edx
  800cbb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800cbd:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cc2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800cc5:	0f b6 0a             	movzbl (%edx),%ecx
  800cc8:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800ccb:	89 f0                	mov    %esi,%eax
  800ccd:	3c 09                	cmp    $0x9,%al
  800ccf:	77 08                	ja     800cd9 <strtol+0x86>
			dig = *s - '0';
  800cd1:	0f be c9             	movsbl %cl,%ecx
  800cd4:	83 e9 30             	sub    $0x30,%ecx
  800cd7:	eb 20                	jmp    800cf9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800cd9:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800cdc:	89 f0                	mov    %esi,%eax
  800cde:	3c 19                	cmp    $0x19,%al
  800ce0:	77 08                	ja     800cea <strtol+0x97>
			dig = *s - 'a' + 10;
  800ce2:	0f be c9             	movsbl %cl,%ecx
  800ce5:	83 e9 57             	sub    $0x57,%ecx
  800ce8:	eb 0f                	jmp    800cf9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800cea:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800ced:	89 f0                	mov    %esi,%eax
  800cef:	3c 19                	cmp    $0x19,%al
  800cf1:	77 16                	ja     800d09 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800cf3:	0f be c9             	movsbl %cl,%ecx
  800cf6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800cf9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800cfc:	7d 0f                	jge    800d0d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800cfe:	83 c2 01             	add    $0x1,%edx
  800d01:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800d05:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800d07:	eb bc                	jmp    800cc5 <strtol+0x72>
  800d09:	89 d8                	mov    %ebx,%eax
  800d0b:	eb 02                	jmp    800d0f <strtol+0xbc>
  800d0d:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800d0f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800d13:	74 05                	je     800d1a <strtol+0xc7>
		*endptr = (char *) s;
  800d15:	8b 75 0c             	mov    0xc(%ebp),%esi
  800d18:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800d1a:	f7 d8                	neg    %eax
  800d1c:	85 ff                	test   %edi,%edi
  800d1e:	0f 44 c3             	cmove  %ebx,%eax
}
  800d21:	5b                   	pop    %ebx
  800d22:	5e                   	pop    %esi
  800d23:	5f                   	pop    %edi
  800d24:	5d                   	pop    %ebp
  800d25:	c3                   	ret    

00800d26 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800d26:	55                   	push   %ebp
  800d27:	89 e5                	mov    %esp,%ebp
  800d29:	57                   	push   %edi
  800d2a:	56                   	push   %esi
  800d2b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d2c:	b8 00 00 00 00       	mov    $0x0,%eax
  800d31:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d34:	8b 55 08             	mov    0x8(%ebp),%edx
  800d37:	89 c3                	mov    %eax,%ebx
  800d39:	89 c7                	mov    %eax,%edi
  800d3b:	89 c6                	mov    %eax,%esi
  800d3d:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800d3f:	5b                   	pop    %ebx
  800d40:	5e                   	pop    %esi
  800d41:	5f                   	pop    %edi
  800d42:	5d                   	pop    %ebp
  800d43:	c3                   	ret    

00800d44 <sys_cgetc>:

int
sys_cgetc(void)
{
  800d44:	55                   	push   %ebp
  800d45:	89 e5                	mov    %esp,%ebp
  800d47:	57                   	push   %edi
  800d48:	56                   	push   %esi
  800d49:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d4a:	ba 00 00 00 00       	mov    $0x0,%edx
  800d4f:	b8 01 00 00 00       	mov    $0x1,%eax
  800d54:	89 d1                	mov    %edx,%ecx
  800d56:	89 d3                	mov    %edx,%ebx
  800d58:	89 d7                	mov    %edx,%edi
  800d5a:	89 d6                	mov    %edx,%esi
  800d5c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800d5e:	5b                   	pop    %ebx
  800d5f:	5e                   	pop    %esi
  800d60:	5f                   	pop    %edi
  800d61:	5d                   	pop    %ebp
  800d62:	c3                   	ret    

00800d63 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800d63:	55                   	push   %ebp
  800d64:	89 e5                	mov    %esp,%ebp
  800d66:	57                   	push   %edi
  800d67:	56                   	push   %esi
  800d68:	53                   	push   %ebx
  800d69:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d6c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800d71:	b8 03 00 00 00       	mov    $0x3,%eax
  800d76:	8b 55 08             	mov    0x8(%ebp),%edx
  800d79:	89 cb                	mov    %ecx,%ebx
  800d7b:	89 cf                	mov    %ecx,%edi
  800d7d:	89 ce                	mov    %ecx,%esi
  800d7f:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d81:	85 c0                	test   %eax,%eax
  800d83:	7e 28                	jle    800dad <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d85:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d89:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800d90:	00 
  800d91:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800d98:	00 
  800d99:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800da0:	00 
  800da1:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800da8:	e8 07 f5 ff ff       	call   8002b4 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800dad:	83 c4 2c             	add    $0x2c,%esp
  800db0:	5b                   	pop    %ebx
  800db1:	5e                   	pop    %esi
  800db2:	5f                   	pop    %edi
  800db3:	5d                   	pop    %ebp
  800db4:	c3                   	ret    

00800db5 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800db5:	55                   	push   %ebp
  800db6:	89 e5                	mov    %esp,%ebp
  800db8:	57                   	push   %edi
  800db9:	56                   	push   %esi
  800dba:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dbb:	ba 00 00 00 00       	mov    $0x0,%edx
  800dc0:	b8 02 00 00 00       	mov    $0x2,%eax
  800dc5:	89 d1                	mov    %edx,%ecx
  800dc7:	89 d3                	mov    %edx,%ebx
  800dc9:	89 d7                	mov    %edx,%edi
  800dcb:	89 d6                	mov    %edx,%esi
  800dcd:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800dcf:	5b                   	pop    %ebx
  800dd0:	5e                   	pop    %esi
  800dd1:	5f                   	pop    %edi
  800dd2:	5d                   	pop    %ebp
  800dd3:	c3                   	ret    

00800dd4 <sys_yield>:

void
sys_yield(void)
{
  800dd4:	55                   	push   %ebp
  800dd5:	89 e5                	mov    %esp,%ebp
  800dd7:	57                   	push   %edi
  800dd8:	56                   	push   %esi
  800dd9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dda:	ba 00 00 00 00       	mov    $0x0,%edx
  800ddf:	b8 0a 00 00 00       	mov    $0xa,%eax
  800de4:	89 d1                	mov    %edx,%ecx
  800de6:	89 d3                	mov    %edx,%ebx
  800de8:	89 d7                	mov    %edx,%edi
  800dea:	89 d6                	mov    %edx,%esi
  800dec:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800dee:	5b                   	pop    %ebx
  800def:	5e                   	pop    %esi
  800df0:	5f                   	pop    %edi
  800df1:	5d                   	pop    %ebp
  800df2:	c3                   	ret    

00800df3 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800df3:	55                   	push   %ebp
  800df4:	89 e5                	mov    %esp,%ebp
  800df6:	57                   	push   %edi
  800df7:	56                   	push   %esi
  800df8:	53                   	push   %ebx
  800df9:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dfc:	be 00 00 00 00       	mov    $0x0,%esi
  800e01:	b8 04 00 00 00       	mov    $0x4,%eax
  800e06:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e09:	8b 55 08             	mov    0x8(%ebp),%edx
  800e0c:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800e0f:	89 f7                	mov    %esi,%edi
  800e11:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e13:	85 c0                	test   %eax,%eax
  800e15:	7e 28                	jle    800e3f <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e17:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e1b:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800e22:	00 
  800e23:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800e2a:	00 
  800e2b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e32:	00 
  800e33:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800e3a:	e8 75 f4 ff ff       	call   8002b4 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800e3f:	83 c4 2c             	add    $0x2c,%esp
  800e42:	5b                   	pop    %ebx
  800e43:	5e                   	pop    %esi
  800e44:	5f                   	pop    %edi
  800e45:	5d                   	pop    %ebp
  800e46:	c3                   	ret    

00800e47 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800e47:	55                   	push   %ebp
  800e48:	89 e5                	mov    %esp,%ebp
  800e4a:	57                   	push   %edi
  800e4b:	56                   	push   %esi
  800e4c:	53                   	push   %ebx
  800e4d:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e50:	b8 05 00 00 00       	mov    $0x5,%eax
  800e55:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e58:	8b 55 08             	mov    0x8(%ebp),%edx
  800e5b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800e5e:	8b 7d 14             	mov    0x14(%ebp),%edi
  800e61:	8b 75 18             	mov    0x18(%ebp),%esi
  800e64:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e66:	85 c0                	test   %eax,%eax
  800e68:	7e 28                	jle    800e92 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e6a:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e6e:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800e75:	00 
  800e76:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800e7d:	00 
  800e7e:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e85:	00 
  800e86:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800e8d:	e8 22 f4 ff ff       	call   8002b4 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800e92:	83 c4 2c             	add    $0x2c,%esp
  800e95:	5b                   	pop    %ebx
  800e96:	5e                   	pop    %esi
  800e97:	5f                   	pop    %edi
  800e98:	5d                   	pop    %ebp
  800e99:	c3                   	ret    

00800e9a <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800e9a:	55                   	push   %ebp
  800e9b:	89 e5                	mov    %esp,%ebp
  800e9d:	57                   	push   %edi
  800e9e:	56                   	push   %esi
  800e9f:	53                   	push   %ebx
  800ea0:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ea3:	bb 00 00 00 00       	mov    $0x0,%ebx
  800ea8:	b8 06 00 00 00       	mov    $0x6,%eax
  800ead:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800eb0:	8b 55 08             	mov    0x8(%ebp),%edx
  800eb3:	89 df                	mov    %ebx,%edi
  800eb5:	89 de                	mov    %ebx,%esi
  800eb7:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800eb9:	85 c0                	test   %eax,%eax
  800ebb:	7e 28                	jle    800ee5 <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ebd:	89 44 24 10          	mov    %eax,0x10(%esp)
  800ec1:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800ec8:	00 
  800ec9:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800ed0:	00 
  800ed1:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ed8:	00 
  800ed9:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800ee0:	e8 cf f3 ff ff       	call   8002b4 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800ee5:	83 c4 2c             	add    $0x2c,%esp
  800ee8:	5b                   	pop    %ebx
  800ee9:	5e                   	pop    %esi
  800eea:	5f                   	pop    %edi
  800eeb:	5d                   	pop    %ebp
  800eec:	c3                   	ret    

00800eed <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800eed:	55                   	push   %ebp
  800eee:	89 e5                	mov    %esp,%ebp
  800ef0:	57                   	push   %edi
  800ef1:	56                   	push   %esi
  800ef2:	53                   	push   %ebx
  800ef3:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ef6:	bb 00 00 00 00       	mov    $0x0,%ebx
  800efb:	b8 08 00 00 00       	mov    $0x8,%eax
  800f00:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f03:	8b 55 08             	mov    0x8(%ebp),%edx
  800f06:	89 df                	mov    %ebx,%edi
  800f08:	89 de                	mov    %ebx,%esi
  800f0a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f0c:	85 c0                	test   %eax,%eax
  800f0e:	7e 28                	jle    800f38 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f10:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f14:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800f1b:	00 
  800f1c:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800f23:	00 
  800f24:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f2b:	00 
  800f2c:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800f33:	e8 7c f3 ff ff       	call   8002b4 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800f38:	83 c4 2c             	add    $0x2c,%esp
  800f3b:	5b                   	pop    %ebx
  800f3c:	5e                   	pop    %esi
  800f3d:	5f                   	pop    %edi
  800f3e:	5d                   	pop    %ebp
  800f3f:	c3                   	ret    

00800f40 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800f40:	55                   	push   %ebp
  800f41:	89 e5                	mov    %esp,%ebp
  800f43:	57                   	push   %edi
  800f44:	56                   	push   %esi
  800f45:	53                   	push   %ebx
  800f46:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f49:	bb 00 00 00 00       	mov    $0x0,%ebx
  800f4e:	b8 09 00 00 00       	mov    $0x9,%eax
  800f53:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f56:	8b 55 08             	mov    0x8(%ebp),%edx
  800f59:	89 df                	mov    %ebx,%edi
  800f5b:	89 de                	mov    %ebx,%esi
  800f5d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f5f:	85 c0                	test   %eax,%eax
  800f61:	7e 28                	jle    800f8b <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f63:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f67:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800f6e:	00 
  800f6f:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800f76:	00 
  800f77:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f7e:	00 
  800f7f:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800f86:	e8 29 f3 ff ff       	call   8002b4 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800f8b:	83 c4 2c             	add    $0x2c,%esp
  800f8e:	5b                   	pop    %ebx
  800f8f:	5e                   	pop    %esi
  800f90:	5f                   	pop    %edi
  800f91:	5d                   	pop    %ebp
  800f92:	c3                   	ret    

00800f93 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800f93:	55                   	push   %ebp
  800f94:	89 e5                	mov    %esp,%ebp
  800f96:	57                   	push   %edi
  800f97:	56                   	push   %esi
  800f98:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f99:	be 00 00 00 00       	mov    $0x0,%esi
  800f9e:	b8 0b 00 00 00       	mov    $0xb,%eax
  800fa3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800fa6:	8b 55 08             	mov    0x8(%ebp),%edx
  800fa9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800fac:	8b 7d 14             	mov    0x14(%ebp),%edi
  800faf:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800fb1:	5b                   	pop    %ebx
  800fb2:	5e                   	pop    %esi
  800fb3:	5f                   	pop    %edi
  800fb4:	5d                   	pop    %ebp
  800fb5:	c3                   	ret    

00800fb6 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800fb6:	55                   	push   %ebp
  800fb7:	89 e5                	mov    %esp,%ebp
  800fb9:	57                   	push   %edi
  800fba:	56                   	push   %esi
  800fbb:	53                   	push   %ebx
  800fbc:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800fbf:	b9 00 00 00 00       	mov    $0x0,%ecx
  800fc4:	b8 0c 00 00 00       	mov    $0xc,%eax
  800fc9:	8b 55 08             	mov    0x8(%ebp),%edx
  800fcc:	89 cb                	mov    %ecx,%ebx
  800fce:	89 cf                	mov    %ecx,%edi
  800fd0:	89 ce                	mov    %ecx,%esi
  800fd2:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800fd4:	85 c0                	test   %eax,%eax
  800fd6:	7e 28                	jle    801000 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800fd8:	89 44 24 10          	mov    %eax,0x10(%esp)
  800fdc:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800fe3:	00 
  800fe4:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800feb:	00 
  800fec:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ff3:	00 
  800ff4:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800ffb:	e8 b4 f2 ff ff       	call   8002b4 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  801000:	83 c4 2c             	add    $0x2c,%esp
  801003:	5b                   	pop    %ebx
  801004:	5e                   	pop    %esi
  801005:	5f                   	pop    %edi
  801006:	5d                   	pop    %ebp
  801007:	c3                   	ret    
  801008:	66 90                	xchg   %ax,%ax
  80100a:	66 90                	xchg   %ax,%ax
  80100c:	66 90                	xchg   %ax,%ax
  80100e:	66 90                	xchg   %ax,%ax

00801010 <__udivdi3>:
  801010:	55                   	push   %ebp
  801011:	57                   	push   %edi
  801012:	56                   	push   %esi
  801013:	83 ec 0c             	sub    $0xc,%esp
  801016:	8b 44 24 28          	mov    0x28(%esp),%eax
  80101a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  80101e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  801022:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  801026:	85 c0                	test   %eax,%eax
  801028:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80102c:	89 ea                	mov    %ebp,%edx
  80102e:	89 0c 24             	mov    %ecx,(%esp)
  801031:	75 2d                	jne    801060 <__udivdi3+0x50>
  801033:	39 e9                	cmp    %ebp,%ecx
  801035:	77 61                	ja     801098 <__udivdi3+0x88>
  801037:	85 c9                	test   %ecx,%ecx
  801039:	89 ce                	mov    %ecx,%esi
  80103b:	75 0b                	jne    801048 <__udivdi3+0x38>
  80103d:	b8 01 00 00 00       	mov    $0x1,%eax
  801042:	31 d2                	xor    %edx,%edx
  801044:	f7 f1                	div    %ecx
  801046:	89 c6                	mov    %eax,%esi
  801048:	31 d2                	xor    %edx,%edx
  80104a:	89 e8                	mov    %ebp,%eax
  80104c:	f7 f6                	div    %esi
  80104e:	89 c5                	mov    %eax,%ebp
  801050:	89 f8                	mov    %edi,%eax
  801052:	f7 f6                	div    %esi
  801054:	89 ea                	mov    %ebp,%edx
  801056:	83 c4 0c             	add    $0xc,%esp
  801059:	5e                   	pop    %esi
  80105a:	5f                   	pop    %edi
  80105b:	5d                   	pop    %ebp
  80105c:	c3                   	ret    
  80105d:	8d 76 00             	lea    0x0(%esi),%esi
  801060:	39 e8                	cmp    %ebp,%eax
  801062:	77 24                	ja     801088 <__udivdi3+0x78>
  801064:	0f bd e8             	bsr    %eax,%ebp
  801067:	83 f5 1f             	xor    $0x1f,%ebp
  80106a:	75 3c                	jne    8010a8 <__udivdi3+0x98>
  80106c:	8b 74 24 04          	mov    0x4(%esp),%esi
  801070:	39 34 24             	cmp    %esi,(%esp)
  801073:	0f 86 9f 00 00 00    	jbe    801118 <__udivdi3+0x108>
  801079:	39 d0                	cmp    %edx,%eax
  80107b:	0f 82 97 00 00 00    	jb     801118 <__udivdi3+0x108>
  801081:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801088:	31 d2                	xor    %edx,%edx
  80108a:	31 c0                	xor    %eax,%eax
  80108c:	83 c4 0c             	add    $0xc,%esp
  80108f:	5e                   	pop    %esi
  801090:	5f                   	pop    %edi
  801091:	5d                   	pop    %ebp
  801092:	c3                   	ret    
  801093:	90                   	nop
  801094:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801098:	89 f8                	mov    %edi,%eax
  80109a:	f7 f1                	div    %ecx
  80109c:	31 d2                	xor    %edx,%edx
  80109e:	83 c4 0c             	add    $0xc,%esp
  8010a1:	5e                   	pop    %esi
  8010a2:	5f                   	pop    %edi
  8010a3:	5d                   	pop    %ebp
  8010a4:	c3                   	ret    
  8010a5:	8d 76 00             	lea    0x0(%esi),%esi
  8010a8:	89 e9                	mov    %ebp,%ecx
  8010aa:	8b 3c 24             	mov    (%esp),%edi
  8010ad:	d3 e0                	shl    %cl,%eax
  8010af:	89 c6                	mov    %eax,%esi
  8010b1:	b8 20 00 00 00       	mov    $0x20,%eax
  8010b6:	29 e8                	sub    %ebp,%eax
  8010b8:	89 c1                	mov    %eax,%ecx
  8010ba:	d3 ef                	shr    %cl,%edi
  8010bc:	89 e9                	mov    %ebp,%ecx
  8010be:	89 7c 24 08          	mov    %edi,0x8(%esp)
  8010c2:	8b 3c 24             	mov    (%esp),%edi
  8010c5:	09 74 24 08          	or     %esi,0x8(%esp)
  8010c9:	89 d6                	mov    %edx,%esi
  8010cb:	d3 e7                	shl    %cl,%edi
  8010cd:	89 c1                	mov    %eax,%ecx
  8010cf:	89 3c 24             	mov    %edi,(%esp)
  8010d2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8010d6:	d3 ee                	shr    %cl,%esi
  8010d8:	89 e9                	mov    %ebp,%ecx
  8010da:	d3 e2                	shl    %cl,%edx
  8010dc:	89 c1                	mov    %eax,%ecx
  8010de:	d3 ef                	shr    %cl,%edi
  8010e0:	09 d7                	or     %edx,%edi
  8010e2:	89 f2                	mov    %esi,%edx
  8010e4:	89 f8                	mov    %edi,%eax
  8010e6:	f7 74 24 08          	divl   0x8(%esp)
  8010ea:	89 d6                	mov    %edx,%esi
  8010ec:	89 c7                	mov    %eax,%edi
  8010ee:	f7 24 24             	mull   (%esp)
  8010f1:	39 d6                	cmp    %edx,%esi
  8010f3:	89 14 24             	mov    %edx,(%esp)
  8010f6:	72 30                	jb     801128 <__udivdi3+0x118>
  8010f8:	8b 54 24 04          	mov    0x4(%esp),%edx
  8010fc:	89 e9                	mov    %ebp,%ecx
  8010fe:	d3 e2                	shl    %cl,%edx
  801100:	39 c2                	cmp    %eax,%edx
  801102:	73 05                	jae    801109 <__udivdi3+0xf9>
  801104:	3b 34 24             	cmp    (%esp),%esi
  801107:	74 1f                	je     801128 <__udivdi3+0x118>
  801109:	89 f8                	mov    %edi,%eax
  80110b:	31 d2                	xor    %edx,%edx
  80110d:	e9 7a ff ff ff       	jmp    80108c <__udivdi3+0x7c>
  801112:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801118:	31 d2                	xor    %edx,%edx
  80111a:	b8 01 00 00 00       	mov    $0x1,%eax
  80111f:	e9 68 ff ff ff       	jmp    80108c <__udivdi3+0x7c>
  801124:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801128:	8d 47 ff             	lea    -0x1(%edi),%eax
  80112b:	31 d2                	xor    %edx,%edx
  80112d:	83 c4 0c             	add    $0xc,%esp
  801130:	5e                   	pop    %esi
  801131:	5f                   	pop    %edi
  801132:	5d                   	pop    %ebp
  801133:	c3                   	ret    
  801134:	66 90                	xchg   %ax,%ax
  801136:	66 90                	xchg   %ax,%ax
  801138:	66 90                	xchg   %ax,%ax
  80113a:	66 90                	xchg   %ax,%ax
  80113c:	66 90                	xchg   %ax,%ax
  80113e:	66 90                	xchg   %ax,%ax

00801140 <__umoddi3>:
  801140:	55                   	push   %ebp
  801141:	57                   	push   %edi
  801142:	56                   	push   %esi
  801143:	83 ec 14             	sub    $0x14,%esp
  801146:	8b 44 24 28          	mov    0x28(%esp),%eax
  80114a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  80114e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  801152:	89 c7                	mov    %eax,%edi
  801154:	89 44 24 04          	mov    %eax,0x4(%esp)
  801158:	8b 44 24 30          	mov    0x30(%esp),%eax
  80115c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  801160:	89 34 24             	mov    %esi,(%esp)
  801163:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801167:	85 c0                	test   %eax,%eax
  801169:	89 c2                	mov    %eax,%edx
  80116b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80116f:	75 17                	jne    801188 <__umoddi3+0x48>
  801171:	39 fe                	cmp    %edi,%esi
  801173:	76 4b                	jbe    8011c0 <__umoddi3+0x80>
  801175:	89 c8                	mov    %ecx,%eax
  801177:	89 fa                	mov    %edi,%edx
  801179:	f7 f6                	div    %esi
  80117b:	89 d0                	mov    %edx,%eax
  80117d:	31 d2                	xor    %edx,%edx
  80117f:	83 c4 14             	add    $0x14,%esp
  801182:	5e                   	pop    %esi
  801183:	5f                   	pop    %edi
  801184:	5d                   	pop    %ebp
  801185:	c3                   	ret    
  801186:	66 90                	xchg   %ax,%ax
  801188:	39 f8                	cmp    %edi,%eax
  80118a:	77 54                	ja     8011e0 <__umoddi3+0xa0>
  80118c:	0f bd e8             	bsr    %eax,%ebp
  80118f:	83 f5 1f             	xor    $0x1f,%ebp
  801192:	75 5c                	jne    8011f0 <__umoddi3+0xb0>
  801194:	8b 7c 24 08          	mov    0x8(%esp),%edi
  801198:	39 3c 24             	cmp    %edi,(%esp)
  80119b:	0f 87 e7 00 00 00    	ja     801288 <__umoddi3+0x148>
  8011a1:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8011a5:	29 f1                	sub    %esi,%ecx
  8011a7:	19 c7                	sbb    %eax,%edi
  8011a9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8011ad:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8011b1:	8b 44 24 08          	mov    0x8(%esp),%eax
  8011b5:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8011b9:	83 c4 14             	add    $0x14,%esp
  8011bc:	5e                   	pop    %esi
  8011bd:	5f                   	pop    %edi
  8011be:	5d                   	pop    %ebp
  8011bf:	c3                   	ret    
  8011c0:	85 f6                	test   %esi,%esi
  8011c2:	89 f5                	mov    %esi,%ebp
  8011c4:	75 0b                	jne    8011d1 <__umoddi3+0x91>
  8011c6:	b8 01 00 00 00       	mov    $0x1,%eax
  8011cb:	31 d2                	xor    %edx,%edx
  8011cd:	f7 f6                	div    %esi
  8011cf:	89 c5                	mov    %eax,%ebp
  8011d1:	8b 44 24 04          	mov    0x4(%esp),%eax
  8011d5:	31 d2                	xor    %edx,%edx
  8011d7:	f7 f5                	div    %ebp
  8011d9:	89 c8                	mov    %ecx,%eax
  8011db:	f7 f5                	div    %ebp
  8011dd:	eb 9c                	jmp    80117b <__umoddi3+0x3b>
  8011df:	90                   	nop
  8011e0:	89 c8                	mov    %ecx,%eax
  8011e2:	89 fa                	mov    %edi,%edx
  8011e4:	83 c4 14             	add    $0x14,%esp
  8011e7:	5e                   	pop    %esi
  8011e8:	5f                   	pop    %edi
  8011e9:	5d                   	pop    %ebp
  8011ea:	c3                   	ret    
  8011eb:	90                   	nop
  8011ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8011f0:	8b 04 24             	mov    (%esp),%eax
  8011f3:	be 20 00 00 00       	mov    $0x20,%esi
  8011f8:	89 e9                	mov    %ebp,%ecx
  8011fa:	29 ee                	sub    %ebp,%esi
  8011fc:	d3 e2                	shl    %cl,%edx
  8011fe:	89 f1                	mov    %esi,%ecx
  801200:	d3 e8                	shr    %cl,%eax
  801202:	89 e9                	mov    %ebp,%ecx
  801204:	89 44 24 04          	mov    %eax,0x4(%esp)
  801208:	8b 04 24             	mov    (%esp),%eax
  80120b:	09 54 24 04          	or     %edx,0x4(%esp)
  80120f:	89 fa                	mov    %edi,%edx
  801211:	d3 e0                	shl    %cl,%eax
  801213:	89 f1                	mov    %esi,%ecx
  801215:	89 44 24 08          	mov    %eax,0x8(%esp)
  801219:	8b 44 24 10          	mov    0x10(%esp),%eax
  80121d:	d3 ea                	shr    %cl,%edx
  80121f:	89 e9                	mov    %ebp,%ecx
  801221:	d3 e7                	shl    %cl,%edi
  801223:	89 f1                	mov    %esi,%ecx
  801225:	d3 e8                	shr    %cl,%eax
  801227:	89 e9                	mov    %ebp,%ecx
  801229:	09 f8                	or     %edi,%eax
  80122b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80122f:	f7 74 24 04          	divl   0x4(%esp)
  801233:	d3 e7                	shl    %cl,%edi
  801235:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801239:	89 d7                	mov    %edx,%edi
  80123b:	f7 64 24 08          	mull   0x8(%esp)
  80123f:	39 d7                	cmp    %edx,%edi
  801241:	89 c1                	mov    %eax,%ecx
  801243:	89 14 24             	mov    %edx,(%esp)
  801246:	72 2c                	jb     801274 <__umoddi3+0x134>
  801248:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  80124c:	72 22                	jb     801270 <__umoddi3+0x130>
  80124e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801252:	29 c8                	sub    %ecx,%eax
  801254:	19 d7                	sbb    %edx,%edi
  801256:	89 e9                	mov    %ebp,%ecx
  801258:	89 fa                	mov    %edi,%edx
  80125a:	d3 e8                	shr    %cl,%eax
  80125c:	89 f1                	mov    %esi,%ecx
  80125e:	d3 e2                	shl    %cl,%edx
  801260:	89 e9                	mov    %ebp,%ecx
  801262:	d3 ef                	shr    %cl,%edi
  801264:	09 d0                	or     %edx,%eax
  801266:	89 fa                	mov    %edi,%edx
  801268:	83 c4 14             	add    $0x14,%esp
  80126b:	5e                   	pop    %esi
  80126c:	5f                   	pop    %edi
  80126d:	5d                   	pop    %ebp
  80126e:	c3                   	ret    
  80126f:	90                   	nop
  801270:	39 d7                	cmp    %edx,%edi
  801272:	75 da                	jne    80124e <__umoddi3+0x10e>
  801274:	8b 14 24             	mov    (%esp),%edx
  801277:	89 c1                	mov    %eax,%ecx
  801279:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  80127d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  801281:	eb cb                	jmp    80124e <__umoddi3+0x10e>
  801283:	90                   	nop
  801284:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801288:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  80128c:	0f 82 0f ff ff ff    	jb     8011a1 <__umoddi3+0x61>
  801292:	e9 1a ff ff ff       	jmp    8011b1 <__umoddi3+0x71>
