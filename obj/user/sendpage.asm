
obj/user/sendpage:     file format elf32-i386


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
  80002c:	e8 af 01 00 00       	call   8001e0 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
#define TEMP_ADDR	((char*)0xa00000)
#define TEMP_ADDR_CHILD	((char*)0xb00000)

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 28             	sub    $0x28,%esp
	envid_t who;

	if ((who = fork()) == 0) {
  800039:	e8 0a 0f 00 00       	call   800f48 <fork>
  80003e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  800041:	85 c0                	test   %eax,%eax
  800043:	0f 85 bd 00 00 00    	jne    800106 <umain+0xd3>
		// Child
		ipc_recv(&who, TEMP_ADDR_CHILD, 0);
  800049:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800050:	00 
  800051:	c7 44 24 04 00 00 b0 	movl   $0xb00000,0x4(%esp)
  800058:	00 
  800059:	8d 45 f4             	lea    -0xc(%ebp),%eax
  80005c:	89 04 24             	mov    %eax,(%esp)
  80005f:	e8 28 0f 00 00       	call   800f8c <ipc_recv>
		cprintf("%x got message: %s\n", who, TEMP_ADDR_CHILD);
  800064:	c7 44 24 08 00 00 b0 	movl   $0xb00000,0x8(%esp)
  80006b:	00 
  80006c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80006f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800073:	c7 04 24 00 13 80 00 	movl   $0x801300,(%esp)
  80007a:	e8 6a 02 00 00       	call   8002e9 <cprintf>
		if (strncmp(TEMP_ADDR_CHILD, str1, strlen(str1)) == 0)
  80007f:	a1 04 20 80 00       	mov    0x802004,%eax
  800084:	89 04 24             	mov    %eax,(%esp)
  800087:	e8 54 08 00 00       	call   8008e0 <strlen>
  80008c:	89 44 24 08          	mov    %eax,0x8(%esp)
  800090:	a1 04 20 80 00       	mov    0x802004,%eax
  800095:	89 44 24 04          	mov    %eax,0x4(%esp)
  800099:	c7 04 24 00 00 b0 00 	movl   $0xb00000,(%esp)
  8000a0:	e8 4d 09 00 00       	call   8009f2 <strncmp>
  8000a5:	85 c0                	test   %eax,%eax
  8000a7:	75 0c                	jne    8000b5 <umain+0x82>
			cprintf("child received correct message\n");
  8000a9:	c7 04 24 14 13 80 00 	movl   $0x801314,(%esp)
  8000b0:	e8 34 02 00 00       	call   8002e9 <cprintf>

		memcpy(TEMP_ADDR_CHILD, str2, strlen(str2) + 1);
  8000b5:	a1 00 20 80 00       	mov    0x802000,%eax
  8000ba:	89 04 24             	mov    %eax,(%esp)
  8000bd:	e8 1e 08 00 00       	call   8008e0 <strlen>
  8000c2:	83 c0 01             	add    $0x1,%eax
  8000c5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8000c9:	a1 00 20 80 00       	mov    0x802000,%eax
  8000ce:	89 44 24 04          	mov    %eax,0x4(%esp)
  8000d2:	c7 04 24 00 00 b0 00 	movl   $0xb00000,(%esp)
  8000d9:	e8 3e 0a 00 00       	call   800b1c <memcpy>
		ipc_send(who, 0, TEMP_ADDR_CHILD, PTE_P | PTE_W | PTE_U);
  8000de:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
  8000e5:	00 
  8000e6:	c7 44 24 08 00 00 b0 	movl   $0xb00000,0x8(%esp)
  8000ed:	00 
  8000ee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8000f5:	00 
  8000f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8000f9:	89 04 24             	mov    %eax,(%esp)
  8000fc:	e8 ad 0e 00 00       	call   800fae <ipc_send>
		return;
  800101:	e9 d8 00 00 00       	jmp    8001de <umain+0x1ab>
	}

	// Parent
	sys_page_alloc(thisenv->env_id, TEMP_ADDR, PTE_P | PTE_W | PTE_U);
  800106:	a1 0c 20 80 00       	mov    0x80200c,%eax
  80010b:	8b 40 48             	mov    0x48(%eax),%eax
  80010e:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  800115:	00 
  800116:	c7 44 24 04 00 00 a0 	movl   $0xa00000,0x4(%esp)
  80011d:	00 
  80011e:	89 04 24             	mov    %eax,(%esp)
  800121:	e8 0d 0c 00 00       	call   800d33 <sys_page_alloc>
	memcpy(TEMP_ADDR, str1, strlen(str1) + 1);
  800126:	a1 04 20 80 00       	mov    0x802004,%eax
  80012b:	89 04 24             	mov    %eax,(%esp)
  80012e:	e8 ad 07 00 00       	call   8008e0 <strlen>
  800133:	83 c0 01             	add    $0x1,%eax
  800136:	89 44 24 08          	mov    %eax,0x8(%esp)
  80013a:	a1 04 20 80 00       	mov    0x802004,%eax
  80013f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800143:	c7 04 24 00 00 a0 00 	movl   $0xa00000,(%esp)
  80014a:	e8 cd 09 00 00       	call   800b1c <memcpy>
	ipc_send(who, 0, TEMP_ADDR, PTE_P | PTE_W | PTE_U);
  80014f:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
  800156:	00 
  800157:	c7 44 24 08 00 00 a0 	movl   $0xa00000,0x8(%esp)
  80015e:	00 
  80015f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800166:	00 
  800167:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80016a:	89 04 24             	mov    %eax,(%esp)
  80016d:	e8 3c 0e 00 00       	call   800fae <ipc_send>

	ipc_recv(&who, TEMP_ADDR, 0);
  800172:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800179:	00 
  80017a:	c7 44 24 04 00 00 a0 	movl   $0xa00000,0x4(%esp)
  800181:	00 
  800182:	8d 45 f4             	lea    -0xc(%ebp),%eax
  800185:	89 04 24             	mov    %eax,(%esp)
  800188:	e8 ff 0d 00 00       	call   800f8c <ipc_recv>
	cprintf("%x got message: %s\n", who, TEMP_ADDR);
  80018d:	c7 44 24 08 00 00 a0 	movl   $0xa00000,0x8(%esp)
  800194:	00 
  800195:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800198:	89 44 24 04          	mov    %eax,0x4(%esp)
  80019c:	c7 04 24 00 13 80 00 	movl   $0x801300,(%esp)
  8001a3:	e8 41 01 00 00       	call   8002e9 <cprintf>
	if (strncmp(TEMP_ADDR, str2, strlen(str2)) == 0)
  8001a8:	a1 00 20 80 00       	mov    0x802000,%eax
  8001ad:	89 04 24             	mov    %eax,(%esp)
  8001b0:	e8 2b 07 00 00       	call   8008e0 <strlen>
  8001b5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001b9:	a1 00 20 80 00       	mov    0x802000,%eax
  8001be:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001c2:	c7 04 24 00 00 a0 00 	movl   $0xa00000,(%esp)
  8001c9:	e8 24 08 00 00       	call   8009f2 <strncmp>
  8001ce:	85 c0                	test   %eax,%eax
  8001d0:	75 0c                	jne    8001de <umain+0x1ab>
		cprintf("parent received correct message\n");
  8001d2:	c7 04 24 34 13 80 00 	movl   $0x801334,(%esp)
  8001d9:	e8 0b 01 00 00       	call   8002e9 <cprintf>
	return;
}
  8001de:	c9                   	leave  
  8001df:	c3                   	ret    

008001e0 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8001e0:	55                   	push   %ebp
  8001e1:	89 e5                	mov    %esp,%ebp
  8001e3:	56                   	push   %esi
  8001e4:	53                   	push   %ebx
  8001e5:	83 ec 10             	sub    $0x10,%esp
  8001e8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8001eb:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  8001ee:	c7 05 0c 20 80 00 00 	movl   $0x0,0x80200c
  8001f5:	00 00 00 
	thisenv = &envs[ENVX(sys_getenvid())]; 
  8001f8:	e8 f8 0a 00 00       	call   800cf5 <sys_getenvid>
  8001fd:	25 ff 03 00 00       	and    $0x3ff,%eax
  800202:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800205:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80020a:	a3 0c 20 80 00       	mov    %eax,0x80200c
	// save the name of the program so that panic() can use it
	if (argc > 0)
  80020f:	85 db                	test   %ebx,%ebx
  800211:	7e 07                	jle    80021a <libmain+0x3a>
		binaryname = argv[0];
  800213:	8b 06                	mov    (%esi),%eax
  800215:	a3 08 20 80 00       	mov    %eax,0x802008

	// call user main routine
	umain(argc, argv);
  80021a:	89 74 24 04          	mov    %esi,0x4(%esp)
  80021e:	89 1c 24             	mov    %ebx,(%esp)
  800221:	e8 0d fe ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800226:	e8 07 00 00 00       	call   800232 <exit>
}
  80022b:	83 c4 10             	add    $0x10,%esp
  80022e:	5b                   	pop    %ebx
  80022f:	5e                   	pop    %esi
  800230:	5d                   	pop    %ebp
  800231:	c3                   	ret    

00800232 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800232:	55                   	push   %ebp
  800233:	89 e5                	mov    %esp,%ebp
  800235:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800238:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80023f:	e8 5f 0a 00 00       	call   800ca3 <sys_env_destroy>
}
  800244:	c9                   	leave  
  800245:	c3                   	ret    

00800246 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800246:	55                   	push   %ebp
  800247:	89 e5                	mov    %esp,%ebp
  800249:	53                   	push   %ebx
  80024a:	83 ec 14             	sub    $0x14,%esp
  80024d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800250:	8b 13                	mov    (%ebx),%edx
  800252:	8d 42 01             	lea    0x1(%edx),%eax
  800255:	89 03                	mov    %eax,(%ebx)
  800257:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80025a:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80025e:	3d ff 00 00 00       	cmp    $0xff,%eax
  800263:	75 19                	jne    80027e <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800265:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80026c:	00 
  80026d:	8d 43 08             	lea    0x8(%ebx),%eax
  800270:	89 04 24             	mov    %eax,(%esp)
  800273:	e8 ee 09 00 00       	call   800c66 <sys_cputs>
		b->idx = 0;
  800278:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  80027e:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800282:	83 c4 14             	add    $0x14,%esp
  800285:	5b                   	pop    %ebx
  800286:	5d                   	pop    %ebp
  800287:	c3                   	ret    

00800288 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800288:	55                   	push   %ebp
  800289:	89 e5                	mov    %esp,%ebp
  80028b:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800291:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800298:	00 00 00 
	b.cnt = 0;
  80029b:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8002a2:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8002a5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002a8:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002ac:	8b 45 08             	mov    0x8(%ebp),%eax
  8002af:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002b3:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8002b9:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002bd:	c7 04 24 46 02 80 00 	movl   $0x800246,(%esp)
  8002c4:	e8 b5 01 00 00       	call   80047e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8002c9:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8002cf:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002d3:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8002d9:	89 04 24             	mov    %eax,(%esp)
  8002dc:	e8 85 09 00 00       	call   800c66 <sys_cputs>

	return b.cnt;
}
  8002e1:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8002e7:	c9                   	leave  
  8002e8:	c3                   	ret    

