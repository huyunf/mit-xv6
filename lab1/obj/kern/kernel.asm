
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
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
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
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 60 19 10 f0 	movl   $0xf0101960,(%esp)
f0100055:	e8 10 0a 00 00       	call   f0100a6a <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 5d 07 00 00       	call   f01007e4 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 7c 19 10 f0 	movl   $0xf010197c,(%esp)
f0100092:	e8 d3 09 00 00       	call   f0100a6a <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 28             	sub    $0x28,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 a9 11 f0       	mov    $0xf011a944,%eax
f01000a8:	2d 00 a3 11 f0       	sub    $0xf011a300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 a3 11 f0 	movl   $0xf011a300,(%esp)
f01000c0:	e8 49 14 00 00       	call   f010150e <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 03 05 00 00       	call   f01005cd <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 97 19 10 f0 	movl   $0xf0101997,(%esp)
f01000d9:	e8 8c 09 00 00       	call   f0100a6a <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>
        #define ANSI_COLOR_BLUE    "\x1b[34m"
        #define ANSI_COLOR_MAGENTA "\x1b[35m"
        #define ANSI_COLOR_CYAN    "\x1b[36m"
        #define ANSI_COLOR_RESET   "\x1b[0m"

        unsigned int i = 0x00646c72;
f01000ea:	c7 45 f4 72 6c 64 00 	movl   $0x646c72,-0xc(%ebp)
        cprintf("H%x Wo%s\n", 57616, &i);
f01000f1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01000f4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000f8:	c7 44 24 04 10 e1 00 	movl   $0xe110,0x4(%esp)
f01000ff:	00 
f0100100:	c7 04 24 b2 19 10 f0 	movl   $0xf01019b2,(%esp)
f0100107:	e8 5e 09 00 00       	call   f0100a6a <cprintf>

        cprintf("x=%d, y=%d\n", 3);
f010010c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0100113:	00 
f0100114:	c7 04 24 bc 19 10 f0 	movl   $0xf01019bc,(%esp)
f010011b:	e8 4a 09 00 00       	call   f0100a6a <cprintf>

        cprintf("\033[22;34mHello world!\033[0m\n");
f0100120:	c7 04 24 c8 19 10 f0 	movl   $0xf01019c8,(%esp)
f0100127:	e8 3e 09 00 00       	call   f0100a6a <cprintf>

        cprintf(ANSI_COLOR_RED     "This text is RED!"     ANSI_COLOR_RESET "\n");
f010012c:	c7 04 24 e2 19 10 f0 	movl   $0xf01019e2,(%esp)
f0100133:	e8 32 09 00 00       	call   f0100a6a <cprintf>
        cprintf(ANSI_COLOR_GREEN   "This text is GREEN!"   ANSI_COLOR_RESET "\n");
f0100138:	c7 04 24 fe 19 10 f0 	movl   $0xf01019fe,(%esp)
f010013f:	e8 26 09 00 00       	call   f0100a6a <cprintf>
        cprintf(ANSI_COLOR_YELLOW  "This text is YELLOW!"  ANSI_COLOR_RESET "\n");
f0100144:	c7 04 24 88 1a 10 f0 	movl   $0xf0101a88,(%esp)
f010014b:	e8 1a 09 00 00       	call   f0100a6a <cprintf>
        cprintf(ANSI_COLOR_BLUE    "This text is BLUE!"    ANSI_COLOR_RESET "\n");
f0100150:	c7 04 24 1c 1a 10 f0 	movl   $0xf0101a1c,(%esp)
f0100157:	e8 0e 09 00 00       	call   f0100a6a <cprintf>
        cprintf(ANSI_COLOR_MAGENTA "This text is MAGENTA!" ANSI_COLOR_RESET "\n");
f010015c:	c7 04 24 a8 1a 10 f0 	movl   $0xf0101aa8,(%esp)
f0100163:	e8 02 09 00 00       	call   f0100a6a <cprintf>
        cprintf(ANSI_COLOR_CYAN    "This text is CYAN!"    ANSI_COLOR_RESET "\n");
f0100168:	c7 04 24 39 1a 10 f0 	movl   $0xf0101a39,(%esp)
f010016f:	e8 f6 08 00 00       	call   f0100a6a <cprintf>
    }

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100174:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010017b:	e8 6c 07 00 00       	call   f01008ec <monitor>
f0100180:	eb f2                	jmp    f0100174 <i386_init+0xd7>

f0100182 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100182:	55                   	push   %ebp
f0100183:	89 e5                	mov    %esp,%ebp
f0100185:	56                   	push   %esi
f0100186:	53                   	push   %ebx
f0100187:	83 ec 10             	sub    $0x10,%esp
f010018a:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010018d:	83 3d 40 a9 11 f0 00 	cmpl   $0x0,0xf011a940
f0100194:	75 3d                	jne    f01001d3 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100196:	89 35 40 a9 11 f0    	mov    %esi,0xf011a940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f010019c:	fa                   	cli    
f010019d:	fc                   	cld    

	va_start(ap, fmt);
f010019e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01001a1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01001a4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01001a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01001ab:	89 44 24 04          	mov    %eax,0x4(%esp)
f01001af:	c7 04 24 56 1a 10 f0 	movl   $0xf0101a56,(%esp)
f01001b6:	e8 af 08 00 00       	call   f0100a6a <cprintf>
	vcprintf(fmt, ap);
f01001bb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01001bf:	89 34 24             	mov    %esi,(%esp)
f01001c2:	e8 70 08 00 00       	call   f0100a37 <vcprintf>
	cprintf("\n");
f01001c7:	c7 04 24 d2 1a 10 f0 	movl   $0xf0101ad2,(%esp)
f01001ce:	e8 97 08 00 00       	call   f0100a6a <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01001d3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01001da:	e8 0d 07 00 00       	call   f01008ec <monitor>
f01001df:	eb f2                	jmp    f01001d3 <_panic+0x51>

f01001e1 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01001e1:	55                   	push   %ebp
f01001e2:	89 e5                	mov    %esp,%ebp
f01001e4:	53                   	push   %ebx
f01001e5:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01001e8:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01001eb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01001ee:	89 44 24 08          	mov    %eax,0x8(%esp)
f01001f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01001f5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01001f9:	c7 04 24 6e 1a 10 f0 	movl   $0xf0101a6e,(%esp)
f0100200:	e8 65 08 00 00       	call   f0100a6a <cprintf>
	vcprintf(fmt, ap);
f0100205:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100209:	8b 45 10             	mov    0x10(%ebp),%eax
f010020c:	89 04 24             	mov    %eax,(%esp)
f010020f:	e8 23 08 00 00       	call   f0100a37 <vcprintf>
	cprintf("\n");
f0100214:	c7 04 24 d2 1a 10 f0 	movl   $0xf0101ad2,(%esp)
f010021b:	e8 4a 08 00 00       	call   f0100a6a <cprintf>
	va_end(ap);
}
f0100220:	83 c4 14             	add    $0x14,%esp
f0100223:	5b                   	pop    %ebx
f0100224:	5d                   	pop    %ebp
f0100225:	c3                   	ret    
	...

f0100228 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100228:	55                   	push   %ebp
f0100229:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010022b:	ba 84 00 00 00       	mov    $0x84,%edx
f0100230:	ec                   	in     (%dx),%al
f0100231:	ec                   	in     (%dx),%al
f0100232:	ec                   	in     (%dx),%al
f0100233:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f0100234:	5d                   	pop    %ebp
f0100235:	c3                   	ret    

f0100236 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100236:	55                   	push   %ebp
f0100237:	89 e5                	mov    %esp,%ebp
f0100239:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010023e:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010023f:	a8 01                	test   $0x1,%al
f0100241:	74 08                	je     f010024b <serial_proc_data+0x15>
f0100243:	b2 f8                	mov    $0xf8,%dl
f0100245:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100246:	0f b6 c0             	movzbl %al,%eax
f0100249:	eb 05                	jmp    f0100250 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010024b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100250:	5d                   	pop    %ebp
f0100251:	c3                   	ret    

f0100252 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100252:	55                   	push   %ebp
f0100253:	89 e5                	mov    %esp,%ebp
f0100255:	53                   	push   %ebx
f0100256:	83 ec 04             	sub    $0x4,%esp
f0100259:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010025b:	eb 29                	jmp    f0100286 <cons_intr+0x34>
		if (c == 0)
f010025d:	85 c0                	test   %eax,%eax
f010025f:	74 25                	je     f0100286 <cons_intr+0x34>
			continue;
		cons.buf[cons.wpos++] = c;
f0100261:	8b 15 24 a5 11 f0    	mov    0xf011a524,%edx
f0100267:	88 82 20 a3 11 f0    	mov    %al,-0xfee5ce0(%edx)
f010026d:	8d 42 01             	lea    0x1(%edx),%eax
f0100270:	a3 24 a5 11 f0       	mov    %eax,0xf011a524
		if (cons.wpos == CONSBUFSIZE)
f0100275:	3d 00 02 00 00       	cmp    $0x200,%eax
f010027a:	75 0a                	jne    f0100286 <cons_intr+0x34>
			cons.wpos = 0;
f010027c:	c7 05 24 a5 11 f0 00 	movl   $0x0,0xf011a524
f0100283:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100286:	ff d3                	call   *%ebx
f0100288:	83 f8 ff             	cmp    $0xffffffff,%eax
f010028b:	75 d0                	jne    f010025d <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010028d:	83 c4 04             	add    $0x4,%esp
f0100290:	5b                   	pop    %ebx
f0100291:	5d                   	pop    %ebp
f0100292:	c3                   	ret    

f0100293 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100293:	55                   	push   %ebp
f0100294:	89 e5                	mov    %esp,%ebp
f0100296:	57                   	push   %edi
f0100297:	56                   	push   %esi
f0100298:	53                   	push   %ebx
f0100299:	83 ec 2c             	sub    $0x2c,%esp
f010029c:	89 c6                	mov    %eax,%esi
f010029e:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01002a3:	bf fd 03 00 00       	mov    $0x3fd,%edi
f01002a8:	eb 05                	jmp    f01002af <cons_putc+0x1c>
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01002aa:	e8 79 ff ff ff       	call   f0100228 <delay>
f01002af:	89 fa                	mov    %edi,%edx
f01002b1:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002b2:	a8 20                	test   $0x20,%al
f01002b4:	75 03                	jne    f01002b9 <cons_putc+0x26>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b6:	4b                   	dec    %ebx
f01002b7:	75 f1                	jne    f01002aa <cons_putc+0x17>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002b9:	89 f2                	mov    %esi,%edx
f01002bb:	89 f0                	mov    %esi,%eax
f01002bd:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c5:	ee                   	out    %al,(%dx)
f01002c6:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002cb:	bf 79 03 00 00       	mov    $0x379,%edi
f01002d0:	eb 05                	jmp    f01002d7 <cons_putc+0x44>
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
		delay();
f01002d2:	e8 51 ff ff ff       	call   f0100228 <delay>
f01002d7:	89 fa                	mov    %edi,%edx
f01002d9:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002da:	84 c0                	test   %al,%al
f01002dc:	78 03                	js     f01002e1 <cons_putc+0x4e>
f01002de:	4b                   	dec    %ebx
f01002df:	75 f1                	jne    f01002d2 <cons_putc+0x3f>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e1:	ba 78 03 00 00       	mov    $0x378,%edx
f01002e6:	8a 45 e7             	mov    -0x19(%ebp),%al
f01002e9:	ee                   	out    %al,(%dx)
f01002ea:	b2 7a                	mov    $0x7a,%dl
f01002ec:	b0 0d                	mov    $0xd,%al
f01002ee:	ee                   	out    %al,(%dx)
f01002ef:	b0 08                	mov    $0x8,%al
f01002f1:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01002f2:	f7 c6 00 ff ff ff    	test   $0xffffff00,%esi
f01002f8:	75 06                	jne    f0100300 <cons_putc+0x6d>
		c |= 0x0700;
