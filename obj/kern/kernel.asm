
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 f0 11 00       	mov    $0x11f000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 f0 11 f0       	mov    $0xf011f000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 6a 00 00 00       	call   f01000a8 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	83 ec 10             	sub    $0x10,%esp
f0100048:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010004b:	83 3d 80 ce 22 f0 00 	cmpl   $0x0,0xf022ce80
f0100052:	75 46                	jne    f010009a <_panic+0x5a>
		goto dead;
	panicstr = fmt;
f0100054:	89 35 80 ce 22 f0    	mov    %esi,0xf022ce80

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010005a:	fa                   	cli    
f010005b:	fc                   	cld    

	va_start(ap, fmt);
f010005c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005f:	e8 15 62 00 00       	call   f0106279 <cpunum>
f0100064:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100067:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010006b:	8b 55 08             	mov    0x8(%ebp),%edx
f010006e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100072:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100076:	c7 04 24 60 69 10 f0 	movl   $0xf0106960,(%esp)
f010007d:	e8 34 40 00 00       	call   f01040b6 <cprintf>
	vcprintf(fmt, ap);
f0100082:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100086:	89 34 24             	mov    %esi,(%esp)
f0100089:	e8 f5 3f 00 00       	call   f0104083 <vcprintf>
	cprintf("\n");
f010008e:	c7 04 24 09 79 10 f0 	movl   $0xf0107909,(%esp)
f0100095:	e8 1c 40 00 00       	call   f01040b6 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000a1:	e8 f4 08 00 00       	call   f010099a <monitor>
f01000a6:	eb f2                	jmp    f010009a <_panic+0x5a>

f01000a8 <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f01000a8:	55                   	push   %ebp
f01000a9:	89 e5                	mov    %esp,%ebp
f01000ab:	53                   	push   %ebx
f01000ac:	83 ec 14             	sub    $0x14,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000af:	b8 08 e0 26 f0       	mov    $0xf026e008,%eax
f01000b4:	2d 07 bd 22 f0       	sub    $0xf022bd07,%eax
f01000b9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000c4:	00 
f01000c5:	c7 04 24 07 bd 22 f0 	movl   $0xf022bd07,(%esp)
f01000cc:	e8 56 5b 00 00       	call   f0105c27 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000d1:	e8 a9 05 00 00       	call   f010067f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d6:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000dd:	00 
f01000de:	c7 04 24 cc 69 10 f0 	movl   $0xf01069cc,(%esp)
f01000e5:	e8 cc 3f 00 00       	call   f01040b6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000ea:	e8 d4 14 00 00       	call   f01015c3 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000ef:	e8 0e 37 00 00       	call   f0103802 <env_init>
	trap_init();
f01000f4:	e8 52 40 00 00       	call   f010414b <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000f9:	e8 6c 5e 00 00       	call   f0105f6a <mp_init>
	lapic_init();
f01000fe:	66 90                	xchg   %ax,%ax
f0100100:	e8 8f 61 00 00       	call   f0106294 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f0100105:	e8 dc 3e 00 00       	call   f0103fe6 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f010010a:	c7 04 24 80 14 12 f0 	movl   $0xf0121480,(%esp)
f0100111:	e8 e1 63 00 00       	call   f01064f7 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100116:	83 3d 88 ce 22 f0 07 	cmpl   $0x7,0xf022ce88
f010011d:	77 24                	ja     f0100143 <i386_init+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010011f:	c7 44 24 0c 00 70 00 	movl   $0x7000,0xc(%esp)
f0100126:	00 
f0100127:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f010012e:	f0 
f010012f:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0100136:	00 
f0100137:	c7 04 24 e7 69 10 f0 	movl   $0xf01069e7,(%esp)
f010013e:	e8 fd fe ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100143:	b8 a2 5e 10 f0       	mov    $0xf0105ea2,%eax
f0100148:	2d 28 5e 10 f0       	sub    $0xf0105e28,%eax
f010014d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100151:	c7 44 24 04 28 5e 10 	movl   $0xf0105e28,0x4(%esp)
f0100158:	f0 
f0100159:	c7 04 24 00 70 00 f0 	movl   $0xf0007000,(%esp)
f0100160:	e8 0f 5b 00 00       	call   f0105c74 <memmove>

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100165:	bb 20 d0 22 f0       	mov    $0xf022d020,%ebx
f010016a:	eb 4d                	jmp    f01001b9 <i386_init+0x111>
		if (c == cpus + cpunum())  // We've started already.
f010016c:	e8 08 61 00 00       	call   f0106279 <cpunum>
f0100171:	6b c0 74             	imul   $0x74,%eax,%eax
f0100174:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f0100179:	39 c3                	cmp    %eax,%ebx
f010017b:	74 39                	je     f01001b6 <i386_init+0x10e>
f010017d:	89 d8                	mov    %ebx,%eax
f010017f:	2d 20 d0 22 f0       	sub    $0xf022d020,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100184:	c1 f8 02             	sar    $0x2,%eax
f0100187:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f010018d:	c1 e0 0f             	shl    $0xf,%eax
f0100190:	8d 80 00 60 23 f0    	lea    -0xfdca000(%eax),%eax
f0100196:	a3 84 ce 22 f0       	mov    %eax,0xf022ce84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f010019b:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
f01001a2:	00 
f01001a3:	0f b6 03             	movzbl (%ebx),%eax
f01001a6:	89 04 24             	mov    %eax,(%esp)
f01001a9:	e8 36 62 00 00       	call   f01063e4 <lapic_startap>
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f01001ae:	8b 43 04             	mov    0x4(%ebx),%eax
f01001b1:	83 f8 01             	cmp    $0x1,%eax
f01001b4:	75 f8                	jne    f01001ae <i386_init+0x106>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f01001b6:	83 c3 74             	add    $0x74,%ebx
f01001b9:	6b 05 c4 d3 22 f0 74 	imul   $0x74,0xf022d3c4,%eax
f01001c0:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f01001c5:	39 c3                	cmp    %eax,%ebx
f01001c7:	72 a3                	jb     f010016c <i386_init+0xc4>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001d0:	00 
f01001d1:	c7 04 24 fa 32 22 f0 	movl   $0xf02232fa,(%esp)
f01001d8:	e8 5a 38 00 00       	call   f0103a37 <env_create>

	ENV_CREATE(user_yield, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001dd:	e8 e4 47 00 00       	call   f01049c6 <sched_yield>

f01001e2 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001e2:	55                   	push   %ebp
f01001e3:	89 e5                	mov    %esp,%ebp
f01001e5:	83 ec 18             	sub    $0x18,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001e8:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001ed:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001f2:	77 20                	ja     f0100214 <mp_main+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01001f8:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f01001ff:	f0 
f0100200:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f0100207:	00 
f0100208:	c7 04 24 e7 69 10 f0 	movl   $0xf01069e7,(%esp)
f010020f:	e8 2c fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100214:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0100219:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f010021c:	e8 58 60 00 00       	call   f0106279 <cpunum>
f0100221:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100225:	c7 04 24 f3 69 10 f0 	movl   $0xf01069f3,(%esp)
f010022c:	e8 85 3e 00 00       	call   f01040b6 <cprintf>

	lapic_init();
f0100231:	e8 5e 60 00 00       	call   f0106294 <lapic_init>
	env_init_percpu();
f0100236:	e8 9d 35 00 00       	call   f01037d8 <env_init_percpu>
	trap_init_percpu();
f010023b:	90                   	nop
f010023c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100240:	e8 8b 3e 00 00       	call   f01040d0 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100245:	e8 2f 60 00 00       	call   f0106279 <cpunum>
f010024a:	6b d0 74             	imul   $0x74,%eax,%edx
f010024d:	81 c2 20 d0 22 f0    	add    $0xf022d020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100253:	b8 01 00 00 00       	mov    $0x1,%eax
f0100258:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010025c:	c7 04 24 80 14 12 f0 	movl   $0xf0121480,(%esp)
f0100263:	e8 8f 62 00 00       	call   f01064f7 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();
f0100268:	e8 59 47 00 00       	call   f01049c6 <sched_yield>

f010026d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010026d:	55                   	push   %ebp
f010026e:	89 e5                	mov    %esp,%ebp
f0100270:	53                   	push   %ebx
f0100271:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100274:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100277:	8b 45 0c             	mov    0xc(%ebp),%eax
f010027a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010027e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100281:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100285:	c7 04 24 09 6a 10 f0 	movl   $0xf0106a09,(%esp)
f010028c:	e8 25 3e 00 00       	call   f01040b6 <cprintf>
	vcprintf(fmt, ap);
f0100291:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100295:	8b 45 10             	mov    0x10(%ebp),%eax
f0100298:	89 04 24             	mov    %eax,(%esp)
f010029b:	e8 e3 3d 00 00       	call   f0104083 <vcprintf>
	cprintf("\n");
f01002a0:	c7 04 24 09 79 10 f0 	movl   $0xf0107909,(%esp)
f01002a7:	e8 0a 3e 00 00       	call   f01040b6 <cprintf>
	va_end(ap);
}
f01002ac:	83 c4 14             	add    $0x14,%esp
f01002af:	5b                   	pop    %ebx
f01002b0:	5d                   	pop    %ebp
f01002b1:	c3                   	ret    
f01002b2:	66 90                	xchg   %ax,%ax
f01002b4:	66 90                	xchg   %ax,%ax
f01002b6:	66 90                	xchg   %ax,%ax
f01002b8:	66 90                	xchg   %ax,%ax
f01002ba:	66 90                	xchg   %ax,%ax
f01002bc:	66 90                	xchg   %ax,%ax
f01002be:	66 90                	xchg   %ax,%ax

f01002c0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01002c0:	55                   	push   %ebp
f01002c1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002c8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01002c9:	a8 01                	test   $0x1,%al
f01002cb:	74 08                	je     f01002d5 <serial_proc_data+0x15>
f01002cd:	b2 f8                	mov    $0xf8,%dl
f01002cf:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002d0:	0f b6 c0             	movzbl %al,%eax
f01002d3:	eb 05                	jmp    f01002da <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01002d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01002da:	5d                   	pop    %ebp
f01002db:	c3                   	ret    

f01002dc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002dc:	55                   	push   %ebp
f01002dd:	89 e5                	mov    %esp,%ebp
f01002df:	53                   	push   %ebx
f01002e0:	83 ec 04             	sub    $0x4,%esp
f01002e3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002e5:	eb 2a                	jmp    f0100311 <cons_intr+0x35>
		if (c == 0)
f01002e7:	85 d2                	test   %edx,%edx
f01002e9:	74 26                	je     f0100311 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002eb:	a1 24 c2 22 f0       	mov    0xf022c224,%eax
f01002f0:	8d 48 01             	lea    0x1(%eax),%ecx
f01002f3:	89 0d 24 c2 22 f0    	mov    %ecx,0xf022c224
f01002f9:	88 90 20 c0 22 f0    	mov    %dl,-0xfdd3fe0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002ff:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100305:	75 0a                	jne    f0100311 <cons_intr+0x35>
			cons.wpos = 0;
f0100307:	c7 05 24 c2 22 f0 00 	movl   $0x0,0xf022c224
f010030e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100311:	ff d3                	call   *%ebx
f0100313:	89 c2                	mov    %eax,%edx
f0100315:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100318:	75 cd                	jne    f01002e7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010031a:	83 c4 04             	add    $0x4,%esp
f010031d:	5b                   	pop    %ebx
f010031e:	5d                   	pop    %ebp
f010031f:	c3                   	ret    

f0100320 <kbd_proc_data>:
f0100320:	ba 64 00 00 00       	mov    $0x64,%edx
f0100325:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100326:	a8 01                	test   $0x1,%al
f0100328:	0f 84 ef 00 00 00    	je     f010041d <kbd_proc_data+0xfd>
f010032e:	b2 60                	mov    $0x60,%dl
f0100330:	ec                   	in     (%dx),%al
f0100331:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100333:	3c e0                	cmp    $0xe0,%al
f0100335:	75 0d                	jne    f0100344 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100337:	83 0d 00 c0 22 f0 40 	orl    $0x40,0xf022c000
		return 0;
f010033e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100343:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100344:	55                   	push   %ebp
f0100345:	89 e5                	mov    %esp,%ebp
f0100347:	53                   	push   %ebx
f0100348:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010034b:	84 c0                	test   %al,%al
f010034d:	79 37                	jns    f0100386 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010034f:	8b 0d 00 c0 22 f0    	mov    0xf022c000,%ecx
f0100355:	89 cb                	mov    %ecx,%ebx
f0100357:	83 e3 40             	and    $0x40,%ebx
f010035a:	83 e0 7f             	and    $0x7f,%eax
f010035d:	85 db                	test   %ebx,%ebx
f010035f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100362:	0f b6 d2             	movzbl %dl,%edx
f0100365:	0f b6 82 80 6b 10 f0 	movzbl -0xfef9480(%edx),%eax
f010036c:	83 c8 40             	or     $0x40,%eax
f010036f:	0f b6 c0             	movzbl %al,%eax
f0100372:	f7 d0                	not    %eax
f0100374:	21 c1                	and    %eax,%ecx
f0100376:	89 0d 00 c0 22 f0    	mov    %ecx,0xf022c000
		return 0;
f010037c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100381:	e9 9d 00 00 00       	jmp    f0100423 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100386:	8b 0d 00 c0 22 f0    	mov    0xf022c000,%ecx
f010038c:	f6 c1 40             	test   $0x40,%cl
f010038f:	74 0e                	je     f010039f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100391:	83 c8 80             	or     $0xffffff80,%eax
f0100394:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100396:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100399:	89 0d 00 c0 22 f0    	mov    %ecx,0xf022c000
	}

	shift |= shiftcode[data];
f010039f:	0f b6 d2             	movzbl %dl,%edx
f01003a2:	0f b6 82 80 6b 10 f0 	movzbl -0xfef9480(%edx),%eax
f01003a9:	0b 05 00 c0 22 f0    	or     0xf022c000,%eax
	shift ^= togglecode[data];
f01003af:	0f b6 8a 80 6a 10 f0 	movzbl -0xfef9580(%edx),%ecx
f01003b6:	31 c8                	xor    %ecx,%eax
f01003b8:	a3 00 c0 22 f0       	mov    %eax,0xf022c000

	c = charcode[shift & (CTL | SHIFT)][data];
f01003bd:	89 c1                	mov    %eax,%ecx
f01003bf:	83 e1 03             	and    $0x3,%ecx
f01003c2:	8b 0c 8d 60 6a 10 f0 	mov    -0xfef95a0(,%ecx,4),%ecx
f01003c9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01003cd:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01003d0:	a8 08                	test   $0x8,%al
f01003d2:	74 1b                	je     f01003ef <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01003d4:	89 da                	mov    %ebx,%edx
f01003d6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003d9:	83 f9 19             	cmp    $0x19,%ecx
f01003dc:	77 05                	ja     f01003e3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01003de:	83 eb 20             	sub    $0x20,%ebx
f01003e1:	eb 0c                	jmp    f01003ef <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01003e3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003e6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003e9:	83 fa 19             	cmp    $0x19,%edx
f01003ec:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003ef:	f7 d0                	not    %eax
f01003f1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003f3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003f5:	f6 c2 06             	test   $0x6,%dl
f01003f8:	75 29                	jne    f0100423 <kbd_proc_data+0x103>
f01003fa:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100400:	75 21                	jne    f0100423 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100402:	c7 04 24 23 6a 10 f0 	movl   $0xf0106a23,(%esp)
f0100409:	e8 a8 3c 00 00       	call   f01040b6 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010040e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100413:	b8 03 00 00 00       	mov    $0x3,%eax
f0100418:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100419:	89 d8                	mov    %ebx,%eax
f010041b:	eb 06                	jmp    f0100423 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010041d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100422:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100423:	83 c4 14             	add    $0x14,%esp
f0100426:	5b                   	pop    %ebx
f0100427:	5d                   	pop    %ebp
f0100428:	c3                   	ret    

f0100429 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100429:	55                   	push   %ebp
f010042a:	89 e5                	mov    %esp,%ebp
f010042c:	57                   	push   %edi
f010042d:	56                   	push   %esi
f010042e:	53                   	push   %ebx
f010042f:	83 ec 1c             	sub    $0x1c,%esp
f0100432:	89 c7                	mov    %eax,%edi
f0100434:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100439:	be fd 03 00 00       	mov    $0x3fd,%esi
f010043e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100443:	eb 06                	jmp    f010044b <cons_putc+0x22>
f0100445:	89 ca                	mov    %ecx,%edx
f0100447:	ec                   	in     (%dx),%al
f0100448:	ec                   	in     (%dx),%al
f0100449:	ec                   	in     (%dx),%al
f010044a:	ec                   	in     (%dx),%al
f010044b:	89 f2                	mov    %esi,%edx
f010044d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010044e:	a8 20                	test   $0x20,%al
f0100450:	75 05                	jne    f0100457 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100452:	83 eb 01             	sub    $0x1,%ebx
f0100455:	75 ee                	jne    f0100445 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100457:	89 f8                	mov    %edi,%eax
f0100459:	0f b6 c0             	movzbl %al,%eax
f010045c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010045f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100464:	ee                   	out    %al,(%dx)
f0100465:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010046a:	be 79 03 00 00       	mov    $0x379,%esi
f010046f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100474:	eb 06                	jmp    f010047c <cons_putc+0x53>
f0100476:	89 ca                	mov    %ecx,%edx
f0100478:	ec                   	in     (%dx),%al
f0100479:	ec                   	in     (%dx),%al
f010047a:	ec                   	in     (%dx),%al
f010047b:	ec                   	in     (%dx),%al
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010047f:	84 c0                	test   %al,%al
f0100481:	78 05                	js     f0100488 <cons_putc+0x5f>
f0100483:	83 eb 01             	sub    $0x1,%ebx
f0100486:	75 ee                	jne    f0100476 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100488:	ba 78 03 00 00       	mov    $0x378,%edx
f010048d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100491:	ee                   	out    %al,(%dx)
f0100492:	b2 7a                	mov    $0x7a,%dl
f0100494:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100499:	ee                   	out    %al,(%dx)
f010049a:	b8 08 00 00 00       	mov    $0x8,%eax
f010049f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004a0:	89 fa                	mov    %edi,%edx
f01004a2:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01004a8:	89 f8                	mov    %edi,%eax
f01004aa:	80 cc 07             	or     $0x7,%ah
f01004ad:	85 d2                	test   %edx,%edx
f01004af:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01004b2:	89 f8                	mov    %edi,%eax
f01004b4:	0f b6 c0             	movzbl %al,%eax
f01004b7:	83 f8 09             	cmp    $0x9,%eax
f01004ba:	74 76                	je     f0100532 <cons_putc+0x109>
f01004bc:	83 f8 09             	cmp    $0x9,%eax
f01004bf:	7f 0a                	jg     f01004cb <cons_putc+0xa2>
f01004c1:	83 f8 08             	cmp    $0x8,%eax
f01004c4:	74 16                	je     f01004dc <cons_putc+0xb3>
f01004c6:	e9 9b 00 00 00       	jmp    f0100566 <cons_putc+0x13d>
f01004cb:	83 f8 0a             	cmp    $0xa,%eax
f01004ce:	66 90                	xchg   %ax,%ax
f01004d0:	74 3a                	je     f010050c <cons_putc+0xe3>
f01004d2:	83 f8 0d             	cmp    $0xd,%eax
f01004d5:	74 3d                	je     f0100514 <cons_putc+0xeb>
f01004d7:	e9 8a 00 00 00       	jmp    f0100566 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f01004dc:	0f b7 05 28 c2 22 f0 	movzwl 0xf022c228,%eax
f01004e3:	66 85 c0             	test   %ax,%ax
f01004e6:	0f 84 e5 00 00 00    	je     f01005d1 <cons_putc+0x1a8>
			crt_pos--;
f01004ec:	83 e8 01             	sub    $0x1,%eax
f01004ef:	66 a3 28 c2 22 f0    	mov    %ax,0xf022c228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004f5:	0f b7 c0             	movzwl %ax,%eax
f01004f8:	66 81 e7 00 ff       	and    $0xff00,%di
f01004fd:	83 cf 20             	or     $0x20,%edi
f0100500:	8b 15 2c c2 22 f0    	mov    0xf022c22c,%edx
f0100506:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010050a:	eb 78                	jmp    f0100584 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010050c:	66 83 05 28 c2 22 f0 	addw   $0x50,0xf022c228
f0100513:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100514:	0f b7 05 28 c2 22 f0 	movzwl 0xf022c228,%eax
f010051b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100521:	c1 e8 16             	shr    $0x16,%eax
f0100524:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100527:	c1 e0 04             	shl    $0x4,%eax
f010052a:	66 a3 28 c2 22 f0    	mov    %ax,0xf022c228
f0100530:	eb 52                	jmp    f0100584 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f0100532:	b8 20 00 00 00       	mov    $0x20,%eax
f0100537:	e8 ed fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f010053c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100541:	e8 e3 fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f0100546:	b8 20 00 00 00       	mov    $0x20,%eax
f010054b:	e8 d9 fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f0100550:	b8 20 00 00 00       	mov    $0x20,%eax
f0100555:	e8 cf fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f010055a:	b8 20 00 00 00       	mov    $0x20,%eax
f010055f:	e8 c5 fe ff ff       	call   f0100429 <cons_putc>
f0100564:	eb 1e                	jmp    f0100584 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100566:	0f b7 05 28 c2 22 f0 	movzwl 0xf022c228,%eax
f010056d:	8d 50 01             	lea    0x1(%eax),%edx
f0100570:	66 89 15 28 c2 22 f0 	mov    %dx,0xf022c228
f0100577:	0f b7 c0             	movzwl %ax,%eax
f010057a:	8b 15 2c c2 22 f0    	mov    0xf022c22c,%edx
f0100580:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100584:	66 81 3d 28 c2 22 f0 	cmpw   $0x7cf,0xf022c228
f010058b:	cf 07 
f010058d:	76 42                	jbe    f01005d1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010058f:	a1 2c c2 22 f0       	mov    0xf022c22c,%eax
f0100594:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010059b:	00 
f010059c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005a2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005a6:	89 04 24             	mov    %eax,(%esp)
f01005a9:	e8 c6 56 00 00       	call   f0105c74 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005ae:	8b 15 2c c2 22 f0    	mov    0xf022c22c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005b4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01005b9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005bf:	83 c0 01             	add    $0x1,%eax
f01005c2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01005c7:	75 f0                	jne    f01005b9 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005c9:	66 83 2d 28 c2 22 f0 	subw   $0x50,0xf022c228
f01005d0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005d1:	8b 0d 30 c2 22 f0    	mov    0xf022c230,%ecx
f01005d7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005dc:	89 ca                	mov    %ecx,%edx
f01005de:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005df:	0f b7 1d 28 c2 22 f0 	movzwl 0xf022c228,%ebx
f01005e6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005e9:	89 d8                	mov    %ebx,%eax
f01005eb:	66 c1 e8 08          	shr    $0x8,%ax
f01005ef:	89 f2                	mov    %esi,%edx
f01005f1:	ee                   	out    %al,(%dx)
f01005f2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005f7:	89 ca                	mov    %ecx,%edx
f01005f9:	ee                   	out    %al,(%dx)
f01005fa:	89 d8                	mov    %ebx,%eax
f01005fc:	89 f2                	mov    %esi,%edx
f01005fe:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005ff:	83 c4 1c             	add    $0x1c,%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5e                   	pop    %esi
f0100604:	5f                   	pop    %edi
f0100605:	5d                   	pop    %ebp
f0100606:	c3                   	ret    

f0100607 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100607:	80 3d 34 c2 22 f0 00 	cmpb   $0x0,0xf022c234
f010060e:	74 11                	je     f0100621 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100616:	b8 c0 02 10 f0       	mov    $0xf01002c0,%eax
f010061b:	e8 bc fc ff ff       	call   f01002dc <cons_intr>
}
f0100620:	c9                   	leave  
f0100621:	f3 c3                	repz ret 

f0100623 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100623:	55                   	push   %ebp
f0100624:	89 e5                	mov    %esp,%ebp
f0100626:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100629:	b8 20 03 10 f0       	mov    $0xf0100320,%eax
f010062e:	e8 a9 fc ff ff       	call   f01002dc <cons_intr>
}
f0100633:	c9                   	leave  
f0100634:	c3                   	ret    

f0100635 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100635:	55                   	push   %ebp
f0100636:	89 e5                	mov    %esp,%ebp
f0100638:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010063b:	e8 c7 ff ff ff       	call   f0100607 <serial_intr>
	kbd_intr();
f0100640:	e8 de ff ff ff       	call   f0100623 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100645:	a1 20 c2 22 f0       	mov    0xf022c220,%eax
f010064a:	3b 05 24 c2 22 f0    	cmp    0xf022c224,%eax
f0100650:	74 26                	je     f0100678 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100652:	8d 50 01             	lea    0x1(%eax),%edx
f0100655:	89 15 20 c2 22 f0    	mov    %edx,0xf022c220
f010065b:	0f b6 88 20 c0 22 f0 	movzbl -0xfdd3fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100662:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100664:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010066a:	75 11                	jne    f010067d <cons_getc+0x48>
			cons.rpos = 0;
f010066c:	c7 05 20 c2 22 f0 00 	movl   $0x0,0xf022c220
f0100673:	00 00 00 
f0100676:	eb 05                	jmp    f010067d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100678:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010067d:	c9                   	leave  
f010067e:	c3                   	ret    

f010067f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010067f:	55                   	push   %ebp
f0100680:	89 e5                	mov    %esp,%ebp
f0100682:	57                   	push   %edi
f0100683:	56                   	push   %esi
f0100684:	53                   	push   %ebx
f0100685:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100688:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010068f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100696:	5a a5 
	if (*cp != 0xA55A) {
f0100698:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010069f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01006a3:	74 11                	je     f01006b6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01006a5:	c7 05 30 c2 22 f0 b4 	movl   $0x3b4,0xf022c230
f01006ac:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01006af:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01006b4:	eb 16                	jmp    f01006cc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01006b6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006bd:	c7 05 30 c2 22 f0 d4 	movl   $0x3d4,0xf022c230
f01006c4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006c7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01006cc:	8b 0d 30 c2 22 f0    	mov    0xf022c230,%ecx
f01006d2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006d7:	89 ca                	mov    %ecx,%edx
f01006d9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006da:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006dd:	89 da                	mov    %ebx,%edx
f01006df:	ec                   	in     (%dx),%al
f01006e0:	0f b6 f0             	movzbl %al,%esi
f01006e3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006e6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006eb:	89 ca                	mov    %ecx,%edx
f01006ed:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ee:	89 da                	mov    %ebx,%edx
f01006f0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006f1:	89 3d 2c c2 22 f0    	mov    %edi,0xf022c22c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01006f7:	0f b6 d8             	movzbl %al,%ebx
f01006fa:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01006fc:	66 89 35 28 c2 22 f0 	mov    %si,0xf022c228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f0100703:	e8 1b ff ff ff       	call   f0100623 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f0100708:	0f b7 05 a8 13 12 f0 	movzwl 0xf01213a8,%eax
f010070f:	25 fd ff 00 00       	and    $0xfffd,%eax
f0100714:	89 04 24             	mov    %eax,(%esp)
f0100717:	e8 5b 38 00 00       	call   f0103f77 <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010071c:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100721:	b8 00 00 00 00       	mov    $0x0,%eax
f0100726:	89 f2                	mov    %esi,%edx
f0100728:	ee                   	out    %al,(%dx)
f0100729:	b2 fb                	mov    $0xfb,%dl
f010072b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100730:	ee                   	out    %al,(%dx)
f0100731:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100736:	b8 0c 00 00 00       	mov    $0xc,%eax
f010073b:	89 da                	mov    %ebx,%edx
f010073d:	ee                   	out    %al,(%dx)
f010073e:	b2 f9                	mov    $0xf9,%dl
f0100740:	b8 00 00 00 00       	mov    $0x0,%eax
f0100745:	ee                   	out    %al,(%dx)
f0100746:	b2 fb                	mov    $0xfb,%dl
f0100748:	b8 03 00 00 00       	mov    $0x3,%eax
f010074d:	ee                   	out    %al,(%dx)
f010074e:	b2 fc                	mov    $0xfc,%dl
f0100750:	b8 00 00 00 00       	mov    $0x0,%eax
f0100755:	ee                   	out    %al,(%dx)
f0100756:	b2 f9                	mov    $0xf9,%dl
f0100758:	b8 01 00 00 00       	mov    $0x1,%eax
f010075d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010075e:	b2 fd                	mov    $0xfd,%dl
f0100760:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100761:	3c ff                	cmp    $0xff,%al
f0100763:	0f 95 c1             	setne  %cl
f0100766:	88 0d 34 c2 22 f0    	mov    %cl,0xf022c234
f010076c:	89 f2                	mov    %esi,%edx
f010076e:	ec                   	in     (%dx),%al
f010076f:	89 da                	mov    %ebx,%edx
f0100771:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100772:	84 c9                	test   %cl,%cl
f0100774:	75 0c                	jne    f0100782 <cons_init+0x103>
		cprintf("Serial port does not exist!\n");
f0100776:	c7 04 24 2f 6a 10 f0 	movl   $0xf0106a2f,(%esp)
f010077d:	e8 34 39 00 00       	call   f01040b6 <cprintf>
}
f0100782:	83 c4 1c             	add    $0x1c,%esp
f0100785:	5b                   	pop    %ebx
f0100786:	5e                   	pop    %esi
f0100787:	5f                   	pop    %edi
f0100788:	5d                   	pop    %ebp
f0100789:	c3                   	ret    

f010078a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010078a:	55                   	push   %ebp
f010078b:	89 e5                	mov    %esp,%ebp
f010078d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100790:	8b 45 08             	mov    0x8(%ebp),%eax
f0100793:	e8 91 fc ff ff       	call   f0100429 <cons_putc>
}
f0100798:	c9                   	leave  
f0100799:	c3                   	ret    

f010079a <getchar>:

int
getchar(void)
{
f010079a:	55                   	push   %ebp
f010079b:	89 e5                	mov    %esp,%ebp
f010079d:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007a0:	e8 90 fe ff ff       	call   f0100635 <cons_getc>
f01007a5:	85 c0                	test   %eax,%eax
f01007a7:	74 f7                	je     f01007a0 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007a9:	c9                   	leave  
f01007aa:	c3                   	ret    

f01007ab <iscons>:

int
iscons(int fdnum)
{
f01007ab:	55                   	push   %ebp
f01007ac:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007ae:	b8 01 00 00 00       	mov    $0x1,%eax
f01007b3:	5d                   	pop    %ebp
f01007b4:	c3                   	ret    
f01007b5:	66 90                	xchg   %ax,%ax
f01007b7:	66 90                	xchg   %ax,%ax
f01007b9:	66 90                	xchg   %ax,%ax
f01007bb:	66 90                	xchg   %ax,%ax
f01007bd:	66 90                	xchg   %ax,%ax
f01007bf:	90                   	nop

f01007c0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007c0:	55                   	push   %ebp
f01007c1:	89 e5                	mov    %esp,%ebp
f01007c3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007c6:	c7 44 24 08 80 6c 10 	movl   $0xf0106c80,0x8(%esp)
f01007cd:	f0 
f01007ce:	c7 44 24 04 9e 6c 10 	movl   $0xf0106c9e,0x4(%esp)
f01007d5:	f0 
f01007d6:	c7 04 24 a3 6c 10 f0 	movl   $0xf0106ca3,(%esp)
f01007dd:	e8 d4 38 00 00       	call   f01040b6 <cprintf>
f01007e2:	c7 44 24 08 38 6d 10 	movl   $0xf0106d38,0x8(%esp)
f01007e9:	f0 
f01007ea:	c7 44 24 04 ac 6c 10 	movl   $0xf0106cac,0x4(%esp)
f01007f1:	f0 
f01007f2:	c7 04 24 a3 6c 10 f0 	movl   $0xf0106ca3,(%esp)
f01007f9:	e8 b8 38 00 00       	call   f01040b6 <cprintf>
f01007fe:	c7 44 24 08 60 6d 10 	movl   $0xf0106d60,0x8(%esp)
f0100805:	f0 
f0100806:	c7 44 24 04 b5 6c 10 	movl   $0xf0106cb5,0x4(%esp)
f010080d:	f0 
f010080e:	c7 04 24 a3 6c 10 f0 	movl   $0xf0106ca3,(%esp)
f0100815:	e8 9c 38 00 00       	call   f01040b6 <cprintf>
	return 0;
}
f010081a:	b8 00 00 00 00       	mov    $0x0,%eax
f010081f:	c9                   	leave  
f0100820:	c3                   	ret    

f0100821 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100821:	55                   	push   %ebp
f0100822:	89 e5                	mov    %esp,%ebp
f0100824:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100827:	c7 04 24 bf 6c 10 f0 	movl   $0xf0106cbf,(%esp)
f010082e:	e8 83 38 00 00       	call   f01040b6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100833:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010083a:	00 
f010083b:	c7 04 24 9c 6d 10 f0 	movl   $0xf0106d9c,(%esp)
f0100842:	e8 6f 38 00 00       	call   f01040b6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100847:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010084e:	00 
f010084f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100856:	f0 
f0100857:	c7 04 24 c4 6d 10 f0 	movl   $0xf0106dc4,(%esp)
f010085e:	e8 53 38 00 00       	call   f01040b6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100863:	c7 44 24 08 47 69 10 	movl   $0x106947,0x8(%esp)
f010086a:	00 
f010086b:	c7 44 24 04 47 69 10 	movl   $0xf0106947,0x4(%esp)
f0100872:	f0 
f0100873:	c7 04 24 e8 6d 10 f0 	movl   $0xf0106de8,(%esp)
f010087a:	e8 37 38 00 00       	call   f01040b6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010087f:	c7 44 24 08 07 bd 22 	movl   $0x22bd07,0x8(%esp)
f0100886:	00 
f0100887:	c7 44 24 04 07 bd 22 	movl   $0xf022bd07,0x4(%esp)
f010088e:	f0 
f010088f:	c7 04 24 0c 6e 10 f0 	movl   $0xf0106e0c,(%esp)
f0100896:	e8 1b 38 00 00       	call   f01040b6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010089b:	c7 44 24 08 08 e0 26 	movl   $0x26e008,0x8(%esp)
f01008a2:	00 
f01008a3:	c7 44 24 04 08 e0 26 	movl   $0xf026e008,0x4(%esp)
f01008aa:	f0 
f01008ab:	c7 04 24 30 6e 10 f0 	movl   $0xf0106e30,(%esp)
f01008b2:	e8 ff 37 00 00       	call   f01040b6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01008b7:	b8 07 e4 26 f0       	mov    $0xf026e407,%eax
f01008bc:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01008c1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008c6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008cc:	85 c0                	test   %eax,%eax
f01008ce:	0f 48 c2             	cmovs  %edx,%eax
f01008d1:	c1 f8 0a             	sar    $0xa,%eax
f01008d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d8:	c7 04 24 54 6e 10 f0 	movl   $0xf0106e54,(%esp)
f01008df:	e8 d2 37 00 00       	call   f01040b6 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01008e9:	c9                   	leave  
f01008ea:	c3                   	ret    

f01008eb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{	uint32_t *cur_ebp;
f01008eb:	55                   	push   %ebp
f01008ec:	89 e5                	mov    %esp,%ebp
f01008ee:	56                   	push   %esi
f01008ef:	53                   	push   %ebx
f01008f0:	83 ec 40             	sub    $0x40,%esp
	struct Eipdebuginfo info;
	cur_ebp = (uint32_t *)read_ebp();
f01008f3:	89 eb                	mov    %ebp,%ebx
	while(cur_ebp !=NULL ){	
	cprintf("Stack backtrace:\n");
	cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x \n",cur_ebp, 		*(cur_ebp+1),*(cur_ebp+2),*(cur_ebp+3),*(cur_ebp+4),*(cur_ebp+5),
	*(cur_ebp+6));

	debuginfo_eip(*(cur_ebp+1), &info);
f01008f5:	8d 75 e0             	lea    -0x20(%ebp),%esi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{	uint32_t *cur_ebp;
	struct Eipdebuginfo info;
	cur_ebp = (uint32_t *)read_ebp();
	while(cur_ebp !=NULL ){	
f01008f8:	e9 89 00 00 00       	jmp    f0100986 <mon_backtrace+0x9b>
	cprintf("Stack backtrace:\n");
f01008fd:	c7 04 24 d8 6c 10 f0 	movl   $0xf0106cd8,(%esp)
f0100904:	e8 ad 37 00 00       	call   f01040b6 <cprintf>
	cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x \n",cur_ebp, 		*(cur_ebp+1),*(cur_ebp+2),*(cur_ebp+3),*(cur_ebp+4),*(cur_ebp+5),
f0100909:	8b 43 18             	mov    0x18(%ebx),%eax
f010090c:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100910:	8b 43 14             	mov    0x14(%ebx),%eax
f0100913:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100917:	8b 43 10             	mov    0x10(%ebx),%eax
f010091a:	89 44 24 14          	mov    %eax,0x14(%esp)
f010091e:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100921:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100925:	8b 43 08             	mov    0x8(%ebx),%eax
f0100928:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010092c:	8b 43 04             	mov    0x4(%ebx),%eax
f010092f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100933:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100937:	c7 04 24 80 6e 10 f0 	movl   $0xf0106e80,(%esp)
f010093e:	e8 73 37 00 00       	call   f01040b6 <cprintf>
	*(cur_ebp+6));

	debuginfo_eip(*(cur_ebp+1), &info);
f0100943:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100947:	8b 43 04             	mov    0x4(%ebx),%eax
f010094a:	89 04 24             	mov    %eax,(%esp)
f010094d:	e8 8c 47 00 00       	call   f01050de <debuginfo_eip>
	
	cprintf("%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,
f0100952:	8b 43 04             	mov    0x4(%ebx),%eax
f0100955:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100958:	89 44 24 14          	mov    %eax,0x14(%esp)
f010095c:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010095f:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100963:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100966:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010096a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010096d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100971:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100974:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100978:	c7 04 24 ea 6c 10 f0 	movl   $0xf0106cea,(%esp)
f010097f:	e8 32 37 00 00       	call   f01040b6 <cprintf>
	info.eip_fn_namelen,info.eip_fn_name,(*(cur_ebp+1) - 
	info.eip_fn_addr));
	
	cur_ebp=(uint32_t *) *cur_ebp;	
f0100984:	8b 1b                	mov    (%ebx),%ebx
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{	uint32_t *cur_ebp;
	struct Eipdebuginfo info;
	cur_ebp = (uint32_t *)read_ebp();
	while(cur_ebp !=NULL ){	
f0100986:	85 db                	test   %ebx,%ebx
f0100988:	0f 85 6f ff ff ff    	jne    f01008fd <mon_backtrace+0x12>
	info.eip_fn_addr));
	
	cur_ebp=(uint32_t *) *cur_ebp;	
	}
return 0;
}
f010098e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100993:	83 c4 40             	add    $0x40,%esp
f0100996:	5b                   	pop    %ebx
f0100997:	5e                   	pop    %esi
f0100998:	5d                   	pop    %ebp
f0100999:	c3                   	ret    

f010099a <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010099a:	55                   	push   %ebp
f010099b:	89 e5                	mov    %esp,%ebp
f010099d:	57                   	push   %edi
f010099e:	56                   	push   %esi
f010099f:	53                   	push   %ebx
f01009a0:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009a3:	c7 04 24 b4 6e 10 f0 	movl   $0xf0106eb4,(%esp)
f01009aa:	e8 07 37 00 00       	call   f01040b6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009af:	c7 04 24 d8 6e 10 f0 	movl   $0xf0106ed8,(%esp)
f01009b6:	e8 fb 36 00 00       	call   f01040b6 <cprintf>

	if (tf != NULL)
f01009bb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009bf:	74 0b                	je     f01009cc <monitor+0x32>
		print_trapframe(tf);
f01009c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01009c4:	89 04 24             	mov    %eax,(%esp)
f01009c7:	e8 cc 38 00 00       	call   f0104298 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f01009cc:	c7 04 24 fa 6c 10 f0 	movl   $0xf0106cfa,(%esp)
f01009d3:	e8 f8 4f 00 00       	call   f01059d0 <readline>
f01009d8:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01009da:	85 c0                	test   %eax,%eax
f01009dc:	74 ee                	je     f01009cc <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01009de:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01009e5:	be 00 00 00 00       	mov    $0x0,%esi
f01009ea:	eb 0a                	jmp    f01009f6 <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01009ec:	c6 03 00             	movb   $0x0,(%ebx)
f01009ef:	89 f7                	mov    %esi,%edi
f01009f1:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01009f4:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01009f6:	0f b6 03             	movzbl (%ebx),%eax
f01009f9:	84 c0                	test   %al,%al
f01009fb:	74 63                	je     f0100a60 <monitor+0xc6>
f01009fd:	0f be c0             	movsbl %al,%eax
f0100a00:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a04:	c7 04 24 fe 6c 10 f0 	movl   $0xf0106cfe,(%esp)
f0100a0b:	e8 da 51 00 00       	call   f0105bea <strchr>
f0100a10:	85 c0                	test   %eax,%eax
f0100a12:	75 d8                	jne    f01009ec <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f0100a14:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a17:	74 47                	je     f0100a60 <monitor+0xc6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100a19:	83 fe 0f             	cmp    $0xf,%esi
f0100a1c:	75 16                	jne    f0100a34 <monitor+0x9a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a1e:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100a25:	00 
f0100a26:	c7 04 24 03 6d 10 f0 	movl   $0xf0106d03,(%esp)
f0100a2d:	e8 84 36 00 00       	call   f01040b6 <cprintf>
f0100a32:	eb 98                	jmp    f01009cc <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f0100a34:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a37:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100a3b:	eb 03                	jmp    f0100a40 <monitor+0xa6>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100a3d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a40:	0f b6 03             	movzbl (%ebx),%eax
f0100a43:	84 c0                	test   %al,%al
f0100a45:	74 ad                	je     f01009f4 <monitor+0x5a>
f0100a47:	0f be c0             	movsbl %al,%eax
f0100a4a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a4e:	c7 04 24 fe 6c 10 f0 	movl   $0xf0106cfe,(%esp)
f0100a55:	e8 90 51 00 00       	call   f0105bea <strchr>
f0100a5a:	85 c0                	test   %eax,%eax
f0100a5c:	74 df                	je     f0100a3d <monitor+0xa3>
f0100a5e:	eb 94                	jmp    f01009f4 <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f0100a60:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a67:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a68:	85 f6                	test   %esi,%esi
f0100a6a:	0f 84 5c ff ff ff    	je     f01009cc <monitor+0x32>
f0100a70:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100a75:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a78:	8b 04 85 00 6f 10 f0 	mov    -0xfef9100(,%eax,4),%eax
f0100a7f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a83:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a86:	89 04 24             	mov    %eax,(%esp)
f0100a89:	e8 fe 50 00 00       	call   f0105b8c <strcmp>
f0100a8e:	85 c0                	test   %eax,%eax
f0100a90:	75 24                	jne    f0100ab6 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100a92:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a95:	8b 55 08             	mov    0x8(%ebp),%edx
f0100a98:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a9c:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100a9f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100aa3:	89 34 24             	mov    %esi,(%esp)
f0100aa6:	ff 14 85 08 6f 10 f0 	call   *-0xfef90f8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100aad:	85 c0                	test   %eax,%eax
f0100aaf:	78 25                	js     f0100ad6 <monitor+0x13c>
f0100ab1:	e9 16 ff ff ff       	jmp    f01009cc <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100ab6:	83 c3 01             	add    $0x1,%ebx
f0100ab9:	83 fb 03             	cmp    $0x3,%ebx
f0100abc:	75 b7                	jne    f0100a75 <monitor+0xdb>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100abe:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100ac1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ac5:	c7 04 24 20 6d 10 f0 	movl   $0xf0106d20,(%esp)
f0100acc:	e8 e5 35 00 00       	call   f01040b6 <cprintf>
f0100ad1:	e9 f6 fe ff ff       	jmp    f01009cc <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100ad6:	83 c4 5c             	add    $0x5c,%esp
f0100ad9:	5b                   	pop    %ebx
f0100ada:	5e                   	pop    %esi
f0100adb:	5f                   	pop    %edi
f0100adc:	5d                   	pop    %ebp
f0100add:	c3                   	ret    
f0100ade:	66 90                	xchg   %ax,%ax

f0100ae0 <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ae0:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0100ae6:	c1 f8 03             	sar    $0x3,%eax
f0100ae9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aec:	89 c2                	mov    %eax,%edx
f0100aee:	c1 ea 0c             	shr    $0xc,%edx
f0100af1:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0100af7:	72 26                	jb     f0100b1f <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100af9:	55                   	push   %ebp
f0100afa:	89 e5                	mov    %esp,%ebp
f0100afc:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100aff:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b03:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0100b0a:	f0 
f0100b0b:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100b12:	00 
f0100b13:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f0100b1a:	e8 21 f5 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100b1f:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100b24:	c3                   	ret    

f0100b25 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b25:	89 d1                	mov    %edx,%ecx
f0100b27:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100b2a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100b2d:	a8 01                	test   $0x1,%al
f0100b2f:	74 5d                	je     f0100b8e <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b31:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b36:	89 c1                	mov    %eax,%ecx
f0100b38:	c1 e9 0c             	shr    $0xc,%ecx
f0100b3b:	3b 0d 88 ce 22 f0    	cmp    0xf022ce88,%ecx
f0100b41:	72 26                	jb     f0100b69 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b43:	55                   	push   %ebp
f0100b44:	89 e5                	mov    %esp,%ebp
f0100b46:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b49:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b4d:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0100b54:	f0 
f0100b55:	c7 44 24 04 e3 03 00 	movl   $0x3e3,0x4(%esp)
f0100b5c:	00 
f0100b5d:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100b64:	e8 d7 f4 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100b69:	c1 ea 0c             	shr    $0xc,%edx
f0100b6c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b72:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b79:	89 c2                	mov    %eax,%edx
f0100b7b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b7e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b83:	85 d2                	test   %edx,%edx
f0100b85:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b8a:	0f 44 c2             	cmove  %edx,%eax
f0100b8d:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b8e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b93:	c3                   	ret    

f0100b94 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b94:	55                   	push   %ebp
f0100b95:	89 e5                	mov    %esp,%ebp
f0100b97:	83 ec 18             	sub    $0x18,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b9a:	83 3d 38 c2 22 f0 00 	cmpl   $0x0,0xf022c238
f0100ba1:	75 11                	jne    f0100bb4 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100ba3:	ba 07 f0 26 f0       	mov    $0xf026f007,%edx
f0100ba8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bae:	89 15 38 c2 22 f0    	mov    %edx,0xf022c238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0){
f0100bb4:	85 c0                	test   %eax,%eax
f0100bb6:	74 71                	je     f0100c29 <boot_alloc+0x95>
		nextfree = ROUNDUP(nextfree, PGSIZE);
f0100bb8:	8b 0d 38 c2 22 f0    	mov    0xf022c238,%ecx
f0100bbe:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100bc4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
		result = nextfree;
		nextfree +=n;
f0100bca:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f0100bcd:	89 15 38 c2 22 f0    	mov    %edx,0xf022c238
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100bd3:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100bd9:	77 20                	ja     f0100bfb <boot_alloc+0x67>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100bdb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100bdf:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0100be6:	f0 
f0100be7:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
f0100bee:	00 
f0100bef:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100bf6:	e8 45 f4 ff ff       	call   f0100040 <_panic>
		if(PADDR(nextfree) > npages*PGSIZE){
f0100bfb:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f0100c00:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100c03:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100c09:	39 d0                	cmp    %edx,%eax
f0100c0b:	73 23                	jae    f0100c30 <boot_alloc+0x9c>
		   panic("kernel out of memory! \n");	   	
f0100c0d:	c7 44 24 08 f3 78 10 	movl   $0xf01078f3,0x8(%esp)
f0100c14:	f0 
f0100c15:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
f0100c1c:	00 
f0100c1d:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100c24:	e8 17 f4 ff ff       	call   f0100040 <_panic>
		   
		}		
		return (void *)result;
	}
	else {
		return (void*)nextfree;
f0100c29:	a1 38 c2 22 f0       	mov    0xf022c238,%eax
f0100c2e:	eb 02                	jmp    f0100c32 <boot_alloc+0x9e>
		nextfree +=n;
		if(PADDR(nextfree) > npages*PGSIZE){
		   panic("kernel out of memory! \n");	   	
		   
		}		
		return (void *)result;
f0100c30:	89 c8                	mov    %ecx,%eax
	}
	else {
		return (void*)nextfree;
	}
}
f0100c32:	c9                   	leave  
f0100c33:	c3                   	ret    

f0100c34 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100c34:	55                   	push   %ebp
f0100c35:	89 e5                	mov    %esp,%ebp
f0100c37:	57                   	push   %edi
f0100c38:	56                   	push   %esi
f0100c39:	53                   	push   %ebx
f0100c3a:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c3d:	84 c0                	test   %al,%al
f0100c3f:	0f 85 31 03 00 00    	jne    f0100f76 <check_page_free_list+0x342>
f0100c45:	e9 3e 03 00 00       	jmp    f0100f88 <check_page_free_list+0x354>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100c4a:	c7 44 24 08 24 6f 10 	movl   $0xf0106f24,0x8(%esp)
f0100c51:	f0 
f0100c52:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f0100c59:	00 
f0100c5a:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100c61:	e8 da f3 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100c66:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c69:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c6c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c6f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c72:	89 c2                	mov    %eax,%edx
f0100c74:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c7a:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c80:	0f 95 c2             	setne  %dl
f0100c83:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c86:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c8a:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c8c:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c90:	8b 00                	mov    (%eax),%eax
f0100c92:	85 c0                	test   %eax,%eax
f0100c94:	75 dc                	jne    f0100c72 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c96:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c99:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ca2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ca5:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ca7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100caa:	a3 40 c2 22 f0       	mov    %eax,0xf022c240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100caf:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100cb4:	8b 1d 40 c2 22 f0    	mov    0xf022c240,%ebx
f0100cba:	eb 63                	jmp    f0100d1f <check_page_free_list+0xeb>
f0100cbc:	89 d8                	mov    %ebx,%eax
f0100cbe:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0100cc4:	c1 f8 03             	sar    $0x3,%eax
f0100cc7:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100cca:	89 c2                	mov    %eax,%edx
f0100ccc:	c1 ea 16             	shr    $0x16,%edx
f0100ccf:	39 f2                	cmp    %esi,%edx
f0100cd1:	73 4a                	jae    f0100d1d <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cd3:	89 c2                	mov    %eax,%edx
f0100cd5:	c1 ea 0c             	shr    $0xc,%edx
f0100cd8:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0100cde:	72 20                	jb     f0100d00 <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ce0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ce4:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0100ceb:	f0 
f0100cec:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100cf3:	00 
f0100cf4:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f0100cfb:	e8 40 f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100d00:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100d07:	00 
f0100d08:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100d0f:	00 
	return (void *)(pa + KERNBASE);
f0100d10:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d15:	89 04 24             	mov    %eax,(%esp)
f0100d18:	e8 0a 4f 00 00       	call   f0105c27 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d1d:	8b 1b                	mov    (%ebx),%ebx
f0100d1f:	85 db                	test   %ebx,%ebx
f0100d21:	75 99                	jne    f0100cbc <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100d23:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d28:	e8 67 fe ff ff       	call   f0100b94 <boot_alloc>
f0100d2d:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d30:	8b 15 40 c2 22 f0    	mov    0xf022c240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d36:	8b 0d 90 ce 22 f0    	mov    0xf022ce90,%ecx
		assert(pp < pages + npages);
f0100d3c:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f0100d41:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100d44:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100d47:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d4a:	89 4d cc             	mov    %ecx,-0x34(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100d4d:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d52:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d55:	e9 c4 01 00 00       	jmp    f0100f1e <check_page_free_list+0x2ea>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d5a:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100d5d:	73 24                	jae    f0100d83 <check_page_free_list+0x14f>
f0100d5f:	c7 44 24 0c 0b 79 10 	movl   $0xf010790b,0xc(%esp)
f0100d66:	f0 
f0100d67:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0100d6e:	f0 
f0100d6f:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0100d76:	00 
f0100d77:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100d7e:	e8 bd f2 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100d83:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100d86:	72 24                	jb     f0100dac <check_page_free_list+0x178>
f0100d88:	c7 44 24 0c 2c 79 10 	movl   $0xf010792c,0xc(%esp)
f0100d8f:	f0 
f0100d90:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0100d97:	f0 
f0100d98:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0100d9f:	00 
f0100da0:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100da7:	e8 94 f2 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100dac:	89 d0                	mov    %edx,%eax
f0100dae:	2b 45 cc             	sub    -0x34(%ebp),%eax
f0100db1:	a8 07                	test   $0x7,%al
f0100db3:	74 24                	je     f0100dd9 <check_page_free_list+0x1a5>
f0100db5:	c7 44 24 0c 48 6f 10 	movl   $0xf0106f48,0xc(%esp)
f0100dbc:	f0 
f0100dbd:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0100dc4:	f0 
f0100dc5:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0100dcc:	00 
f0100dcd:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100dd4:	e8 67 f2 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dd9:	c1 f8 03             	sar    $0x3,%eax
f0100ddc:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ddf:	85 c0                	test   %eax,%eax
f0100de1:	75 24                	jne    f0100e07 <check_page_free_list+0x1d3>
f0100de3:	c7 44 24 0c 40 79 10 	movl   $0xf0107940,0xc(%esp)
f0100dea:	f0 
f0100deb:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0100df2:	f0 
f0100df3:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0100dfa:	00 
f0100dfb:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100e02:	e8 39 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e07:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e0c:	75 24                	jne    f0100e32 <check_page_free_list+0x1fe>
f0100e0e:	c7 44 24 0c 51 79 10 	movl   $0xf0107951,0xc(%esp)
f0100e15:	f0 
f0100e16:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0100e1d:	f0 
f0100e1e:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0100e25:	00 
f0100e26:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100e2d:	e8 0e f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e32:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e37:	75 24                	jne    f0100e5d <check_page_free_list+0x229>
f0100e39:	c7 44 24 0c 7c 6f 10 	movl   $0xf0106f7c,0xc(%esp)
f0100e40:	f0 
f0100e41:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0100e48:	f0 
f0100e49:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0100e50:	00 
f0100e51:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100e58:	e8 e3 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e5d:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e62:	75 24                	jne    f0100e88 <check_page_free_list+0x254>
f0100e64:	c7 44 24 0c 6a 79 10 	movl   $0xf010796a,0xc(%esp)
f0100e6b:	f0 
f0100e6c:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0100e73:	f0 
f0100e74:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0100e7b:	00 
f0100e7c:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100e83:	e8 b8 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e88:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e8d:	0f 86 1c 01 00 00    	jbe    f0100faf <check_page_free_list+0x37b>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e93:	89 c1                	mov    %eax,%ecx
f0100e95:	c1 e9 0c             	shr    $0xc,%ecx
f0100e98:	39 4d c4             	cmp    %ecx,-0x3c(%ebp)
f0100e9b:	77 20                	ja     f0100ebd <check_page_free_list+0x289>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e9d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ea1:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0100ea8:	f0 
f0100ea9:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100eb0:	00 
f0100eb1:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f0100eb8:	e8 83 f1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100ebd:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f0100ec3:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100ec6:	0f 86 d3 00 00 00    	jbe    f0100f9f <check_page_free_list+0x36b>
f0100ecc:	c7 44 24 0c a0 6f 10 	movl   $0xf0106fa0,0xc(%esp)
f0100ed3:	f0 
f0100ed4:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0100edb:	f0 
f0100edc:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0100ee3:	00 
f0100ee4:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100eeb:	e8 50 f1 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100ef0:	c7 44 24 0c 84 79 10 	movl   $0xf0107984,0xc(%esp)
f0100ef7:	f0 
f0100ef8:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0100eff:	f0 
f0100f00:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0100f07:	00 
f0100f08:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100f0f:	e8 2c f1 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100f14:	83 c3 01             	add    $0x1,%ebx
f0100f17:	eb 03                	jmp    f0100f1c <check_page_free_list+0x2e8>
		else
			++nfree_extmem;
f0100f19:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f1c:	8b 12                	mov    (%edx),%edx
f0100f1e:	85 d2                	test   %edx,%edx
f0100f20:	0f 85 34 fe ff ff    	jne    f0100d5a <check_page_free_list+0x126>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100f26:	85 db                	test   %ebx,%ebx
f0100f28:	7f 24                	jg     f0100f4e <check_page_free_list+0x31a>
f0100f2a:	c7 44 24 0c a1 79 10 	movl   $0xf01079a1,0xc(%esp)
f0100f31:	f0 
f0100f32:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0100f39:	f0 
f0100f3a:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0100f41:	00 
f0100f42:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100f49:	e8 f2 f0 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100f4e:	85 ff                	test   %edi,%edi
f0100f50:	7f 73                	jg     f0100fc5 <check_page_free_list+0x391>
f0100f52:	c7 44 24 0c b3 79 10 	movl   $0xf01079b3,0xc(%esp)
f0100f59:	f0 
f0100f5a:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0100f61:	f0 
f0100f62:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0100f69:	00 
f0100f6a:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0100f71:	e8 ca f0 ff ff       	call   f0100040 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100f76:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f0100f7b:	85 c0                	test   %eax,%eax
f0100f7d:	0f 85 e3 fc ff ff    	jne    f0100c66 <check_page_free_list+0x32>
f0100f83:	e9 c2 fc ff ff       	jmp    f0100c4a <check_page_free_list+0x16>
f0100f88:	83 3d 40 c2 22 f0 00 	cmpl   $0x0,0xf022c240
f0100f8f:	0f 84 b5 fc ff ff    	je     f0100c4a <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f95:	be 00 04 00 00       	mov    $0x400,%esi
f0100f9a:	e9 15 fd ff ff       	jmp    f0100cb4 <check_page_free_list+0x80>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100f9f:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100fa4:	0f 85 6f ff ff ff    	jne    f0100f19 <check_page_free_list+0x2e5>
f0100faa:	e9 41 ff ff ff       	jmp    f0100ef0 <check_page_free_list+0x2bc>
f0100faf:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100fb4:	0f 85 5a ff ff ff    	jne    f0100f14 <check_page_free_list+0x2e0>
f0100fba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0100fc0:	e9 2b ff ff ff       	jmp    f0100ef0 <check_page_free_list+0x2bc>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100fc5:	83 c4 4c             	add    $0x4c,%esp
f0100fc8:	5b                   	pop    %ebx
f0100fc9:	5e                   	pop    %esi
f0100fca:	5f                   	pop    %edi
f0100fcb:	5d                   	pop    %ebp
f0100fcc:	c3                   	ret    

f0100fcd <page_init>:
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i,j;
	struct PageInfo *tail;
	//Initially setting all pages as used.
		for(i=0;i<npages;i++){
f0100fcd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fd2:	eb 18                	jmp    f0100fec <page_init+0x1f>
		pages[i].pp_ref=1;
f0100fd4:	8b 15 90 ce 22 f0    	mov    0xf022ce90,%edx
f0100fda:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100fdd:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
		pages[i].pp_link=0;
f0100fe3:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i,j;
	struct PageInfo *tail;
	//Initially setting all pages as used.
		for(i=0;i<npages;i++){
f0100fe9:	83 c0 01             	add    $0x1,%eax
f0100fec:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0100ff2:	72 e0                	jb     f0100fd4 <page_init+0x7>
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100ff4:	55                   	push   %ebp
f0100ff5:	89 e5                	mov    %esp,%ebp
f0100ff7:	57                   	push   %edi
f0100ff8:	56                   	push   %esi
f0100ff9:	53                   	push   %ebx
f0100ffa:	83 ec 1c             	sub    $0x1c,%esp
		pages[i].pp_link=0;
	}	

	//Mark Pages 1 to IOPHYSMEM as free
		page_free_list = 0;
	for (i = 1; i < npages_basemem ; ++i) {
f0100ffd:	8b 35 44 c2 22 f0    	mov    0xf022c244,%esi
f0101003:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101008:	b8 01 00 00 00       	mov    $0x1,%eax
f010100d:	eb 39                	jmp    f0101048 <page_init+0x7b>
f010100f:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0101016:	8b 0d 90 ce 22 f0    	mov    0xf022ce90,%ecx
f010101c:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link =0;
f0101023:	c7 04 c1 00 00 00 00 	movl   $0x0,(%ecx,%eax,8)
		if(!page_free_list)
f010102a:	85 db                	test   %ebx,%ebx
f010102c:	75 0a                	jne    f0101038 <page_init+0x6b>
			page_free_list=&pages[i];
f010102e:	89 d3                	mov    %edx,%ebx
f0101030:	03 1d 90 ce 22 f0    	add    0xf022ce90,%ebx
f0101036:	eb 0d                	jmp    f0101045 <page_init+0x78>
		else{
		//cprintf("page: %d and page-1: %d\n",i,i-1); 
		 pages[i-1].pp_link=&pages[i];		
f0101038:	8b 0d 90 ce 22 f0    	mov    0xf022ce90,%ecx
f010103e:	8d 3c 11             	lea    (%ecx,%edx,1),%edi
f0101041:	89 7c 11 f8          	mov    %edi,-0x8(%ecx,%edx,1)
		pages[i].pp_link=0;
	}	

	//Mark Pages 1 to IOPHYSMEM as free
		page_free_list = 0;
	for (i = 1; i < npages_basemem ; ++i) {
f0101045:	83 c0 01             	add    $0x1,%eax
f0101048:	39 f0                	cmp    %esi,%eax
f010104a:	72 c3                	jb     f010100f <page_init+0x42>
f010104c:	89 1d 40 c2 22 f0    	mov    %ebx,0xf022c240
		//cprintf("page: %d and page-1: %d\n",i,i-1); 
		 pages[i-1].pp_link=&pages[i];		
		}
	}
	
	tail=&pages[i-1];
f0101052:	8b 15 90 ce 22 f0    	mov    0xf022ce90,%edx
f0101058:	8d 5c c2 f8          	lea    -0x8(%edx,%eax,8),%ebx
	// Map rest of free memory
	for(j=((ROUNDUP(PADDR(boot_alloc(0)),PGSIZE)/PGSIZE)+1);j<npages;++j){
f010105c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101061:	e8 2e fb ff ff       	call   f0100b94 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101066:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010106b:	77 20                	ja     f010108d <page_init+0xc0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010106d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101071:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0101078:	f0 
f0101079:	c7 44 24 04 55 01 00 	movl   $0x155,0x4(%esp)
f0101080:	00 
f0101081:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101088:	e8 b3 ef ff ff       	call   f0100040 <_panic>
f010108d:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0101092:	c1 e8 0c             	shr    $0xc,%eax
f0101095:	8d 50 01             	lea    0x1(%eax),%edx
f0101098:	c1 e0 03             	shl    $0x3,%eax
f010109b:	eb 29                	jmp    f01010c6 <page_init+0xf9>
		//cprintf(" print j  %d and j-1 %d \n",j,j-1 ); 
		pages[j].pp_ref = 0;
f010109d:	89 c1                	mov    %eax,%ecx
f010109f:	03 0d 90 ce 22 f0    	add    0xf022ce90,%ecx
f01010a5:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[j].pp_link =0;
f01010ab:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		tail->pp_link=&pages[j];
f01010b1:	89 c1                	mov    %eax,%ecx
f01010b3:	03 0d 90 ce 22 f0    	add    0xf022ce90,%ecx
f01010b9:	89 0b                	mov    %ecx,(%ebx)
		tail=&pages[j];
f01010bb:	89 c3                	mov    %eax,%ebx
f01010bd:	03 1d 90 ce 22 f0    	add    0xf022ce90,%ebx
		}
	}
	
	tail=&pages[i-1];
	// Map rest of free memory
	for(j=((ROUNDUP(PADDR(boot_alloc(0)),PGSIZE)/PGSIZE)+1);j<npages;++j){
f01010c3:	83 c2 01             	add    $0x1,%edx
f01010c6:	83 c0 08             	add    $0x8,%eax
f01010c9:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f01010cf:	72 cc                	jb     f010109d <page_init+0xd0>
		pages[j].pp_link =0;
		tail->pp_link=&pages[j];
		tail=&pages[j];
	}
	//setting phsyical page coressponding to MPENTRY_PADDR in use	
		pages[PGNUM(MPENTRY_PADDR)].pp_ref= 1;
f01010d1:	a1 90 ce 22 f0       	mov    0xf022ce90,%eax
f01010d6:	66 c7 40 3c 01 00    	movw   $0x1,0x3c(%eax)
		pages[PGNUM(MPENTRY_PADDR)].pp_link= 0;
f01010dc:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
		pages[PGNUM(MPENTRY_PADDR)-1].pp_link= &pages[PGNUM(MPENTRY_PADDR)+1];
f01010e3:	8d 50 40             	lea    0x40(%eax),%edx
f01010e6:	89 50 30             	mov    %edx,0x30(%eax)
	
		
}
f01010e9:	83 c4 1c             	add    $0x1c,%esp
f01010ec:	5b                   	pop    %ebx
f01010ed:	5e                   	pop    %esi
f01010ee:	5f                   	pop    %edi
f01010ef:	5d                   	pop    %ebp
f01010f0:	c3                   	ret    

f01010f1 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{		// Fill this function in
f01010f1:	55                   	push   %ebp
f01010f2:	89 e5                	mov    %esp,%ebp
f01010f4:	53                   	push   %ebx
f01010f5:	83 ec 14             	sub    $0x14,%esp

	struct PageInfo *ppt=page_free_list;
f01010f8:	8b 1d 40 c2 22 f0    	mov    0xf022c240,%ebx
	if (ppt ==0){
f01010fe:	85 db                	test   %ebx,%ebx
f0101100:	74 6f                	je     f0101171 <page_alloc+0x80>
	//cprintf(" page_alloc returning null\n");
		return NULL;
	}
	page_free_list=ppt->pp_link;	
f0101102:	8b 03                	mov    (%ebx),%eax
f0101104:	a3 40 c2 22 f0       	mov    %eax,0xf022c240
	ppt->pp_link=NULL;
f0101109:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO){
		memset(page2kva(ppt),'\0',PGSIZE);
	}
	return ppt;
f010110f:	89 d8                	mov    %ebx,%eax
	//cprintf(" page_alloc returning null\n");
		return NULL;
	}
	page_free_list=ppt->pp_link;	
	ppt->pp_link=NULL;
	if(alloc_flags & ALLOC_ZERO){
f0101111:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101115:	74 5f                	je     f0101176 <page_alloc+0x85>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101117:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f010111d:	c1 f8 03             	sar    $0x3,%eax
f0101120:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101123:	89 c2                	mov    %eax,%edx
f0101125:	c1 ea 0c             	shr    $0xc,%edx
f0101128:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f010112e:	72 20                	jb     f0101150 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101130:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101134:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f010113b:	f0 
f010113c:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101143:	00 
f0101144:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f010114b:	e8 f0 ee ff ff       	call   f0100040 <_panic>
		memset(page2kva(ppt),'\0',PGSIZE);
f0101150:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101157:	00 
f0101158:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010115f:	00 
	return (void *)(pa + KERNBASE);
f0101160:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101165:	89 04 24             	mov    %eax,(%esp)
f0101168:	e8 ba 4a 00 00       	call   f0105c27 <memset>
	}
	return ppt;
f010116d:	89 d8                	mov    %ebx,%eax
f010116f:	eb 05                	jmp    f0101176 <page_alloc+0x85>
{		// Fill this function in

	struct PageInfo *ppt=page_free_list;
	if (ppt ==0){
	//cprintf(" page_alloc returning null\n");
		return NULL;
f0101171:	b8 00 00 00 00       	mov    $0x0,%eax
	ppt->pp_link=NULL;
	if(alloc_flags & ALLOC_ZERO){
		memset(page2kva(ppt),'\0',PGSIZE);
	}
	return ppt;
}
f0101176:	83 c4 14             	add    $0x14,%esp
f0101179:	5b                   	pop    %ebx
f010117a:	5d                   	pop    %ebp
f010117b:	c3                   	ret    

f010117c <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010117c:	55                   	push   %ebp
f010117d:	89 e5                	mov    %esp,%ebp
f010117f:	83 ec 18             	sub    $0x18,%esp
f0101182:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill in this function 
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	//cprintf("pp ref:%d and pp link: %x \n",pp->pp_ref,pp->pp_link);
	if (pp->pp_ref !=0){
f0101185:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010118a:	74 1c                	je     f01011a8 <page_free+0x2c>
		panic("page your trying to free is already allocated");
f010118c:	c7 44 24 08 e8 6f 10 	movl   $0xf0106fe8,0x8(%esp)
f0101193:	f0 
f0101194:	c7 44 24 04 8d 01 00 	movl   $0x18d,0x4(%esp)
f010119b:	00 
f010119c:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01011a3:	e8 98 ee ff ff       	call   f0100040 <_panic>
		return;
	}	
	else{
                //cprintf("print value of page_free_list :%x \n",pp->pp_link );	
		pp->pp_link = page_free_list;
f01011a8:	8b 15 40 c2 22 f0    	mov    0xf022c240,%edx
f01011ae:	89 10                	mov    %edx,(%eax)
		page_free_list=pp;	
f01011b0:	a3 40 c2 22 f0       	mov    %eax,0xf022c240

	}
	
}
f01011b5:	c9                   	leave  
f01011b6:	c3                   	ret    

f01011b7 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01011b7:	55                   	push   %ebp
f01011b8:	89 e5                	mov    %esp,%ebp
f01011ba:	83 ec 18             	sub    $0x18,%esp
f01011bd:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01011c0:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f01011c4:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01011c7:	66 89 50 04          	mov    %dx,0x4(%eax)
f01011cb:	66 85 d2             	test   %dx,%dx
f01011ce:	75 08                	jne    f01011d8 <page_decref+0x21>
		page_free(pp);
f01011d0:	89 04 24             	mov    %eax,(%esp)
f01011d3:	e8 a4 ff ff ff       	call   f010117c <page_free>
}
f01011d8:	c9                   	leave  
f01011d9:	c3                   	ret    

f01011da <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01011da:	55                   	push   %ebp
f01011db:	89 e5                	mov    %esp,%ebp
f01011dd:	57                   	push   %edi
f01011de:	56                   	push   %esi
f01011df:	53                   	push   %ebx
f01011e0:	83 ec 1c             	sub    $0x1c,%esp
f01011e3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pde_t *pde; //va(virtual address) point to pa(physical address)
	  pte_t *pgtable; //same as pde
	  struct PageInfo *pp;

	  pde = &pgdir[PDX(va)]; // va->pgdir
f01011e6:	89 de                	mov    %ebx,%esi
f01011e8:	c1 ee 16             	shr    $0x16,%esi
f01011eb:	c1 e6 02             	shl    $0x2,%esi
f01011ee:	03 75 08             	add    0x8(%ebp),%esi
	  if(*pde & PTE_P) { 
f01011f1:	8b 06                	mov    (%esi),%eax
f01011f3:	a8 01                	test   $0x1,%al
f01011f5:	74 3d                	je     f0101234 <pgdir_walk+0x5a>
	  	pgtable = (KADDR(PTE_ADDR(*pde)));
f01011f7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011fc:	89 c2                	mov    %eax,%edx
f01011fe:	c1 ea 0c             	shr    $0xc,%edx
f0101201:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0101207:	72 20                	jb     f0101229 <pgdir_walk+0x4f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101209:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010120d:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0101214:	f0 
f0101215:	c7 44 24 04 c3 01 00 	movl   $0x1c3,0x4(%esp)
f010121c:	00 
f010121d:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101224:	e8 17 ee ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101229:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f010122f:	e9 97 00 00 00       	jmp    f01012cb <pgdir_walk+0xf1>
	  } else {
		//page table page not exist
		if(!create || 
f0101234:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101238:	0f 84 9b 00 00 00    	je     f01012d9 <pgdir_walk+0xff>
f010123e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101245:	e8 a7 fe ff ff       	call   f01010f1 <page_alloc>
f010124a:	85 c0                	test   %eax,%eax
f010124c:	0f 84 8e 00 00 00    	je     f01012e0 <pgdir_walk+0x106>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101252:	89 c1                	mov    %eax,%ecx
f0101254:	2b 0d 90 ce 22 f0    	sub    0xf022ce90,%ecx
f010125a:	c1 f9 03             	sar    $0x3,%ecx
f010125d:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101260:	89 ca                	mov    %ecx,%edx
f0101262:	c1 ea 0c             	shr    $0xc,%edx
f0101265:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f010126b:	72 20                	jb     f010128d <pgdir_walk+0xb3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010126d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0101271:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0101278:	f0 
f0101279:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101280:	00 
f0101281:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f0101288:	e8 b3 ed ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010128d:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f0101293:	89 fa                	mov    %edi,%edx
		   !(pp = page_alloc(ALLOC_ZERO)) ||
f0101295:	85 ff                	test   %edi,%edi
f0101297:	74 4e                	je     f01012e7 <pgdir_walk+0x10d>
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
		    
		pp->pp_ref++;
f0101299:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010129e:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f01012a4:	77 20                	ja     f01012c6 <pgdir_walk+0xec>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01012a6:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01012aa:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f01012b1:	f0 
f01012b2:	c7 44 24 04 cc 01 00 	movl   $0x1cc,0x4(%esp)
f01012b9:	00 
f01012ba:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01012c1:	e8 7a ed ff ff       	call   f0100040 <_panic>
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
f01012c6:	83 c9 07             	or     $0x7,%ecx
f01012c9:	89 0e                	mov    %ecx,(%esi)
	}
	return &pgtable[PTX(va)];
f01012cb:	c1 eb 0a             	shr    $0xa,%ebx
f01012ce:	89 d8                	mov    %ebx,%eax
f01012d0:	25 fc 0f 00 00       	and    $0xffc,%eax
f01012d5:	01 d0                	add    %edx,%eax
f01012d7:	eb 13                	jmp    f01012ec <pgdir_walk+0x112>
	  } else {
		//page table page not exist
		if(!create || 
		   !(pp = page_alloc(ALLOC_ZERO)) ||
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
f01012d9:	b8 00 00 00 00       	mov    $0x0,%eax
f01012de:	eb 0c                	jmp    f01012ec <pgdir_walk+0x112>
f01012e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01012e5:	eb 05                	jmp    f01012ec <pgdir_walk+0x112>
f01012e7:	b8 00 00 00 00       	mov    $0x0,%eax
		    
		pp->pp_ref++;
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
	}
	return &pgtable[PTX(va)];
}
f01012ec:	83 c4 1c             	add    $0x1c,%esp
f01012ef:	5b                   	pop    %ebx
f01012f0:	5e                   	pop    %esi
f01012f1:	5f                   	pop    %edi
f01012f2:	5d                   	pop    %ebp
f01012f3:	c3                   	ret    

f01012f4 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01012f4:	55                   	push   %ebp
f01012f5:	89 e5                	mov    %esp,%ebp
f01012f7:	57                   	push   %edi
f01012f8:	56                   	push   %esi
f01012f9:	53                   	push   %ebx
f01012fa:	83 ec 2c             	sub    $0x2c,%esp
f01012fd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101300:	89 ce                	mov    %ecx,%esi
f0101302:	89 d3                	mov    %edx,%ebx
f0101304:	8b 45 08             	mov    0x8(%ebp),%eax
f0101307:	29 d0                	sub    %edx,%eax
f0101309:	89 45 e0             	mov    %eax,-0x20(%ebp)
	
	while(1){
	if( (pte=pgdir_walk(pgdir,(void *)va, 1))==NULL )
		panic("Cannot allocate page for mapping,System out of memory");
	// map virtual to physical addr	
	*pte=pa|perm|PTE_P;
f010130c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010130f:	83 c8 01             	or     $0x1,%eax
f0101312:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101315:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101318:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
{
	// Fill this function in
	pte_t *pte;	
	
	while(1){
	if( (pte=pgdir_walk(pgdir,(void *)va, 1))==NULL )
f010131b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101322:	00 
f0101323:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101327:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010132a:	89 04 24             	mov    %eax,(%esp)
f010132d:	e8 a8 fe ff ff       	call   f01011da <pgdir_walk>
f0101332:	85 c0                	test   %eax,%eax
f0101334:	75 1c                	jne    f0101352 <boot_map_region+0x5e>
		panic("Cannot allocate page for mapping,System out of memory");
f0101336:	c7 44 24 08 18 70 10 	movl   $0xf0107018,0x8(%esp)
f010133d:	f0 
f010133e:	c7 44 24 04 e4 01 00 	movl   $0x1e4,0x4(%esp)
f0101345:	00 
f0101346:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010134d:	e8 ee ec ff ff       	call   f0100040 <_panic>
	// map virtual to physical addr	
	*pte=pa|perm|PTE_P;
f0101352:	0b 7d dc             	or     -0x24(%ebp),%edi
f0101355:	89 38                	mov    %edi,(%eax)
		
	if (size<=PGSIZE)
f0101357:	81 fe 00 10 00 00    	cmp    $0x1000,%esi
f010135d:	76 0e                	jbe    f010136d <boot_map_region+0x79>
		break;
	//increment counters to map all the way till va+size		
	va +=PGSIZE;		
f010135f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	pa +=PGSIZE;	
	size -=PGSIZE;
f0101365:	81 ee 00 10 00 00    	sub    $0x1000,%esi
	}
f010136b:	eb a8                	jmp    f0101315 <boot_map_region+0x21>

}
f010136d:	83 c4 2c             	add    $0x2c,%esp
f0101370:	5b                   	pop    %ebx
f0101371:	5e                   	pop    %esi
f0101372:	5f                   	pop    %edi
f0101373:	5d                   	pop    %ebp
f0101374:	c3                   	ret    

f0101375 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{      // Fill this function in
f0101375:	55                   	push   %ebp
f0101376:	89 e5                	mov    %esp,%ebp
f0101378:	53                   	push   %ebx
f0101379:	83 ec 14             	sub    $0x14,%esp
f010137c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte_entry;

	pte_entry = pgdir_walk(pgdir, va, 0);
f010137f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101386:	00 
f0101387:	8b 45 0c             	mov    0xc(%ebp),%eax
f010138a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010138e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101391:	89 04 24             	mov    %eax,(%esp)
f0101394:	e8 41 fe ff ff       	call   f01011da <pgdir_walk>
	if (pte_entry == NULL)
f0101399:	85 c0                	test   %eax,%eax
f010139b:	74 3f                	je     f01013dc <page_lookup+0x67>
		return NULL;
	if (*pte_entry == 0)
f010139d:	83 38 00             	cmpl   $0x0,(%eax)
f01013a0:	74 41                	je     f01013e3 <page_lookup+0x6e>
		return NULL;

	if (pte_store != NULL)
f01013a2:	85 db                	test   %ebx,%ebx
f01013a4:	74 02                	je     f01013a8 <page_lookup+0x33>
		*pte_store = pte_entry;
f01013a6:	89 03                	mov    %eax,(%ebx)

	return pa2page(PTE_ADDR(*pte_entry));	
f01013a8:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013aa:	c1 e8 0c             	shr    $0xc,%eax
f01013ad:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f01013b3:	72 1c                	jb     f01013d1 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f01013b5:	c7 44 24 08 50 70 10 	movl   $0xf0107050,0x8(%esp)
f01013bc:	f0 
f01013bd:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f01013c4:	00 
f01013c5:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f01013cc:	e8 6f ec ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01013d1:	8b 15 90 ce 22 f0    	mov    0xf022ce90,%edx
f01013d7:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01013da:	eb 0c                	jmp    f01013e8 <page_lookup+0x73>
{      // Fill this function in
	pte_t *pte_entry;

	pte_entry = pgdir_walk(pgdir, va, 0);
	if (pte_entry == NULL)
		return NULL;
f01013dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01013e1:	eb 05                	jmp    f01013e8 <page_lookup+0x73>
	if (*pte_entry == 0)
		return NULL;
f01013e3:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store=pgtab;	

	return pa2page(PTE_ADDR(*pgtab));
*/
}
f01013e8:	83 c4 14             	add    $0x14,%esp
f01013eb:	5b                   	pop    %ebx
f01013ec:	5d                   	pop    %ebp
f01013ed:	c3                   	ret    

f01013ee <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01013ee:	55                   	push   %ebp
f01013ef:	89 e5                	mov    %esp,%ebp
f01013f1:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f01013f4:	e8 80 4e 00 00       	call   f0106279 <cpunum>
f01013f9:	6b c0 74             	imul   $0x74,%eax,%eax
f01013fc:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f0101403:	74 16                	je     f010141b <tlb_invalidate+0x2d>
f0101405:	e8 6f 4e 00 00       	call   f0106279 <cpunum>
f010140a:	6b c0 74             	imul   $0x74,%eax,%eax
f010140d:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0101413:	8b 55 08             	mov    0x8(%ebp),%edx
f0101416:	39 50 60             	cmp    %edx,0x60(%eax)
f0101419:	75 06                	jne    f0101421 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010141b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010141e:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101421:	c9                   	leave  
f0101422:	c3                   	ret    

f0101423 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{	
f0101423:	55                   	push   %ebp
f0101424:	89 e5                	mov    %esp,%ebp
f0101426:	56                   	push   %esi
f0101427:	53                   	push   %ebx
f0101428:	83 ec 20             	sub    $0x20,%esp
f010142b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010142e:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	struct PageInfo *pg;
	pte_t *pte;
	pte_t **pte_store=&pte;

	pg=page_lookup(pgdir,va,pte_store);
f0101431:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101434:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101438:	89 74 24 04          	mov    %esi,0x4(%esp)
f010143c:	89 1c 24             	mov    %ebx,(%esp)
f010143f:	e8 31 ff ff ff       	call   f0101375 <page_lookup>
// If there is no physical page at that address, silently does nothing.
	if (!pg)
f0101444:	85 c0                	test   %eax,%eax
f0101446:	75 0e                	jne    f0101456 <page_remove+0x33>
	{cprintf("page not found \n");
f0101448:	c7 04 24 c4 79 10 f0 	movl   $0xf01079c4,(%esp)
f010144f:	e8 62 2c 00 00       	call   f01040b6 <cprintf>
f0101454:	eb 1d                	jmp    f0101473 <page_remove+0x50>
		return;}

//   - The ref count on the physical page should decrement.
//   - The physical page should be freed if the refcount reaches 0.
	
	page_decref(pg);
f0101456:	89 04 24             	mov    %eax,(%esp)
f0101459:	e8 59 fd ff ff       	call   f01011b7 <page_decref>
	//cprintf("page ref after decrement : %d \n",pg->pp_ref);
//- The pg table entry corresponding to 'va' should be set to 0.
//     (if such a PTE exists)
	if(pte_store){
		**pte_store=0;
f010145e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101461:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
//   - The TLB must be invalidated if you remove an entry from
//     the page table.
	tlb_invalidate(pgdir,va);	
f0101467:	89 74 24 04          	mov    %esi,0x4(%esp)
f010146b:	89 1c 24             	mov    %ebx,(%esp)
f010146e:	e8 7b ff ff ff       	call   f01013ee <tlb_invalidate>
	}
}
f0101473:	83 c4 20             	add    $0x20,%esp
f0101476:	5b                   	pop    %ebx
f0101477:	5e                   	pop    %esi
f0101478:	5d                   	pop    %ebp
f0101479:	c3                   	ret    

f010147a <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{/*	// Fill this function in
f010147a:	55                   	push   %ebp
f010147b:	89 e5                	mov    %esp,%ebp
f010147d:	57                   	push   %edi
f010147e:	56                   	push   %esi
f010147f:	53                   	push   %ebx
f0101480:	83 ec 1c             	sub    $0x1c,%esp
f0101483:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101486:	8b 7d 10             	mov    0x10(%ebp),%edi
//set permission of page_table_entry and increment pp->ref count
	*pte=pa |perm| PTE_P ;
	 pp->pp_ref++;
	return 0;
*/
    pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101489:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101490:	00 
f0101491:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101495:	8b 45 08             	mov    0x8(%ebp),%eax
f0101498:	89 04 24             	mov    %eax,(%esp)
f010149b:	e8 3a fd ff ff       	call   f01011da <pgdir_walk>
f01014a0:	89 c6                	mov    %eax,%esi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014a2:	8b 15 90 ce 22 f0    	mov    0xf022ce90,%edx
    physaddr_t ppa = page2pa(pp);

    if (pte != NULL) {
f01014a8:	85 c0                	test   %eax,%eax
f01014aa:	74 4d                	je     f01014f9 <page_insert+0x7f>
        // for page alreay mapped
        if (*pte & PTE_P){
f01014ac:	8b 00                	mov    (%eax),%eax
f01014ae:	a8 01                	test   $0x1,%al
f01014b0:	74 35                	je     f01014e7 <page_insert+0x6d>
		if(PTE_ADDR(*pte)==ppa){
f01014b2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01014b7:	89 d9                	mov    %ebx,%ecx
f01014b9:	29 d1                	sub    %edx,%ecx
f01014bb:	89 ca                	mov    %ecx,%edx
f01014bd:	c1 fa 03             	sar    $0x3,%edx
f01014c0:	c1 e2 0c             	shl    $0xc,%edx
f01014c3:	39 d0                	cmp    %edx,%eax
f01014c5:	75 11                	jne    f01014d8 <page_insert+0x5e>
			*pte=ppa|perm|PTE_P;
f01014c7:	8b 55 14             	mov    0x14(%ebp),%edx
f01014ca:	83 ca 01             	or     $0x1,%edx
f01014cd:	09 d0                	or     %edx,%eax
f01014cf:	89 06                	mov    %eax,(%esi)
			return 0;
f01014d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01014d6:	eb 76                	jmp    f010154e <page_insert+0xd4>
		}
            page_remove(pgdir, va); // also invalidates tlb
f01014d8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01014dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01014df:	89 04 24             	mov    %eax,(%esp)
f01014e2:	e8 3c ff ff ff       	call   f0101423 <page_remove>
	}
        if (page_free_list == pp) 
f01014e7:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f01014ec:	39 d8                	cmp    %ebx,%eax
f01014ee:	75 26                	jne    f0101516 <page_insert+0x9c>
            page_free_list = page_free_list->pp_link; 
f01014f0:	8b 00                	mov    (%eax),%eax
f01014f2:	a3 40 c2 22 f0       	mov    %eax,0xf022c240
f01014f7:	eb 1d                	jmp    f0101516 <page_insert+0x9c>
		
	} else {
	    pte = pgdir_walk(pgdir, va, 1);
f01014f9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101500:	00 
f0101501:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101505:	8b 45 08             	mov    0x8(%ebp),%eax
f0101508:	89 04 24             	mov    %eax,(%esp)
f010150b:	e8 ca fc ff ff       	call   f01011da <pgdir_walk>
f0101510:	89 c6                	mov    %eax,%esi
	    if (!pte)
f0101512:	85 c0                	test   %eax,%eax
f0101514:	74 33                	je     f0101549 <page_insert+0xcf>
		    return -E_NO_MEM;
    	    
	}
	*pte = page2pa(pp) | perm | PTE_P;
f0101516:	8b 55 14             	mov    0x14(%ebp),%edx
f0101519:	83 ca 01             	or     $0x1,%edx
f010151c:	89 d8                	mov    %ebx,%eax
f010151e:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0101524:	c1 f8 03             	sar    $0x3,%eax
f0101527:	c1 e0 0c             	shl    $0xc,%eax
f010152a:	09 d0                	or     %edx,%eax
f010152c:	89 06                	mov    %eax,(%esi)
	pp->pp_ref++;
f010152e:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	//cprintf("ref variable count: %d \n",pp->pp_ref);
    	tlb_invalidate(pgdir, va);
f0101533:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101537:	8b 45 08             	mov    0x8(%ebp),%eax
f010153a:	89 04 24             	mov    %eax,(%esp)
f010153d:	e8 ac fe ff ff       	call   f01013ee <tlb_invalidate>
	return 0;
f0101542:	b8 00 00 00 00       	mov    $0x0,%eax
f0101547:	eb 05                	jmp    f010154e <page_insert+0xd4>
            page_free_list = page_free_list->pp_link; 
		
	} else {
	    pte = pgdir_walk(pgdir, va, 1);
	    if (!pte)
		    return -E_NO_MEM;
f0101549:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*pte = page2pa(pp) | perm | PTE_P;
	pp->pp_ref++;
	//cprintf("ref variable count: %d \n",pp->pp_ref);
    	tlb_invalidate(pgdir, va);
	return 0;
}
f010154e:	83 c4 1c             	add    $0x1c,%esp
f0101551:	5b                   	pop    %ebx
f0101552:	5e                   	pop    %esi
f0101553:	5f                   	pop    %edi
f0101554:	5d                   	pop    %ebp
f0101555:	c3                   	ret    

f0101556 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0101556:	55                   	push   %ebp
f0101557:	89 e5                	mov    %esp,%ebp
f0101559:	56                   	push   %esi
f010155a:	53                   	push   %ebx
f010155b:	83 ec 10             	sub    $0x10,%esp
f010155e:	8b 45 0c             	mov    0xc(%ebp),%eax
	// Where to start the next region.  Initially, this is the
	// beginning of the MMIO region.  Because this is static, its
	// value will be preserved between calls to mmio_map_region
	// (just like nextfree in boot_alloc).
	static uintptr_t base = MMIOBASE;
	       uintptr_t reserve = base; 
f0101561:	8b 1d 00 13 12 f0    	mov    0xf0121300,%ebx
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	//panic("mmio_map_region not implemented");
	size_t sz = ROUNDUP( size , PGSIZE);
f0101567:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
f010156d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if ( ( base + size ) > MMIOLIM)
f0101573:	01 d8                	add    %ebx,%eax
f0101575:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f010157a:	76 1c                	jbe    f0101598 <mmio_map_region+0x42>
		panic(" kern/pmap.c -> mmio_map_region : mmio reservation overflows limit mmiolim \n");
f010157c:	c7 44 24 08 70 70 10 	movl   $0xf0107070,0x8(%esp)
f0101583:	f0 
f0101584:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f010158b:	00 
f010158c:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101593:	e8 a8 ea ff ff       	call   f0100040 <_panic>
	
	boot_map_region(kern_pgdir, base, sz, pa, PTE_PCD|PTE_PWT|PTE_W);
f0101598:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
f010159f:	00 
f01015a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01015a3:	89 04 24             	mov    %eax,(%esp)
f01015a6:	89 f1                	mov    %esi,%ecx
f01015a8:	89 da                	mov    %ebx,%edx
f01015aa:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01015af:	e8 40 fd ff ff       	call   f01012f4 <boot_map_region>
	base += sz ; 
f01015b4:	01 35 00 13 12 f0    	add    %esi,0xf0121300
	return (void*)reserve;	
	
}
f01015ba:	89 d8                	mov    %ebx,%eax
f01015bc:	83 c4 10             	add    $0x10,%esp
f01015bf:	5b                   	pop    %ebx
f01015c0:	5e                   	pop    %esi
f01015c1:	5d                   	pop    %ebp
f01015c2:	c3                   	ret    

f01015c3 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01015c3:	55                   	push   %ebp
f01015c4:	89 e5                	mov    %esp,%ebp
f01015c6:	57                   	push   %edi
f01015c7:	56                   	push   %esi
f01015c8:	53                   	push   %ebx
f01015c9:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01015cc:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f01015d3:	e8 75 29 00 00       	call   f0103f4d <mc146818_read>
f01015d8:	89 c3                	mov    %eax,%ebx
f01015da:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01015e1:	e8 67 29 00 00       	call   f0103f4d <mc146818_read>
f01015e6:	c1 e0 08             	shl    $0x8,%eax
f01015e9:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01015eb:	89 d8                	mov    %ebx,%eax
f01015ed:	c1 e0 0a             	shl    $0xa,%eax
f01015f0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01015f6:	85 c0                	test   %eax,%eax
f01015f8:	0f 48 c2             	cmovs  %edx,%eax
f01015fb:	c1 f8 0c             	sar    $0xc,%eax
f01015fe:	a3 44 c2 22 f0       	mov    %eax,0xf022c244
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101603:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010160a:	e8 3e 29 00 00       	call   f0103f4d <mc146818_read>
f010160f:	89 c3                	mov    %eax,%ebx
f0101611:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101618:	e8 30 29 00 00       	call   f0103f4d <mc146818_read>
f010161d:	c1 e0 08             	shl    $0x8,%eax
f0101620:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101622:	89 d8                	mov    %ebx,%eax
f0101624:	c1 e0 0a             	shl    $0xa,%eax
f0101627:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010162d:	85 c0                	test   %eax,%eax
f010162f:	0f 48 c2             	cmovs  %edx,%eax
f0101632:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101635:	85 c0                	test   %eax,%eax
f0101637:	74 0e                	je     f0101647 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101639:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010163f:	89 15 88 ce 22 f0    	mov    %edx,0xf022ce88
f0101645:	eb 0c                	jmp    f0101653 <mem_init+0x90>
	else
		npages = npages_basemem;
f0101647:	8b 15 44 c2 22 f0    	mov    0xf022c244,%edx
f010164d:	89 15 88 ce 22 f0    	mov    %edx,0xf022ce88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101653:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101656:	c1 e8 0a             	shr    $0xa,%eax
f0101659:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010165d:	a1 44 c2 22 f0       	mov    0xf022c244,%eax
f0101662:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101665:	c1 e8 0a             	shr    $0xa,%eax
f0101668:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010166c:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f0101671:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101674:	c1 e8 0a             	shr    $0xa,%eax
f0101677:	89 44 24 04          	mov    %eax,0x4(%esp)
f010167b:	c7 04 24 c0 70 10 f0 	movl   $0xf01070c0,(%esp)
f0101682:	e8 2f 2a 00 00       	call   f01040b6 <cprintf>
	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
	
	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101687:	b8 00 10 00 00       	mov    $0x1000,%eax
f010168c:	e8 03 f5 ff ff       	call   f0100b94 <boot_alloc>
f0101691:	a3 8c ce 22 f0       	mov    %eax,0xf022ce8c
	memset(kern_pgdir, 0, PGSIZE);
f0101696:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010169d:	00 
f010169e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01016a5:	00 
f01016a6:	89 04 24             	mov    %eax,(%esp)
f01016a9:	e8 79 45 00 00       	call   f0105c27 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01016ae:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01016b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01016b8:	77 20                	ja     f01016da <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01016ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016be:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f01016c5:	f0 
f01016c6:	c7 44 24 04 95 00 00 	movl   $0x95,0x4(%esp)
f01016cd:	00 
f01016ce:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01016d5:	e8 66 e9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01016da:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01016e0:	83 ca 05             	or     $0x5,%edx
f01016e3:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(sizeof(struct PageInfo)*npages);
f01016e9:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f01016ee:	c1 e0 03             	shl    $0x3,%eax
f01016f1:	e8 9e f4 ff ff       	call   f0100b94 <boot_alloc>
f01016f6:	a3 90 ce 22 f0       	mov    %eax,0xf022ce90
	memset(pages, 0, npages*sizeof(struct PageInfo));
f01016fb:	8b 0d 88 ce 22 f0    	mov    0xf022ce88,%ecx
f0101701:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101708:	89 54 24 08          	mov    %edx,0x8(%esp)
f010170c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101713:	00 
f0101714:	89 04 24             	mov    %eax,(%esp)
f0101717:	e8 0b 45 00 00       	call   f0105c27 <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f010171c:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101721:	e8 6e f4 ff ff       	call   f0100b94 <boot_alloc>
f0101726:	a3 48 c2 22 f0       	mov    %eax,0xf022c248
	memset(envs,0,NENV*sizeof(struct Env));
f010172b:	c7 44 24 08 00 f0 01 	movl   $0x1f000,0x8(%esp)
f0101732:	00 
f0101733:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010173a:	00 
f010173b:	89 04 24             	mov    %eax,(%esp)
f010173e:	e8 e4 44 00 00       	call   f0105c27 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101743:	e8 85 f8 ff ff       	call   f0100fcd <page_init>

	check_page_free_list(1);
f0101748:	b8 01 00 00 00       	mov    $0x1,%eax
f010174d:	e8 e2 f4 ff ff       	call   f0100c34 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101752:	83 3d 90 ce 22 f0 00 	cmpl   $0x0,0xf022ce90
f0101759:	75 1c                	jne    f0101777 <mem_init+0x1b4>
		panic("'pages' is a null pointer!");
f010175b:	c7 44 24 08 d5 79 10 	movl   $0xf01079d5,0x8(%esp)
f0101762:	f0 
f0101763:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f010176a:	00 
f010176b:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101772:	e8 c9 e8 ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101777:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f010177c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101781:	eb 05                	jmp    f0101788 <mem_init+0x1c5>
		++nfree;
f0101783:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101786:	8b 00                	mov    (%eax),%eax
f0101788:	85 c0                	test   %eax,%eax
f010178a:	75 f7                	jne    f0101783 <mem_init+0x1c0>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010178c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101793:	e8 59 f9 ff ff       	call   f01010f1 <page_alloc>
f0101798:	89 c7                	mov    %eax,%edi
f010179a:	85 c0                	test   %eax,%eax
f010179c:	75 24                	jne    f01017c2 <mem_init+0x1ff>
f010179e:	c7 44 24 0c f0 79 10 	movl   $0xf01079f0,0xc(%esp)
f01017a5:	f0 
f01017a6:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01017ad:	f0 
f01017ae:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f01017b5:	00 
f01017b6:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01017bd:	e8 7e e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017c2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017c9:	e8 23 f9 ff ff       	call   f01010f1 <page_alloc>
f01017ce:	89 c6                	mov    %eax,%esi
f01017d0:	85 c0                	test   %eax,%eax
f01017d2:	75 24                	jne    f01017f8 <mem_init+0x235>
f01017d4:	c7 44 24 0c 06 7a 10 	movl   $0xf0107a06,0xc(%esp)
f01017db:	f0 
f01017dc:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01017e3:	f0 
f01017e4:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f01017eb:	00 
f01017ec:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01017f3:	e8 48 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01017f8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017ff:	e8 ed f8 ff ff       	call   f01010f1 <page_alloc>
f0101804:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101807:	85 c0                	test   %eax,%eax
f0101809:	75 24                	jne    f010182f <mem_init+0x26c>
f010180b:	c7 44 24 0c 1c 7a 10 	movl   $0xf0107a1c,0xc(%esp)
f0101812:	f0 
f0101813:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010181a:	f0 
f010181b:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f0101822:	00 
f0101823:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010182a:	e8 11 e8 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010182f:	39 f7                	cmp    %esi,%edi
f0101831:	75 24                	jne    f0101857 <mem_init+0x294>
f0101833:	c7 44 24 0c 32 7a 10 	movl   $0xf0107a32,0xc(%esp)
f010183a:	f0 
f010183b:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101842:	f0 
f0101843:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f010184a:	00 
f010184b:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101852:	e8 e9 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101857:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010185a:	39 c6                	cmp    %eax,%esi
f010185c:	74 04                	je     f0101862 <mem_init+0x29f>
f010185e:	39 c7                	cmp    %eax,%edi
f0101860:	75 24                	jne    f0101886 <mem_init+0x2c3>
f0101862:	c7 44 24 0c fc 70 10 	movl   $0xf01070fc,0xc(%esp)
f0101869:	f0 
f010186a:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101871:	f0 
f0101872:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0101879:	00 
f010187a:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101881:	e8 ba e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101886:	8b 15 90 ce 22 f0    	mov    0xf022ce90,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010188c:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f0101891:	c1 e0 0c             	shl    $0xc,%eax
f0101894:	89 f9                	mov    %edi,%ecx
f0101896:	29 d1                	sub    %edx,%ecx
f0101898:	c1 f9 03             	sar    $0x3,%ecx
f010189b:	c1 e1 0c             	shl    $0xc,%ecx
f010189e:	39 c1                	cmp    %eax,%ecx
f01018a0:	72 24                	jb     f01018c6 <mem_init+0x303>
f01018a2:	c7 44 24 0c 44 7a 10 	movl   $0xf0107a44,0xc(%esp)
f01018a9:	f0 
f01018aa:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01018b1:	f0 
f01018b2:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f01018b9:	00 
f01018ba:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01018c1:	e8 7a e7 ff ff       	call   f0100040 <_panic>
f01018c6:	89 f1                	mov    %esi,%ecx
f01018c8:	29 d1                	sub    %edx,%ecx
f01018ca:	c1 f9 03             	sar    $0x3,%ecx
f01018cd:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01018d0:	39 c8                	cmp    %ecx,%eax
f01018d2:	77 24                	ja     f01018f8 <mem_init+0x335>
f01018d4:	c7 44 24 0c 61 7a 10 	movl   $0xf0107a61,0xc(%esp)
f01018db:	f0 
f01018dc:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01018e3:	f0 
f01018e4:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f01018eb:	00 
f01018ec:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01018f3:	e8 48 e7 ff ff       	call   f0100040 <_panic>
f01018f8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01018fb:	29 d1                	sub    %edx,%ecx
f01018fd:	89 ca                	mov    %ecx,%edx
f01018ff:	c1 fa 03             	sar    $0x3,%edx
f0101902:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101905:	39 d0                	cmp    %edx,%eax
f0101907:	77 24                	ja     f010192d <mem_init+0x36a>
f0101909:	c7 44 24 0c 7e 7a 10 	movl   $0xf0107a7e,0xc(%esp)
f0101910:	f0 
f0101911:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101918:	f0 
f0101919:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0101920:	00 
f0101921:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101928:	e8 13 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010192d:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f0101932:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101935:	c7 05 40 c2 22 f0 00 	movl   $0x0,0xf022c240
f010193c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010193f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101946:	e8 a6 f7 ff ff       	call   f01010f1 <page_alloc>
f010194b:	85 c0                	test   %eax,%eax
f010194d:	74 24                	je     f0101973 <mem_init+0x3b0>
f010194f:	c7 44 24 0c 9b 7a 10 	movl   $0xf0107a9b,0xc(%esp)
f0101956:	f0 
f0101957:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010195e:	f0 
f010195f:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f0101966:	00 
f0101967:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010196e:	e8 cd e6 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101973:	89 3c 24             	mov    %edi,(%esp)
f0101976:	e8 01 f8 ff ff       	call   f010117c <page_free>
	page_free(pp1);
f010197b:	89 34 24             	mov    %esi,(%esp)
f010197e:	e8 f9 f7 ff ff       	call   f010117c <page_free>
	page_free(pp2);
f0101983:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101986:	89 04 24             	mov    %eax,(%esp)
f0101989:	e8 ee f7 ff ff       	call   f010117c <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010198e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101995:	e8 57 f7 ff ff       	call   f01010f1 <page_alloc>
f010199a:	89 c6                	mov    %eax,%esi
f010199c:	85 c0                	test   %eax,%eax
f010199e:	75 24                	jne    f01019c4 <mem_init+0x401>
f01019a0:	c7 44 24 0c f0 79 10 	movl   $0xf01079f0,0xc(%esp)
f01019a7:	f0 
f01019a8:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01019af:	f0 
f01019b0:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f01019b7:	00 
f01019b8:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01019bf:	e8 7c e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01019c4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019cb:	e8 21 f7 ff ff       	call   f01010f1 <page_alloc>
f01019d0:	89 c7                	mov    %eax,%edi
f01019d2:	85 c0                	test   %eax,%eax
f01019d4:	75 24                	jne    f01019fa <mem_init+0x437>
f01019d6:	c7 44 24 0c 06 7a 10 	movl   $0xf0107a06,0xc(%esp)
f01019dd:	f0 
f01019de:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01019e5:	f0 
f01019e6:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f01019ed:	00 
f01019ee:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01019f5:	e8 46 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01019fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a01:	e8 eb f6 ff ff       	call   f01010f1 <page_alloc>
f0101a06:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a09:	85 c0                	test   %eax,%eax
f0101a0b:	75 24                	jne    f0101a31 <mem_init+0x46e>
f0101a0d:	c7 44 24 0c 1c 7a 10 	movl   $0xf0107a1c,0xc(%esp)
f0101a14:	f0 
f0101a15:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101a1c:	f0 
f0101a1d:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f0101a24:	00 
f0101a25:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101a2c:	e8 0f e6 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a31:	39 fe                	cmp    %edi,%esi
f0101a33:	75 24                	jne    f0101a59 <mem_init+0x496>
f0101a35:	c7 44 24 0c 32 7a 10 	movl   $0xf0107a32,0xc(%esp)
f0101a3c:	f0 
f0101a3d:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101a44:	f0 
f0101a45:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f0101a4c:	00 
f0101a4d:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101a54:	e8 e7 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a59:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a5c:	39 c7                	cmp    %eax,%edi
f0101a5e:	74 04                	je     f0101a64 <mem_init+0x4a1>
f0101a60:	39 c6                	cmp    %eax,%esi
f0101a62:	75 24                	jne    f0101a88 <mem_init+0x4c5>
f0101a64:	c7 44 24 0c fc 70 10 	movl   $0xf01070fc,0xc(%esp)
f0101a6b:	f0 
f0101a6c:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101a73:	f0 
f0101a74:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0101a7b:	00 
f0101a7c:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101a83:	e8 b8 e5 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101a88:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a8f:	e8 5d f6 ff ff       	call   f01010f1 <page_alloc>
f0101a94:	85 c0                	test   %eax,%eax
f0101a96:	74 24                	je     f0101abc <mem_init+0x4f9>
f0101a98:	c7 44 24 0c 9b 7a 10 	movl   $0xf0107a9b,0xc(%esp)
f0101a9f:	f0 
f0101aa0:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101aa7:	f0 
f0101aa8:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0101aaf:	00 
f0101ab0:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101ab7:	e8 84 e5 ff ff       	call   f0100040 <_panic>
f0101abc:	89 f0                	mov    %esi,%eax
f0101abe:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0101ac4:	c1 f8 03             	sar    $0x3,%eax
f0101ac7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101aca:	89 c2                	mov    %eax,%edx
f0101acc:	c1 ea 0c             	shr    $0xc,%edx
f0101acf:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0101ad5:	72 20                	jb     f0101af7 <mem_init+0x534>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ad7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101adb:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0101ae2:	f0 
f0101ae3:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101aea:	00 
f0101aeb:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f0101af2:	e8 49 e5 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101af7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101afe:	00 
f0101aff:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101b06:	00 
	return (void *)(pa + KERNBASE);
f0101b07:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b0c:	89 04 24             	mov    %eax,(%esp)
f0101b0f:	e8 13 41 00 00       	call   f0105c27 <memset>
	page_free(pp0);
f0101b14:	89 34 24             	mov    %esi,(%esp)
f0101b17:	e8 60 f6 ff ff       	call   f010117c <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101b1c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101b23:	e8 c9 f5 ff ff       	call   f01010f1 <page_alloc>
f0101b28:	85 c0                	test   %eax,%eax
f0101b2a:	75 24                	jne    f0101b50 <mem_init+0x58d>
f0101b2c:	c7 44 24 0c aa 7a 10 	movl   $0xf0107aaa,0xc(%esp)
f0101b33:	f0 
f0101b34:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101b3b:	f0 
f0101b3c:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0101b43:	00 
f0101b44:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101b4b:	e8 f0 e4 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101b50:	39 c6                	cmp    %eax,%esi
f0101b52:	74 24                	je     f0101b78 <mem_init+0x5b5>
f0101b54:	c7 44 24 0c c8 7a 10 	movl   $0xf0107ac8,0xc(%esp)
f0101b5b:	f0 
f0101b5c:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101b63:	f0 
f0101b64:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0101b6b:	00 
f0101b6c:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101b73:	e8 c8 e4 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b78:	89 f0                	mov    %esi,%eax
f0101b7a:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0101b80:	c1 f8 03             	sar    $0x3,%eax
f0101b83:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b86:	89 c2                	mov    %eax,%edx
f0101b88:	c1 ea 0c             	shr    $0xc,%edx
f0101b8b:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0101b91:	72 20                	jb     f0101bb3 <mem_init+0x5f0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b93:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101b97:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0101b9e:	f0 
f0101b9f:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101ba6:	00 
f0101ba7:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f0101bae:	e8 8d e4 ff ff       	call   f0100040 <_panic>
f0101bb3:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101bb9:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101bbf:	80 38 00             	cmpb   $0x0,(%eax)
f0101bc2:	74 24                	je     f0101be8 <mem_init+0x625>
f0101bc4:	c7 44 24 0c d8 7a 10 	movl   $0xf0107ad8,0xc(%esp)
f0101bcb:	f0 
f0101bcc:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101bd3:	f0 
f0101bd4:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f0101bdb:	00 
f0101bdc:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101be3:	e8 58 e4 ff ff       	call   f0100040 <_panic>
f0101be8:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101beb:	39 d0                	cmp    %edx,%eax
f0101bed:	75 d0                	jne    f0101bbf <mem_init+0x5fc>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101bef:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bf2:	a3 40 c2 22 f0       	mov    %eax,0xf022c240

	// free the pages we took
	page_free(pp0);
f0101bf7:	89 34 24             	mov    %esi,(%esp)
f0101bfa:	e8 7d f5 ff ff       	call   f010117c <page_free>
	page_free(pp1);
f0101bff:	89 3c 24             	mov    %edi,(%esp)
f0101c02:	e8 75 f5 ff ff       	call   f010117c <page_free>
	page_free(pp2);
f0101c07:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c0a:	89 04 24             	mov    %eax,(%esp)
f0101c0d:	e8 6a f5 ff ff       	call   f010117c <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101c12:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f0101c17:	eb 05                	jmp    f0101c1e <mem_init+0x65b>
		--nfree;
f0101c19:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101c1c:	8b 00                	mov    (%eax),%eax
f0101c1e:	85 c0                	test   %eax,%eax
f0101c20:	75 f7                	jne    f0101c19 <mem_init+0x656>
		--nfree;
	assert(nfree == 0);
f0101c22:	85 db                	test   %ebx,%ebx
f0101c24:	74 24                	je     f0101c4a <mem_init+0x687>
f0101c26:	c7 44 24 0c e2 7a 10 	movl   $0xf0107ae2,0xc(%esp)
f0101c2d:	f0 
f0101c2e:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101c35:	f0 
f0101c36:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0101c3d:	00 
f0101c3e:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101c45:	e8 f6 e3 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101c4a:	c7 04 24 1c 71 10 f0 	movl   $0xf010711c,(%esp)
f0101c51:	e8 60 24 00 00       	call   f01040b6 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101c56:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c5d:	e8 8f f4 ff ff       	call   f01010f1 <page_alloc>
f0101c62:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101c65:	85 c0                	test   %eax,%eax
f0101c67:	75 24                	jne    f0101c8d <mem_init+0x6ca>
f0101c69:	c7 44 24 0c f0 79 10 	movl   $0xf01079f0,0xc(%esp)
f0101c70:	f0 
f0101c71:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101c78:	f0 
f0101c79:	c7 44 24 04 f8 03 00 	movl   $0x3f8,0x4(%esp)
f0101c80:	00 
f0101c81:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101c88:	e8 b3 e3 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101c8d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c94:	e8 58 f4 ff ff       	call   f01010f1 <page_alloc>
f0101c99:	89 c3                	mov    %eax,%ebx
f0101c9b:	85 c0                	test   %eax,%eax
f0101c9d:	75 24                	jne    f0101cc3 <mem_init+0x700>
f0101c9f:	c7 44 24 0c 06 7a 10 	movl   $0xf0107a06,0xc(%esp)
f0101ca6:	f0 
f0101ca7:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101cae:	f0 
f0101caf:	c7 44 24 04 f9 03 00 	movl   $0x3f9,0x4(%esp)
f0101cb6:	00 
f0101cb7:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101cbe:	e8 7d e3 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101cc3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cca:	e8 22 f4 ff ff       	call   f01010f1 <page_alloc>
f0101ccf:	89 c6                	mov    %eax,%esi
f0101cd1:	85 c0                	test   %eax,%eax
f0101cd3:	75 24                	jne    f0101cf9 <mem_init+0x736>
f0101cd5:	c7 44 24 0c 1c 7a 10 	movl   $0xf0107a1c,0xc(%esp)
f0101cdc:	f0 
f0101cdd:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101ce4:	f0 
f0101ce5:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f0101cec:	00 
f0101ced:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101cf4:	e8 47 e3 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101cf9:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101cfc:	75 24                	jne    f0101d22 <mem_init+0x75f>
f0101cfe:	c7 44 24 0c 32 7a 10 	movl   $0xf0107a32,0xc(%esp)
f0101d05:	f0 
f0101d06:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101d0d:	f0 
f0101d0e:	c7 44 24 04 fd 03 00 	movl   $0x3fd,0x4(%esp)
f0101d15:	00 
f0101d16:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101d1d:	e8 1e e3 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101d22:	39 c3                	cmp    %eax,%ebx
f0101d24:	74 05                	je     f0101d2b <mem_init+0x768>
f0101d26:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101d29:	75 24                	jne    f0101d4f <mem_init+0x78c>
f0101d2b:	c7 44 24 0c fc 70 10 	movl   $0xf01070fc,0xc(%esp)
f0101d32:	f0 
f0101d33:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101d3a:	f0 
f0101d3b:	c7 44 24 04 fe 03 00 	movl   $0x3fe,0x4(%esp)
f0101d42:	00 
f0101d43:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101d4a:	e8 f1 e2 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101d4f:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f0101d54:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101d57:	c7 05 40 c2 22 f0 00 	movl   $0x0,0xf022c240
f0101d5e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101d61:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d68:	e8 84 f3 ff ff       	call   f01010f1 <page_alloc>
f0101d6d:	85 c0                	test   %eax,%eax
f0101d6f:	74 24                	je     f0101d95 <mem_init+0x7d2>
f0101d71:	c7 44 24 0c 9b 7a 10 	movl   $0xf0107a9b,0xc(%esp)
f0101d78:	f0 
f0101d79:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101d80:	f0 
f0101d81:	c7 44 24 04 05 04 00 	movl   $0x405,0x4(%esp)
f0101d88:	00 
f0101d89:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101d90:	e8 ab e2 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101d95:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101d98:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101d9c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101da3:	00 
f0101da4:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0101da9:	89 04 24             	mov    %eax,(%esp)
f0101dac:	e8 c4 f5 ff ff       	call   f0101375 <page_lookup>
f0101db1:	85 c0                	test   %eax,%eax
f0101db3:	74 24                	je     f0101dd9 <mem_init+0x816>
f0101db5:	c7 44 24 0c 3c 71 10 	movl   $0xf010713c,0xc(%esp)
f0101dbc:	f0 
f0101dbd:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101dc4:	f0 
f0101dc5:	c7 44 24 04 08 04 00 	movl   $0x408,0x4(%esp)
f0101dcc:	00 
f0101dcd:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101dd4:	e8 67 e2 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101dd9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101de0:	00 
f0101de1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101de8:	00 
f0101de9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101ded:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0101df2:	89 04 24             	mov    %eax,(%esp)
f0101df5:	e8 80 f6 ff ff       	call   f010147a <page_insert>
f0101dfa:	85 c0                	test   %eax,%eax
f0101dfc:	78 24                	js     f0101e22 <mem_init+0x85f>
f0101dfe:	c7 44 24 0c 74 71 10 	movl   $0xf0107174,0xc(%esp)
f0101e05:	f0 
f0101e06:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101e0d:	f0 
f0101e0e:	c7 44 24 04 0b 04 00 	movl   $0x40b,0x4(%esp)
f0101e15:	00 
f0101e16:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101e1d:	e8 1e e2 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101e22:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e25:	89 04 24             	mov    %eax,(%esp)
f0101e28:	e8 4f f3 ff ff       	call   f010117c <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101e2d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e34:	00 
f0101e35:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e3c:	00 
f0101e3d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e41:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0101e46:	89 04 24             	mov    %eax,(%esp)
f0101e49:	e8 2c f6 ff ff       	call   f010147a <page_insert>
f0101e4e:	85 c0                	test   %eax,%eax
f0101e50:	74 24                	je     f0101e76 <mem_init+0x8b3>
f0101e52:	c7 44 24 0c a4 71 10 	movl   $0xf01071a4,0xc(%esp)
f0101e59:	f0 
f0101e5a:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101e61:	f0 
f0101e62:	c7 44 24 04 0f 04 00 	movl   $0x40f,0x4(%esp)
f0101e69:	00 
f0101e6a:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101e71:	e8 ca e1 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e76:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e7c:	a1 90 ce 22 f0       	mov    0xf022ce90,%eax
f0101e81:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e84:	8b 17                	mov    (%edi),%edx
f0101e86:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e8c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e8f:	29 c1                	sub    %eax,%ecx
f0101e91:	89 c8                	mov    %ecx,%eax
f0101e93:	c1 f8 03             	sar    $0x3,%eax
f0101e96:	c1 e0 0c             	shl    $0xc,%eax
f0101e99:	39 c2                	cmp    %eax,%edx
f0101e9b:	74 24                	je     f0101ec1 <mem_init+0x8fe>
f0101e9d:	c7 44 24 0c d4 71 10 	movl   $0xf01071d4,0xc(%esp)
f0101ea4:	f0 
f0101ea5:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101eac:	f0 
f0101ead:	c7 44 24 04 10 04 00 	movl   $0x410,0x4(%esp)
f0101eb4:	00 
f0101eb5:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101ebc:	e8 7f e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101ec1:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ec6:	89 f8                	mov    %edi,%eax
f0101ec8:	e8 58 ec ff ff       	call   f0100b25 <check_va2pa>
f0101ecd:	89 da                	mov    %ebx,%edx
f0101ecf:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101ed2:	c1 fa 03             	sar    $0x3,%edx
f0101ed5:	c1 e2 0c             	shl    $0xc,%edx
f0101ed8:	39 d0                	cmp    %edx,%eax
f0101eda:	74 24                	je     f0101f00 <mem_init+0x93d>
f0101edc:	c7 44 24 0c fc 71 10 	movl   $0xf01071fc,0xc(%esp)
f0101ee3:	f0 
f0101ee4:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101eeb:	f0 
f0101eec:	c7 44 24 04 11 04 00 	movl   $0x411,0x4(%esp)
f0101ef3:	00 
f0101ef4:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101efb:	e8 40 e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101f00:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f05:	74 24                	je     f0101f2b <mem_init+0x968>
f0101f07:	c7 44 24 0c ed 7a 10 	movl   $0xf0107aed,0xc(%esp)
f0101f0e:	f0 
f0101f0f:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101f16:	f0 
f0101f17:	c7 44 24 04 12 04 00 	movl   $0x412,0x4(%esp)
f0101f1e:	00 
f0101f1f:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101f26:	e8 15 e1 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101f2b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f2e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f33:	74 24                	je     f0101f59 <mem_init+0x996>
f0101f35:	c7 44 24 0c fe 7a 10 	movl   $0xf0107afe,0xc(%esp)
f0101f3c:	f0 
f0101f3d:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101f44:	f0 
f0101f45:	c7 44 24 04 13 04 00 	movl   $0x413,0x4(%esp)
f0101f4c:	00 
f0101f4d:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101f54:	e8 e7 e0 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f59:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f60:	00 
f0101f61:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f68:	00 
f0101f69:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f6d:	89 3c 24             	mov    %edi,(%esp)
f0101f70:	e8 05 f5 ff ff       	call   f010147a <page_insert>
f0101f75:	85 c0                	test   %eax,%eax
f0101f77:	74 24                	je     f0101f9d <mem_init+0x9da>
f0101f79:	c7 44 24 0c 2c 72 10 	movl   $0xf010722c,0xc(%esp)
f0101f80:	f0 
f0101f81:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101f88:	f0 
f0101f89:	c7 44 24 04 16 04 00 	movl   $0x416,0x4(%esp)
f0101f90:	00 
f0101f91:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101f98:	e8 a3 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f9d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fa2:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0101fa7:	e8 79 eb ff ff       	call   f0100b25 <check_va2pa>
f0101fac:	89 f2                	mov    %esi,%edx
f0101fae:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0101fb4:	c1 fa 03             	sar    $0x3,%edx
f0101fb7:	c1 e2 0c             	shl    $0xc,%edx
f0101fba:	39 d0                	cmp    %edx,%eax
f0101fbc:	74 24                	je     f0101fe2 <mem_init+0xa1f>
f0101fbe:	c7 44 24 0c 68 72 10 	movl   $0xf0107268,0xc(%esp)
f0101fc5:	f0 
f0101fc6:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101fcd:	f0 
f0101fce:	c7 44 24 04 17 04 00 	movl   $0x417,0x4(%esp)
f0101fd5:	00 
f0101fd6:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0101fdd:	e8 5e e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101fe2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fe7:	74 24                	je     f010200d <mem_init+0xa4a>
f0101fe9:	c7 44 24 0c 0f 7b 10 	movl   $0xf0107b0f,0xc(%esp)
f0101ff0:	f0 
f0101ff1:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0101ff8:	f0 
f0101ff9:	c7 44 24 04 18 04 00 	movl   $0x418,0x4(%esp)
f0102000:	00 
f0102001:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102008:	e8 33 e0 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010200d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102014:	e8 d8 f0 ff ff       	call   f01010f1 <page_alloc>
f0102019:	85 c0                	test   %eax,%eax
f010201b:	74 24                	je     f0102041 <mem_init+0xa7e>
f010201d:	c7 44 24 0c 9b 7a 10 	movl   $0xf0107a9b,0xc(%esp)
f0102024:	f0 
f0102025:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010202c:	f0 
f010202d:	c7 44 24 04 1b 04 00 	movl   $0x41b,0x4(%esp)
f0102034:	00 
f0102035:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010203c:	e8 ff df ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102041:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102048:	00 
f0102049:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102050:	00 
f0102051:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102055:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f010205a:	89 04 24             	mov    %eax,(%esp)
f010205d:	e8 18 f4 ff ff       	call   f010147a <page_insert>
f0102062:	85 c0                	test   %eax,%eax
f0102064:	74 24                	je     f010208a <mem_init+0xac7>
f0102066:	c7 44 24 0c 2c 72 10 	movl   $0xf010722c,0xc(%esp)
f010206d:	f0 
f010206e:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102075:	f0 
f0102076:	c7 44 24 04 1e 04 00 	movl   $0x41e,0x4(%esp)
f010207d:	00 
f010207e:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102085:	e8 b6 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010208a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010208f:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102094:	e8 8c ea ff ff       	call   f0100b25 <check_va2pa>
f0102099:	89 f2                	mov    %esi,%edx
f010209b:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f01020a1:	c1 fa 03             	sar    $0x3,%edx
f01020a4:	c1 e2 0c             	shl    $0xc,%edx
f01020a7:	39 d0                	cmp    %edx,%eax
f01020a9:	74 24                	je     f01020cf <mem_init+0xb0c>
f01020ab:	c7 44 24 0c 68 72 10 	movl   $0xf0107268,0xc(%esp)
f01020b2:	f0 
f01020b3:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01020ba:	f0 
f01020bb:	c7 44 24 04 1f 04 00 	movl   $0x41f,0x4(%esp)
f01020c2:	00 
f01020c3:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01020ca:	e8 71 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01020cf:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01020d4:	74 24                	je     f01020fa <mem_init+0xb37>
f01020d6:	c7 44 24 0c 0f 7b 10 	movl   $0xf0107b0f,0xc(%esp)
f01020dd:	f0 
f01020de:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01020e5:	f0 
f01020e6:	c7 44 24 04 20 04 00 	movl   $0x420,0x4(%esp)
f01020ed:	00 
f01020ee:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01020f5:	e8 46 df ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01020fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102101:	e8 eb ef ff ff       	call   f01010f1 <page_alloc>
f0102106:	85 c0                	test   %eax,%eax
f0102108:	74 24                	je     f010212e <mem_init+0xb6b>
f010210a:	c7 44 24 0c 9b 7a 10 	movl   $0xf0107a9b,0xc(%esp)
f0102111:	f0 
f0102112:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102119:	f0 
f010211a:	c7 44 24 04 24 04 00 	movl   $0x424,0x4(%esp)
f0102121:	00 
f0102122:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102129:	e8 12 df ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010212e:	8b 15 8c ce 22 f0    	mov    0xf022ce8c,%edx
f0102134:	8b 02                	mov    (%edx),%eax
f0102136:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010213b:	89 c1                	mov    %eax,%ecx
f010213d:	c1 e9 0c             	shr    $0xc,%ecx
f0102140:	3b 0d 88 ce 22 f0    	cmp    0xf022ce88,%ecx
f0102146:	72 20                	jb     f0102168 <mem_init+0xba5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102148:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010214c:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0102153:	f0 
f0102154:	c7 44 24 04 27 04 00 	movl   $0x427,0x4(%esp)
f010215b:	00 
f010215c:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102163:	e8 d8 de ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102168:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010216d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102170:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102177:	00 
f0102178:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010217f:	00 
f0102180:	89 14 24             	mov    %edx,(%esp)
f0102183:	e8 52 f0 ff ff       	call   f01011da <pgdir_walk>
f0102188:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010218b:	8d 51 04             	lea    0x4(%ecx),%edx
f010218e:	39 d0                	cmp    %edx,%eax
f0102190:	74 24                	je     f01021b6 <mem_init+0xbf3>
f0102192:	c7 44 24 0c 98 72 10 	movl   $0xf0107298,0xc(%esp)
f0102199:	f0 
f010219a:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01021a1:	f0 
f01021a2:	c7 44 24 04 28 04 00 	movl   $0x428,0x4(%esp)
f01021a9:	00 
f01021aa:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01021b1:	e8 8a de ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01021b6:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01021bd:	00 
f01021be:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021c5:	00 
f01021c6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01021ca:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01021cf:	89 04 24             	mov    %eax,(%esp)
f01021d2:	e8 a3 f2 ff ff       	call   f010147a <page_insert>
f01021d7:	85 c0                	test   %eax,%eax
f01021d9:	74 24                	je     f01021ff <mem_init+0xc3c>
f01021db:	c7 44 24 0c d8 72 10 	movl   $0xf01072d8,0xc(%esp)
f01021e2:	f0 
f01021e3:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01021ea:	f0 
f01021eb:	c7 44 24 04 2b 04 00 	movl   $0x42b,0x4(%esp)
f01021f2:	00 
f01021f3:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01021fa:	e8 41 de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01021ff:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f0102205:	ba 00 10 00 00       	mov    $0x1000,%edx
f010220a:	89 f8                	mov    %edi,%eax
f010220c:	e8 14 e9 ff ff       	call   f0100b25 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102211:	89 f2                	mov    %esi,%edx
f0102213:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0102219:	c1 fa 03             	sar    $0x3,%edx
f010221c:	c1 e2 0c             	shl    $0xc,%edx
f010221f:	39 d0                	cmp    %edx,%eax
f0102221:	74 24                	je     f0102247 <mem_init+0xc84>
f0102223:	c7 44 24 0c 68 72 10 	movl   $0xf0107268,0xc(%esp)
f010222a:	f0 
f010222b:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102232:	f0 
f0102233:	c7 44 24 04 2c 04 00 	movl   $0x42c,0x4(%esp)
f010223a:	00 
f010223b:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102242:	e8 f9 dd ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102247:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010224c:	74 24                	je     f0102272 <mem_init+0xcaf>
f010224e:	c7 44 24 0c 0f 7b 10 	movl   $0xf0107b0f,0xc(%esp)
f0102255:	f0 
f0102256:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010225d:	f0 
f010225e:	c7 44 24 04 2d 04 00 	movl   $0x42d,0x4(%esp)
f0102265:	00 
f0102266:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010226d:	e8 ce dd ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102272:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102279:	00 
f010227a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102281:	00 
f0102282:	89 3c 24             	mov    %edi,(%esp)
f0102285:	e8 50 ef ff ff       	call   f01011da <pgdir_walk>
f010228a:	f6 00 04             	testb  $0x4,(%eax)
f010228d:	75 24                	jne    f01022b3 <mem_init+0xcf0>
f010228f:	c7 44 24 0c 18 73 10 	movl   $0xf0107318,0xc(%esp)
f0102296:	f0 
f0102297:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010229e:	f0 
f010229f:	c7 44 24 04 2e 04 00 	movl   $0x42e,0x4(%esp)
f01022a6:	00 
f01022a7:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01022ae:	e8 8d dd ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01022b3:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01022b8:	f6 00 04             	testb  $0x4,(%eax)
f01022bb:	75 24                	jne    f01022e1 <mem_init+0xd1e>
f01022bd:	c7 44 24 0c 20 7b 10 	movl   $0xf0107b20,0xc(%esp)
f01022c4:	f0 
f01022c5:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01022cc:	f0 
f01022cd:	c7 44 24 04 2f 04 00 	movl   $0x42f,0x4(%esp)
f01022d4:	00 
f01022d5:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01022dc:	e8 5f dd ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01022e1:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022e8:	00 
f01022e9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022f0:	00 
f01022f1:	89 74 24 04          	mov    %esi,0x4(%esp)
f01022f5:	89 04 24             	mov    %eax,(%esp)
f01022f8:	e8 7d f1 ff ff       	call   f010147a <page_insert>
f01022fd:	85 c0                	test   %eax,%eax
f01022ff:	74 24                	je     f0102325 <mem_init+0xd62>
f0102301:	c7 44 24 0c 2c 72 10 	movl   $0xf010722c,0xc(%esp)
f0102308:	f0 
f0102309:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102310:	f0 
f0102311:	c7 44 24 04 32 04 00 	movl   $0x432,0x4(%esp)
f0102318:	00 
f0102319:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102320:	e8 1b dd ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102325:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010232c:	00 
f010232d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102334:	00 
f0102335:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f010233a:	89 04 24             	mov    %eax,(%esp)
f010233d:	e8 98 ee ff ff       	call   f01011da <pgdir_walk>
f0102342:	f6 00 02             	testb  $0x2,(%eax)
f0102345:	75 24                	jne    f010236b <mem_init+0xda8>
f0102347:	c7 44 24 0c 4c 73 10 	movl   $0xf010734c,0xc(%esp)
f010234e:	f0 
f010234f:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102356:	f0 
f0102357:	c7 44 24 04 33 04 00 	movl   $0x433,0x4(%esp)
f010235e:	00 
f010235f:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102366:	e8 d5 dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010236b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102372:	00 
f0102373:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010237a:	00 
f010237b:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102380:	89 04 24             	mov    %eax,(%esp)
f0102383:	e8 52 ee ff ff       	call   f01011da <pgdir_walk>
f0102388:	f6 00 04             	testb  $0x4,(%eax)
f010238b:	74 24                	je     f01023b1 <mem_init+0xdee>
f010238d:	c7 44 24 0c 80 73 10 	movl   $0xf0107380,0xc(%esp)
f0102394:	f0 
f0102395:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010239c:	f0 
f010239d:	c7 44 24 04 34 04 00 	movl   $0x434,0x4(%esp)
f01023a4:	00 
f01023a5:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01023ac:	e8 8f dc ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01023b1:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01023b8:	00 
f01023b9:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01023c0:	00 
f01023c1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023c4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01023c8:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01023cd:	89 04 24             	mov    %eax,(%esp)
f01023d0:	e8 a5 f0 ff ff       	call   f010147a <page_insert>
f01023d5:	85 c0                	test   %eax,%eax
f01023d7:	78 24                	js     f01023fd <mem_init+0xe3a>
f01023d9:	c7 44 24 0c b8 73 10 	movl   $0xf01073b8,0xc(%esp)
f01023e0:	f0 
f01023e1:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01023e8:	f0 
f01023e9:	c7 44 24 04 37 04 00 	movl   $0x437,0x4(%esp)
f01023f0:	00 
f01023f1:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01023f8:	e8 43 dc ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01023fd:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102404:	00 
f0102405:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010240c:	00 
f010240d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102411:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102416:	89 04 24             	mov    %eax,(%esp)
f0102419:	e8 5c f0 ff ff       	call   f010147a <page_insert>
f010241e:	85 c0                	test   %eax,%eax
f0102420:	74 24                	je     f0102446 <mem_init+0xe83>
f0102422:	c7 44 24 0c f0 73 10 	movl   $0xf01073f0,0xc(%esp)
f0102429:	f0 
f010242a:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102431:	f0 
f0102432:	c7 44 24 04 3a 04 00 	movl   $0x43a,0x4(%esp)
f0102439:	00 
f010243a:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102441:	e8 fa db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102446:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010244d:	00 
f010244e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102455:	00 
f0102456:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f010245b:	89 04 24             	mov    %eax,(%esp)
f010245e:	e8 77 ed ff ff       	call   f01011da <pgdir_walk>
f0102463:	f6 00 04             	testb  $0x4,(%eax)
f0102466:	74 24                	je     f010248c <mem_init+0xec9>
f0102468:	c7 44 24 0c 80 73 10 	movl   $0xf0107380,0xc(%esp)
f010246f:	f0 
f0102470:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102477:	f0 
f0102478:	c7 44 24 04 3b 04 00 	movl   $0x43b,0x4(%esp)
f010247f:	00 
f0102480:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102487:	e8 b4 db ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010248c:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f0102492:	ba 00 00 00 00       	mov    $0x0,%edx
f0102497:	89 f8                	mov    %edi,%eax
f0102499:	e8 87 e6 ff ff       	call   f0100b25 <check_va2pa>
f010249e:	89 c1                	mov    %eax,%ecx
f01024a0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01024a3:	89 d8                	mov    %ebx,%eax
f01024a5:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f01024ab:	c1 f8 03             	sar    $0x3,%eax
f01024ae:	c1 e0 0c             	shl    $0xc,%eax
f01024b1:	39 c1                	cmp    %eax,%ecx
f01024b3:	74 24                	je     f01024d9 <mem_init+0xf16>
f01024b5:	c7 44 24 0c 2c 74 10 	movl   $0xf010742c,0xc(%esp)
f01024bc:	f0 
f01024bd:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01024c4:	f0 
f01024c5:	c7 44 24 04 3e 04 00 	movl   $0x43e,0x4(%esp)
f01024cc:	00 
f01024cd:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01024d4:	e8 67 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01024d9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024de:	89 f8                	mov    %edi,%eax
f01024e0:	e8 40 e6 ff ff       	call   f0100b25 <check_va2pa>
f01024e5:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01024e8:	74 24                	je     f010250e <mem_init+0xf4b>
f01024ea:	c7 44 24 0c 58 74 10 	movl   $0xf0107458,0xc(%esp)
f01024f1:	f0 
f01024f2:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01024f9:	f0 
f01024fa:	c7 44 24 04 3f 04 00 	movl   $0x43f,0x4(%esp)
f0102501:	00 
f0102502:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102509:	e8 32 db ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010250e:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0102513:	74 24                	je     f0102539 <mem_init+0xf76>
f0102515:	c7 44 24 0c 36 7b 10 	movl   $0xf0107b36,0xc(%esp)
f010251c:	f0 
f010251d:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102524:	f0 
f0102525:	c7 44 24 04 41 04 00 	movl   $0x441,0x4(%esp)
f010252c:	00 
f010252d:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102534:	e8 07 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102539:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010253e:	74 24                	je     f0102564 <mem_init+0xfa1>
f0102540:	c7 44 24 0c 47 7b 10 	movl   $0xf0107b47,0xc(%esp)
f0102547:	f0 
f0102548:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010254f:	f0 
f0102550:	c7 44 24 04 42 04 00 	movl   $0x442,0x4(%esp)
f0102557:	00 
f0102558:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010255f:	e8 dc da ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102564:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010256b:	e8 81 eb ff ff       	call   f01010f1 <page_alloc>
f0102570:	85 c0                	test   %eax,%eax
f0102572:	74 04                	je     f0102578 <mem_init+0xfb5>
f0102574:	39 c6                	cmp    %eax,%esi
f0102576:	74 24                	je     f010259c <mem_init+0xfd9>
f0102578:	c7 44 24 0c 88 74 10 	movl   $0xf0107488,0xc(%esp)
f010257f:	f0 
f0102580:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102587:	f0 
f0102588:	c7 44 24 04 45 04 00 	movl   $0x445,0x4(%esp)
f010258f:	00 
f0102590:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102597:	e8 a4 da ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010259c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01025a3:	00 
f01025a4:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01025a9:	89 04 24             	mov    %eax,(%esp)
f01025ac:	e8 72 ee ff ff       	call   f0101423 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01025b1:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f01025b7:	ba 00 00 00 00       	mov    $0x0,%edx
f01025bc:	89 f8                	mov    %edi,%eax
f01025be:	e8 62 e5 ff ff       	call   f0100b25 <check_va2pa>
f01025c3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025c6:	74 24                	je     f01025ec <mem_init+0x1029>
f01025c8:	c7 44 24 0c ac 74 10 	movl   $0xf01074ac,0xc(%esp)
f01025cf:	f0 
f01025d0:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01025d7:	f0 
f01025d8:	c7 44 24 04 49 04 00 	movl   $0x449,0x4(%esp)
f01025df:	00 
f01025e0:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01025e7:	e8 54 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01025ec:	ba 00 10 00 00       	mov    $0x1000,%edx
f01025f1:	89 f8                	mov    %edi,%eax
f01025f3:	e8 2d e5 ff ff       	call   f0100b25 <check_va2pa>
f01025f8:	89 da                	mov    %ebx,%edx
f01025fa:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0102600:	c1 fa 03             	sar    $0x3,%edx
f0102603:	c1 e2 0c             	shl    $0xc,%edx
f0102606:	39 d0                	cmp    %edx,%eax
f0102608:	74 24                	je     f010262e <mem_init+0x106b>
f010260a:	c7 44 24 0c 58 74 10 	movl   $0xf0107458,0xc(%esp)
f0102611:	f0 
f0102612:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102619:	f0 
f010261a:	c7 44 24 04 4a 04 00 	movl   $0x44a,0x4(%esp)
f0102621:	00 
f0102622:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102629:	e8 12 da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010262e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102633:	74 24                	je     f0102659 <mem_init+0x1096>
f0102635:	c7 44 24 0c ed 7a 10 	movl   $0xf0107aed,0xc(%esp)
f010263c:	f0 
f010263d:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102644:	f0 
f0102645:	c7 44 24 04 4b 04 00 	movl   $0x44b,0x4(%esp)
f010264c:	00 
f010264d:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102654:	e8 e7 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102659:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010265e:	74 24                	je     f0102684 <mem_init+0x10c1>
f0102660:	c7 44 24 0c 47 7b 10 	movl   $0xf0107b47,0xc(%esp)
f0102667:	f0 
f0102668:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010266f:	f0 
f0102670:	c7 44 24 04 4c 04 00 	movl   $0x44c,0x4(%esp)
f0102677:	00 
f0102678:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010267f:	e8 bc d9 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102684:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010268b:	00 
f010268c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102693:	00 
f0102694:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102698:	89 3c 24             	mov    %edi,(%esp)
f010269b:	e8 da ed ff ff       	call   f010147a <page_insert>
f01026a0:	85 c0                	test   %eax,%eax
f01026a2:	74 24                	je     f01026c8 <mem_init+0x1105>
f01026a4:	c7 44 24 0c d0 74 10 	movl   $0xf01074d0,0xc(%esp)
f01026ab:	f0 
f01026ac:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01026b3:	f0 
f01026b4:	c7 44 24 04 4f 04 00 	movl   $0x44f,0x4(%esp)
f01026bb:	00 
f01026bc:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01026c3:	e8 78 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f01026c8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01026cd:	75 24                	jne    f01026f3 <mem_init+0x1130>
f01026cf:	c7 44 24 0c 58 7b 10 	movl   $0xf0107b58,0xc(%esp)
f01026d6:	f0 
f01026d7:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01026de:	f0 
f01026df:	c7 44 24 04 50 04 00 	movl   $0x450,0x4(%esp)
f01026e6:	00 
f01026e7:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01026ee:	e8 4d d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f01026f3:	83 3b 00             	cmpl   $0x0,(%ebx)
f01026f6:	74 24                	je     f010271c <mem_init+0x1159>
f01026f8:	c7 44 24 0c 64 7b 10 	movl   $0xf0107b64,0xc(%esp)
f01026ff:	f0 
f0102700:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102707:	f0 
f0102708:	c7 44 24 04 51 04 00 	movl   $0x451,0x4(%esp)
f010270f:	00 
f0102710:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102717:	e8 24 d9 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010271c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102723:	00 
f0102724:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102729:	89 04 24             	mov    %eax,(%esp)
f010272c:	e8 f2 ec ff ff       	call   f0101423 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102731:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f0102737:	ba 00 00 00 00       	mov    $0x0,%edx
f010273c:	89 f8                	mov    %edi,%eax
f010273e:	e8 e2 e3 ff ff       	call   f0100b25 <check_va2pa>
f0102743:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102746:	74 24                	je     f010276c <mem_init+0x11a9>
f0102748:	c7 44 24 0c ac 74 10 	movl   $0xf01074ac,0xc(%esp)
f010274f:	f0 
f0102750:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102757:	f0 
f0102758:	c7 44 24 04 55 04 00 	movl   $0x455,0x4(%esp)
f010275f:	00 
f0102760:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102767:	e8 d4 d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010276c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102771:	89 f8                	mov    %edi,%eax
f0102773:	e8 ad e3 ff ff       	call   f0100b25 <check_va2pa>
f0102778:	83 f8 ff             	cmp    $0xffffffff,%eax
f010277b:	74 24                	je     f01027a1 <mem_init+0x11de>
f010277d:	c7 44 24 0c 08 75 10 	movl   $0xf0107508,0xc(%esp)
f0102784:	f0 
f0102785:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010278c:	f0 
f010278d:	c7 44 24 04 56 04 00 	movl   $0x456,0x4(%esp)
f0102794:	00 
f0102795:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010279c:	e8 9f d8 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01027a1:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01027a6:	74 24                	je     f01027cc <mem_init+0x1209>
f01027a8:	c7 44 24 0c 79 7b 10 	movl   $0xf0107b79,0xc(%esp)
f01027af:	f0 
f01027b0:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01027b7:	f0 
f01027b8:	c7 44 24 04 57 04 00 	movl   $0x457,0x4(%esp)
f01027bf:	00 
f01027c0:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01027c7:	e8 74 d8 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01027cc:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01027d1:	74 24                	je     f01027f7 <mem_init+0x1234>
f01027d3:	c7 44 24 0c 47 7b 10 	movl   $0xf0107b47,0xc(%esp)
f01027da:	f0 
f01027db:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01027e2:	f0 
f01027e3:	c7 44 24 04 58 04 00 	movl   $0x458,0x4(%esp)
f01027ea:	00 
f01027eb:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01027f2:	e8 49 d8 ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01027f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027fe:	e8 ee e8 ff ff       	call   f01010f1 <page_alloc>
f0102803:	85 c0                	test   %eax,%eax
f0102805:	74 04                	je     f010280b <mem_init+0x1248>
f0102807:	39 c3                	cmp    %eax,%ebx
f0102809:	74 24                	je     f010282f <mem_init+0x126c>
f010280b:	c7 44 24 0c 30 75 10 	movl   $0xf0107530,0xc(%esp)
f0102812:	f0 
f0102813:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010281a:	f0 
f010281b:	c7 44 24 04 5b 04 00 	movl   $0x45b,0x4(%esp)
f0102822:	00 
f0102823:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010282a:	e8 11 d8 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010282f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102836:	e8 b6 e8 ff ff       	call   f01010f1 <page_alloc>
f010283b:	85 c0                	test   %eax,%eax
f010283d:	74 24                	je     f0102863 <mem_init+0x12a0>
f010283f:	c7 44 24 0c 9b 7a 10 	movl   $0xf0107a9b,0xc(%esp)
f0102846:	f0 
f0102847:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010284e:	f0 
f010284f:	c7 44 24 04 5e 04 00 	movl   $0x45e,0x4(%esp)
f0102856:	00 
f0102857:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010285e:	e8 dd d7 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102863:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102868:	8b 08                	mov    (%eax),%ecx
f010286a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102870:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102873:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0102879:	c1 fa 03             	sar    $0x3,%edx
f010287c:	c1 e2 0c             	shl    $0xc,%edx
f010287f:	39 d1                	cmp    %edx,%ecx
f0102881:	74 24                	je     f01028a7 <mem_init+0x12e4>
f0102883:	c7 44 24 0c d4 71 10 	movl   $0xf01071d4,0xc(%esp)
f010288a:	f0 
f010288b:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102892:	f0 
f0102893:	c7 44 24 04 61 04 00 	movl   $0x461,0x4(%esp)
f010289a:	00 
f010289b:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01028a2:	e8 99 d7 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01028a7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01028ad:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028b0:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01028b5:	74 24                	je     f01028db <mem_init+0x1318>
f01028b7:	c7 44 24 0c fe 7a 10 	movl   $0xf0107afe,0xc(%esp)
f01028be:	f0 
f01028bf:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01028c6:	f0 
f01028c7:	c7 44 24 04 63 04 00 	movl   $0x463,0x4(%esp)
f01028ce:	00 
f01028cf:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01028d6:	e8 65 d7 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01028db:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028de:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01028e4:	89 04 24             	mov    %eax,(%esp)
f01028e7:	e8 90 e8 ff ff       	call   f010117c <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01028ec:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01028f3:	00 
f01028f4:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01028fb:	00 
f01028fc:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102901:	89 04 24             	mov    %eax,(%esp)
f0102904:	e8 d1 e8 ff ff       	call   f01011da <pgdir_walk>
f0102909:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010290c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010290f:	8b 15 8c ce 22 f0    	mov    0xf022ce8c,%edx
f0102915:	8b 7a 04             	mov    0x4(%edx),%edi
f0102918:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010291e:	8b 0d 88 ce 22 f0    	mov    0xf022ce88,%ecx
f0102924:	89 f8                	mov    %edi,%eax
f0102926:	c1 e8 0c             	shr    $0xc,%eax
f0102929:	39 c8                	cmp    %ecx,%eax
f010292b:	72 20                	jb     f010294d <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010292d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102931:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0102938:	f0 
f0102939:	c7 44 24 04 6a 04 00 	movl   $0x46a,0x4(%esp)
f0102940:	00 
f0102941:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102948:	e8 f3 d6 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010294d:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102953:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102956:	74 24                	je     f010297c <mem_init+0x13b9>
f0102958:	c7 44 24 0c 8a 7b 10 	movl   $0xf0107b8a,0xc(%esp)
f010295f:	f0 
f0102960:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102967:	f0 
f0102968:	c7 44 24 04 6b 04 00 	movl   $0x46b,0x4(%esp)
f010296f:	00 
f0102970:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102977:	e8 c4 d6 ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010297c:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102983:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102986:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010298c:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0102992:	c1 f8 03             	sar    $0x3,%eax
f0102995:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102998:	89 c2                	mov    %eax,%edx
f010299a:	c1 ea 0c             	shr    $0xc,%edx
f010299d:	39 d1                	cmp    %edx,%ecx
f010299f:	77 20                	ja     f01029c1 <mem_init+0x13fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029a1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029a5:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f01029ac:	f0 
f01029ad:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01029b4:	00 
f01029b5:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f01029bc:	e8 7f d6 ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01029c1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029c8:	00 
f01029c9:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01029d0:	00 
	return (void *)(pa + KERNBASE);
f01029d1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029d6:	89 04 24             	mov    %eax,(%esp)
f01029d9:	e8 49 32 00 00       	call   f0105c27 <memset>
	page_free(pp0);
f01029de:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01029e1:	89 3c 24             	mov    %edi,(%esp)
f01029e4:	e8 93 e7 ff ff       	call   f010117c <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01029e9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01029f0:	00 
f01029f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01029f8:	00 
f01029f9:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01029fe:	89 04 24             	mov    %eax,(%esp)
f0102a01:	e8 d4 e7 ff ff       	call   f01011da <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a06:	89 fa                	mov    %edi,%edx
f0102a08:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0102a0e:	c1 fa 03             	sar    $0x3,%edx
f0102a11:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a14:	89 d0                	mov    %edx,%eax
f0102a16:	c1 e8 0c             	shr    $0xc,%eax
f0102a19:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0102a1f:	72 20                	jb     f0102a41 <mem_init+0x147e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a21:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102a25:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0102a2c:	f0 
f0102a2d:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0102a34:	00 
f0102a35:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f0102a3c:	e8 ff d5 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102a41:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102a47:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102a4a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102a50:	f6 00 01             	testb  $0x1,(%eax)
f0102a53:	74 24                	je     f0102a79 <mem_init+0x14b6>
f0102a55:	c7 44 24 0c a2 7b 10 	movl   $0xf0107ba2,0xc(%esp)
f0102a5c:	f0 
f0102a5d:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102a64:	f0 
f0102a65:	c7 44 24 04 75 04 00 	movl   $0x475,0x4(%esp)
f0102a6c:	00 
f0102a6d:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102a74:	e8 c7 d5 ff ff       	call   f0100040 <_panic>
f0102a79:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102a7c:	39 d0                	cmp    %edx,%eax
f0102a7e:	75 d0                	jne    f0102a50 <mem_init+0x148d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102a80:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102a85:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102a8b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a8e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102a94:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102a97:	89 0d 40 c2 22 f0    	mov    %ecx,0xf022c240

	// free the pages we took
	page_free(pp0);
f0102a9d:	89 04 24             	mov    %eax,(%esp)
f0102aa0:	e8 d7 e6 ff ff       	call   f010117c <page_free>
	page_free(pp1);
f0102aa5:	89 1c 24             	mov    %ebx,(%esp)
f0102aa8:	e8 cf e6 ff ff       	call   f010117c <page_free>
	page_free(pp2);
f0102aad:	89 34 24             	mov    %esi,(%esp)
f0102ab0:	e8 c7 e6 ff ff       	call   f010117c <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102ab5:	c7 44 24 04 01 10 00 	movl   $0x1001,0x4(%esp)
f0102abc:	00 
f0102abd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ac4:	e8 8d ea ff ff       	call   f0101556 <mmio_map_region>
f0102ac9:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102acb:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102ad2:	00 
f0102ad3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ada:	e8 77 ea ff ff       	call   f0101556 <mmio_map_region>
f0102adf:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102ae1:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102ae7:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102aec:	77 08                	ja     f0102af6 <mem_init+0x1533>
f0102aee:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102af4:	77 24                	ja     f0102b1a <mem_init+0x1557>
f0102af6:	c7 44 24 0c 54 75 10 	movl   $0xf0107554,0xc(%esp)
f0102afd:	f0 
f0102afe:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102b05:	f0 
f0102b06:	c7 44 24 04 85 04 00 	movl   $0x485,0x4(%esp)
f0102b0d:	00 
f0102b0e:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102b15:	e8 26 d5 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102b1a:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102b20:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102b26:	77 08                	ja     f0102b30 <mem_init+0x156d>
f0102b28:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102b2e:	77 24                	ja     f0102b54 <mem_init+0x1591>
f0102b30:	c7 44 24 0c 7c 75 10 	movl   $0xf010757c,0xc(%esp)
f0102b37:	f0 
f0102b38:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102b3f:	f0 
f0102b40:	c7 44 24 04 86 04 00 	movl   $0x486,0x4(%esp)
f0102b47:	00 
f0102b48:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102b4f:	e8 ec d4 ff ff       	call   f0100040 <_panic>
f0102b54:	89 da                	mov    %ebx,%edx
f0102b56:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102b58:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102b5e:	74 24                	je     f0102b84 <mem_init+0x15c1>
f0102b60:	c7 44 24 0c a4 75 10 	movl   $0xf01075a4,0xc(%esp)
f0102b67:	f0 
f0102b68:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102b6f:	f0 
f0102b70:	c7 44 24 04 88 04 00 	movl   $0x488,0x4(%esp)
f0102b77:	00 
f0102b78:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102b7f:	e8 bc d4 ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102b84:	39 c6                	cmp    %eax,%esi
f0102b86:	73 24                	jae    f0102bac <mem_init+0x15e9>
f0102b88:	c7 44 24 0c b9 7b 10 	movl   $0xf0107bb9,0xc(%esp)
f0102b8f:	f0 
f0102b90:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102b97:	f0 
f0102b98:	c7 44 24 04 8a 04 00 	movl   $0x48a,0x4(%esp)
f0102b9f:	00 
f0102ba0:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102ba7:	e8 94 d4 ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102bac:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f0102bb2:	89 da                	mov    %ebx,%edx
f0102bb4:	89 f8                	mov    %edi,%eax
f0102bb6:	e8 6a df ff ff       	call   f0100b25 <check_va2pa>
f0102bbb:	85 c0                	test   %eax,%eax
f0102bbd:	74 24                	je     f0102be3 <mem_init+0x1620>
f0102bbf:	c7 44 24 0c cc 75 10 	movl   $0xf01075cc,0xc(%esp)
f0102bc6:	f0 
f0102bc7:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102bce:	f0 
f0102bcf:	c7 44 24 04 8c 04 00 	movl   $0x48c,0x4(%esp)
f0102bd6:	00 
f0102bd7:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102bde:	e8 5d d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102be3:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102be9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102bec:	89 c2                	mov    %eax,%edx
f0102bee:	89 f8                	mov    %edi,%eax
f0102bf0:	e8 30 df ff ff       	call   f0100b25 <check_va2pa>
f0102bf5:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102bfa:	74 24                	je     f0102c20 <mem_init+0x165d>
f0102bfc:	c7 44 24 0c f0 75 10 	movl   $0xf01075f0,0xc(%esp)
f0102c03:	f0 
f0102c04:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102c0b:	f0 
f0102c0c:	c7 44 24 04 8d 04 00 	movl   $0x48d,0x4(%esp)
f0102c13:	00 
f0102c14:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102c1b:	e8 20 d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102c20:	89 f2                	mov    %esi,%edx
f0102c22:	89 f8                	mov    %edi,%eax
f0102c24:	e8 fc de ff ff       	call   f0100b25 <check_va2pa>
f0102c29:	85 c0                	test   %eax,%eax
f0102c2b:	74 24                	je     f0102c51 <mem_init+0x168e>
f0102c2d:	c7 44 24 0c 20 76 10 	movl   $0xf0107620,0xc(%esp)
f0102c34:	f0 
f0102c35:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102c3c:	f0 
f0102c3d:	c7 44 24 04 8e 04 00 	movl   $0x48e,0x4(%esp)
f0102c44:	00 
f0102c45:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102c4c:	e8 ef d3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102c51:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102c57:	89 f8                	mov    %edi,%eax
f0102c59:	e8 c7 de ff ff       	call   f0100b25 <check_va2pa>
f0102c5e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102c61:	74 24                	je     f0102c87 <mem_init+0x16c4>
f0102c63:	c7 44 24 0c 44 76 10 	movl   $0xf0107644,0xc(%esp)
f0102c6a:	f0 
f0102c6b:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102c72:	f0 
f0102c73:	c7 44 24 04 8f 04 00 	movl   $0x48f,0x4(%esp)
f0102c7a:	00 
f0102c7b:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102c82:	e8 b9 d3 ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102c87:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102c8e:	00 
f0102c8f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c93:	89 3c 24             	mov    %edi,(%esp)
f0102c96:	e8 3f e5 ff ff       	call   f01011da <pgdir_walk>
f0102c9b:	f6 00 1a             	testb  $0x1a,(%eax)
f0102c9e:	75 24                	jne    f0102cc4 <mem_init+0x1701>
f0102ca0:	c7 44 24 0c 70 76 10 	movl   $0xf0107670,0xc(%esp)
f0102ca7:	f0 
f0102ca8:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102caf:	f0 
f0102cb0:	c7 44 24 04 91 04 00 	movl   $0x491,0x4(%esp)
f0102cb7:	00 
f0102cb8:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102cbf:	e8 7c d3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102cc4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102ccb:	00 
f0102ccc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102cd0:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102cd5:	89 04 24             	mov    %eax,(%esp)
f0102cd8:	e8 fd e4 ff ff       	call   f01011da <pgdir_walk>
f0102cdd:	f6 00 04             	testb  $0x4,(%eax)
f0102ce0:	74 24                	je     f0102d06 <mem_init+0x1743>
f0102ce2:	c7 44 24 0c b4 76 10 	movl   $0xf01076b4,0xc(%esp)
f0102ce9:	f0 
f0102cea:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102cf1:	f0 
f0102cf2:	c7 44 24 04 92 04 00 	movl   $0x492,0x4(%esp)
f0102cf9:	00 
f0102cfa:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102d01:	e8 3a d3 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102d06:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102d0d:	00 
f0102d0e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102d12:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102d17:	89 04 24             	mov    %eax,(%esp)
f0102d1a:	e8 bb e4 ff ff       	call   f01011da <pgdir_walk>
f0102d1f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102d25:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102d2c:	00 
f0102d2d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d30:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d34:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102d39:	89 04 24             	mov    %eax,(%esp)
f0102d3c:	e8 99 e4 ff ff       	call   f01011da <pgdir_walk>
f0102d41:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102d47:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102d4e:	00 
f0102d4f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102d53:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102d58:	89 04 24             	mov    %eax,(%esp)
f0102d5b:	e8 7a e4 ff ff       	call   f01011da <pgdir_walk>
f0102d60:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102d66:	c7 04 24 cb 7b 10 f0 	movl   $0xf0107bcb,(%esp)
f0102d6d:	e8 44 13 00 00       	call   f01040b6 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f0102d72:	a1 90 ce 22 f0       	mov    0xf022ce90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d77:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d7c:	77 20                	ja     f0102d9e <mem_init+0x17db>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d7e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d82:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0102d89:	f0 
f0102d8a:	c7 44 24 04 bb 00 00 	movl   $0xbb,0x4(%esp)
f0102d91:	00 
f0102d92:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102d99:	e8 a2 d2 ff ff       	call   f0100040 <_panic>
f0102d9e:	8b 15 88 ce 22 f0    	mov    0xf022ce88,%edx
f0102da4:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102dab:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102db1:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102db8:	00 
	return (physaddr_t)kva - KERNBASE;
f0102db9:	05 00 00 00 10       	add    $0x10000000,%eax
f0102dbe:	89 04 24             	mov    %eax,(%esp)
f0102dc1:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102dc6:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102dcb:	e8 24 e5 ff ff       	call   f01012f4 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, ROUNDUP( (sizeof(struct Env)*NENV),PGSIZE), PADDR(envs), PTE_U);
f0102dd0:	a1 48 c2 22 f0       	mov    0xf022c248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102dd5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dda:	77 20                	ja     f0102dfc <mem_init+0x1839>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ddc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102de0:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0102de7:	f0 
f0102de8:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
f0102def:	00 
f0102df0:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102df7:	e8 44 d2 ff ff       	call   f0100040 <_panic>
f0102dfc:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102e03:	00 
	return (physaddr_t)kva - KERNBASE;
f0102e04:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e09:	89 04 24             	mov    %eax,(%esp)
f0102e0c:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102e11:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102e16:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102e1b:	e8 d4 e4 ff ff       	call   f01012f4 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e20:	b8 00 70 11 f0       	mov    $0xf0117000,%eax
f0102e25:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e2a:	77 20                	ja     f0102e4c <mem_init+0x1889>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e2c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e30:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0102e37:	f0 
f0102e38:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
f0102e3f:	00 
f0102e40:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102e47:	e8 f4 d1 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102e4c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102e53:	00 
f0102e54:	c7 04 24 00 70 11 00 	movl   $0x117000,(%esp)
f0102e5b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102e60:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102e65:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102e6a:	e8 85 e4 ff ff       	call   f01012f4 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE/* ~KERNBASE + 1 */, 0, 		PTE_W);
f0102e6f:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102e76:	00 
f0102e77:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e7e:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102e83:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102e88:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102e8d:	e8 62 e4 ff ff       	call   f01012f4 <boot_map_region>
f0102e92:	bf 00 e0 26 f0       	mov    $0xf026e000,%edi
f0102e97:	bb 00 e0 22 f0       	mov    $0xf022e000,%ebx
f0102e9c:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ea1:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102ea7:	77 20                	ja     f0102ec9 <mem_init+0x1906>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ea9:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102ead:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0102eb4:	f0 
f0102eb5:	c7 44 24 04 13 01 00 	movl   $0x113,0x4(%esp)
f0102ebc:	00 
f0102ebd:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102ec4:	e8 77 d1 ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:
	uint8_t i=0;
	size_t kstacktop_i;
	for (;i<NCPU;i++){
	kstacktop_i = KSTACKTOP -( i * (KSTKSIZE + KSTKGAP) );
	boot_map_region(kern_pgdir, kstacktop_i-KSTKSIZE, KSTKSIZE, PADDR((void *)percpu_kstacks[i]), PTE_W|PTE_P);
f0102ec9:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102ed0:	00 
f0102ed1:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102ed7:	89 04 24             	mov    %eax,(%esp)
f0102eda:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102edf:	89 f2                	mov    %esi,%edx
f0102ee1:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102ee6:	e8 09 e4 ff ff       	call   f01012f4 <boot_map_region>
f0102eeb:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102ef1:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//     Permissions: kernel RW, user NONE
	//boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
	// LAB 4: Your code here:
	uint8_t i=0;
	size_t kstacktop_i;
	for (;i<NCPU;i++){
f0102ef7:	39 fb                	cmp    %edi,%ebx
f0102ef9:	75 a6                	jne    f0102ea1 <mem_init+0x18de>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102efb:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102f01:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f0102f06:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102f09:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102f10:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102f15:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102f18:	8b 35 90 ce 22 f0    	mov    0xf022ce90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f1e:	89 75 cc             	mov    %esi,-0x34(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102f21:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0102f27:	89 45 c8             	mov    %eax,-0x38(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102f2a:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102f2f:	eb 6a                	jmp    f0102f9b <mem_init+0x19d8>
f0102f31:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102f37:	89 f8                	mov    %edi,%eax
f0102f39:	e8 e7 db ff ff       	call   f0100b25 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f3e:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102f45:	77 20                	ja     f0102f67 <mem_init+0x19a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f47:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102f4b:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0102f52:	f0 
f0102f53:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f0102f5a:	00 
f0102f5b:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102f62:	e8 d9 d0 ff ff       	call   f0100040 <_panic>
f0102f67:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102f6a:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f0102f6d:	39 d0                	cmp    %edx,%eax
f0102f6f:	74 24                	je     f0102f95 <mem_init+0x19d2>
f0102f71:	c7 44 24 0c e8 76 10 	movl   $0xf01076e8,0xc(%esp)
f0102f78:	f0 
f0102f79:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102f80:	f0 
f0102f81:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f0102f88:	00 
f0102f89:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102f90:	e8 ab d0 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102f95:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f9b:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102f9e:	77 91                	ja     f0102f31 <mem_init+0x196e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102fa0:	8b 1d 48 c2 22 f0    	mov    0xf022c248,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102fa6:	89 de                	mov    %ebx,%esi
f0102fa8:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102fad:	89 f8                	mov    %edi,%eax
f0102faf:	e8 71 db ff ff       	call   f0100b25 <check_va2pa>
f0102fb4:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102fba:	77 20                	ja     f0102fdc <mem_init+0x1a19>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102fbc:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102fc0:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0102fc7:	f0 
f0102fc8:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f0102fcf:	00 
f0102fd0:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0102fd7:	e8 64 d0 ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102fdc:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102fe1:	81 c6 00 00 40 21    	add    $0x21400000,%esi
f0102fe7:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0102fea:	39 d0                	cmp    %edx,%eax
f0102fec:	74 24                	je     f0103012 <mem_init+0x1a4f>
f0102fee:	c7 44 24 0c 1c 77 10 	movl   $0xf010771c,0xc(%esp)
f0102ff5:	f0 
f0102ff6:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0102ffd:	f0 
f0102ffe:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f0103005:	00 
f0103006:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010300d:	e8 2e d0 ff ff       	call   f0100040 <_panic>
f0103012:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0103018:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f010301e:	0f 85 a8 05 00 00    	jne    f01035cc <mem_init+0x2009>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0103024:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103027:	c1 e6 0c             	shl    $0xc,%esi
f010302a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010302f:	eb 3b                	jmp    f010306c <mem_init+0x1aa9>
f0103031:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0103037:	89 f8                	mov    %edi,%eax
f0103039:	e8 e7 da ff ff       	call   f0100b25 <check_va2pa>
f010303e:	39 c3                	cmp    %eax,%ebx
f0103040:	74 24                	je     f0103066 <mem_init+0x1aa3>
f0103042:	c7 44 24 0c 50 77 10 	movl   $0xf0107750,0xc(%esp)
f0103049:	f0 
f010304a:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0103051:	f0 
f0103052:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f0103059:	00 
f010305a:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0103061:	e8 da cf ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0103066:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010306c:	39 f3                	cmp    %esi,%ebx
f010306e:	72 c1                	jb     f0103031 <mem_init+0x1a6e>
f0103070:	c7 45 d0 00 e0 22 f0 	movl   $0xf022e000,-0x30(%ebp)
f0103077:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f010307e:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0103083:	b8 00 e0 22 f0       	mov    $0xf022e000,%eax
f0103088:	05 00 80 00 20       	add    $0x20008000,%eax
f010308d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103090:	8d 86 00 80 00 00    	lea    0x8000(%esi),%eax
f0103096:	89 45 cc             	mov    %eax,-0x34(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0103099:	89 f2                	mov    %esi,%edx
f010309b:	89 f8                	mov    %edi,%eax
f010309d:	e8 83 da ff ff       	call   f0100b25 <check_va2pa>
f01030a2:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01030a5:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f01030ab:	77 20                	ja     f01030cd <mem_init+0x1b0a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030ad:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01030b1:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f01030b8:	f0 
f01030b9:	c7 44 24 04 bb 03 00 	movl   $0x3bb,0x4(%esp)
f01030c0:	00 
f01030c1:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01030c8:	e8 73 cf ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030cd:	89 f3                	mov    %esi,%ebx
f01030cf:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01030d2:	03 4d d4             	add    -0x2c(%ebp),%ecx
f01030d5:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01030d8:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01030db:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f01030de:	39 c2                	cmp    %eax,%edx
f01030e0:	74 24                	je     f0103106 <mem_init+0x1b43>
f01030e2:	c7 44 24 0c 78 77 10 	movl   $0xf0107778,0xc(%esp)
f01030e9:	f0 
f01030ea:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01030f1:	f0 
f01030f2:	c7 44 24 04 bb 03 00 	movl   $0x3bb,0x4(%esp)
f01030f9:	00 
f01030fa:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0103101:	e8 3a cf ff ff       	call   f0100040 <_panic>
f0103106:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010310c:	3b 5d cc             	cmp    -0x34(%ebp),%ebx
f010310f:	0f 85 a9 04 00 00    	jne    f01035be <mem_init+0x1ffb>
f0103115:	8d 9e 00 80 ff ff    	lea    -0x8000(%esi),%ebx
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f010311b:	89 da                	mov    %ebx,%edx
f010311d:	89 f8                	mov    %edi,%eax
f010311f:	e8 01 da ff ff       	call   f0100b25 <check_va2pa>
f0103124:	83 f8 ff             	cmp    $0xffffffff,%eax
f0103127:	74 24                	je     f010314d <mem_init+0x1b8a>
f0103129:	c7 44 24 0c c0 77 10 	movl   $0xf01077c0,0xc(%esp)
f0103130:	f0 
f0103131:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0103138:	f0 
f0103139:	c7 44 24 04 bd 03 00 	movl   $0x3bd,0x4(%esp)
f0103140:	00 
f0103141:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0103148:	e8 f3 ce ff ff       	call   f0100040 <_panic>
f010314d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0103153:	39 de                	cmp    %ebx,%esi
f0103155:	75 c4                	jne    f010311b <mem_init+0x1b58>
f0103157:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f010315d:	81 45 d4 00 80 01 00 	addl   $0x18000,-0x2c(%ebp)
f0103164:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f010316b:	81 fe 00 80 f7 ef    	cmp    $0xeff78000,%esi
f0103171:	0f 85 19 ff ff ff    	jne    f0103090 <mem_init+0x1acd>
f0103177:	b8 00 00 00 00       	mov    $0x0,%eax
f010317c:	e9 c2 00 00 00       	jmp    f0103243 <mem_init+0x1c80>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0103181:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0103187:	83 fa 04             	cmp    $0x4,%edx
f010318a:	77 2e                	ja     f01031ba <mem_init+0x1bf7>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f010318c:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0103190:	0f 85 aa 00 00 00    	jne    f0103240 <mem_init+0x1c7d>
f0103196:	c7 44 24 0c e4 7b 10 	movl   $0xf0107be4,0xc(%esp)
f010319d:	f0 
f010319e:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01031a5:	f0 
f01031a6:	c7 44 24 04 c8 03 00 	movl   $0x3c8,0x4(%esp)
f01031ad:	00 
f01031ae:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01031b5:	e8 86 ce ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01031ba:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01031bf:	76 55                	jbe    f0103216 <mem_init+0x1c53>
				assert(pgdir[i] & PTE_P);
f01031c1:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01031c4:	f6 c2 01             	test   $0x1,%dl
f01031c7:	75 24                	jne    f01031ed <mem_init+0x1c2a>
f01031c9:	c7 44 24 0c e4 7b 10 	movl   $0xf0107be4,0xc(%esp)
f01031d0:	f0 
f01031d1:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01031d8:	f0 
f01031d9:	c7 44 24 04 cc 03 00 	movl   $0x3cc,0x4(%esp)
f01031e0:	00 
f01031e1:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01031e8:	e8 53 ce ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01031ed:	f6 c2 02             	test   $0x2,%dl
f01031f0:	75 4e                	jne    f0103240 <mem_init+0x1c7d>
f01031f2:	c7 44 24 0c f5 7b 10 	movl   $0xf0107bf5,0xc(%esp)
f01031f9:	f0 
f01031fa:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0103201:	f0 
f0103202:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f0103209:	00 
f010320a:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0103211:	e8 2a ce ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0103216:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010321a:	74 24                	je     f0103240 <mem_init+0x1c7d>
f010321c:	c7 44 24 0c 06 7c 10 	movl   $0xf0107c06,0xc(%esp)
f0103223:	f0 
f0103224:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010322b:	f0 
f010322c:	c7 44 24 04 cf 03 00 	movl   $0x3cf,0x4(%esp)
f0103233:	00 
f0103234:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010323b:	e8 00 ce ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0103240:	83 c0 01             	add    $0x1,%eax
f0103243:	3d 00 04 00 00       	cmp    $0x400,%eax
f0103248:	0f 85 33 ff ff ff    	jne    f0103181 <mem_init+0x1bbe>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010324e:	c7 04 24 e4 77 10 f0 	movl   $0xf01077e4,(%esp)
f0103255:	e8 5c 0e 00 00       	call   f01040b6 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010325a:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f010325f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103264:	77 20                	ja     f0103286 <mem_init+0x1cc3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103266:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010326a:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0103271:	f0 
f0103272:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
f0103279:	00 
f010327a:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0103281:	e8 ba cd ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103286:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010328b:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010328e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103293:	e8 9c d9 ff ff       	call   f0100c34 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0103298:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f010329b:	83 e0 f3             	and    $0xfffffff3,%eax
f010329e:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01032a3:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01032a6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01032ad:	e8 3f de ff ff       	call   f01010f1 <page_alloc>
f01032b2:	89 c3                	mov    %eax,%ebx
f01032b4:	85 c0                	test   %eax,%eax
f01032b6:	75 24                	jne    f01032dc <mem_init+0x1d19>
f01032b8:	c7 44 24 0c f0 79 10 	movl   $0xf01079f0,0xc(%esp)
f01032bf:	f0 
f01032c0:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01032c7:	f0 
f01032c8:	c7 44 24 04 a7 04 00 	movl   $0x4a7,0x4(%esp)
f01032cf:	00 
f01032d0:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01032d7:	e8 64 cd ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01032dc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01032e3:	e8 09 de ff ff       	call   f01010f1 <page_alloc>
f01032e8:	89 c7                	mov    %eax,%edi
f01032ea:	85 c0                	test   %eax,%eax
f01032ec:	75 24                	jne    f0103312 <mem_init+0x1d4f>
f01032ee:	c7 44 24 0c 06 7a 10 	movl   $0xf0107a06,0xc(%esp)
f01032f5:	f0 
f01032f6:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01032fd:	f0 
f01032fe:	c7 44 24 04 a8 04 00 	movl   $0x4a8,0x4(%esp)
f0103305:	00 
f0103306:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010330d:	e8 2e cd ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0103312:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103319:	e8 d3 dd ff ff       	call   f01010f1 <page_alloc>
f010331e:	89 c6                	mov    %eax,%esi
f0103320:	85 c0                	test   %eax,%eax
f0103322:	75 24                	jne    f0103348 <mem_init+0x1d85>
f0103324:	c7 44 24 0c 1c 7a 10 	movl   $0xf0107a1c,0xc(%esp)
f010332b:	f0 
f010332c:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0103333:	f0 
f0103334:	c7 44 24 04 a9 04 00 	movl   $0x4a9,0x4(%esp)
f010333b:	00 
f010333c:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0103343:	e8 f8 cc ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0103348:	89 1c 24             	mov    %ebx,(%esp)
f010334b:	e8 2c de ff ff       	call   f010117c <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0103350:	89 f8                	mov    %edi,%eax
f0103352:	e8 89 d7 ff ff       	call   f0100ae0 <page2kva>
f0103357:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010335e:	00 
f010335f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0103366:	00 
f0103367:	89 04 24             	mov    %eax,(%esp)
f010336a:	e8 b8 28 00 00       	call   f0105c27 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f010336f:	89 f0                	mov    %esi,%eax
f0103371:	e8 6a d7 ff ff       	call   f0100ae0 <page2kva>
f0103376:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010337d:	00 
f010337e:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0103385:	00 
f0103386:	89 04 24             	mov    %eax,(%esp)
f0103389:	e8 99 28 00 00       	call   f0105c27 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010338e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103395:	00 
f0103396:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010339d:	00 
f010339e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033a2:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01033a7:	89 04 24             	mov    %eax,(%esp)
f01033aa:	e8 cb e0 ff ff       	call   f010147a <page_insert>
	assert(pp1->pp_ref == 1);
f01033af:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01033b4:	74 24                	je     f01033da <mem_init+0x1e17>
f01033b6:	c7 44 24 0c ed 7a 10 	movl   $0xf0107aed,0xc(%esp)
f01033bd:	f0 
f01033be:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01033c5:	f0 
f01033c6:	c7 44 24 04 ae 04 00 	movl   $0x4ae,0x4(%esp)
f01033cd:	00 
f01033ce:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01033d5:	e8 66 cc ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01033da:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01033e1:	01 01 01 
f01033e4:	74 24                	je     f010340a <mem_init+0x1e47>
f01033e6:	c7 44 24 0c 04 78 10 	movl   $0xf0107804,0xc(%esp)
f01033ed:	f0 
f01033ee:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01033f5:	f0 
f01033f6:	c7 44 24 04 af 04 00 	movl   $0x4af,0x4(%esp)
f01033fd:	00 
f01033fe:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0103405:	e8 36 cc ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010340a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103411:	00 
f0103412:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103419:	00 
f010341a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010341e:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0103423:	89 04 24             	mov    %eax,(%esp)
f0103426:	e8 4f e0 ff ff       	call   f010147a <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010342b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103432:	02 02 02 
f0103435:	74 24                	je     f010345b <mem_init+0x1e98>
f0103437:	c7 44 24 0c 28 78 10 	movl   $0xf0107828,0xc(%esp)
f010343e:	f0 
f010343f:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0103446:	f0 
f0103447:	c7 44 24 04 b1 04 00 	movl   $0x4b1,0x4(%esp)
f010344e:	00 
f010344f:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0103456:	e8 e5 cb ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010345b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103460:	74 24                	je     f0103486 <mem_init+0x1ec3>
f0103462:	c7 44 24 0c 0f 7b 10 	movl   $0xf0107b0f,0xc(%esp)
f0103469:	f0 
f010346a:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0103471:	f0 
f0103472:	c7 44 24 04 b2 04 00 	movl   $0x4b2,0x4(%esp)
f0103479:	00 
f010347a:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0103481:	e8 ba cb ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0103486:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010348b:	74 24                	je     f01034b1 <mem_init+0x1eee>
f010348d:	c7 44 24 0c 79 7b 10 	movl   $0xf0107b79,0xc(%esp)
f0103494:	f0 
f0103495:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010349c:	f0 
f010349d:	c7 44 24 04 b3 04 00 	movl   $0x4b3,0x4(%esp)
f01034a4:	00 
f01034a5:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01034ac:	e8 8f cb ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01034b1:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01034b8:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01034bb:	89 f0                	mov    %esi,%eax
f01034bd:	e8 1e d6 ff ff       	call   f0100ae0 <page2kva>
f01034c2:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f01034c8:	74 24                	je     f01034ee <mem_init+0x1f2b>
f01034ca:	c7 44 24 0c 4c 78 10 	movl   $0xf010784c,0xc(%esp)
f01034d1:	f0 
f01034d2:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f01034d9:	f0 
f01034da:	c7 44 24 04 b5 04 00 	movl   $0x4b5,0x4(%esp)
f01034e1:	00 
f01034e2:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f01034e9:	e8 52 cb ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01034ee:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01034f5:	00 
f01034f6:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01034fb:	89 04 24             	mov    %eax,(%esp)
f01034fe:	e8 20 df ff ff       	call   f0101423 <page_remove>
	assert(pp2->pp_ref == 0);
f0103503:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0103508:	74 24                	je     f010352e <mem_init+0x1f6b>
f010350a:	c7 44 24 0c 47 7b 10 	movl   $0xf0107b47,0xc(%esp)
f0103511:	f0 
f0103512:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0103519:	f0 
f010351a:	c7 44 24 04 b7 04 00 	movl   $0x4b7,0x4(%esp)
f0103521:	00 
f0103522:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f0103529:	e8 12 cb ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010352e:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0103533:	8b 08                	mov    (%eax),%ecx
f0103535:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010353b:	89 da                	mov    %ebx,%edx
f010353d:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0103543:	c1 fa 03             	sar    $0x3,%edx
f0103546:	c1 e2 0c             	shl    $0xc,%edx
f0103549:	39 d1                	cmp    %edx,%ecx
f010354b:	74 24                	je     f0103571 <mem_init+0x1fae>
f010354d:	c7 44 24 0c d4 71 10 	movl   $0xf01071d4,0xc(%esp)
f0103554:	f0 
f0103555:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010355c:	f0 
f010355d:	c7 44 24 04 ba 04 00 	movl   $0x4ba,0x4(%esp)
f0103564:	00 
f0103565:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010356c:	e8 cf ca ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0103571:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0103577:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010357c:	74 24                	je     f01035a2 <mem_init+0x1fdf>
f010357e:	c7 44 24 0c fe 7a 10 	movl   $0xf0107afe,0xc(%esp)
f0103585:	f0 
f0103586:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010358d:	f0 
f010358e:	c7 44 24 04 bc 04 00 	movl   $0x4bc,0x4(%esp)
f0103595:	00 
f0103596:	c7 04 24 e7 78 10 f0 	movl   $0xf01078e7,(%esp)
f010359d:	e8 9e ca ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01035a2:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01035a8:	89 1c 24             	mov    %ebx,(%esp)
f01035ab:	e8 cc db ff ff       	call   f010117c <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01035b0:	c7 04 24 78 78 10 f0 	movl   $0xf0107878,(%esp)
f01035b7:	e8 fa 0a 00 00       	call   f01040b6 <cprintf>
f01035bc:	eb 1c                	jmp    f01035da <mem_init+0x2017>
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01035be:	89 da                	mov    %ebx,%edx
f01035c0:	89 f8                	mov    %edi,%eax
f01035c2:	e8 5e d5 ff ff       	call   f0100b25 <check_va2pa>
f01035c7:	e9 0c fb ff ff       	jmp    f01030d8 <mem_init+0x1b15>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01035cc:	89 da                	mov    %ebx,%edx
f01035ce:	89 f8                	mov    %edi,%eax
f01035d0:	e8 50 d5 ff ff       	call   f0100b25 <check_va2pa>
f01035d5:	e9 0d fa ff ff       	jmp    f0102fe7 <mem_init+0x1a24>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01035da:	83 c4 4c             	add    $0x4c,%esp
f01035dd:	5b                   	pop    %ebx
f01035de:	5e                   	pop    %esi
f01035df:	5f                   	pop    %edi
f01035e0:	5d                   	pop    %ebp
f01035e1:	c3                   	ret    

f01035e2 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01035e2:	55                   	push   %ebp
f01035e3:	89 e5                	mov    %esp,%ebp
f01035e5:	57                   	push   %edi
f01035e6:	56                   	push   %esi
f01035e7:	53                   	push   %ebx
f01035e8:	83 ec 2c             	sub    $0x2c,%esp
f01035eb:	8b 7d 08             	mov    0x8(%ebp),%edi
f01035ee:	8b 75 14             	mov    0x14(%ebp),%esi

	// LAB 3: Your code here.
	struct PageInfo *pg;
	pte_t *pte;
	pte_t **pte_store=&pte;
	uintptr_t end = ROUNDUP((uintptr_t)(va+len),PGSIZE);
f01035f1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035f4:	03 45 10             	add    0x10(%ebp),%eax
f01035f7:	05 ff 0f 00 00       	add    $0xfff,%eax
f01035fc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0103601:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	uintptr_t start_addr = ROUNDDOWN((uintptr_t)va , PGSIZE) ; 
f0103604:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103607:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx

    for( ; start_addr < end  ; start_addr +=PGSIZE ){
f010360d:	eb 47                	jmp    f0103656 <user_mem_check+0x74>
	   pg=page_lookup(env->env_pgdir,(void*)start_addr,pte_store);
f010360f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103612:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103616:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010361a:	8b 47 60             	mov    0x60(%edi),%eax
f010361d:	89 04 24             	mov    %eax,(%esp)
f0103620:	e8 50 dd ff ff       	call   f0101375 <page_lookup>
       if( (!pg) || ((**pte_store & perm) != perm) || 
f0103625:	85 c0                	test   %eax,%eax
f0103627:	74 13                	je     f010363c <user_mem_check+0x5a>
f0103629:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010362c:	89 f2                	mov    %esi,%edx
f010362e:	23 10                	and    (%eax),%edx
f0103630:	39 d6                	cmp    %edx,%esi
f0103632:	75 08                	jne    f010363c <user_mem_check+0x5a>
f0103634:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010363a:	76 14                	jbe    f0103650 <user_mem_check+0x6e>
f010363c:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f010363f:	0f 42 5d 0c          	cmovb  0xc(%ebp),%ebx
	    start_addr >= ULIM){
	    user_mem_check_addr = start_addr<(uintptr_t )va ?(uintptr_t )va: 		    start_addr;
f0103643:	89 1d 3c c2 22 f0    	mov    %ebx,0xf022c23c
		return -E_FAULT;
f0103649:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010364e:	eb 10                	jmp    f0103660 <user_mem_check+0x7e>
	pte_t *pte;
	pte_t **pte_store=&pte;
	uintptr_t end = ROUNDUP((uintptr_t)(va+len),PGSIZE);
	uintptr_t start_addr = ROUNDDOWN((uintptr_t)va , PGSIZE) ; 

    for( ; start_addr < end  ; start_addr +=PGSIZE ){
f0103650:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103656:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0103659:	72 b4                	jb     f010360f <user_mem_check+0x2d>
	    start_addr >= ULIM){
	    user_mem_check_addr = start_addr<(uintptr_t )va ?(uintptr_t )va: 		    start_addr;
		return -E_FAULT;
	    }    
    }
	return 0;
f010365b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103660:	83 c4 2c             	add    $0x2c,%esp
f0103663:	5b                   	pop    %ebx
f0103664:	5e                   	pop    %esi
f0103665:	5f                   	pop    %edi
f0103666:	5d                   	pop    %ebp
f0103667:	c3                   	ret    

f0103668 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0103668:	55                   	push   %ebp
f0103669:	89 e5                	mov    %esp,%ebp
f010366b:	53                   	push   %ebx
f010366c:	83 ec 14             	sub    $0x14,%esp
f010366f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0103672:	8b 45 14             	mov    0x14(%ebp),%eax
f0103675:	83 c8 04             	or     $0x4,%eax
f0103678:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010367c:	8b 45 10             	mov    0x10(%ebp),%eax
f010367f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103683:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103686:	89 44 24 04          	mov    %eax,0x4(%esp)
f010368a:	89 1c 24             	mov    %ebx,(%esp)
f010368d:	e8 50 ff ff ff       	call   f01035e2 <user_mem_check>
f0103692:	85 c0                	test   %eax,%eax
f0103694:	79 24                	jns    f01036ba <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f0103696:	a1 3c c2 22 f0       	mov    0xf022c23c,%eax
f010369b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010369f:	8b 43 48             	mov    0x48(%ebx),%eax
f01036a2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036a6:	c7 04 24 a4 78 10 f0 	movl   $0xf01078a4,(%esp)
f01036ad:	e8 04 0a 00 00       	call   f01040b6 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01036b2:	89 1c 24             	mov    %ebx,(%esp)
f01036b5:	e8 08 07 00 00       	call   f0103dc2 <env_destroy>
	}
}
f01036ba:	83 c4 14             	add    $0x14,%esp
f01036bd:	5b                   	pop    %ebx
f01036be:	5d                   	pop    %ebp
f01036bf:	c3                   	ret    

f01036c0 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01036c0:	55                   	push   %ebp
f01036c1:	89 e5                	mov    %esp,%ebp
f01036c3:	57                   	push   %edi
f01036c4:	56                   	push   %esi
f01036c5:	53                   	push   %ebx
f01036c6:	83 ec 1c             	sub    $0x1c,%esp
f01036c9:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	struct PageInfo *pg; 
	uintptr_t start_va=ROUNDDOWN( (uintptr_t)va,PGSIZE);
f01036cb:	89 d3                	mov    %edx,%ebx
f01036cd:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t end_lim =ROUNDUP( (uintptr_t)va+len,PGSIZE );	
f01036d3:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01036da:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	//int i=0;
	for( ; start_va < end_lim; start_va+= PGSIZE ){	
f01036e0:	eb 4d                	jmp    f010372f <region_alloc+0x6f>
		pg=page_alloc(0);
f01036e2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01036e9:	e8 03 da ff ff       	call   f01010f1 <page_alloc>
		if(pg==NULL)
f01036ee:	85 c0                	test   %eax,%eax
f01036f0:	75 1c                	jne    f010370e <region_alloc+0x4e>
		  panic("region_alloc :page_alloc returned null ");	
f01036f2:	c7 44 24 08 14 7c 10 	movl   $0xf0107c14,0x8(%esp)
f01036f9:	f0 
f01036fa:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
f0103701:	00 
f0103702:	c7 04 24 cb 7c 10 f0 	movl   $0xf0107ccb,(%esp)
f0103709:	e8 32 c9 ff ff       	call   f0100040 <_panic>
		page_insert(e->env_pgdir,pg,(void *)start_va,PTE_U|PTE_P|PTE_W);
f010370e:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
f0103715:	00 
f0103716:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010371a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010371e:	8b 47 60             	mov    0x60(%edi),%eax
f0103721:	89 04 24             	mov    %eax,(%esp)
f0103724:	e8 51 dd ff ff       	call   f010147a <page_insert>
	//   (Watch out for corner-cases!)
	struct PageInfo *pg; 
	uintptr_t start_va=ROUNDDOWN( (uintptr_t)va,PGSIZE);
	uintptr_t end_lim =ROUNDUP( (uintptr_t)va+len,PGSIZE );	
	//int i=0;
	for( ; start_va < end_lim; start_va+= PGSIZE ){	
f0103729:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010372f:	39 f3                	cmp    %esi,%ebx
f0103731:	72 af                	jb     f01036e2 <region_alloc+0x22>
		if(pg==NULL)
		  panic("region_alloc :page_alloc returned null ");	
		page_insert(e->env_pgdir,pg,(void *)start_va,PTE_U|PTE_P|PTE_W);
	}

}
f0103733:	83 c4 1c             	add    $0x1c,%esp
f0103736:	5b                   	pop    %ebx
f0103737:	5e                   	pop    %esi
f0103738:	5f                   	pop    %edi
f0103739:	5d                   	pop    %ebp
f010373a:	c3                   	ret    

f010373b <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010373b:	55                   	push   %ebp
f010373c:	89 e5                	mov    %esp,%ebp
f010373e:	56                   	push   %esi
f010373f:	53                   	push   %ebx
f0103740:	8b 45 08             	mov    0x8(%ebp),%eax
f0103743:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103746:	85 c0                	test   %eax,%eax
f0103748:	75 1a                	jne    f0103764 <envid2env+0x29>
		*env_store = curenv;
f010374a:	e8 2a 2b 00 00       	call   f0106279 <cpunum>
f010374f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103752:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103758:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010375b:	89 01                	mov    %eax,(%ecx)
		return 0;
f010375d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103762:	eb 70                	jmp    f01037d4 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103764:	89 c3                	mov    %eax,%ebx
f0103766:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f010376c:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f010376f:	03 1d 48 c2 22 f0    	add    0xf022c248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103775:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103779:	74 05                	je     f0103780 <envid2env+0x45>
f010377b:	39 43 48             	cmp    %eax,0x48(%ebx)
f010377e:	74 10                	je     f0103790 <envid2env+0x55>
		*env_store = 0;
f0103780:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103783:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103789:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010378e:	eb 44                	jmp    f01037d4 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103790:	84 d2                	test   %dl,%dl
f0103792:	74 36                	je     f01037ca <envid2env+0x8f>
f0103794:	e8 e0 2a 00 00       	call   f0106279 <cpunum>
f0103799:	6b c0 74             	imul   $0x74,%eax,%eax
f010379c:	39 98 28 d0 22 f0    	cmp    %ebx,-0xfdd2fd8(%eax)
f01037a2:	74 26                	je     f01037ca <envid2env+0x8f>
f01037a4:	8b 73 4c             	mov    0x4c(%ebx),%esi
f01037a7:	e8 cd 2a 00 00       	call   f0106279 <cpunum>
f01037ac:	6b c0 74             	imul   $0x74,%eax,%eax
f01037af:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01037b5:	3b 70 48             	cmp    0x48(%eax),%esi
f01037b8:	74 10                	je     f01037ca <envid2env+0x8f>
		*env_store = 0;
f01037ba:	8b 45 0c             	mov    0xc(%ebp),%eax
f01037bd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01037c3:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01037c8:	eb 0a                	jmp    f01037d4 <envid2env+0x99>
	}

	*env_store = e;
f01037ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01037cd:	89 18                	mov    %ebx,(%eax)
	return 0;
f01037cf:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01037d4:	5b                   	pop    %ebx
f01037d5:	5e                   	pop    %esi
f01037d6:	5d                   	pop    %ebp
f01037d7:	c3                   	ret    

f01037d8 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01037d8:	55                   	push   %ebp
f01037d9:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01037db:	b8 20 13 12 f0       	mov    $0xf0121320,%eax
f01037e0:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01037e3:	b8 23 00 00 00       	mov    $0x23,%eax
f01037e8:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01037ea:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01037ec:	b0 10                	mov    $0x10,%al
f01037ee:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01037f0:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01037f2:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01037f4:	ea fb 37 10 f0 08 00 	ljmp   $0x8,$0xf01037fb
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01037fb:	b0 00                	mov    $0x0,%al
f01037fd:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103800:	5d                   	pop    %ebp
f0103801:	c3                   	ret    

f0103802 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103802:	8b 0d 4c c2 22 f0    	mov    0xf022c24c,%ecx
f0103808:	a1 48 c2 22 f0       	mov    0xf022c248,%eax
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i=0;i<NENV;i++){
		envs[i].env_id =0;	
f010380d:	ba 00 04 00 00       	mov    $0x400,%edx
f0103812:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_parent_id = 0;
f0103819:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
		envs[i].env_type = 0;
f0103820:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
		envs[i].env_status = ENV_FREE;
f0103827:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_runs = 0;
f010382e:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
		envs[i].env_pgdir = NULL;
f0103835:	c7 40 60 00 00 00 00 	movl   $0x0,0x60(%eax)
		if (!(env_free_list))
f010383c:	85 c9                	test   %ecx,%ecx
f010383e:	74 05                	je     f0103845 <env_init+0x43>
		env_free_list = &envs[i];
		else
		envs[i-1].env_link=&envs[i];	
f0103840:	89 40 c8             	mov    %eax,-0x38(%eax)
f0103843:	eb 02                	jmp    f0103847 <env_init+0x45>
		envs[i].env_type = 0;
		envs[i].env_status = ENV_FREE;
		envs[i].env_runs = 0;
		envs[i].env_pgdir = NULL;
		if (!(env_free_list))
		env_free_list = &envs[i];
f0103845:	89 c1                	mov    %eax,%ecx
f0103847:	83 c0 7c             	add    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i=0;i<NENV;i++){
f010384a:	83 ea 01             	sub    $0x1,%edx
f010384d:	75 c3                	jne    f0103812 <env_init+0x10>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f010384f:	55                   	push   %ebp
f0103850:	89 e5                	mov    %esp,%ebp
f0103852:	89 0d 4c c2 22 f0    	mov    %ecx,0xf022c24c
		if (!(env_free_list))
		env_free_list = &envs[i];
		else
		envs[i-1].env_link=&envs[i];	
	}
		envs[NENV - 1].env_link = NULL;
f0103858:	a1 48 c2 22 f0       	mov    0xf022c248,%eax
f010385d:	c7 80 c8 ef 01 00 00 	movl   $0x0,0x1efc8(%eax)
f0103864:	00 00 00 
	// Per-CPU part of the initialization
	env_init_percpu();
f0103867:	e8 6c ff ff ff       	call   f01037d8 <env_init_percpu>
}
f010386c:	5d                   	pop    %ebp
f010386d:	c3                   	ret    

f010386e <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f010386e:	55                   	push   %ebp
f010386f:	89 e5                	mov    %esp,%ebp
f0103871:	53                   	push   %ebx
f0103872:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103875:	8b 1d 4c c2 22 f0    	mov    0xf022c24c,%ebx
f010387b:	85 db                	test   %ebx,%ebx
f010387d:	0f 84 a2 01 00 00    	je     f0103a25 <env_alloc+0x1b7>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103883:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010388a:	e8 62 d8 ff ff       	call   f01010f1 <page_alloc>
f010388f:	85 c0                	test   %eax,%eax
f0103891:	0f 84 95 01 00 00    	je     f0103a2c <env_alloc+0x1be>
f0103897:	89 c2                	mov    %eax,%edx
f0103899:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f010389f:	c1 fa 03             	sar    $0x3,%edx
f01038a2:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01038a5:	89 d1                	mov    %edx,%ecx
f01038a7:	c1 e9 0c             	shr    $0xc,%ecx
f01038aa:	3b 0d 88 ce 22 f0    	cmp    0xf022ce88,%ecx
f01038b0:	72 20                	jb     f01038d2 <env_alloc+0x64>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01038b2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01038b6:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f01038bd:	f0 
f01038be:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01038c5:	00 
f01038c6:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f01038cd:	e8 6e c7 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01038d2:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01038d8:	89 53 60             	mov    %edx,0x60(%ebx)

	// LAB 3: Your code here.

	//set e->env_pgdir
	e->env_pgdir =page2kva(p);
	p->pp_ref++;
f01038db:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f01038e0:	b8 00 00 00 00       	mov    $0x0,%eax
	//clear env_pgdir before mapping
 	for (i = 0; i != PDX(UTOP); ++i)
        e->env_pgdir[i] = 0;
f01038e5:	8b 53 60             	mov    0x60(%ebx),%edx
f01038e8:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f01038ef:	83 c0 04             	add    $0x4,%eax

	//set e->env_pgdir
	e->env_pgdir =page2kva(p);
	p->pp_ref++;
	//clear env_pgdir before mapping
 	for (i = 0; i != PDX(UTOP); ++i)
f01038f2:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01038f7:	75 ec                	jne    f01038e5 <env_alloc+0x77>
        e->env_pgdir[i] = 0;
	
	for(i= PDX(UTOP);i<NPDENTRIES;i++){
		e->env_pgdir[i] = kern_pgdir[i];
f01038f9:	8b 15 8c ce 22 f0    	mov    0xf022ce8c,%edx
f01038ff:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103902:	8b 53 60             	mov    0x60(%ebx),%edx
f0103905:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0103908:	83 c0 04             	add    $0x4,%eax
	p->pp_ref++;
	//clear env_pgdir before mapping
 	for (i = 0; i != PDX(UTOP); ++i)
        e->env_pgdir[i] = 0;
	
	for(i= PDX(UTOP);i<NPDENTRIES;i++){
f010390b:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0103910:	75 e7                	jne    f01038f9 <env_alloc+0x8b>
		e->env_pgdir[i] = kern_pgdir[i];
	}
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103912:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103915:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010391a:	77 20                	ja     f010393c <env_alloc+0xce>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010391c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103920:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0103927:	f0 
f0103928:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
f010392f:	00 
f0103930:	c7 04 24 cb 7c 10 f0 	movl   $0xf0107ccb,(%esp)
f0103937:	e8 04 c7 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010393c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103942:	83 ca 05             	or     $0x5,%edx
f0103945:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010394b:	8b 43 48             	mov    0x48(%ebx),%eax
f010394e:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103953:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103958:	ba 00 10 00 00       	mov    $0x1000,%edx
f010395d:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103960:	89 da                	mov    %ebx,%edx
f0103962:	2b 15 48 c2 22 f0    	sub    0xf022c248,%edx
f0103968:	c1 fa 02             	sar    $0x2,%edx
f010396b:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0103971:	09 d0                	or     %edx,%eax
f0103973:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103976:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103979:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010397c:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103983:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f010398a:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103991:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103998:	00 
f0103999:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01039a0:	00 
f01039a1:	89 1c 24             	mov    %ebx,(%esp)
f01039a4:	e8 7e 22 00 00       	call   f0105c27 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01039a9:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01039af:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01039b5:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01039bb:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01039c2:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f01039c8:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f01039cf:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f01039d3:	8b 43 44             	mov    0x44(%ebx),%eax
f01039d6:	a3 4c c2 22 f0       	mov    %eax,0xf022c24c
	*newenv_store = e;
f01039db:	8b 45 08             	mov    0x8(%ebp),%eax
f01039de:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01039e0:	8b 5b 48             	mov    0x48(%ebx),%ebx
f01039e3:	e8 91 28 00 00       	call   f0106279 <cpunum>
f01039e8:	6b d0 74             	imul   $0x74,%eax,%edx
f01039eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01039f0:	83 ba 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%edx)
f01039f7:	74 11                	je     f0103a0a <env_alloc+0x19c>
f01039f9:	e8 7b 28 00 00       	call   f0106279 <cpunum>
f01039fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a01:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103a07:	8b 40 48             	mov    0x48(%eax),%eax
f0103a0a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103a0e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a12:	c7 04 24 d6 7c 10 f0 	movl   $0xf0107cd6,(%esp)
f0103a19:	e8 98 06 00 00       	call   f01040b6 <cprintf>
	return 0;
f0103a1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a23:	eb 0c                	jmp    f0103a31 <env_alloc+0x1c3>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103a25:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103a2a:	eb 05                	jmp    f0103a31 <env_alloc+0x1c3>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103a2c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103a31:	83 c4 14             	add    $0x14,%esp
f0103a34:	5b                   	pop    %ebx
f0103a35:	5d                   	pop    %ebp
f0103a36:	c3                   	ret    

f0103a37 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103a37:	55                   	push   %ebp
f0103a38:	89 e5                	mov    %esp,%ebp
f0103a3a:	57                   	push   %edi
f0103a3b:	56                   	push   %esi
f0103a3c:	53                   	push   %ebx
f0103a3d:	83 ec 3c             	sub    $0x3c,%esp
f0103a40:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r;
	envid_t parent_id=0;
	if ( ( r=env_alloc(&e, parent_id)) !=0  )
f0103a43:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103a4a:	00 
f0103a4b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103a4e:	89 04 24             	mov    %eax,(%esp)
f0103a51:	e8 18 fe ff ff       	call   f010386e <env_alloc>
f0103a56:	85 c0                	test   %eax,%eax
f0103a58:	74 20                	je     f0103a7a <env_create+0x43>
	    panic("env_create: env_alloc failed with error %e \n",r);
f0103a5a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a5e:	c7 44 24 08 3c 7c 10 	movl   $0xf0107c3c,0x8(%esp)
f0103a65:	f0 
f0103a66:	c7 44 24 04 b0 01 00 	movl   $0x1b0,0x4(%esp)
f0103a6d:	00 
f0103a6e:	c7 04 24 cb 7c 10 f0 	movl   $0xf0107ccb,(%esp)
f0103a75:	e8 c6 c5 ff ff       	call   f0100040 <_panic>

	//load the elf binary
	load_icode(e,binary);
f0103a7a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a7d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Check ELF header
	struct Proghdr *ph, *eph;
	int i;
	struct Elf* ELFHDR=(struct Elf*)(binary);

	if(ELFHDR->e_magic != ELF_MAGIC)
f0103a80:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103a86:	74 1c                	je     f0103aa4 <env_create+0x6d>
	    panic("load_icode: binary not in ELF format\n");
f0103a88:	c7 44 24 08 6c 7c 10 	movl   $0xf0107c6c,0x8(%esp)
f0103a8f:	f0 
f0103a90:	c7 44 24 04 7b 01 00 	movl   $0x17b,0x4(%esp)
f0103a97:	00 
f0103a98:	c7 04 24 cb 7c 10 f0 	movl   $0xf0107ccb,(%esp)
f0103a9f:	e8 9c c5 ff ff       	call   f0100040 <_panic>

	
	//load environment page dir for memmove to work properly
	lcr3(PADDR(e->env_pgdir));
f0103aa4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103aa7:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103aaa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103aaf:	77 20                	ja     f0103ad1 <env_create+0x9a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103ab1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ab5:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0103abc:	f0 
f0103abd:	c7 44 24 04 7f 01 00 	movl   $0x17f,0x4(%esp)
f0103ac4:	00 
f0103ac5:	c7 04 24 cb 7c 10 f0 	movl   $0xf0107ccb,(%esp)
f0103acc:	e8 6f c5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103ad1:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103ad6:	0f 22 d8             	mov    %eax,%cr3
	ph=(struct Proghdr *) (binary + ELFHDR->e_phoff);
f0103ad9:	89 fb                	mov    %edi,%ebx
f0103adb:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph=ph + ELFHDR->e_phnum;
f0103ade:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103ae2:	c1 e6 05             	shl    $0x5,%esi
f0103ae5:	01 de                	add    %ebx,%esi
f0103ae7:	eb 71                	jmp    f0103b5a <env_create+0x123>
	
	for(;ph<eph; ph++){
	    if(ph->p_type != ELF_PROG_LOAD)
f0103ae9:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103aec:	75 69                	jne    f0103b57 <env_create+0x120>
	        continue;
		
	    if(ph->p_memsz < ph->p_filesz)
f0103aee:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103af1:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f0103af4:	73 1c                	jae    f0103b12 <env_create+0xdb>
		panic("load_icode: file size is greater than memory available");
f0103af6:	c7 44 24 08 94 7c 10 	movl   $0xf0107c94,0x8(%esp)
f0103afd:	f0 
f0103afe:	c7 44 24 04 88 01 00 	movl   $0x188,0x4(%esp)
f0103b05:	00 
f0103b06:	c7 04 24 cb 7c 10 f0 	movl   $0xf0107ccb,(%esp)
f0103b0d:	e8 2e c5 ff ff       	call   f0100040 <_panic>
		
	//allocate and map pages for each segment
	    region_alloc(e, (void*)(ph->p_va), ph->p_memsz);
f0103b12:	8b 53 08             	mov    0x8(%ebx),%edx
f0103b15:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103b18:	e8 a3 fb ff ff       	call   f01036c0 <region_alloc>
			
	//  The ph->p_filesz bytes from the ELF binary, starting at
	//  'binary + ph->p_offset', should be copied to virtual address
	//  ph->p_va.
            memmove((void*)(ph->p_va), binary+ph->p_offset,ph->p_filesz);
f0103b1d:	8b 43 10             	mov    0x10(%ebx),%eax
f0103b20:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103b24:	89 f8                	mov    %edi,%eax
f0103b26:	03 43 04             	add    0x4(%ebx),%eax
f0103b29:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b2d:	8b 43 08             	mov    0x8(%ebx),%eax
f0103b30:	89 04 24             	mov    %eax,(%esp)
f0103b33:	e8 3c 21 00 00       	call   f0105c74 <memmove>
	// Any remaining memory bytes should be cleared to zero
	    memset( (void *)(ph->p_va+ph->p_filesz),0,(ph->p_memsz - ph->p_filesz));
f0103b38:	8b 43 10             	mov    0x10(%ebx),%eax
f0103b3b:	8b 53 14             	mov    0x14(%ebx),%edx
f0103b3e:	29 c2                	sub    %eax,%edx
f0103b40:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103b44:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103b4b:	00 
f0103b4c:	03 43 08             	add    0x8(%ebx),%eax
f0103b4f:	89 04 24             	mov    %eax,(%esp)
f0103b52:	e8 d0 20 00 00       	call   f0105c27 <memset>
	//load environment page dir for memmove to work properly
	lcr3(PADDR(e->env_pgdir));
	ph=(struct Proghdr *) (binary + ELFHDR->e_phoff);
	eph=ph + ELFHDR->e_phnum;
	
	for(;ph<eph; ph++){
f0103b57:	83 c3 20             	add    $0x20,%ebx
f0103b5a:	39 de                	cmp    %ebx,%esi
f0103b5c:	77 8b                	ja     f0103ae9 <env_create+0xb2>
	    memset( (void *)(ph->p_va+ph->p_filesz),0,(ph->p_memsz - ph->p_filesz));
	}
	
	//  You must also do something with the program's entry point,
	//  to make sure that the environment starts executing there.
	    e->env_tf.tf_eip=ELFHDR->e_entry;
f0103b5e:	8b 47 18             	mov    0x18(%edi),%eax
f0103b61:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103b64:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	    region_alloc(e, (void*)(USTACKTOP - PGSIZE),PGSIZE);
f0103b67:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103b6c:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103b71:	89 f8                	mov    %edi,%eax
f0103b73:	e8 48 fb ff ff       	call   f01036c0 <region_alloc>
	
	    lcr3(PADDR(kern_pgdir));
f0103b78:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103b7d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103b82:	77 20                	ja     f0103ba4 <env_create+0x16d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103b84:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103b88:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0103b8f:	f0 
f0103b90:	c7 44 24 04 9e 01 00 	movl   $0x19e,0x4(%esp)
f0103b97:	00 
f0103b98:	c7 04 24 cb 7c 10 f0 	movl   $0xf0107ccb,(%esp)
f0103b9f:	e8 9c c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103ba4:	05 00 00 00 10       	add    $0x10000000,%eax
f0103ba9:	0f 22 d8             	mov    %eax,%cr3

	//load the elf binary
	load_icode(e,binary);

	//set env type
	e->env_type = type;
f0103bac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103baf:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103bb2:	89 50 50             	mov    %edx,0x50(%eax)

}
f0103bb5:	83 c4 3c             	add    $0x3c,%esp
f0103bb8:	5b                   	pop    %ebx
f0103bb9:	5e                   	pop    %esi
f0103bba:	5f                   	pop    %edi
f0103bbb:	5d                   	pop    %ebp
f0103bbc:	c3                   	ret    

f0103bbd <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103bbd:	55                   	push   %ebp
f0103bbe:	89 e5                	mov    %esp,%ebp
f0103bc0:	57                   	push   %edi
f0103bc1:	56                   	push   %esi
f0103bc2:	53                   	push   %ebx
f0103bc3:	83 ec 2c             	sub    $0x2c,%esp
f0103bc6:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103bc9:	e8 ab 26 00 00       	call   f0106279 <cpunum>
f0103bce:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bd1:	39 b8 28 d0 22 f0    	cmp    %edi,-0xfdd2fd8(%eax)
f0103bd7:	75 34                	jne    f0103c0d <env_free+0x50>
		lcr3(PADDR(kern_pgdir));
f0103bd9:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103bde:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103be3:	77 20                	ja     f0103c05 <env_free+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103be5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103be9:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0103bf0:	f0 
f0103bf1:	c7 44 24 04 c8 01 00 	movl   $0x1c8,0x4(%esp)
f0103bf8:	00 
f0103bf9:	c7 04 24 cb 7c 10 f0 	movl   $0xf0107ccb,(%esp)
f0103c00:	e8 3b c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103c05:	05 00 00 00 10       	add    $0x10000000,%eax
f0103c0a:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103c0d:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103c10:	e8 64 26 00 00       	call   f0106279 <cpunum>
f0103c15:	6b d0 74             	imul   $0x74,%eax,%edx
f0103c18:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c1d:	83 ba 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%edx)
f0103c24:	74 11                	je     f0103c37 <env_free+0x7a>
f0103c26:	e8 4e 26 00 00       	call   f0106279 <cpunum>
f0103c2b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c2e:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103c34:	8b 40 48             	mov    0x48(%eax),%eax
f0103c37:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103c3b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c3f:	c7 04 24 eb 7c 10 f0 	movl   $0xf0107ceb,(%esp)
f0103c46:	e8 6b 04 00 00       	call   f01040b6 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103c4b:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103c52:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103c55:	89 c8                	mov    %ecx,%eax
f0103c57:	c1 e0 02             	shl    $0x2,%eax
f0103c5a:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103c5d:	8b 47 60             	mov    0x60(%edi),%eax
f0103c60:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0103c63:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103c69:	0f 84 b7 00 00 00    	je     f0103d26 <env_free+0x169>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103c6f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103c75:	89 f0                	mov    %esi,%eax
f0103c77:	c1 e8 0c             	shr    $0xc,%eax
f0103c7a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c7d:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0103c83:	72 20                	jb     f0103ca5 <env_free+0xe8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103c85:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103c89:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0103c90:	f0 
f0103c91:	c7 44 24 04 d7 01 00 	movl   $0x1d7,0x4(%esp)
f0103c98:	00 
f0103c99:	c7 04 24 cb 7c 10 f0 	movl   $0xf0107ccb,(%esp)
f0103ca0:	e8 9b c3 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103ca5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103ca8:	c1 e0 16             	shl    $0x16,%eax
f0103cab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103cae:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103cb3:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103cba:	01 
f0103cbb:	74 17                	je     f0103cd4 <env_free+0x117>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103cbd:	89 d8                	mov    %ebx,%eax
f0103cbf:	c1 e0 0c             	shl    $0xc,%eax
f0103cc2:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103cc5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cc9:	8b 47 60             	mov    0x60(%edi),%eax
f0103ccc:	89 04 24             	mov    %eax,(%esp)
f0103ccf:	e8 4f d7 ff ff       	call   f0101423 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103cd4:	83 c3 01             	add    $0x1,%ebx
f0103cd7:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103cdd:	75 d4                	jne    f0103cb3 <env_free+0xf6>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103cdf:	8b 47 60             	mov    0x60(%edi),%eax
f0103ce2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103ce5:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103cec:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103cef:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0103cf5:	72 1c                	jb     f0103d13 <env_free+0x156>
		panic("pa2page called with invalid pa");
f0103cf7:	c7 44 24 08 50 70 10 	movl   $0xf0107050,0x8(%esp)
f0103cfe:	f0 
f0103cff:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103d06:	00 
f0103d07:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f0103d0e:	e8 2d c3 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103d13:	a1 90 ce 22 f0       	mov    0xf022ce90,%eax
f0103d18:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103d1b:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103d1e:	89 04 24             	mov    %eax,(%esp)
f0103d21:	e8 91 d4 ff ff       	call   f01011b7 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103d26:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103d2a:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103d31:	0f 85 1b ff ff ff    	jne    f0103c52 <env_free+0x95>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103d37:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103d3a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103d3f:	77 20                	ja     f0103d61 <env_free+0x1a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103d41:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d45:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0103d4c:	f0 
f0103d4d:	c7 44 24 04 e5 01 00 	movl   $0x1e5,0x4(%esp)
f0103d54:	00 
f0103d55:	c7 04 24 cb 7c 10 f0 	movl   $0xf0107ccb,(%esp)
f0103d5c:	e8 df c2 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103d61:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103d68:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103d6d:	c1 e8 0c             	shr    $0xc,%eax
f0103d70:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0103d76:	72 1c                	jb     f0103d94 <env_free+0x1d7>
		panic("pa2page called with invalid pa");
f0103d78:	c7 44 24 08 50 70 10 	movl   $0xf0107050,0x8(%esp)
f0103d7f:	f0 
f0103d80:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103d87:	00 
f0103d88:	c7 04 24 d9 78 10 f0 	movl   $0xf01078d9,(%esp)
f0103d8f:	e8 ac c2 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103d94:	8b 15 90 ce 22 f0    	mov    0xf022ce90,%edx
f0103d9a:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103d9d:	89 04 24             	mov    %eax,(%esp)
f0103da0:	e8 12 d4 ff ff       	call   f01011b7 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103da5:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103dac:	a1 4c c2 22 f0       	mov    0xf022c24c,%eax
f0103db1:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103db4:	89 3d 4c c2 22 f0    	mov    %edi,0xf022c24c
}
f0103dba:	83 c4 2c             	add    $0x2c,%esp
f0103dbd:	5b                   	pop    %ebx
f0103dbe:	5e                   	pop    %esi
f0103dbf:	5f                   	pop    %edi
f0103dc0:	5d                   	pop    %ebp
f0103dc1:	c3                   	ret    

f0103dc2 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103dc2:	55                   	push   %ebp
f0103dc3:	89 e5                	mov    %esp,%ebp
f0103dc5:	53                   	push   %ebx
f0103dc6:	83 ec 14             	sub    $0x14,%esp
f0103dc9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103dcc:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103dd0:	75 19                	jne    f0103deb <env_destroy+0x29>
f0103dd2:	e8 a2 24 00 00       	call   f0106279 <cpunum>
f0103dd7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dda:	39 98 28 d0 22 f0    	cmp    %ebx,-0xfdd2fd8(%eax)
f0103de0:	74 09                	je     f0103deb <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103de2:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103de9:	eb 2f                	jmp    f0103e1a <env_destroy+0x58>
	}

	env_free(e);
f0103deb:	89 1c 24             	mov    %ebx,(%esp)
f0103dee:	e8 ca fd ff ff       	call   f0103bbd <env_free>

	if (curenv == e) {
f0103df3:	e8 81 24 00 00       	call   f0106279 <cpunum>
f0103df8:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dfb:	39 98 28 d0 22 f0    	cmp    %ebx,-0xfdd2fd8(%eax)
f0103e01:	75 17                	jne    f0103e1a <env_destroy+0x58>
		curenv = NULL;
f0103e03:	e8 71 24 00 00       	call   f0106279 <cpunum>
f0103e08:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e0b:	c7 80 28 d0 22 f0 00 	movl   $0x0,-0xfdd2fd8(%eax)
f0103e12:	00 00 00 
		sched_yield();
f0103e15:	e8 ac 0b 00 00       	call   f01049c6 <sched_yield>
	}
}
f0103e1a:	83 c4 14             	add    $0x14,%esp
f0103e1d:	5b                   	pop    %ebx
f0103e1e:	5d                   	pop    %ebp
f0103e1f:	c3                   	ret    

f0103e20 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103e20:	55                   	push   %ebp
f0103e21:	89 e5                	mov    %esp,%ebp
f0103e23:	53                   	push   %ebx
f0103e24:	83 ec 14             	sub    $0x14,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103e27:	e8 4d 24 00 00       	call   f0106279 <cpunum>
f0103e2c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e2f:	8b 98 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%ebx
f0103e35:	e8 3f 24 00 00       	call   f0106279 <cpunum>
f0103e3a:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f0103e3d:	8b 65 08             	mov    0x8(%ebp),%esp
f0103e40:	61                   	popa   
f0103e41:	07                   	pop    %es
f0103e42:	1f                   	pop    %ds
f0103e43:	83 c4 08             	add    $0x8,%esp
f0103e46:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103e47:	c7 44 24 08 01 7d 10 	movl   $0xf0107d01,0x8(%esp)
f0103e4e:	f0 
f0103e4f:	c7 44 24 04 1b 02 00 	movl   $0x21b,0x4(%esp)
f0103e56:	00 
f0103e57:	c7 04 24 cb 7c 10 f0 	movl   $0xf0107ccb,(%esp)
f0103e5e:	e8 dd c1 ff ff       	call   f0100040 <_panic>

f0103e63 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103e63:	55                   	push   %ebp
f0103e64:	89 e5                	mov    %esp,%ebp
f0103e66:	83 ec 18             	sub    $0x18,%esp
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if (curenv==NULL){
f0103e69:	e8 0b 24 00 00       	call   f0106279 <cpunum>
f0103e6e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e71:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f0103e78:	75 0e                	jne    f0103e88 <env_run+0x25>
	   cprintf("first call to env_runs \n");    
f0103e7a:	c7 04 24 0d 7d 10 f0 	movl   $0xf0107d0d,(%esp)
f0103e81:	e8 30 02 00 00       	call   f01040b6 <cprintf>
f0103e86:	eb 29                	jmp    f0103eb1 <env_run+0x4e>
	}
	else{
	    if( curenv->env_status ==ENV_RUNNING )
f0103e88:	e8 ec 23 00 00       	call   f0106279 <cpunum>
f0103e8d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e90:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103e96:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103e9a:	75 15                	jne    f0103eb1 <env_run+0x4e>
		curenv->env_status = ENV_RUNNABLE;
f0103e9c:	e8 d8 23 00 00       	call   f0106279 <cpunum>
f0103ea1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ea4:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103eaa:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv=e;
f0103eb1:	e8 c3 23 00 00       	call   f0106279 <cpunum>
f0103eb6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eb9:	8b 55 08             	mov    0x8(%ebp),%edx
f0103ebc:	89 90 28 d0 22 f0    	mov    %edx,-0xfdd2fd8(%eax)
	curenv->env_status=ENV_RUNNING;
f0103ec2:	e8 b2 23 00 00       	call   f0106279 <cpunum>
f0103ec7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eca:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103ed0:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103ed7:	e8 9d 23 00 00       	call   f0106279 <cpunum>
f0103edc:	6b c0 74             	imul   $0x74,%eax,%eax
f0103edf:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103ee5:	83 40 58 01          	addl   $0x1,0x58(%eax)
	//switch to env address space
	lcr3(PADDR(curenv->env_pgdir));
f0103ee9:	e8 8b 23 00 00       	call   f0106279 <cpunum>
f0103eee:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ef1:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103ef7:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103efa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103eff:	77 20                	ja     f0103f21 <env_run+0xbe>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103f01:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f05:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0103f0c:	f0 
f0103f0d:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
f0103f14:	00 
f0103f15:	c7 04 24 cb 7c 10 f0 	movl   $0xf0107ccb,(%esp)
f0103f1c:	e8 1f c1 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103f21:	05 00 00 00 10       	add    $0x10000000,%eax
f0103f26:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103f29:	c7 04 24 80 14 12 f0 	movl   $0xf0121480,(%esp)
f0103f30:	e8 6e 26 00 00       	call   f01065a3 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103f35:	f3 90                	pause  
	//release lock
	unlock_kernel();
	//restore environments registers
	env_pop_tf(&(curenv->env_tf));	
f0103f37:	e8 3d 23 00 00       	call   f0106279 <cpunum>
f0103f3c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f3f:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103f45:	89 04 24             	mov    %eax,(%esp)
f0103f48:	e8 d3 fe ff ff       	call   f0103e20 <env_pop_tf>

f0103f4d <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103f4d:	55                   	push   %ebp
f0103f4e:	89 e5                	mov    %esp,%ebp
f0103f50:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103f54:	ba 70 00 00 00       	mov    $0x70,%edx
f0103f59:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103f5a:	b2 71                	mov    $0x71,%dl
f0103f5c:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103f5d:	0f b6 c0             	movzbl %al,%eax
}
f0103f60:	5d                   	pop    %ebp
f0103f61:	c3                   	ret    

f0103f62 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103f62:	55                   	push   %ebp
f0103f63:	89 e5                	mov    %esp,%ebp
f0103f65:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103f69:	ba 70 00 00 00       	mov    $0x70,%edx
f0103f6e:	ee                   	out    %al,(%dx)
f0103f6f:	b2 71                	mov    $0x71,%dl
f0103f71:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f74:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103f75:	5d                   	pop    %ebp
f0103f76:	c3                   	ret    

f0103f77 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103f77:	55                   	push   %ebp
f0103f78:	89 e5                	mov    %esp,%ebp
f0103f7a:	56                   	push   %esi
f0103f7b:	53                   	push   %ebx
f0103f7c:	83 ec 10             	sub    $0x10,%esp
f0103f7f:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103f82:	66 a3 a8 13 12 f0    	mov    %ax,0xf01213a8
	if (!didinit)
f0103f88:	80 3d 50 c2 22 f0 00 	cmpb   $0x0,0xf022c250
f0103f8f:	74 4e                	je     f0103fdf <irq_setmask_8259A+0x68>
f0103f91:	89 c6                	mov    %eax,%esi
f0103f93:	ba 21 00 00 00       	mov    $0x21,%edx
f0103f98:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103f99:	66 c1 e8 08          	shr    $0x8,%ax
f0103f9d:	b2 a1                	mov    $0xa1,%dl
f0103f9f:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103fa0:	c7 04 24 26 7d 10 f0 	movl   $0xf0107d26,(%esp)
f0103fa7:	e8 0a 01 00 00       	call   f01040b6 <cprintf>
	for (i = 0; i < 16; i++)
f0103fac:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103fb1:	0f b7 f6             	movzwl %si,%esi
f0103fb4:	f7 d6                	not    %esi
f0103fb6:	0f a3 de             	bt     %ebx,%esi
f0103fb9:	73 10                	jae    f0103fcb <irq_setmask_8259A+0x54>
			cprintf(" %d", i);
f0103fbb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103fbf:	c7 04 24 eb 84 10 f0 	movl   $0xf01084eb,(%esp)
f0103fc6:	e8 eb 00 00 00       	call   f01040b6 <cprintf>
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103fcb:	83 c3 01             	add    $0x1,%ebx
f0103fce:	83 fb 10             	cmp    $0x10,%ebx
f0103fd1:	75 e3                	jne    f0103fb6 <irq_setmask_8259A+0x3f>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103fd3:	c7 04 24 09 79 10 f0 	movl   $0xf0107909,(%esp)
f0103fda:	e8 d7 00 00 00       	call   f01040b6 <cprintf>
}
f0103fdf:	83 c4 10             	add    $0x10,%esp
f0103fe2:	5b                   	pop    %ebx
f0103fe3:	5e                   	pop    %esi
f0103fe4:	5d                   	pop    %ebp
f0103fe5:	c3                   	ret    

f0103fe6 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103fe6:	c6 05 50 c2 22 f0 01 	movb   $0x1,0xf022c250
f0103fed:	ba 21 00 00 00       	mov    $0x21,%edx
f0103ff2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ff7:	ee                   	out    %al,(%dx)
f0103ff8:	b2 a1                	mov    $0xa1,%dl
f0103ffa:	ee                   	out    %al,(%dx)
f0103ffb:	b2 20                	mov    $0x20,%dl
f0103ffd:	b8 11 00 00 00       	mov    $0x11,%eax
f0104002:	ee                   	out    %al,(%dx)
f0104003:	b2 21                	mov    $0x21,%dl
f0104005:	b8 20 00 00 00       	mov    $0x20,%eax
f010400a:	ee                   	out    %al,(%dx)
f010400b:	b8 04 00 00 00       	mov    $0x4,%eax
f0104010:	ee                   	out    %al,(%dx)
f0104011:	b8 03 00 00 00       	mov    $0x3,%eax
f0104016:	ee                   	out    %al,(%dx)
f0104017:	b2 a0                	mov    $0xa0,%dl
f0104019:	b8 11 00 00 00       	mov    $0x11,%eax
f010401e:	ee                   	out    %al,(%dx)
f010401f:	b2 a1                	mov    $0xa1,%dl
f0104021:	b8 28 00 00 00       	mov    $0x28,%eax
f0104026:	ee                   	out    %al,(%dx)
f0104027:	b8 02 00 00 00       	mov    $0x2,%eax
f010402c:	ee                   	out    %al,(%dx)
f010402d:	b8 01 00 00 00       	mov    $0x1,%eax
f0104032:	ee                   	out    %al,(%dx)
f0104033:	b2 20                	mov    $0x20,%dl
f0104035:	b8 68 00 00 00       	mov    $0x68,%eax
f010403a:	ee                   	out    %al,(%dx)
f010403b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104040:	ee                   	out    %al,(%dx)
f0104041:	b2 a0                	mov    $0xa0,%dl
f0104043:	b8 68 00 00 00       	mov    $0x68,%eax
f0104048:	ee                   	out    %al,(%dx)
f0104049:	b8 0a 00 00 00       	mov    $0xa,%eax
f010404e:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f010404f:	0f b7 05 a8 13 12 f0 	movzwl 0xf01213a8,%eax
f0104056:	66 83 f8 ff          	cmp    $0xffff,%ax
f010405a:	74 12                	je     f010406e <pic_init+0x88>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f010405c:	55                   	push   %ebp
f010405d:	89 e5                	mov    %esp,%ebp
f010405f:	83 ec 18             	sub    $0x18,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0104062:	0f b7 c0             	movzwl %ax,%eax
f0104065:	89 04 24             	mov    %eax,(%esp)
f0104068:	e8 0a ff ff ff       	call   f0103f77 <irq_setmask_8259A>
}
f010406d:	c9                   	leave  
f010406e:	f3 c3                	repz ret 

f0104070 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0104070:	55                   	push   %ebp
f0104071:	89 e5                	mov    %esp,%ebp
f0104073:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0104076:	8b 45 08             	mov    0x8(%ebp),%eax
f0104079:	89 04 24             	mov    %eax,(%esp)
f010407c:	e8 09 c7 ff ff       	call   f010078a <cputchar>
	*cnt++;
}
f0104081:	c9                   	leave  
f0104082:	c3                   	ret    

f0104083 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0104083:	55                   	push   %ebp
f0104084:	89 e5                	mov    %esp,%ebp
f0104086:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0104089:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0104090:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104093:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104097:	8b 45 08             	mov    0x8(%ebp),%eax
f010409a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010409e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01040a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040a5:	c7 04 24 70 40 10 f0 	movl   $0xf0104070,(%esp)
f01040ac:	e8 bd 14 00 00       	call   f010556e <vprintfmt>
	return cnt;
}
f01040b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01040b4:	c9                   	leave  
f01040b5:	c3                   	ret    

f01040b6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01040b6:	55                   	push   %ebp
f01040b7:	89 e5                	mov    %esp,%ebp
f01040b9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01040bc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01040bf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01040c6:	89 04 24             	mov    %eax,(%esp)
f01040c9:	e8 b5 ff ff ff       	call   f0104083 <vcprintf>
	va_end(ap);

	return cnt;
}
f01040ce:	c9                   	leave  
f01040cf:	c3                   	ret    

f01040d0 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01040d0:	55                   	push   %ebp
f01040d1:	89 e5                	mov    %esp,%ebp
f01040d3:	83 ec 08             	sub    $0x8,%esp
	// user space on that CPU.
	//
	// LAB 4: Your code here:
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	int i = cpunum(); 
f01040d6:	e8 9e 21 00 00       	call   f0106279 <cpunum>

	cpus[i].cpu_ts.ts_esp0 = KSTACKTOP - (KSTKSIZE + KSTKGAP) * i;
f01040db:	6b d0 74             	imul   $0x74,%eax,%edx
f01040de:	89 c1                	mov    %eax,%ecx
f01040e0:	f7 d9                	neg    %ecx
f01040e2:	c1 e1 10             	shl    $0x10,%ecx
f01040e5:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f01040eb:	89 8a 30 d0 22 f0    	mov    %ecx,-0xfdd2fd0(%edx)
	cpus[i].cpu_ts.ts_ss0 = GD_KD;
f01040f1:	66 c7 82 34 d0 22 f0 	movw   $0x10,-0xfdd2fcc(%edx)
f01040f8:	10 00 
	
	
	// Initialize the TSS slot of the gdt.
	gdt[ (GD_TSS0 >> 3) + i ] = SEG16(STS_T32A, (uint32_t) (&cpus[i].cpu_ts),
f01040fa:	83 c0 05             	add    $0x5,%eax
f01040fd:	81 c2 2c d0 22 f0    	add    $0xf022d02c,%edx
f0104103:	66 c7 04 c5 40 13 12 	movw   $0x67,-0xfedecc0(,%eax,8)
f010410a:	f0 67 00 
f010410d:	66 89 14 c5 42 13 12 	mov    %dx,-0xfedecbe(,%eax,8)
f0104114:	f0 
f0104115:	89 d1                	mov    %edx,%ecx
f0104117:	c1 e9 10             	shr    $0x10,%ecx
f010411a:	88 0c c5 44 13 12 f0 	mov    %cl,-0xfedecbc(,%eax,8)
f0104121:	c6 04 c5 46 13 12 f0 	movb   $0x40,-0xfedecba(,%eax,8)
f0104128:	40 
f0104129:	c1 ea 18             	shr    $0x18,%edx
f010412c:	88 14 c5 47 13 12 f0 	mov    %dl,-0xfedecb9(,%eax,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[ (GD_TSS0 >> 3) + i ].sd_s = 0;
f0104133:	c6 04 c5 45 13 12 f0 	movb   $0x89,-0xfedecbb(,%eax,8)
f010413a:	89 
	
	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr( GD_TSS0 + (i * sizeof(struct Segdesc) ) );
f010413b:	c1 e0 03             	shl    $0x3,%eax
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010413e:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0104141:	b8 aa 13 12 f0       	mov    $0xf01213aa,%eax
f0104146:	0f 01 18             	lidtl  (%eax)
	ltr(GD_TSS0);
	// Load the IDT
	lidt(&idt_pd); */
	
	
}
f0104149:	c9                   	leave  
f010414a:	c3                   	ret    

f010414b <trap_init>:
trap_init(void)
{
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	int i=0;
f010414b:	b8 00 00 00 00       	mov    $0x0,%eax
	for (; i< MAX_IDT ; i++){
		SETGATE(idt[i], 0, GD_KT, trap_handler[i], 0);
f0104150:	8b 14 85 b0 13 12 f0 	mov    -0xfedec50(,%eax,4),%edx
f0104157:	66 89 14 c5 60 c2 22 	mov    %dx,-0xfdd3da0(,%eax,8)
f010415e:	f0 
f010415f:	66 c7 04 c5 62 c2 22 	movw   $0x8,-0xfdd3d9e(,%eax,8)
f0104166:	f0 08 00 
f0104169:	c6 04 c5 64 c2 22 f0 	movb   $0x0,-0xfdd3d9c(,%eax,8)
f0104170:	00 
f0104171:	c6 04 c5 65 c2 22 f0 	movb   $0x8e,-0xfdd3d9b(,%eax,8)
f0104178:	8e 
f0104179:	c1 ea 10             	shr    $0x10,%edx
f010417c:	66 89 14 c5 66 c2 22 	mov    %dx,-0xfdd3d9a(,%eax,8)
f0104183:	f0 
{
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	int i=0;
	for (; i< MAX_IDT ; i++){
f0104184:	83 c0 01             	add    $0x1,%eax
f0104187:	3d 00 01 00 00       	cmp    $0x100,%eax
f010418c:	75 c2                	jne    f0104150 <trap_init+0x5>
#define MAX_IDT 256
extern uint32_t trap_handler[];

void	
trap_init(void)
{
f010418e:	55                   	push   %ebp
f010418f:	89 e5                	mov    %esp,%ebp
f0104191:	83 ec 08             	sub    $0x8,%esp
	int i=0;
	for (; i< MAX_IDT ; i++){
		SETGATE(idt[i], 0, GD_KT, trap_handler[i], 0);
	}
	// init break point
	SETGATE(idt[T_BRKPT], 0, GD_KT, trap_handler[T_BRKPT], 3);
f0104194:	a1 bc 13 12 f0       	mov    0xf01213bc,%eax
f0104199:	66 a3 78 c2 22 f0    	mov    %ax,0xf022c278
f010419f:	66 c7 05 7a c2 22 f0 	movw   $0x8,0xf022c27a
f01041a6:	08 00 
f01041a8:	c6 05 7c c2 22 f0 00 	movb   $0x0,0xf022c27c
f01041af:	c6 05 7d c2 22 f0 ee 	movb   $0xee,0xf022c27d
f01041b6:	c1 e8 10             	shr    $0x10,%eax
f01041b9:	66 a3 7e c2 22 f0    	mov    %ax,0xf022c27e
	// init syscall
	SETGATE(idt[T_SYSCALL], 0, GD_KT, trap_handler[T_SYSCALL], 3);
f01041bf:	a1 70 14 12 f0       	mov    0xf0121470,%eax
f01041c4:	66 a3 e0 c3 22 f0    	mov    %ax,0xf022c3e0
f01041ca:	66 c7 05 e2 c3 22 f0 	movw   $0x8,0xf022c3e2
f01041d1:	08 00 
f01041d3:	c6 05 e4 c3 22 f0 00 	movb   $0x0,0xf022c3e4
f01041da:	c6 05 e5 c3 22 f0 ee 	movb   $0xee,0xf022c3e5
f01041e1:	c1 e8 10             	shr    $0x10,%eax
f01041e4:	66 a3 e6 c3 22 f0    	mov    %ax,0xf022c3e6

	// Per-CPU setup 
	trap_init_percpu();
f01041ea:	e8 e1 fe ff ff       	call   f01040d0 <trap_init_percpu>
}
f01041ef:	c9                   	leave  
f01041f0:	c3                   	ret    

f01041f1 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01041f1:	55                   	push   %ebp
f01041f2:	89 e5                	mov    %esp,%ebp
f01041f4:	53                   	push   %ebx
f01041f5:	83 ec 14             	sub    $0x14,%esp
f01041f8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01041fb:	8b 03                	mov    (%ebx),%eax
f01041fd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104201:	c7 04 24 3a 7d 10 f0 	movl   $0xf0107d3a,(%esp)
f0104208:	e8 a9 fe ff ff       	call   f01040b6 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010420d:	8b 43 04             	mov    0x4(%ebx),%eax
f0104210:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104214:	c7 04 24 49 7d 10 f0 	movl   $0xf0107d49,(%esp)
f010421b:	e8 96 fe ff ff       	call   f01040b6 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104220:	8b 43 08             	mov    0x8(%ebx),%eax
f0104223:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104227:	c7 04 24 58 7d 10 f0 	movl   $0xf0107d58,(%esp)
f010422e:	e8 83 fe ff ff       	call   f01040b6 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104233:	8b 43 0c             	mov    0xc(%ebx),%eax
f0104236:	89 44 24 04          	mov    %eax,0x4(%esp)
f010423a:	c7 04 24 67 7d 10 f0 	movl   $0xf0107d67,(%esp)
f0104241:	e8 70 fe ff ff       	call   f01040b6 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0104246:	8b 43 10             	mov    0x10(%ebx),%eax
f0104249:	89 44 24 04          	mov    %eax,0x4(%esp)
f010424d:	c7 04 24 76 7d 10 f0 	movl   $0xf0107d76,(%esp)
f0104254:	e8 5d fe ff ff       	call   f01040b6 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0104259:	8b 43 14             	mov    0x14(%ebx),%eax
f010425c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104260:	c7 04 24 85 7d 10 f0 	movl   $0xf0107d85,(%esp)
f0104267:	e8 4a fe ff ff       	call   f01040b6 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010426c:	8b 43 18             	mov    0x18(%ebx),%eax
f010426f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104273:	c7 04 24 94 7d 10 f0 	movl   $0xf0107d94,(%esp)
f010427a:	e8 37 fe ff ff       	call   f01040b6 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010427f:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0104282:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104286:	c7 04 24 a3 7d 10 f0 	movl   $0xf0107da3,(%esp)
f010428d:	e8 24 fe ff ff       	call   f01040b6 <cprintf>
}
f0104292:	83 c4 14             	add    $0x14,%esp
f0104295:	5b                   	pop    %ebx
f0104296:	5d                   	pop    %ebp
f0104297:	c3                   	ret    

f0104298 <print_trapframe>:
	
}

void
print_trapframe(struct Trapframe *tf)
{
f0104298:	55                   	push   %ebp
f0104299:	89 e5                	mov    %esp,%ebp
f010429b:	56                   	push   %esi
f010429c:	53                   	push   %ebx
f010429d:	83 ec 10             	sub    $0x10,%esp
f01042a0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f01042a3:	e8 d1 1f 00 00       	call   f0106279 <cpunum>
f01042a8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01042ac:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01042b0:	c7 04 24 07 7e 10 f0 	movl   $0xf0107e07,(%esp)
f01042b7:	e8 fa fd ff ff       	call   f01040b6 <cprintf>
	print_regs(&tf->tf_regs);
f01042bc:	89 1c 24             	mov    %ebx,(%esp)
f01042bf:	e8 2d ff ff ff       	call   f01041f1 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01042c4:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01042c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042cc:	c7 04 24 25 7e 10 f0 	movl   $0xf0107e25,(%esp)
f01042d3:	e8 de fd ff ff       	call   f01040b6 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01042d8:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01042dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042e0:	c7 04 24 38 7e 10 f0 	movl   $0xf0107e38,(%esp)
f01042e7:	e8 ca fd ff ff       	call   f01040b6 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01042ec:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f01042ef:	83 f8 13             	cmp    $0x13,%eax
f01042f2:	77 09                	ja     f01042fd <print_trapframe+0x65>
		return excnames[trapno];
f01042f4:	8b 14 85 e0 80 10 f0 	mov    -0xfef7f20(,%eax,4),%edx
f01042fb:	eb 1f                	jmp    f010431c <print_trapframe+0x84>
	if (trapno == T_SYSCALL)
f01042fd:	83 f8 30             	cmp    $0x30,%eax
f0104300:	74 15                	je     f0104317 <print_trapframe+0x7f>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0104302:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f0104305:	83 fa 0f             	cmp    $0xf,%edx
f0104308:	ba be 7d 10 f0       	mov    $0xf0107dbe,%edx
f010430d:	b9 d1 7d 10 f0       	mov    $0xf0107dd1,%ecx
f0104312:	0f 47 d1             	cmova  %ecx,%edx
f0104315:	eb 05                	jmp    f010431c <print_trapframe+0x84>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0104317:	ba b2 7d 10 f0       	mov    $0xf0107db2,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010431c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104320:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104324:	c7 04 24 4b 7e 10 f0 	movl   $0xf0107e4b,(%esp)
f010432b:	e8 86 fd ff ff       	call   f01040b6 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104330:	3b 1d 60 ca 22 f0    	cmp    0xf022ca60,%ebx
f0104336:	75 19                	jne    f0104351 <print_trapframe+0xb9>
f0104338:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010433c:	75 13                	jne    f0104351 <print_trapframe+0xb9>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f010433e:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0104341:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104345:	c7 04 24 5d 7e 10 f0 	movl   $0xf0107e5d,(%esp)
f010434c:	e8 65 fd ff ff       	call   f01040b6 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0104351:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0104354:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104358:	c7 04 24 6c 7e 10 f0 	movl   $0xf0107e6c,(%esp)
f010435f:	e8 52 fd ff ff       	call   f01040b6 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0104364:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104368:	75 51                	jne    f01043bb <print_trapframe+0x123>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f010436a:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f010436d:	89 c2                	mov    %eax,%edx
f010436f:	83 e2 01             	and    $0x1,%edx
f0104372:	ba e0 7d 10 f0       	mov    $0xf0107de0,%edx
f0104377:	b9 eb 7d 10 f0       	mov    $0xf0107deb,%ecx
f010437c:	0f 45 ca             	cmovne %edx,%ecx
f010437f:	89 c2                	mov    %eax,%edx
f0104381:	83 e2 02             	and    $0x2,%edx
f0104384:	ba f7 7d 10 f0       	mov    $0xf0107df7,%edx
f0104389:	be fd 7d 10 f0       	mov    $0xf0107dfd,%esi
f010438e:	0f 44 d6             	cmove  %esi,%edx
f0104391:	83 e0 04             	and    $0x4,%eax
f0104394:	b8 02 7e 10 f0       	mov    $0xf0107e02,%eax
f0104399:	be 37 7f 10 f0       	mov    $0xf0107f37,%esi
f010439e:	0f 44 c6             	cmove  %esi,%eax
f01043a1:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01043a5:	89 54 24 08          	mov    %edx,0x8(%esp)
f01043a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043ad:	c7 04 24 7a 7e 10 f0 	movl   $0xf0107e7a,(%esp)
f01043b4:	e8 fd fc ff ff       	call   f01040b6 <cprintf>
f01043b9:	eb 0c                	jmp    f01043c7 <print_trapframe+0x12f>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01043bb:	c7 04 24 09 79 10 f0 	movl   $0xf0107909,(%esp)
f01043c2:	e8 ef fc ff ff       	call   f01040b6 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01043c7:	8b 43 30             	mov    0x30(%ebx),%eax
f01043ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043ce:	c7 04 24 89 7e 10 f0 	movl   $0xf0107e89,(%esp)
f01043d5:	e8 dc fc ff ff       	call   f01040b6 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01043da:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01043de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043e2:	c7 04 24 98 7e 10 f0 	movl   $0xf0107e98,(%esp)
f01043e9:	e8 c8 fc ff ff       	call   f01040b6 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01043ee:	8b 43 38             	mov    0x38(%ebx),%eax
f01043f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043f5:	c7 04 24 ab 7e 10 f0 	movl   $0xf0107eab,(%esp)
f01043fc:	e8 b5 fc ff ff       	call   f01040b6 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0104401:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104405:	74 27                	je     f010442e <print_trapframe+0x196>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0104407:	8b 43 3c             	mov    0x3c(%ebx),%eax
f010440a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010440e:	c7 04 24 ba 7e 10 f0 	movl   $0xf0107eba,(%esp)
f0104415:	e8 9c fc ff ff       	call   f01040b6 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010441a:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010441e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104422:	c7 04 24 c9 7e 10 f0 	movl   $0xf0107ec9,(%esp)
f0104429:	e8 88 fc ff ff       	call   f01040b6 <cprintf>
	}
}
f010442e:	83 c4 10             	add    $0x10,%esp
f0104431:	5b                   	pop    %ebx
f0104432:	5e                   	pop    %esi
f0104433:	5d                   	pop    %ebp
f0104434:	c3                   	ret    

f0104435 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104435:	55                   	push   %ebp
f0104436:	89 e5                	mov    %esp,%ebp
f0104438:	57                   	push   %edi
f0104439:	56                   	push   %esi
f010443a:	53                   	push   %ebx
f010443b:	83 ec 1c             	sub    $0x1c,%esp
f010443e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104441:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if((tf->tf_cs & 3) == 0){
f0104444:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104448:	75 28                	jne    f0104472 <page_fault_handler+0x3d>
	    print_trapframe(tf);
f010444a:	89 1c 24             	mov    %ebx,(%esp)
f010444d:	e8 46 fe ff ff       	call   f0104298 <print_trapframe>
	    panic("page fault in kernel space : fault va %08x\n",fault_va);
f0104452:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104456:	c7 44 24 08 84 80 10 	movl   $0xf0108084,0x8(%esp)
f010445d:	f0 
f010445e:	c7 44 24 04 40 01 00 	movl   $0x140,0x4(%esp)
f0104465:	00 
f0104466:	c7 04 24 dc 7e 10 f0 	movl   $0xf0107edc,(%esp)
f010446d:	e8 ce bb ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104472:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0104475:	e8 ff 1d 00 00       	call   f0106279 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010447a:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010447e:	89 74 24 08          	mov    %esi,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f0104482:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104485:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f010448b:	8b 40 48             	mov    0x48(%eax),%eax
f010448e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104492:	c7 04 24 b0 80 10 f0 	movl   $0xf01080b0,(%esp)
f0104499:	e8 18 fc ff ff       	call   f01040b6 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f010449e:	89 1c 24             	mov    %ebx,(%esp)
f01044a1:	e8 f2 fd ff ff       	call   f0104298 <print_trapframe>
	env_destroy(curenv);
f01044a6:	e8 ce 1d 00 00       	call   f0106279 <cpunum>
f01044ab:	6b c0 74             	imul   $0x74,%eax,%eax
f01044ae:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01044b4:	89 04 24             	mov    %eax,(%esp)
f01044b7:	e8 06 f9 ff ff       	call   f0103dc2 <env_destroy>
}
f01044bc:	83 c4 1c             	add    $0x1c,%esp
f01044bf:	5b                   	pop    %ebx
f01044c0:	5e                   	pop    %esi
f01044c1:	5f                   	pop    %edi
f01044c2:	5d                   	pop    %ebp
f01044c3:	c3                   	ret    

f01044c4 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01044c4:	55                   	push   %ebp
f01044c5:	89 e5                	mov    %esp,%ebp
f01044c7:	57                   	push   %edi
f01044c8:	56                   	push   %esi
f01044c9:	83 ec 20             	sub    $0x20,%esp
f01044cc:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01044cf:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f01044d0:	83 3d 80 ce 22 f0 00 	cmpl   $0x0,0xf022ce80
f01044d7:	74 01                	je     f01044da <trap+0x16>
		asm volatile("hlt");
f01044d9:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f01044da:	e8 9a 1d 00 00       	call   f0106279 <cpunum>
f01044df:	6b d0 74             	imul   $0x74,%eax,%edx
f01044e2:	81 c2 20 d0 22 f0    	add    $0xf022d020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01044e8:	b8 01 00 00 00       	mov    $0x1,%eax
f01044ed:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f01044f1:	83 f8 02             	cmp    $0x2,%eax
f01044f4:	75 0c                	jne    f0104502 <trap+0x3e>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01044f6:	c7 04 24 80 14 12 f0 	movl   $0xf0121480,(%esp)
f01044fd:	e8 f5 1f 00 00       	call   f01064f7 <spin_lock>

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0104502:	9c                   	pushf  
f0104503:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0104504:	f6 c4 02             	test   $0x2,%ah
f0104507:	74 24                	je     f010452d <trap+0x69>
f0104509:	c7 44 24 0c e8 7e 10 	movl   $0xf0107ee8,0xc(%esp)
f0104510:	f0 
f0104511:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f0104518:	f0 
f0104519:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
f0104520:	00 
f0104521:	c7 04 24 dc 7e 10 f0 	movl   $0xf0107edc,(%esp)
f0104528:	e8 13 bb ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f010452d:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104531:	83 e0 03             	and    $0x3,%eax
f0104534:	66 83 f8 03          	cmp    $0x3,%ax
f0104538:	0f 85 a7 00 00 00    	jne    f01045e5 <trap+0x121>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		assert(curenv);
f010453e:	e8 36 1d 00 00       	call   f0106279 <cpunum>
f0104543:	6b c0 74             	imul   $0x74,%eax,%eax
f0104546:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f010454d:	75 24                	jne    f0104573 <trap+0xaf>
f010454f:	c7 44 24 0c 01 7f 10 	movl   $0xf0107f01,0xc(%esp)
f0104556:	f0 
f0104557:	c7 44 24 08 17 79 10 	movl   $0xf0107917,0x8(%esp)
f010455e:	f0 
f010455f:	c7 44 24 04 11 01 00 	movl   $0x111,0x4(%esp)
f0104566:	00 
f0104567:	c7 04 24 dc 7e 10 f0 	movl   $0xf0107edc,(%esp)
f010456e:	e8 cd ba ff ff       	call   f0100040 <_panic>
f0104573:	c7 04 24 80 14 12 f0 	movl   $0xf0121480,(%esp)
f010457a:	e8 78 1f 00 00       	call   f01064f7 <spin_lock>
		lock_kernel();
		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f010457f:	e8 f5 1c 00 00       	call   f0106279 <cpunum>
f0104584:	6b c0 74             	imul   $0x74,%eax,%eax
f0104587:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f010458d:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0104591:	75 2d                	jne    f01045c0 <trap+0xfc>
			env_free(curenv);
f0104593:	e8 e1 1c 00 00       	call   f0106279 <cpunum>
f0104598:	6b c0 74             	imul   $0x74,%eax,%eax
f010459b:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01045a1:	89 04 24             	mov    %eax,(%esp)
f01045a4:	e8 14 f6 ff ff       	call   f0103bbd <env_free>
			curenv = NULL;
f01045a9:	e8 cb 1c 00 00       	call   f0106279 <cpunum>
f01045ae:	6b c0 74             	imul   $0x74,%eax,%eax
f01045b1:	c7 80 28 d0 22 f0 00 	movl   $0x0,-0xfdd2fd8(%eax)
f01045b8:	00 00 00 
			sched_yield();
f01045bb:	e8 06 04 00 00       	call   f01049c6 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01045c0:	e8 b4 1c 00 00       	call   f0106279 <cpunum>
f01045c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01045c8:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01045ce:	b9 11 00 00 00       	mov    $0x11,%ecx
f01045d3:	89 c7                	mov    %eax,%edi
f01045d5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01045d7:	e8 9d 1c 00 00       	call   f0106279 <cpunum>
f01045dc:	6b c0 74             	imul   $0x74,%eax,%eax
f01045df:	8b b0 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01045e5:	89 35 60 ca 22 f0    	mov    %esi,0xf022ca60


	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f01045eb:	8b 46 28             	mov    0x28(%esi),%eax
f01045ee:	83 f8 27             	cmp    $0x27,%eax
f01045f1:	75 19                	jne    f010460c <trap+0x148>
		cprintf("Spurious interrupt on irq 7\n");
f01045f3:	c7 04 24 08 7f 10 f0 	movl   $0xf0107f08,(%esp)
f01045fa:	e8 b7 fa ff ff       	call   f01040b6 <cprintf>
		print_trapframe(tf);
f01045ff:	89 34 24             	mov    %esi,(%esp)
f0104602:	e8 91 fc ff ff       	call   f0104298 <print_trapframe>
f0104607:	e9 9d 00 00 00       	jmp    f01046a9 <trap+0x1e5>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.


	switch(tf->tf_trapno){
f010460c:	83 f8 0e             	cmp    $0xe,%eax
f010460f:	90                   	nop
f0104610:	74 10                	je     f0104622 <trap+0x15e>
f0104612:	83 f8 30             	cmp    $0x30,%eax
f0104615:	74 1f                	je     f0104636 <trap+0x172>
f0104617:	83 f8 03             	cmp    $0x3,%eax
f010461a:	75 4c                	jne    f0104668 <trap+0x1a4>
f010461c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104620:	eb 0a                	jmp    f010462c <trap+0x168>
	case T_PGFLT:
		page_fault_handler(tf);
f0104622:	89 34 24             	mov    %esi,(%esp)
f0104625:	e8 0b fe ff ff       	call   f0104435 <page_fault_handler>
f010462a:	eb 7d                	jmp    f01046a9 <trap+0x1e5>
		break;
	case T_BRKPT:
		monitor(tf);
f010462c:	89 34 24             	mov    %esi,(%esp)
f010462f:	e8 66 c3 ff ff       	call   f010099a <monitor>
f0104634:	eb 73                	jmp    f01046a9 <trap+0x1e5>
		break;
	case T_SYSCALL:
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0104636:	8b 46 04             	mov    0x4(%esi),%eax
f0104639:	89 44 24 14          	mov    %eax,0x14(%esp)
f010463d:	8b 06                	mov    (%esi),%eax
f010463f:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104643:	8b 46 10             	mov    0x10(%esi),%eax
f0104646:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010464a:	8b 46 18             	mov    0x18(%esi),%eax
f010464d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104651:	8b 46 14             	mov    0x14(%esi),%eax
f0104654:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104658:	8b 46 1c             	mov    0x1c(%esi),%eax
f010465b:	89 04 24             	mov    %eax,(%esp)
f010465e:	e8 4d 04 00 00       	call   f0104ab0 <syscall>
f0104663:	89 46 1c             	mov    %eax,0x1c(%esi)
f0104666:	eb 41                	jmp    f01046a9 <trap+0x1e5>
			tf->tf_regs.reg_esi);
		break;
	default:
		
		// Unexpected trap: The user process or the kernel has a bug.
	    print_trapframe(tf);
f0104668:	89 34 24             	mov    %esi,(%esp)
f010466b:	e8 28 fc ff ff       	call   f0104298 <print_trapframe>
	    if (tf->tf_cs == GD_KT)
f0104670:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104675:	75 1c                	jne    f0104693 <trap+0x1cf>

		panic("unhandled trap in kernel");
f0104677:	c7 44 24 08 25 7f 10 	movl   $0xf0107f25,0x8(%esp)
f010467e:	f0 
f010467f:	c7 44 24 04 ef 00 00 	movl   $0xef,0x4(%esp)
f0104686:	00 
f0104687:	c7 04 24 dc 7e 10 f0 	movl   $0xf0107edc,(%esp)
f010468e:	e8 ad b9 ff ff       	call   f0100040 <_panic>
	    else {
		env_destroy(curenv);
f0104693:	e8 e1 1b 00 00       	call   f0106279 <cpunum>
f0104698:	6b c0 74             	imul   $0x74,%eax,%eax
f010469b:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01046a1:	89 04 24             	mov    %eax,(%esp)
f01046a4:	e8 19 f7 ff ff       	call   f0103dc2 <env_destroy>
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f01046a9:	e8 cb 1b 00 00       	call   f0106279 <cpunum>
f01046ae:	6b c0 74             	imul   $0x74,%eax,%eax
f01046b1:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f01046b8:	74 2a                	je     f01046e4 <trap+0x220>
f01046ba:	e8 ba 1b 00 00       	call   f0106279 <cpunum>
f01046bf:	6b c0 74             	imul   $0x74,%eax,%eax
f01046c2:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01046c8:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01046cc:	75 16                	jne    f01046e4 <trap+0x220>
		env_run(curenv);
f01046ce:	e8 a6 1b 00 00       	call   f0106279 <cpunum>
f01046d3:	6b c0 74             	imul   $0x74,%eax,%eax
f01046d6:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01046dc:	89 04 24             	mov    %eax,(%esp)
f01046df:	e8 7f f7 ff ff       	call   f0103e63 <env_run>
	else
		sched_yield();
f01046e4:	e8 dd 02 00 00       	call   f01049c6 <sched_yield>
f01046e9:	90                   	nop

f01046ea <hdlr_t0>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
	TRAPHANDLER_NOEC(hdlr_t0, 0)
f01046ea:	6a 00                	push   $0x0
f01046ec:	6a 00                	push   $0x0
f01046ee:	e9 e8 01 00 00       	jmp    f01048db <_alltraps>
f01046f3:	90                   	nop

f01046f4 <hdlr_t1>:
	TRAPHANDLER_NOEC(hdlr_t1, 1)
f01046f4:	6a 00                	push   $0x0
f01046f6:	6a 01                	push   $0x1
f01046f8:	e9 de 01 00 00       	jmp    f01048db <_alltraps>
f01046fd:	90                   	nop

f01046fe <hdlr_t2>:
	TRAPHANDLER_NOEC(hdlr_t2, 2)
f01046fe:	6a 00                	push   $0x0
f0104700:	6a 02                	push   $0x2
f0104702:	e9 d4 01 00 00       	jmp    f01048db <_alltraps>
f0104707:	90                   	nop

f0104708 <hdlr_t3>:
	TRAPHANDLER_NOEC(hdlr_t3, 3)
f0104708:	6a 00                	push   $0x0
f010470a:	6a 03                	push   $0x3
f010470c:	e9 ca 01 00 00       	jmp    f01048db <_alltraps>
f0104711:	90                   	nop

f0104712 <hdlr_t4>:
	TRAPHANDLER_NOEC(hdlr_t4, 4)
f0104712:	6a 00                	push   $0x0
f0104714:	6a 04                	push   $0x4
f0104716:	e9 c0 01 00 00       	jmp    f01048db <_alltraps>
f010471b:	90                   	nop

f010471c <hdlr_t5>:
	TRAPHANDLER_NOEC(hdlr_t5, 5)
f010471c:	6a 00                	push   $0x0
f010471e:	6a 05                	push   $0x5
f0104720:	e9 b6 01 00 00       	jmp    f01048db <_alltraps>
f0104725:	90                   	nop

f0104726 <hdlr_t6>:
	TRAPHANDLER_NOEC(hdlr_t6, 6)
f0104726:	6a 00                	push   $0x0
f0104728:	6a 06                	push   $0x6
f010472a:	e9 ac 01 00 00       	jmp    f01048db <_alltraps>
f010472f:	90                   	nop

f0104730 <hdlr_t7>:
	TRAPHANDLER_NOEC(hdlr_t7, 7)
f0104730:	6a 00                	push   $0x0
f0104732:	6a 07                	push   $0x7
f0104734:	e9 a2 01 00 00       	jmp    f01048db <_alltraps>
f0104739:	90                   	nop

f010473a <hdlr_t8>:
	TRAPHANDLER(hdlr_t8, 8)
f010473a:	6a 08                	push   $0x8
f010473c:	e9 9a 01 00 00       	jmp    f01048db <_alltraps>
f0104741:	90                   	nop

f0104742 <hdlr_t9>:
	TRAPHANDLER_NOEC(hdlr_t9, 9)
f0104742:	6a 00                	push   $0x0
f0104744:	6a 09                	push   $0x9
f0104746:	e9 90 01 00 00       	jmp    f01048db <_alltraps>
f010474b:	90                   	nop

f010474c <hdlr_t10>:
	TRAPHANDLER(hdlr_t10, 10)
f010474c:	6a 0a                	push   $0xa
f010474e:	e9 88 01 00 00       	jmp    f01048db <_alltraps>
f0104753:	90                   	nop

f0104754 <hdlr_t11>:
	TRAPHANDLER(hdlr_t11, 11)
f0104754:	6a 0b                	push   $0xb
f0104756:	e9 80 01 00 00       	jmp    f01048db <_alltraps>
f010475b:	90                   	nop

f010475c <hdlr_t12>:
	TRAPHANDLER(hdlr_t12, 12)
f010475c:	6a 0c                	push   $0xc
f010475e:	e9 78 01 00 00       	jmp    f01048db <_alltraps>
f0104763:	90                   	nop

f0104764 <hdlr_t13>:
	TRAPHANDLER(hdlr_t13, 13)
f0104764:	6a 0d                	push   $0xd
f0104766:	e9 70 01 00 00       	jmp    f01048db <_alltraps>
f010476b:	90                   	nop

f010476c <hdlr_t14>:
	TRAPHANDLER(hdlr_t14, 14)
f010476c:	6a 0e                	push   $0xe
f010476e:	e9 68 01 00 00       	jmp    f01048db <_alltraps>
f0104773:	90                   	nop

f0104774 <hdlr_t15>:
	TRAPHANDLER_NOEC(hdlr_t15, 15)
f0104774:	6a 00                	push   $0x0
f0104776:	6a 0f                	push   $0xf
f0104778:	e9 5e 01 00 00       	jmp    f01048db <_alltraps>
f010477d:	90                   	nop

f010477e <hdlr_t16>:
	TRAPHANDLER_NOEC(hdlr_t16, 16)
f010477e:	6a 00                	push   $0x0
f0104780:	6a 10                	push   $0x10
f0104782:	e9 54 01 00 00       	jmp    f01048db <_alltraps>
f0104787:	90                   	nop

f0104788 <hdlr_t17>:
	TRAPHANDLER_NOEC(hdlr_t17, 17)
f0104788:	6a 00                	push   $0x0
f010478a:	6a 11                	push   $0x11
f010478c:	e9 4a 01 00 00       	jmp    f01048db <_alltraps>
f0104791:	90                   	nop

f0104792 <hdlr_t18>:
	TRAPHANDLER_NOEC(hdlr_t18, 18)
f0104792:	6a 00                	push   $0x0
f0104794:	6a 12                	push   $0x12
f0104796:	e9 40 01 00 00       	jmp    f01048db <_alltraps>
f010479b:	90                   	nop

f010479c <hdlr_t19>:
	TRAPHANDLER_NOEC(hdlr_t19, 19)
f010479c:	6a 00                	push   $0x0
f010479e:	6a 13                	push   $0x13
f01047a0:	e9 36 01 00 00       	jmp    f01048db <_alltraps>
f01047a5:	90                   	nop

f01047a6 <hdlr_t20>:
	TRAPHANDLER_NOEC(hdlr_t20, 20)
f01047a6:	6a 00                	push   $0x0
f01047a8:	6a 14                	push   $0x14
f01047aa:	e9 2c 01 00 00       	jmp    f01048db <_alltraps>
f01047af:	90                   	nop

f01047b0 <hdlr_t21>:
	TRAPHANDLER_NOEC(hdlr_t21, 21)
f01047b0:	6a 00                	push   $0x0
f01047b2:	6a 15                	push   $0x15
f01047b4:	e9 22 01 00 00       	jmp    f01048db <_alltraps>
f01047b9:	90                   	nop

f01047ba <hdlr_t22>:
	TRAPHANDLER_NOEC(hdlr_t22, 22)
f01047ba:	6a 00                	push   $0x0
f01047bc:	6a 16                	push   $0x16
f01047be:	e9 18 01 00 00       	jmp    f01048db <_alltraps>
f01047c3:	90                   	nop

f01047c4 <hdlr_t23>:
	TRAPHANDLER_NOEC(hdlr_t23, 23)
f01047c4:	6a 00                	push   $0x0
f01047c6:	6a 17                	push   $0x17
f01047c8:	e9 0e 01 00 00       	jmp    f01048db <_alltraps>
f01047cd:	90                   	nop

f01047ce <hdlr_t24>:
	TRAPHANDLER_NOEC(hdlr_t24, 24)
f01047ce:	6a 00                	push   $0x0
f01047d0:	6a 18                	push   $0x18
f01047d2:	e9 04 01 00 00       	jmp    f01048db <_alltraps>
f01047d7:	90                   	nop

f01047d8 <hdlr_t25>:
	TRAPHANDLER_NOEC(hdlr_t25, 25)
f01047d8:	6a 00                	push   $0x0
f01047da:	6a 19                	push   $0x19
f01047dc:	e9 fa 00 00 00       	jmp    f01048db <_alltraps>
f01047e1:	90                   	nop

f01047e2 <hdlr_t26>:
	TRAPHANDLER_NOEC(hdlr_t26, 26)
f01047e2:	6a 00                	push   $0x0
f01047e4:	6a 1a                	push   $0x1a
f01047e6:	e9 f0 00 00 00       	jmp    f01048db <_alltraps>
f01047eb:	90                   	nop

f01047ec <hdlr_t27>:
	TRAPHANDLER_NOEC(hdlr_t27, 27)
f01047ec:	6a 00                	push   $0x0
f01047ee:	6a 1b                	push   $0x1b
f01047f0:	e9 e6 00 00 00       	jmp    f01048db <_alltraps>
f01047f5:	90                   	nop

f01047f6 <hdlr_t28>:
	TRAPHANDLER_NOEC(hdlr_t28, 28)
f01047f6:	6a 00                	push   $0x0
f01047f8:	6a 1c                	push   $0x1c
f01047fa:	e9 dc 00 00 00       	jmp    f01048db <_alltraps>
f01047ff:	90                   	nop

f0104800 <hdlr_t29>:
	TRAPHANDLER_NOEC(hdlr_t29, 29)
f0104800:	6a 00                	push   $0x0
f0104802:	6a 1d                	push   $0x1d
f0104804:	e9 d2 00 00 00       	jmp    f01048db <_alltraps>
f0104809:	90                   	nop

f010480a <hdlr_t30>:
	TRAPHANDLER_NOEC(hdlr_t30, 30)
f010480a:	6a 00                	push   $0x0
f010480c:	6a 1e                	push   $0x1e
f010480e:	e9 c8 00 00 00       	jmp    f01048db <_alltraps>
f0104813:	90                   	nop

f0104814 <hdlr_t31>:
	TRAPHANDLER_NOEC(hdlr_t31, 31)
f0104814:	6a 00                	push   $0x0
f0104816:	6a 1f                	push   $0x1f
f0104818:	e9 be 00 00 00       	jmp    f01048db <_alltraps>
f010481d:	90                   	nop

f010481e <hdlr_t32>:
	TRAPHANDLER_NOEC(hdlr_t32, 32)
f010481e:	6a 00                	push   $0x0
f0104820:	6a 20                	push   $0x20
f0104822:	e9 b4 00 00 00       	jmp    f01048db <_alltraps>
f0104827:	90                   	nop

f0104828 <hdlr_t33>:
	TRAPHANDLER_NOEC(hdlr_t33, 33)
f0104828:	6a 00                	push   $0x0
f010482a:	6a 21                	push   $0x21
f010482c:	e9 aa 00 00 00       	jmp    f01048db <_alltraps>
f0104831:	90                   	nop

f0104832 <hdlr_t34>:
	TRAPHANDLER_NOEC(hdlr_t34, 34)
f0104832:	6a 00                	push   $0x0
f0104834:	6a 22                	push   $0x22
f0104836:	e9 a0 00 00 00       	jmp    f01048db <_alltraps>
f010483b:	90                   	nop

f010483c <hdlr_t35>:
	TRAPHANDLER_NOEC(hdlr_t35, 35)
f010483c:	6a 00                	push   $0x0
f010483e:	6a 23                	push   $0x23
f0104840:	e9 96 00 00 00       	jmp    f01048db <_alltraps>
f0104845:	90                   	nop

f0104846 <hdlr_t36>:
	TRAPHANDLER_NOEC(hdlr_t36, 36)
f0104846:	6a 00                	push   $0x0
f0104848:	6a 24                	push   $0x24
f010484a:	e9 8c 00 00 00       	jmp    f01048db <_alltraps>
f010484f:	90                   	nop

f0104850 <hdlr_t37>:
	TRAPHANDLER_NOEC(hdlr_t37, 37)
f0104850:	6a 00                	push   $0x0
f0104852:	6a 25                	push   $0x25
f0104854:	e9 82 00 00 00       	jmp    f01048db <_alltraps>
f0104859:	90                   	nop

f010485a <hdlr_t38>:
	TRAPHANDLER_NOEC(hdlr_t38, 38)
f010485a:	6a 00                	push   $0x0
f010485c:	6a 26                	push   $0x26
f010485e:	e9 78 00 00 00       	jmp    f01048db <_alltraps>
f0104863:	90                   	nop

f0104864 <hdlr_t39>:
	TRAPHANDLER_NOEC(hdlr_t39, 39)
f0104864:	6a 00                	push   $0x0
f0104866:	6a 27                	push   $0x27
f0104868:	e9 6e 00 00 00       	jmp    f01048db <_alltraps>
f010486d:	90                   	nop

f010486e <hdlr_t40>:
	TRAPHANDLER_NOEC(hdlr_t40, 40)
f010486e:	6a 00                	push   $0x0
f0104870:	6a 28                	push   $0x28
f0104872:	e9 64 00 00 00       	jmp    f01048db <_alltraps>
f0104877:	90                   	nop

f0104878 <hdlr_t41>:
	TRAPHANDLER_NOEC(hdlr_t41, 41)
f0104878:	6a 00                	push   $0x0
f010487a:	6a 29                	push   $0x29
f010487c:	e9 5a 00 00 00       	jmp    f01048db <_alltraps>
f0104881:	90                   	nop

f0104882 <hdlr_t42>:
	TRAPHANDLER_NOEC(hdlr_t42, 42)
f0104882:	6a 00                	push   $0x0
f0104884:	6a 2a                	push   $0x2a
f0104886:	e9 50 00 00 00       	jmp    f01048db <_alltraps>
f010488b:	90                   	nop

f010488c <hdlr_t43>:
	TRAPHANDLER_NOEC(hdlr_t43, 43)
f010488c:	6a 00                	push   $0x0
f010488e:	6a 2b                	push   $0x2b
f0104890:	e9 46 00 00 00       	jmp    f01048db <_alltraps>
f0104895:	90                   	nop

f0104896 <hdlr_t44>:
	TRAPHANDLER_NOEC(hdlr_t44, 44)
f0104896:	6a 00                	push   $0x0
f0104898:	6a 2c                	push   $0x2c
f010489a:	e9 3c 00 00 00       	jmp    f01048db <_alltraps>
f010489f:	90                   	nop

f01048a0 <hdlr_t45>:
	TRAPHANDLER_NOEC(hdlr_t45, 45)
f01048a0:	6a 00                	push   $0x0
f01048a2:	6a 2d                	push   $0x2d
f01048a4:	e9 32 00 00 00       	jmp    f01048db <_alltraps>
f01048a9:	90                   	nop

f01048aa <hdlr_t46>:
	TRAPHANDLER_NOEC(hdlr_t46, 46)
f01048aa:	6a 00                	push   $0x0
f01048ac:	6a 2e                	push   $0x2e
f01048ae:	e9 28 00 00 00       	jmp    f01048db <_alltraps>
f01048b3:	90                   	nop

f01048b4 <hdlr_t47>:
	TRAPHANDLER_NOEC(hdlr_t47, 47)
f01048b4:	6a 00                	push   $0x0
f01048b6:	6a 2f                	push   $0x2f
f01048b8:	e9 1e 00 00 00       	jmp    f01048db <_alltraps>
f01048bd:	90                   	nop

f01048be <hdlr_t48>:
	TRAPHANDLER_NOEC(hdlr_t48, 48)
f01048be:	6a 00                	push   $0x0
f01048c0:	6a 30                	push   $0x30
f01048c2:	e9 14 00 00 00       	jmp    f01048db <_alltraps>
f01048c7:	90                   	nop

f01048c8 <hdlr_t49>:
	TRAPHANDLER_NOEC(hdlr_t49, 49)
f01048c8:	6a 00                	push   $0x0
f01048ca:	6a 31                	push   $0x31
f01048cc:	e9 0a 00 00 00       	jmp    f01048db <_alltraps>
f01048d1:	90                   	nop

f01048d2 <hdlr_t50>:
	TRAPHANDLER_NOEC(hdlr_t50, 50)
f01048d2:	6a 00                	push   $0x0
f01048d4:	6a 32                	push   $0x32
f01048d6:	e9 00 00 00 00       	jmp    f01048db <_alltraps>

f01048db <_alltraps>:
 */

.globl _alltraps
_alltraps:
	// Build trapframe 
	push %ds
f01048db:	1e                   	push   %ds
	push %es
f01048dc:	06                   	push   %es
	pushal // push all registers 
f01048dd:	60                   	pusha  
	movw $GD_KD, %ax //load GD_KD into ds and es
f01048de:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f01048e2:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f01048e4:	8e c0                	mov    %eax,%es
	pushl %esp /* struct Trapframe * as argument */
f01048e6:	54                   	push   %esp
	call trap //never returns
f01048e7:	e8 d8 fb ff ff       	call   f01044c4 <trap>
f01048ec:	66 90                	xchg   %ax,%ax
f01048ee:	66 90                	xchg   %ax,%ax

f01048f0 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f01048f0:	55                   	push   %ebp
f01048f1:	89 e5                	mov    %esp,%ebp
f01048f3:	83 ec 18             	sub    $0x18,%esp
f01048f6:	8b 15 48 c2 22 f0    	mov    0xf022c248,%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01048fc:	b8 00 00 00 00       	mov    $0x0,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0104901:	8b 4a 54             	mov    0x54(%edx),%ecx
f0104904:	83 e9 01             	sub    $0x1,%ecx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104907:	83 f9 02             	cmp    $0x2,%ecx
f010490a:	76 0f                	jbe    f010491b <sched_halt+0x2b>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010490c:	83 c0 01             	add    $0x1,%eax
f010490f:	83 c2 7c             	add    $0x7c,%edx
f0104912:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104917:	75 e8                	jne    f0104901 <sched_halt+0x11>
f0104919:	eb 07                	jmp    f0104922 <sched_halt+0x32>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f010491b:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104920:	75 1a                	jne    f010493c <sched_halt+0x4c>
		cprintf("No runnable environments in the system!\n");
f0104922:	c7 04 24 30 81 10 f0 	movl   $0xf0108130,(%esp)
f0104929:	e8 88 f7 ff ff       	call   f01040b6 <cprintf>
		while (1)
			monitor(NULL);
f010492e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104935:	e8 60 c0 ff ff       	call   f010099a <monitor>
f010493a:	eb f2                	jmp    f010492e <sched_halt+0x3e>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f010493c:	e8 38 19 00 00       	call   f0106279 <cpunum>
f0104941:	6b c0 74             	imul   $0x74,%eax,%eax
f0104944:	c7 80 28 d0 22 f0 00 	movl   $0x0,-0xfdd2fd8(%eax)
f010494b:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f010494e:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0104953:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104958:	77 20                	ja     f010497a <sched_halt+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010495a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010495e:	c7 44 24 08 a8 69 10 	movl   $0xf01069a8,0x8(%esp)
f0104965:	f0 
f0104966:	c7 44 24 04 4d 00 00 	movl   $0x4d,0x4(%esp)
f010496d:	00 
f010496e:	c7 04 24 59 81 10 f0 	movl   $0xf0108159,(%esp)
f0104975:	e8 c6 b6 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010497a:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010497f:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104982:	e8 f2 18 00 00       	call   f0106279 <cpunum>
f0104987:	6b d0 74             	imul   $0x74,%eax,%edx
f010498a:	81 c2 20 d0 22 f0    	add    $0xf022d020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104990:	b8 02 00 00 00       	mov    $0x2,%eax
f0104995:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104999:	c7 04 24 80 14 12 f0 	movl   $0xf0121480,(%esp)
f01049a0:	e8 fe 1b 00 00       	call   f01065a3 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01049a5:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01049a7:	e8 cd 18 00 00       	call   f0106279 <cpunum>
f01049ac:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01049af:	8b 80 30 d0 22 f0    	mov    -0xfdd2fd0(%eax),%eax
f01049b5:	bd 00 00 00 00       	mov    $0x0,%ebp
f01049ba:	89 c4                	mov    %eax,%esp
f01049bc:	6a 00                	push   $0x0
f01049be:	6a 00                	push   $0x0
f01049c0:	fb                   	sti    
f01049c1:	f4                   	hlt    
f01049c2:	eb fd                	jmp    f01049c1 <sched_halt+0xd1>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f01049c4:	c9                   	leave  
f01049c5:	c3                   	ret    

f01049c6 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01049c6:	55                   	push   %ebp
f01049c7:	89 e5                	mov    %esp,%ebp
f01049c9:	53                   	push   %ebx
f01049ca:	83 ec 14             	sub    $0x14,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.

	int i=0,j=0;
	i = curenv ? (curenv - envs + 1) % NENV : 0;
f01049cd:	e8 a7 18 00 00       	call   f0106279 <cpunum>
f01049d2:	6b c0 74             	imul   $0x74,%eax,%eax
f01049d5:	ba 00 00 00 00       	mov    $0x0,%edx
f01049da:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f01049e1:	74 32                	je     f0104a15 <sched_yield+0x4f>
f01049e3:	e8 91 18 00 00       	call   f0106279 <cpunum>
f01049e8:	6b c0 74             	imul   $0x74,%eax,%eax
f01049eb:	8b 90 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%edx
f01049f1:	2b 15 48 c2 22 f0    	sub    0xf022c248,%edx
f01049f7:	c1 fa 02             	sar    $0x2,%edx
f01049fa:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0104a00:	83 c2 01             	add    $0x1,%edx
f0104a03:	89 d0                	mov    %edx,%eax
f0104a05:	c1 f8 1f             	sar    $0x1f,%eax
f0104a08:	c1 e8 16             	shr    $0x16,%eax
f0104a0b:	01 c2                	add    %eax,%edx
f0104a0d:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104a13:	29 c2                	sub    %eax,%edx
		 
	while( j < NENV){
		if (envs[i].env_status == ENV_RUNNABLE)
f0104a15:	8b 1d 48 c2 22 f0    	mov    0xf022c248,%ebx
f0104a1b:	b8 00 04 00 00       	mov    $0x400,%eax
f0104a20:	6b ca 7c             	imul   $0x7c,%edx,%ecx
f0104a23:	83 7c 0b 54 02       	cmpl   $0x2,0x54(%ebx,%ecx,1)
f0104a28:	74 6f                	je     f0104a99 <sched_yield+0xd3>
		    break;
	    ++j;
	    i = (i + 1) % NENV ;
f0104a2a:	83 c2 01             	add    $0x1,%edx
f0104a2d:	89 d1                	mov    %edx,%ecx
f0104a2f:	c1 f9 1f             	sar    $0x1f,%ecx
f0104a32:	c1 e9 16             	shr    $0x16,%ecx
f0104a35:	01 ca                	add    %ecx,%edx
f0104a37:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104a3d:	29 ca                	sub    %ecx,%edx
	// LAB 4: Your code here.

	int i=0,j=0;
	i = curenv ? (curenv - envs + 1) % NENV : 0;
		 
	while( j < NENV){
f0104a3f:	83 e8 01             	sub    $0x1,%eax
f0104a42:	75 dc                	jne    f0104a20 <sched_yield+0x5a>
		if (envs[i].env_status == ENV_RUNNABLE)
		    break;
	    ++j;
	    i = (i + 1) % NENV ;
	}
	if (envs[i].env_status == ENV_RUNNABLE){
f0104a44:	6b d2 7c             	imul   $0x7c,%edx,%edx
f0104a47:	01 da                	add    %ebx,%edx
f0104a49:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0104a4d:	75 08                	jne    f0104a57 <sched_yield+0x91>
	    idle = envs + i ;
	    env_run(idle);
f0104a4f:	89 14 24             	mov    %edx,(%esp)
f0104a52:	e8 0c f4 ff ff       	call   f0103e63 <env_run>
	} 
	else if ( !idle && curenv && (curenv->env_status == ENV_RUNNING) ){
f0104a57:	e8 1d 18 00 00       	call   f0106279 <cpunum>
f0104a5c:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a5f:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f0104a66:	74 2a                	je     f0104a92 <sched_yield+0xcc>
f0104a68:	e8 0c 18 00 00       	call   f0106279 <cpunum>
f0104a6d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a70:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104a76:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104a7a:	75 16                	jne    f0104a92 <sched_yield+0xcc>
	    env_run(curenv) ;
f0104a7c:	e8 f8 17 00 00       	call   f0106279 <cpunum>
f0104a81:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a84:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104a8a:	89 04 24             	mov    %eax,(%esp)
f0104a8d:	e8 d1 f3 ff ff       	call   f0103e63 <env_run>
	}
	// sched_halt never returns
	    sched_halt();
f0104a92:	e8 59 fe ff ff       	call   f01048f0 <sched_halt>
f0104a97:	eb 09                	jmp    f0104aa2 <sched_yield+0xdc>
		if (envs[i].env_status == ENV_RUNNABLE)
		    break;
	    ++j;
	    i = (i + 1) % NENV ;
	}
	if (envs[i].env_status == ENV_RUNNABLE){
f0104a99:	6b d2 7c             	imul   $0x7c,%edx,%edx
f0104a9c:	01 da                	add    %ebx,%edx
f0104a9e:	66 90                	xchg   %ax,%ax
f0104aa0:	eb ad                	jmp    f0104a4f <sched_yield+0x89>
	else if ( !idle && curenv && (curenv->env_status == ENV_RUNNING) ){
	    env_run(curenv) ;
	}
	// sched_halt never returns
	    sched_halt();
}
f0104aa2:	83 c4 14             	add    $0x14,%esp
f0104aa5:	5b                   	pop    %ebx
f0104aa6:	5d                   	pop    %ebp
f0104aa7:	c3                   	ret    
f0104aa8:	66 90                	xchg   %ax,%ax
f0104aaa:	66 90                	xchg   %ax,%ax
f0104aac:	66 90                	xchg   %ax,%ax
f0104aae:	66 90                	xchg   %ax,%ax

f0104ab0 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104ab0:	55                   	push   %ebp
f0104ab1:	89 e5                	mov    %esp,%ebp
f0104ab3:	57                   	push   %edi
f0104ab4:	56                   	push   %esi
f0104ab5:	53                   	push   %ebx
f0104ab6:	83 ec 2c             	sub    $0x2c,%esp
f0104ab9:	8b 45 08             	mov    0x8(%ebp),%eax
f0104abc:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) {
f0104abf:	83 f8 0a             	cmp    $0xa,%eax
f0104ac2:	0f 87 f0 04 00 00    	ja     f0104fb8 <syscall+0x508>
f0104ac8:	ff 24 85 98 84 10 f0 	jmp    *-0xfef7b68(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f0104acf:	e8 a5 17 00 00       	call   f0106279 <cpunum>
f0104ad4:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104adb:	00 
f0104adc:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104ae0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104ae3:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104ae7:	6b c0 74             	imul   $0x74,%eax,%eax
f0104aea:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104af0:	89 04 24             	mov    %eax,(%esp)
f0104af3:	e8 70 eb ff ff       	call   f0103668 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104af8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104afb:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104aff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104b03:	c7 04 24 66 81 10 f0 	movl   $0xf0108166,(%esp)
f0104b0a:	e8 a7 f5 ff ff       	call   f01040b6 <cprintf>

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f0104b0f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b14:	e9 bb 04 00 00       	jmp    f0104fd4 <syscall+0x524>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104b19:	e8 17 bb ff ff       	call   f0100635 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f0104b1e:	66 90                	xchg   %ax,%ax
f0104b20:	e9 af 04 00 00       	jmp    f0104fd4 <syscall+0x524>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104b25:	e8 4f 17 00 00       	call   f0106279 <cpunum>
f0104b2a:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b2d:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104b33:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f0104b36:	e9 99 04 00 00       	jmp    f0104fd4 <syscall+0x524>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104b3b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104b42:	00 
f0104b43:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104b46:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b4a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104b4d:	89 04 24             	mov    %eax,(%esp)
f0104b50:	e8 e6 eb ff ff       	call   f010373b <envid2env>
		return r;
f0104b55:	89 c2                	mov    %eax,%edx
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104b57:	85 c0                	test   %eax,%eax
f0104b59:	78 6e                	js     f0104bc9 <syscall+0x119>
		return r;
	if (e == curenv)
f0104b5b:	e8 19 17 00 00       	call   f0106279 <cpunum>
f0104b60:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104b63:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b66:	39 90 28 d0 22 f0    	cmp    %edx,-0xfdd2fd8(%eax)
f0104b6c:	75 23                	jne    f0104b91 <syscall+0xe1>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104b6e:	e8 06 17 00 00       	call   f0106279 <cpunum>
f0104b73:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b76:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104b7c:	8b 40 48             	mov    0x48(%eax),%eax
f0104b7f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b83:	c7 04 24 6b 81 10 f0 	movl   $0xf010816b,(%esp)
f0104b8a:	e8 27 f5 ff ff       	call   f01040b6 <cprintf>
f0104b8f:	eb 28                	jmp    f0104bb9 <syscall+0x109>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104b91:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104b94:	e8 e0 16 00 00       	call   f0106279 <cpunum>
f0104b99:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104b9d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ba0:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104ba6:	8b 40 48             	mov    0x48(%eax),%eax
f0104ba9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104bad:	c7 04 24 86 81 10 f0 	movl   $0xf0108186,(%esp)
f0104bb4:	e8 fd f4 ff ff       	call   f01040b6 <cprintf>
	env_destroy(e);
f0104bb9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104bbc:	89 04 24             	mov    %eax,(%esp)
f0104bbf:	e8 fe f1 ff ff       	call   f0103dc2 <env_destroy>
	return 0;
f0104bc4:	ba 00 00 00 00       	mov    $0x0,%edx
		
	case SYS_getenvid:
		return sys_getenvid();
		
	case SYS_env_destroy:
		return sys_env_destroy(a1);
f0104bc9:	89 d0                	mov    %edx,%eax
f0104bcb:	e9 04 04 00 00       	jmp    f0104fd4 <syscall+0x524>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104bd0:	e8 f1 fd ff ff       	call   f01049c6 <sched_yield>
	// LAB 4: Your code here.
	//panic("sys_exofork not implemented");
	struct Env *childenv;
	int r;
	//env_alloc(struct Env **newenv_store, envid_t parent_id)
	if ( (r = env_alloc(&childenv, curenv->env_id) ) < 0 ){
f0104bd5:	e8 9f 16 00 00       	call   f0106279 <cpunum>
f0104bda:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bdd:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104be3:	8b 40 48             	mov    0x48(%eax),%eax
f0104be6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104bea:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104bed:	89 04 24             	mov    %eax,(%esp)
f0104bf0:	e8 79 ec ff ff       	call   f010386e <env_alloc>
f0104bf5:	85 c0                	test   %eax,%eax
f0104bf7:	79 20                	jns    f0104c19 <syscall+0x169>
	    panic("error in creating child eniv in sys_exofork, %e \n",r);	
f0104bf9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104bfd:	c7 44 24 08 c4 81 10 	movl   $0xf01081c4,0x8(%esp)
f0104c04:	f0 
f0104c05:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
f0104c0c:	00 
f0104c0d:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104c14:	e8 27 b4 ff ff       	call   f0100040 <_panic>
	    return r;
	}
	//return 0 in child environment	
	childenv->env_status = ENV_NOT_RUNNABLE ;
f0104c19:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104c1c:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
	childenv->env_tf = curenv->env_tf ;
f0104c23:	e8 51 16 00 00       	call   f0106279 <cpunum>
f0104c28:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c2b:	8b b0 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%esi
f0104c31:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104c36:	89 df                	mov    %ebx,%edi
f0104c38:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	childenv->env_tf.tf_regs.reg_eax = 0;	
f0104c3a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c3d:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	
	return childenv->env_id;
f0104c44:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_yield:
		sys_yield();
	
	case SYS_exofork:
		return sys_exofork();
f0104c47:	e9 88 03 00 00       	jmp    f0104fd4 <syscall+0x524>

	// LAB 4: Your code here.
	//panic("sys_env_set_status not implemented");
	struct Env *env_store;
	int r;
	if  ( (r= envid2env(envid, &env_store, 1)) < 0 ) {
f0104c4c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104c53:	00 
f0104c54:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104c57:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c5b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c5e:	89 04 24             	mov    %eax,(%esp)
f0104c61:	e8 d5 ea ff ff       	call   f010373b <envid2env>
f0104c66:	85 c0                	test   %eax,%eax
f0104c68:	79 20                	jns    f0104c8a <syscall+0x1da>
	    panic("Bad or stale environment in kern/syscall.c/sys_env_set_st : %e \n",r); 
f0104c6a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104c6e:	c7 44 24 08 f8 81 10 	movl   $0xf01081f8,0x8(%esp)
f0104c75:	f0 
f0104c76:	c7 44 24 04 7d 00 00 	movl   $0x7d,0x4(%esp)
f0104c7d:	00 
f0104c7e:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104c85:	e8 b6 b3 ff ff       	call   f0100040 <_panic>
	    return r;	
	}
	if ( status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE ){
f0104c8a:	83 fb 04             	cmp    $0x4,%ebx
f0104c8d:	74 05                	je     f0104c94 <syscall+0x1e4>
f0104c8f:	83 fb 02             	cmp    $0x2,%ebx
f0104c92:	75 10                	jne    f0104ca4 <syscall+0x1f4>
	    env_store->env_status = status;
f0104c94:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c97:	89 58 54             	mov    %ebx,0x54(%eax)
	
	case SYS_exofork:
		return sys_exofork();
	
	case SYS_env_set_status:
		return sys_env_set_status( (envid_t)a1, (int)a2);
f0104c9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c9f:	e9 30 03 00 00       	jmp    f0104fd4 <syscall+0x524>
	if ( status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE ){
	    env_store->env_status = status;
	    return 0;
	}
	else{
	    panic("not valid status for this environment kern/syscall.c : sys_env_set status \n");
f0104ca4:	c7 44 24 08 3c 82 10 	movl   $0xf010823c,0x8(%esp)
f0104cab:	f0 
f0104cac:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
f0104cb3:	00 
f0104cb4:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104cbb:	e8 80 b3 ff ff       	call   f0100040 <_panic>
	struct PageInfo *p = NULL;
	struct Env *env_store;	
	int r;
	
	// Allocate a page from the page directory for environment.
	if (!(p = page_alloc(ALLOC_ZERO)))
f0104cc0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0104cc7:	e8 25 c4 ff ff       	call   f01010f1 <page_alloc>
f0104ccc:	89 c6                	mov    %eax,%esi
f0104cce:	85 c0                	test   %eax,%eax
f0104cd0:	0f 84 d3 00 00 00    	je     f0104da9 <syscall+0x2f9>
		return -E_NO_MEM;

	//get environment from envid
	if ( (r= envid2env(envid, &env_store, 1) < 0 ) ){
f0104cd6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104cdd:	00 
f0104cde:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104ce1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ce5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104ce8:	89 04 24             	mov    %eax,(%esp)
f0104ceb:	e8 4b ea ff ff       	call   f010373b <envid2env>
f0104cf0:	c1 e8 1f             	shr    $0x1f,%eax
f0104cf3:	85 c0                	test   %eax,%eax
f0104cf5:	74 20                	je     f0104d17 <syscall+0x267>
	    panic("Bad or stale environment in kern/syscall.c :sys_page_alloc with %e \n",r); 
f0104cf7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104cfb:	c7 44 24 08 88 82 10 	movl   $0xf0108288,0x8(%esp)
f0104d02:	f0 
f0104d03:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
f0104d0a:	00 
f0104d0b:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104d12:	e8 29 b3 ff ff       	call   f0100040 <_panic>
	    return r;	
	}
	// Check if valid virtual address and page alignment 
	if ( (uintptr_t)va >= UTOP || ( (uintptr_t)va % PGSIZE != 0 )  ){
f0104d17:	81 fb ff ff bf ee    	cmp    $0xeebfffff,%ebx
f0104d1d:	77 08                	ja     f0104d27 <syscall+0x277>
f0104d1f:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
f0104d25:	74 1c                	je     f0104d43 <syscall+0x293>
	    panic("Invalid memory access va>=UTOP or va not page aligned \n");
f0104d27:	c7 44 24 08 d0 82 10 	movl   $0xf01082d0,0x8(%esp)
f0104d2e:	f0 
f0104d2f:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
f0104d36:	00 
f0104d37:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104d3e:	e8 fd b2 ff ff       	call   f0100040 <_panic>
	    return -E_INVAL;
	}
	// Check for valid permissions 
	if ( !(perm & PTE_P) && !(perm & PTE_U) && !(perm & ~(PTE_SYSCALL)) ){
f0104d43:	f7 45 14 fd f1 ff ff 	testl  $0xfffff1fd,0x14(%ebp)
f0104d4a:	75 1c                	jne    f0104d68 <syscall+0x2b8>
	   panic("Invalid permissions.Check PTE_SYSCALL for valid permissions.\n");
f0104d4c:	c7 44 24 08 08 83 10 	movl   $0xf0108308,0x8(%esp)
f0104d53:	f0 
f0104d54:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
f0104d5b:	00 
f0104d5c:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104d63:	e8 d8 b2 ff ff       	call   f0100040 <_panic>
	    return -E_INVAL;
	}
	// Check if page is mapped correctly
	if ( (r=page_insert(env_store->env_pgdir,p,(void *)va,perm)) < 0 ){
f0104d68:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d6b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104d6f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104d73:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104d77:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104d7a:	8b 40 60             	mov    0x60(%eax),%eax
f0104d7d:	89 04 24             	mov    %eax,(%esp)
f0104d80:	e8 f5 c6 ff ff       	call   f010147a <page_insert>
f0104d85:	85 c0                	test   %eax,%eax
f0104d87:	79 2a                	jns    f0104db3 <syscall+0x303>
	    panic("Error inserting page %e in kern/syscall.c : sys_page_alloc\n",r);
f0104d89:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104d8d:	c7 44 24 08 48 83 10 	movl   $0xf0108348,0x8(%esp)
f0104d94:	f0 
f0104d95:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
f0104d9c:	00 
f0104d9d:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104da4:	e8 97 b2 ff ff       	call   f0100040 <_panic>
	struct Env *env_store;	
	int r;
	
	// Allocate a page from the page directory for environment.
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0104da9:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104dae:	e9 21 02 00 00       	jmp    f0104fd4 <syscall+0x524>
	if ( (r=page_insert(env_store->env_pgdir,p,(void *)va,perm)) < 0 ){
	    panic("Error inserting page %e in kern/syscall.c : sys_page_alloc\n",r);
            page_remove(env_store->env_pgdir,va);
	    return r;
	}
	return 0;  // No errors in this system call.
f0104db3:	b8 00 00 00 00       	mov    $0x0,%eax
	
	case SYS_env_set_status:
		return sys_env_set_status( (envid_t)a1, (int)a2);

	case SYS_page_alloc:
		return sys_page_alloc( (envid_t)a1, (void *)a2, (int)a3);
f0104db8:	e9 17 02 00 00       	jmp    f0104fd4 <syscall+0x524>
	pte_t **pte_store=&pte;
	struct Env *senv_store,*denv_store;	
	int r,d;

	//get environment from envid & check if its valid env
	if ( (r= envid2env(srcenvid, &senv_store, 1) < 0 ) || (d = envid2env(dstenvid,
f0104dbd:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104dc4:	00 
f0104dc5:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104dc8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104dcc:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104dcf:	89 04 24             	mov    %eax,(%esp)
f0104dd2:	e8 64 e9 ff ff       	call   f010373b <envid2env>
f0104dd7:	c1 e8 1f             	shr    $0x1f,%eax
f0104dda:	89 c6                	mov    %eax,%esi
f0104ddc:	85 c0                	test   %eax,%eax
f0104dde:	75 1e                	jne    f0104dfe <syscall+0x34e>
f0104de0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104de7:	00 
f0104de8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104deb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104def:	8b 45 14             	mov    0x14(%ebp),%eax
f0104df2:	89 04 24             	mov    %eax,(%esp)
f0104df5:	e8 41 e9 ff ff       	call   f010373b <envid2env>
f0104dfa:	85 c0                	test   %eax,%eax
f0104dfc:	79 20                	jns    f0104e1e <syscall+0x36e>
		&denv_store, 1) < 0  ) ){
	    panic("Bad or stale environment in kern/syscall.c :sys_page_map with %e \n",r); 
f0104dfe:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104e02:	c7 44 24 08 84 83 10 	movl   $0xf0108384,0x8(%esp)
f0104e09:	f0 
f0104e0a:	c7 44 24 04 fc 00 00 	movl   $0xfc,0x4(%esp)
f0104e11:	00 
f0104e12:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104e19:	e8 22 b2 ff ff       	call   f0100040 <_panic>
	    return r;	
	}
	// Check if valid virtual address and page alignment 
	if ( (uintptr_t)srcva >= UTOP || ( (uintptr_t)srcva % PGSIZE != 0 ) 
f0104e1e:	81 fb ff ff bf ee    	cmp    $0xeebfffff,%ebx
f0104e24:	77 1a                	ja     f0104e40 <syscall+0x390>
f0104e26:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
f0104e2c:	75 12                	jne    f0104e40 <syscall+0x390>
            || (uintptr_t)dstva >= UTOP || ( (uintptr_t)dstva % PGSIZE != 0 )  ){
f0104e2e:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104e35:	77 09                	ja     f0104e40 <syscall+0x390>
f0104e37:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f0104e3e:	74 1c                	je     f0104e5c <syscall+0x3ac>
	    panic("Invalid memory access va>=UTOP or va not page aligned \n");
f0104e40:	c7 44 24 08 d0 82 10 	movl   $0xf01082d0,0x8(%esp)
f0104e47:	f0 
f0104e48:	c7 44 24 04 02 01 00 	movl   $0x102,0x4(%esp)
f0104e4f:	00 
f0104e50:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104e57:	e8 e4 b1 ff ff       	call   f0100040 <_panic>
	    return -E_INVAL;
	}
	//is srcva is not mapped in srcenvid's address space.?
	 if ( !(p = page_lookup(senv_store ->env_pgdir,srcva,pte_store) ) ){
f0104e5c:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104e5f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104e63:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104e67:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104e6a:	8b 40 60             	mov    0x60(%eax),%eax
f0104e6d:	89 04 24             	mov    %eax,(%esp)
f0104e70:	e8 00 c5 ff ff       	call   f0101375 <page_lookup>
f0104e75:	85 c0                	test   %eax,%eax
f0104e77:	75 1c                	jne    f0104e95 <syscall+0x3e5>
	    panic("Src Va not mapped in Src env \n");
f0104e79:	c7 44 24 08 c8 83 10 	movl   $0xf01083c8,0x8(%esp)
f0104e80:	f0 
f0104e81:	c7 44 24 04 07 01 00 	movl   $0x107,0x4(%esp)
f0104e88:	00 
f0104e89:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104e90:	e8 ab b1 ff ff       	call   f0100040 <_panic>
	    return -E_INVAL;
	 }
	// Check for valid permissions 
	if ( !(perm & PTE_P) && !(perm & PTE_U) && !(perm & ~(PTE_SYSCALL)) ){
f0104e95:	f7 45 1c fd f1 ff ff 	testl  $0xfffff1fd,0x1c(%ebp)
f0104e9c:	75 1c                	jne    f0104eba <syscall+0x40a>
	   panic("Invalid permissions.Check PTE_SYSCALL for valid permissions \n");
f0104e9e:	c7 44 24 08 e8 83 10 	movl   $0xf01083e8,0x8(%esp)
f0104ea5:	f0 
f0104ea6:	c7 44 24 04 0c 01 00 	movl   $0x10c,0x4(%esp)
f0104ead:	00 
f0104eae:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104eb5:	e8 86 b1 ff ff       	call   f0100040 <_panic>
	    return -E_INVAL;
	}
	// Check if srcva is read only. If yes then allow write while mapping
	if ( (perm & PTE_W) && !(**pte_store & PTE_W) )
f0104eba:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104ebe:	74 24                	je     f0104ee4 <syscall+0x434>
f0104ec0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104ec3:	f6 02 02             	testb  $0x2,(%edx)
f0104ec6:	75 1c                	jne    f0104ee4 <syscall+0x434>
	   panic("Cannot have assign write perm to read only page \n");
f0104ec8:	c7 44 24 08 28 84 10 	movl   $0xf0108428,0x8(%esp)
f0104ecf:	f0 
f0104ed0:	c7 44 24 04 11 01 00 	movl   $0x111,0x4(%esp)
f0104ed7:	00 
f0104ed8:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104edf:	e8 5c b1 ff ff       	call   f0100040 <_panic>
	 
	// Map page from 'src' in 'srcenvid' to 'dst' in 'dstenvid' with permissions 'perm'
	if ( (r=page_insert(denv_store->env_pgdir,p,(void *)dstva,perm)) < 0 ){
f0104ee4:	8b 7d 1c             	mov    0x1c(%ebp),%edi
f0104ee7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104eeb:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104eee:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104ef2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ef6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ef9:	8b 40 60             	mov    0x60(%eax),%eax
f0104efc:	89 04 24             	mov    %eax,(%esp)
f0104eff:	e8 76 c5 ff ff       	call   f010147a <page_insert>
f0104f04:	85 c0                	test   %eax,%eax
f0104f06:	79 20                	jns    f0104f28 <syscall+0x478>
	    panic("Error inserting page %e in kern/syscall.c : sys_page_map\n",r);
f0104f08:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104f0c:	c7 44 24 08 5c 84 10 	movl   $0xf010845c,0x8(%esp)
f0104f13:	f0 
f0104f14:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
f0104f1b:	00 
f0104f1c:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104f23:	e8 18 b1 ff ff       	call   f0100040 <_panic>

	case SYS_page_alloc:
		return sys_page_alloc( (envid_t)a1, (void *)a2, (int)a3);
	
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
f0104f28:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f2d:	e9 a2 00 00 00       	jmp    f0104fd4 <syscall+0x524>
	//panic("sys_page_unmap not implemented");
	struct Env *env_store;	
	int r;

	//get environment from envid
	if ( (r= envid2env(envid, &env_store, 1) < 0 ) ){
f0104f32:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104f39:	00 
f0104f3a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104f3d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104f41:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104f44:	89 04 24             	mov    %eax,(%esp)
f0104f47:	e8 ef e7 ff ff       	call   f010373b <envid2env>
f0104f4c:	c1 e8 1f             	shr    $0x1f,%eax
f0104f4f:	85 c0                	test   %eax,%eax
f0104f51:	74 20                	je     f0104f73 <syscall+0x4c3>
	    panic("Bad or stale environment in kern/syscall.c :sys_page_alloc with %e \n",r); 
f0104f53:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104f57:	c7 44 24 08 88 82 10 	movl   $0xf0108288,0x8(%esp)
f0104f5e:	f0 
f0104f5f:	c7 44 24 04 2f 01 00 	movl   $0x12f,0x4(%esp)
f0104f66:	00 
f0104f67:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104f6e:	e8 cd b0 ff ff       	call   f0100040 <_panic>
	    return r;	
	}
	// Check if valid virtual address and page alignment 
	if ( (uintptr_t)va >= UTOP || ( (uintptr_t)va % PGSIZE != 0 )  ){
f0104f73:	81 fb ff ff bf ee    	cmp    $0xeebfffff,%ebx
f0104f79:	77 08                	ja     f0104f83 <syscall+0x4d3>
f0104f7b:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
f0104f81:	74 1c                	je     f0104f9f <syscall+0x4ef>
	    panic("Invalid memory access va>=UTOP or va not page aligned \n");
f0104f83:	c7 44 24 08 d0 82 10 	movl   $0xf01082d0,0x8(%esp)
f0104f8a:	f0 
f0104f8b:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
f0104f92:	00 
f0104f93:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104f9a:	e8 a1 b0 ff ff       	call   f0100040 <_panic>
	    return -E_INVAL;
	}
	
	page_remove(env_store->env_pgdir,va) ;
f0104f9f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104fa3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104fa6:	8b 40 60             	mov    0x60(%eax),%eax
f0104fa9:	89 04 24             	mov    %eax,(%esp)
f0104fac:	e8 72 c4 ff ff       	call   f0101423 <page_remove>
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
	     (envid_t) a3, (void *)a4, (int )a5);

	case SYS_page_unmap:
		return sys_page_unmap((envid_t)a1, (void *)a2);	
f0104fb1:	b8 00 00 00 00       	mov    $0x0,%eax
f0104fb6:	eb 1c                	jmp    f0104fd4 <syscall+0x524>
	
	default:
		panic("Invalid System Call \n");
f0104fb8:	c7 44 24 08 ad 81 10 	movl   $0xf01081ad,0x8(%esp)
f0104fbf:	f0 
f0104fc0:	c7 44 24 04 a7 01 00 	movl   $0x1a7,0x4(%esp)
f0104fc7:	00 
f0104fc8:	c7 04 24 9e 81 10 f0 	movl   $0xf010819e,(%esp)
f0104fcf:	e8 6c b0 ff ff       	call   f0100040 <_panic>
		return -E_INVAL;
	}
}
f0104fd4:	83 c4 2c             	add    $0x2c,%esp
f0104fd7:	5b                   	pop    %ebx
f0104fd8:	5e                   	pop    %esi
f0104fd9:	5f                   	pop    %edi
f0104fda:	5d                   	pop    %ebp
f0104fdb:	c3                   	ret    

f0104fdc <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104fdc:	55                   	push   %ebp
f0104fdd:	89 e5                	mov    %esp,%ebp
f0104fdf:	57                   	push   %edi
f0104fe0:	56                   	push   %esi
f0104fe1:	53                   	push   %ebx
f0104fe2:	83 ec 14             	sub    $0x14,%esp
f0104fe5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104fe8:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104feb:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104fee:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104ff1:	8b 1a                	mov    (%edx),%ebx
f0104ff3:	8b 01                	mov    (%ecx),%eax
f0104ff5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104ff8:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104fff:	e9 88 00 00 00       	jmp    f010508c <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0105004:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105007:	01 d8                	add    %ebx,%eax
f0105009:	89 c7                	mov    %eax,%edi
f010500b:	c1 ef 1f             	shr    $0x1f,%edi
f010500e:	01 c7                	add    %eax,%edi
f0105010:	d1 ff                	sar    %edi
f0105012:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0105015:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0105018:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010501b:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010501d:	eb 03                	jmp    f0105022 <stab_binsearch+0x46>
			m--;
f010501f:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0105022:	39 c3                	cmp    %eax,%ebx
f0105024:	7f 1f                	jg     f0105045 <stab_binsearch+0x69>
f0105026:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010502a:	83 ea 0c             	sub    $0xc,%edx
f010502d:	39 f1                	cmp    %esi,%ecx
f010502f:	75 ee                	jne    f010501f <stab_binsearch+0x43>
f0105031:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0105034:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0105037:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010503a:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010503e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0105041:	76 18                	jbe    f010505b <stab_binsearch+0x7f>
f0105043:	eb 05                	jmp    f010504a <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0105045:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0105048:	eb 42                	jmp    f010508c <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f010504a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010504d:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010504f:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0105052:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0105059:	eb 31                	jmp    f010508c <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010505b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010505e:	73 17                	jae    f0105077 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0105060:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0105063:	83 e8 01             	sub    $0x1,%eax
f0105066:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105069:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010506c:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010506e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0105075:	eb 15                	jmp    f010508c <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0105077:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010507a:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010507d:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f010507f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0105083:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0105085:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010508c:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010508f:	0f 8e 6f ff ff ff    	jle    f0105004 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0105095:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0105099:	75 0f                	jne    f01050aa <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f010509b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010509e:	8b 00                	mov    (%eax),%eax
f01050a0:	83 e8 01             	sub    $0x1,%eax
f01050a3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01050a6:	89 07                	mov    %eax,(%edi)
f01050a8:	eb 2c                	jmp    f01050d6 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01050aa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01050ad:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01050af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01050b2:	8b 0f                	mov    (%edi),%ecx
f01050b4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01050b7:	8b 7d ec             	mov    -0x14(%ebp),%edi
f01050ba:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01050bd:	eb 03                	jmp    f01050c2 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01050bf:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01050c2:	39 c8                	cmp    %ecx,%eax
f01050c4:	7e 0b                	jle    f01050d1 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f01050c6:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01050ca:	83 ea 0c             	sub    $0xc,%edx
f01050cd:	39 f3                	cmp    %esi,%ebx
f01050cf:	75 ee                	jne    f01050bf <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f01050d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01050d4:	89 07                	mov    %eax,(%edi)
	}
}
f01050d6:	83 c4 14             	add    $0x14,%esp
f01050d9:	5b                   	pop    %ebx
f01050da:	5e                   	pop    %esi
f01050db:	5f                   	pop    %edi
f01050dc:	5d                   	pop    %ebp
f01050dd:	c3                   	ret    

f01050de <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01050de:	55                   	push   %ebp
f01050df:	89 e5                	mov    %esp,%ebp
f01050e1:	57                   	push   %edi
f01050e2:	56                   	push   %esi
f01050e3:	53                   	push   %ebx
f01050e4:	83 ec 4c             	sub    $0x4c,%esp
f01050e7:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01050ea:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01050ed:	c7 07 c4 84 10 f0    	movl   $0xf01084c4,(%edi)
	info->eip_line = 0;
f01050f3:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f01050fa:	c7 47 08 c4 84 10 f0 	movl   $0xf01084c4,0x8(%edi)
	info->eip_fn_namelen = 9;
f0105101:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0105108:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f010510b:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0105112:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0105118:	0f 87 cf 00 00 00    	ja     f01051ed <debuginfo_eip+0x10f>
		const struct UserStabData *usd = (const struct UserStabData *) 			USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if ( (user_mem_check(curenv,(void *)usd,sizeof(struct 				UserStabData),PTE_U)) < 0 )
f010511e:	e8 56 11 00 00       	call   f0106279 <cpunum>
f0105123:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f010512a:	00 
f010512b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0105132:	00 
f0105133:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f010513a:	00 
f010513b:	6b c0 74             	imul   $0x74,%eax,%eax
f010513e:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0105144:	89 04 24             	mov    %eax,(%esp)
f0105147:	e8 96 e4 ff ff       	call   f01035e2 <user_mem_check>
f010514c:	85 c0                	test   %eax,%eax
f010514e:	0f 88 5f 02 00 00    	js     f01053b3 <debuginfo_eip+0x2d5>
			return -1;
		
		//------------------------------------------------------
		stabs = usd->stabs;
f0105154:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f0105159:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f010515f:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0105165:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0105168:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f010516e:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
                if ( (user_mem_check(curenv,(void *)stabs,
f0105171:	89 f2                	mov    %esi,%edx
f0105173:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0105176:	29 c2                	sub    %eax,%edx
f0105178:	89 55 b8             	mov    %edx,-0x48(%ebp)
f010517b:	e8 f9 10 00 00       	call   f0106279 <cpunum>
f0105180:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0105187:	00 
f0105188:	8b 55 b8             	mov    -0x48(%ebp),%edx
f010518b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010518f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0105192:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105196:	6b c0 74             	imul   $0x74,%eax,%eax
f0105199:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f010519f:	89 04 24             	mov    %eax,(%esp)
f01051a2:	e8 3b e4 ff ff       	call   f01035e2 <user_mem_check>
f01051a7:	85 c0                	test   %eax,%eax
f01051a9:	0f 88 0b 02 00 00    	js     f01053ba <debuginfo_eip+0x2dc>
		   (uintptr_t)stab_end - (uintptr_t)stabs,PTE_U)) < 0 )
			return -1;

		if ( (user_mem_check(curenv,(void *)stabstr,
f01051af:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01051b2:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01051b5:	89 55 b8             	mov    %edx,-0x48(%ebp)
f01051b8:	e8 bc 10 00 00       	call   f0106279 <cpunum>
f01051bd:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01051c4:	00 
f01051c5:	8b 55 b8             	mov    -0x48(%ebp),%edx
f01051c8:	89 54 24 08          	mov    %edx,0x8(%esp)
f01051cc:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f01051cf:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01051d3:	6b c0 74             	imul   $0x74,%eax,%eax
f01051d6:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01051dc:	89 04 24             	mov    %eax,(%esp)
f01051df:	e8 fe e3 ff ff       	call   f01035e2 <user_mem_check>
f01051e4:	85 c0                	test   %eax,%eax
f01051e6:	79 1f                	jns    f0105207 <debuginfo_eip+0x129>
f01051e8:	e9 d4 01 00 00       	jmp    f01053c1 <debuginfo_eip+0x2e3>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01051ed:	c7 45 bc 05 64 11 f0 	movl   $0xf0116405,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01051f4:	c7 45 c0 5d 2d 11 f0 	movl   $0xf0112d5d,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01051fb:	be 5c 2d 11 f0       	mov    $0xf0112d5c,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0105200:	c7 45 c4 b8 89 10 f0 	movl   $0xf01089b8,-0x3c(%ebp)
			
		
		}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0105207:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010520a:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f010520d:	0f 83 b5 01 00 00    	jae    f01053c8 <debuginfo_eip+0x2ea>
f0105213:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0105217:	0f 85 b2 01 00 00    	jne    f01053cf <debuginfo_eip+0x2f1>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010521d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0105224:	2b 75 c4             	sub    -0x3c(%ebp),%esi
f0105227:	c1 fe 02             	sar    $0x2,%esi
f010522a:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0105230:	83 e8 01             	sub    $0x1,%eax
f0105233:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0105236:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010523a:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0105241:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0105244:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0105247:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010524a:	89 f0                	mov    %esi,%eax
f010524c:	e8 8b fd ff ff       	call   f0104fdc <stab_binsearch>
	if (lfile == 0)
f0105251:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105254:	85 c0                	test   %eax,%eax
f0105256:	0f 84 7a 01 00 00    	je     f01053d6 <debuginfo_eip+0x2f8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010525c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010525f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105262:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0105265:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105269:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0105270:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0105273:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0105276:	89 f0                	mov    %esi,%eax
f0105278:	e8 5f fd ff ff       	call   f0104fdc <stab_binsearch>

	if (lfun <= rfun) {
f010527d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105280:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0105283:	39 f0                	cmp    %esi,%eax
f0105285:	7f 32                	jg     f01052b9 <debuginfo_eip+0x1db>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0105287:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010528a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010528d:	8d 14 91             	lea    (%ecx,%edx,4),%edx
f0105290:	8b 0a                	mov    (%edx),%ecx
f0105292:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f0105295:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0105298:	2b 4d c0             	sub    -0x40(%ebp),%ecx
f010529b:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f010529e:	73 09                	jae    f01052a9 <debuginfo_eip+0x1cb>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01052a0:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01052a3:	03 4d c0             	add    -0x40(%ebp),%ecx
f01052a6:	89 4f 08             	mov    %ecx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01052a9:	8b 52 08             	mov    0x8(%edx),%edx
f01052ac:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f01052af:	29 d3                	sub    %edx,%ebx
		// Search within the function definition for the line number.
		lline = lfun;
f01052b1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01052b4:	89 75 d0             	mov    %esi,-0x30(%ebp)
f01052b7:	eb 0f                	jmp    f01052c8 <debuginfo_eip+0x1ea>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01052b9:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f01052bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01052bf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01052c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01052c5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01052c8:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01052cf:	00 
f01052d0:	8b 47 08             	mov    0x8(%edi),%eax
f01052d3:	89 04 24             	mov    %eax,(%esp)
f01052d6:	e8 30 09 00 00       	call   f0105c0b <strfind>
f01052db:	2b 47 08             	sub    0x8(%edi),%eax
f01052de:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01052e1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01052e5:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01052ec:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01052ef:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01052f2:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01052f5:	89 f0                	mov    %esi,%eax
f01052f7:	e8 e0 fc ff ff       	call   f0104fdc <stab_binsearch>
	if(lline <= rline){
f01052fc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01052ff:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0105302:	0f 8f d5 00 00 00    	jg     f01053dd <debuginfo_eip+0x2ff>
		info->eip_line = stabs[lline].n_desc;
f0105308:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010530b:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0105310:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0105313:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105316:	89 c3                	mov    %eax,%ebx
f0105318:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010531b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010531e:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0105321:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0105324:	89 df                	mov    %ebx,%edi
f0105326:	eb 06                	jmp    f010532e <debuginfo_eip+0x250>
f0105328:	83 e8 01             	sub    $0x1,%eax
f010532b:	83 ea 0c             	sub    $0xc,%edx
f010532e:	89 c6                	mov    %eax,%esi
f0105330:	39 c7                	cmp    %eax,%edi
f0105332:	7f 3c                	jg     f0105370 <debuginfo_eip+0x292>
	       && stabs[lline].n_type != N_SOL
f0105334:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0105338:	80 f9 84             	cmp    $0x84,%cl
f010533b:	75 08                	jne    f0105345 <debuginfo_eip+0x267>
f010533d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105340:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0105343:	eb 11                	jmp    f0105356 <debuginfo_eip+0x278>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0105345:	80 f9 64             	cmp    $0x64,%cl
f0105348:	75 de                	jne    f0105328 <debuginfo_eip+0x24a>
f010534a:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f010534e:	74 d8                	je     f0105328 <debuginfo_eip+0x24a>
f0105350:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105353:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0105356:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0105359:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f010535c:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f010535f:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0105362:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0105365:	39 d0                	cmp    %edx,%eax
f0105367:	73 0a                	jae    f0105373 <debuginfo_eip+0x295>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0105369:	03 45 c0             	add    -0x40(%ebp),%eax
f010536c:	89 07                	mov    %eax,(%edi)
f010536e:	eb 03                	jmp    f0105373 <debuginfo_eip+0x295>
f0105370:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0105373:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0105376:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0105379:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010537e:	39 da                	cmp    %ebx,%edx
f0105380:	7d 67                	jge    f01053e9 <debuginfo_eip+0x30b>
		for (lline = lfun + 1;
f0105382:	83 c2 01             	add    $0x1,%edx
f0105385:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0105388:	89 d0                	mov    %edx,%eax
f010538a:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010538d:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0105390:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0105393:	eb 04                	jmp    f0105399 <debuginfo_eip+0x2bb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0105395:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0105399:	39 c3                	cmp    %eax,%ebx
f010539b:	7e 47                	jle    f01053e4 <debuginfo_eip+0x306>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010539d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01053a1:	83 c0 01             	add    $0x1,%eax
f01053a4:	83 c2 0c             	add    $0xc,%edx
f01053a7:	80 f9 a0             	cmp    $0xa0,%cl
f01053aa:	74 e9                	je     f0105395 <debuginfo_eip+0x2b7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01053ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01053b1:	eb 36                	jmp    f01053e9 <debuginfo_eip+0x30b>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if ( (user_mem_check(curenv,(void *)usd,sizeof(struct 				UserStabData),PTE_U)) < 0 )
			return -1;
f01053b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01053b8:	eb 2f                	jmp    f01053e9 <debuginfo_eip+0x30b>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
                if ( (user_mem_check(curenv,(void *)stabs,
		   (uintptr_t)stab_end - (uintptr_t)stabs,PTE_U)) < 0 )
			return -1;
f01053ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01053bf:	eb 28                	jmp    f01053e9 <debuginfo_eip+0x30b>

		if ( (user_mem_check(curenv,(void *)stabstr,
		   (uintptr_t)stabstr_end - (uintptr_t)stabstr,PTE_U)) < 0 )
			return -1;
f01053c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01053c6:	eb 21                	jmp    f01053e9 <debuginfo_eip+0x30b>
		
		}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01053c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01053cd:	eb 1a                	jmp    f01053e9 <debuginfo_eip+0x30b>
f01053cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01053d4:	eb 13                	jmp    f01053e9 <debuginfo_eip+0x30b>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01053d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01053db:	eb 0c                	jmp    f01053e9 <debuginfo_eip+0x30b>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline <= rline){
		info->eip_line = stabs[lline].n_desc;
	}
	else
		return -1;	
f01053dd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01053e2:	eb 05                	jmp    f01053e9 <debuginfo_eip+0x30b>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01053e4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01053e9:	83 c4 4c             	add    $0x4c,%esp
f01053ec:	5b                   	pop    %ebx
f01053ed:	5e                   	pop    %esi
f01053ee:	5f                   	pop    %edi
f01053ef:	5d                   	pop    %ebp
f01053f0:	c3                   	ret    
f01053f1:	66 90                	xchg   %ax,%ax
f01053f3:	66 90                	xchg   %ax,%ax
f01053f5:	66 90                	xchg   %ax,%ax
f01053f7:	66 90                	xchg   %ax,%ax
f01053f9:	66 90                	xchg   %ax,%ax
f01053fb:	66 90                	xchg   %ax,%ax
f01053fd:	66 90                	xchg   %ax,%ax
f01053ff:	90                   	nop

f0105400 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0105400:	55                   	push   %ebp
f0105401:	89 e5                	mov    %esp,%ebp
f0105403:	57                   	push   %edi
f0105404:	56                   	push   %esi
f0105405:	53                   	push   %ebx
f0105406:	83 ec 3c             	sub    $0x3c,%esp
f0105409:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010540c:	89 d7                	mov    %edx,%edi
f010540e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105411:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105414:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105417:	89 c3                	mov    %eax,%ebx
f0105419:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010541c:	8b 45 10             	mov    0x10(%ebp),%eax
f010541f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0105422:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105427:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010542a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010542d:	39 d9                	cmp    %ebx,%ecx
f010542f:	72 05                	jb     f0105436 <printnum+0x36>
f0105431:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0105434:	77 69                	ja     f010549f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0105436:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0105439:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010543d:	83 ee 01             	sub    $0x1,%esi
f0105440:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105444:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105448:	8b 44 24 08          	mov    0x8(%esp),%eax
f010544c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105450:	89 c3                	mov    %eax,%ebx
f0105452:	89 d6                	mov    %edx,%esi
f0105454:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105457:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010545a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010545e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105462:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105465:	89 04 24             	mov    %eax,(%esp)
f0105468:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010546b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010546f:	e8 4c 12 00 00       	call   f01066c0 <__udivdi3>
f0105474:	89 d9                	mov    %ebx,%ecx
f0105476:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010547a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010547e:	89 04 24             	mov    %eax,(%esp)
f0105481:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105485:	89 fa                	mov    %edi,%edx
f0105487:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010548a:	e8 71 ff ff ff       	call   f0105400 <printnum>
f010548f:	eb 1b                	jmp    f01054ac <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0105491:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105495:	8b 45 18             	mov    0x18(%ebp),%eax
f0105498:	89 04 24             	mov    %eax,(%esp)
f010549b:	ff d3                	call   *%ebx
f010549d:	eb 03                	jmp    f01054a2 <printnum+0xa2>
f010549f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01054a2:	83 ee 01             	sub    $0x1,%esi
f01054a5:	85 f6                	test   %esi,%esi
f01054a7:	7f e8                	jg     f0105491 <printnum+0x91>
f01054a9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01054ac:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01054b0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01054b4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01054b7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01054ba:	89 44 24 08          	mov    %eax,0x8(%esp)
f01054be:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01054c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01054c5:	89 04 24             	mov    %eax,(%esp)
f01054c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01054cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01054cf:	e8 1c 13 00 00       	call   f01067f0 <__umoddi3>
f01054d4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01054d8:	0f be 80 ce 84 10 f0 	movsbl -0xfef7b32(%eax),%eax
f01054df:	89 04 24             	mov    %eax,(%esp)
f01054e2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01054e5:	ff d0                	call   *%eax
}
f01054e7:	83 c4 3c             	add    $0x3c,%esp
f01054ea:	5b                   	pop    %ebx
f01054eb:	5e                   	pop    %esi
f01054ec:	5f                   	pop    %edi
f01054ed:	5d                   	pop    %ebp
f01054ee:	c3                   	ret    

f01054ef <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01054ef:	55                   	push   %ebp
f01054f0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01054f2:	83 fa 01             	cmp    $0x1,%edx
f01054f5:	7e 0e                	jle    f0105505 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01054f7:	8b 10                	mov    (%eax),%edx
f01054f9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01054fc:	89 08                	mov    %ecx,(%eax)
f01054fe:	8b 02                	mov    (%edx),%eax
f0105500:	8b 52 04             	mov    0x4(%edx),%edx
f0105503:	eb 22                	jmp    f0105527 <getuint+0x38>
	else if (lflag)
f0105505:	85 d2                	test   %edx,%edx
f0105507:	74 10                	je     f0105519 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0105509:	8b 10                	mov    (%eax),%edx
f010550b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010550e:	89 08                	mov    %ecx,(%eax)
f0105510:	8b 02                	mov    (%edx),%eax
f0105512:	ba 00 00 00 00       	mov    $0x0,%edx
f0105517:	eb 0e                	jmp    f0105527 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0105519:	8b 10                	mov    (%eax),%edx
f010551b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010551e:	89 08                	mov    %ecx,(%eax)
f0105520:	8b 02                	mov    (%edx),%eax
f0105522:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0105527:	5d                   	pop    %ebp
f0105528:	c3                   	ret    

f0105529 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0105529:	55                   	push   %ebp
f010552a:	89 e5                	mov    %esp,%ebp
f010552c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010552f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0105533:	8b 10                	mov    (%eax),%edx
f0105535:	3b 50 04             	cmp    0x4(%eax),%edx
f0105538:	73 0a                	jae    f0105544 <sprintputch+0x1b>
		*b->buf++ = ch;
f010553a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010553d:	89 08                	mov    %ecx,(%eax)
f010553f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105542:	88 02                	mov    %al,(%edx)
}
f0105544:	5d                   	pop    %ebp
f0105545:	c3                   	ret    

f0105546 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0105546:	55                   	push   %ebp
f0105547:	89 e5                	mov    %esp,%ebp
f0105549:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010554c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010554f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105553:	8b 45 10             	mov    0x10(%ebp),%eax
f0105556:	89 44 24 08          	mov    %eax,0x8(%esp)
f010555a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010555d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105561:	8b 45 08             	mov    0x8(%ebp),%eax
f0105564:	89 04 24             	mov    %eax,(%esp)
f0105567:	e8 02 00 00 00       	call   f010556e <vprintfmt>
	va_end(ap);
}
f010556c:	c9                   	leave  
f010556d:	c3                   	ret    

f010556e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010556e:	55                   	push   %ebp
f010556f:	89 e5                	mov    %esp,%ebp
f0105571:	57                   	push   %edi
f0105572:	56                   	push   %esi
f0105573:	53                   	push   %ebx
f0105574:	83 ec 3c             	sub    $0x3c,%esp
f0105577:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010557a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010557d:	eb 14                	jmp    f0105593 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010557f:	85 c0                	test   %eax,%eax
f0105581:	0f 84 b3 03 00 00    	je     f010593a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0105587:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010558b:	89 04 24             	mov    %eax,(%esp)
f010558e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105591:	89 f3                	mov    %esi,%ebx
f0105593:	8d 73 01             	lea    0x1(%ebx),%esi
f0105596:	0f b6 03             	movzbl (%ebx),%eax
f0105599:	83 f8 25             	cmp    $0x25,%eax
f010559c:	75 e1                	jne    f010557f <vprintfmt+0x11>
f010559e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01055a2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01055a9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f01055b0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01055b7:	ba 00 00 00 00       	mov    $0x0,%edx
f01055bc:	eb 1d                	jmp    f01055db <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01055be:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01055c0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01055c4:	eb 15                	jmp    f01055db <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01055c6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01055c8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01055cc:	eb 0d                	jmp    f01055db <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01055ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01055d1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01055d4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01055db:	8d 5e 01             	lea    0x1(%esi),%ebx
f01055de:	0f b6 0e             	movzbl (%esi),%ecx
f01055e1:	0f b6 c1             	movzbl %cl,%eax
f01055e4:	83 e9 23             	sub    $0x23,%ecx
f01055e7:	80 f9 55             	cmp    $0x55,%cl
f01055ea:	0f 87 2a 03 00 00    	ja     f010591a <vprintfmt+0x3ac>
f01055f0:	0f b6 c9             	movzbl %cl,%ecx
f01055f3:	ff 24 8d a0 85 10 f0 	jmp    *-0xfef7a60(,%ecx,4)
f01055fa:	89 de                	mov    %ebx,%esi
f01055fc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0105601:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0105604:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0105608:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010560b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010560e:	83 fb 09             	cmp    $0x9,%ebx
f0105611:	77 36                	ja     f0105649 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0105613:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0105616:	eb e9                	jmp    f0105601 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0105618:	8b 45 14             	mov    0x14(%ebp),%eax
f010561b:	8d 48 04             	lea    0x4(%eax),%ecx
f010561e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0105621:	8b 00                	mov    (%eax),%eax
f0105623:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105626:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0105628:	eb 22                	jmp    f010564c <vprintfmt+0xde>
f010562a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010562d:	85 c9                	test   %ecx,%ecx
f010562f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105634:	0f 49 c1             	cmovns %ecx,%eax
f0105637:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010563a:	89 de                	mov    %ebx,%esi
f010563c:	eb 9d                	jmp    f01055db <vprintfmt+0x6d>
f010563e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0105640:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0105647:	eb 92                	jmp    f01055db <vprintfmt+0x6d>
f0105649:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010564c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0105650:	79 89                	jns    f01055db <vprintfmt+0x6d>
f0105652:	e9 77 ff ff ff       	jmp    f01055ce <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0105657:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010565a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010565c:	e9 7a ff ff ff       	jmp    f01055db <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0105661:	8b 45 14             	mov    0x14(%ebp),%eax
f0105664:	8d 50 04             	lea    0x4(%eax),%edx
f0105667:	89 55 14             	mov    %edx,0x14(%ebp)
f010566a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010566e:	8b 00                	mov    (%eax),%eax
f0105670:	89 04 24             	mov    %eax,(%esp)
f0105673:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105676:	e9 18 ff ff ff       	jmp    f0105593 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010567b:	8b 45 14             	mov    0x14(%ebp),%eax
f010567e:	8d 50 04             	lea    0x4(%eax),%edx
f0105681:	89 55 14             	mov    %edx,0x14(%ebp)
f0105684:	8b 00                	mov    (%eax),%eax
f0105686:	99                   	cltd   
f0105687:	31 d0                	xor    %edx,%eax
f0105689:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010568b:	83 f8 09             	cmp    $0x9,%eax
f010568e:	7f 0b                	jg     f010569b <vprintfmt+0x12d>
f0105690:	8b 14 85 00 87 10 f0 	mov    -0xfef7900(,%eax,4),%edx
f0105697:	85 d2                	test   %edx,%edx
f0105699:	75 20                	jne    f01056bb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010569b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010569f:	c7 44 24 08 e6 84 10 	movl   $0xf01084e6,0x8(%esp)
f01056a6:	f0 
f01056a7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01056ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01056ae:	89 04 24             	mov    %eax,(%esp)
f01056b1:	e8 90 fe ff ff       	call   f0105546 <printfmt>
f01056b6:	e9 d8 fe ff ff       	jmp    f0105593 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01056bb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01056bf:	c7 44 24 08 29 79 10 	movl   $0xf0107929,0x8(%esp)
f01056c6:	f0 
f01056c7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01056cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01056ce:	89 04 24             	mov    %eax,(%esp)
f01056d1:	e8 70 fe ff ff       	call   f0105546 <printfmt>
f01056d6:	e9 b8 fe ff ff       	jmp    f0105593 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01056db:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01056de:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01056e1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01056e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01056e7:	8d 50 04             	lea    0x4(%eax),%edx
f01056ea:	89 55 14             	mov    %edx,0x14(%ebp)
f01056ed:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01056ef:	85 f6                	test   %esi,%esi
f01056f1:	b8 df 84 10 f0       	mov    $0xf01084df,%eax
f01056f6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f01056f9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01056fd:	0f 84 97 00 00 00    	je     f010579a <vprintfmt+0x22c>
f0105703:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0105707:	0f 8e 9b 00 00 00    	jle    f01057a8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010570d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105711:	89 34 24             	mov    %esi,(%esp)
f0105714:	e8 9f 03 00 00       	call   f0105ab8 <strnlen>
f0105719:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010571c:	29 c2                	sub    %eax,%edx
f010571e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0105721:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0105725:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105728:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010572b:	8b 75 08             	mov    0x8(%ebp),%esi
f010572e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105731:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105733:	eb 0f                	jmp    f0105744 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0105735:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105739:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010573c:	89 04 24             	mov    %eax,(%esp)
f010573f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105741:	83 eb 01             	sub    $0x1,%ebx
f0105744:	85 db                	test   %ebx,%ebx
f0105746:	7f ed                	jg     f0105735 <vprintfmt+0x1c7>
f0105748:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010574b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010574e:	85 d2                	test   %edx,%edx
f0105750:	b8 00 00 00 00       	mov    $0x0,%eax
f0105755:	0f 49 c2             	cmovns %edx,%eax
f0105758:	29 c2                	sub    %eax,%edx
f010575a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010575d:	89 d7                	mov    %edx,%edi
f010575f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105762:	eb 50                	jmp    f01057b4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0105764:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105768:	74 1e                	je     f0105788 <vprintfmt+0x21a>
f010576a:	0f be d2             	movsbl %dl,%edx
f010576d:	83 ea 20             	sub    $0x20,%edx
f0105770:	83 fa 5e             	cmp    $0x5e,%edx
f0105773:	76 13                	jbe    f0105788 <vprintfmt+0x21a>
					putch('?', putdat);
f0105775:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105778:	89 44 24 04          	mov    %eax,0x4(%esp)
f010577c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0105783:	ff 55 08             	call   *0x8(%ebp)
f0105786:	eb 0d                	jmp    f0105795 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0105788:	8b 55 0c             	mov    0xc(%ebp),%edx
f010578b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010578f:	89 04 24             	mov    %eax,(%esp)
f0105792:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105795:	83 ef 01             	sub    $0x1,%edi
f0105798:	eb 1a                	jmp    f01057b4 <vprintfmt+0x246>
f010579a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010579d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01057a0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01057a3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01057a6:	eb 0c                	jmp    f01057b4 <vprintfmt+0x246>
f01057a8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01057ab:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01057ae:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01057b1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01057b4:	83 c6 01             	add    $0x1,%esi
f01057b7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01057bb:	0f be c2             	movsbl %dl,%eax
f01057be:	85 c0                	test   %eax,%eax
f01057c0:	74 27                	je     f01057e9 <vprintfmt+0x27b>
f01057c2:	85 db                	test   %ebx,%ebx
f01057c4:	78 9e                	js     f0105764 <vprintfmt+0x1f6>
f01057c6:	83 eb 01             	sub    $0x1,%ebx
f01057c9:	79 99                	jns    f0105764 <vprintfmt+0x1f6>
f01057cb:	89 f8                	mov    %edi,%eax
f01057cd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01057d0:	8b 75 08             	mov    0x8(%ebp),%esi
f01057d3:	89 c3                	mov    %eax,%ebx
f01057d5:	eb 1a                	jmp    f01057f1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01057d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01057db:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01057e2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01057e4:	83 eb 01             	sub    $0x1,%ebx
f01057e7:	eb 08                	jmp    f01057f1 <vprintfmt+0x283>
f01057e9:	89 fb                	mov    %edi,%ebx
f01057eb:	8b 75 08             	mov    0x8(%ebp),%esi
f01057ee:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01057f1:	85 db                	test   %ebx,%ebx
f01057f3:	7f e2                	jg     f01057d7 <vprintfmt+0x269>
f01057f5:	89 75 08             	mov    %esi,0x8(%ebp)
f01057f8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01057fb:	e9 93 fd ff ff       	jmp    f0105593 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105800:	83 fa 01             	cmp    $0x1,%edx
f0105803:	7e 16                	jle    f010581b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0105805:	8b 45 14             	mov    0x14(%ebp),%eax
f0105808:	8d 50 08             	lea    0x8(%eax),%edx
f010580b:	89 55 14             	mov    %edx,0x14(%ebp)
f010580e:	8b 50 04             	mov    0x4(%eax),%edx
f0105811:	8b 00                	mov    (%eax),%eax
f0105813:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105816:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0105819:	eb 32                	jmp    f010584d <vprintfmt+0x2df>
	else if (lflag)
f010581b:	85 d2                	test   %edx,%edx
f010581d:	74 18                	je     f0105837 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010581f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105822:	8d 50 04             	lea    0x4(%eax),%edx
f0105825:	89 55 14             	mov    %edx,0x14(%ebp)
f0105828:	8b 30                	mov    (%eax),%esi
f010582a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010582d:	89 f0                	mov    %esi,%eax
f010582f:	c1 f8 1f             	sar    $0x1f,%eax
f0105832:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105835:	eb 16                	jmp    f010584d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0105837:	8b 45 14             	mov    0x14(%ebp),%eax
f010583a:	8d 50 04             	lea    0x4(%eax),%edx
f010583d:	89 55 14             	mov    %edx,0x14(%ebp)
f0105840:	8b 30                	mov    (%eax),%esi
f0105842:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0105845:	89 f0                	mov    %esi,%eax
f0105847:	c1 f8 1f             	sar    $0x1f,%eax
f010584a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010584d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105850:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0105853:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0105858:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010585c:	0f 89 80 00 00 00    	jns    f01058e2 <vprintfmt+0x374>
				putch('-', putdat);
f0105862:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105866:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010586d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0105870:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105873:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0105876:	f7 d8                	neg    %eax
f0105878:	83 d2 00             	adc    $0x0,%edx
f010587b:	f7 da                	neg    %edx
			}
			base = 10;
f010587d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0105882:	eb 5e                	jmp    f01058e2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0105884:	8d 45 14             	lea    0x14(%ebp),%eax
f0105887:	e8 63 fc ff ff       	call   f01054ef <getuint>
			base = 10;
f010588c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0105891:	eb 4f                	jmp    f01058e2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0105893:	8d 45 14             	lea    0x14(%ebp),%eax
f0105896:	e8 54 fc ff ff       	call   f01054ef <getuint>
			base = 8;
f010589b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01058a0:	eb 40                	jmp    f01058e2 <vprintfmt+0x374>
			
		// pointer
		case 'p':
			putch('0', putdat);
f01058a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01058a6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01058ad:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01058b0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01058b4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01058bb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01058be:	8b 45 14             	mov    0x14(%ebp),%eax
f01058c1:	8d 50 04             	lea    0x4(%eax),%edx
f01058c4:	89 55 14             	mov    %edx,0x14(%ebp)
			
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01058c7:	8b 00                	mov    (%eax),%eax
f01058c9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01058ce:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01058d3:	eb 0d                	jmp    f01058e2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01058d5:	8d 45 14             	lea    0x14(%ebp),%eax
f01058d8:	e8 12 fc ff ff       	call   f01054ef <getuint>
			base = 16;
f01058dd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01058e2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01058e6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01058ea:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01058ed:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01058f1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01058f5:	89 04 24             	mov    %eax,(%esp)
f01058f8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01058fc:	89 fa                	mov    %edi,%edx
f01058fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0105901:	e8 fa fa ff ff       	call   f0105400 <printnum>
			break;
f0105906:	e9 88 fc ff ff       	jmp    f0105593 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010590b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010590f:	89 04 24             	mov    %eax,(%esp)
f0105912:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105915:	e9 79 fc ff ff       	jmp    f0105593 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010591a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010591e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0105925:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105928:	89 f3                	mov    %esi,%ebx
f010592a:	eb 03                	jmp    f010592f <vprintfmt+0x3c1>
f010592c:	83 eb 01             	sub    $0x1,%ebx
f010592f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0105933:	75 f7                	jne    f010592c <vprintfmt+0x3be>
f0105935:	e9 59 fc ff ff       	jmp    f0105593 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010593a:	83 c4 3c             	add    $0x3c,%esp
f010593d:	5b                   	pop    %ebx
f010593e:	5e                   	pop    %esi
f010593f:	5f                   	pop    %edi
f0105940:	5d                   	pop    %ebp
f0105941:	c3                   	ret    

f0105942 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105942:	55                   	push   %ebp
f0105943:	89 e5                	mov    %esp,%ebp
f0105945:	83 ec 28             	sub    $0x28,%esp
f0105948:	8b 45 08             	mov    0x8(%ebp),%eax
f010594b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010594e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105951:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105955:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105958:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010595f:	85 c0                	test   %eax,%eax
f0105961:	74 30                	je     f0105993 <vsnprintf+0x51>
f0105963:	85 d2                	test   %edx,%edx
f0105965:	7e 2c                	jle    f0105993 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105967:	8b 45 14             	mov    0x14(%ebp),%eax
f010596a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010596e:	8b 45 10             	mov    0x10(%ebp),%eax
f0105971:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105975:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105978:	89 44 24 04          	mov    %eax,0x4(%esp)
f010597c:	c7 04 24 29 55 10 f0 	movl   $0xf0105529,(%esp)
f0105983:	e8 e6 fb ff ff       	call   f010556e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105988:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010598b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010598e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105991:	eb 05                	jmp    f0105998 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0105993:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105998:	c9                   	leave  
f0105999:	c3                   	ret    

f010599a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010599a:	55                   	push   %ebp
f010599b:	89 e5                	mov    %esp,%ebp
f010599d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01059a0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01059a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01059a7:	8b 45 10             	mov    0x10(%ebp),%eax
f01059aa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01059ae:	8b 45 0c             	mov    0xc(%ebp),%eax
f01059b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01059b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01059b8:	89 04 24             	mov    %eax,(%esp)
f01059bb:	e8 82 ff ff ff       	call   f0105942 <vsnprintf>
	va_end(ap);

	return rc;
}
f01059c0:	c9                   	leave  
f01059c1:	c3                   	ret    
f01059c2:	66 90                	xchg   %ax,%ax
f01059c4:	66 90                	xchg   %ax,%ax
f01059c6:	66 90                	xchg   %ax,%ax
f01059c8:	66 90                	xchg   %ax,%ax
f01059ca:	66 90                	xchg   %ax,%ax
f01059cc:	66 90                	xchg   %ax,%ax
f01059ce:	66 90                	xchg   %ax,%ax

f01059d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01059d0:	55                   	push   %ebp
f01059d1:	89 e5                	mov    %esp,%ebp
f01059d3:	57                   	push   %edi
f01059d4:	56                   	push   %esi
f01059d5:	53                   	push   %ebx
f01059d6:	83 ec 1c             	sub    $0x1c,%esp
f01059d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01059dc:	85 c0                	test   %eax,%eax
f01059de:	74 10                	je     f01059f0 <readline+0x20>
		cprintf("%s", prompt);
f01059e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01059e4:	c7 04 24 29 79 10 f0 	movl   $0xf0107929,(%esp)
f01059eb:	e8 c6 e6 ff ff       	call   f01040b6 <cprintf>

	i = 0;
	echoing = iscons(0);
f01059f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01059f7:	e8 af ad ff ff       	call   f01007ab <iscons>
f01059fc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01059fe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105a03:	e8 92 ad ff ff       	call   f010079a <getchar>
f0105a08:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0105a0a:	85 c0                	test   %eax,%eax
f0105a0c:	79 17                	jns    f0105a25 <readline+0x55>
			cprintf("read error: %e\n", c);
f0105a0e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105a12:	c7 04 24 28 87 10 f0 	movl   $0xf0108728,(%esp)
f0105a19:	e8 98 e6 ff ff       	call   f01040b6 <cprintf>
			return NULL;
f0105a1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105a23:	eb 6d                	jmp    f0105a92 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105a25:	83 f8 7f             	cmp    $0x7f,%eax
f0105a28:	74 05                	je     f0105a2f <readline+0x5f>
f0105a2a:	83 f8 08             	cmp    $0x8,%eax
f0105a2d:	75 19                	jne    f0105a48 <readline+0x78>
f0105a2f:	85 f6                	test   %esi,%esi
f0105a31:	7e 15                	jle    f0105a48 <readline+0x78>
			if (echoing)
f0105a33:	85 ff                	test   %edi,%edi
f0105a35:	74 0c                	je     f0105a43 <readline+0x73>
				cputchar('\b');
f0105a37:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0105a3e:	e8 47 ad ff ff       	call   f010078a <cputchar>
			i--;
f0105a43:	83 ee 01             	sub    $0x1,%esi
f0105a46:	eb bb                	jmp    f0105a03 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105a48:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0105a4e:	7f 1c                	jg     f0105a6c <readline+0x9c>
f0105a50:	83 fb 1f             	cmp    $0x1f,%ebx
f0105a53:	7e 17                	jle    f0105a6c <readline+0x9c>
			if (echoing)
f0105a55:	85 ff                	test   %edi,%edi
f0105a57:	74 08                	je     f0105a61 <readline+0x91>
				cputchar(c);
f0105a59:	89 1c 24             	mov    %ebx,(%esp)
f0105a5c:	e8 29 ad ff ff       	call   f010078a <cputchar>
			buf[i++] = c;
f0105a61:	88 9e 80 ca 22 f0    	mov    %bl,-0xfdd3580(%esi)
f0105a67:	8d 76 01             	lea    0x1(%esi),%esi
f0105a6a:	eb 97                	jmp    f0105a03 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0105a6c:	83 fb 0d             	cmp    $0xd,%ebx
f0105a6f:	74 05                	je     f0105a76 <readline+0xa6>
f0105a71:	83 fb 0a             	cmp    $0xa,%ebx
f0105a74:	75 8d                	jne    f0105a03 <readline+0x33>
			if (echoing)
f0105a76:	85 ff                	test   %edi,%edi
f0105a78:	74 0c                	je     f0105a86 <readline+0xb6>
				cputchar('\n');
f0105a7a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0105a81:	e8 04 ad ff ff       	call   f010078a <cputchar>
			buf[i] = 0;
f0105a86:	c6 86 80 ca 22 f0 00 	movb   $0x0,-0xfdd3580(%esi)
			return buf;
f0105a8d:	b8 80 ca 22 f0       	mov    $0xf022ca80,%eax
		}
	}
}
f0105a92:	83 c4 1c             	add    $0x1c,%esp
f0105a95:	5b                   	pop    %ebx
f0105a96:	5e                   	pop    %esi
f0105a97:	5f                   	pop    %edi
f0105a98:	5d                   	pop    %ebp
f0105a99:	c3                   	ret    
f0105a9a:	66 90                	xchg   %ax,%ax
f0105a9c:	66 90                	xchg   %ax,%ax
f0105a9e:	66 90                	xchg   %ax,%ax

f0105aa0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105aa0:	55                   	push   %ebp
f0105aa1:	89 e5                	mov    %esp,%ebp
f0105aa3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105aa6:	b8 00 00 00 00       	mov    $0x0,%eax
f0105aab:	eb 03                	jmp    f0105ab0 <strlen+0x10>
		n++;
f0105aad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105ab0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105ab4:	75 f7                	jne    f0105aad <strlen+0xd>
		n++;
	return n;
}
f0105ab6:	5d                   	pop    %ebp
f0105ab7:	c3                   	ret    

f0105ab8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105ab8:	55                   	push   %ebp
f0105ab9:	89 e5                	mov    %esp,%ebp
f0105abb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105abe:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105ac1:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ac6:	eb 03                	jmp    f0105acb <strnlen+0x13>
		n++;
f0105ac8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105acb:	39 d0                	cmp    %edx,%eax
f0105acd:	74 06                	je     f0105ad5 <strnlen+0x1d>
f0105acf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0105ad3:	75 f3                	jne    f0105ac8 <strnlen+0x10>
		n++;
	return n;
}
f0105ad5:	5d                   	pop    %ebp
f0105ad6:	c3                   	ret    

f0105ad7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105ad7:	55                   	push   %ebp
f0105ad8:	89 e5                	mov    %esp,%ebp
f0105ada:	53                   	push   %ebx
f0105adb:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ade:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105ae1:	89 c2                	mov    %eax,%edx
f0105ae3:	83 c2 01             	add    $0x1,%edx
f0105ae6:	83 c1 01             	add    $0x1,%ecx
f0105ae9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0105aed:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105af0:	84 db                	test   %bl,%bl
f0105af2:	75 ef                	jne    f0105ae3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105af4:	5b                   	pop    %ebx
f0105af5:	5d                   	pop    %ebp
f0105af6:	c3                   	ret    

f0105af7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105af7:	55                   	push   %ebp
f0105af8:	89 e5                	mov    %esp,%ebp
f0105afa:	53                   	push   %ebx
f0105afb:	83 ec 08             	sub    $0x8,%esp
f0105afe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105b01:	89 1c 24             	mov    %ebx,(%esp)
f0105b04:	e8 97 ff ff ff       	call   f0105aa0 <strlen>
	strcpy(dst + len, src);
f0105b09:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105b0c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105b10:	01 d8                	add    %ebx,%eax
f0105b12:	89 04 24             	mov    %eax,(%esp)
f0105b15:	e8 bd ff ff ff       	call   f0105ad7 <strcpy>
	return dst;
}
f0105b1a:	89 d8                	mov    %ebx,%eax
f0105b1c:	83 c4 08             	add    $0x8,%esp
f0105b1f:	5b                   	pop    %ebx
f0105b20:	5d                   	pop    %ebp
f0105b21:	c3                   	ret    

f0105b22 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105b22:	55                   	push   %ebp
f0105b23:	89 e5                	mov    %esp,%ebp
f0105b25:	56                   	push   %esi
f0105b26:	53                   	push   %ebx
f0105b27:	8b 75 08             	mov    0x8(%ebp),%esi
f0105b2a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105b2d:	89 f3                	mov    %esi,%ebx
f0105b2f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105b32:	89 f2                	mov    %esi,%edx
f0105b34:	eb 0f                	jmp    f0105b45 <strncpy+0x23>
		*dst++ = *src;
f0105b36:	83 c2 01             	add    $0x1,%edx
f0105b39:	0f b6 01             	movzbl (%ecx),%eax
f0105b3c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105b3f:	80 39 01             	cmpb   $0x1,(%ecx)
f0105b42:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105b45:	39 da                	cmp    %ebx,%edx
f0105b47:	75 ed                	jne    f0105b36 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0105b49:	89 f0                	mov    %esi,%eax
f0105b4b:	5b                   	pop    %ebx
f0105b4c:	5e                   	pop    %esi
f0105b4d:	5d                   	pop    %ebp
f0105b4e:	c3                   	ret    

f0105b4f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105b4f:	55                   	push   %ebp
f0105b50:	89 e5                	mov    %esp,%ebp
f0105b52:	56                   	push   %esi
f0105b53:	53                   	push   %ebx
f0105b54:	8b 75 08             	mov    0x8(%ebp),%esi
f0105b57:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105b5a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0105b5d:	89 f0                	mov    %esi,%eax
f0105b5f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105b63:	85 c9                	test   %ecx,%ecx
f0105b65:	75 0b                	jne    f0105b72 <strlcpy+0x23>
f0105b67:	eb 1d                	jmp    f0105b86 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105b69:	83 c0 01             	add    $0x1,%eax
f0105b6c:	83 c2 01             	add    $0x1,%edx
f0105b6f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105b72:	39 d8                	cmp    %ebx,%eax
f0105b74:	74 0b                	je     f0105b81 <strlcpy+0x32>
f0105b76:	0f b6 0a             	movzbl (%edx),%ecx
f0105b79:	84 c9                	test   %cl,%cl
f0105b7b:	75 ec                	jne    f0105b69 <strlcpy+0x1a>
f0105b7d:	89 c2                	mov    %eax,%edx
f0105b7f:	eb 02                	jmp    f0105b83 <strlcpy+0x34>
f0105b81:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0105b83:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0105b86:	29 f0                	sub    %esi,%eax
}
f0105b88:	5b                   	pop    %ebx
f0105b89:	5e                   	pop    %esi
f0105b8a:	5d                   	pop    %ebp
f0105b8b:	c3                   	ret    

f0105b8c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105b8c:	55                   	push   %ebp
f0105b8d:	89 e5                	mov    %esp,%ebp
f0105b8f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105b92:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105b95:	eb 06                	jmp    f0105b9d <strcmp+0x11>
		p++, q++;
f0105b97:	83 c1 01             	add    $0x1,%ecx
f0105b9a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105b9d:	0f b6 01             	movzbl (%ecx),%eax
f0105ba0:	84 c0                	test   %al,%al
f0105ba2:	74 04                	je     f0105ba8 <strcmp+0x1c>
f0105ba4:	3a 02                	cmp    (%edx),%al
f0105ba6:	74 ef                	je     f0105b97 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105ba8:	0f b6 c0             	movzbl %al,%eax
f0105bab:	0f b6 12             	movzbl (%edx),%edx
f0105bae:	29 d0                	sub    %edx,%eax
}
f0105bb0:	5d                   	pop    %ebp
f0105bb1:	c3                   	ret    

f0105bb2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105bb2:	55                   	push   %ebp
f0105bb3:	89 e5                	mov    %esp,%ebp
f0105bb5:	53                   	push   %ebx
f0105bb6:	8b 45 08             	mov    0x8(%ebp),%eax
f0105bb9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105bbc:	89 c3                	mov    %eax,%ebx
f0105bbe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105bc1:	eb 06                	jmp    f0105bc9 <strncmp+0x17>
		n--, p++, q++;
f0105bc3:	83 c0 01             	add    $0x1,%eax
f0105bc6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105bc9:	39 d8                	cmp    %ebx,%eax
f0105bcb:	74 15                	je     f0105be2 <strncmp+0x30>
f0105bcd:	0f b6 08             	movzbl (%eax),%ecx
f0105bd0:	84 c9                	test   %cl,%cl
f0105bd2:	74 04                	je     f0105bd8 <strncmp+0x26>
f0105bd4:	3a 0a                	cmp    (%edx),%cl
f0105bd6:	74 eb                	je     f0105bc3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105bd8:	0f b6 00             	movzbl (%eax),%eax
f0105bdb:	0f b6 12             	movzbl (%edx),%edx
f0105bde:	29 d0                	sub    %edx,%eax
f0105be0:	eb 05                	jmp    f0105be7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105be2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105be7:	5b                   	pop    %ebx
f0105be8:	5d                   	pop    %ebp
f0105be9:	c3                   	ret    

f0105bea <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105bea:	55                   	push   %ebp
f0105beb:	89 e5                	mov    %esp,%ebp
f0105bed:	8b 45 08             	mov    0x8(%ebp),%eax
f0105bf0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105bf4:	eb 07                	jmp    f0105bfd <strchr+0x13>
		if (*s == c)
f0105bf6:	38 ca                	cmp    %cl,%dl
f0105bf8:	74 0f                	je     f0105c09 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0105bfa:	83 c0 01             	add    $0x1,%eax
f0105bfd:	0f b6 10             	movzbl (%eax),%edx
f0105c00:	84 d2                	test   %dl,%dl
f0105c02:	75 f2                	jne    f0105bf6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105c04:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105c09:	5d                   	pop    %ebp
f0105c0a:	c3                   	ret    

f0105c0b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105c0b:	55                   	push   %ebp
f0105c0c:	89 e5                	mov    %esp,%ebp
f0105c0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c11:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105c15:	eb 07                	jmp    f0105c1e <strfind+0x13>
		if (*s == c)
f0105c17:	38 ca                	cmp    %cl,%dl
f0105c19:	74 0a                	je     f0105c25 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0105c1b:	83 c0 01             	add    $0x1,%eax
f0105c1e:	0f b6 10             	movzbl (%eax),%edx
f0105c21:	84 d2                	test   %dl,%dl
f0105c23:	75 f2                	jne    f0105c17 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0105c25:	5d                   	pop    %ebp
f0105c26:	c3                   	ret    

f0105c27 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105c27:	55                   	push   %ebp
f0105c28:	89 e5                	mov    %esp,%ebp
f0105c2a:	57                   	push   %edi
f0105c2b:	56                   	push   %esi
f0105c2c:	53                   	push   %ebx
f0105c2d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105c30:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105c33:	85 c9                	test   %ecx,%ecx
f0105c35:	74 36                	je     f0105c6d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105c37:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105c3d:	75 28                	jne    f0105c67 <memset+0x40>
f0105c3f:	f6 c1 03             	test   $0x3,%cl
f0105c42:	75 23                	jne    f0105c67 <memset+0x40>
		c &= 0xFF;
f0105c44:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105c48:	89 d3                	mov    %edx,%ebx
f0105c4a:	c1 e3 08             	shl    $0x8,%ebx
f0105c4d:	89 d6                	mov    %edx,%esi
f0105c4f:	c1 e6 18             	shl    $0x18,%esi
f0105c52:	89 d0                	mov    %edx,%eax
f0105c54:	c1 e0 10             	shl    $0x10,%eax
f0105c57:	09 f0                	or     %esi,%eax
f0105c59:	09 c2                	or     %eax,%edx
f0105c5b:	89 d0                	mov    %edx,%eax
f0105c5d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0105c5f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0105c62:	fc                   	cld    
f0105c63:	f3 ab                	rep stos %eax,%es:(%edi)
f0105c65:	eb 06                	jmp    f0105c6d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105c67:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105c6a:	fc                   	cld    
f0105c6b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105c6d:	89 f8                	mov    %edi,%eax
f0105c6f:	5b                   	pop    %ebx
f0105c70:	5e                   	pop    %esi
f0105c71:	5f                   	pop    %edi
f0105c72:	5d                   	pop    %ebp
f0105c73:	c3                   	ret    

f0105c74 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105c74:	55                   	push   %ebp
f0105c75:	89 e5                	mov    %esp,%ebp
f0105c77:	57                   	push   %edi
f0105c78:	56                   	push   %esi
f0105c79:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c7c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105c7f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105c82:	39 c6                	cmp    %eax,%esi
f0105c84:	73 35                	jae    f0105cbb <memmove+0x47>
f0105c86:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105c89:	39 d0                	cmp    %edx,%eax
f0105c8b:	73 2e                	jae    f0105cbb <memmove+0x47>
		s += n;
		d += n;
f0105c8d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0105c90:	89 d6                	mov    %edx,%esi
f0105c92:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105c94:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105c9a:	75 13                	jne    f0105caf <memmove+0x3b>
f0105c9c:	f6 c1 03             	test   $0x3,%cl
f0105c9f:	75 0e                	jne    f0105caf <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105ca1:	83 ef 04             	sub    $0x4,%edi
f0105ca4:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105ca7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0105caa:	fd                   	std    
f0105cab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105cad:	eb 09                	jmp    f0105cb8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105caf:	83 ef 01             	sub    $0x1,%edi
f0105cb2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105cb5:	fd                   	std    
f0105cb6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105cb8:	fc                   	cld    
f0105cb9:	eb 1d                	jmp    f0105cd8 <memmove+0x64>
f0105cbb:	89 f2                	mov    %esi,%edx
f0105cbd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105cbf:	f6 c2 03             	test   $0x3,%dl
f0105cc2:	75 0f                	jne    f0105cd3 <memmove+0x5f>
f0105cc4:	f6 c1 03             	test   $0x3,%cl
f0105cc7:	75 0a                	jne    f0105cd3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105cc9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0105ccc:	89 c7                	mov    %eax,%edi
f0105cce:	fc                   	cld    
f0105ccf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105cd1:	eb 05                	jmp    f0105cd8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105cd3:	89 c7                	mov    %eax,%edi
f0105cd5:	fc                   	cld    
f0105cd6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105cd8:	5e                   	pop    %esi
f0105cd9:	5f                   	pop    %edi
f0105cda:	5d                   	pop    %ebp
f0105cdb:	c3                   	ret    

f0105cdc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105cdc:	55                   	push   %ebp
f0105cdd:	89 e5                	mov    %esp,%ebp
f0105cdf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105ce2:	8b 45 10             	mov    0x10(%ebp),%eax
f0105ce5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105ce9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105cec:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105cf0:	8b 45 08             	mov    0x8(%ebp),%eax
f0105cf3:	89 04 24             	mov    %eax,(%esp)
f0105cf6:	e8 79 ff ff ff       	call   f0105c74 <memmove>
}
f0105cfb:	c9                   	leave  
f0105cfc:	c3                   	ret    

f0105cfd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105cfd:	55                   	push   %ebp
f0105cfe:	89 e5                	mov    %esp,%ebp
f0105d00:	56                   	push   %esi
f0105d01:	53                   	push   %ebx
f0105d02:	8b 55 08             	mov    0x8(%ebp),%edx
f0105d05:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105d08:	89 d6                	mov    %edx,%esi
f0105d0a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105d0d:	eb 1a                	jmp    f0105d29 <memcmp+0x2c>
		if (*s1 != *s2)
f0105d0f:	0f b6 02             	movzbl (%edx),%eax
f0105d12:	0f b6 19             	movzbl (%ecx),%ebx
f0105d15:	38 d8                	cmp    %bl,%al
f0105d17:	74 0a                	je     f0105d23 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105d19:	0f b6 c0             	movzbl %al,%eax
f0105d1c:	0f b6 db             	movzbl %bl,%ebx
f0105d1f:	29 d8                	sub    %ebx,%eax
f0105d21:	eb 0f                	jmp    f0105d32 <memcmp+0x35>
		s1++, s2++;
f0105d23:	83 c2 01             	add    $0x1,%edx
f0105d26:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105d29:	39 f2                	cmp    %esi,%edx
f0105d2b:	75 e2                	jne    f0105d0f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0105d2d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105d32:	5b                   	pop    %ebx
f0105d33:	5e                   	pop    %esi
f0105d34:	5d                   	pop    %ebp
f0105d35:	c3                   	ret    

f0105d36 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105d36:	55                   	push   %ebp
f0105d37:	89 e5                	mov    %esp,%ebp
f0105d39:	8b 45 08             	mov    0x8(%ebp),%eax
f0105d3c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105d3f:	89 c2                	mov    %eax,%edx
f0105d41:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105d44:	eb 07                	jmp    f0105d4d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105d46:	38 08                	cmp    %cl,(%eax)
f0105d48:	74 07                	je     f0105d51 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105d4a:	83 c0 01             	add    $0x1,%eax
f0105d4d:	39 d0                	cmp    %edx,%eax
f0105d4f:	72 f5                	jb     f0105d46 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0105d51:	5d                   	pop    %ebp
f0105d52:	c3                   	ret    

f0105d53 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105d53:	55                   	push   %ebp
f0105d54:	89 e5                	mov    %esp,%ebp
f0105d56:	57                   	push   %edi
f0105d57:	56                   	push   %esi
f0105d58:	53                   	push   %ebx
f0105d59:	8b 55 08             	mov    0x8(%ebp),%edx
f0105d5c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105d5f:	eb 03                	jmp    f0105d64 <strtol+0x11>
		s++;
f0105d61:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105d64:	0f b6 0a             	movzbl (%edx),%ecx
f0105d67:	80 f9 09             	cmp    $0x9,%cl
f0105d6a:	74 f5                	je     f0105d61 <strtol+0xe>
f0105d6c:	80 f9 20             	cmp    $0x20,%cl
f0105d6f:	74 f0                	je     f0105d61 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105d71:	80 f9 2b             	cmp    $0x2b,%cl
f0105d74:	75 0a                	jne    f0105d80 <strtol+0x2d>
		s++;
f0105d76:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105d79:	bf 00 00 00 00       	mov    $0x0,%edi
f0105d7e:	eb 11                	jmp    f0105d91 <strtol+0x3e>
f0105d80:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105d85:	80 f9 2d             	cmp    $0x2d,%cl
f0105d88:	75 07                	jne    f0105d91 <strtol+0x3e>
		s++, neg = 1;
f0105d8a:	8d 52 01             	lea    0x1(%edx),%edx
f0105d8d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105d91:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0105d96:	75 15                	jne    f0105dad <strtol+0x5a>
f0105d98:	80 3a 30             	cmpb   $0x30,(%edx)
f0105d9b:	75 10                	jne    f0105dad <strtol+0x5a>
f0105d9d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0105da1:	75 0a                	jne    f0105dad <strtol+0x5a>
		s += 2, base = 16;
f0105da3:	83 c2 02             	add    $0x2,%edx
f0105da6:	b8 10 00 00 00       	mov    $0x10,%eax
f0105dab:	eb 10                	jmp    f0105dbd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0105dad:	85 c0                	test   %eax,%eax
f0105daf:	75 0c                	jne    f0105dbd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105db1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105db3:	80 3a 30             	cmpb   $0x30,(%edx)
f0105db6:	75 05                	jne    f0105dbd <strtol+0x6a>
		s++, base = 8;
f0105db8:	83 c2 01             	add    $0x1,%edx
f0105dbb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0105dbd:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105dc2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105dc5:	0f b6 0a             	movzbl (%edx),%ecx
f0105dc8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0105dcb:	89 f0                	mov    %esi,%eax
f0105dcd:	3c 09                	cmp    $0x9,%al
f0105dcf:	77 08                	ja     f0105dd9 <strtol+0x86>
			dig = *s - '0';
f0105dd1:	0f be c9             	movsbl %cl,%ecx
f0105dd4:	83 e9 30             	sub    $0x30,%ecx
f0105dd7:	eb 20                	jmp    f0105df9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0105dd9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0105ddc:	89 f0                	mov    %esi,%eax
f0105dde:	3c 19                	cmp    $0x19,%al
f0105de0:	77 08                	ja     f0105dea <strtol+0x97>
			dig = *s - 'a' + 10;
f0105de2:	0f be c9             	movsbl %cl,%ecx
f0105de5:	83 e9 57             	sub    $0x57,%ecx
f0105de8:	eb 0f                	jmp    f0105df9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0105dea:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0105ded:	89 f0                	mov    %esi,%eax
f0105def:	3c 19                	cmp    $0x19,%al
f0105df1:	77 16                	ja     f0105e09 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0105df3:	0f be c9             	movsbl %cl,%ecx
f0105df6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0105df9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0105dfc:	7d 0f                	jge    f0105e0d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0105dfe:	83 c2 01             	add    $0x1,%edx
f0105e01:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0105e05:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0105e07:	eb bc                	jmp    f0105dc5 <strtol+0x72>
f0105e09:	89 d8                	mov    %ebx,%eax
f0105e0b:	eb 02                	jmp    f0105e0f <strtol+0xbc>
f0105e0d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0105e0f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105e13:	74 05                	je     f0105e1a <strtol+0xc7>
		*endptr = (char *) s;
f0105e15:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105e18:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0105e1a:	f7 d8                	neg    %eax
f0105e1c:	85 ff                	test   %edi,%edi
f0105e1e:	0f 44 c3             	cmove  %ebx,%eax
}
f0105e21:	5b                   	pop    %ebx
f0105e22:	5e                   	pop    %esi
f0105e23:	5f                   	pop    %edi
f0105e24:	5d                   	pop    %ebp
f0105e25:	c3                   	ret    
f0105e26:	66 90                	xchg   %ax,%ax

f0105e28 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105e28:	fa                   	cli    

	xorw    %ax, %ax
f0105e29:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0105e2b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105e2d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105e2f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105e31:	0f 01 16             	lgdtl  (%esi)
f0105e34:	74 70                	je     f0105ea6 <mpentry_end+0x4>
	movl    %cr0, %eax
f0105e36:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105e39:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105e3d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105e40:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105e46:	08 00                	or     %al,(%eax)

f0105e48 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105e48:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105e4c:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105e4e:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105e50:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105e52:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105e56:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105e58:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0105e5a:	b8 00 f0 11 00       	mov    $0x11f000,%eax
	movl    %eax, %cr3
f0105e5f:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105e62:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105e65:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0105e6a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105e6d:	8b 25 84 ce 22 f0    	mov    0xf022ce84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105e73:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105e78:	b8 e2 01 10 f0       	mov    $0xf01001e2,%eax
	call    *%eax
f0105e7d:	ff d0                	call   *%eax

f0105e7f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105e7f:	eb fe                	jmp    f0105e7f <spin>
f0105e81:	8d 76 00             	lea    0x0(%esi),%esi

f0105e84 <gdt>:
	...
f0105e8c:	ff                   	(bad)  
f0105e8d:	ff 00                	incl   (%eax)
f0105e8f:	00 00                	add    %al,(%eax)
f0105e91:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105e98:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f0105e9c <gdtdesc>:
f0105e9c:	17                   	pop    %ss
f0105e9d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105ea2 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105ea2:	90                   	nop
f0105ea3:	66 90                	xchg   %ax,%ax
f0105ea5:	66 90                	xchg   %ax,%ax
f0105ea7:	66 90                	xchg   %ax,%ax
f0105ea9:	66 90                	xchg   %ax,%ax
f0105eab:	66 90                	xchg   %ax,%ax
f0105ead:	66 90                	xchg   %ax,%ax
f0105eaf:	90                   	nop

f0105eb0 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105eb0:	55                   	push   %ebp
f0105eb1:	89 e5                	mov    %esp,%ebp
f0105eb3:	56                   	push   %esi
f0105eb4:	53                   	push   %ebx
f0105eb5:	83 ec 10             	sub    $0x10,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105eb8:	8b 0d 88 ce 22 f0    	mov    0xf022ce88,%ecx
f0105ebe:	89 c3                	mov    %eax,%ebx
f0105ec0:	c1 eb 0c             	shr    $0xc,%ebx
f0105ec3:	39 cb                	cmp    %ecx,%ebx
f0105ec5:	72 20                	jb     f0105ee7 <mpsearch1+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105ec7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105ecb:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0105ed2:	f0 
f0105ed3:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0105eda:	00 
f0105edb:	c7 04 24 c5 88 10 f0 	movl   $0xf01088c5,(%esp)
f0105ee2:	e8 59 a1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105ee7:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105eed:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105eef:	89 c2                	mov    %eax,%edx
f0105ef1:	c1 ea 0c             	shr    $0xc,%edx
f0105ef4:	39 d1                	cmp    %edx,%ecx
f0105ef6:	77 20                	ja     f0105f18 <mpsearch1+0x68>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105ef8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105efc:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0105f03:	f0 
f0105f04:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0105f0b:	00 
f0105f0c:	c7 04 24 c5 88 10 f0 	movl   $0xf01088c5,(%esp)
f0105f13:	e8 28 a1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105f18:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0105f1e:	eb 36                	jmp    f0105f56 <mpsearch1+0xa6>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105f20:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105f27:	00 
f0105f28:	c7 44 24 04 d5 88 10 	movl   $0xf01088d5,0x4(%esp)
f0105f2f:	f0 
f0105f30:	89 1c 24             	mov    %ebx,(%esp)
f0105f33:	e8 c5 fd ff ff       	call   f0105cfd <memcmp>
f0105f38:	85 c0                	test   %eax,%eax
f0105f3a:	75 17                	jne    f0105f53 <mpsearch1+0xa3>
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105f3c:	ba 00 00 00 00       	mov    $0x0,%edx
		sum += ((uint8_t *)addr)[i];
f0105f41:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0105f45:	01 c8                	add    %ecx,%eax
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105f47:	83 c2 01             	add    $0x1,%edx
f0105f4a:	83 fa 10             	cmp    $0x10,%edx
f0105f4d:	75 f2                	jne    f0105f41 <mpsearch1+0x91>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105f4f:	84 c0                	test   %al,%al
f0105f51:	74 0e                	je     f0105f61 <mpsearch1+0xb1>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105f53:	83 c3 10             	add    $0x10,%ebx
f0105f56:	39 f3                	cmp    %esi,%ebx
f0105f58:	72 c6                	jb     f0105f20 <mpsearch1+0x70>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105f5a:	b8 00 00 00 00       	mov    $0x0,%eax
f0105f5f:	eb 02                	jmp    f0105f63 <mpsearch1+0xb3>
f0105f61:	89 d8                	mov    %ebx,%eax
}
f0105f63:	83 c4 10             	add    $0x10,%esp
f0105f66:	5b                   	pop    %ebx
f0105f67:	5e                   	pop    %esi
f0105f68:	5d                   	pop    %ebp
f0105f69:	c3                   	ret    

f0105f6a <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105f6a:	55                   	push   %ebp
f0105f6b:	89 e5                	mov    %esp,%ebp
f0105f6d:	57                   	push   %edi
f0105f6e:	56                   	push   %esi
f0105f6f:	53                   	push   %ebx
f0105f70:	83 ec 2c             	sub    $0x2c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105f73:	c7 05 c0 d3 22 f0 20 	movl   $0xf022d020,0xf022d3c0
f0105f7a:	d0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105f7d:	83 3d 88 ce 22 f0 00 	cmpl   $0x0,0xf022ce88
f0105f84:	75 24                	jne    f0105faa <mp_init+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105f86:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
f0105f8d:	00 
f0105f8e:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f0105f95:	f0 
f0105f96:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0105f9d:	00 
f0105f9e:	c7 04 24 c5 88 10 f0 	movl   $0xf01088c5,(%esp)
f0105fa5:	e8 96 a0 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105faa:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105fb1:	85 c0                	test   %eax,%eax
f0105fb3:	74 16                	je     f0105fcb <mp_init+0x61>
		p <<= 4;	// Translate from segment to PA
f0105fb5:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105fb8:	ba 00 04 00 00       	mov    $0x400,%edx
f0105fbd:	e8 ee fe ff ff       	call   f0105eb0 <mpsearch1>
f0105fc2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105fc5:	85 c0                	test   %eax,%eax
f0105fc7:	75 3c                	jne    f0106005 <mp_init+0x9b>
f0105fc9:	eb 20                	jmp    f0105feb <mp_init+0x81>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105fcb:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105fd2:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105fd5:	2d 00 04 00 00       	sub    $0x400,%eax
f0105fda:	ba 00 04 00 00       	mov    $0x400,%edx
f0105fdf:	e8 cc fe ff ff       	call   f0105eb0 <mpsearch1>
f0105fe4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105fe7:	85 c0                	test   %eax,%eax
f0105fe9:	75 1a                	jne    f0106005 <mp_init+0x9b>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105feb:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105ff0:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105ff5:	e8 b6 fe ff ff       	call   f0105eb0 <mpsearch1>
f0105ffa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105ffd:	85 c0                	test   %eax,%eax
f0105fff:	0f 84 54 02 00 00    	je     f0106259 <mp_init+0x2ef>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0106005:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106008:	8b 70 04             	mov    0x4(%eax),%esi
f010600b:	85 f6                	test   %esi,%esi
f010600d:	74 06                	je     f0106015 <mp_init+0xab>
f010600f:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0106013:	74 11                	je     f0106026 <mp_init+0xbc>
		cprintf("SMP: Default configurations not implemented\n");
f0106015:	c7 04 24 38 87 10 f0 	movl   $0xf0108738,(%esp)
f010601c:	e8 95 e0 ff ff       	call   f01040b6 <cprintf>
f0106021:	e9 33 02 00 00       	jmp    f0106259 <mp_init+0x2ef>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0106026:	89 f0                	mov    %esi,%eax
f0106028:	c1 e8 0c             	shr    $0xc,%eax
f010602b:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0106031:	72 20                	jb     f0106053 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106033:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0106037:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f010603e:	f0 
f010603f:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f0106046:	00 
f0106047:	c7 04 24 c5 88 10 f0 	movl   $0xf01088c5,(%esp)
f010604e:	e8 ed 9f ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0106053:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0106059:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0106060:	00 
f0106061:	c7 44 24 04 da 88 10 	movl   $0xf01088da,0x4(%esp)
f0106068:	f0 
f0106069:	89 1c 24             	mov    %ebx,(%esp)
f010606c:	e8 8c fc ff ff       	call   f0105cfd <memcmp>
f0106071:	85 c0                	test   %eax,%eax
f0106073:	74 11                	je     f0106086 <mp_init+0x11c>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0106075:	c7 04 24 68 87 10 f0 	movl   $0xf0108768,(%esp)
f010607c:	e8 35 e0 ff ff       	call   f01040b6 <cprintf>
f0106081:	e9 d3 01 00 00       	jmp    f0106259 <mp_init+0x2ef>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0106086:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f010608a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010608e:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0106091:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0106096:	b8 00 00 00 00       	mov    $0x0,%eax
f010609b:	eb 0d                	jmp    f01060aa <mp_init+0x140>
		sum += ((uint8_t *)addr)[i];
f010609d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f01060a4:	f0 
f01060a5:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01060a7:	83 c0 01             	add    $0x1,%eax
f01060aa:	39 c7                	cmp    %eax,%edi
f01060ac:	7f ef                	jg     f010609d <mp_init+0x133>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01060ae:	84 d2                	test   %dl,%dl
f01060b0:	74 11                	je     f01060c3 <mp_init+0x159>
		cprintf("SMP: Bad MP configuration checksum\n");
f01060b2:	c7 04 24 9c 87 10 f0 	movl   $0xf010879c,(%esp)
f01060b9:	e8 f8 df ff ff       	call   f01040b6 <cprintf>
f01060be:	e9 96 01 00 00       	jmp    f0106259 <mp_init+0x2ef>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f01060c3:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f01060c7:	3c 04                	cmp    $0x4,%al
f01060c9:	74 1f                	je     f01060ea <mp_init+0x180>
f01060cb:	3c 01                	cmp    $0x1,%al
f01060cd:	8d 76 00             	lea    0x0(%esi),%esi
f01060d0:	74 18                	je     f01060ea <mp_init+0x180>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f01060d2:	0f b6 c0             	movzbl %al,%eax
f01060d5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01060d9:	c7 04 24 c0 87 10 f0 	movl   $0xf01087c0,(%esp)
f01060e0:	e8 d1 df ff ff       	call   f01040b6 <cprintf>
f01060e5:	e9 6f 01 00 00       	jmp    f0106259 <mp_init+0x2ef>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01060ea:	0f b7 73 28          	movzwl 0x28(%ebx),%esi
f01060ee:	0f b7 7d e2          	movzwl -0x1e(%ebp),%edi
f01060f2:	01 df                	add    %ebx,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01060f4:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01060f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01060fe:	eb 09                	jmp    f0106109 <mp_init+0x19f>
		sum += ((uint8_t *)addr)[i];
f0106100:	0f b6 0c 07          	movzbl (%edi,%eax,1),%ecx
f0106104:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0106106:	83 c0 01             	add    $0x1,%eax
f0106109:	39 c6                	cmp    %eax,%esi
f010610b:	7f f3                	jg     f0106100 <mp_init+0x196>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010610d:	02 53 2a             	add    0x2a(%ebx),%dl
f0106110:	84 d2                	test   %dl,%dl
f0106112:	74 11                	je     f0106125 <mp_init+0x1bb>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0106114:	c7 04 24 e0 87 10 f0 	movl   $0xf01087e0,(%esp)
f010611b:	e8 96 df ff ff       	call   f01040b6 <cprintf>
f0106120:	e9 34 01 00 00       	jmp    f0106259 <mp_init+0x2ef>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0106125:	85 db                	test   %ebx,%ebx
f0106127:	0f 84 2c 01 00 00    	je     f0106259 <mp_init+0x2ef>
		return;
	ismp = 1;
f010612d:	c7 05 00 d0 22 f0 01 	movl   $0x1,0xf022d000
f0106134:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0106137:	8b 43 24             	mov    0x24(%ebx),%eax
f010613a:	a3 00 e0 26 f0       	mov    %eax,0xf026e000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010613f:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0106142:	be 00 00 00 00       	mov    $0x0,%esi
f0106147:	e9 86 00 00 00       	jmp    f01061d2 <mp_init+0x268>
		switch (*p) {
f010614c:	0f b6 07             	movzbl (%edi),%eax
f010614f:	84 c0                	test   %al,%al
f0106151:	74 06                	je     f0106159 <mp_init+0x1ef>
f0106153:	3c 04                	cmp    $0x4,%al
f0106155:	77 57                	ja     f01061ae <mp_init+0x244>
f0106157:	eb 50                	jmp    f01061a9 <mp_init+0x23f>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0106159:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f010615d:	8d 76 00             	lea    0x0(%esi),%esi
f0106160:	74 11                	je     f0106173 <mp_init+0x209>
				bootcpu = &cpus[ncpu];
f0106162:	6b 05 c4 d3 22 f0 74 	imul   $0x74,0xf022d3c4,%eax
f0106169:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f010616e:	a3 c0 d3 22 f0       	mov    %eax,0xf022d3c0
			if (ncpu < NCPU) {
f0106173:	a1 c4 d3 22 f0       	mov    0xf022d3c4,%eax
f0106178:	83 f8 07             	cmp    $0x7,%eax
f010617b:	7f 13                	jg     f0106190 <mp_init+0x226>
				cpus[ncpu].cpu_id = ncpu;
f010617d:	6b d0 74             	imul   $0x74,%eax,%edx
f0106180:	88 82 20 d0 22 f0    	mov    %al,-0xfdd2fe0(%edx)
				ncpu++;
f0106186:	83 c0 01             	add    $0x1,%eax
f0106189:	a3 c4 d3 22 f0       	mov    %eax,0xf022d3c4
f010618e:	eb 14                	jmp    f01061a4 <mp_init+0x23a>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0106190:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0106194:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106198:	c7 04 24 10 88 10 f0 	movl   $0xf0108810,(%esp)
f010619f:	e8 12 df ff ff       	call   f01040b6 <cprintf>
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01061a4:	83 c7 14             	add    $0x14,%edi
			continue;
f01061a7:	eb 26                	jmp    f01061cf <mp_init+0x265>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01061a9:	83 c7 08             	add    $0x8,%edi
			continue;
f01061ac:	eb 21                	jmp    f01061cf <mp_init+0x265>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f01061ae:	0f b6 c0             	movzbl %al,%eax
f01061b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01061b5:	c7 04 24 38 88 10 f0 	movl   $0xf0108838,(%esp)
f01061bc:	e8 f5 de ff ff       	call   f01040b6 <cprintf>
			ismp = 0;
f01061c1:	c7 05 00 d0 22 f0 00 	movl   $0x0,0xf022d000
f01061c8:	00 00 00 
			i = conf->entry;
f01061cb:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01061cf:	83 c6 01             	add    $0x1,%esi
f01061d2:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f01061d6:	39 c6                	cmp    %eax,%esi
f01061d8:	0f 82 6e ff ff ff    	jb     f010614c <mp_init+0x1e2>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01061de:	a1 c0 d3 22 f0       	mov    0xf022d3c0,%eax
f01061e3:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01061ea:	83 3d 00 d0 22 f0 00 	cmpl   $0x0,0xf022d000
f01061f1:	75 22                	jne    f0106215 <mp_init+0x2ab>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01061f3:	c7 05 c4 d3 22 f0 01 	movl   $0x1,0xf022d3c4
f01061fa:	00 00 00 
		lapicaddr = 0;
f01061fd:	c7 05 00 e0 26 f0 00 	movl   $0x0,0xf026e000
f0106204:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0106207:	c7 04 24 58 88 10 f0 	movl   $0xf0108858,(%esp)
f010620e:	e8 a3 de ff ff       	call   f01040b6 <cprintf>
		return;
f0106213:	eb 44                	jmp    f0106259 <mp_init+0x2ef>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0106215:	8b 15 c4 d3 22 f0    	mov    0xf022d3c4,%edx
f010621b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010621f:	0f b6 00             	movzbl (%eax),%eax
f0106222:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106226:	c7 04 24 df 88 10 f0 	movl   $0xf01088df,(%esp)
f010622d:	e8 84 de ff ff       	call   f01040b6 <cprintf>

	if (mp->imcrp) {
f0106232:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106235:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0106239:	74 1e                	je     f0106259 <mp_init+0x2ef>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f010623b:	c7 04 24 84 88 10 f0 	movl   $0xf0108884,(%esp)
f0106242:	e8 6f de ff ff       	call   f01040b6 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106247:	ba 22 00 00 00       	mov    $0x22,%edx
f010624c:	b8 70 00 00 00       	mov    $0x70,%eax
f0106251:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0106252:	b2 23                	mov    $0x23,%dl
f0106254:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0106255:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106258:	ee                   	out    %al,(%dx)
	}
}
f0106259:	83 c4 2c             	add    $0x2c,%esp
f010625c:	5b                   	pop    %ebx
f010625d:	5e                   	pop    %esi
f010625e:	5f                   	pop    %edi
f010625f:	5d                   	pop    %ebp
f0106260:	c3                   	ret    

f0106261 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0106261:	55                   	push   %ebp
f0106262:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0106264:	8b 0d 04 e0 26 f0    	mov    0xf026e004,%ecx
f010626a:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010626d:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f010626f:	a1 04 e0 26 f0       	mov    0xf026e004,%eax
f0106274:	8b 40 20             	mov    0x20(%eax),%eax
}
f0106277:	5d                   	pop    %ebp
f0106278:	c3                   	ret    

f0106279 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0106279:	55                   	push   %ebp
f010627a:	89 e5                	mov    %esp,%ebp
	if (lapic)
f010627c:	a1 04 e0 26 f0       	mov    0xf026e004,%eax
f0106281:	85 c0                	test   %eax,%eax
f0106283:	74 08                	je     f010628d <cpunum+0x14>
		return lapic[ID] >> 24;
f0106285:	8b 40 20             	mov    0x20(%eax),%eax
f0106288:	c1 e8 18             	shr    $0x18,%eax
f010628b:	eb 05                	jmp    f0106292 <cpunum+0x19>
	return 0;
f010628d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0106292:	5d                   	pop    %ebp
f0106293:	c3                   	ret    

f0106294 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0106294:	a1 00 e0 26 f0       	mov    0xf026e000,%eax
f0106299:	85 c0                	test   %eax,%eax
f010629b:	0f 84 23 01 00 00    	je     f01063c4 <lapic_init+0x130>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f01062a1:	55                   	push   %ebp
f01062a2:	89 e5                	mov    %esp,%ebp
f01062a4:	83 ec 18             	sub    $0x18,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f01062a7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01062ae:	00 
f01062af:	89 04 24             	mov    %eax,(%esp)
f01062b2:	e8 9f b2 ff ff       	call   f0101556 <mmio_map_region>
f01062b7:	a3 04 e0 26 f0       	mov    %eax,0xf026e004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f01062bc:	ba 27 01 00 00       	mov    $0x127,%edx
f01062c1:	b8 3c 00 00 00       	mov    $0x3c,%eax
f01062c6:	e8 96 ff ff ff       	call   f0106261 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f01062cb:	ba 0b 00 00 00       	mov    $0xb,%edx
f01062d0:	b8 f8 00 00 00       	mov    $0xf8,%eax
f01062d5:	e8 87 ff ff ff       	call   f0106261 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f01062da:	ba 20 00 02 00       	mov    $0x20020,%edx
f01062df:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01062e4:	e8 78 ff ff ff       	call   f0106261 <lapicw>
	lapicw(TICR, 10000000); 
f01062e9:	ba 80 96 98 00       	mov    $0x989680,%edx
f01062ee:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01062f3:	e8 69 ff ff ff       	call   f0106261 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f01062f8:	e8 7c ff ff ff       	call   f0106279 <cpunum>
f01062fd:	6b c0 74             	imul   $0x74,%eax,%eax
f0106300:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f0106305:	39 05 c0 d3 22 f0    	cmp    %eax,0xf022d3c0
f010630b:	74 0f                	je     f010631c <lapic_init+0x88>
		lapicw(LINT0, MASKED);
f010630d:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106312:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0106317:	e8 45 ff ff ff       	call   f0106261 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f010631c:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106321:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0106326:	e8 36 ff ff ff       	call   f0106261 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f010632b:	a1 04 e0 26 f0       	mov    0xf026e004,%eax
f0106330:	8b 40 30             	mov    0x30(%eax),%eax
f0106333:	c1 e8 10             	shr    $0x10,%eax
f0106336:	3c 03                	cmp    $0x3,%al
f0106338:	76 0f                	jbe    f0106349 <lapic_init+0xb5>
		lapicw(PCINT, MASKED);
f010633a:	ba 00 00 01 00       	mov    $0x10000,%edx
f010633f:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0106344:	e8 18 ff ff ff       	call   f0106261 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0106349:	ba 33 00 00 00       	mov    $0x33,%edx
f010634e:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0106353:	e8 09 ff ff ff       	call   f0106261 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0106358:	ba 00 00 00 00       	mov    $0x0,%edx
f010635d:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106362:	e8 fa fe ff ff       	call   f0106261 <lapicw>
	lapicw(ESR, 0);
f0106367:	ba 00 00 00 00       	mov    $0x0,%edx
f010636c:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106371:	e8 eb fe ff ff       	call   f0106261 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0106376:	ba 00 00 00 00       	mov    $0x0,%edx
f010637b:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0106380:	e8 dc fe ff ff       	call   f0106261 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0106385:	ba 00 00 00 00       	mov    $0x0,%edx
f010638a:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010638f:	e8 cd fe ff ff       	call   f0106261 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0106394:	ba 00 85 08 00       	mov    $0x88500,%edx
f0106399:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010639e:	e8 be fe ff ff       	call   f0106261 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f01063a3:	8b 15 04 e0 26 f0    	mov    0xf026e004,%edx
f01063a9:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01063af:	f6 c4 10             	test   $0x10,%ah
f01063b2:	75 f5                	jne    f01063a9 <lapic_init+0x115>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f01063b4:	ba 00 00 00 00       	mov    $0x0,%edx
f01063b9:	b8 20 00 00 00       	mov    $0x20,%eax
f01063be:	e8 9e fe ff ff       	call   f0106261 <lapicw>
}
f01063c3:	c9                   	leave  
f01063c4:	f3 c3                	repz ret 

f01063c6 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f01063c6:	83 3d 04 e0 26 f0 00 	cmpl   $0x0,0xf026e004
f01063cd:	74 13                	je     f01063e2 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f01063cf:	55                   	push   %ebp
f01063d0:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f01063d2:	ba 00 00 00 00       	mov    $0x0,%edx
f01063d7:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01063dc:	e8 80 fe ff ff       	call   f0106261 <lapicw>
}
f01063e1:	5d                   	pop    %ebp
f01063e2:	f3 c3                	repz ret 

f01063e4 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01063e4:	55                   	push   %ebp
f01063e5:	89 e5                	mov    %esp,%ebp
f01063e7:	56                   	push   %esi
f01063e8:	53                   	push   %ebx
f01063e9:	83 ec 10             	sub    $0x10,%esp
f01063ec:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01063ef:	8b 75 0c             	mov    0xc(%ebp),%esi
f01063f2:	ba 70 00 00 00       	mov    $0x70,%edx
f01063f7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01063fc:	ee                   	out    %al,(%dx)
f01063fd:	b2 71                	mov    $0x71,%dl
f01063ff:	b8 0a 00 00 00       	mov    $0xa,%eax
f0106404:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0106405:	83 3d 88 ce 22 f0 00 	cmpl   $0x0,0xf022ce88
f010640c:	75 24                	jne    f0106432 <lapic_startap+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010640e:	c7 44 24 0c 67 04 00 	movl   $0x467,0xc(%esp)
f0106415:	00 
f0106416:	c7 44 24 08 84 69 10 	movl   $0xf0106984,0x8(%esp)
f010641d:	f0 
f010641e:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f0106425:	00 
f0106426:	c7 04 24 fc 88 10 f0 	movl   $0xf01088fc,(%esp)
f010642d:	e8 0e 9c ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0106432:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0106439:	00 00 
	wrv[1] = addr >> 4;
f010643b:	89 f0                	mov    %esi,%eax
f010643d:	c1 e8 04             	shr    $0x4,%eax
f0106440:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0106446:	c1 e3 18             	shl    $0x18,%ebx
f0106449:	89 da                	mov    %ebx,%edx
f010644b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106450:	e8 0c fe ff ff       	call   f0106261 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0106455:	ba 00 c5 00 00       	mov    $0xc500,%edx
f010645a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010645f:	e8 fd fd ff ff       	call   f0106261 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0106464:	ba 00 85 00 00       	mov    $0x8500,%edx
f0106469:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010646e:	e8 ee fd ff ff       	call   f0106261 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106473:	c1 ee 0c             	shr    $0xc,%esi
f0106476:	81 ce 00 06 00 00    	or     $0x600,%esi
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f010647c:	89 da                	mov    %ebx,%edx
f010647e:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106483:	e8 d9 fd ff ff       	call   f0106261 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106488:	89 f2                	mov    %esi,%edx
f010648a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010648f:	e8 cd fd ff ff       	call   f0106261 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0106494:	89 da                	mov    %ebx,%edx
f0106496:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010649b:	e8 c1 fd ff ff       	call   f0106261 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01064a0:	89 f2                	mov    %esi,%edx
f01064a2:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01064a7:	e8 b5 fd ff ff       	call   f0106261 <lapicw>
		microdelay(200);
	}
}
f01064ac:	83 c4 10             	add    $0x10,%esp
f01064af:	5b                   	pop    %ebx
f01064b0:	5e                   	pop    %esi
f01064b1:	5d                   	pop    %ebp
f01064b2:	c3                   	ret    

f01064b3 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f01064b3:	55                   	push   %ebp
f01064b4:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f01064b6:	8b 55 08             	mov    0x8(%ebp),%edx
f01064b9:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f01064bf:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01064c4:	e8 98 fd ff ff       	call   f0106261 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f01064c9:	8b 15 04 e0 26 f0    	mov    0xf026e004,%edx
f01064cf:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01064d5:	f6 c4 10             	test   $0x10,%ah
f01064d8:	75 f5                	jne    f01064cf <lapic_ipi+0x1c>
		;
}
f01064da:	5d                   	pop    %ebp
f01064db:	c3                   	ret    

f01064dc <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01064dc:	55                   	push   %ebp
f01064dd:	89 e5                	mov    %esp,%ebp
f01064df:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f01064e2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f01064e8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01064eb:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01064ee:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01064f5:	5d                   	pop    %ebp
f01064f6:	c3                   	ret    

f01064f7 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01064f7:	55                   	push   %ebp
f01064f8:	89 e5                	mov    %esp,%ebp
f01064fa:	56                   	push   %esi
f01064fb:	53                   	push   %ebx
f01064fc:	83 ec 20             	sub    $0x20,%esp
f01064ff:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0106502:	83 3b 00             	cmpl   $0x0,(%ebx)
f0106505:	75 07                	jne    f010650e <spin_lock+0x17>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0106507:	ba 01 00 00 00       	mov    $0x1,%edx
f010650c:	eb 42                	jmp    f0106550 <spin_lock+0x59>
f010650e:	8b 73 08             	mov    0x8(%ebx),%esi
f0106511:	e8 63 fd ff ff       	call   f0106279 <cpunum>
f0106516:	6b c0 74             	imul   $0x74,%eax,%eax
f0106519:	05 20 d0 22 f0       	add    $0xf022d020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f010651e:	39 c6                	cmp    %eax,%esi
f0106520:	75 e5                	jne    f0106507 <spin_lock+0x10>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0106522:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0106525:	e8 4f fd ff ff       	call   f0106279 <cpunum>
f010652a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f010652e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106532:	c7 44 24 08 0c 89 10 	movl   $0xf010890c,0x8(%esp)
f0106539:	f0 
f010653a:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
f0106541:	00 
f0106542:	c7 04 24 70 89 10 f0 	movl   $0xf0108970,(%esp)
f0106549:	e8 f2 9a ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f010654e:	f3 90                	pause  
f0106550:	89 d0                	mov    %edx,%eax
f0106552:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0106555:	85 c0                	test   %eax,%eax
f0106557:	75 f5                	jne    f010654e <spin_lock+0x57>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0106559:	e8 1b fd ff ff       	call   f0106279 <cpunum>
f010655e:	6b c0 74             	imul   $0x74,%eax,%eax
f0106561:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f0106566:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0106569:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f010656c:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f010656e:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0106573:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0106579:	76 12                	jbe    f010658d <spin_lock+0x96>
			break;
		pcs[i] = ebp[1];          // saved %eip
f010657b:	8b 4a 04             	mov    0x4(%edx),%ecx
f010657e:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0106581:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0106583:	83 c0 01             	add    $0x1,%eax
f0106586:	83 f8 0a             	cmp    $0xa,%eax
f0106589:	75 e8                	jne    f0106573 <spin_lock+0x7c>
f010658b:	eb 0f                	jmp    f010659c <spin_lock+0xa5>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f010658d:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0106594:	83 c0 01             	add    $0x1,%eax
f0106597:	83 f8 09             	cmp    $0x9,%eax
f010659a:	7e f1                	jle    f010658d <spin_lock+0x96>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f010659c:	83 c4 20             	add    $0x20,%esp
f010659f:	5b                   	pop    %ebx
f01065a0:	5e                   	pop    %esi
f01065a1:	5d                   	pop    %ebp
f01065a2:	c3                   	ret    

f01065a3 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f01065a3:	55                   	push   %ebp
f01065a4:	89 e5                	mov    %esp,%ebp
f01065a6:	57                   	push   %edi
f01065a7:	56                   	push   %esi
f01065a8:	53                   	push   %ebx
f01065a9:	83 ec 6c             	sub    $0x6c,%esp
f01065ac:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01065af:	83 3e 00             	cmpl   $0x0,(%esi)
f01065b2:	74 18                	je     f01065cc <spin_unlock+0x29>
f01065b4:	8b 5e 08             	mov    0x8(%esi),%ebx
f01065b7:	e8 bd fc ff ff       	call   f0106279 <cpunum>
f01065bc:	6b c0 74             	imul   $0x74,%eax,%eax
f01065bf:	05 20 d0 22 f0       	add    $0xf022d020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f01065c4:	39 c3                	cmp    %eax,%ebx
f01065c6:	0f 84 ce 00 00 00    	je     f010669a <spin_unlock+0xf7>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f01065cc:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
f01065d3:	00 
f01065d4:	8d 46 0c             	lea    0xc(%esi),%eax
f01065d7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01065db:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f01065de:	89 1c 24             	mov    %ebx,(%esp)
f01065e1:	e8 8e f6 ff ff       	call   f0105c74 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f01065e6:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f01065e9:	0f b6 38             	movzbl (%eax),%edi
f01065ec:	8b 76 04             	mov    0x4(%esi),%esi
f01065ef:	e8 85 fc ff ff       	call   f0106279 <cpunum>
f01065f4:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01065f8:	89 74 24 08          	mov    %esi,0x8(%esp)
f01065fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106600:	c7 04 24 38 89 10 f0 	movl   $0xf0108938,(%esp)
f0106607:	e8 aa da ff ff       	call   f01040b6 <cprintf>
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010660c:	8d 7d a8             	lea    -0x58(%ebp),%edi
f010660f:	eb 65                	jmp    f0106676 <spin_unlock+0xd3>
f0106611:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0106615:	89 04 24             	mov    %eax,(%esp)
f0106618:	e8 c1 ea ff ff       	call   f01050de <debuginfo_eip>
f010661d:	85 c0                	test   %eax,%eax
f010661f:	78 39                	js     f010665a <spin_unlock+0xb7>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0106621:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0106623:	89 c2                	mov    %eax,%edx
f0106625:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0106628:	89 54 24 18          	mov    %edx,0x18(%esp)
f010662c:	8b 55 b0             	mov    -0x50(%ebp),%edx
f010662f:	89 54 24 14          	mov    %edx,0x14(%esp)
f0106633:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0106636:	89 54 24 10          	mov    %edx,0x10(%esp)
f010663a:	8b 55 ac             	mov    -0x54(%ebp),%edx
f010663d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0106641:	8b 55 a8             	mov    -0x58(%ebp),%edx
f0106644:	89 54 24 08          	mov    %edx,0x8(%esp)
f0106648:	89 44 24 04          	mov    %eax,0x4(%esp)
f010664c:	c7 04 24 80 89 10 f0 	movl   $0xf0108980,(%esp)
f0106653:	e8 5e da ff ff       	call   f01040b6 <cprintf>
f0106658:	eb 12                	jmp    f010666c <spin_unlock+0xc9>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f010665a:	8b 06                	mov    (%esi),%eax
f010665c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106660:	c7 04 24 97 89 10 f0 	movl   $0xf0108997,(%esp)
f0106667:	e8 4a da ff ff       	call   f01040b6 <cprintf>
f010666c:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f010666f:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0106672:	39 c3                	cmp    %eax,%ebx
f0106674:	74 08                	je     f010667e <spin_unlock+0xdb>
f0106676:	89 de                	mov    %ebx,%esi
f0106678:	8b 03                	mov    (%ebx),%eax
f010667a:	85 c0                	test   %eax,%eax
f010667c:	75 93                	jne    f0106611 <spin_unlock+0x6e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f010667e:	c7 44 24 08 9f 89 10 	movl   $0xf010899f,0x8(%esp)
f0106685:	f0 
f0106686:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
f010668d:	00 
f010668e:	c7 04 24 70 89 10 f0 	movl   $0xf0108970,(%esp)
f0106695:	e8 a6 99 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f010669a:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f01066a1:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f01066a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01066ad:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f01066b0:	83 c4 6c             	add    $0x6c,%esp
f01066b3:	5b                   	pop    %ebx
f01066b4:	5e                   	pop    %esi
f01066b5:	5f                   	pop    %edi
f01066b6:	5d                   	pop    %ebp
f01066b7:	c3                   	ret    
f01066b8:	66 90                	xchg   %ax,%ax
f01066ba:	66 90                	xchg   %ax,%ax
f01066bc:	66 90                	xchg   %ax,%ax
f01066be:	66 90                	xchg   %ax,%ax

f01066c0 <__udivdi3>:
f01066c0:	55                   	push   %ebp
f01066c1:	57                   	push   %edi
f01066c2:	56                   	push   %esi
f01066c3:	83 ec 0c             	sub    $0xc,%esp
f01066c6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01066ca:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01066ce:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01066d2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01066d6:	85 c0                	test   %eax,%eax
f01066d8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01066dc:	89 ea                	mov    %ebp,%edx
f01066de:	89 0c 24             	mov    %ecx,(%esp)
f01066e1:	75 2d                	jne    f0106710 <__udivdi3+0x50>
f01066e3:	39 e9                	cmp    %ebp,%ecx
f01066e5:	77 61                	ja     f0106748 <__udivdi3+0x88>
f01066e7:	85 c9                	test   %ecx,%ecx
f01066e9:	89 ce                	mov    %ecx,%esi
f01066eb:	75 0b                	jne    f01066f8 <__udivdi3+0x38>
f01066ed:	b8 01 00 00 00       	mov    $0x1,%eax
f01066f2:	31 d2                	xor    %edx,%edx
f01066f4:	f7 f1                	div    %ecx
f01066f6:	89 c6                	mov    %eax,%esi
f01066f8:	31 d2                	xor    %edx,%edx
f01066fa:	89 e8                	mov    %ebp,%eax
f01066fc:	f7 f6                	div    %esi
f01066fe:	89 c5                	mov    %eax,%ebp
f0106700:	89 f8                	mov    %edi,%eax
f0106702:	f7 f6                	div    %esi
f0106704:	89 ea                	mov    %ebp,%edx
f0106706:	83 c4 0c             	add    $0xc,%esp
f0106709:	5e                   	pop    %esi
f010670a:	5f                   	pop    %edi
f010670b:	5d                   	pop    %ebp
f010670c:	c3                   	ret    
f010670d:	8d 76 00             	lea    0x0(%esi),%esi
f0106710:	39 e8                	cmp    %ebp,%eax
f0106712:	77 24                	ja     f0106738 <__udivdi3+0x78>
f0106714:	0f bd e8             	bsr    %eax,%ebp
f0106717:	83 f5 1f             	xor    $0x1f,%ebp
f010671a:	75 3c                	jne    f0106758 <__udivdi3+0x98>
f010671c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0106720:	39 34 24             	cmp    %esi,(%esp)
f0106723:	0f 86 9f 00 00 00    	jbe    f01067c8 <__udivdi3+0x108>
f0106729:	39 d0                	cmp    %edx,%eax
f010672b:	0f 82 97 00 00 00    	jb     f01067c8 <__udivdi3+0x108>
f0106731:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106738:	31 d2                	xor    %edx,%edx
f010673a:	31 c0                	xor    %eax,%eax
f010673c:	83 c4 0c             	add    $0xc,%esp
f010673f:	5e                   	pop    %esi
f0106740:	5f                   	pop    %edi
f0106741:	5d                   	pop    %ebp
f0106742:	c3                   	ret    
f0106743:	90                   	nop
f0106744:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106748:	89 f8                	mov    %edi,%eax
f010674a:	f7 f1                	div    %ecx
f010674c:	31 d2                	xor    %edx,%edx
f010674e:	83 c4 0c             	add    $0xc,%esp
f0106751:	5e                   	pop    %esi
f0106752:	5f                   	pop    %edi
f0106753:	5d                   	pop    %ebp
f0106754:	c3                   	ret    
f0106755:	8d 76 00             	lea    0x0(%esi),%esi
f0106758:	89 e9                	mov    %ebp,%ecx
f010675a:	8b 3c 24             	mov    (%esp),%edi
f010675d:	d3 e0                	shl    %cl,%eax
f010675f:	89 c6                	mov    %eax,%esi
f0106761:	b8 20 00 00 00       	mov    $0x20,%eax
f0106766:	29 e8                	sub    %ebp,%eax
f0106768:	89 c1                	mov    %eax,%ecx
f010676a:	d3 ef                	shr    %cl,%edi
f010676c:	89 e9                	mov    %ebp,%ecx
f010676e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0106772:	8b 3c 24             	mov    (%esp),%edi
f0106775:	09 74 24 08          	or     %esi,0x8(%esp)
f0106779:	89 d6                	mov    %edx,%esi
f010677b:	d3 e7                	shl    %cl,%edi
f010677d:	89 c1                	mov    %eax,%ecx
f010677f:	89 3c 24             	mov    %edi,(%esp)
f0106782:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0106786:	d3 ee                	shr    %cl,%esi
f0106788:	89 e9                	mov    %ebp,%ecx
f010678a:	d3 e2                	shl    %cl,%edx
f010678c:	89 c1                	mov    %eax,%ecx
f010678e:	d3 ef                	shr    %cl,%edi
f0106790:	09 d7                	or     %edx,%edi
f0106792:	89 f2                	mov    %esi,%edx
f0106794:	89 f8                	mov    %edi,%eax
f0106796:	f7 74 24 08          	divl   0x8(%esp)
f010679a:	89 d6                	mov    %edx,%esi
f010679c:	89 c7                	mov    %eax,%edi
f010679e:	f7 24 24             	mull   (%esp)
f01067a1:	39 d6                	cmp    %edx,%esi
f01067a3:	89 14 24             	mov    %edx,(%esp)
f01067a6:	72 30                	jb     f01067d8 <__udivdi3+0x118>
f01067a8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01067ac:	89 e9                	mov    %ebp,%ecx
f01067ae:	d3 e2                	shl    %cl,%edx
f01067b0:	39 c2                	cmp    %eax,%edx
f01067b2:	73 05                	jae    f01067b9 <__udivdi3+0xf9>
f01067b4:	3b 34 24             	cmp    (%esp),%esi
f01067b7:	74 1f                	je     f01067d8 <__udivdi3+0x118>
f01067b9:	89 f8                	mov    %edi,%eax
f01067bb:	31 d2                	xor    %edx,%edx
f01067bd:	e9 7a ff ff ff       	jmp    f010673c <__udivdi3+0x7c>
f01067c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01067c8:	31 d2                	xor    %edx,%edx
f01067ca:	b8 01 00 00 00       	mov    $0x1,%eax
f01067cf:	e9 68 ff ff ff       	jmp    f010673c <__udivdi3+0x7c>
f01067d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01067d8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01067db:	31 d2                	xor    %edx,%edx
f01067dd:	83 c4 0c             	add    $0xc,%esp
f01067e0:	5e                   	pop    %esi
f01067e1:	5f                   	pop    %edi
f01067e2:	5d                   	pop    %ebp
f01067e3:	c3                   	ret    
f01067e4:	66 90                	xchg   %ax,%ax
f01067e6:	66 90                	xchg   %ax,%ax
f01067e8:	66 90                	xchg   %ax,%ax
f01067ea:	66 90                	xchg   %ax,%ax
f01067ec:	66 90                	xchg   %ax,%ax
f01067ee:	66 90                	xchg   %ax,%ax

f01067f0 <__umoddi3>:
f01067f0:	55                   	push   %ebp
f01067f1:	57                   	push   %edi
f01067f2:	56                   	push   %esi
f01067f3:	83 ec 14             	sub    $0x14,%esp
f01067f6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01067fa:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01067fe:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0106802:	89 c7                	mov    %eax,%edi
f0106804:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106808:	8b 44 24 30          	mov    0x30(%esp),%eax
f010680c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0106810:	89 34 24             	mov    %esi,(%esp)
f0106813:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106817:	85 c0                	test   %eax,%eax
f0106819:	89 c2                	mov    %eax,%edx
f010681b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010681f:	75 17                	jne    f0106838 <__umoddi3+0x48>
f0106821:	39 fe                	cmp    %edi,%esi
f0106823:	76 4b                	jbe    f0106870 <__umoddi3+0x80>
f0106825:	89 c8                	mov    %ecx,%eax
f0106827:	89 fa                	mov    %edi,%edx
f0106829:	f7 f6                	div    %esi
f010682b:	89 d0                	mov    %edx,%eax
f010682d:	31 d2                	xor    %edx,%edx
f010682f:	83 c4 14             	add    $0x14,%esp
f0106832:	5e                   	pop    %esi
f0106833:	5f                   	pop    %edi
f0106834:	5d                   	pop    %ebp
f0106835:	c3                   	ret    
f0106836:	66 90                	xchg   %ax,%ax
f0106838:	39 f8                	cmp    %edi,%eax
f010683a:	77 54                	ja     f0106890 <__umoddi3+0xa0>
f010683c:	0f bd e8             	bsr    %eax,%ebp
f010683f:	83 f5 1f             	xor    $0x1f,%ebp
f0106842:	75 5c                	jne    f01068a0 <__umoddi3+0xb0>
f0106844:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0106848:	39 3c 24             	cmp    %edi,(%esp)
f010684b:	0f 87 e7 00 00 00    	ja     f0106938 <__umoddi3+0x148>
f0106851:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0106855:	29 f1                	sub    %esi,%ecx
f0106857:	19 c7                	sbb    %eax,%edi
f0106859:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010685d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106861:	8b 44 24 08          	mov    0x8(%esp),%eax
f0106865:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0106869:	83 c4 14             	add    $0x14,%esp
f010686c:	5e                   	pop    %esi
f010686d:	5f                   	pop    %edi
f010686e:	5d                   	pop    %ebp
f010686f:	c3                   	ret    
f0106870:	85 f6                	test   %esi,%esi
f0106872:	89 f5                	mov    %esi,%ebp
f0106874:	75 0b                	jne    f0106881 <__umoddi3+0x91>
f0106876:	b8 01 00 00 00       	mov    $0x1,%eax
f010687b:	31 d2                	xor    %edx,%edx
f010687d:	f7 f6                	div    %esi
f010687f:	89 c5                	mov    %eax,%ebp
f0106881:	8b 44 24 04          	mov    0x4(%esp),%eax
f0106885:	31 d2                	xor    %edx,%edx
f0106887:	f7 f5                	div    %ebp
f0106889:	89 c8                	mov    %ecx,%eax
f010688b:	f7 f5                	div    %ebp
f010688d:	eb 9c                	jmp    f010682b <__umoddi3+0x3b>
f010688f:	90                   	nop
f0106890:	89 c8                	mov    %ecx,%eax
f0106892:	89 fa                	mov    %edi,%edx
f0106894:	83 c4 14             	add    $0x14,%esp
f0106897:	5e                   	pop    %esi
f0106898:	5f                   	pop    %edi
f0106899:	5d                   	pop    %ebp
f010689a:	c3                   	ret    
f010689b:	90                   	nop
f010689c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01068a0:	8b 04 24             	mov    (%esp),%eax
f01068a3:	be 20 00 00 00       	mov    $0x20,%esi
f01068a8:	89 e9                	mov    %ebp,%ecx
f01068aa:	29 ee                	sub    %ebp,%esi
f01068ac:	d3 e2                	shl    %cl,%edx
f01068ae:	89 f1                	mov    %esi,%ecx
f01068b0:	d3 e8                	shr    %cl,%eax
f01068b2:	89 e9                	mov    %ebp,%ecx
f01068b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01068b8:	8b 04 24             	mov    (%esp),%eax
f01068bb:	09 54 24 04          	or     %edx,0x4(%esp)
f01068bf:	89 fa                	mov    %edi,%edx
f01068c1:	d3 e0                	shl    %cl,%eax
f01068c3:	89 f1                	mov    %esi,%ecx
f01068c5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01068c9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01068cd:	d3 ea                	shr    %cl,%edx
f01068cf:	89 e9                	mov    %ebp,%ecx
f01068d1:	d3 e7                	shl    %cl,%edi
f01068d3:	89 f1                	mov    %esi,%ecx
f01068d5:	d3 e8                	shr    %cl,%eax
f01068d7:	89 e9                	mov    %ebp,%ecx
f01068d9:	09 f8                	or     %edi,%eax
f01068db:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01068df:	f7 74 24 04          	divl   0x4(%esp)
f01068e3:	d3 e7                	shl    %cl,%edi
f01068e5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01068e9:	89 d7                	mov    %edx,%edi
f01068eb:	f7 64 24 08          	mull   0x8(%esp)
f01068ef:	39 d7                	cmp    %edx,%edi
f01068f1:	89 c1                	mov    %eax,%ecx
f01068f3:	89 14 24             	mov    %edx,(%esp)
f01068f6:	72 2c                	jb     f0106924 <__umoddi3+0x134>
f01068f8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01068fc:	72 22                	jb     f0106920 <__umoddi3+0x130>
f01068fe:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0106902:	29 c8                	sub    %ecx,%eax
f0106904:	19 d7                	sbb    %edx,%edi
f0106906:	89 e9                	mov    %ebp,%ecx
f0106908:	89 fa                	mov    %edi,%edx
f010690a:	d3 e8                	shr    %cl,%eax
f010690c:	89 f1                	mov    %esi,%ecx
f010690e:	d3 e2                	shl    %cl,%edx
f0106910:	89 e9                	mov    %ebp,%ecx
f0106912:	d3 ef                	shr    %cl,%edi
f0106914:	09 d0                	or     %edx,%eax
f0106916:	89 fa                	mov    %edi,%edx
f0106918:	83 c4 14             	add    $0x14,%esp
f010691b:	5e                   	pop    %esi
f010691c:	5f                   	pop    %edi
f010691d:	5d                   	pop    %ebp
f010691e:	c3                   	ret    
f010691f:	90                   	nop
f0106920:	39 d7                	cmp    %edx,%edi
f0106922:	75 da                	jne    f01068fe <__umoddi3+0x10e>
f0106924:	8b 14 24             	mov    (%esp),%edx
f0106927:	89 c1                	mov    %eax,%ecx
f0106929:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010692d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0106931:	eb cb                	jmp    f01068fe <__umoddi3+0x10e>
f0106933:	90                   	nop
f0106934:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106938:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010693c:	0f 82 0f ff ff ff    	jb     f0106851 <__umoddi3+0x61>
f0106942:	e9 1a ff ff ff       	jmp    f0106861 <__umoddi3+0x71>