008002e9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8002e9:	55                   	push   %ebp
  8002ea:	89 e5                	mov    %esp,%ebp
  8002ec:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002ef:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002f2:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002f6:	8b 45 08             	mov    0x8(%ebp),%eax
  8002f9:	89 04 24             	mov    %eax,(%esp)
  8002fc:	e8 87 ff ff ff       	call   800288 <vcprintf>
	va_end(ap);

	return cnt;
}
  800301:	c9                   	leave  
  800302:	c3                   	ret    
  800303:	66 90                	xchg   %ax,%ax
  800305:	66 90                	xchg   %ax,%ax
  800307:	66 90                	xchg   %ax,%ax
  800309:	66 90                	xchg   %ax,%ax
  80030b:	66 90                	xchg   %ax,%ax
  80030d:	66 90                	xchg   %ax,%ax
  80030f:	90                   	nop

00800310 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800310:	55                   	push   %ebp
  800311:	89 e5                	mov    %esp,%ebp
  800313:	57                   	push   %edi
  800314:	56                   	push   %esi
  800315:	53                   	push   %ebx
  800316:	83 ec 3c             	sub    $0x3c,%esp
  800319:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80031c:	89 d7                	mov    %edx,%edi
  80031e:	8b 45 08             	mov    0x8(%ebp),%eax
  800321:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800324:	8b 45 0c             	mov    0xc(%ebp),%eax
  800327:	89 c3                	mov    %eax,%ebx
  800329:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80032c:	8b 45 10             	mov    0x10(%ebp),%eax
  80032f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800332:	b9 00 00 00 00       	mov    $0x0,%ecx
  800337:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80033a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80033d:	39 d9                	cmp    %ebx,%ecx
  80033f:	72 05                	jb     800346 <printnum+0x36>
  800341:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800344:	77 69                	ja     8003af <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800346:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800349:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80034d:	83 ee 01             	sub    $0x1,%esi
  800350:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800354:	89 44 24 08          	mov    %eax,0x8(%esp)
  800358:	8b 44 24 08          	mov    0x8(%esp),%eax
  80035c:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800360:	89 c3                	mov    %eax,%ebx
  800362:	89 d6                	mov    %edx,%esi
  800364:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800367:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80036a:	89 54 24 08          	mov    %edx,0x8(%esp)
  80036e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800372:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800375:	89 04 24             	mov    %eax,(%esp)
  800378:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80037b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80037f:	e8 dc 0c 00 00       	call   801060 <__udivdi3>
  800384:	89 d9                	mov    %ebx,%ecx
  800386:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80038a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80038e:	89 04 24             	mov    %eax,(%esp)
  800391:	89 54 24 04          	mov    %edx,0x4(%esp)
  800395:	89 fa                	mov    %edi,%edx
  800397:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80039a:	e8 71 ff ff ff       	call   800310 <printnum>
  80039f:	eb 1b                	jmp    8003bc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8003a1:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003a5:	8b 45 18             	mov    0x18(%ebp),%eax
  8003a8:	89 04 24             	mov    %eax,(%esp)
  8003ab:	ff d3                	call   *%ebx
  8003ad:	eb 03                	jmp    8003b2 <printnum+0xa2>
  8003af:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8003b2:	83 ee 01             	sub    $0x1,%esi
  8003b5:	85 f6                	test   %esi,%esi
  8003b7:	7f e8                	jg     8003a1 <printnum+0x91>
  8003b9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8003bc:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003c0:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8003c4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  8003c7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8003ca:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003ce:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8003d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003d5:	89 04 24             	mov    %eax,(%esp)
  8003d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003db:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003df:	e8 ac 0d 00 00       	call   801190 <__umoddi3>
  8003e4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003e8:	0f be 80 ac 13 80 00 	movsbl 0x8013ac(%eax),%eax
  8003ef:	89 04 24             	mov    %eax,(%esp)
  8003f2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8003f5:	ff d0                	call   *%eax
}
  8003f7:	83 c4 3c             	add    $0x3c,%esp
  8003fa:	5b                   	pop    %ebx
  8003fb:	5e                   	pop    %esi
  8003fc:	5f                   	pop    %edi
  8003fd:	5d                   	pop    %ebp
  8003fe:	c3                   	ret    

008003ff <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8003ff:	55                   	push   %ebp
  800400:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800402:	83 fa 01             	cmp    $0x1,%edx
  800405:	7e 0e                	jle    800415 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800407:	8b 10                	mov    (%eax),%edx
  800409:	8d 4a 08             	lea    0x8(%edx),%ecx
  80040c:	89 08                	mov    %ecx,(%eax)
  80040e:	8b 02                	mov    (%edx),%eax
  800410:	8b 52 04             	mov    0x4(%edx),%edx
  800413:	eb 22                	jmp    800437 <getuint+0x38>
	else if (lflag)
  800415:	85 d2                	test   %edx,%edx
  800417:	74 10                	je     800429 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800419:	8b 10                	mov    (%eax),%edx
  80041b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80041e:	89 08                	mov    %ecx,(%eax)
  800420:	8b 02                	mov    (%edx),%eax
  800422:	ba 00 00 00 00       	mov    $0x0,%edx
  800427:	eb 0e                	jmp    800437 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800429:	8b 10                	mov    (%eax),%edx
  80042b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80042e:	89 08                	mov    %ecx,(%eax)
  800430:	8b 02                	mov    (%edx),%eax
  800432:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800437:	5d                   	pop    %ebp
  800438:	c3                   	ret    

00800439 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800439:	55                   	push   %ebp
  80043a:	89 e5                	mov    %esp,%ebp
  80043c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80043f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800443:	8b 10                	mov    (%eax),%edx
  800445:	3b 50 04             	cmp    0x4(%eax),%edx
  800448:	73 0a                	jae    800454 <sprintputch+0x1b>
		*b->buf++ = ch;
  80044a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80044d:	89 08                	mov    %ecx,(%eax)
  80044f:	8b 45 08             	mov    0x8(%ebp),%eax
  800452:	88 02                	mov    %al,(%edx)
}
  800454:	5d                   	pop    %ebp
  800455:	c3                   	ret    

00800456 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800456:	55                   	push   %ebp
  800457:	89 e5                	mov    %esp,%ebp
  800459:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  80045c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80045f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800463:	8b 45 10             	mov    0x10(%ebp),%eax
  800466:	89 44 24 08          	mov    %eax,0x8(%esp)
  80046a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80046d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800471:	8b 45 08             	mov    0x8(%ebp),%eax
  800474:	89 04 24             	mov    %eax,(%esp)
  800477:	e8 02 00 00 00       	call   80047e <vprintfmt>
	va_end(ap);
}
  80047c:	c9                   	leave  
  80047d:	c3                   	ret    