f01002fa:	81 ce 00 07 00 00    	or     $0x700,%esi

	switch (c & 0xff) {
f0100300:	89 f0                	mov    %esi,%eax
f0100302:	25 ff 00 00 00       	and    $0xff,%eax
f0100307:	83 f8 09             	cmp    $0x9,%eax
f010030a:	74 78                	je     f0100384 <cons_putc+0xf1>
f010030c:	83 f8 09             	cmp    $0x9,%eax
f010030f:	7f 0b                	jg     f010031c <cons_putc+0x89>
f0100311:	83 f8 08             	cmp    $0x8,%eax
f0100314:	0f 85 9e 00 00 00    	jne    f01003b8 <cons_putc+0x125>
f010031a:	eb 10                	jmp    f010032c <cons_putc+0x99>
f010031c:	83 f8 0a             	cmp    $0xa,%eax
f010031f:	74 39                	je     f010035a <cons_putc+0xc7>
f0100321:	83 f8 0d             	cmp    $0xd,%eax
f0100324:	0f 85 8e 00 00 00    	jne    f01003b8 <cons_putc+0x125>
f010032a:	eb 36                	jmp    f0100362 <cons_putc+0xcf>
	case '\b':
		if (crt_pos > 0) {
f010032c:	66 a1 34 a5 11 f0    	mov    0xf011a534,%ax
f0100332:	66 85 c0             	test   %ax,%ax
f0100335:	0f 84 e2 00 00 00    	je     f010041d <cons_putc+0x18a>
			crt_pos--;
f010033b:	48                   	dec    %eax
f010033c:	66 a3 34 a5 11 f0    	mov    %ax,0xf011a534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100342:	0f b7 c0             	movzwl %ax,%eax
f0100345:	81 e6 00 ff ff ff    	and    $0xffffff00,%esi
f010034b:	83 ce 20             	or     $0x20,%esi
f010034e:	8b 15 30 a5 11 f0    	mov    0xf011a530,%edx
f0100354:	66 89 34 42          	mov    %si,(%edx,%eax,2)
f0100358:	eb 78                	jmp    f01003d2 <cons_putc+0x13f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010035a:	66 83 05 34 a5 11 f0 	addw   $0x50,0xf011a534
f0100361:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100362:	66 8b 0d 34 a5 11 f0 	mov    0xf011a534,%cx
f0100369:	bb 50 00 00 00       	mov    $0x50,%ebx
f010036e:	89 c8                	mov    %ecx,%eax
f0100370:	ba 00 00 00 00       	mov    $0x0,%edx
f0100375:	66 f7 f3             	div    %bx
f0100378:	66 29 d1             	sub    %dx,%cx
f010037b:	66 89 0d 34 a5 11 f0 	mov    %cx,0xf011a534
f0100382:	eb 4e                	jmp    f01003d2 <cons_putc+0x13f>
		break;
	case '\t':
		cons_putc(' ');
f0100384:	b8 20 00 00 00       	mov    $0x20,%eax
f0100389:	e8 05 ff ff ff       	call   f0100293 <cons_putc>
		cons_putc(' ');
f010038e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100393:	e8 fb fe ff ff       	call   f0100293 <cons_putc>
		cons_putc(' ');
f0100398:	b8 20 00 00 00       	mov    $0x20,%eax
f010039d:	e8 f1 fe ff ff       	call   f0100293 <cons_putc>
		cons_putc(' ');
f01003a2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003a7:	e8 e7 fe ff ff       	call   f0100293 <cons_putc>
		cons_putc(' ');
f01003ac:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b1:	e8 dd fe ff ff       	call   f0100293 <cons_putc>
f01003b6:	eb 1a                	jmp    f01003d2 <cons_putc+0x13f>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003b8:	66 a1 34 a5 11 f0    	mov    0xf011a534,%ax
f01003be:	0f b7 c8             	movzwl %ax,%ecx
f01003c1:	8b 15 30 a5 11 f0    	mov    0xf011a530,%edx
f01003c7:	66 89 34 4a          	mov    %si,(%edx,%ecx,2)
f01003cb:	40                   	inc    %eax
f01003cc:	66 a3 34 a5 11 f0    	mov    %ax,0xf011a534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003d2:	66 81 3d 34 a5 11 f0 	cmpw   $0x7cf,0xf011a534
f01003d9:	cf 07 
f01003db:	76 40                	jbe    f010041d <cons_putc+0x18a>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003dd:	a1 30 a5 11 f0       	mov    0xf011a530,%eax
f01003e2:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01003e9:	00 
f01003ea:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01003f0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01003f4:	89 04 24             	mov    %eax,(%esp)
f01003f7:	e8 5c 11 00 00       	call   f0101558 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01003fc:	8b 15 30 a5 11 f0    	mov    0xf011a530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100402:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100407:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010040d:	40                   	inc    %eax
f010040e:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100413:	75 f2                	jne    f0100407 <cons_putc+0x174>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100415:	66 83 2d 34 a5 11 f0 	subw   $0x50,0xf011a534
f010041c:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010041d:	8b 0d 2c a5 11 f0    	mov    0xf011a52c,%ecx
f0100423:	b0 0e                	mov    $0xe,%al
f0100425:	89 ca                	mov    %ecx,%edx
f0100427:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100428:	66 8b 35 34 a5 11 f0 	mov    0xf011a534,%si
f010042f:	8d 59 01             	lea    0x1(%ecx),%ebx
f0100432:	89 f0                	mov    %esi,%eax
f0100434:	66 c1 e8 08          	shr    $0x8,%ax
f0100438:	89 da                	mov    %ebx,%edx
f010043a:	ee                   	out    %al,(%dx)
f010043b:	b0 0f                	mov    $0xf,%al
f010043d:	89 ca                	mov    %ecx,%edx
f010043f:	ee                   	out    %al,(%dx)
f0100440:	89 f0                	mov    %esi,%eax
f0100442:	89 da                	mov    %ebx,%edx
f0100444:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100445:	83 c4 2c             	add    $0x2c,%esp
f0100448:	5b                   	pop    %ebx
f0100449:	5e                   	pop    %esi
f010044a:	5f                   	pop    %edi
f010044b:	5d                   	pop    %ebp
f010044c:	c3                   	ret    

f010044d <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010044d:	55                   	push   %ebp
f010044e:	89 e5                	mov    %esp,%ebp
f0100450:	53                   	push   %ebx
f0100451:	83 ec 14             	sub    $0x14,%esp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100454:	ba 64 00 00 00       	mov    $0x64,%edx
f0100459:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f010045a:	0f b6 c0             	movzbl %al,%eax
f010045d:	a8 01                	test   $0x1,%al
f010045f:	0f 84 e0 00 00 00    	je     f0100545 <kbd_proc_data+0xf8>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f0100465:	a8 20                	test   $0x20,%al
f0100467:	0f 85 df 00 00 00    	jne    f010054c <kbd_proc_data+0xff>
f010046d:	b2 60                	mov    $0x60,%dl
f010046f:	ec                   	in     (%dx),%al
f0100470:	88 c2                	mov    %al,%dl
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100472:	3c e0                	cmp    $0xe0,%al
f0100474:	75 11                	jne    f0100487 <kbd_proc_data+0x3a>
		// E0 escape character
		shift |= E0ESC;
f0100476:	83 0d 28 a5 11 f0 40 	orl    $0x40,0xf011a528
		return 0;
f010047d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100482:	e9 ca 00 00 00       	jmp    f0100551 <kbd_proc_data+0x104>
	} else if (data & 0x80) {
f0100487:	84 c0                	test   %al,%al
f0100489:	79 33                	jns    f01004be <kbd_proc_data+0x71>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010048b:	8b 0d 28 a5 11 f0    	mov    0xf011a528,%ecx
f0100491:	f6 c1 40             	test   $0x40,%cl
f0100494:	75 05                	jne    f010049b <kbd_proc_data+0x4e>
f0100496:	88 c2                	mov    %al,%dl
f0100498:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010049b:	0f b6 d2             	movzbl %dl,%edx
f010049e:	8a 82 00 1b 10 f0    	mov    -0xfefe500(%edx),%al
f01004a4:	83 c8 40             	or     $0x40,%eax
f01004a7:	0f b6 c0             	movzbl %al,%eax
f01004aa:	f7 d0                	not    %eax
f01004ac:	21 c1                	and    %eax,%ecx
f01004ae:	89 0d 28 a5 11 f0    	mov    %ecx,0xf011a528
		return 0;
f01004b4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01004b9:	e9 93 00 00 00       	jmp    f0100551 <kbd_proc_data+0x104>
	} else if (shift & E0ESC) {
f01004be:	8b 0d 28 a5 11 f0    	mov    0xf011a528,%ecx
f01004c4:	f6 c1 40             	test   $0x40,%cl
f01004c7:	74 0e                	je     f01004d7 <kbd_proc_data+0x8a>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01004c9:	88 c2                	mov    %al,%dl
f01004cb:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01004ce:	83 e1 bf             	and    $0xffffffbf,%ecx
f01004d1:	89 0d 28 a5 11 f0    	mov    %ecx,0xf011a528
	}

	shift |= shiftcode[data];
f01004d7:	0f b6 d2             	movzbl %dl,%edx
f01004da:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f01004e1:	0b 05 28 a5 11 f0    	or     0xf011a528,%eax
	shift ^= togglecode[data];
f01004e7:	0f b6 8a 00 1c 10 f0 	movzbl -0xfefe400(%edx),%ecx
f01004ee:	31 c8                	xor    %ecx,%eax
f01004f0:	a3 28 a5 11 f0       	mov    %eax,0xf011a528

	c = charcode[shift & (CTL | SHIFT)][data];
f01004f5:	89 c1                	mov    %eax,%ecx
f01004f7:	83 e1 03             	and    $0x3,%ecx
f01004fa:	8b 0c 8d 00 1d 10 f0 	mov    -0xfefe300(,%ecx,4),%ecx
f0100501:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100505:	a8 08                	test   $0x8,%al
f0100507:	74 18                	je     f0100521 <kbd_proc_data+0xd4>
		if ('a' <= c && c <= 'z')
f0100509:	8d 53 9f             	lea    -0x61(%ebx),%edx
f010050c:	83 fa 19             	cmp    $0x19,%edx
f010050f:	77 05                	ja     f0100516 <kbd_proc_data+0xc9>
			c += 'A' - 'a';
f0100511:	83 eb 20             	sub    $0x20,%ebx
f0100514:	eb 0b                	jmp    f0100521 <kbd_proc_data+0xd4>
		else if ('A' <= c && c <= 'Z')
f0100516:	8d 53 bf             	lea    -0x41(%ebx),%edx
f0100519:	83 fa 19             	cmp    $0x19,%edx
f010051c:	77 03                	ja     f0100521 <kbd_proc_data+0xd4>
			c += 'a' - 'A';
f010051e:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100521:	f7 d0                	not    %eax
f0100523:	a8 06                	test   $0x6,%al
f0100525:	75 2a                	jne    f0100551 <kbd_proc_data+0x104>
f0100527:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010052d:	75 22                	jne    f0100551 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010052f:	c7 04 24 c8 1a 10 f0 	movl   $0xf0101ac8,(%esp)
f0100536:	e8 2f 05 00 00       	call   f0100a6a <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010053b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100540:	b0 03                	mov    $0x3,%al
f0100542:	ee                   	out    %al,(%dx)
f0100543:	eb 0c                	jmp    f0100551 <kbd_proc_data+0x104>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100545:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010054a:	eb 05                	jmp    f0100551 <kbd_proc_data+0x104>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010054c:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100551:	89 d8                	mov    %ebx,%eax
f0100553:	83 c4 14             	add    $0x14,%esp
f0100556:	5b                   	pop    %ebx
f0100557:	5d                   	pop    %ebp
f0100558:	c3                   	ret    

f0100559 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100559:	55                   	push   %ebp
f010055a:	89 e5                	mov    %esp,%ebp
f010055c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f010055f:	80 3d 00 a3 11 f0 00 	cmpb   $0x0,0xf011a300
f0100566:	74 0a                	je     f0100572 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100568:	b8 36 02 10 f0       	mov    $0xf0100236,%eax
f010056d:	e8 e0 fc ff ff       	call   f0100252 <cons_intr>
}
f0100572:	c9                   	leave  
f0100573:	c3                   	ret    

f0100574 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100574:	55                   	push   %ebp
f0100575:	89 e5                	mov    %esp,%ebp
f0100577:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010057a:	b8 4d 04 10 f0       	mov    $0xf010044d,%eax
f010057f:	e8 ce fc ff ff       	call   f0100252 <cons_intr>
}
f0100584:	c9                   	leave  
f0100585:	c3                   	ret    

f0100586 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100586:	55                   	push   %ebp
f0100587:	89 e5                	mov    %esp,%ebp
f0100589:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010058c:	e8 c8 ff ff ff       	call   f0100559 <serial_intr>
	kbd_intr();
f0100591:	e8 de ff ff ff       	call   f0100574 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100596:	8b 15 20 a5 11 f0    	mov    0xf011a520,%edx
f010059c:	3b 15 24 a5 11 f0    	cmp    0xf011a524,%edx
f01005a2:	74 22                	je     f01005c6 <cons_getc+0x40>
		c = cons.buf[cons.rpos++];
f01005a4:	0f b6 82 20 a3 11 f0 	movzbl -0xfee5ce0(%edx),%eax
f01005ab:	42                   	inc    %edx
f01005ac:	89 15 20 a5 11 f0    	mov    %edx,0xf011a520
		if (cons.rpos == CONSBUFSIZE)
f01005b2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01005b8:	75 11                	jne    f01005cb <cons_getc+0x45>
			cons.rpos = 0;
f01005ba:	c7 05 20 a5 11 f0 00 	movl   $0x0,0xf011a520
f01005c1:	00 00 00 
f01005c4:	eb 05                	jmp    f01005cb <cons_getc+0x45>
		return c;
	}
	return 0;
f01005c6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01005cb:	c9                   	leave  
f01005cc:	c3                   	ret    

f01005cd <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01005cd:	55                   	push   %ebp
f01005ce:	89 e5                	mov    %esp,%ebp
f01005d0:	57                   	push   %edi
f01005d1:	56                   	push   %esi
f01005d2:	53                   	push   %ebx
f01005d3:	83 ec 2c             	sub    $0x2c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01005d6:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f01005dd:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005e4:	5a a5 
	if (*cp != 0xA55A) {
f01005e6:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f01005ec:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005f0:	74 11                	je     f0100603 <cons_init+0x36>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01005f2:	c7 05 2c a5 11 f0 b4 	movl   $0x3b4,0xf011a52c
f01005f9:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005fc:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100601:	eb 16                	jmp    f0100619 <cons_init+0x4c>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100603:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010060a:	c7 05 2c a5 11 f0 d4 	movl   $0x3d4,0xf011a52c
f0100611:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100614:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100619:	8b 0d 2c a5 11 f0    	mov    0xf011a52c,%ecx
f010061f:	b0 0e                	mov    $0xe,%al
f0100621:	89 ca                	mov    %ecx,%edx
f0100623:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100624:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100627:	89 da                	mov    %ebx,%edx
f0100629:	ec                   	in     (%dx),%al
f010062a:	0f b6 f8             	movzbl %al,%edi
f010062d:	c1 e7 08             	shl    $0x8,%edi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100630:	b0 0f                	mov    $0xf,%al
f0100632:	89 ca                	mov    %ecx,%edx
f0100634:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100635:	89 da                	mov    %ebx,%edx
f0100637:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100638:	89 35 30 a5 11 f0    	mov    %esi,0xf011a530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010063e:	0f b6 d8             	movzbl %al,%ebx
f0100641:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100643:	66 89 3d 34 a5 11 f0 	mov    %di,0xf011a534
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010064a:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010064f:	b0 00                	mov    $0x0,%al
f0100651:	89 da                	mov    %ebx,%edx
f0100653:	ee                   	out    %al,(%dx)
f0100654:	b2 fb                	mov    $0xfb,%dl
f0100656:	b0 80                	mov    $0x80,%al
f0100658:	ee                   	out    %al,(%dx)
f0100659:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f010065e:	b0 0c                	mov    $0xc,%al
f0100660:	89 ca                	mov    %ecx,%edx
f0100662:	ee                   	out    %al,(%dx)
f0100663:	b2 f9                	mov    $0xf9,%dl
f0100665:	b0 00                	mov    $0x0,%al
f0100667:	ee                   	out    %al,(%dx)
f0100668:	b2 fb                	mov    $0xfb,%dl
f010066a:	b0 03                	mov    $0x3,%al
f010066c:	ee                   	out    %al,(%dx)
f010066d:	b2 fc                	mov    $0xfc,%dl
f010066f:	b0 00                	mov    $0x0,%al
f0100671:	ee                   	out    %al,(%dx)
f0100672:	b2 f9                	mov    $0xf9,%dl
f0100674:	b0 01                	mov    $0x1,%al
f0100676:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100677:	b2 fd                	mov    $0xfd,%dl
f0100679:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010067a:	3c ff                	cmp    $0xff,%al
f010067c:	0f 95 45 e7          	setne  -0x19(%ebp)
f0100680:	8a 45 e7             	mov    -0x19(%ebp),%al
f0100683:	a2 00 a3 11 f0       	mov    %al,0xf011a300
f0100688:	89 da                	mov    %ebx,%edx
f010068a:	ec                   	in     (%dx),%al
f010068b:	89 ca                	mov    %ecx,%edx
f010068d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010068e:	80 7d e7 00          	cmpb   $0x0,-0x19(%ebp)
f0100692:	75 0c                	jne    f01006a0 <cons_init+0xd3>
		cprintf("Serial port does not exist!\n");
f0100694:	c7 04 24 d4 1a 10 f0 	movl   $0xf0101ad4,(%esp)
f010069b:	e8 ca 03 00 00       	call   f0100a6a <cprintf>
}
f01006a0:	83 c4 2c             	add    $0x2c,%esp
f01006a3:	5b                   	pop    %ebx
f01006a4:	5e                   	pop    %esi
f01006a5:	5f                   	pop    %edi
f01006a6:	5d                   	pop    %ebp
f01006a7:	c3                   	ret    

f01006a8 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006a8:	55                   	push   %ebp
f01006a9:	89 e5                	mov    %esp,%ebp
f01006ab:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01006b1:	e8 dd fb ff ff       	call   f0100293 <cons_putc>
}
f01006b6:	c9                   	leave  
f01006b7:	c3                   	ret    

f01006b8 <getchar>:

int
getchar(void)
{
f01006b8:	55                   	push   %ebp
f01006b9:	89 e5                	mov    %esp,%ebp
f01006bb:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006be:	e8 c3 fe ff ff       	call   f0100586 <cons_getc>
f01006c3:	85 c0                	test   %eax,%eax
f01006c5:	74 f7                	je     f01006be <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006c7:	c9                   	leave  
f01006c8:	c3                   	ret    

f01006c9 <iscons>:

int
iscons(int fdnum)
{
f01006c9:	55                   	push   %ebp
f01006ca:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006cc:	b8 01 00 00 00       	mov    $0x1,%eax
f01006d1:	5d                   	pop    %ebp
f01006d2:	c3                   	ret    
	...

f01006d4 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d4:	55                   	push   %ebp
f01006d5:	89 e5                	mov    %esp,%ebp
f01006d7:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006da:	c7 04 24 10 1d 10 f0 	movl   $0xf0101d10,(%esp)
f01006e1:	e8 84 03 00 00       	call   f0100a6a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006e6:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006ed:	00 
f01006ee:	c7 04 24 f4 1d 10 f0 	movl   $0xf0101df4,(%esp)
f01006f5:	e8 70 03 00 00       	call   f0100a6a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006fa:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100701:	00 
f0100702:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100709:	f0 
f010070a:	c7 04 24 1c 1e 10 f0 	movl   $0xf0101e1c,(%esp)
f0100711:	e8 54 03 00 00       	call   f0100a6a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100716:	c7 44 24 08 52 19 10 	movl   $0x101952,0x8(%esp)
f010071d:	00 
f010071e:	c7 44 24 04 52 19 10 	movl   $0xf0101952,0x4(%esp)
f0100725:	f0 
f0100726:	c7 04 24 40 1e 10 f0 	movl   $0xf0101e40,(%esp)
f010072d:	e8 38 03 00 00       	call   f0100a6a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100732:	c7 44 24 08 00 a3 11 	movl   $0x11a300,0x8(%esp)
f0100739:	00 
f010073a:	c7 44 24 04 00 a3 11 	movl   $0xf011a300,0x4(%esp)
f0100741:	f0 
f0100742:	c7 04 24 64 1e 10 f0 	movl   $0xf0101e64,(%esp)
f0100749:	e8 1c 03 00 00       	call   f0100a6a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010074e:	c7 44 24 08 44 a9 11 	movl   $0x11a944,0x8(%esp)
f0100755:	00 
f0100756:	c7 44 24 04 44 a9 11 	movl   $0xf011a944,0x4(%esp)
f010075d:	f0 
f010075e:	c7 04 24 88 1e 10 f0 	movl   $0xf0101e88,(%esp)
f0100765:	e8 00 03 00 00       	call   f0100a6a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010076a:	b8 43 ad 11 f0       	mov    $0xf011ad43,%eax
f010076f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100774:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100779:	89 c2                	mov    %eax,%edx
f010077b:	85 c0                	test   %eax,%eax
f010077d:	79 06                	jns    f0100785 <mon_kerninfo+0xb1>
f010077f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100785:	c1 fa 0a             	sar    $0xa,%edx
f0100788:	89 54 24 04          	mov    %edx,0x4(%esp)
f010078c:	c7 04 24 ac 1e 10 f0 	movl   $0xf0101eac,(%esp)
f0100793:	e8 d2 02 00 00       	call   f0100a6a <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100798:	b8 00 00 00 00       	mov    $0x0,%eax
f010079d:	c9                   	leave  
f010079e:	c3                   	ret    

f010079f <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010079f:	55                   	push   %ebp
f01007a0:	89 e5                	mov    %esp,%ebp
f01007a2:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007a5:	c7 44 24 08 29 1d 10 	movl   $0xf0101d29,0x8(%esp)
f01007ac:	f0 
f01007ad:	c7 44 24 04 47 1d 10 	movl   $0xf0101d47,0x4(%esp)
f01007b4:	f0 
f01007b5:	c7 04 24 4c 1d 10 f0 	movl   $0xf0101d4c,(%esp)
f01007bc:	e8 a9 02 00 00       	call   f0100a6a <cprintf>
f01007c1:	c7 44 24 08 d8 1e 10 	movl   $0xf0101ed8,0x8(%esp)
f01007c8:	f0 
f01007c9:	c7 44 24 04 55 1d 10 	movl   $0xf0101d55,0x4(%esp)
f01007d0:	f0 
f01007d1:	c7 04 24 4c 1d 10 f0 	movl   $0xf0101d4c,(%esp)
f01007d8:	e8 8d 02 00 00       	call   f0100a6a <cprintf>
	return 0;
}
f01007dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e2:	c9                   	leave  
f01007e3:	c3                   	ret    

f01007e4 <mon_backtrace>:
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007e4:	55                   	push   %ebp
f01007e5:	89 e5                	mov    %esp,%ebp
f01007e7:	57                   	push   %edi
f01007e8:	56                   	push   %esi
f01007e9:	53                   	push   %ebx
f01007ea:	81 ec bc 00 00 00    	sub    $0xbc,%esp
	// Your code here.
    uint8_t i;
    uint32_t* ebp = (uint32_t*) read_ebp();
f01007f0:	89 ee                	mov    %ebp,%esi
    uintptr_t eip = 0;
    struct Eipdebuginfo info;
    uint8_t fun_name[100]; 

    cprintf("Stack backtrace: %s:%d :%s\n", __FILE__, __LINE__, __FUNCTION__);
f01007f2:	c7 44 24 0c 64 1f 10 	movl   $0xf0101f64,0xc(%esp)
f01007f9:	f0 
f01007fa:	c7 44 24 08 42 00 00 	movl   $0x42,0x8(%esp)
f0100801:	00 
f0100802:	c7 44 24 04 5e 1d 10 	movl   $0xf0101d5e,0x4(%esp)
f0100809:	f0 
f010080a:	c7 04 24 6d 1d 10 f0 	movl   $0xf0101d6d,(%esp)
f0100811:	e8 54 02 00 00       	call   f0100a6a <cprintf>

    while (ebp){
f0100816:	e9 b9 00 00 00       	jmp    f01008d4 <mon_backtrace+0xf0>
        // get basic register value
        eip = ebp[1];
f010081b:	8b 46 04             	mov    0x4(%esi),%eax
f010081e:	89 85 64 ff ff ff    	mov    %eax,-0x9c(%ebp)
        cprintf("ebp %08x eip %08x args", ebp, eip);
f0100824:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100828:	89 74 24 04          	mov    %esi,0x4(%esp)
f010082c:	c7 04 24 89 1d 10 f0 	movl   $0xf0101d89,(%esp)
f0100833:	e8 32 02 00 00       	call   f0100a6a <cprintf>
f0100838:	bb 00 00 00 00       	mov    $0x0,%ebx
        for(i=2; i<=6; ++i)
            cprintf(" %08.x", ebp[i]);
f010083d:	8b 44 1e 08          	mov    0x8(%esi,%ebx,1),%eax
f0100841:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100845:	c7 04 24 a0 1d 10 f0 	movl   $0xf0101da0,(%esp)
f010084c:	e8 19 02 00 00       	call   f0100a6a <cprintf>
f0100851:	83 c3 04             	add    $0x4,%ebx

    while (ebp){
        // get basic register value
        eip = ebp[1];
        cprintf("ebp %08x eip %08x args", ebp, eip);
        for(i=2; i<=6; ++i)
f0100854:	83 fb 14             	cmp    $0x14,%ebx
f0100857:	75 e4                	jne    f010083d <mon_backtrace+0x59>
            cprintf(" %08.x", ebp[i]);
        cprintf("\n");
f0100859:	c7 04 24 d2 1a 10 f0 	movl   $0xf0101ad2,(%esp)
f0100860:	e8 05 02 00 00       	call   f0100a6a <cprintf>

        // trace function name from eip
        debuginfo_eip(eip, &info); 
f0100865:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100868:	89 44 24 04          	mov    %eax,0x4(%esp)
f010086c:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
f0100872:	89 04 24             	mov    %eax,(%esp)
f0100875:	e8 ea 02 00 00       	call   f0100b64 <debuginfo_eip>
        for(i=0; i<info.eip_fn_namelen; i++)
f010087a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
            fun_name[i] = info.eip_fn_name[i];
f010087d:	8b 7d d8             	mov    -0x28(%ebp),%edi
            cprintf(" %08.x", ebp[i]);
        cprintf("\n");

        // trace function name from eip
        debuginfo_eip(eip, &info); 
        for(i=0; i<info.eip_fn_namelen; i++)
f0100880:	b0 00                	mov    $0x0,%al
f0100882:	eb 0e                	jmp    f0100892 <mon_backtrace+0xae>
            fun_name[i] = info.eip_fn_name[i];
f0100884:	0f b6 c8             	movzbl %al,%ecx
f0100887:	8a 0c 0f             	mov    (%edi,%ecx,1),%cl
f010088a:	88 8c 15 6c ff ff ff 	mov    %cl,-0x94(%ebp,%edx,1)
            cprintf(" %08.x", ebp[i]);
        cprintf("\n");

        // trace function name from eip
        debuginfo_eip(eip, &info); 
        for(i=0; i<info.eip_fn_namelen; i++)
f0100891:	40                   	inc    %eax
f0100892:	0f b6 d0             	movzbl %al,%edx
f0100895:	39 da                	cmp    %ebx,%edx
f0100897:	7c eb                	jl     f0100884 <mon_backtrace+0xa0>
            fun_name[i] = info.eip_fn_name[i];
        fun_name[info.eip_fn_namelen] = 0;
f0100899:	c6 84 1d 6c ff ff ff 	movb   $0x0,-0x94(%ebp,%ebx,1)
f01008a0:	00 
        cprintf("\t%s:%d: %s+%d\n", info.eip_file, info.eip_line, fun_name, eip-info.eip_fn_addr);
f01008a1:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
f01008a7:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008aa:	89 44 24 10          	mov    %eax,0x10(%esp)
f01008ae:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f01008b4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01008bb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008bf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01008c2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c6:	c7 04 24 a7 1d 10 f0 	movl   $0xf0101da7,(%esp)
f01008cd:	e8 98 01 00 00       	call   f0100a6a <cprintf>

        ebp = (uint32_t*) *ebp;
f01008d2:	8b 36                	mov    (%esi),%esi
    struct Eipdebuginfo info;
    uint8_t fun_name[100]; 

    cprintf("Stack backtrace: %s:%d :%s\n", __FILE__, __LINE__, __FUNCTION__);

    while (ebp){
f01008d4:	85 f6                	test   %esi,%esi
f01008d6:	0f 85 3f ff ff ff    	jne    f010081b <mon_backtrace+0x37>

        ebp = (uint32_t*) *ebp;
    }

	return 0;
}
f01008dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01008e1:	81 c4 bc 00 00 00    	add    $0xbc,%esp
f01008e7:	5b                   	pop    %ebx
f01008e8:	5e                   	pop    %esi
f01008e9:	5f                   	pop    %edi
f01008ea:	5d                   	pop    %ebp
f01008eb:	c3                   	ret    

f01008ec <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008ec:	55                   	push   %ebp
f01008ed:	89 e5                	mov    %esp,%ebp
f01008ef:	57                   	push   %edi
f01008f0:	56                   	push   %esi
f01008f1:	53                   	push   %ebx
f01008f2:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008f5:	c7 04 24 00 1f 10 f0 	movl   $0xf0101f00,(%esp)
f01008fc:	e8 69 01 00 00       	call   f0100a6a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100901:	c7 04 24 24 1f 10 f0 	movl   $0xf0101f24,(%esp)
f0100908:	e8 5d 01 00 00       	call   f0100a6a <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f010090d:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f0100910:	c7 04 24 b6 1d 10 f0 	movl   $0xf0101db6,(%esp)
f0100917:	e8 c8 09 00 00       	call   f01012e4 <readline>
f010091c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010091e:	85 c0                	test   %eax,%eax
f0100920:	74 ee                	je     f0100910 <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100922:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100929:	be 00 00 00 00       	mov    $0x0,%esi
f010092e:	eb 04                	jmp    f0100934 <monitor+0x48>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100930:	c6 03 00             	movb   $0x0,(%ebx)
f0100933:	43                   	inc    %ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100934:	8a 03                	mov    (%ebx),%al
f0100936:	84 c0                	test   %al,%al
f0100938:	74 5e                	je     f0100998 <monitor+0xac>
f010093a:	0f be c0             	movsbl %al,%eax
f010093d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100941:	c7 04 24 ba 1d 10 f0 	movl   $0xf0101dba,(%esp)
f0100948:	e8 8c 0b 00 00       	call   f01014d9 <strchr>
f010094d:	85 c0                	test   %eax,%eax
f010094f:	75 df                	jne    f0100930 <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f0100951:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100954:	74 42                	je     f0100998 <monitor+0xac>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100956:	83 fe 0f             	cmp    $0xf,%esi
f0100959:	75 16                	jne    f0100971 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010095b:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100962:	00 
f0100963:	c7 04 24 bf 1d 10 f0 	movl   $0xf0101dbf,(%esp)
f010096a:	e8 fb 00 00 00       	call   f0100a6a <cprintf>
f010096f:	eb 9f                	jmp    f0100910 <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f0100971:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100975:	46                   	inc    %esi
f0100976:	eb 01                	jmp    f0100979 <monitor+0x8d>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100978:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100979:	8a 03                	mov    (%ebx),%al
f010097b:	84 c0                	test   %al,%al
f010097d:	74 b5                	je     f0100934 <monitor+0x48>
f010097f:	0f be c0             	movsbl %al,%eax
f0100982:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100986:	c7 04 24 ba 1d 10 f0 	movl   $0xf0101dba,(%esp)
f010098d:	e8 47 0b 00 00       	call   f01014d9 <strchr>
f0100992:	85 c0                	test   %eax,%eax
f0100994:	74 e2                	je     f0100978 <monitor+0x8c>
f0100996:	eb 9c                	jmp    f0100934 <monitor+0x48>
			buf++;
	}
	argv[argc] = 0;
f0100998:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010099f:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009a0:	85 f6                	test   %esi,%esi
f01009a2:	0f 84 68 ff ff ff    	je     f0100910 <monitor+0x24>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009a8:	c7 44 24 04 47 1d 10 	movl   $0xf0101d47,0x4(%esp)
f01009af:	f0 
f01009b0:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009b3:	89 04 24             	mov    %eax,(%esp)
f01009b6:	e8 cb 0a 00 00       	call   f0101486 <strcmp>
f01009bb:	85 c0                	test   %eax,%eax
f01009bd:	74 1b                	je     f01009da <monitor+0xee>
f01009bf:	c7 44 24 04 55 1d 10 	movl   $0xf0101d55,0x4(%esp)
f01009c6:	f0 
f01009c7:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009ca:	89 04 24             	mov    %eax,(%esp)
f01009cd:	e8 b4 0a 00 00       	call   f0101486 <strcmp>
f01009d2:	85 c0                	test   %eax,%eax
f01009d4:	75 2c                	jne    f0100a02 <monitor+0x116>
f01009d6:	b0 01                	mov    $0x1,%al
f01009d8:	eb 05                	jmp    f01009df <monitor+0xf3>
f01009da:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01009df:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01009e2:	01 d0                	add    %edx,%eax
f01009e4:	8b 55 08             	mov    0x8(%ebp),%edx
f01009e7:	89 54 24 08          	mov    %edx,0x8(%esp)
f01009eb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01009ef:	89 34 24             	mov    %esi,(%esp)
f01009f2:	ff 14 85 54 1f 10 f0 	call   *-0xfefe0ac(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009f9:	85 c0                	test   %eax,%eax
f01009fb:	78 1d                	js     f0100a1a <monitor+0x12e>
f01009fd:	e9 0e ff ff ff       	jmp    f0100910 <monitor+0x24>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a02:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a05:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a09:	c7 04 24 dc 1d 10 f0 	movl   $0xf0101ddc,(%esp)
f0100a10:	e8 55 00 00 00       	call   f0100a6a <cprintf>
f0100a15:	e9 f6 fe ff ff       	jmp    f0100910 <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a1a:	83 c4 5c             	add    $0x5c,%esp
f0100a1d:	5b                   	pop    %ebx
f0100a1e:	5e                   	pop    %esi
f0100a1f:	5f                   	pop    %edi
f0100a20:	5d                   	pop    %ebp
f0100a21:	c3                   	ret    
	...

f0100a24 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a24:	55                   	push   %ebp
f0100a25:	89 e5                	mov    %esp,%ebp
f0100a27:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100a2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a2d:	89 04 24             	mov    %eax,(%esp)
f0100a30:	e8 73 fc ff ff       	call   f01006a8 <cputchar>
	*cnt++;
}
f0100a35:	c9                   	leave  
f0100a36:	c3                   	ret    

f0100a37 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a37:	55                   	push   %ebp
f0100a38:	89 e5                	mov    %esp,%ebp
f0100a3a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100a3d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a44:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a47:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a4e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a52:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a55:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a59:	c7 04 24 24 0a 10 f0 	movl   $0xf0100a24,(%esp)
f0100a60:	e8 69 04 00 00       	call   f0100ece <vprintfmt>
	return cnt;
}
f0100a65:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a68:	c9                   	leave  
f0100a69:	c3                   	ret    