0080047e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80047e:	55                   	push   %ebp
  80047f:	89 e5                	mov    %esp,%ebp
  800481:	57                   	push   %edi
  800482:	56                   	push   %esi
  800483:	53                   	push   %ebx
  800484:	83 ec 3c             	sub    $0x3c,%esp
  800487:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80048a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80048d:	eb 14                	jmp    8004a3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80048f:	85 c0                	test   %eax,%eax
  800491:	0f 84 b3 03 00 00    	je     80084a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800497:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80049b:	89 04 24             	mov    %eax,(%esp)
  80049e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8004a1:	89 f3                	mov    %esi,%ebx
  8004a3:	8d 73 01             	lea    0x1(%ebx),%esi
  8004a6:	0f b6 03             	movzbl (%ebx),%eax
  8004a9:	83 f8 25             	cmp    $0x25,%eax
  8004ac:	75 e1                	jne    80048f <vprintfmt+0x11>
  8004ae:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  8004b2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  8004b9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  8004c0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  8004c7:	ba 00 00 00 00       	mov    $0x0,%edx
  8004cc:	eb 1d                	jmp    8004eb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ce:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  8004d0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  8004d4:	eb 15                	jmp    8004eb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8004d8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  8004dc:	eb 0d                	jmp    8004eb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8004de:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8004e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8004e4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004eb:	8d 5e 01             	lea    0x1(%esi),%ebx
  8004ee:	0f b6 0e             	movzbl (%esi),%ecx
  8004f1:	0f b6 c1             	movzbl %cl,%eax
  8004f4:	83 e9 23             	sub    $0x23,%ecx
  8004f7:	80 f9 55             	cmp    $0x55,%cl
  8004fa:	0f 87 2a 03 00 00    	ja     80082a <vprintfmt+0x3ac>
  800500:	0f b6 c9             	movzbl %cl,%ecx
  800503:	ff 24 8d 80 14 80 00 	jmp    *0x801480(,%ecx,4)
  80050a:	89 de                	mov    %ebx,%esi
  80050c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800511:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800514:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  800518:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80051b:	8d 58 d0             	lea    -0x30(%eax),%ebx
  80051e:	83 fb 09             	cmp    $0x9,%ebx
  800521:	77 36                	ja     800559 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800523:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800526:	eb e9                	jmp    800511 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800528:	8b 45 14             	mov    0x14(%ebp),%eax
  80052b:	8d 48 04             	lea    0x4(%eax),%ecx
  80052e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800531:	8b 00                	mov    (%eax),%eax
  800533:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800536:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800538:	eb 22                	jmp    80055c <vprintfmt+0xde>
  80053a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80053d:	85 c9                	test   %ecx,%ecx
  80053f:	b8 00 00 00 00       	mov    $0x0,%eax
  800544:	0f 49 c1             	cmovns %ecx,%eax
  800547:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80054a:	89 de                	mov    %ebx,%esi
  80054c:	eb 9d                	jmp    8004eb <vprintfmt+0x6d>
  80054e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800550:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  800557:	eb 92                	jmp    8004eb <vprintfmt+0x6d>
  800559:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  80055c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800560:	79 89                	jns    8004eb <vprintfmt+0x6d>
  800562:	e9 77 ff ff ff       	jmp    8004de <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800567:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80056a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80056c:	e9 7a ff ff ff       	jmp    8004eb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800571:	8b 45 14             	mov    0x14(%ebp),%eax
  800574:	8d 50 04             	lea    0x4(%eax),%edx
  800577:	89 55 14             	mov    %edx,0x14(%ebp)
  80057a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80057e:	8b 00                	mov    (%eax),%eax
  800580:	89 04 24             	mov    %eax,(%esp)
  800583:	ff 55 08             	call   *0x8(%ebp)
			break;
  800586:	e9 18 ff ff ff       	jmp    8004a3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80058b:	8b 45 14             	mov    0x14(%ebp),%eax
  80058e:	8d 50 04             	lea    0x4(%eax),%edx
  800591:	89 55 14             	mov    %edx,0x14(%ebp)
  800594:	8b 00                	mov    (%eax),%eax
  800596:	99                   	cltd   
  800597:	31 d0                	xor    %edx,%eax
  800599:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80059b:	83 f8 09             	cmp    $0x9,%eax
  80059e:	7f 0b                	jg     8005ab <vprintfmt+0x12d>
  8005a0:	8b 14 85 e0 15 80 00 	mov    0x8015e0(,%eax,4),%edx
  8005a7:	85 d2                	test   %edx,%edx
  8005a9:	75 20                	jne    8005cb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  8005ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8005af:	c7 44 24 08 c4 13 80 	movl   $0x8013c4,0x8(%esp)
  8005b6:	00 
  8005b7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005bb:	8b 45 08             	mov    0x8(%ebp),%eax
  8005be:	89 04 24             	mov    %eax,(%esp)
  8005c1:	e8 90 fe ff ff       	call   800456 <printfmt>
  8005c6:	e9 d8 fe ff ff       	jmp    8004a3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8005cb:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8005cf:	c7 44 24 08 cd 13 80 	movl   $0x8013cd,0x8(%esp)
  8005d6:	00 
  8005d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005db:	8b 45 08             	mov    0x8(%ebp),%eax
  8005de:	89 04 24             	mov    %eax,(%esp)
  8005e1:	e8 70 fe ff ff       	call   800456 <printfmt>
  8005e6:	e9 b8 fe ff ff       	jmp    8004a3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005eb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8005ee:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8005f1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8005f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f7:	8d 50 04             	lea    0x4(%eax),%edx
  8005fa:	89 55 14             	mov    %edx,0x14(%ebp)
  8005fd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  8005ff:	85 f6                	test   %esi,%esi
  800601:	b8 bd 13 80 00       	mov    $0x8013bd,%eax
  800606:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800609:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80060d:	0f 84 97 00 00 00    	je     8006aa <vprintfmt+0x22c>
  800613:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800617:	0f 8e 9b 00 00 00    	jle    8006b8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80061d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800621:	89 34 24             	mov    %esi,(%esp)
  800624:	e8 cf 02 00 00       	call   8008f8 <strnlen>
  800629:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80062c:	29 c2                	sub    %eax,%edx
  80062e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  800631:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  800635:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800638:	89 75 d8             	mov    %esi,-0x28(%ebp)
  80063b:	8b 75 08             	mov    0x8(%ebp),%esi
  80063e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800641:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800643:	eb 0f                	jmp    800654 <vprintfmt+0x1d6>
					putch(padc, putdat);
  800645:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800649:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80064c:	89 04 24             	mov    %eax,(%esp)
  80064f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800651:	83 eb 01             	sub    $0x1,%ebx
  800654:	85 db                	test   %ebx,%ebx
  800656:	7f ed                	jg     800645 <vprintfmt+0x1c7>
  800658:	8b 75 d8             	mov    -0x28(%ebp),%esi
  80065b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80065e:	85 d2                	test   %edx,%edx
  800660:	b8 00 00 00 00       	mov    $0x0,%eax
  800665:	0f 49 c2             	cmovns %edx,%eax
  800668:	29 c2                	sub    %eax,%edx
  80066a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80066d:	89 d7                	mov    %edx,%edi
  80066f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800672:	eb 50                	jmp    8006c4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800674:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800678:	74 1e                	je     800698 <vprintfmt+0x21a>
  80067a:	0f be d2             	movsbl %dl,%edx
  80067d:	83 ea 20             	sub    $0x20,%edx
  800680:	83 fa 5e             	cmp    $0x5e,%edx
  800683:	76 13                	jbe    800698 <vprintfmt+0x21a>
					putch('?', putdat);
  800685:	8b 45 0c             	mov    0xc(%ebp),%eax
  800688:	89 44 24 04          	mov    %eax,0x4(%esp)
  80068c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800693:	ff 55 08             	call   *0x8(%ebp)
  800696:	eb 0d                	jmp    8006a5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800698:	8b 55 0c             	mov    0xc(%ebp),%edx
  80069b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80069f:	89 04 24             	mov    %eax,(%esp)
  8006a2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006a5:	83 ef 01             	sub    $0x1,%edi
  8006a8:	eb 1a                	jmp    8006c4 <vprintfmt+0x246>
  8006aa:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8006ad:	8b 7d dc             	mov    -0x24(%ebp),%edi
  8006b0:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8006b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8006b6:	eb 0c                	jmp    8006c4 <vprintfmt+0x246>
  8006b8:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8006bb:	8b 7d dc             	mov    -0x24(%ebp),%edi
  8006be:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8006c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8006c4:	83 c6 01             	add    $0x1,%esi
  8006c7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  8006cb:	0f be c2             	movsbl %dl,%eax
  8006ce:	85 c0                	test   %eax,%eax
  8006d0:	74 27                	je     8006f9 <vprintfmt+0x27b>
  8006d2:	85 db                	test   %ebx,%ebx
  8006d4:	78 9e                	js     800674 <vprintfmt+0x1f6>
  8006d6:	83 eb 01             	sub    $0x1,%ebx
  8006d9:	79 99                	jns    800674 <vprintfmt+0x1f6>
  8006db:	89 f8                	mov    %edi,%eax
  8006dd:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8006e0:	8b 75 08             	mov    0x8(%ebp),%esi
  8006e3:	89 c3                	mov    %eax,%ebx
  8006e5:	eb 1a                	jmp    800701 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8006e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006eb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8006f2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8006f4:	83 eb 01             	sub    $0x1,%ebx
  8006f7:	eb 08                	jmp    800701 <vprintfmt+0x283>
  8006f9:	89 fb                	mov    %edi,%ebx
  8006fb:	8b 75 08             	mov    0x8(%ebp),%esi
  8006fe:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800701:	85 db                	test   %ebx,%ebx
  800703:	7f e2                	jg     8006e7 <vprintfmt+0x269>
  800705:	89 75 08             	mov    %esi,0x8(%ebp)
  800708:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80070b:	e9 93 fd ff ff       	jmp    8004a3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800710:	83 fa 01             	cmp    $0x1,%edx
  800713:	7e 16                	jle    80072b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  800715:	8b 45 14             	mov    0x14(%ebp),%eax
  800718:	8d 50 08             	lea    0x8(%eax),%edx
  80071b:	89 55 14             	mov    %edx,0x14(%ebp)
  80071e:	8b 50 04             	mov    0x4(%eax),%edx
  800721:	8b 00                	mov    (%eax),%eax
  800723:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800726:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800729:	eb 32                	jmp    80075d <vprintfmt+0x2df>
	else if (lflag)
  80072b:	85 d2                	test   %edx,%edx
  80072d:	74 18                	je     800747 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  80072f:	8b 45 14             	mov    0x14(%ebp),%eax
  800732:	8d 50 04             	lea    0x4(%eax),%edx
  800735:	89 55 14             	mov    %edx,0x14(%ebp)
  800738:	8b 30                	mov    (%eax),%esi
  80073a:	89 75 e0             	mov    %esi,-0x20(%ebp)
  80073d:	89 f0                	mov    %esi,%eax
  80073f:	c1 f8 1f             	sar    $0x1f,%eax
  800742:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800745:	eb 16                	jmp    80075d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  800747:	8b 45 14             	mov    0x14(%ebp),%eax
  80074a:	8d 50 04             	lea    0x4(%eax),%edx
  80074d:	89 55 14             	mov    %edx,0x14(%ebp)
  800750:	8b 30                	mov    (%eax),%esi
  800752:	89 75 e0             	mov    %esi,-0x20(%ebp)
  800755:	89 f0                	mov    %esi,%eax
  800757:	c1 f8 1f             	sar    $0x1f,%eax
  80075a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80075d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800760:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800763:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800768:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80076c:	0f 89 80 00 00 00    	jns    8007f2 <vprintfmt+0x374>
				putch('-', putdat);
  800772:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800776:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80077d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800780:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800783:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800786:	f7 d8                	neg    %eax
  800788:	83 d2 00             	adc    $0x0,%edx
  80078b:	f7 da                	neg    %edx
			}
			base = 10;
  80078d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800792:	eb 5e                	jmp    8007f2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800794:	8d 45 14             	lea    0x14(%ebp),%eax
  800797:	e8 63 fc ff ff       	call   8003ff <getuint>
			base = 10;
  80079c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8007a1:	eb 4f                	jmp    8007f2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  8007a3:	8d 45 14             	lea    0x14(%ebp),%eax
  8007a6:	e8 54 fc ff ff       	call   8003ff <getuint>
			base = 8;
  8007ab:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8007b0:	eb 40                	jmp    8007f2 <vprintfmt+0x374>
			
		// pointer
		case 'p':
			putch('0', putdat);
  8007b2:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007b6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8007bd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  8007c0:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007c4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8007cb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007ce:	8b 45 14             	mov    0x14(%ebp),%eax
  8007d1:	8d 50 04             	lea    0x4(%eax),%edx
  8007d4:	89 55 14             	mov    %edx,0x14(%ebp)
			
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007d7:	8b 00                	mov    (%eax),%eax
  8007d9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007de:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007e3:	eb 0d                	jmp    8007f2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007e5:	8d 45 14             	lea    0x14(%ebp),%eax
  8007e8:	e8 12 fc ff ff       	call   8003ff <getuint>
			base = 16;
  8007ed:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007f2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  8007f6:	89 74 24 10          	mov    %esi,0x10(%esp)
  8007fa:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8007fd:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800801:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800805:	89 04 24             	mov    %eax,(%esp)
  800808:	89 54 24 04          	mov    %edx,0x4(%esp)
  80080c:	89 fa                	mov    %edi,%edx
  80080e:	8b 45 08             	mov    0x8(%ebp),%eax
  800811:	e8 fa fa ff ff       	call   800310 <printnum>
			break;
  800816:	e9 88 fc ff ff       	jmp    8004a3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80081b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80081f:	89 04 24             	mov    %eax,(%esp)
  800822:	ff 55 08             	call   *0x8(%ebp)
			break;
  800825:	e9 79 fc ff ff       	jmp    8004a3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80082a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80082e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800835:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  800838:	89 f3                	mov    %esi,%ebx
  80083a:	eb 03                	jmp    80083f <vprintfmt+0x3c1>
  80083c:	83 eb 01             	sub    $0x1,%ebx
  80083f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  800843:	75 f7                	jne    80083c <vprintfmt+0x3be>
  800845:	e9 59 fc ff ff       	jmp    8004a3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  80084a:	83 c4 3c             	add    $0x3c,%esp
  80084d:	5b                   	pop    %ebx
  80084e:	5e                   	pop    %esi
  80084f:	5f                   	pop    %edi
  800850:	5d                   	pop    %ebp
  800851:	c3                   	ret    