f0100a6a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a6a:	55                   	push   %ebp
f0100a6b:	89 e5                	mov    %esp,%ebp
f0100a6d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a70:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a73:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a77:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a7a:	89 04 24             	mov    %eax,(%esp)
f0100a7d:	e8 b5 ff ff ff       	call   f0100a37 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a82:	c9                   	leave  
f0100a83:	c3                   	ret    

f0100a84 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a84:	55                   	push   %ebp
f0100a85:	89 e5                	mov    %esp,%ebp
f0100a87:	57                   	push   %edi
f0100a88:	56                   	push   %esi
f0100a89:	53                   	push   %ebx
f0100a8a:	83 ec 10             	sub    $0x10,%esp
f0100a8d:	89 c3                	mov    %eax,%ebx
f0100a8f:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a92:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a95:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a98:	8b 0a                	mov    (%edx),%ecx
f0100a9a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a9d:	8b 00                	mov    (%eax),%eax
f0100a9f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100aa2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100aa9:	eb 77                	jmp    f0100b22 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100aab:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100aae:	01 c8                	add    %ecx,%eax
f0100ab0:	bf 02 00 00 00       	mov    $0x2,%edi
f0100ab5:	99                   	cltd   
f0100ab6:	f7 ff                	idiv   %edi
f0100ab8:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100aba:	eb 01                	jmp    f0100abd <stab_binsearch+0x39>
			m--;
f0100abc:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100abd:	39 ca                	cmp    %ecx,%edx
f0100abf:	7c 1d                	jl     f0100ade <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100ac1:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ac4:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100ac9:	39 f7                	cmp    %esi,%edi
f0100acb:	75 ef                	jne    f0100abc <stab_binsearch+0x38>
f0100acd:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100ad0:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100ad3:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100ad7:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100ada:	73 18                	jae    f0100af4 <stab_binsearch+0x70>
f0100adc:	eb 05                	jmp    f0100ae3 <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100ade:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100ae1:	eb 3f                	jmp    f0100b22 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100ae3:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100ae6:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100ae8:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aeb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100af2:	eb 2e                	jmp    f0100b22 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100af4:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100af7:	76 15                	jbe    f0100b0e <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100af9:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100afc:	4f                   	dec    %edi
f0100afd:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100b00:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b03:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b05:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100b0c:	eb 14                	jmp    f0100b22 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b0e:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100b11:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100b14:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100b16:	ff 45 0c             	incl   0xc(%ebp)
f0100b19:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b1b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100b22:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100b25:	7e 84                	jle    f0100aab <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b27:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100b2b:	75 0d                	jne    f0100b3a <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100b2d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b30:	8b 02                	mov    (%edx),%eax
f0100b32:	48                   	dec    %eax
f0100b33:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b36:	89 01                	mov    %eax,(%ecx)
f0100b38:	eb 22                	jmp    f0100b5c <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b3a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b3d:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b3f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b42:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b44:	eb 01                	jmp    f0100b47 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100b46:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b47:	39 c1                	cmp    %eax,%ecx
f0100b49:	7d 0c                	jge    f0100b57 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100b4b:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100b4e:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100b53:	39 f2                	cmp    %esi,%edx
f0100b55:	75 ef                	jne    f0100b46 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b57:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b5a:	89 02                	mov    %eax,(%edx)
	}
}
f0100b5c:	83 c4 10             	add    $0x10,%esp
f0100b5f:	5b                   	pop    %ebx
f0100b60:	5e                   	pop    %esi
f0100b61:	5f                   	pop    %edi
f0100b62:	5d                   	pop    %ebp
f0100b63:	c3                   	ret    

f0100b64 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b64:	55                   	push   %ebp
f0100b65:	89 e5                	mov    %esp,%ebp
f0100b67:	57                   	push   %edi
f0100b68:	56                   	push   %esi
f0100b69:	53                   	push   %ebx
f0100b6a:	83 ec 4c             	sub    $0x4c,%esp
f0100b6d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b70:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b73:	c7 03 72 1f 10 f0    	movl   $0xf0101f72,(%ebx)
	info->eip_line = 0;
f0100b79:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b80:	c7 43 08 72 1f 10 f0 	movl   $0xf0101f72,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b87:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b8e:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b91:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b98:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b9e:	76 12                	jbe    f0100bb2 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ba0:	b8 62 f5 10 f0       	mov    $0xf010f562,%eax
f0100ba5:	3d c5 68 10 f0       	cmp    $0xf01068c5,%eax
f0100baa:	0f 86 a7 01 00 00    	jbe    f0100d57 <debuginfo_eip+0x1f3>
f0100bb0:	eb 1c                	jmp    f0100bce <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100bb2:	c7 44 24 08 7c 1f 10 	movl   $0xf0101f7c,0x8(%esp)
f0100bb9:	f0 
f0100bba:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100bc1:	00 
f0100bc2:	c7 04 24 89 1f 10 f0 	movl   $0xf0101f89,(%esp)
f0100bc9:	e8 b4 f5 ff ff       	call   f0100182 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bd3:	80 3d 61 f5 10 f0 00 	cmpb   $0x0,0xf010f561
f0100bda:	0f 85 83 01 00 00    	jne    f0100d63 <debuginfo_eip+0x1ff>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100be0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100be7:	b8 c4 68 10 f0       	mov    $0xf01068c4,%eax
f0100bec:	2d a8 21 10 f0       	sub    $0xf01021a8,%eax
f0100bf1:	c1 f8 02             	sar    $0x2,%eax
f0100bf4:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100bfa:	48                   	dec    %eax
f0100bfb:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100bfe:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c02:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100c09:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c0c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c0f:	b8 a8 21 10 f0       	mov    $0xf01021a8,%eax
f0100c14:	e8 6b fe ff ff       	call   f0100a84 <stab_binsearch>
	if (lfile == 0)
f0100c19:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100c1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100c21:	85 d2                	test   %edx,%edx
f0100c23:	0f 84 3a 01 00 00    	je     f0100d63 <debuginfo_eip+0x1ff>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c29:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100c2c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c2f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c32:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c36:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100c3d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c40:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c43:	b8 a8 21 10 f0       	mov    $0xf01021a8,%eax
f0100c48:	e8 37 fe ff ff       	call   f0100a84 <stab_binsearch>

	if (lfun <= rfun) {
f0100c4d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c50:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c53:	39 d0                	cmp    %edx,%eax
f0100c55:	7f 3e                	jg     f0100c95 <debuginfo_eip+0x131>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c57:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100c5a:	8d b9 a8 21 10 f0    	lea    -0xfefde58(%ecx),%edi
f0100c60:	8b 89 a8 21 10 f0    	mov    -0xfefde58(%ecx),%ecx
f0100c66:	89 4d c0             	mov    %ecx,-0x40(%ebp)
f0100c69:	b9 62 f5 10 f0       	mov    $0xf010f562,%ecx
f0100c6e:	81 e9 c5 68 10 f0    	sub    $0xf01068c5,%ecx
f0100c74:	39 4d c0             	cmp    %ecx,-0x40(%ebp)
f0100c77:	73 0c                	jae    f0100c85 <debuginfo_eip+0x121>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c79:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0100c7c:	81 c1 c5 68 10 f0    	add    $0xf01068c5,%ecx
f0100c82:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c85:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c88:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c8b:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c8d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c90:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c93:	eb 0f                	jmp    f0100ca4 <debuginfo_eip+0x140>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c95:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c98:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c9b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c9e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ca1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100ca4:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100cab:	00 
f0100cac:	8b 43 08             	mov    0x8(%ebx),%eax
f0100caf:	89 04 24             	mov    %eax,(%esp)
f0100cb2:	e8 3f 08 00 00       	call   f01014f6 <strfind>
f0100cb7:	2b 43 08             	sub    0x8(%ebx),%eax
f0100cba:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100cbd:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100cc1:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100cc8:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100ccb:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100cce:	b8 a8 21 10 f0       	mov    $0xf01021a8,%eax
f0100cd3:	e8 ac fd ff ff       	call   f0100a84 <stab_binsearch>
    if(lline <= rline){
f0100cd8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
        info->eip_line = stabs[lline].n_desc;
    } else {
        return -1;
f0100cdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if(lline <= rline){
f0100ce0:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100ce3:	7f 7e                	jg     f0100d63 <debuginfo_eip+0x1ff>
        info->eip_line = stabs[lline].n_desc;
f0100ce5:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100ce8:	0f b7 82 ae 21 10 f0 	movzwl -0xfefde52(%edx),%eax
f0100cef:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100cf2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100cf5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cf8:	eb 01                	jmp    f0100cfb <debuginfo_eip+0x197>
f0100cfa:	48                   	dec    %eax
f0100cfb:	89 c6                	mov    %eax,%esi
f0100cfd:	39 c7                	cmp    %eax,%edi
f0100cff:	7f 26                	jg     f0100d27 <debuginfo_eip+0x1c3>
	       && stabs[lline].n_type != N_SOL
f0100d01:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100d04:	8d 0c 95 a8 21 10 f0 	lea    -0xfefde58(,%edx,4),%ecx
f0100d0b:	8a 51 04             	mov    0x4(%ecx),%dl
f0100d0e:	80 fa 84             	cmp    $0x84,%dl
f0100d11:	74 58                	je     f0100d6b <debuginfo_eip+0x207>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d13:	80 fa 64             	cmp    $0x64,%dl
f0100d16:	75 e2                	jne    f0100cfa <debuginfo_eip+0x196>
f0100d18:	83 79 08 00          	cmpl   $0x0,0x8(%ecx)
f0100d1c:	74 dc                	je     f0100cfa <debuginfo_eip+0x196>
f0100d1e:	eb 4b                	jmp    f0100d6b <debuginfo_eip+0x207>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d20:	05 c5 68 10 f0       	add    $0xf01068c5,%eax
f0100d25:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d27:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d2a:	8b 55 d8             	mov    -0x28(%ebp),%edx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d2d:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d32:	39 d1                	cmp    %edx,%ecx
f0100d34:	7d 2d                	jge    f0100d63 <debuginfo_eip+0x1ff>
		for (lline = lfun + 1;
f0100d36:	8d 41 01             	lea    0x1(%ecx),%eax
f0100d39:	eb 03                	jmp    f0100d3e <debuginfo_eip+0x1da>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d3b:	ff 43 14             	incl   0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d3e:	39 d0                	cmp    %edx,%eax
f0100d40:	7d 1c                	jge    f0100d5e <debuginfo_eip+0x1fa>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d42:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100d45:	40                   	inc    %eax
f0100d46:	80 3c 8d ac 21 10 f0 	cmpb   $0xa0,-0xfefde54(,%ecx,4)
f0100d4d:	a0 
f0100d4e:	74 eb                	je     f0100d3b <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d50:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d55:	eb 0c                	jmp    f0100d63 <debuginfo_eip+0x1ff>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d57:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d5c:	eb 05                	jmp    f0100d63 <debuginfo_eip+0x1ff>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d5e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d63:	83 c4 4c             	add    $0x4c,%esp
f0100d66:	5b                   	pop    %ebx
f0100d67:	5e                   	pop    %esi
f0100d68:	5f                   	pop    %edi
f0100d69:	5d                   	pop    %ebp
f0100d6a:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d6b:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100d6e:	8b 86 a8 21 10 f0    	mov    -0xfefde58(%esi),%eax
f0100d74:	ba 62 f5 10 f0       	mov    $0xf010f562,%edx
f0100d79:	81 ea c5 68 10 f0    	sub    $0xf01068c5,%edx
f0100d7f:	39 d0                	cmp    %edx,%eax
f0100d81:	72 9d                	jb     f0100d20 <debuginfo_eip+0x1bc>
f0100d83:	eb a2                	jmp    f0100d27 <debuginfo_eip+0x1c3>
f0100d85:	00 00                	add    %al,(%eax)
	...

f0100d88 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d88:	55                   	push   %ebp
f0100d89:	89 e5                	mov    %esp,%ebp
f0100d8b:	57                   	push   %edi
f0100d8c:	56                   	push   %esi
f0100d8d:	53                   	push   %ebx
f0100d8e:	83 ec 3c             	sub    $0x3c,%esp
f0100d91:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d94:	89 d7                	mov    %edx,%edi
f0100d96:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d99:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100d9c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d9f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100da2:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100da5:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100da8:	85 c0                	test   %eax,%eax
f0100daa:	75 08                	jne    f0100db4 <printnum+0x2c>
f0100dac:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100daf:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100db2:	77 57                	ja     f0100e0b <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100db4:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100db8:	4b                   	dec    %ebx
f0100db9:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100dbd:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dc0:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dc4:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100dc8:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100dcc:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100dd3:	00 
f0100dd4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100dd7:	89 04 24             	mov    %eax,(%esp)
f0100dda:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ddd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100de1:	e8 1e 09 00 00       	call   f0101704 <__udivdi3>
f0100de6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100dea:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100dee:	89 04 24             	mov    %eax,(%esp)
f0100df1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100df5:	89 fa                	mov    %edi,%edx
f0100df7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dfa:	e8 89 ff ff ff       	call   f0100d88 <printnum>
f0100dff:	eb 0f                	jmp    f0100e10 <printnum+0x88>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e01:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e05:	89 34 24             	mov    %esi,(%esp)
f0100e08:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e0b:	4b                   	dec    %ebx
f0100e0c:	85 db                	test   %ebx,%ebx
f0100e0e:	7f f1                	jg     f0100e01 <printnum+0x79>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e10:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e14:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e18:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e1b:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e1f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e26:	00 
f0100e27:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e2a:	89 04 24             	mov    %eax,(%esp)
f0100e2d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e30:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e34:	e8 eb 09 00 00       	call   f0101824 <__umoddi3>
f0100e39:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e3d:	0f be 80 97 1f 10 f0 	movsbl -0xfefe069(%eax),%eax
f0100e44:	89 04 24             	mov    %eax,(%esp)
f0100e47:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100e4a:	83 c4 3c             	add    $0x3c,%esp
f0100e4d:	5b                   	pop    %ebx
f0100e4e:	5e                   	pop    %esi
f0100e4f:	5f                   	pop    %edi
f0100e50:	5d                   	pop    %ebp
f0100e51:	c3                   	ret    

f0100e52 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e52:	55                   	push   %ebp
f0100e53:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e55:	83 fa 01             	cmp    $0x1,%edx
f0100e58:	7e 0e                	jle    f0100e68 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e5a:	8b 10                	mov    (%eax),%edx
f0100e5c:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e5f:	89 08                	mov    %ecx,(%eax)
f0100e61:	8b 02                	mov    (%edx),%eax
f0100e63:	8b 52 04             	mov    0x4(%edx),%edx
f0100e66:	eb 22                	jmp    f0100e8a <getuint+0x38>
	else if (lflag)
f0100e68:	85 d2                	test   %edx,%edx
f0100e6a:	74 10                	je     f0100e7c <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e6c:	8b 10                	mov    (%eax),%edx
f0100e6e:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e71:	89 08                	mov    %ecx,(%eax)
f0100e73:	8b 02                	mov    (%edx),%eax
f0100e75:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e7a:	eb 0e                	jmp    f0100e8a <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e7c:	8b 10                	mov    (%eax),%edx
f0100e7e:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e81:	89 08                	mov    %ecx,(%eax)
f0100e83:	8b 02                	mov    (%edx),%eax
f0100e85:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e8a:	5d                   	pop    %ebp
f0100e8b:	c3                   	ret    

f0100e8c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e8c:	55                   	push   %ebp
f0100e8d:	89 e5                	mov    %esp,%ebp
f0100e8f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e92:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0100e95:	8b 10                	mov    (%eax),%edx
f0100e97:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e9a:	73 08                	jae    f0100ea4 <sprintputch+0x18>
		*b->buf++ = ch;
f0100e9c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100e9f:	88 0a                	mov    %cl,(%edx)
f0100ea1:	42                   	inc    %edx
f0100ea2:	89 10                	mov    %edx,(%eax)
}
f0100ea4:	5d                   	pop    %ebp
f0100ea5:	c3                   	ret    

f0100ea6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100ea6:	55                   	push   %ebp
f0100ea7:	89 e5                	mov    %esp,%ebp
f0100ea9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100eac:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100eaf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100eb3:	8b 45 10             	mov    0x10(%ebp),%eax
f0100eb6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100eba:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ebd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ec1:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ec4:	89 04 24             	mov    %eax,(%esp)
f0100ec7:	e8 02 00 00 00       	call   f0100ece <vprintfmt>
	va_end(ap);
}
f0100ecc:	c9                   	leave  
f0100ecd:	c3                   	ret    

f0100ece <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ece:	55                   	push   %ebp
f0100ecf:	89 e5                	mov    %esp,%ebp
f0100ed1:	57                   	push   %edi
f0100ed2:	56                   	push   %esi
f0100ed3:	53                   	push   %ebx
f0100ed4:	83 ec 4c             	sub    $0x4c,%esp
f0100ed7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100eda:	8b 75 10             	mov    0x10(%ebp),%esi
f0100edd:	eb 12                	jmp    f0100ef1 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100edf:	85 c0                	test   %eax,%eax
f0100ee1:	0f 84 6b 03 00 00    	je     f0101252 <vprintfmt+0x384>
				return;
			putch(ch, putdat);
f0100ee7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100eeb:	89 04 24             	mov    %eax,(%esp)
f0100eee:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ef1:	0f b6 06             	movzbl (%esi),%eax
f0100ef4:	46                   	inc    %esi
f0100ef5:	83 f8 25             	cmp    $0x25,%eax
f0100ef8:	75 e5                	jne    f0100edf <vprintfmt+0x11>
f0100efa:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100efe:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100f05:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100f0a:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100f11:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f16:	eb 26                	jmp    f0100f3e <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f18:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f1b:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100f1f:	eb 1d                	jmp    f0100f3e <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f21:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f24:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100f28:	eb 14                	jmp    f0100f3e <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f2a:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100f2d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100f34:	eb 08                	jmp    f0100f3e <vprintfmt+0x70>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f36:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0100f39:	bf ff ff ff ff       	mov    $0xffffffff,%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3e:	0f b6 06             	movzbl (%esi),%eax
f0100f41:	8d 56 01             	lea    0x1(%esi),%edx
f0100f44:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100f47:	8a 16                	mov    (%esi),%dl
f0100f49:	83 ea 23             	sub    $0x23,%edx
f0100f4c:	80 fa 55             	cmp    $0x55,%dl
f0100f4f:	0f 87 e1 02 00 00    	ja     f0101236 <vprintfmt+0x368>
f0100f55:	0f b6 d2             	movzbl %dl,%edx
f0100f58:	ff 24 95 24 20 10 f0 	jmp    *-0xfefdfdc(,%edx,4)
f0100f5f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100f62:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f67:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0100f6a:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0100f6e:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f71:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100f74:	83 fa 09             	cmp    $0x9,%edx
f0100f77:	77 2a                	ja     f0100fa3 <vprintfmt+0xd5>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f79:	46                   	inc    %esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f7a:	eb eb                	jmp    f0100f67 <vprintfmt+0x99>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f7c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f7f:	8d 50 04             	lea    0x4(%eax),%edx
f0100f82:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f85:	8b 38                	mov    (%eax),%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f87:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f8a:	eb 17                	jmp    f0100fa3 <vprintfmt+0xd5>

		case '.':
			if (width < 0)
f0100f8c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f90:	78 98                	js     f0100f2a <vprintfmt+0x5c>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f92:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100f95:	eb a7                	jmp    f0100f3e <vprintfmt+0x70>
f0100f97:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f9a:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100fa1:	eb 9b                	jmp    f0100f3e <vprintfmt+0x70>

		process_precision:
			if (width < 0)
f0100fa3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100fa7:	79 95                	jns    f0100f3e <vprintfmt+0x70>
f0100fa9:	eb 8b                	jmp    f0100f36 <vprintfmt+0x68>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fab:	41                   	inc    %ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fac:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100faf:	eb 8d                	jmp    f0100f3e <vprintfmt+0x70>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fb1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb4:	8d 50 04             	lea    0x4(%eax),%edx
f0100fb7:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fba:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fbe:	8b 00                	mov    (%eax),%eax
f0100fc0:	89 04 24             	mov    %eax,(%esp)
f0100fc3:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc6:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100fc9:	e9 23 ff ff ff       	jmp    f0100ef1 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fce:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd1:	8d 50 04             	lea    0x4(%eax),%edx
f0100fd4:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fd7:	8b 00                	mov    (%eax),%eax
f0100fd9:	85 c0                	test   %eax,%eax
f0100fdb:	79 02                	jns    f0100fdf <vprintfmt+0x111>
f0100fdd:	f7 d8                	neg    %eax
f0100fdf:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fe1:	83 f8 06             	cmp    $0x6,%eax
f0100fe4:	7f 0b                	jg     f0100ff1 <vprintfmt+0x123>
f0100fe6:	8b 04 85 7c 21 10 f0 	mov    -0xfefde84(,%eax,4),%eax
f0100fed:	85 c0                	test   %eax,%eax
f0100fef:	75 23                	jne    f0101014 <vprintfmt+0x146>
				printfmt(putch, putdat, "error %d", err);
f0100ff1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100ff5:	c7 44 24 08 af 1f 10 	movl   $0xf0101faf,0x8(%esp)
f0100ffc:	f0 
f0100ffd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101001:	8b 45 08             	mov    0x8(%ebp),%eax
f0101004:	89 04 24             	mov    %eax,(%esp)
f0101007:	e8 9a fe ff ff       	call   f0100ea6 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010100c:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010100f:	e9 dd fe ff ff       	jmp    f0100ef1 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0101014:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101018:	c7 44 24 08 b8 1f 10 	movl   $0xf0101fb8,0x8(%esp)
f010101f:	f0 
f0101020:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101024:	8b 55 08             	mov    0x8(%ebp),%edx
f0101027:	89 14 24             	mov    %edx,(%esp)
f010102a:	e8 77 fe ff ff       	call   f0100ea6 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010102f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101032:	e9 ba fe ff ff       	jmp    f0100ef1 <vprintfmt+0x23>
f0101037:	89 f9                	mov    %edi,%ecx
f0101039:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010103c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010103f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101042:	8d 50 04             	lea    0x4(%eax),%edx
f0101045:	89 55 14             	mov    %edx,0x14(%ebp)
f0101048:	8b 30                	mov    (%eax),%esi
f010104a:	85 f6                	test   %esi,%esi
f010104c:	75 05                	jne    f0101053 <vprintfmt+0x185>
				p = "(null)";
f010104e:	be a8 1f 10 f0       	mov    $0xf0101fa8,%esi
			if (width > 0 && padc != '-')
f0101053:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101057:	0f 8e 84 00 00 00    	jle    f01010e1 <vprintfmt+0x213>
f010105d:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0101061:	74 7e                	je     f01010e1 <vprintfmt+0x213>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101063:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101067:	89 34 24             	mov    %esi,(%esp)
f010106a:	e8 53 03 00 00       	call   f01013c2 <strnlen>
f010106f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101072:	29 c2                	sub    %eax,%edx
f0101074:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
f0101077:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010107b:	89 75 d0             	mov    %esi,-0x30(%ebp)
f010107e:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0101081:	89 de                	mov    %ebx,%esi
f0101083:	89 d3                	mov    %edx,%ebx
f0101085:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101087:	eb 0b                	jmp    f0101094 <vprintfmt+0x1c6>
					putch(padc, putdat);
f0101089:	89 74 24 04          	mov    %esi,0x4(%esp)
f010108d:	89 3c 24             	mov    %edi,(%esp)
f0101090:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101093:	4b                   	dec    %ebx
f0101094:	85 db                	test   %ebx,%ebx
f0101096:	7f f1                	jg     f0101089 <vprintfmt+0x1bb>
f0101098:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010109b:	89 f3                	mov    %esi,%ebx
f010109d:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f01010a0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010a3:	85 c0                	test   %eax,%eax
f01010a5:	79 05                	jns    f01010ac <vprintfmt+0x1de>
f01010a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ac:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01010af:	29 c2                	sub    %eax,%edx
f01010b1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01010b4:	eb 2b                	jmp    f01010e1 <vprintfmt+0x213>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010b6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010ba:	74 18                	je     f01010d4 <vprintfmt+0x206>
f01010bc:	8d 50 e0             	lea    -0x20(%eax),%edx
f01010bf:	83 fa 5e             	cmp    $0x5e,%edx
f01010c2:	76 10                	jbe    f01010d4 <vprintfmt+0x206>
					putch('?', putdat);
f01010c4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c8:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010cf:	ff 55 08             	call   *0x8(%ebp)
f01010d2:	eb 0a                	jmp    f01010de <vprintfmt+0x210>
				else
					putch(ch, putdat);
f01010d4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010d8:	89 04 24             	mov    %eax,(%esp)
f01010db:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010de:	ff 4d e4             	decl   -0x1c(%ebp)
f01010e1:	0f be 06             	movsbl (%esi),%eax
f01010e4:	46                   	inc    %esi
f01010e5:	85 c0                	test   %eax,%eax
f01010e7:	74 21                	je     f010110a <vprintfmt+0x23c>
f01010e9:	85 ff                	test   %edi,%edi
f01010eb:	78 c9                	js     f01010b6 <vprintfmt+0x1e8>
f01010ed:	4f                   	dec    %edi
f01010ee:	79 c6                	jns    f01010b6 <vprintfmt+0x1e8>
f01010f0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01010f3:	89 de                	mov    %ebx,%esi
f01010f5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01010f8:	eb 18                	jmp    f0101112 <vprintfmt+0x244>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01010fa:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010fe:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101105:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101107:	4b                   	dec    %ebx
f0101108:	eb 08                	jmp    f0101112 <vprintfmt+0x244>
f010110a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010110d:	89 de                	mov    %ebx,%esi
f010110f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101112:	85 db                	test   %ebx,%ebx
f0101114:	7f e4                	jg     f01010fa <vprintfmt+0x22c>
f0101116:	89 7d 08             	mov    %edi,0x8(%ebp)
f0101119:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010111b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010111e:	e9 ce fd ff ff       	jmp    f0100ef1 <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101123:	83 f9 01             	cmp    $0x1,%ecx
f0101126:	7e 10                	jle    f0101138 <vprintfmt+0x26a>
		return va_arg(*ap, long long);
f0101128:	8b 45 14             	mov    0x14(%ebp),%eax
f010112b:	8d 50 08             	lea    0x8(%eax),%edx
f010112e:	89 55 14             	mov    %edx,0x14(%ebp)
f0101131:	8b 30                	mov    (%eax),%esi
f0101133:	8b 78 04             	mov    0x4(%eax),%edi
f0101136:	eb 26                	jmp    f010115e <vprintfmt+0x290>
	else if (lflag)
f0101138:	85 c9                	test   %ecx,%ecx
f010113a:	74 12                	je     f010114e <vprintfmt+0x280>
		return va_arg(*ap, long);
f010113c:	8b 45 14             	mov    0x14(%ebp),%eax
f010113f:	8d 50 04             	lea    0x4(%eax),%edx
f0101142:	89 55 14             	mov    %edx,0x14(%ebp)
f0101145:	8b 30                	mov    (%eax),%esi
f0101147:	89 f7                	mov    %esi,%edi
f0101149:	c1 ff 1f             	sar    $0x1f,%edi
f010114c:	eb 10                	jmp    f010115e <vprintfmt+0x290>
	else
		return va_arg(*ap, int);
f010114e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101151:	8d 50 04             	lea    0x4(%eax),%edx
f0101154:	89 55 14             	mov    %edx,0x14(%ebp)
f0101157:	8b 30                	mov    (%eax),%esi
f0101159:	89 f7                	mov    %esi,%edi
f010115b:	c1 ff 1f             	sar    $0x1f,%edi
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010115e:	85 ff                	test   %edi,%edi
f0101160:	78 0a                	js     f010116c <vprintfmt+0x29e>
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101162:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101167:	e9 8c 00 00 00       	jmp    f01011f8 <vprintfmt+0x32a>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f010116c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101170:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101177:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010117a:	f7 de                	neg    %esi
f010117c:	83 d7 00             	adc    $0x0,%edi
f010117f:	f7 df                	neg    %edi
			}
			base = 10;
f0101181:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101186:	eb 70                	jmp    f01011f8 <vprintfmt+0x32a>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101188:	89 ca                	mov    %ecx,%edx
f010118a:	8d 45 14             	lea    0x14(%ebp),%eax
f010118d:	e8 c0 fc ff ff       	call   f0100e52 <getuint>
f0101192:	89 c6                	mov    %eax,%esi
f0101194:	89 d7                	mov    %edx,%edi
			base = 10;
f0101196:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010119b:	eb 5b                	jmp    f01011f8 <vprintfmt+0x32a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010119d:	89 ca                	mov    %ecx,%edx
f010119f:	8d 45 14             	lea    0x14(%ebp),%eax
f01011a2:	e8 ab fc ff ff       	call   f0100e52 <getuint>
f01011a7:	89 c6                	mov    %eax,%esi
f01011a9:	89 d7                	mov    %edx,%edi
			base = 8;
f01011ab:	b8 08 00 00 00       	mov    $0x8,%eax
            goto number;
f01011b0:	eb 46                	jmp    f01011f8 <vprintfmt+0x32a>
		// pointer
		case 'p':
			putch('0', putdat);
f01011b2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011b6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011bd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011c0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011c4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011cb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d1:	8d 50 04             	lea    0x4(%eax),%edx
f01011d4:	89 55 14             	mov    %edx,0x14(%ebp)
            goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01011d7:	8b 30                	mov    (%eax),%esi
f01011d9:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01011de:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01011e3:	eb 13                	jmp    f01011f8 <vprintfmt+0x32a>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01011e5:	89 ca                	mov    %ecx,%edx
f01011e7:	8d 45 14             	lea    0x14(%ebp),%eax
f01011ea:	e8 63 fc ff ff       	call   f0100e52 <getuint>
f01011ef:	89 c6                	mov    %eax,%esi
f01011f1:	89 d7                	mov    %edx,%edi
			base = 16;
f01011f3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01011f8:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01011fc:	89 54 24 10          	mov    %edx,0x10(%esp)
f0101200:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101203:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101207:	89 44 24 08          	mov    %eax,0x8(%esp)
f010120b:	89 34 24             	mov    %esi,(%esp)
f010120e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101212:	89 da                	mov    %ebx,%edx
f0101214:	8b 45 08             	mov    0x8(%ebp),%eax
f0101217:	e8 6c fb ff ff       	call   f0100d88 <printnum>
			break;
f010121c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010121f:	e9 cd fc ff ff       	jmp    f0100ef1 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101224:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101228:	89 04 24             	mov    %eax,(%esp)
f010122b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010122e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101231:	e9 bb fc ff ff       	jmp    f0100ef1 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101236:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010123a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101241:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101244:	eb 01                	jmp    f0101247 <vprintfmt+0x379>
f0101246:	4e                   	dec    %esi
f0101247:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010124b:	75 f9                	jne    f0101246 <vprintfmt+0x378>
f010124d:	e9 9f fc ff ff       	jmp    f0100ef1 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f0101252:	83 c4 4c             	add    $0x4c,%esp
f0101255:	5b                   	pop    %ebx
f0101256:	5e                   	pop    %esi
f0101257:	5f                   	pop    %edi
f0101258:	5d                   	pop    %ebp
f0101259:	c3                   	ret    

f010125a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010125a:	55                   	push   %ebp
f010125b:	89 e5                	mov    %esp,%ebp
f010125d:	83 ec 28             	sub    $0x28,%esp
f0101260:	8b 45 08             	mov    0x8(%ebp),%eax
f0101263:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101266:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101269:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010126d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101270:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101277:	85 c0                	test   %eax,%eax
f0101279:	74 30                	je     f01012ab <vsnprintf+0x51>
f010127b:	85 d2                	test   %edx,%edx
f010127d:	7e 33                	jle    f01012b2 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010127f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101282:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101286:	8b 45 10             	mov    0x10(%ebp),%eax
f0101289:	89 44 24 08          	mov    %eax,0x8(%esp)
f010128d:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101290:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101294:	c7 04 24 8c 0e 10 f0 	movl   $0xf0100e8c,(%esp)
f010129b:	e8 2e fc ff ff       	call   f0100ece <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012a3:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012a9:	eb 0c                	jmp    f01012b7 <vsnprintf+0x5d>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012ab:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01012b0:	eb 05                	jmp    f01012b7 <vsnprintf+0x5d>
f01012b2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012b7:	c9                   	leave  
f01012b8:	c3                   	ret    

f01012b9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012b9:	55                   	push   %ebp
f01012ba:	89 e5                	mov    %esp,%ebp
f01012bc:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012bf:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012c6:	8b 45 10             	mov    0x10(%ebp),%eax
f01012c9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012cd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01012d7:	89 04 24             	mov    %eax,(%esp)
f01012da:	e8 7b ff ff ff       	call   f010125a <vsnprintf>
	va_end(ap);

	return rc;
}
f01012df:	c9                   	leave  
f01012e0:	c3                   	ret    
f01012e1:	00 00                	add    %al,(%eax)
	...