00800852 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800852:	55                   	push   %ebp
  800853:	89 e5                	mov    %esp,%ebp
  800855:	83 ec 28             	sub    $0x28,%esp
  800858:	8b 45 08             	mov    0x8(%ebp),%eax
  80085b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80085e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800861:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800865:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800868:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80086f:	85 c0                	test   %eax,%eax
  800871:	74 30                	je     8008a3 <vsnprintf+0x51>
  800873:	85 d2                	test   %edx,%edx
  800875:	7e 2c                	jle    8008a3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800877:	8b 45 14             	mov    0x14(%ebp),%eax
  80087a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80087e:	8b 45 10             	mov    0x10(%ebp),%eax
  800881:	89 44 24 08          	mov    %eax,0x8(%esp)
  800885:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800888:	89 44 24 04          	mov    %eax,0x4(%esp)
  80088c:	c7 04 24 39 04 80 00 	movl   $0x800439,(%esp)
  800893:	e8 e6 fb ff ff       	call   80047e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800898:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80089b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80089e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8008a1:	eb 05                	jmp    8008a8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8008a3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8008a8:	c9                   	leave  
  8008a9:	c3                   	ret    

008008aa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8008aa:	55                   	push   %ebp
  8008ab:	89 e5                	mov    %esp,%ebp
  8008ad:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8008b0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8008b3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8008b7:	8b 45 10             	mov    0x10(%ebp),%eax
  8008ba:	89 44 24 08          	mov    %eax,0x8(%esp)
  8008be:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008c1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8008c5:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c8:	89 04 24             	mov    %eax,(%esp)
  8008cb:	e8 82 ff ff ff       	call   800852 <vsnprintf>
	va_end(ap);

	return rc;
}
  8008d0:	c9                   	leave  
  8008d1:	c3                   	ret    
  8008d2:	66 90                	xchg   %ax,%ax
  8008d4:	66 90                	xchg   %ax,%ax
  8008d6:	66 90                	xchg   %ax,%ax
  8008d8:	66 90                	xchg   %ax,%ax
  8008da:	66 90                	xchg   %ax,%ax
  8008dc:	66 90                	xchg   %ax,%ax
  8008de:	66 90                	xchg   %ax,%ax

008008e0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008e0:	55                   	push   %ebp
  8008e1:	89 e5                	mov    %esp,%ebp
  8008e3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008e6:	b8 00 00 00 00       	mov    $0x0,%eax
  8008eb:	eb 03                	jmp    8008f0 <strlen+0x10>
		n++;
  8008ed:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008f0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008f4:	75 f7                	jne    8008ed <strlen+0xd>
		n++;
	return n;
}
  8008f6:	5d                   	pop    %ebp
  8008f7:	c3                   	ret    

008008f8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008f8:	55                   	push   %ebp
  8008f9:	89 e5                	mov    %esp,%ebp
  8008fb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008fe:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800901:	b8 00 00 00 00       	mov    $0x0,%eax
  800906:	eb 03                	jmp    80090b <strnlen+0x13>
		n++;
  800908:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80090b:	39 d0                	cmp    %edx,%eax
  80090d:	74 06                	je     800915 <strnlen+0x1d>
  80090f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800913:	75 f3                	jne    800908 <strnlen+0x10>
		n++;
	return n;
}
  800915:	5d                   	pop    %ebp
  800916:	c3                   	ret    

00800917 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800917:	55                   	push   %ebp
  800918:	89 e5                	mov    %esp,%ebp
  80091a:	53                   	push   %ebx
  80091b:	8b 45 08             	mov    0x8(%ebp),%eax
  80091e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800921:	89 c2                	mov    %eax,%edx
  800923:	83 c2 01             	add    $0x1,%edx
  800926:	83 c1 01             	add    $0x1,%ecx
  800929:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80092d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800930:	84 db                	test   %bl,%bl
  800932:	75 ef                	jne    800923 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800934:	5b                   	pop    %ebx
  800935:	5d                   	pop    %ebp
  800936:	c3                   	ret    

00800937 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800937:	55                   	push   %ebp
  800938:	89 e5                	mov    %esp,%ebp
  80093a:	53                   	push   %ebx
  80093b:	83 ec 08             	sub    $0x8,%esp
  80093e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800941:	89 1c 24             	mov    %ebx,(%esp)
  800944:	e8 97 ff ff ff       	call   8008e0 <strlen>
	strcpy(dst + len, src);
  800949:	8b 55 0c             	mov    0xc(%ebp),%edx
  80094c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800950:	01 d8                	add    %ebx,%eax
  800952:	89 04 24             	mov    %eax,(%esp)
  800955:	e8 bd ff ff ff       	call   800917 <strcpy>
	return dst;
}
  80095a:	89 d8                	mov    %ebx,%eax
  80095c:	83 c4 08             	add    $0x8,%esp
  80095f:	5b                   	pop    %ebx
  800960:	5d                   	pop    %ebp
  800961:	c3                   	ret    

00800962 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800962:	55                   	push   %ebp
  800963:	89 e5                	mov    %esp,%ebp
  800965:	56                   	push   %esi
  800966:	53                   	push   %ebx
  800967:	8b 75 08             	mov    0x8(%ebp),%esi
  80096a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80096d:	89 f3                	mov    %esi,%ebx
  80096f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800972:	89 f2                	mov    %esi,%edx
  800974:	eb 0f                	jmp    800985 <strncpy+0x23>
		*dst++ = *src;
  800976:	83 c2 01             	add    $0x1,%edx
  800979:	0f b6 01             	movzbl (%ecx),%eax
  80097c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80097f:	80 39 01             	cmpb   $0x1,(%ecx)
  800982:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800985:	39 da                	cmp    %ebx,%edx
  800987:	75 ed                	jne    800976 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800989:	89 f0                	mov    %esi,%eax
  80098b:	5b                   	pop    %ebx
  80098c:	5e                   	pop    %esi
  80098d:	5d                   	pop    %ebp
  80098e:	c3                   	ret    

0080098f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80098f:	55                   	push   %ebp
  800990:	89 e5                	mov    %esp,%ebp
  800992:	56                   	push   %esi
  800993:	53                   	push   %ebx
  800994:	8b 75 08             	mov    0x8(%ebp),%esi
  800997:	8b 55 0c             	mov    0xc(%ebp),%edx
  80099a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80099d:	89 f0                	mov    %esi,%eax
  80099f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8009a3:	85 c9                	test   %ecx,%ecx
  8009a5:	75 0b                	jne    8009b2 <strlcpy+0x23>
  8009a7:	eb 1d                	jmp    8009c6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8009a9:	83 c0 01             	add    $0x1,%eax
  8009ac:	83 c2 01             	add    $0x1,%edx
  8009af:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8009b2:	39 d8                	cmp    %ebx,%eax
  8009b4:	74 0b                	je     8009c1 <strlcpy+0x32>
  8009b6:	0f b6 0a             	movzbl (%edx),%ecx
  8009b9:	84 c9                	test   %cl,%cl
  8009bb:	75 ec                	jne    8009a9 <strlcpy+0x1a>
  8009bd:	89 c2                	mov    %eax,%edx
  8009bf:	eb 02                	jmp    8009c3 <strlcpy+0x34>
  8009c1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  8009c3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  8009c6:	29 f0                	sub    %esi,%eax
}
  8009c8:	5b                   	pop    %ebx
  8009c9:	5e                   	pop    %esi
  8009ca:	5d                   	pop    %ebp
  8009cb:	c3                   	ret    

008009cc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8009cc:	55                   	push   %ebp
  8009cd:	89 e5                	mov    %esp,%ebp
  8009cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009d2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8009d5:	eb 06                	jmp    8009dd <strcmp+0x11>
		p++, q++;
  8009d7:	83 c1 01             	add    $0x1,%ecx
  8009da:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8009dd:	0f b6 01             	movzbl (%ecx),%eax
  8009e0:	84 c0                	test   %al,%al
  8009e2:	74 04                	je     8009e8 <strcmp+0x1c>
  8009e4:	3a 02                	cmp    (%edx),%al
  8009e6:	74 ef                	je     8009d7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009e8:	0f b6 c0             	movzbl %al,%eax
  8009eb:	0f b6 12             	movzbl (%edx),%edx
  8009ee:	29 d0                	sub    %edx,%eax
}
  8009f0:	5d                   	pop    %ebp
  8009f1:	c3                   	ret    

008009f2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009f2:	55                   	push   %ebp
  8009f3:	89 e5                	mov    %esp,%ebp
  8009f5:	53                   	push   %ebx
  8009f6:	8b 45 08             	mov    0x8(%ebp),%eax
  8009f9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009fc:	89 c3                	mov    %eax,%ebx
  8009fe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800a01:	eb 06                	jmp    800a09 <strncmp+0x17>
		n--, p++, q++;
  800a03:	83 c0 01             	add    $0x1,%eax
  800a06:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800a09:	39 d8                	cmp    %ebx,%eax
  800a0b:	74 15                	je     800a22 <strncmp+0x30>
  800a0d:	0f b6 08             	movzbl (%eax),%ecx
  800a10:	84 c9                	test   %cl,%cl
  800a12:	74 04                	je     800a18 <strncmp+0x26>
  800a14:	3a 0a                	cmp    (%edx),%cl
  800a16:	74 eb                	je     800a03 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800a18:	0f b6 00             	movzbl (%eax),%eax
  800a1b:	0f b6 12             	movzbl (%edx),%edx
  800a1e:	29 d0                	sub    %edx,%eax
  800a20:	eb 05                	jmp    800a27 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800a22:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800a27:	5b                   	pop    %ebx
  800a28:	5d                   	pop    %ebp
  800a29:	c3                   	ret    

00800a2a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800a2a:	55                   	push   %ebp
  800a2b:	89 e5                	mov    %esp,%ebp
  800a2d:	8b 45 08             	mov    0x8(%ebp),%eax
  800a30:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a34:	eb 07                	jmp    800a3d <strchr+0x13>
		if (*s == c)
  800a36:	38 ca                	cmp    %cl,%dl
  800a38:	74 0f                	je     800a49 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800a3a:	83 c0 01             	add    $0x1,%eax
  800a3d:	0f b6 10             	movzbl (%eax),%edx
  800a40:	84 d2                	test   %dl,%dl
  800a42:	75 f2                	jne    800a36 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800a44:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a49:	5d                   	pop    %ebp
  800a4a:	c3                   	ret    

00800a4b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a4b:	55                   	push   %ebp
  800a4c:	89 e5                	mov    %esp,%ebp
  800a4e:	8b 45 08             	mov    0x8(%ebp),%eax
  800a51:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a55:	eb 07                	jmp    800a5e <strfind+0x13>
		if (*s == c)
  800a57:	38 ca                	cmp    %cl,%dl
  800a59:	74 0a                	je     800a65 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800a5b:	83 c0 01             	add    $0x1,%eax
  800a5e:	0f b6 10             	movzbl (%eax),%edx
  800a61:	84 d2                	test   %dl,%dl
  800a63:	75 f2                	jne    800a57 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800a65:	5d                   	pop    %ebp
  800a66:	c3                   	ret    

00800a67 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a67:	55                   	push   %ebp
  800a68:	89 e5                	mov    %esp,%ebp
  800a6a:	57                   	push   %edi
  800a6b:	56                   	push   %esi
  800a6c:	53                   	push   %ebx
  800a6d:	8b 7d 08             	mov    0x8(%ebp),%edi
  800a70:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800a73:	85 c9                	test   %ecx,%ecx
  800a75:	74 36                	je     800aad <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a77:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a7d:	75 28                	jne    800aa7 <memset+0x40>
  800a7f:	f6 c1 03             	test   $0x3,%cl
  800a82:	75 23                	jne    800aa7 <memset+0x40>
		c &= 0xFF;
  800a84:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a88:	89 d3                	mov    %edx,%ebx
  800a8a:	c1 e3 08             	shl    $0x8,%ebx
  800a8d:	89 d6                	mov    %edx,%esi
  800a8f:	c1 e6 18             	shl    $0x18,%esi
  800a92:	89 d0                	mov    %edx,%eax
  800a94:	c1 e0 10             	shl    $0x10,%eax
  800a97:	09 f0                	or     %esi,%eax
  800a99:	09 c2                	or     %eax,%edx
  800a9b:	89 d0                	mov    %edx,%eax
  800a9d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a9f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800aa2:	fc                   	cld    
  800aa3:	f3 ab                	rep stos %eax,%es:(%edi)
  800aa5:	eb 06                	jmp    800aad <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800aa7:	8b 45 0c             	mov    0xc(%ebp),%eax
  800aaa:	fc                   	cld    
  800aab:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800aad:	89 f8                	mov    %edi,%eax
  800aaf:	5b                   	pop    %ebx
  800ab0:	5e                   	pop    %esi
  800ab1:	5f                   	pop    %edi
  800ab2:	5d                   	pop    %ebp
  800ab3:	c3                   	ret    

00800ab4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800ab4:	55                   	push   %ebp
  800ab5:	89 e5                	mov    %esp,%ebp
  800ab7:	57                   	push   %edi
  800ab8:	56                   	push   %esi
  800ab9:	8b 45 08             	mov    0x8(%ebp),%eax
  800abc:	8b 75 0c             	mov    0xc(%ebp),%esi
  800abf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800ac2:	39 c6                	cmp    %eax,%esi
  800ac4:	73 35                	jae    800afb <memmove+0x47>
  800ac6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800ac9:	39 d0                	cmp    %edx,%eax
  800acb:	73 2e                	jae    800afb <memmove+0x47>
		s += n;
		d += n;
  800acd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800ad0:	89 d6                	mov    %edx,%esi
  800ad2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ad4:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800ada:	75 13                	jne    800aef <memmove+0x3b>
  800adc:	f6 c1 03             	test   $0x3,%cl
  800adf:	75 0e                	jne    800aef <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800ae1:	83 ef 04             	sub    $0x4,%edi
  800ae4:	8d 72 fc             	lea    -0x4(%edx),%esi
  800ae7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800aea:	fd                   	std    
  800aeb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800aed:	eb 09                	jmp    800af8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800aef:	83 ef 01             	sub    $0x1,%edi
  800af2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800af5:	fd                   	std    
  800af6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800af8:	fc                   	cld    
  800af9:	eb 1d                	jmp    800b18 <memmove+0x64>
  800afb:	89 f2                	mov    %esi,%edx
  800afd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800aff:	f6 c2 03             	test   $0x3,%dl
  800b02:	75 0f                	jne    800b13 <memmove+0x5f>
  800b04:	f6 c1 03             	test   $0x3,%cl
  800b07:	75 0a                	jne    800b13 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800b09:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800b0c:	89 c7                	mov    %eax,%edi
  800b0e:	fc                   	cld    
  800b0f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b11:	eb 05                	jmp    800b18 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800b13:	89 c7                	mov    %eax,%edi
  800b15:	fc                   	cld    
  800b16:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800b18:	5e                   	pop    %esi
  800b19:	5f                   	pop    %edi
  800b1a:	5d                   	pop    %ebp
  800b1b:	c3                   	ret    

00800b1c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800b1c:	55                   	push   %ebp
  800b1d:	89 e5                	mov    %esp,%ebp
  800b1f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800b22:	8b 45 10             	mov    0x10(%ebp),%eax
  800b25:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b29:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b2c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b30:	8b 45 08             	mov    0x8(%ebp),%eax
  800b33:	89 04 24             	mov    %eax,(%esp)
  800b36:	e8 79 ff ff ff       	call   800ab4 <memmove>
}
  800b3b:	c9                   	leave  
  800b3c:	c3                   	ret    

00800b3d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800b3d:	55                   	push   %ebp
  800b3e:	89 e5                	mov    %esp,%ebp
  800b40:	56                   	push   %esi
  800b41:	53                   	push   %ebx
  800b42:	8b 55 08             	mov    0x8(%ebp),%edx
  800b45:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b48:	89 d6                	mov    %edx,%esi
  800b4a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b4d:	eb 1a                	jmp    800b69 <memcmp+0x2c>
		if (*s1 != *s2)
  800b4f:	0f b6 02             	movzbl (%edx),%eax
  800b52:	0f b6 19             	movzbl (%ecx),%ebx
  800b55:	38 d8                	cmp    %bl,%al
  800b57:	74 0a                	je     800b63 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b59:	0f b6 c0             	movzbl %al,%eax
  800b5c:	0f b6 db             	movzbl %bl,%ebx
  800b5f:	29 d8                	sub    %ebx,%eax
  800b61:	eb 0f                	jmp    800b72 <memcmp+0x35>
		s1++, s2++;
  800b63:	83 c2 01             	add    $0x1,%edx
  800b66:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b69:	39 f2                	cmp    %esi,%edx
  800b6b:	75 e2                	jne    800b4f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b6d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b72:	5b                   	pop    %ebx
  800b73:	5e                   	pop    %esi
  800b74:	5d                   	pop    %ebp
  800b75:	c3                   	ret    

00800b76 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b76:	55                   	push   %ebp
  800b77:	89 e5                	mov    %esp,%ebp
  800b79:	8b 45 08             	mov    0x8(%ebp),%eax
  800b7c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b7f:	89 c2                	mov    %eax,%edx
  800b81:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b84:	eb 07                	jmp    800b8d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b86:	38 08                	cmp    %cl,(%eax)
  800b88:	74 07                	je     800b91 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b8a:	83 c0 01             	add    $0x1,%eax
  800b8d:	39 d0                	cmp    %edx,%eax
  800b8f:	72 f5                	jb     800b86 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b91:	5d                   	pop    %ebp
  800b92:	c3                   	ret    

00800b93 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b93:	55                   	push   %ebp
  800b94:	89 e5                	mov    %esp,%ebp
  800b96:	57                   	push   %edi
  800b97:	56                   	push   %esi
  800b98:	53                   	push   %ebx
  800b99:	8b 55 08             	mov    0x8(%ebp),%edx
  800b9c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b9f:	eb 03                	jmp    800ba4 <strtol+0x11>
		s++;
  800ba1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ba4:	0f b6 0a             	movzbl (%edx),%ecx
  800ba7:	80 f9 09             	cmp    $0x9,%cl
  800baa:	74 f5                	je     800ba1 <strtol+0xe>
  800bac:	80 f9 20             	cmp    $0x20,%cl
  800baf:	74 f0                	je     800ba1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800bb1:	80 f9 2b             	cmp    $0x2b,%cl
  800bb4:	75 0a                	jne    800bc0 <strtol+0x2d>
		s++;
  800bb6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800bb9:	bf 00 00 00 00       	mov    $0x0,%edi
  800bbe:	eb 11                	jmp    800bd1 <strtol+0x3e>
  800bc0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800bc5:	80 f9 2d             	cmp    $0x2d,%cl
  800bc8:	75 07                	jne    800bd1 <strtol+0x3e>
		s++, neg = 1;
  800bca:	8d 52 01             	lea    0x1(%edx),%edx
  800bcd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800bd1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800bd6:	75 15                	jne    800bed <strtol+0x5a>
  800bd8:	80 3a 30             	cmpb   $0x30,(%edx)
  800bdb:	75 10                	jne    800bed <strtol+0x5a>
  800bdd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800be1:	75 0a                	jne    800bed <strtol+0x5a>
		s += 2, base = 16;
  800be3:	83 c2 02             	add    $0x2,%edx
  800be6:	b8 10 00 00 00       	mov    $0x10,%eax
  800beb:	eb 10                	jmp    800bfd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800bed:	85 c0                	test   %eax,%eax
  800bef:	75 0c                	jne    800bfd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800bf1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800bf3:	80 3a 30             	cmpb   $0x30,(%edx)
  800bf6:	75 05                	jne    800bfd <strtol+0x6a>
		s++, base = 8;
  800bf8:	83 c2 01             	add    $0x1,%edx
  800bfb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800bfd:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c02:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800c05:	0f b6 0a             	movzbl (%edx),%ecx
  800c08:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800c0b:	89 f0                	mov    %esi,%eax
  800c0d:	3c 09                	cmp    $0x9,%al
  800c0f:	77 08                	ja     800c19 <strtol+0x86>
			dig = *s - '0';
  800c11:	0f be c9             	movsbl %cl,%ecx
  800c14:	83 e9 30             	sub    $0x30,%ecx
  800c17:	eb 20                	jmp    800c39 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800c19:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800c1c:	89 f0                	mov    %esi,%eax
  800c1e:	3c 19                	cmp    $0x19,%al
  800c20:	77 08                	ja     800c2a <strtol+0x97>
			dig = *s - 'a' + 10;
  800c22:	0f be c9             	movsbl %cl,%ecx
  800c25:	83 e9 57             	sub    $0x57,%ecx
  800c28:	eb 0f                	jmp    800c39 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800c2a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800c2d:	89 f0                	mov    %esi,%eax
  800c2f:	3c 19                	cmp    $0x19,%al
  800c31:	77 16                	ja     800c49 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800c33:	0f be c9             	movsbl %cl,%ecx
  800c36:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800c39:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800c3c:	7d 0f                	jge    800c4d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800c3e:	83 c2 01             	add    $0x1,%edx
  800c41:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800c45:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800c47:	eb bc                	jmp    800c05 <strtol+0x72>
  800c49:	89 d8                	mov    %ebx,%eax
  800c4b:	eb 02                	jmp    800c4f <strtol+0xbc>
  800c4d:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800c4f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c53:	74 05                	je     800c5a <strtol+0xc7>
		*endptr = (char *) s;
  800c55:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c58:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800c5a:	f7 d8                	neg    %eax
  800c5c:	85 ff                	test   %edi,%edi
  800c5e:	0f 44 c3             	cmove  %ebx,%eax
}
  800c61:	5b                   	pop    %ebx
  800c62:	5e                   	pop    %esi
  800c63:	5f                   	pop    %edi
  800c64:	5d                   	pop    %ebp
  800c65:	c3                   	ret    

00800c66 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800c66:	55                   	push   %ebp
  800c67:	89 e5                	mov    %esp,%ebp
  800c69:	57                   	push   %edi
  800c6a:	56                   	push   %esi
  800c6b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c6c:	b8 00 00 00 00       	mov    $0x0,%eax
  800c71:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c74:	8b 55 08             	mov    0x8(%ebp),%edx
  800c77:	89 c3                	mov    %eax,%ebx
  800c79:	89 c7                	mov    %eax,%edi
  800c7b:	89 c6                	mov    %eax,%esi
  800c7d:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800c7f:	5b                   	pop    %ebx
  800c80:	5e                   	pop    %esi
  800c81:	5f                   	pop    %edi
  800c82:	5d                   	pop    %ebp
  800c83:	c3                   	ret    