f01012e4 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012e4:	55                   	push   %ebp
f01012e5:	89 e5                	mov    %esp,%ebp
f01012e7:	57                   	push   %edi
f01012e8:	56                   	push   %esi
f01012e9:	53                   	push   %ebx
f01012ea:	83 ec 1c             	sub    $0x1c,%esp
f01012ed:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012f0:	85 c0                	test   %eax,%eax
f01012f2:	74 10                	je     f0101304 <readline+0x20>
		cprintf("%s", prompt);
f01012f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012f8:	c7 04 24 b8 1f 10 f0 	movl   $0xf0101fb8,(%esp)
f01012ff:	e8 66 f7 ff ff       	call   f0100a6a <cprintf>

	i = 0;
	echoing = iscons(0);
f0101304:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010130b:	e8 b9 f3 ff ff       	call   f01006c9 <iscons>
f0101310:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101312:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101317:	e8 9c f3 ff ff       	call   f01006b8 <getchar>
f010131c:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010131e:	85 c0                	test   %eax,%eax
f0101320:	79 17                	jns    f0101339 <readline+0x55>
			cprintf("read error: %e\n", c);
f0101322:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101326:	c7 04 24 98 21 10 f0 	movl   $0xf0102198,(%esp)
f010132d:	e8 38 f7 ff ff       	call   f0100a6a <cprintf>
			return NULL;
f0101332:	b8 00 00 00 00       	mov    $0x0,%eax
f0101337:	eb 69                	jmp    f01013a2 <readline+0xbe>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101339:	83 f8 08             	cmp    $0x8,%eax
f010133c:	74 05                	je     f0101343 <readline+0x5f>
f010133e:	83 f8 7f             	cmp    $0x7f,%eax
f0101341:	75 17                	jne    f010135a <readline+0x76>
f0101343:	85 f6                	test   %esi,%esi
f0101345:	7e 13                	jle    f010135a <readline+0x76>
			if (echoing)
f0101347:	85 ff                	test   %edi,%edi
f0101349:	74 0c                	je     f0101357 <readline+0x73>
				cputchar('\b');
f010134b:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0101352:	e8 51 f3 ff ff       	call   f01006a8 <cputchar>
			i--;
f0101357:	4e                   	dec    %esi
f0101358:	eb bd                	jmp    f0101317 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010135a:	83 fb 1f             	cmp    $0x1f,%ebx
f010135d:	7e 1d                	jle    f010137c <readline+0x98>
f010135f:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101365:	7f 15                	jg     f010137c <readline+0x98>
			if (echoing)
f0101367:	85 ff                	test   %edi,%edi
f0101369:	74 08                	je     f0101373 <readline+0x8f>
				cputchar(c);
f010136b:	89 1c 24             	mov    %ebx,(%esp)
f010136e:	e8 35 f3 ff ff       	call   f01006a8 <cputchar>
			buf[i++] = c;
f0101373:	88 9e 40 a5 11 f0    	mov    %bl,-0xfee5ac0(%esi)
f0101379:	46                   	inc    %esi
f010137a:	eb 9b                	jmp    f0101317 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010137c:	83 fb 0a             	cmp    $0xa,%ebx
f010137f:	74 05                	je     f0101386 <readline+0xa2>
f0101381:	83 fb 0d             	cmp    $0xd,%ebx
f0101384:	75 91                	jne    f0101317 <readline+0x33>
			if (echoing)
f0101386:	85 ff                	test   %edi,%edi
f0101388:	74 0c                	je     f0101396 <readline+0xb2>
				cputchar('\n');
f010138a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101391:	e8 12 f3 ff ff       	call   f01006a8 <cputchar>
			buf[i] = 0;
f0101396:	c6 86 40 a5 11 f0 00 	movb   $0x0,-0xfee5ac0(%esi)
			return buf;
f010139d:	b8 40 a5 11 f0       	mov    $0xf011a540,%eax
		}
	}
}
f01013a2:	83 c4 1c             	add    $0x1c,%esp
f01013a5:	5b                   	pop    %ebx
f01013a6:	5e                   	pop    %esi
f01013a7:	5f                   	pop    %edi
f01013a8:	5d                   	pop    %ebp
f01013a9:	c3                   	ret    
	...

f01013ac <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013ac:	55                   	push   %ebp
f01013ad:	89 e5                	mov    %esp,%ebp
f01013af:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013b2:	b8 00 00 00 00       	mov    $0x0,%eax
f01013b7:	eb 01                	jmp    f01013ba <strlen+0xe>
		n++;
f01013b9:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013ba:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013be:	75 f9                	jne    f01013b9 <strlen+0xd>
		n++;
	return n;
}
f01013c0:	5d                   	pop    %ebp
f01013c1:	c3                   	ret    

f01013c2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013c2:	55                   	push   %ebp
f01013c3:	89 e5                	mov    %esp,%ebp
f01013c5:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
f01013c8:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01013d0:	eb 01                	jmp    f01013d3 <strnlen+0x11>
		n++;
f01013d2:	40                   	inc    %eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013d3:	39 d0                	cmp    %edx,%eax
f01013d5:	74 06                	je     f01013dd <strnlen+0x1b>
f01013d7:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01013db:	75 f5                	jne    f01013d2 <strnlen+0x10>
		n++;
	return n;
}
f01013dd:	5d                   	pop    %ebp
f01013de:	c3                   	ret    

f01013df <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013df:	55                   	push   %ebp
f01013e0:	89 e5                	mov    %esp,%ebp
f01013e2:	53                   	push   %ebx
f01013e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013e9:	ba 00 00 00 00       	mov    $0x0,%edx
f01013ee:	8a 0c 13             	mov    (%ebx,%edx,1),%cl
f01013f1:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01013f4:	42                   	inc    %edx
f01013f5:	84 c9                	test   %cl,%cl
f01013f7:	75 f5                	jne    f01013ee <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01013f9:	5b                   	pop    %ebx
f01013fa:	5d                   	pop    %ebp
f01013fb:	c3                   	ret    

f01013fc <strcat>:

char *
strcat(char *dst, const char *src)
{
f01013fc:	55                   	push   %ebp
f01013fd:	89 e5                	mov    %esp,%ebp
f01013ff:	53                   	push   %ebx
f0101400:	83 ec 08             	sub    $0x8,%esp
f0101403:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101406:	89 1c 24             	mov    %ebx,(%esp)
f0101409:	e8 9e ff ff ff       	call   f01013ac <strlen>
	strcpy(dst + len, src);
f010140e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101411:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101415:	01 d8                	add    %ebx,%eax
f0101417:	89 04 24             	mov    %eax,(%esp)
f010141a:	e8 c0 ff ff ff       	call   f01013df <strcpy>
	return dst;
}
f010141f:	89 d8                	mov    %ebx,%eax
f0101421:	83 c4 08             	add    $0x8,%esp
f0101424:	5b                   	pop    %ebx
f0101425:	5d                   	pop    %ebp
f0101426:	c3                   	ret    

f0101427 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101427:	55                   	push   %ebp
f0101428:	89 e5                	mov    %esp,%ebp
f010142a:	56                   	push   %esi
f010142b:	53                   	push   %ebx
f010142c:	8b 45 08             	mov    0x8(%ebp),%eax
f010142f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101432:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101435:	b9 00 00 00 00       	mov    $0x0,%ecx
f010143a:	eb 0c                	jmp    f0101448 <strncpy+0x21>
		*dst++ = *src;
f010143c:	8a 1a                	mov    (%edx),%bl
f010143e:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101441:	80 3a 01             	cmpb   $0x1,(%edx)
f0101444:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101447:	41                   	inc    %ecx
f0101448:	39 f1                	cmp    %esi,%ecx
f010144a:	75 f0                	jne    f010143c <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010144c:	5b                   	pop    %ebx
f010144d:	5e                   	pop    %esi
f010144e:	5d                   	pop    %ebp
f010144f:	c3                   	ret    

f0101450 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101450:	55                   	push   %ebp
f0101451:	89 e5                	mov    %esp,%ebp
f0101453:	56                   	push   %esi
f0101454:	53                   	push   %ebx
f0101455:	8b 75 08             	mov    0x8(%ebp),%esi
f0101458:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010145b:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010145e:	85 d2                	test   %edx,%edx
f0101460:	75 0a                	jne    f010146c <strlcpy+0x1c>
f0101462:	89 f0                	mov    %esi,%eax
f0101464:	eb 1a                	jmp    f0101480 <strlcpy+0x30>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101466:	88 18                	mov    %bl,(%eax)
f0101468:	40                   	inc    %eax
f0101469:	41                   	inc    %ecx
f010146a:	eb 02                	jmp    f010146e <strlcpy+0x1e>
strlcpy(char *dst, const char *src, size_t size)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010146c:	89 f0                	mov    %esi,%eax
		while (--size > 0 && *src != '\0')
f010146e:	4a                   	dec    %edx
f010146f:	74 0a                	je     f010147b <strlcpy+0x2b>
f0101471:	8a 19                	mov    (%ecx),%bl
f0101473:	84 db                	test   %bl,%bl
f0101475:	75 ef                	jne    f0101466 <strlcpy+0x16>
f0101477:	89 c2                	mov    %eax,%edx
f0101479:	eb 02                	jmp    f010147d <strlcpy+0x2d>
f010147b:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f010147d:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101480:	29 f0                	sub    %esi,%eax
}
f0101482:	5b                   	pop    %ebx
f0101483:	5e                   	pop    %esi
f0101484:	5d                   	pop    %ebp
f0101485:	c3                   	ret    

f0101486 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101486:	55                   	push   %ebp
f0101487:	89 e5                	mov    %esp,%ebp
f0101489:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010148c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010148f:	eb 02                	jmp    f0101493 <strcmp+0xd>
		p++, q++;
f0101491:	41                   	inc    %ecx
f0101492:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101493:	8a 01                	mov    (%ecx),%al
f0101495:	84 c0                	test   %al,%al
f0101497:	74 04                	je     f010149d <strcmp+0x17>
f0101499:	3a 02                	cmp    (%edx),%al
f010149b:	74 f4                	je     f0101491 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010149d:	0f b6 c0             	movzbl %al,%eax
f01014a0:	0f b6 12             	movzbl (%edx),%edx
f01014a3:	29 d0                	sub    %edx,%eax
}
f01014a5:	5d                   	pop    %ebp
f01014a6:	c3                   	ret    

f01014a7 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014a7:	55                   	push   %ebp
f01014a8:	89 e5                	mov    %esp,%ebp
f01014aa:	53                   	push   %ebx
f01014ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ae:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014b1:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
f01014b4:	eb 03                	jmp    f01014b9 <strncmp+0x12>
		n--, p++, q++;
f01014b6:	4a                   	dec    %edx
f01014b7:	40                   	inc    %eax
f01014b8:	41                   	inc    %ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014b9:	85 d2                	test   %edx,%edx
f01014bb:	74 14                	je     f01014d1 <strncmp+0x2a>
f01014bd:	8a 18                	mov    (%eax),%bl
f01014bf:	84 db                	test   %bl,%bl
f01014c1:	74 04                	je     f01014c7 <strncmp+0x20>
f01014c3:	3a 19                	cmp    (%ecx),%bl
f01014c5:	74 ef                	je     f01014b6 <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014c7:	0f b6 00             	movzbl (%eax),%eax
f01014ca:	0f b6 11             	movzbl (%ecx),%edx
f01014cd:	29 d0                	sub    %edx,%eax
f01014cf:	eb 05                	jmp    f01014d6 <strncmp+0x2f>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01014d1:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01014d6:	5b                   	pop    %ebx
f01014d7:	5d                   	pop    %ebp
f01014d8:	c3                   	ret    

f01014d9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014d9:	55                   	push   %ebp
f01014da:	89 e5                	mov    %esp,%ebp
f01014dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01014df:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f01014e2:	eb 05                	jmp    f01014e9 <strchr+0x10>
		if (*s == c)
f01014e4:	38 ca                	cmp    %cl,%dl
f01014e6:	74 0c                	je     f01014f4 <strchr+0x1b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014e8:	40                   	inc    %eax
f01014e9:	8a 10                	mov    (%eax),%dl
f01014eb:	84 d2                	test   %dl,%dl
f01014ed:	75 f5                	jne    f01014e4 <strchr+0xb>
		if (*s == c)
			return (char *) s;
	return 0;
f01014ef:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014f4:	5d                   	pop    %ebp
f01014f5:	c3                   	ret    

f01014f6 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01014f6:	55                   	push   %ebp
f01014f7:	89 e5                	mov    %esp,%ebp
f01014f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01014fc:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f01014ff:	eb 05                	jmp    f0101506 <strfind+0x10>
		if (*s == c)
f0101501:	38 ca                	cmp    %cl,%dl
f0101503:	74 07                	je     f010150c <strfind+0x16>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101505:	40                   	inc    %eax
f0101506:	8a 10                	mov    (%eax),%dl
f0101508:	84 d2                	test   %dl,%dl
f010150a:	75 f5                	jne    f0101501 <strfind+0xb>
		if (*s == c)
			break;
	return (char *) s;
}
f010150c:	5d                   	pop    %ebp
f010150d:	c3                   	ret    

f010150e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010150e:	55                   	push   %ebp
f010150f:	89 e5                	mov    %esp,%ebp
f0101511:	57                   	push   %edi
f0101512:	56                   	push   %esi
f0101513:	53                   	push   %ebx
f0101514:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101517:	8b 45 0c             	mov    0xc(%ebp),%eax
f010151a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010151d:	85 c9                	test   %ecx,%ecx
f010151f:	74 30                	je     f0101551 <memset+0x43>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101521:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101527:	75 25                	jne    f010154e <memset+0x40>
f0101529:	f6 c1 03             	test   $0x3,%cl
f010152c:	75 20                	jne    f010154e <memset+0x40>
		c &= 0xFF;
f010152e:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101531:	89 d3                	mov    %edx,%ebx
f0101533:	c1 e3 08             	shl    $0x8,%ebx
f0101536:	89 d6                	mov    %edx,%esi
f0101538:	c1 e6 18             	shl    $0x18,%esi
f010153b:	89 d0                	mov    %edx,%eax
f010153d:	c1 e0 10             	shl    $0x10,%eax
f0101540:	09 f0                	or     %esi,%eax
f0101542:	09 d0                	or     %edx,%eax
f0101544:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101546:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101549:	fc                   	cld    
f010154a:	f3 ab                	rep stos %eax,%es:(%edi)
f010154c:	eb 03                	jmp    f0101551 <memset+0x43>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010154e:	fc                   	cld    
f010154f:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101551:	89 f8                	mov    %edi,%eax
f0101553:	5b                   	pop    %ebx
f0101554:	5e                   	pop    %esi
f0101555:	5f                   	pop    %edi
f0101556:	5d                   	pop    %ebp
f0101557:	c3                   	ret    

f0101558 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101558:	55                   	push   %ebp
f0101559:	89 e5                	mov    %esp,%ebp
f010155b:	57                   	push   %edi
f010155c:	56                   	push   %esi
f010155d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101560:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101563:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101566:	39 c6                	cmp    %eax,%esi
f0101568:	73 34                	jae    f010159e <memmove+0x46>
f010156a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010156d:	39 d0                	cmp    %edx,%eax
f010156f:	73 2d                	jae    f010159e <memmove+0x46>
		s += n;
		d += n;
f0101571:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101574:	f6 c2 03             	test   $0x3,%dl
f0101577:	75 1b                	jne    f0101594 <memmove+0x3c>
f0101579:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010157f:	75 13                	jne    f0101594 <memmove+0x3c>
f0101581:	f6 c1 03             	test   $0x3,%cl
f0101584:	75 0e                	jne    f0101594 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101586:	83 ef 04             	sub    $0x4,%edi
f0101589:	8d 72 fc             	lea    -0x4(%edx),%esi
f010158c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010158f:	fd                   	std    
f0101590:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101592:	eb 07                	jmp    f010159b <memmove+0x43>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101594:	4f                   	dec    %edi
f0101595:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101598:	fd                   	std    
f0101599:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010159b:	fc                   	cld    
f010159c:	eb 20                	jmp    f01015be <memmove+0x66>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010159e:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015a4:	75 13                	jne    f01015b9 <memmove+0x61>
f01015a6:	a8 03                	test   $0x3,%al
f01015a8:	75 0f                	jne    f01015b9 <memmove+0x61>
f01015aa:	f6 c1 03             	test   $0x3,%cl
f01015ad:	75 0a                	jne    f01015b9 <memmove+0x61>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015af:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01015b2:	89 c7                	mov    %eax,%edi
f01015b4:	fc                   	cld    
f01015b5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015b7:	eb 05                	jmp    f01015be <memmove+0x66>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015b9:	89 c7                	mov    %eax,%edi
f01015bb:	fc                   	cld    
f01015bc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015be:	5e                   	pop    %esi
f01015bf:	5f                   	pop    %edi
f01015c0:	5d                   	pop    %ebp
f01015c1:	c3                   	ret    

f01015c2 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01015c2:	55                   	push   %ebp
f01015c3:	89 e5                	mov    %esp,%ebp
f01015c5:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01015c8:	8b 45 10             	mov    0x10(%ebp),%eax
f01015cb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01015d9:	89 04 24             	mov    %eax,(%esp)
f01015dc:	e8 77 ff ff ff       	call   f0101558 <memmove>
}
f01015e1:	c9                   	leave  
f01015e2:	c3                   	ret    

f01015e3 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015e3:	55                   	push   %ebp
f01015e4:	89 e5                	mov    %esp,%ebp
f01015e6:	57                   	push   %edi
f01015e7:	56                   	push   %esi
f01015e8:	53                   	push   %ebx
f01015e9:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015ec:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015ef:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015f2:	ba 00 00 00 00       	mov    $0x0,%edx
f01015f7:	eb 16                	jmp    f010160f <memcmp+0x2c>
		if (*s1 != *s2)
f01015f9:	8a 04 17             	mov    (%edi,%edx,1),%al
f01015fc:	42                   	inc    %edx
f01015fd:	8a 4c 16 ff          	mov    -0x1(%esi,%edx,1),%cl
f0101601:	38 c8                	cmp    %cl,%al
f0101603:	74 0a                	je     f010160f <memcmp+0x2c>
			return (int) *s1 - (int) *s2;
f0101605:	0f b6 c0             	movzbl %al,%eax
f0101608:	0f b6 c9             	movzbl %cl,%ecx
f010160b:	29 c8                	sub    %ecx,%eax
f010160d:	eb 09                	jmp    f0101618 <memcmp+0x35>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010160f:	39 da                	cmp    %ebx,%edx
f0101611:	75 e6                	jne    f01015f9 <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101613:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101618:	5b                   	pop    %ebx
f0101619:	5e                   	pop    %esi
f010161a:	5f                   	pop    %edi
f010161b:	5d                   	pop    %ebp
f010161c:	c3                   	ret    

f010161d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010161d:	55                   	push   %ebp
f010161e:	89 e5                	mov    %esp,%ebp
f0101620:	8b 45 08             	mov    0x8(%ebp),%eax
f0101623:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101626:	89 c2                	mov    %eax,%edx
f0101628:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010162b:	eb 05                	jmp    f0101632 <memfind+0x15>
		if (*(const unsigned char *) s == (unsigned char) c)
f010162d:	38 08                	cmp    %cl,(%eax)
f010162f:	74 05                	je     f0101636 <memfind+0x19>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101631:	40                   	inc    %eax
f0101632:	39 d0                	cmp    %edx,%eax
f0101634:	72 f7                	jb     f010162d <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101636:	5d                   	pop    %ebp
f0101637:	c3                   	ret    

f0101638 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101638:	55                   	push   %ebp
f0101639:	89 e5                	mov    %esp,%ebp
f010163b:	57                   	push   %edi
f010163c:	56                   	push   %esi
f010163d:	53                   	push   %ebx
f010163e:	8b 55 08             	mov    0x8(%ebp),%edx
f0101641:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101644:	eb 01                	jmp    f0101647 <strtol+0xf>
		s++;
f0101646:	42                   	inc    %edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101647:	8a 02                	mov    (%edx),%al
f0101649:	3c 20                	cmp    $0x20,%al
f010164b:	74 f9                	je     f0101646 <strtol+0xe>
f010164d:	3c 09                	cmp    $0x9,%al
f010164f:	74 f5                	je     f0101646 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101651:	3c 2b                	cmp    $0x2b,%al
f0101653:	75 08                	jne    f010165d <strtol+0x25>
		s++;
f0101655:	42                   	inc    %edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101656:	bf 00 00 00 00       	mov    $0x0,%edi
f010165b:	eb 13                	jmp    f0101670 <strtol+0x38>
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010165d:	3c 2d                	cmp    $0x2d,%al
f010165f:	75 0a                	jne    f010166b <strtol+0x33>
		s++, neg = 1;
f0101661:	8d 52 01             	lea    0x1(%edx),%edx
f0101664:	bf 01 00 00 00       	mov    $0x1,%edi
f0101669:	eb 05                	jmp    f0101670 <strtol+0x38>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010166b:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101670:	85 db                	test   %ebx,%ebx
f0101672:	74 05                	je     f0101679 <strtol+0x41>
f0101674:	83 fb 10             	cmp    $0x10,%ebx
f0101677:	75 28                	jne    f01016a1 <strtol+0x69>
f0101679:	8a 02                	mov    (%edx),%al
f010167b:	3c 30                	cmp    $0x30,%al
f010167d:	75 10                	jne    f010168f <strtol+0x57>
f010167f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101683:	75 0a                	jne    f010168f <strtol+0x57>
		s += 2, base = 16;
f0101685:	83 c2 02             	add    $0x2,%edx
f0101688:	bb 10 00 00 00       	mov    $0x10,%ebx
f010168d:	eb 12                	jmp    f01016a1 <strtol+0x69>
	else if (base == 0 && s[0] == '0')
f010168f:	85 db                	test   %ebx,%ebx
f0101691:	75 0e                	jne    f01016a1 <strtol+0x69>
f0101693:	3c 30                	cmp    $0x30,%al
f0101695:	75 05                	jne    f010169c <strtol+0x64>
		s++, base = 8;
f0101697:	42                   	inc    %edx
f0101698:	b3 08                	mov    $0x8,%bl
f010169a:	eb 05                	jmp    f01016a1 <strtol+0x69>
	else if (base == 0)
		base = 10;
f010169c:	bb 0a 00 00 00       	mov    $0xa,%ebx
f01016a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01016a6:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016a8:	8a 0a                	mov    (%edx),%cl
f01016aa:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01016ad:	80 fb 09             	cmp    $0x9,%bl
f01016b0:	77 08                	ja     f01016ba <strtol+0x82>
			dig = *s - '0';
f01016b2:	0f be c9             	movsbl %cl,%ecx
f01016b5:	83 e9 30             	sub    $0x30,%ecx
f01016b8:	eb 1e                	jmp    f01016d8 <strtol+0xa0>
		else if (*s >= 'a' && *s <= 'z')
f01016ba:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01016bd:	80 fb 19             	cmp    $0x19,%bl
f01016c0:	77 08                	ja     f01016ca <strtol+0x92>
			dig = *s - 'a' + 10;
f01016c2:	0f be c9             	movsbl %cl,%ecx
f01016c5:	83 e9 57             	sub    $0x57,%ecx
f01016c8:	eb 0e                	jmp    f01016d8 <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
f01016ca:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f01016cd:	80 fb 19             	cmp    $0x19,%bl
f01016d0:	77 12                	ja     f01016e4 <strtol+0xac>
			dig = *s - 'A' + 10;
f01016d2:	0f be c9             	movsbl %cl,%ecx
f01016d5:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01016d8:	39 f1                	cmp    %esi,%ecx
f01016da:	7d 0c                	jge    f01016e8 <strtol+0xb0>
			break;
		s++, val = (val * base) + dig;
f01016dc:	42                   	inc    %edx
f01016dd:	0f af c6             	imul   %esi,%eax
f01016e0:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01016e2:	eb c4                	jmp    f01016a8 <strtol+0x70>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01016e4:	89 c1                	mov    %eax,%ecx
f01016e6:	eb 02                	jmp    f01016ea <strtol+0xb2>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01016e8:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01016ea:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01016ee:	74 05                	je     f01016f5 <strtol+0xbd>
		*endptr = (char *) s;
f01016f0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01016f3:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01016f5:	85 ff                	test   %edi,%edi
f01016f7:	74 04                	je     f01016fd <strtol+0xc5>
f01016f9:	89 c8                	mov    %ecx,%eax
f01016fb:	f7 d8                	neg    %eax
}
f01016fd:	5b                   	pop    %ebx
f01016fe:	5e                   	pop    %esi
f01016ff:	5f                   	pop    %edi
f0101700:	5d                   	pop    %ebp
f0101701:	c3                   	ret    
	...

f0101704 <__udivdi3>:
#endif