00800c84 <sys_cgetc>:

int
sys_cgetc(void)
{
  800c84:	55                   	push   %ebp
  800c85:	89 e5                	mov    %esp,%ebp
  800c87:	57                   	push   %edi
  800c88:	56                   	push   %esi
  800c89:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c8a:	ba 00 00 00 00       	mov    $0x0,%edx
  800c8f:	b8 01 00 00 00       	mov    $0x1,%eax
  800c94:	89 d1                	mov    %edx,%ecx
  800c96:	89 d3                	mov    %edx,%ebx
  800c98:	89 d7                	mov    %edx,%edi
  800c9a:	89 d6                	mov    %edx,%esi
  800c9c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c9e:	5b                   	pop    %ebx
  800c9f:	5e                   	pop    %esi
  800ca0:	5f                   	pop    %edi
  800ca1:	5d                   	pop    %ebp
  800ca2:	c3                   	ret    

00800ca3 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ca3:	55                   	push   %ebp
  800ca4:	89 e5                	mov    %esp,%ebp
  800ca6:	57                   	push   %edi
  800ca7:	56                   	push   %esi
  800ca8:	53                   	push   %ebx
  800ca9:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cac:	b9 00 00 00 00       	mov    $0x0,%ecx
  800cb1:	b8 03 00 00 00       	mov    $0x3,%eax
  800cb6:	8b 55 08             	mov    0x8(%ebp),%edx
  800cb9:	89 cb                	mov    %ecx,%ebx
  800cbb:	89 cf                	mov    %ecx,%edi
  800cbd:	89 ce                	mov    %ecx,%esi
  800cbf:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cc1:	85 c0                	test   %eax,%eax
  800cc3:	7e 28                	jle    800ced <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cc5:	89 44 24 10          	mov    %eax,0x10(%esp)
  800cc9:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800cd0:	00 
  800cd1:	c7 44 24 08 08 16 80 	movl   $0x801608,0x8(%esp)
  800cd8:	00 
  800cd9:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ce0:	00 
  800ce1:	c7 04 24 25 16 80 00 	movl   $0x801625,(%esp)
  800ce8:	e8 1b 03 00 00       	call   801008 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800ced:	83 c4 2c             	add    $0x2c,%esp
  800cf0:	5b                   	pop    %ebx
  800cf1:	5e                   	pop    %esi
  800cf2:	5f                   	pop    %edi
  800cf3:	5d                   	pop    %ebp
  800cf4:	c3                   	ret    

00800cf5 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800cf5:	55                   	push   %ebp
  800cf6:	89 e5                	mov    %esp,%ebp
  800cf8:	57                   	push   %edi
  800cf9:	56                   	push   %esi
  800cfa:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cfb:	ba 00 00 00 00       	mov    $0x0,%edx
  800d00:	b8 02 00 00 00       	mov    $0x2,%eax
  800d05:	89 d1                	mov    %edx,%ecx
  800d07:	89 d3                	mov    %edx,%ebx
  800d09:	89 d7                	mov    %edx,%edi
  800d0b:	89 d6                	mov    %edx,%esi
  800d0d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800d0f:	5b                   	pop    %ebx
  800d10:	5e                   	pop    %esi
  800d11:	5f                   	pop    %edi
  800d12:	5d                   	pop    %ebp
  800d13:	c3                   	ret    

00800d14 <sys_yield>:

void
sys_yield(void)
{
  800d14:	55                   	push   %ebp
  800d15:	89 e5                	mov    %esp,%ebp
  800d17:	57                   	push   %edi
  800d18:	56                   	push   %esi
  800d19:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d1a:	ba 00 00 00 00       	mov    $0x0,%edx
  800d1f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800d24:	89 d1                	mov    %edx,%ecx
  800d26:	89 d3                	mov    %edx,%ebx
  800d28:	89 d7                	mov    %edx,%edi
  800d2a:	89 d6                	mov    %edx,%esi
  800d2c:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800d2e:	5b                   	pop    %ebx
  800d2f:	5e                   	pop    %esi
  800d30:	5f                   	pop    %edi
  800d31:	5d                   	pop    %ebp
  800d32:	c3                   	ret    

00800d33 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800d33:	55                   	push   %ebp
  800d34:	89 e5                	mov    %esp,%ebp
  800d36:	57                   	push   %edi
  800d37:	56                   	push   %esi
  800d38:	53                   	push   %ebx
  800d39:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d3c:	be 00 00 00 00       	mov    $0x0,%esi
  800d41:	b8 04 00 00 00       	mov    $0x4,%eax
  800d46:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d49:	8b 55 08             	mov    0x8(%ebp),%edx
  800d4c:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d4f:	89 f7                	mov    %esi,%edi
  800d51:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d53:	85 c0                	test   %eax,%eax
  800d55:	7e 28                	jle    800d7f <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d57:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d5b:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800d62:	00 
  800d63:	c7 44 24 08 08 16 80 	movl   $0x801608,0x8(%esp)
  800d6a:	00 
  800d6b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d72:	00 
  800d73:	c7 04 24 25 16 80 00 	movl   $0x801625,(%esp)
  800d7a:	e8 89 02 00 00       	call   801008 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800d7f:	83 c4 2c             	add    $0x2c,%esp
  800d82:	5b                   	pop    %ebx
  800d83:	5e                   	pop    %esi
  800d84:	5f                   	pop    %edi
  800d85:	5d                   	pop    %ebp
  800d86:	c3                   	ret    

00800d87 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800d87:	55                   	push   %ebp
  800d88:	89 e5                	mov    %esp,%ebp
  800d8a:	57                   	push   %edi
  800d8b:	56                   	push   %esi
  800d8c:	53                   	push   %ebx
  800d8d:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d90:	b8 05 00 00 00       	mov    $0x5,%eax
  800d95:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d98:	8b 55 08             	mov    0x8(%ebp),%edx
  800d9b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d9e:	8b 7d 14             	mov    0x14(%ebp),%edi
  800da1:	8b 75 18             	mov    0x18(%ebp),%esi
  800da4:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800da6:	85 c0                	test   %eax,%eax
  800da8:	7e 28                	jle    800dd2 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800daa:	89 44 24 10          	mov    %eax,0x10(%esp)
  800dae:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800db5:	00 
  800db6:	c7 44 24 08 08 16 80 	movl   $0x801608,0x8(%esp)
  800dbd:	00 
  800dbe:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800dc5:	00 
  800dc6:	c7 04 24 25 16 80 00 	movl   $0x801625,(%esp)
  800dcd:	e8 36 02 00 00       	call   801008 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800dd2:	83 c4 2c             	add    $0x2c,%esp
  800dd5:	5b                   	pop    %ebx
  800dd6:	5e                   	pop    %esi
  800dd7:	5f                   	pop    %edi
  800dd8:	5d                   	pop    %ebp
  800dd9:	c3                   	ret    

00800dda <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800dda:	55                   	push   %ebp
  800ddb:	89 e5                	mov    %esp,%ebp
  800ddd:	57                   	push   %edi
  800dde:	56                   	push   %esi
  800ddf:	53                   	push   %ebx
  800de0:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800de3:	bb 00 00 00 00       	mov    $0x0,%ebx
  800de8:	b8 06 00 00 00       	mov    $0x6,%eax
  800ded:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800df0:	8b 55 08             	mov    0x8(%ebp),%edx
  800df3:	89 df                	mov    %ebx,%edi
  800df5:	89 de                	mov    %ebx,%esi
  800df7:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800df9:	85 c0                	test   %eax,%eax
  800dfb:	7e 28                	jle    800e25 <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800dfd:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e01:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800e08:	00 
  800e09:	c7 44 24 08 08 16 80 	movl   $0x801608,0x8(%esp)
  800e10:	00 
  800e11:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e18:	00 
  800e19:	c7 04 24 25 16 80 00 	movl   $0x801625,(%esp)
  800e20:	e8 e3 01 00 00       	call   801008 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800e25:	83 c4 2c             	add    $0x2c,%esp
  800e28:	5b                   	pop    %ebx
  800e29:	5e                   	pop    %esi
  800e2a:	5f                   	pop    %edi
  800e2b:	5d                   	pop    %ebp
  800e2c:	c3                   	ret    

00800e2d <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800e2d:	55                   	push   %ebp
  800e2e:	89 e5                	mov    %esp,%ebp
  800e30:	57                   	push   %edi
  800e31:	56                   	push   %esi
  800e32:	53                   	push   %ebx
  800e33:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e36:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e3b:	b8 08 00 00 00       	mov    $0x8,%eax
  800e40:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e43:	8b 55 08             	mov    0x8(%ebp),%edx
  800e46:	89 df                	mov    %ebx,%edi
  800e48:	89 de                	mov    %ebx,%esi
  800e4a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e4c:	85 c0                	test   %eax,%eax
  800e4e:	7e 28                	jle    800e78 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e50:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e54:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800e5b:	00 
  800e5c:	c7 44 24 08 08 16 80 	movl   $0x801608,0x8(%esp)
  800e63:	00 
  800e64:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e6b:	00 
  800e6c:	c7 04 24 25 16 80 00 	movl   $0x801625,(%esp)
  800e73:	e8 90 01 00 00       	call   801008 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800e78:	83 c4 2c             	add    $0x2c,%esp
  800e7b:	5b                   	pop    %ebx
  800e7c:	5e                   	pop    %esi
  800e7d:	5f                   	pop    %edi
  800e7e:	5d                   	pop    %ebp
  800e7f:	c3                   	ret    

00800e80 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800e80:	55                   	push   %ebp
  800e81:	89 e5                	mov    %esp,%ebp
  800e83:	57                   	push   %edi
  800e84:	56                   	push   %esi
  800e85:	53                   	push   %ebx
  800e86:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e89:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e8e:	b8 09 00 00 00       	mov    $0x9,%eax
  800e93:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e96:	8b 55 08             	mov    0x8(%ebp),%edx
  800e99:	89 df                	mov    %ebx,%edi
  800e9b:	89 de                	mov    %ebx,%esi
  800e9d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e9f:	85 c0                	test   %eax,%eax
  800ea1:	7e 28                	jle    800ecb <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ea3:	89 44 24 10          	mov    %eax,0x10(%esp)
  800ea7:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800eae:	00 
  800eaf:	c7 44 24 08 08 16 80 	movl   $0x801608,0x8(%esp)
  800eb6:	00 
  800eb7:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ebe:	00 
  800ebf:	c7 04 24 25 16 80 00 	movl   $0x801625,(%esp)
  800ec6:	e8 3d 01 00 00       	call   801008 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800ecb:	83 c4 2c             	add    $0x2c,%esp
  800ece:	5b                   	pop    %ebx
  800ecf:	5e                   	pop    %esi
  800ed0:	5f                   	pop    %edi
  800ed1:	5d                   	pop    %ebp
  800ed2:	c3                   	ret    

00800ed3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800ed3:	55                   	push   %ebp
  800ed4:	89 e5                	mov    %esp,%ebp
  800ed6:	57                   	push   %edi
  800ed7:	56                   	push   %esi
  800ed8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ed9:	be 00 00 00 00       	mov    $0x0,%esi
  800ede:	b8 0b 00 00 00       	mov    $0xb,%eax
  800ee3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ee6:	8b 55 08             	mov    0x8(%ebp),%edx
  800ee9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800eec:	8b 7d 14             	mov    0x14(%ebp),%edi
  800eef:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800ef1:	5b                   	pop    %ebx
  800ef2:	5e                   	pop    %esi
  800ef3:	5f                   	pop    %edi
  800ef4:	5d                   	pop    %ebp
  800ef5:	c3                   	ret    

00800ef6 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800ef6:	55                   	push   %ebp
  800ef7:	89 e5                	mov    %esp,%ebp
  800ef9:	57                   	push   %edi
  800efa:	56                   	push   %esi
  800efb:	53                   	push   %ebx
  800efc:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800eff:	b9 00 00 00 00       	mov    $0x0,%ecx
  800f04:	b8 0c 00 00 00       	mov    $0xc,%eax
  800f09:	8b 55 08             	mov    0x8(%ebp),%edx
  800f0c:	89 cb                	mov    %ecx,%ebx
  800f0e:	89 cf                	mov    %ecx,%edi
  800f10:	89 ce                	mov    %ecx,%esi
  800f12:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f14:	85 c0                	test   %eax,%eax
  800f16:	7e 28                	jle    800f40 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f18:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f1c:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800f23:	00 
  800f24:	c7 44 24 08 08 16 80 	movl   $0x801608,0x8(%esp)
  800f2b:	00 
  800f2c:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f33:	00 
  800f34:	c7 04 24 25 16 80 00 	movl   $0x801625,(%esp)
  800f3b:	e8 c8 00 00 00       	call   801008 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800f40:	83 c4 2c             	add    $0x2c,%esp
  800f43:	5b                   	pop    %ebx
  800f44:	5e                   	pop    %esi
  800f45:	5f                   	pop    %edi
  800f46:	5d                   	pop    %ebp
  800f47:	c3                   	ret    

00800f48 <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800f48:	55                   	push   %ebp
  800f49:	89 e5                	mov    %esp,%ebp
  800f4b:	83 ec 18             	sub    $0x18,%esp
	// LAB 4: Your code here.
	panic("fork not implemented");
  800f4e:	c7 44 24 08 3f 16 80 	movl   $0x80163f,0x8(%esp)
  800f55:	00 
  800f56:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
  800f5d:	00 
  800f5e:	c7 04 24 33 16 80 00 	movl   $0x801633,(%esp)
  800f65:	e8 9e 00 00 00       	call   801008 <_panic>

00800f6a <sfork>:
}

// Challenge!
int
sfork(void)
{
  800f6a:	55                   	push   %ebp
  800f6b:	89 e5                	mov    %esp,%ebp
  800f6d:	83 ec 18             	sub    $0x18,%esp
	panic("sfork not implemented");
  800f70:	c7 44 24 08 3e 16 80 	movl   $0x80163e,0x8(%esp)
  800f77:	00 
  800f78:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  800f7f:	00 
  800f80:	c7 04 24 33 16 80 00 	movl   $0x801633,(%esp)
  800f87:	e8 7c 00 00 00       	call   801008 <_panic>

00800f8c <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  800f8c:	55                   	push   %ebp
  800f8d:	89 e5                	mov    %esp,%ebp
  800f8f:	83 ec 18             	sub    $0x18,%esp
	// LAB 4: Your code here.
	panic("ipc_recv not implemented");
  800f92:	c7 44 24 08 54 16 80 	movl   $0x801654,0x8(%esp)
  800f99:	00 
  800f9a:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
  800fa1:	00 
  800fa2:	c7 04 24 6d 16 80 00 	movl   $0x80166d,(%esp)
  800fa9:	e8 5a 00 00 00       	call   801008 <_panic>

00800fae <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_try_send a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  800fae:	55                   	push   %ebp
  800faf:	89 e5                	mov    %esp,%ebp
  800fb1:	83 ec 18             	sub    $0x18,%esp
	// LAB 4: Your code here.
	panic("ipc_send not implemented");
  800fb4:	c7 44 24 08 77 16 80 	movl   $0x801677,0x8(%esp)
  800fbb:	00 
  800fbc:	c7 44 24 04 2a 00 00 	movl   $0x2a,0x4(%esp)
  800fc3:	00 
  800fc4:	c7 04 24 6d 16 80 00 	movl   $0x80166d,(%esp)
  800fcb:	e8 38 00 00 00       	call   801008 <_panic>

00800fd0 <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  800fd0:	55                   	push   %ebp
  800fd1:	89 e5                	mov    %esp,%ebp
  800fd3:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
  800fd6:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
  800fdb:	6b d0 7c             	imul   $0x7c,%eax,%edx
  800fde:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  800fe4:	8b 52 50             	mov    0x50(%edx),%edx
  800fe7:	39 ca                	cmp    %ecx,%edx
  800fe9:	75 0d                	jne    800ff8 <ipc_find_env+0x28>
			return envs[i].env_id;
  800feb:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800fee:	05 08 00 c0 ee       	add    $0xeec00008,%eax
  800ff3:	8b 40 40             	mov    0x40(%eax),%eax
  800ff6:	eb 0e                	jmp    801006 <ipc_find_env+0x36>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  800ff8:	83 c0 01             	add    $0x1,%eax
  800ffb:	3d 00 04 00 00       	cmp    $0x400,%eax
  801000:	75 d9                	jne    800fdb <ipc_find_env+0xb>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  801002:	66 b8 00 00          	mov    $0x0,%ax
}
  801006:	5d                   	pop    %ebp
  801007:	c3                   	ret    

00801008 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  801008:	55                   	push   %ebp
  801009:	89 e5                	mov    %esp,%ebp
  80100b:	56                   	push   %esi
  80100c:	53                   	push   %ebx
  80100d:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  801010:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  801013:	8b 35 08 20 80 00    	mov    0x802008,%esi
  801019:	e8 d7 fc ff ff       	call   800cf5 <sys_getenvid>
  80101e:	8b 55 0c             	mov    0xc(%ebp),%edx
  801021:	89 54 24 10          	mov    %edx,0x10(%esp)
  801025:	8b 55 08             	mov    0x8(%ebp),%edx
  801028:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80102c:	89 74 24 08          	mov    %esi,0x8(%esp)
  801030:	89 44 24 04          	mov    %eax,0x4(%esp)
  801034:	c7 04 24 90 16 80 00 	movl   $0x801690,(%esp)
  80103b:	e8 a9 f2 ff ff       	call   8002e9 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  801040:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  801044:	8b 45 10             	mov    0x10(%ebp),%eax
  801047:	89 04 24             	mov    %eax,(%esp)
  80104a:	e8 39 f2 ff ff       	call   800288 <vcprintf>
	cprintf("\n");
  80104f:	c7 04 24 12 13 80 00 	movl   $0x801312,(%esp)
  801056:	e8 8e f2 ff ff       	call   8002e9 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80105b:	cc                   	int3   
  80105c:	eb fd                	jmp    80105b <_panic+0x53>
  80105e:	66 90                	xchg   %ax,%ax

00801060 <__udivdi3>:
  801060:	55                   	push   %ebp
  801061:	57                   	push   %edi
  801062:	56                   	push   %esi
  801063:	83 ec 0c             	sub    $0xc,%esp
  801066:	8b 44 24 28          	mov    0x28(%esp),%eax
  80106a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  80106e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  801072:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  801076:	85 c0                	test   %eax,%eax
  801078:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80107c:	89 ea                	mov    %ebp,%edx
  80107e:	89 0c 24             	mov    %ecx,(%esp)
  801081:	75 2d                	jne    8010b0 <__udivdi3+0x50>
  801083:	39 e9                	cmp    %ebp,%ecx
  801085:	77 61                	ja     8010e8 <__udivdi3+0x88>
  801087:	85 c9                	test   %ecx,%ecx
  801089:	89 ce                	mov    %ecx,%esi
  80108b:	75 0b                	jne    801098 <__udivdi3+0x38>
  80108d:	b8 01 00 00 00       	mov    $0x1,%eax
  801092:	31 d2                	xor    %edx,%edx
  801094:	f7 f1                	div    %ecx
  801096:	89 c6                	mov    %eax,%esi
  801098:	31 d2                	xor    %edx,%edx
  80109a:	89 e8                	mov    %ebp,%eax
  80109c:	f7 f6                	div    %esi
  80109e:	89 c5                	mov    %eax,%ebp
  8010a0:	89 f8                	mov    %edi,%eax
  8010a2:	f7 f6                	div    %esi
  8010a4:	89 ea                	mov    %ebp,%edx
  8010a6:	83 c4 0c             	add    $0xc,%esp
  8010a9:	5e                   	pop    %esi
  8010aa:	5f                   	pop    %edi
  8010ab:	5d                   	pop    %ebp
  8010ac:	c3                   	ret    
  8010ad:	8d 76 00             	lea    0x0(%esi),%esi
  8010b0:	39 e8                	cmp    %ebp,%eax
  8010b2:	77 24                	ja     8010d8 <__udivdi3+0x78>
  8010b4:	0f bd e8             	bsr    %eax,%ebp
  8010b7:	83 f5 1f             	xor    $0x1f,%ebp
  8010ba:	75 3c                	jne    8010f8 <__udivdi3+0x98>
  8010bc:	8b 74 24 04          	mov    0x4(%esp),%esi
  8010c0:	39 34 24             	cmp    %esi,(%esp)
  8010c3:	0f 86 9f 00 00 00    	jbe    801168 <__udivdi3+0x108>
  8010c9:	39 d0                	cmp    %edx,%eax
  8010cb:	0f 82 97 00 00 00    	jb     801168 <__udivdi3+0x108>
  8010d1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8010d8:	31 d2                	xor    %edx,%edx
  8010da:	31 c0                	xor    %eax,%eax
  8010dc:	83 c4 0c             	add    $0xc,%esp
  8010df:	5e                   	pop    %esi
  8010e0:	5f                   	pop    %edi
  8010e1:	5d                   	pop    %ebp
  8010e2:	c3                   	ret    
  8010e3:	90                   	nop
  8010e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8010e8:	89 f8                	mov    %edi,%eax
  8010ea:	f7 f1                	div    %ecx
  8010ec:	31 d2                	xor    %edx,%edx
  8010ee:	83 c4 0c             	add    $0xc,%esp
  8010f1:	5e                   	pop    %esi
  8010f2:	5f                   	pop    %edi
  8010f3:	5d                   	pop    %ebp
  8010f4:	c3                   	ret    
  8010f5:	8d 76 00             	lea    0x0(%esi),%esi
  8010f8:	89 e9                	mov    %ebp,%ecx
  8010fa:	8b 3c 24             	mov    (%esp),%edi
  8010fd:	d3 e0                	shl    %cl,%eax
  8010ff:	89 c6                	mov    %eax,%esi
  801101:	b8 20 00 00 00       	mov    $0x20,%eax
  801106:	29 e8                	sub    %ebp,%eax
  801108:	89 c1                	mov    %eax,%ecx
  80110a:	d3 ef                	shr    %cl,%edi
  80110c:	89 e9                	mov    %ebp,%ecx
  80110e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801112:	8b 3c 24             	mov    (%esp),%edi
  801115:	09 74 24 08          	or     %esi,0x8(%esp)
  801119:	89 d6                	mov    %edx,%esi
  80111b:	d3 e7                	shl    %cl,%edi
  80111d:	89 c1                	mov    %eax,%ecx
  80111f:	89 3c 24             	mov    %edi,(%esp)
  801122:	8b 7c 24 04          	mov    0x4(%esp),%edi
  801126:	d3 ee                	shr    %cl,%esi
  801128:	89 e9                	mov    %ebp,%ecx
  80112a:	d3 e2                	shl    %cl,%edx
  80112c:	89 c1                	mov    %eax,%ecx
  80112e:	d3 ef                	shr    %cl,%edi
  801130:	09 d7                	or     %edx,%edi
  801132:	89 f2                	mov    %esi,%edx
  801134:	89 f8                	mov    %edi,%eax
  801136:	f7 74 24 08          	divl   0x8(%esp)
  80113a:	89 d6                	mov    %edx,%esi
  80113c:	89 c7                	mov    %eax,%edi
  80113e:	f7 24 24             	mull   (%esp)
  801141:	39 d6                	cmp    %edx,%esi
  801143:	89 14 24             	mov    %edx,(%esp)
  801146:	72 30                	jb     801178 <__udivdi3+0x118>
  801148:	8b 54 24 04          	mov    0x4(%esp),%edx
  80114c:	89 e9                	mov    %ebp,%ecx
  80114e:	d3 e2                	shl    %cl,%edx
  801150:	39 c2                	cmp    %eax,%edx
  801152:	73 05                	jae    801159 <__udivdi3+0xf9>
  801154:	3b 34 24             	cmp    (%esp),%esi
  801157:	74 1f                	je     801178 <__udivdi3+0x118>
  801159:	89 f8                	mov    %edi,%eax
  80115b:	31 d2                	xor    %edx,%edx
  80115d:	e9 7a ff ff ff       	jmp    8010dc <__udivdi3+0x7c>
  801162:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801168:	31 d2                	xor    %edx,%edx
  80116a:	b8 01 00 00 00       	mov    $0x1,%eax
  80116f:	e9 68 ff ff ff       	jmp    8010dc <__udivdi3+0x7c>
  801174:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801178:	8d 47 ff             	lea    -0x1(%edi),%eax
  80117b:	31 d2                	xor    %edx,%edx
  80117d:	83 c4 0c             	add    $0xc,%esp
  801180:	5e                   	pop    %esi
  801181:	5f                   	pop    %edi
  801182:	5d                   	pop    %ebp
  801183:	c3                   	ret    
  801184:	66 90                	xchg   %ax,%ax
  801186:	66 90                	xchg   %ax,%ax
  801188:	66 90                	xchg   %ax,%ax
  80118a:	66 90                	xchg   %ax,%ax
  80118c:	66 90                	xchg   %ax,%ax
  80118e:	66 90                	xchg   %ax,%ax

00801190 <__umoddi3>:
  801190:	55                   	push   %ebp
  801191:	57                   	push   %edi
  801192:	56                   	push   %esi
  801193:	83 ec 14             	sub    $0x14,%esp
  801196:	8b 44 24 28          	mov    0x28(%esp),%eax
  80119a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  80119e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  8011a2:	89 c7                	mov    %eax,%edi
  8011a4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8011a8:	8b 44 24 30          	mov    0x30(%esp),%eax
  8011ac:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8011b0:	89 34 24             	mov    %esi,(%esp)
  8011b3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8011b7:	85 c0                	test   %eax,%eax
  8011b9:	89 c2                	mov    %eax,%edx
  8011bb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8011bf:	75 17                	jne    8011d8 <__umoddi3+0x48>
  8011c1:	39 fe                	cmp    %edi,%esi
  8011c3:	76 4b                	jbe    801210 <__umoddi3+0x80>
  8011c5:	89 c8                	mov    %ecx,%eax
  8011c7:	89 fa                	mov    %edi,%edx
  8011c9:	f7 f6                	div    %esi
  8011cb:	89 d0                	mov    %edx,%eax
  8011cd:	31 d2                	xor    %edx,%edx
  8011cf:	83 c4 14             	add    $0x14,%esp
  8011d2:	5e                   	pop    %esi
  8011d3:	5f                   	pop    %edi
  8011d4:	5d                   	pop    %ebp
  8011d5:	c3                   	ret    
  8011d6:	66 90                	xchg   %ax,%ax
  8011d8:	39 f8                	cmp    %edi,%eax
  8011da:	77 54                	ja     801230 <__umoddi3+0xa0>
  8011dc:	0f bd e8             	bsr    %eax,%ebp
  8011df:	83 f5 1f             	xor    $0x1f,%ebp
  8011e2:	75 5c                	jne    801240 <__umoddi3+0xb0>
  8011e4:	8b 7c 24 08          	mov    0x8(%esp),%edi
  8011e8:	39 3c 24             	cmp    %edi,(%esp)
  8011eb:	0f 87 e7 00 00 00    	ja     8012d8 <__umoddi3+0x148>
  8011f1:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8011f5:	29 f1                	sub    %esi,%ecx
  8011f7:	19 c7                	sbb    %eax,%edi
  8011f9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8011fd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801201:	8b 44 24 08          	mov    0x8(%esp),%eax
  801205:	8b 54 24 0c          	mov    0xc(%esp),%edx
  801209:	83 c4 14             	add    $0x14,%esp
  80120c:	5e                   	pop    %esi
  80120d:	5f                   	pop    %edi
  80120e:	5d                   	pop    %ebp
  80120f:	c3                   	ret    
  801210:	85 f6                	test   %esi,%esi
  801212:	89 f5                	mov    %esi,%ebp
  801214:	75 0b                	jne    801221 <__umoddi3+0x91>
  801216:	b8 01 00 00 00       	mov    $0x1,%eax
  80121b:	31 d2                	xor    %edx,%edx
  80121d:	f7 f6                	div    %esi
  80121f:	89 c5                	mov    %eax,%ebp
  801221:	8b 44 24 04          	mov    0x4(%esp),%eax
  801225:	31 d2                	xor    %edx,%edx
  801227:	f7 f5                	div    %ebp
  801229:	89 c8                	mov    %ecx,%eax
  80122b:	f7 f5                	div    %ebp
  80122d:	eb 9c                	jmp    8011cb <__umoddi3+0x3b>
  80122f:	90                   	nop
  801230:	89 c8                	mov    %ecx,%eax
  801232:	89 fa                	mov    %edi,%edx
  801234:	83 c4 14             	add    $0x14,%esp
  801237:	5e                   	pop    %esi
  801238:	5f                   	pop    %edi
  801239:	5d                   	pop    %ebp
  80123a:	c3                   	ret    
  80123b:	90                   	nop
  80123c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801240:	8b 04 24             	mov    (%esp),%eax
  801243:	be 20 00 00 00       	mov    $0x20,%esi
  801248:	89 e9                	mov    %ebp,%ecx
  80124a:	29 ee                	sub    %ebp,%esi
  80124c:	d3 e2                	shl    %cl,%edx
  80124e:	89 f1                	mov    %esi,%ecx
  801250:	d3 e8                	shr    %cl,%eax
  801252:	89 e9                	mov    %ebp,%ecx
  801254:	89 44 24 04          	mov    %eax,0x4(%esp)
  801258:	8b 04 24             	mov    (%esp),%eax
  80125b:	09 54 24 04          	or     %edx,0x4(%esp)
  80125f:	89 fa                	mov    %edi,%edx
  801261:	d3 e0                	shl    %cl,%eax
  801263:	89 f1                	mov    %esi,%ecx
  801265:	89 44 24 08          	mov    %eax,0x8(%esp)
  801269:	8b 44 24 10          	mov    0x10(%esp),%eax
  80126d:	d3 ea                	shr    %cl,%edx
  80126f:	89 e9                	mov    %ebp,%ecx
  801271:	d3 e7                	shl    %cl,%edi
  801273:	89 f1                	mov    %esi,%ecx
  801275:	d3 e8                	shr    %cl,%eax
  801277:	89 e9                	mov    %ebp,%ecx
  801279:	09 f8                	or     %edi,%eax
  80127b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80127f:	f7 74 24 04          	divl   0x4(%esp)
  801283:	d3 e7                	shl    %cl,%edi
  801285:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801289:	89 d7                	mov    %edx,%edi
  80128b:	f7 64 24 08          	mull   0x8(%esp)
  80128f:	39 d7                	cmp    %edx,%edi
  801291:	89 c1                	mov    %eax,%ecx
  801293:	89 14 24             	mov    %edx,(%esp)
  801296:	72 2c                	jb     8012c4 <__umoddi3+0x134>
  801298:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  80129c:	72 22                	jb     8012c0 <__umoddi3+0x130>
  80129e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  8012a2:	29 c8                	sub    %ecx,%eax
  8012a4:	19 d7                	sbb    %edx,%edi
  8012a6:	89 e9                	mov    %ebp,%ecx
  8012a8:	89 fa                	mov    %edi,%edx
  8012aa:	d3 e8                	shr    %cl,%eax
  8012ac:	89 f1                	mov    %esi,%ecx
  8012ae:	d3 e2                	shl    %cl,%edx
  8012b0:	89 e9                	mov    %ebp,%ecx
  8012b2:	d3 ef                	shr    %cl,%edi
  8012b4:	09 d0                	or     %edx,%eax
  8012b6:	89 fa                	mov    %edi,%edx
  8012b8:	83 c4 14             	add    $0x14,%esp
  8012bb:	5e                   	pop    %esi
  8012bc:	5f                   	pop    %edi
  8012bd:	5d                   	pop    %ebp
  8012be:	c3                   	ret    
  8012bf:	90                   	nop
  8012c0:	39 d7                	cmp    %edx,%edi
  8012c2:	75 da                	jne    80129e <__umoddi3+0x10e>
  8012c4:	8b 14 24             	mov    (%esp),%edx
  8012c7:	89 c1                	mov    %eax,%ecx
  8012c9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  8012cd:	1b 54 24 04          	sbb    0x4(%esp),%edx
  8012d1:	eb cb                	jmp    80129e <__umoddi3+0x10e>
  8012d3:	90                   	nop
  8012d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8012d8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  8012dc:	0f 82 0f ff ff ff    	jb     8011f1 <__umoddi3+0x61>
  8012e2:	e9 1a ff ff ff       	jmp    801201 <__umoddi3+0x71>