#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
f0101704:	55                   	push   %ebp
f0101705:	57                   	push   %edi
f0101706:	56                   	push   %esi
f0101707:	83 ec 10             	sub    $0x10,%esp
f010170a:	8b 74 24 20          	mov    0x20(%esp),%esi
f010170e:	8b 4c 24 28          	mov    0x28(%esp),%ecx
static inline __attribute__ ((__always_inline__))
#endif
UDWtype
__udivmoddi4 (UDWtype n, UDWtype d, UDWtype *rp)
{
  const DWunion nn = {.ll = n};
f0101712:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101716:	8b 7c 24 24          	mov    0x24(%esp),%edi
  const DWunion dd = {.ll = d};
f010171a:	89 cd                	mov    %ecx,%ebp
f010171c:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  d1 = dd.s.high;
  n0 = nn.s.low;
  n1 = nn.s.high;

#if !UDIV_NEEDS_NORMALIZATION
  if (d1 == 0)
f0101720:	85 c0                	test   %eax,%eax
f0101722:	75 2c                	jne    f0101750 <__udivdi3+0x4c>
    {
      if (d0 > n1)
f0101724:	39 f9                	cmp    %edi,%ecx
f0101726:	77 68                	ja     f0101790 <__udivdi3+0x8c>
	}
      else
	{
	  /* qq = NN / 0d */

	  if (d0 == 0)
f0101728:	85 c9                	test   %ecx,%ecx
f010172a:	75 0b                	jne    f0101737 <__udivdi3+0x33>
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */
f010172c:	b8 01 00 00 00       	mov    $0x1,%eax
f0101731:	31 d2                	xor    %edx,%edx
f0101733:	f7 f1                	div    %ecx
f0101735:	89 c1                	mov    %eax,%ecx

	  udiv_qrnnd (q1, n1, 0, n1, d0);
f0101737:	31 d2                	xor    %edx,%edx
f0101739:	89 f8                	mov    %edi,%eax
f010173b:	f7 f1                	div    %ecx
f010173d:	89 c7                	mov    %eax,%edi
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f010173f:	89 f0                	mov    %esi,%eax
f0101741:	f7 f1                	div    %ecx
f0101743:	89 c6                	mov    %eax,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0101745:	89 f0                	mov    %esi,%eax
f0101747:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0101749:	83 c4 10             	add    $0x10,%esp
f010174c:	5e                   	pop    %esi
f010174d:	5f                   	pop    %edi
f010174e:	5d                   	pop    %ebp
f010174f:	c3                   	ret    
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f0101750:	39 f8                	cmp    %edi,%eax
f0101752:	77 2c                	ja     f0101780 <__udivdi3+0x7c>
	}
      else
	{
	  /* 0q = NN / dd */

	  count_leading_zeros (bm, d1);
f0101754:	0f bd f0             	bsr    %eax,%esi
	  if (bm == 0)
f0101757:	83 f6 1f             	xor    $0x1f,%esi
f010175a:	75 4c                	jne    f01017a8 <__udivdi3+0xa4>

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f010175c:	39 f8                	cmp    %edi,%eax
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f010175e:	bf 00 00 00 00       	mov    $0x0,%edi

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0101763:	72 0a                	jb     f010176f <__udivdi3+0x6b>
f0101765:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0101769:	0f 87 ad 00 00 00    	ja     f010181c <__udivdi3+0x118>
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f010176f:	be 01 00 00 00       	mov    $0x1,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0101774:	89 f0                	mov    %esi,%eax
f0101776:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0101778:	83 c4 10             	add    $0x10,%esp
f010177b:	5e                   	pop    %esi
f010177c:	5f                   	pop    %edi
f010177d:	5d                   	pop    %ebp
f010177e:	c3                   	ret    
f010177f:	90                   	nop
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f0101780:	31 ff                	xor    %edi,%edi
f0101782:	31 f6                	xor    %esi,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0101784:	89 f0                	mov    %esi,%eax
f0101786:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0101788:	83 c4 10             	add    $0x10,%esp
f010178b:	5e                   	pop    %esi
f010178c:	5f                   	pop    %edi
f010178d:	5d                   	pop    %ebp
f010178e:	c3                   	ret    
f010178f:	90                   	nop
    {
      if (d0 > n1)
	{
	  /* 0q = nn / 0D */

	  udiv_qrnnd (q0, n0, n1, n0, d0);
f0101790:	89 fa                	mov    %edi,%edx
f0101792:	89 f0                	mov    %esi,%eax
f0101794:	f7 f1                	div    %ecx
f0101796:	89 c6                	mov    %eax,%esi
f0101798:	31 ff                	xor    %edi,%edi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f010179a:	89 f0                	mov    %esi,%eax
f010179c:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f010179e:	83 c4 10             	add    $0x10,%esp
f01017a1:	5e                   	pop    %esi
f01017a2:	5f                   	pop    %edi
f01017a3:	5d                   	pop    %ebp
f01017a4:	c3                   	ret    
f01017a5:	8d 76 00             	lea    0x0(%esi),%esi
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
f01017a8:	89 f1                	mov    %esi,%ecx
f01017aa:	d3 e0                	shl    %cl,%eax
f01017ac:	89 44 24 0c          	mov    %eax,0xc(%esp)
	  else
	    {
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;
f01017b0:	b8 20 00 00 00       	mov    $0x20,%eax
f01017b5:	29 f0                	sub    %esi,%eax

	      d1 = (d1 << bm) | (d0 >> b);
f01017b7:	89 ea                	mov    %ebp,%edx
f01017b9:	88 c1                	mov    %al,%cl
f01017bb:	d3 ea                	shr    %cl,%edx
f01017bd:	8b 4c 24 0c          	mov    0xc(%esp),%ecx
f01017c1:	09 ca                	or     %ecx,%edx
f01017c3:	89 54 24 08          	mov    %edx,0x8(%esp)
	      d0 = d0 << bm;
f01017c7:	89 f1                	mov    %esi,%ecx
f01017c9:	d3 e5                	shl    %cl,%ebp
f01017cb:	89 6c 24 0c          	mov    %ebp,0xc(%esp)
	      n2 = n1 >> b;
f01017cf:	89 fd                	mov    %edi,%ebp
f01017d1:	88 c1                	mov    %al,%cl
f01017d3:	d3 ed                	shr    %cl,%ebp
	      n1 = (n1 << bm) | (n0 >> b);
f01017d5:	89 fa                	mov    %edi,%edx
f01017d7:	89 f1                	mov    %esi,%ecx
f01017d9:	d3 e2                	shl    %cl,%edx
f01017db:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01017df:	88 c1                	mov    %al,%cl
f01017e1:	d3 ef                	shr    %cl,%edi
f01017e3:	09 d7                	or     %edx,%edi
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
f01017e5:	89 f8                	mov    %edi,%eax
f01017e7:	89 ea                	mov    %ebp,%edx
f01017e9:	f7 74 24 08          	divl   0x8(%esp)
f01017ed:	89 d1                	mov    %edx,%ecx
f01017ef:	89 c7                	mov    %eax,%edi
	      umul_ppmm (m1, m0, q0, d0);
f01017f1:	f7 64 24 0c          	mull   0xc(%esp)

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f01017f5:	39 d1                	cmp    %edx,%ecx
f01017f7:	72 17                	jb     f0101810 <__udivdi3+0x10c>
f01017f9:	74 09                	je     f0101804 <__udivdi3+0x100>
f01017fb:	89 fe                	mov    %edi,%esi
f01017fd:	31 ff                	xor    %edi,%edi
f01017ff:	e9 41 ff ff ff       	jmp    f0101745 <__udivdi3+0x41>

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
	      n0 = n0 << bm;
f0101804:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101808:	89 f1                	mov    %esi,%ecx
f010180a:	d3 e2                	shl    %cl,%edx

	      udiv_qrnnd (q0, n1, n2, n1, d1);
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f010180c:	39 c2                	cmp    %eax,%edx
f010180e:	73 eb                	jae    f01017fb <__udivdi3+0xf7>
		{
		  q0--;
f0101810:	8d 77 ff             	lea    -0x1(%edi),%esi
		  sub_ddmmss (m1, m0, m1, m0, d1, d0);
f0101813:	31 ff                	xor    %edi,%edi
f0101815:	e9 2b ff ff ff       	jmp    f0101745 <__udivdi3+0x41>
f010181a:	66 90                	xchg   %ax,%ax

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f010181c:	31 f6                	xor    %esi,%esi
f010181e:	e9 22 ff ff ff       	jmp    f0101745 <__udivdi3+0x41>
	...

f0101824 <__umoddi3>:
#endif

#ifdef L_umoddi3
UDWtype
__umoddi3 (UDWtype u, UDWtype v)
{
f0101824:	55                   	push   %ebp
f0101825:	57                   	push   %edi
f0101826:	56                   	push   %esi
f0101827:	83 ec 20             	sub    $0x20,%esp
f010182a:	8b 44 24 30          	mov    0x30(%esp),%eax
f010182e:	8b 4c 24 38          	mov    0x38(%esp),%ecx
static inline __attribute__ ((__always_inline__))
#endif
UDWtype
__udivmoddi4 (UDWtype n, UDWtype d, UDWtype *rp)
{
  const DWunion nn = {.ll = n};
f0101832:	89 44 24 14          	mov    %eax,0x14(%esp)
f0101836:	8b 74 24 34          	mov    0x34(%esp),%esi
  const DWunion dd = {.ll = d};
f010183a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010183e:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
  UWtype q0, q1;
  UWtype b, bm;

  d0 = dd.s.low;
  d1 = dd.s.high;
  n0 = nn.s.low;
f0101842:	89 c7                	mov    %eax,%edi
  n1 = nn.s.high;
f0101844:	89 f2                	mov    %esi,%edx

#if !UDIV_NEEDS_NORMALIZATION
  if (d1 == 0)
f0101846:	85 ed                	test   %ebp,%ebp
f0101848:	75 16                	jne    f0101860 <__umoddi3+0x3c>
    {
      if (d0 > n1)
f010184a:	39 f1                	cmp    %esi,%ecx
f010184c:	0f 86 a6 00 00 00    	jbe    f01018f8 <__umoddi3+0xd4>

	  if (d0 == 0)
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */

	  udiv_qrnnd (q1, n1, 0, n1, d0);
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f0101852:	f7 f1                	div    %ecx

      if (rp != 0)
	{
	  rr.s.low = n0;
	  rr.s.high = 0;
	  *rp = rr.ll;
f0101854:	89 d0                	mov    %edx,%eax
f0101856:	31 d2                	xor    %edx,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0101858:	83 c4 20             	add    $0x20,%esp
f010185b:	5e                   	pop    %esi
f010185c:	5f                   	pop    %edi
f010185d:	5d                   	pop    %ebp
f010185e:	c3                   	ret    
f010185f:	90                   	nop
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f0101860:	39 f5                	cmp    %esi,%ebp
f0101862:	0f 87 ac 00 00 00    	ja     f0101914 <__umoddi3+0xf0>
	}
      else
	{
	  /* 0q = NN / dd */

	  count_leading_zeros (bm, d1);
f0101868:	0f bd c5             	bsr    %ebp,%eax
	  if (bm == 0)
f010186b:	83 f0 1f             	xor    $0x1f,%eax
f010186e:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101872:	0f 84 a8 00 00 00    	je     f0101920 <__umoddi3+0xfc>
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
f0101878:	8a 4c 24 10          	mov    0x10(%esp),%cl
f010187c:	d3 e5                	shl    %cl,%ebp
	  else
	    {
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;
f010187e:	bf 20 00 00 00       	mov    $0x20,%edi
f0101883:	2b 7c 24 10          	sub    0x10(%esp),%edi

	      d1 = (d1 << bm) | (d0 >> b);
f0101887:	8b 44 24 0c          	mov    0xc(%esp),%eax
f010188b:	89 f9                	mov    %edi,%ecx
f010188d:	d3 e8                	shr    %cl,%eax
f010188f:	09 e8                	or     %ebp,%eax
f0101891:	89 44 24 18          	mov    %eax,0x18(%esp)
	      d0 = d0 << bm;
f0101895:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101899:	8a 4c 24 10          	mov    0x10(%esp),%cl
f010189d:	d3 e0                	shl    %cl,%eax
f010189f:	89 44 24 0c          	mov    %eax,0xc(%esp)
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
f01018a3:	89 f2                	mov    %esi,%edx
f01018a5:	d3 e2                	shl    %cl,%edx
	      n0 = n0 << bm;
f01018a7:	8b 44 24 14          	mov    0x14(%esp),%eax
f01018ab:	d3 e0                	shl    %cl,%eax
f01018ad:	89 44 24 1c          	mov    %eax,0x1c(%esp)
	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
f01018b1:	8b 44 24 14          	mov    0x14(%esp),%eax
f01018b5:	89 f9                	mov    %edi,%ecx
f01018b7:	d3 e8                	shr    %cl,%eax
f01018b9:	09 d0                	or     %edx,%eax

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
f01018bb:	d3 ee                	shr    %cl,%esi
	      n1 = (n1 << bm) | (n0 >> b);
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
f01018bd:	89 f2                	mov    %esi,%edx
f01018bf:	f7 74 24 18          	divl   0x18(%esp)
f01018c3:	89 d6                	mov    %edx,%esi
	      umul_ppmm (m1, m0, q0, d0);
f01018c5:	f7 64 24 0c          	mull   0xc(%esp)
f01018c9:	89 c5                	mov    %eax,%ebp
f01018cb:	89 d1                	mov    %edx,%ecx

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f01018cd:	39 d6                	cmp    %edx,%esi
f01018cf:	72 67                	jb     f0101938 <__umoddi3+0x114>
f01018d1:	74 75                	je     f0101948 <__umoddi3+0x124>
	      q1 = 0;

	      /* Remainder in (n1n0 - m1m0) >> bm.  */
	      if (rp != 0)
		{
		  sub_ddmmss (n1, n0, n1, n0, m1, m0);
f01018d3:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01018d7:	29 e8                	sub    %ebp,%eax
f01018d9:	19 ce                	sbb    %ecx,%esi
		  rr.s.low = (n1 << b) | (n0 >> bm);
f01018db:	8a 4c 24 10          	mov    0x10(%esp),%cl
f01018df:	d3 e8                	shr    %cl,%eax
f01018e1:	89 f2                	mov    %esi,%edx
f01018e3:	89 f9                	mov    %edi,%ecx
f01018e5:	d3 e2                	shl    %cl,%edx
		  rr.s.high = n1 >> bm;
		  *rp = rr.ll;
f01018e7:	09 d0                	or     %edx,%eax
f01018e9:	89 f2                	mov    %esi,%edx
f01018eb:	8a 4c 24 10          	mov    0x10(%esp),%cl
f01018ef:	d3 ea                	shr    %cl,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f01018f1:	83 c4 20             	add    $0x20,%esp
f01018f4:	5e                   	pop    %esi
f01018f5:	5f                   	pop    %edi
f01018f6:	5d                   	pop    %ebp
f01018f7:	c3                   	ret    
	}
      else
	{
	  /* qq = NN / 0d */

	  if (d0 == 0)
f01018f8:	85 c9                	test   %ecx,%ecx
f01018fa:	75 0b                	jne    f0101907 <__umoddi3+0xe3>
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */
f01018fc:	b8 01 00 00 00       	mov    $0x1,%eax
f0101901:	31 d2                	xor    %edx,%edx
f0101903:	f7 f1                	div    %ecx
f0101905:	89 c1                	mov    %eax,%ecx

	  udiv_qrnnd (q1, n1, 0, n1, d0);
f0101907:	89 f0                	mov    %esi,%eax
f0101909:	31 d2                	xor    %edx,%edx
f010190b:	f7 f1                	div    %ecx
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f010190d:	89 f8                	mov    %edi,%eax
f010190f:	e9 3e ff ff ff       	jmp    f0101852 <__umoddi3+0x2e>
	  /* Remainder in n1n0.  */
	  if (rp != 0)
	    {
	      rr.s.low = n0;
	      rr.s.high = n1;
	      *rp = rr.ll;
f0101914:	89 f2                	mov    %esi,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0101916:	83 c4 20             	add    $0x20,%esp
f0101919:	5e                   	pop    %esi
f010191a:	5f                   	pop    %edi
f010191b:	5d                   	pop    %ebp
f010191c:	c3                   	ret    
f010191d:	8d 76 00             	lea    0x0(%esi),%esi

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0101920:	39 f5                	cmp    %esi,%ebp
f0101922:	72 04                	jb     f0101928 <__umoddi3+0x104>
f0101924:	39 f9                	cmp    %edi,%ecx
f0101926:	77 06                	ja     f010192e <__umoddi3+0x10a>
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f0101928:	89 f2                	mov    %esi,%edx
f010192a:	29 cf                	sub    %ecx,%edi
f010192c:	19 ea                	sbb    %ebp,%edx

	      if (rp != 0)
		{
		  rr.s.low = n0;
		  rr.s.high = n1;
		  *rp = rr.ll;
f010192e:	89 f8                	mov    %edi,%eax
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0101930:	83 c4 20             	add    $0x20,%esp
f0101933:	5e                   	pop    %esi
f0101934:	5f                   	pop    %edi
f0101935:	5d                   	pop    %ebp
f0101936:	c3                   	ret    
f0101937:	90                   	nop
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
		{
		  q0--;
		  sub_ddmmss (m1, m0, m1, m0, d1, d0);
f0101938:	89 d1                	mov    %edx,%ecx
f010193a:	89 c5                	mov    %eax,%ebp
f010193c:	2b 6c 24 0c          	sub    0xc(%esp),%ebp
f0101940:	1b 4c 24 18          	sbb    0x18(%esp),%ecx
f0101944:	eb 8d                	jmp    f01018d3 <__umoddi3+0xaf>
f0101946:	66 90                	xchg   %ax,%ax
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0101948:	39 44 24 1c          	cmp    %eax,0x1c(%esp)
f010194c:	72 ea                	jb     f0101938 <__umoddi3+0x114>
f010194e:	89 f1                	mov    %esi,%ecx
f0101950:	eb 81                	jmp    f01018d3 <__umoddi3+0xaf>
