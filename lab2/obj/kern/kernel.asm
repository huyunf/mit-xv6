
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
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 50 a9 11 f0       	mov    $0xf011a950,%eax
f010004b:	2d 00 a3 11 f0       	sub    $0xf011a300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 a3 11 f0 	movl   $0xf011a300,(%esp)
f0100063:	e8 22 15 00 00       	call   f010158a <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 70 04 00 00       	call   f01004dd <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 e0 19 10 f0 	movl   $0xf01019e0,(%esp)
f010007c:	e8 65 0a 00 00       	call   f0100ae6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 d7 08 00 00       	call   f010095d <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 6a 07 00 00       	call   f01007fc <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 40 a9 11 f0 00 	cmpl   $0x0,0xf011a940
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 40 a9 11 f0    	mov    %esi,0xf011a940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 fb 19 10 f0 	movl   $0xf01019fb,(%esp)
f01000c8:	e8 19 0a 00 00       	call   f0100ae6 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 da 09 00 00       	call   f0100ab3 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 37 1a 10 f0 	movl   $0xf0101a37,(%esp)
f01000e0:	e8 01 0a 00 00       	call   f0100ae6 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 0b 07 00 00       	call   f01007fc <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 13 1a 10 f0 	movl   $0xf0101a13,(%esp)
f0100112:	e8 cf 09 00 00       	call   f0100ae6 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 8d 09 00 00       	call   f0100ab3 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 37 1a 10 f0 	movl   $0xf0101a37,(%esp)
f010012d:	e8 b4 09 00 00       	call   f0100ae6 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    

f0100138 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100138:	55                   	push   %ebp
f0100139:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010013b:	ba 84 00 00 00       	mov    $0x84,%edx
f0100140:	ec                   	in     (%dx),%al
f0100141:	ec                   	in     (%dx),%al
f0100142:	ec                   	in     (%dx),%al
f0100143:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f0100144:	5d                   	pop    %ebp
f0100145:	c3                   	ret    

f0100146 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100146:	55                   	push   %ebp
f0100147:	89 e5                	mov    %esp,%ebp
f0100149:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010014e:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010014f:	a8 01                	test   $0x1,%al
f0100151:	74 08                	je     f010015b <serial_proc_data+0x15>
f0100153:	b2 f8                	mov    $0xf8,%dl
f0100155:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100156:	0f b6 c0             	movzbl %al,%eax
f0100159:	eb 05                	jmp    f0100160 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010015b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100160:	5d                   	pop    %ebp
f0100161:	c3                   	ret    

f0100162 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100162:	55                   	push   %ebp
f0100163:	89 e5                	mov    %esp,%ebp
f0100165:	53                   	push   %ebx
f0100166:	83 ec 04             	sub    $0x4,%esp
f0100169:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010016b:	eb 29                	jmp    f0100196 <cons_intr+0x34>
		if (c == 0)
f010016d:	85 c0                	test   %eax,%eax
f010016f:	74 25                	je     f0100196 <cons_intr+0x34>
			continue;
		cons.buf[cons.wpos++] = c;
f0100171:	8b 15 24 a5 11 f0    	mov    0xf011a524,%edx
f0100177:	88 82 20 a3 11 f0    	mov    %al,-0xfee5ce0(%edx)
f010017d:	8d 42 01             	lea    0x1(%edx),%eax
f0100180:	a3 24 a5 11 f0       	mov    %eax,0xf011a524
		if (cons.wpos == CONSBUFSIZE)
f0100185:	3d 00 02 00 00       	cmp    $0x200,%eax
f010018a:	75 0a                	jne    f0100196 <cons_intr+0x34>
			cons.wpos = 0;
f010018c:	c7 05 24 a5 11 f0 00 	movl   $0x0,0xf011a524
f0100193:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100196:	ff d3                	call   *%ebx
f0100198:	83 f8 ff             	cmp    $0xffffffff,%eax
f010019b:	75 d0                	jne    f010016d <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019d:	83 c4 04             	add    $0x4,%esp
f01001a0:	5b                   	pop    %ebx
f01001a1:	5d                   	pop    %ebp
f01001a2:	c3                   	ret    

f01001a3 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001a3:	55                   	push   %ebp
f01001a4:	89 e5                	mov    %esp,%ebp
f01001a6:	57                   	push   %edi
f01001a7:	56                   	push   %esi
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 2c             	sub    $0x2c,%esp
f01001ac:	89 c6                	mov    %eax,%esi
f01001ae:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01001b3:	bf fd 03 00 00       	mov    $0x3fd,%edi
f01001b8:	eb 05                	jmp    f01001bf <cons_putc+0x1c>
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001ba:	e8 79 ff ff ff       	call   f0100138 <delay>
f01001bf:	89 fa                	mov    %edi,%edx
f01001c1:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001c2:	a8 20                	test   $0x20,%al
f01001c4:	75 03                	jne    f01001c9 <cons_putc+0x26>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001c6:	4b                   	dec    %ebx
f01001c7:	75 f1                	jne    f01001ba <cons_putc+0x17>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001c9:	89 f2                	mov    %esi,%edx
f01001cb:	89 f0                	mov    %esi,%eax
f01001cd:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001d5:	ee                   	out    %al,(%dx)
f01001d6:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001db:	bf 79 03 00 00       	mov    $0x379,%edi
f01001e0:	eb 05                	jmp    f01001e7 <cons_putc+0x44>
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
		delay();
f01001e2:	e8 51 ff ff ff       	call   f0100138 <delay>
f01001e7:	89 fa                	mov    %edi,%edx
f01001e9:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001ea:	84 c0                	test   %al,%al
f01001ec:	78 03                	js     f01001f1 <cons_putc+0x4e>
f01001ee:	4b                   	dec    %ebx
f01001ef:	75 f1                	jne    f01001e2 <cons_putc+0x3f>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001f1:	ba 78 03 00 00       	mov    $0x378,%edx
f01001f6:	8a 45 e7             	mov    -0x19(%ebp),%al
f01001f9:	ee                   	out    %al,(%dx)
f01001fa:	b2 7a                	mov    $0x7a,%dl
f01001fc:	b0 0d                	mov    $0xd,%al
f01001fe:	ee                   	out    %al,(%dx)
f01001ff:	b0 08                	mov    $0x8,%al
f0100201:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100202:	f7 c6 00 ff ff ff    	test   $0xffffff00,%esi
f0100208:	75 06                	jne    f0100210 <cons_putc+0x6d>
		c |= 0x0700;
f010020a:	81 ce 00 07 00 00    	or     $0x700,%esi

	switch (c & 0xff) {
f0100210:	89 f0                	mov    %esi,%eax
f0100212:	25 ff 00 00 00       	and    $0xff,%eax
f0100217:	83 f8 09             	cmp    $0x9,%eax
f010021a:	74 78                	je     f0100294 <cons_putc+0xf1>
f010021c:	83 f8 09             	cmp    $0x9,%eax
f010021f:	7f 0b                	jg     f010022c <cons_putc+0x89>
f0100221:	83 f8 08             	cmp    $0x8,%eax
f0100224:	0f 85 9e 00 00 00    	jne    f01002c8 <cons_putc+0x125>
f010022a:	eb 10                	jmp    f010023c <cons_putc+0x99>
f010022c:	83 f8 0a             	cmp    $0xa,%eax
f010022f:	74 39                	je     f010026a <cons_putc+0xc7>
f0100231:	83 f8 0d             	cmp    $0xd,%eax
f0100234:	0f 85 8e 00 00 00    	jne    f01002c8 <cons_putc+0x125>
f010023a:	eb 36                	jmp    f0100272 <cons_putc+0xcf>
	case '\b':
		if (crt_pos > 0) {
f010023c:	66 a1 34 a5 11 f0    	mov    0xf011a534,%ax
f0100242:	66 85 c0             	test   %ax,%ax
f0100245:	0f 84 e2 00 00 00    	je     f010032d <cons_putc+0x18a>
			crt_pos--;
f010024b:	48                   	dec    %eax
f010024c:	66 a3 34 a5 11 f0    	mov    %ax,0xf011a534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100252:	0f b7 c0             	movzwl %ax,%eax
f0100255:	81 e6 00 ff ff ff    	and    $0xffffff00,%esi
f010025b:	83 ce 20             	or     $0x20,%esi
f010025e:	8b 15 30 a5 11 f0    	mov    0xf011a530,%edx
f0100264:	66 89 34 42          	mov    %si,(%edx,%eax,2)
f0100268:	eb 78                	jmp    f01002e2 <cons_putc+0x13f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010026a:	66 83 05 34 a5 11 f0 	addw   $0x50,0xf011a534
f0100271:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100272:	66 8b 0d 34 a5 11 f0 	mov    0xf011a534,%cx
f0100279:	bb 50 00 00 00       	mov    $0x50,%ebx
f010027e:	89 c8                	mov    %ecx,%eax
f0100280:	ba 00 00 00 00       	mov    $0x0,%edx
f0100285:	66 f7 f3             	div    %bx
f0100288:	66 29 d1             	sub    %dx,%cx
f010028b:	66 89 0d 34 a5 11 f0 	mov    %cx,0xf011a534
f0100292:	eb 4e                	jmp    f01002e2 <cons_putc+0x13f>
		break;
	case '\t':
		cons_putc(' ');
f0100294:	b8 20 00 00 00       	mov    $0x20,%eax
f0100299:	e8 05 ff ff ff       	call   f01001a3 <cons_putc>
		cons_putc(' ');
f010029e:	b8 20 00 00 00       	mov    $0x20,%eax
f01002a3:	e8 fb fe ff ff       	call   f01001a3 <cons_putc>
		cons_putc(' ');
f01002a8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002ad:	e8 f1 fe ff ff       	call   f01001a3 <cons_putc>
		cons_putc(' ');
f01002b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01002b7:	e8 e7 fe ff ff       	call   f01001a3 <cons_putc>
		cons_putc(' ');
f01002bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c1:	e8 dd fe ff ff       	call   f01001a3 <cons_putc>
f01002c6:	eb 1a                	jmp    f01002e2 <cons_putc+0x13f>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002c8:	66 a1 34 a5 11 f0    	mov    0xf011a534,%ax
f01002ce:	0f b7 c8             	movzwl %ax,%ecx
f01002d1:	8b 15 30 a5 11 f0    	mov    0xf011a530,%edx
f01002d7:	66 89 34 4a          	mov    %si,(%edx,%ecx,2)
f01002db:	40                   	inc    %eax
f01002dc:	66 a3 34 a5 11 f0    	mov    %ax,0xf011a534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01002e2:	66 81 3d 34 a5 11 f0 	cmpw   $0x7cf,0xf011a534
f01002e9:	cf 07 
f01002eb:	76 40                	jbe    f010032d <cons_putc+0x18a>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01002ed:	a1 30 a5 11 f0       	mov    0xf011a530,%eax
f01002f2:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01002f9:	00 
f01002fa:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100300:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100304:	89 04 24             	mov    %eax,(%esp)
f0100307:	e8 c8 12 00 00       	call   f01015d4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010030c:	8b 15 30 a5 11 f0    	mov    0xf011a530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100312:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100317:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010031d:	40                   	inc    %eax
f010031e:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100323:	75 f2                	jne    f0100317 <cons_putc+0x174>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100325:	66 83 2d 34 a5 11 f0 	subw   $0x50,0xf011a534
f010032c:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010032d:	8b 0d 2c a5 11 f0    	mov    0xf011a52c,%ecx
f0100333:	b0 0e                	mov    $0xe,%al
f0100335:	89 ca                	mov    %ecx,%edx
f0100337:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100338:	66 8b 35 34 a5 11 f0 	mov    0xf011a534,%si
f010033f:	8d 59 01             	lea    0x1(%ecx),%ebx
f0100342:	89 f0                	mov    %esi,%eax
f0100344:	66 c1 e8 08          	shr    $0x8,%ax
f0100348:	89 da                	mov    %ebx,%edx
f010034a:	ee                   	out    %al,(%dx)
f010034b:	b0 0f                	mov    $0xf,%al
f010034d:	89 ca                	mov    %ecx,%edx
f010034f:	ee                   	out    %al,(%dx)
f0100350:	89 f0                	mov    %esi,%eax
f0100352:	89 da                	mov    %ebx,%edx
f0100354:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100355:	83 c4 2c             	add    $0x2c,%esp
f0100358:	5b                   	pop    %ebx
f0100359:	5e                   	pop    %esi
f010035a:	5f                   	pop    %edi
f010035b:	5d                   	pop    %ebp
f010035c:	c3                   	ret    

f010035d <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010035d:	55                   	push   %ebp
f010035e:	89 e5                	mov    %esp,%ebp
f0100360:	53                   	push   %ebx
f0100361:	83 ec 14             	sub    $0x14,%esp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100364:	ba 64 00 00 00       	mov    $0x64,%edx
f0100369:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f010036a:	0f b6 c0             	movzbl %al,%eax
f010036d:	a8 01                	test   $0x1,%al
f010036f:	0f 84 e0 00 00 00    	je     f0100455 <kbd_proc_data+0xf8>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f0100375:	a8 20                	test   $0x20,%al
f0100377:	0f 85 df 00 00 00    	jne    f010045c <kbd_proc_data+0xff>
f010037d:	b2 60                	mov    $0x60,%dl
f010037f:	ec                   	in     (%dx),%al
f0100380:	88 c2                	mov    %al,%dl
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100382:	3c e0                	cmp    $0xe0,%al
f0100384:	75 11                	jne    f0100397 <kbd_proc_data+0x3a>
		// E0 escape character
		shift |= E0ESC;
f0100386:	83 0d 28 a5 11 f0 40 	orl    $0x40,0xf011a528
		return 0;
f010038d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100392:	e9 ca 00 00 00       	jmp    f0100461 <kbd_proc_data+0x104>
	} else if (data & 0x80) {
f0100397:	84 c0                	test   %al,%al
f0100399:	79 33                	jns    f01003ce <kbd_proc_data+0x71>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010039b:	8b 0d 28 a5 11 f0    	mov    0xf011a528,%ecx
f01003a1:	f6 c1 40             	test   $0x40,%cl
f01003a4:	75 05                	jne    f01003ab <kbd_proc_data+0x4e>
f01003a6:	88 c2                	mov    %al,%dl
f01003a8:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003ab:	0f b6 d2             	movzbl %dl,%edx
f01003ae:	8a 82 60 1a 10 f0    	mov    -0xfefe5a0(%edx),%al
f01003b4:	83 c8 40             	or     $0x40,%eax
f01003b7:	0f b6 c0             	movzbl %al,%eax
f01003ba:	f7 d0                	not    %eax
f01003bc:	21 c1                	and    %eax,%ecx
f01003be:	89 0d 28 a5 11 f0    	mov    %ecx,0xf011a528
		return 0;
f01003c4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003c9:	e9 93 00 00 00       	jmp    f0100461 <kbd_proc_data+0x104>
	} else if (shift & E0ESC) {
f01003ce:	8b 0d 28 a5 11 f0    	mov    0xf011a528,%ecx
f01003d4:	f6 c1 40             	test   $0x40,%cl
f01003d7:	74 0e                	je     f01003e7 <kbd_proc_data+0x8a>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01003d9:	88 c2                	mov    %al,%dl
f01003db:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01003de:	83 e1 bf             	and    $0xffffffbf,%ecx
f01003e1:	89 0d 28 a5 11 f0    	mov    %ecx,0xf011a528
	}

	shift |= shiftcode[data];
f01003e7:	0f b6 d2             	movzbl %dl,%edx
f01003ea:	0f b6 82 60 1a 10 f0 	movzbl -0xfefe5a0(%edx),%eax
f01003f1:	0b 05 28 a5 11 f0    	or     0xf011a528,%eax
	shift ^= togglecode[data];
f01003f7:	0f b6 8a 60 1b 10 f0 	movzbl -0xfefe4a0(%edx),%ecx
f01003fe:	31 c8                	xor    %ecx,%eax
f0100400:	a3 28 a5 11 f0       	mov    %eax,0xf011a528

	c = charcode[shift & (CTL | SHIFT)][data];
f0100405:	89 c1                	mov    %eax,%ecx
f0100407:	83 e1 03             	and    $0x3,%ecx
f010040a:	8b 0c 8d 60 1c 10 f0 	mov    -0xfefe3a0(,%ecx,4),%ecx
f0100411:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100415:	a8 08                	test   $0x8,%al
f0100417:	74 18                	je     f0100431 <kbd_proc_data+0xd4>
		if ('a' <= c && c <= 'z')
f0100419:	8d 53 9f             	lea    -0x61(%ebx),%edx
f010041c:	83 fa 19             	cmp    $0x19,%edx
f010041f:	77 05                	ja     f0100426 <kbd_proc_data+0xc9>
			c += 'A' - 'a';
f0100421:	83 eb 20             	sub    $0x20,%ebx
f0100424:	eb 0b                	jmp    f0100431 <kbd_proc_data+0xd4>
		else if ('A' <= c && c <= 'Z')
f0100426:	8d 53 bf             	lea    -0x41(%ebx),%edx
f0100429:	83 fa 19             	cmp    $0x19,%edx
f010042c:	77 03                	ja     f0100431 <kbd_proc_data+0xd4>
			c += 'a' - 'A';
f010042e:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100431:	f7 d0                	not    %eax
f0100433:	a8 06                	test   $0x6,%al
f0100435:	75 2a                	jne    f0100461 <kbd_proc_data+0x104>
f0100437:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010043d:	75 22                	jne    f0100461 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010043f:	c7 04 24 2d 1a 10 f0 	movl   $0xf0101a2d,(%esp)
f0100446:	e8 9b 06 00 00       	call   f0100ae6 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010044b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100450:	b0 03                	mov    $0x3,%al
f0100452:	ee                   	out    %al,(%dx)
f0100453:	eb 0c                	jmp    f0100461 <kbd_proc_data+0x104>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100455:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010045a:	eb 05                	jmp    f0100461 <kbd_proc_data+0x104>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010045c:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100461:	89 d8                	mov    %ebx,%eax
f0100463:	83 c4 14             	add    $0x14,%esp
f0100466:	5b                   	pop    %ebx
f0100467:	5d                   	pop    %ebp
f0100468:	c3                   	ret    

f0100469 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100469:	55                   	push   %ebp
f010046a:	89 e5                	mov    %esp,%ebp
f010046c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f010046f:	80 3d 00 a3 11 f0 00 	cmpb   $0x0,0xf011a300
f0100476:	74 0a                	je     f0100482 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100478:	b8 46 01 10 f0       	mov    $0xf0100146,%eax
f010047d:	e8 e0 fc ff ff       	call   f0100162 <cons_intr>
}
f0100482:	c9                   	leave  
f0100483:	c3                   	ret    

f0100484 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100484:	55                   	push   %ebp
f0100485:	89 e5                	mov    %esp,%ebp
f0100487:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010048a:	b8 5d 03 10 f0       	mov    $0xf010035d,%eax
f010048f:	e8 ce fc ff ff       	call   f0100162 <cons_intr>
}
f0100494:	c9                   	leave  
f0100495:	c3                   	ret    

f0100496 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100496:	55                   	push   %ebp
f0100497:	89 e5                	mov    %esp,%ebp
f0100499:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010049c:	e8 c8 ff ff ff       	call   f0100469 <serial_intr>
	kbd_intr();
f01004a1:	e8 de ff ff ff       	call   f0100484 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004a6:	8b 15 20 a5 11 f0    	mov    0xf011a520,%edx
f01004ac:	3b 15 24 a5 11 f0    	cmp    0xf011a524,%edx
f01004b2:	74 22                	je     f01004d6 <cons_getc+0x40>
		c = cons.buf[cons.rpos++];
f01004b4:	0f b6 82 20 a3 11 f0 	movzbl -0xfee5ce0(%edx),%eax
f01004bb:	42                   	inc    %edx
f01004bc:	89 15 20 a5 11 f0    	mov    %edx,0xf011a520
		if (cons.rpos == CONSBUFSIZE)
f01004c2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004c8:	75 11                	jne    f01004db <cons_getc+0x45>
			cons.rpos = 0;
f01004ca:	c7 05 20 a5 11 f0 00 	movl   $0x0,0xf011a520
f01004d1:	00 00 00 
f01004d4:	eb 05                	jmp    f01004db <cons_getc+0x45>
		return c;
	}
	return 0;
f01004d6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004db:	c9                   	leave  
f01004dc:	c3                   	ret    

f01004dd <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004dd:	55                   	push   %ebp
f01004de:	89 e5                	mov    %esp,%ebp
f01004e0:	57                   	push   %edi
f01004e1:	56                   	push   %esi
f01004e2:	53                   	push   %ebx
f01004e3:	83 ec 2c             	sub    $0x2c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004e6:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f01004ed:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01004f4:	5a a5 
	if (*cp != 0xA55A) {
f01004f6:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f01004fc:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100500:	74 11                	je     f0100513 <cons_init+0x36>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100502:	c7 05 2c a5 11 f0 b4 	movl   $0x3b4,0xf011a52c
f0100509:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010050c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100511:	eb 16                	jmp    f0100529 <cons_init+0x4c>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100513:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010051a:	c7 05 2c a5 11 f0 d4 	movl   $0x3d4,0xf011a52c
f0100521:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100524:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100529:	8b 0d 2c a5 11 f0    	mov    0xf011a52c,%ecx
f010052f:	b0 0e                	mov    $0xe,%al
f0100531:	89 ca                	mov    %ecx,%edx
f0100533:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100534:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100537:	89 da                	mov    %ebx,%edx
f0100539:	ec                   	in     (%dx),%al
f010053a:	0f b6 f8             	movzbl %al,%edi
f010053d:	c1 e7 08             	shl    $0x8,%edi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100540:	b0 0f                	mov    $0xf,%al
f0100542:	89 ca                	mov    %ecx,%edx
f0100544:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100545:	89 da                	mov    %ebx,%edx
f0100547:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100548:	89 35 30 a5 11 f0    	mov    %esi,0xf011a530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010054e:	0f b6 d8             	movzbl %al,%ebx
f0100551:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100553:	66 89 3d 34 a5 11 f0 	mov    %di,0xf011a534
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055a:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010055f:	b0 00                	mov    $0x0,%al
f0100561:	89 da                	mov    %ebx,%edx
f0100563:	ee                   	out    %al,(%dx)
f0100564:	b2 fb                	mov    $0xfb,%dl
f0100566:	b0 80                	mov    $0x80,%al
f0100568:	ee                   	out    %al,(%dx)
f0100569:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f010056e:	b0 0c                	mov    $0xc,%al
f0100570:	89 ca                	mov    %ecx,%edx
f0100572:	ee                   	out    %al,(%dx)
f0100573:	b2 f9                	mov    $0xf9,%dl
f0100575:	b0 00                	mov    $0x0,%al
f0100577:	ee                   	out    %al,(%dx)
f0100578:	b2 fb                	mov    $0xfb,%dl
f010057a:	b0 03                	mov    $0x3,%al
f010057c:	ee                   	out    %al,(%dx)
f010057d:	b2 fc                	mov    $0xfc,%dl
f010057f:	b0 00                	mov    $0x0,%al
f0100581:	ee                   	out    %al,(%dx)
f0100582:	b2 f9                	mov    $0xf9,%dl
f0100584:	b0 01                	mov    $0x1,%al
f0100586:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100587:	b2 fd                	mov    $0xfd,%dl
f0100589:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010058a:	3c ff                	cmp    $0xff,%al
f010058c:	0f 95 45 e7          	setne  -0x19(%ebp)
f0100590:	8a 45 e7             	mov    -0x19(%ebp),%al
f0100593:	a2 00 a3 11 f0       	mov    %al,0xf011a300
f0100598:	89 da                	mov    %ebx,%edx
f010059a:	ec                   	in     (%dx),%al
f010059b:	89 ca                	mov    %ecx,%edx
f010059d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010059e:	80 7d e7 00          	cmpb   $0x0,-0x19(%ebp)
f01005a2:	75 0c                	jne    f01005b0 <cons_init+0xd3>
		cprintf("Serial port does not exist!\n");
f01005a4:	c7 04 24 39 1a 10 f0 	movl   $0xf0101a39,(%esp)
f01005ab:	e8 36 05 00 00       	call   f0100ae6 <cprintf>
}
f01005b0:	83 c4 2c             	add    $0x2c,%esp
f01005b3:	5b                   	pop    %ebx
f01005b4:	5e                   	pop    %esi
f01005b5:	5f                   	pop    %edi
f01005b6:	5d                   	pop    %ebp
f01005b7:	c3                   	ret    

f01005b8 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005b8:	55                   	push   %ebp
f01005b9:	89 e5                	mov    %esp,%ebp
f01005bb:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005be:	8b 45 08             	mov    0x8(%ebp),%eax
f01005c1:	e8 dd fb ff ff       	call   f01001a3 <cons_putc>
}
f01005c6:	c9                   	leave  
f01005c7:	c3                   	ret    

f01005c8 <getchar>:

int
getchar(void)
{
f01005c8:	55                   	push   %ebp
f01005c9:	89 e5                	mov    %esp,%ebp
f01005cb:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01005ce:	e8 c3 fe ff ff       	call   f0100496 <cons_getc>
f01005d3:	85 c0                	test   %eax,%eax
f01005d5:	74 f7                	je     f01005ce <getchar+0x6>
		/* do nothing */;
	return c;
}
f01005d7:	c9                   	leave  
f01005d8:	c3                   	ret    

f01005d9 <iscons>:

int
iscons(int fdnum)
{
f01005d9:	55                   	push   %ebp
f01005da:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01005dc:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e1:	5d                   	pop    %ebp
f01005e2:	c3                   	ret    
	...

f01005e4 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01005e4:	55                   	push   %ebp
f01005e5:	89 e5                	mov    %esp,%ebp
f01005e7:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01005ea:	c7 04 24 70 1c 10 f0 	movl   $0xf0101c70,(%esp)
f01005f1:	e8 f0 04 00 00       	call   f0100ae6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01005f6:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01005fd:	00 
f01005fe:	c7 04 24 54 1d 10 f0 	movl   $0xf0101d54,(%esp)
f0100605:	e8 dc 04 00 00       	call   f0100ae6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010060a:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100611:	00 
f0100612:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100619:	f0 
f010061a:	c7 04 24 7c 1d 10 f0 	movl   $0xf0101d7c,(%esp)
f0100621:	e8 c0 04 00 00       	call   f0100ae6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100626:	c7 44 24 08 ce 19 10 	movl   $0x1019ce,0x8(%esp)
f010062d:	00 
f010062e:	c7 44 24 04 ce 19 10 	movl   $0xf01019ce,0x4(%esp)
f0100635:	f0 
f0100636:	c7 04 24 a0 1d 10 f0 	movl   $0xf0101da0,(%esp)
f010063d:	e8 a4 04 00 00       	call   f0100ae6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100642:	c7 44 24 08 00 a3 11 	movl   $0x11a300,0x8(%esp)
f0100649:	00 
f010064a:	c7 44 24 04 00 a3 11 	movl   $0xf011a300,0x4(%esp)
f0100651:	f0 
f0100652:	c7 04 24 c4 1d 10 f0 	movl   $0xf0101dc4,(%esp)
f0100659:	e8 88 04 00 00       	call   f0100ae6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010065e:	c7 44 24 08 50 a9 11 	movl   $0x11a950,0x8(%esp)
f0100665:	00 
f0100666:	c7 44 24 04 50 a9 11 	movl   $0xf011a950,0x4(%esp)
f010066d:	f0 
f010066e:	c7 04 24 e8 1d 10 f0 	movl   $0xf0101de8,(%esp)
f0100675:	e8 6c 04 00 00       	call   f0100ae6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010067a:	b8 4f ad 11 f0       	mov    $0xf011ad4f,%eax
f010067f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100684:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100689:	89 c2                	mov    %eax,%edx
f010068b:	85 c0                	test   %eax,%eax
f010068d:	79 06                	jns    f0100695 <mon_kerninfo+0xb1>
f010068f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100695:	c1 fa 0a             	sar    $0xa,%edx
f0100698:	89 54 24 04          	mov    %edx,0x4(%esp)
f010069c:	c7 04 24 0c 1e 10 f0 	movl   $0xf0101e0c,(%esp)
f01006a3:	e8 3e 04 00 00       	call   f0100ae6 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ad:	c9                   	leave  
f01006ae:	c3                   	ret    

f01006af <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006af:	55                   	push   %ebp
f01006b0:	89 e5                	mov    %esp,%ebp
f01006b2:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006b5:	c7 44 24 08 89 1c 10 	movl   $0xf0101c89,0x8(%esp)
f01006bc:	f0 
f01006bd:	c7 44 24 04 a7 1c 10 	movl   $0xf0101ca7,0x4(%esp)
f01006c4:	f0 
f01006c5:	c7 04 24 ac 1c 10 f0 	movl   $0xf0101cac,(%esp)
f01006cc:	e8 15 04 00 00       	call   f0100ae6 <cprintf>
f01006d1:	c7 44 24 08 38 1e 10 	movl   $0xf0101e38,0x8(%esp)
f01006d8:	f0 
f01006d9:	c7 44 24 04 b5 1c 10 	movl   $0xf0101cb5,0x4(%esp)
f01006e0:	f0 
f01006e1:	c7 04 24 ac 1c 10 f0 	movl   $0xf0101cac,(%esp)
f01006e8:	e8 f9 03 00 00       	call   f0100ae6 <cprintf>
	return 0;
}
f01006ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f2:	c9                   	leave  
f01006f3:	c3                   	ret    

f01006f4 <mon_backtrace>:
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01006f4:	55                   	push   %ebp
f01006f5:	89 e5                	mov    %esp,%ebp
f01006f7:	57                   	push   %edi
f01006f8:	56                   	push   %esi
f01006f9:	53                   	push   %ebx
f01006fa:	81 ec bc 00 00 00    	sub    $0xbc,%esp
	// Your code here.
    uint8_t i;
    uint32_t* ebp = (uint32_t*) read_ebp();
f0100700:	89 ee                	mov    %ebp,%esi
    uintptr_t eip = 0;
    struct Eipdebuginfo info;
    uint8_t fun_name[100]; 

    cprintf("Stack backtrace: %s:%d :%s\n", __FILE__, __LINE__, __FUNCTION__);
f0100702:	c7 44 24 0c c4 1e 10 	movl   $0xf0101ec4,0xc(%esp)
f0100709:	f0 
f010070a:	c7 44 24 08 42 00 00 	movl   $0x42,0x8(%esp)
f0100711:	00 
f0100712:	c7 44 24 04 be 1c 10 	movl   $0xf0101cbe,0x4(%esp)
f0100719:	f0 
f010071a:	c7 04 24 cd 1c 10 f0 	movl   $0xf0101ccd,(%esp)
f0100721:	e8 c0 03 00 00       	call   f0100ae6 <cprintf>

    while (ebp){
f0100726:	e9 b9 00 00 00       	jmp    f01007e4 <mon_backtrace+0xf0>
        // get basic register value
        eip = ebp[1];
f010072b:	8b 46 04             	mov    0x4(%esi),%eax
f010072e:	89 85 64 ff ff ff    	mov    %eax,-0x9c(%ebp)
        cprintf("ebp %08x eip %08x args", ebp, eip);
f0100734:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100738:	89 74 24 04          	mov    %esi,0x4(%esp)
f010073c:	c7 04 24 e9 1c 10 f0 	movl   $0xf0101ce9,(%esp)
f0100743:	e8 9e 03 00 00       	call   f0100ae6 <cprintf>
f0100748:	bb 00 00 00 00       	mov    $0x0,%ebx
        for(i=2; i<=6; ++i)
            cprintf(" %08.x", ebp[i]);
f010074d:	8b 44 1e 08          	mov    0x8(%esi,%ebx,1),%eax
f0100751:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100755:	c7 04 24 00 1d 10 f0 	movl   $0xf0101d00,(%esp)
f010075c:	e8 85 03 00 00       	call   f0100ae6 <cprintf>
f0100761:	83 c3 04             	add    $0x4,%ebx

    while (ebp){
        // get basic register value
        eip = ebp[1];
        cprintf("ebp %08x eip %08x args", ebp, eip);
        for(i=2; i<=6; ++i)
f0100764:	83 fb 14             	cmp    $0x14,%ebx
f0100767:	75 e4                	jne    f010074d <mon_backtrace+0x59>
            cprintf(" %08.x", ebp[i]);
        cprintf("\n");
f0100769:	c7 04 24 37 1a 10 f0 	movl   $0xf0101a37,(%esp)
f0100770:	e8 71 03 00 00       	call   f0100ae6 <cprintf>

        // trace function name from eip
        debuginfo_eip(eip, &info); 
f0100775:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100778:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077c:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
f0100782:	89 04 24             	mov    %eax,(%esp)
f0100785:	e8 56 04 00 00       	call   f0100be0 <debuginfo_eip>
        for(i=0; i<info.eip_fn_namelen; i++)
f010078a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
            fun_name[i] = info.eip_fn_name[i];
f010078d:	8b 7d d8             	mov    -0x28(%ebp),%edi
            cprintf(" %08.x", ebp[i]);
        cprintf("\n");

        // trace function name from eip
        debuginfo_eip(eip, &info); 
        for(i=0; i<info.eip_fn_namelen; i++)
f0100790:	b0 00                	mov    $0x0,%al
f0100792:	eb 0e                	jmp    f01007a2 <mon_backtrace+0xae>
            fun_name[i] = info.eip_fn_name[i];
f0100794:	0f b6 c8             	movzbl %al,%ecx
f0100797:	8a 0c 0f             	mov    (%edi,%ecx,1),%cl
f010079a:	88 8c 15 6c ff ff ff 	mov    %cl,-0x94(%ebp,%edx,1)
            cprintf(" %08.x", ebp[i]);
        cprintf("\n");

        // trace function name from eip
        debuginfo_eip(eip, &info); 
        for(i=0; i<info.eip_fn_namelen; i++)
f01007a1:	40                   	inc    %eax
f01007a2:	0f b6 d0             	movzbl %al,%edx
f01007a5:	39 da                	cmp    %ebx,%edx
f01007a7:	7c eb                	jl     f0100794 <mon_backtrace+0xa0>
            fun_name[i] = info.eip_fn_name[i];
        fun_name[info.eip_fn_namelen] = 0;
f01007a9:	c6 84 1d 6c ff ff ff 	movb   $0x0,-0x94(%ebp,%ebx,1)
f01007b0:	00 
        cprintf("\t%s:%d: %s+%d\n", info.eip_file, info.eip_line, fun_name, eip-info.eip_fn_addr);
f01007b1:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
f01007b7:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007ba:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007be:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f01007c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007cb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007cf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d6:	c7 04 24 07 1d 10 f0 	movl   $0xf0101d07,(%esp)
f01007dd:	e8 04 03 00 00       	call   f0100ae6 <cprintf>

        ebp = (uint32_t*) *ebp;
f01007e2:	8b 36                	mov    (%esi),%esi
    struct Eipdebuginfo info;
    uint8_t fun_name[100]; 

    cprintf("Stack backtrace: %s:%d :%s\n", __FILE__, __LINE__, __FUNCTION__);

    while (ebp){
f01007e4:	85 f6                	test   %esi,%esi
f01007e6:	0f 85 3f ff ff ff    	jne    f010072b <mon_backtrace+0x37>

        ebp = (uint32_t*) *ebp;
    }

	return 0;
}
f01007ec:	b8 00 00 00 00       	mov    $0x0,%eax
f01007f1:	81 c4 bc 00 00 00    	add    $0xbc,%esp
f01007f7:	5b                   	pop    %ebx
f01007f8:	5e                   	pop    %esi
f01007f9:	5f                   	pop    %edi
f01007fa:	5d                   	pop    %ebp
f01007fb:	c3                   	ret    

f01007fc <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007fc:	55                   	push   %ebp
f01007fd:	89 e5                	mov    %esp,%ebp
f01007ff:	57                   	push   %edi
f0100800:	56                   	push   %esi
f0100801:	53                   	push   %ebx
f0100802:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100805:	c7 04 24 60 1e 10 f0 	movl   $0xf0101e60,(%esp)
f010080c:	e8 d5 02 00 00       	call   f0100ae6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100811:	c7 04 24 84 1e 10 f0 	movl   $0xf0101e84,(%esp)
f0100818:	e8 c9 02 00 00       	call   f0100ae6 <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f010081d:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f0100820:	c7 04 24 16 1d 10 f0 	movl   $0xf0101d16,(%esp)
f0100827:	e8 34 0b 00 00       	call   f0101360 <readline>
f010082c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010082e:	85 c0                	test   %eax,%eax
f0100830:	74 ee                	je     f0100820 <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100832:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100839:	be 00 00 00 00       	mov    $0x0,%esi
f010083e:	eb 04                	jmp    f0100844 <monitor+0x48>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100840:	c6 03 00             	movb   $0x0,(%ebx)
f0100843:	43                   	inc    %ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100844:	8a 03                	mov    (%ebx),%al
f0100846:	84 c0                	test   %al,%al
f0100848:	74 5e                	je     f01008a8 <monitor+0xac>
f010084a:	0f be c0             	movsbl %al,%eax
f010084d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100851:	c7 04 24 1a 1d 10 f0 	movl   $0xf0101d1a,(%esp)
f0100858:	e8 f8 0c 00 00       	call   f0101555 <strchr>
f010085d:	85 c0                	test   %eax,%eax
f010085f:	75 df                	jne    f0100840 <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f0100861:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100864:	74 42                	je     f01008a8 <monitor+0xac>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100866:	83 fe 0f             	cmp    $0xf,%esi
f0100869:	75 16                	jne    f0100881 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010086b:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100872:	00 
f0100873:	c7 04 24 1f 1d 10 f0 	movl   $0xf0101d1f,(%esp)
f010087a:	e8 67 02 00 00       	call   f0100ae6 <cprintf>
f010087f:	eb 9f                	jmp    f0100820 <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f0100881:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100885:	46                   	inc    %esi
f0100886:	eb 01                	jmp    f0100889 <monitor+0x8d>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100888:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100889:	8a 03                	mov    (%ebx),%al
f010088b:	84 c0                	test   %al,%al
f010088d:	74 b5                	je     f0100844 <monitor+0x48>
f010088f:	0f be c0             	movsbl %al,%eax
f0100892:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100896:	c7 04 24 1a 1d 10 f0 	movl   $0xf0101d1a,(%esp)
f010089d:	e8 b3 0c 00 00       	call   f0101555 <strchr>
f01008a2:	85 c0                	test   %eax,%eax
f01008a4:	74 e2                	je     f0100888 <monitor+0x8c>
f01008a6:	eb 9c                	jmp    f0100844 <monitor+0x48>
			buf++;
	}
	argv[argc] = 0;
f01008a8:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008af:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008b0:	85 f6                	test   %esi,%esi
f01008b2:	0f 84 68 ff ff ff    	je     f0100820 <monitor+0x24>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008b8:	c7 44 24 04 a7 1c 10 	movl   $0xf0101ca7,0x4(%esp)
f01008bf:	f0 
f01008c0:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008c3:	89 04 24             	mov    %eax,(%esp)
f01008c6:	e8 37 0c 00 00       	call   f0101502 <strcmp>
f01008cb:	85 c0                	test   %eax,%eax
f01008cd:	74 1b                	je     f01008ea <monitor+0xee>
f01008cf:	c7 44 24 04 b5 1c 10 	movl   $0xf0101cb5,0x4(%esp)
f01008d6:	f0 
f01008d7:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008da:	89 04 24             	mov    %eax,(%esp)
f01008dd:	e8 20 0c 00 00       	call   f0101502 <strcmp>
f01008e2:	85 c0                	test   %eax,%eax
f01008e4:	75 2c                	jne    f0100912 <monitor+0x116>
f01008e6:	b0 01                	mov    $0x1,%al
f01008e8:	eb 05                	jmp    f01008ef <monitor+0xf3>
f01008ea:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008ef:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008f2:	01 d0                	add    %edx,%eax
f01008f4:	8b 55 08             	mov    0x8(%ebp),%edx
f01008f7:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008fb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01008ff:	89 34 24             	mov    %esi,(%esp)
f0100902:	ff 14 85 b4 1e 10 f0 	call   *-0xfefe14c(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100909:	85 c0                	test   %eax,%eax
f010090b:	78 1d                	js     f010092a <monitor+0x12e>
f010090d:	e9 0e ff ff ff       	jmp    f0100820 <monitor+0x24>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100912:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100915:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100919:	c7 04 24 3c 1d 10 f0 	movl   $0xf0101d3c,(%esp)
f0100920:	e8 c1 01 00 00       	call   f0100ae6 <cprintf>
f0100925:	e9 f6 fe ff ff       	jmp    f0100820 <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010092a:	83 c4 5c             	add    $0x5c,%esp
f010092d:	5b                   	pop    %ebx
f010092e:	5e                   	pop    %esi
f010092f:	5f                   	pop    %edi
f0100930:	5d                   	pop    %ebp
f0100931:	c3                   	ret    
	...

f0100934 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100934:	55                   	push   %ebp
f0100935:	89 e5                	mov    %esp,%ebp
f0100937:	56                   	push   %esi
f0100938:	53                   	push   %ebx
f0100939:	83 ec 10             	sub    $0x10,%esp
f010093c:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010093e:	89 04 24             	mov    %eax,(%esp)
f0100941:	e8 32 01 00 00       	call   f0100a78 <mc146818_read>
f0100946:	89 c6                	mov    %eax,%esi
f0100948:	43                   	inc    %ebx
f0100949:	89 1c 24             	mov    %ebx,(%esp)
f010094c:	e8 27 01 00 00       	call   f0100a78 <mc146818_read>
f0100951:	c1 e0 08             	shl    $0x8,%eax
f0100954:	09 f0                	or     %esi,%eax
}
f0100956:	83 c4 10             	add    $0x10,%esp
f0100959:	5b                   	pop    %ebx
f010095a:	5e                   	pop    %esi
f010095b:	5d                   	pop    %ebp
f010095c:	c3                   	ret    

f010095d <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010095d:	55                   	push   %ebp
f010095e:	89 e5                	mov    %esp,%ebp
f0100960:	56                   	push   %esi
f0100961:	53                   	push   %ebx
f0100962:	83 ec 10             	sub    $0x10,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100965:	b8 15 00 00 00       	mov    $0x15,%eax
f010096a:	e8 c5 ff ff ff       	call   f0100934 <nvram_read>
f010096f:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100971:	b8 17 00 00 00       	mov    $0x17,%eax
f0100976:	e8 b9 ff ff ff       	call   f0100934 <nvram_read>
f010097b:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010097d:	b8 34 00 00 00       	mov    $0x34,%eax
f0100982:	e8 ad ff ff ff       	call   f0100934 <nvram_read>

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100987:	c1 e0 06             	shl    $0x6,%eax
f010098a:	74 07                	je     f0100993 <mem_init+0x36>
		totalmem = 16 * 1024 + ext16mem;
f010098c:	05 00 40 00 00       	add    $0x4000,%eax
f0100991:	eb 0c                	jmp    f010099f <mem_init+0x42>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
	else
		totalmem = basemem;
f0100993:	89 d8                	mov    %ebx,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
f0100995:	85 f6                	test   %esi,%esi
f0100997:	74 06                	je     f010099f <mem_init+0x42>
		totalmem = 1 * 1024 + extmem;
f0100999:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f010099f:	89 c2                	mov    %eax,%edx
f01009a1:	c1 ea 02             	shr    $0x2,%edx
f01009a4:	89 15 44 a9 11 f0    	mov    %edx,0xf011a944
	npages_basemem = basemem / (PGSIZE / 1024);
f01009aa:	89 da                	mov    %ebx,%edx
f01009ac:	c1 ea 02             	shr    $0x2,%edx
f01009af:	89 15 38 a5 11 f0    	mov    %edx,0xf011a538

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01009b5:	89 c2                	mov    %eax,%edx
f01009b7:	29 da                	sub    %ebx,%edx
f01009b9:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01009bd:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01009c1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009c5:	c7 04 24 d4 1e 10 f0 	movl   $0xf0101ed4,(%esp)
f01009cc:	e8 15 01 00 00       	call   f0100ae6 <cprintf>

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");
f01009d1:	c7 44 24 08 10 1f 10 	movl   $0xf0101f10,0x8(%esp)
f01009d8:	f0 
f01009d9:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
f01009e0:	00 
f01009e1:	c7 04 24 3c 1f 10 f0 	movl   $0xf0101f3c,(%esp)
f01009e8:	e8 a7 f6 ff ff       	call   f0100094 <_panic>

f01009ed <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01009ed:	55                   	push   %ebp
f01009ee:	89 e5                	mov    %esp,%ebp
f01009f0:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f01009f1:	8b 1d 3c a5 11 f0    	mov    0xf011a53c,%ebx
f01009f7:	b8 00 00 00 00       	mov    $0x0,%eax
f01009fc:	eb 20                	jmp    f0100a1e <page_init+0x31>
		pages[i].pp_ref = 0;
f01009fe:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100a05:	89 d1                	mov    %edx,%ecx
f0100a07:	03 0d 4c a9 11 f0    	add    0xf011a94c,%ecx
f0100a0d:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100a13:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100a15:	89 d3                	mov    %edx,%ebx
f0100a17:	03 1d 4c a9 11 f0    	add    0xf011a94c,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100a1d:	40                   	inc    %eax
f0100a1e:	3b 05 44 a9 11 f0    	cmp    0xf011a944,%eax
f0100a24:	72 d8                	jb     f01009fe <page_init+0x11>
f0100a26:	89 1d 3c a5 11 f0    	mov    %ebx,0xf011a53c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100a2c:	5b                   	pop    %ebx
f0100a2d:	5d                   	pop    %ebp
f0100a2e:	c3                   	ret    

f0100a2f <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100a2f:	55                   	push   %ebp
f0100a30:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100a32:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a37:	5d                   	pop    %ebp
f0100a38:	c3                   	ret    

f0100a39 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100a39:	55                   	push   %ebp
f0100a3a:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100a3c:	5d                   	pop    %ebp
f0100a3d:	c3                   	ret    

f0100a3e <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100a3e:	55                   	push   %ebp
f0100a3f:	89 e5                	mov    %esp,%ebp
f0100a41:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100a44:	66 ff 48 04          	decw   0x4(%eax)
		page_free(pp);
}
f0100a48:	5d                   	pop    %ebp
f0100a49:	c3                   	ret    

f0100a4a <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100a4a:	55                   	push   %ebp
f0100a4b:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100a4d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a52:	5d                   	pop    %ebp
f0100a53:	c3                   	ret    

f0100a54 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100a54:	55                   	push   %ebp
f0100a55:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100a57:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a5c:	5d                   	pop    %ebp
f0100a5d:	c3                   	ret    

f0100a5e <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100a5e:	55                   	push   %ebp
f0100a5f:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100a61:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a66:	5d                   	pop    %ebp
f0100a67:	c3                   	ret    

f0100a68 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100a68:	55                   	push   %ebp
f0100a69:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100a6b:	5d                   	pop    %ebp
f0100a6c:	c3                   	ret    

f0100a6d <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100a6d:	55                   	push   %ebp
f0100a6e:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100a70:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a73:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100a76:	5d                   	pop    %ebp
f0100a77:	c3                   	ret    

f0100a78 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100a78:	55                   	push   %ebp
f0100a79:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100a7b:	ba 70 00 00 00       	mov    $0x70,%edx
f0100a80:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a83:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100a84:	b2 71                	mov    $0x71,%dl
f0100a86:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100a87:	0f b6 c0             	movzbl %al,%eax
}
f0100a8a:	5d                   	pop    %ebp
f0100a8b:	c3                   	ret    

f0100a8c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100a8c:	55                   	push   %ebp
f0100a8d:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100a8f:	ba 70 00 00 00       	mov    $0x70,%edx
f0100a94:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a97:	ee                   	out    %al,(%dx)
f0100a98:	b2 71                	mov    $0x71,%dl
f0100a9a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a9d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100a9e:	5d                   	pop    %ebp
f0100a9f:	c3                   	ret    

f0100aa0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100aa0:	55                   	push   %ebp
f0100aa1:	89 e5                	mov    %esp,%ebp
f0100aa3:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100aa6:	8b 45 08             	mov    0x8(%ebp),%eax
f0100aa9:	89 04 24             	mov    %eax,(%esp)
f0100aac:	e8 07 fb ff ff       	call   f01005b8 <cputchar>
	*cnt++;
}
f0100ab1:	c9                   	leave  
f0100ab2:	c3                   	ret    

f0100ab3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100ab3:	55                   	push   %ebp
f0100ab4:	89 e5                	mov    %esp,%ebp
f0100ab6:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100ab9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100ac0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ac3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ac7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100aca:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ace:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100ad1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ad5:	c7 04 24 a0 0a 10 f0 	movl   $0xf0100aa0,(%esp)
f0100adc:	e8 69 04 00 00       	call   f0100f4a <vprintfmt>
	return cnt;
}
f0100ae1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ae4:	c9                   	leave  
f0100ae5:	c3                   	ret    

f0100ae6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100ae6:	55                   	push   %ebp
f0100ae7:	89 e5                	mov    %esp,%ebp
f0100ae9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100aec:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100aef:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100af3:	8b 45 08             	mov    0x8(%ebp),%eax
f0100af6:	89 04 24             	mov    %eax,(%esp)
f0100af9:	e8 b5 ff ff ff       	call   f0100ab3 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100afe:	c9                   	leave  
f0100aff:	c3                   	ret    

f0100b00 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100b00:	55                   	push   %ebp
f0100b01:	89 e5                	mov    %esp,%ebp
f0100b03:	57                   	push   %edi
f0100b04:	56                   	push   %esi
f0100b05:	53                   	push   %ebx
f0100b06:	83 ec 10             	sub    $0x10,%esp
f0100b09:	89 c3                	mov    %eax,%ebx
f0100b0b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100b0e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100b11:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100b14:	8b 0a                	mov    (%edx),%ecx
f0100b16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b19:	8b 00                	mov    (%eax),%eax
f0100b1b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b1e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100b25:	eb 77                	jmp    f0100b9e <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100b27:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b2a:	01 c8                	add    %ecx,%eax
f0100b2c:	bf 02 00 00 00       	mov    $0x2,%edi
f0100b31:	99                   	cltd   
f0100b32:	f7 ff                	idiv   %edi
f0100b34:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100b36:	eb 01                	jmp    f0100b39 <stab_binsearch+0x39>
			m--;
f0100b38:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100b39:	39 ca                	cmp    %ecx,%edx
f0100b3b:	7c 1d                	jl     f0100b5a <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100b3d:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100b40:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100b45:	39 f7                	cmp    %esi,%edi
f0100b47:	75 ef                	jne    f0100b38 <stab_binsearch+0x38>
f0100b49:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b4c:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100b4f:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100b53:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100b56:	73 18                	jae    f0100b70 <stab_binsearch+0x70>
f0100b58:	eb 05                	jmp    f0100b5f <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100b5a:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100b5d:	eb 3f                	jmp    f0100b9e <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100b5f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100b62:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100b64:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b67:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100b6e:	eb 2e                	jmp    f0100b9e <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100b70:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100b73:	76 15                	jbe    f0100b8a <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100b75:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100b78:	4f                   	dec    %edi
f0100b79:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100b7c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b7f:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b81:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100b88:	eb 14                	jmp    f0100b9e <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b8a:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100b8d:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100b90:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100b92:	ff 45 0c             	incl   0xc(%ebp)
f0100b95:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b97:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100b9e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100ba1:	7e 84                	jle    f0100b27 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ba3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100ba7:	75 0d                	jne    f0100bb6 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100ba9:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100bac:	8b 02                	mov    (%edx),%eax
f0100bae:	48                   	dec    %eax
f0100baf:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100bb2:	89 01                	mov    %eax,(%ecx)
f0100bb4:	eb 22                	jmp    f0100bd8 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100bb6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100bb9:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100bbb:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100bbe:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100bc0:	eb 01                	jmp    f0100bc3 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100bc2:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100bc3:	39 c1                	cmp    %eax,%ecx
f0100bc5:	7d 0c                	jge    f0100bd3 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100bc7:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100bca:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100bcf:	39 f2                	cmp    %esi,%edx
f0100bd1:	75 ef                	jne    f0100bc2 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100bd3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100bd6:	89 02                	mov    %eax,(%edx)
	}
}
f0100bd8:	83 c4 10             	add    $0x10,%esp
f0100bdb:	5b                   	pop    %ebx
f0100bdc:	5e                   	pop    %esi
f0100bdd:	5f                   	pop    %edi
f0100bde:	5d                   	pop    %ebp
f0100bdf:	c3                   	ret    

f0100be0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100be0:	55                   	push   %ebp
f0100be1:	89 e5                	mov    %esp,%ebp
f0100be3:	57                   	push   %edi
f0100be4:	56                   	push   %esi
f0100be5:	53                   	push   %ebx
f0100be6:	83 ec 4c             	sub    $0x4c,%esp
f0100be9:	8b 75 08             	mov    0x8(%ebp),%esi
f0100bec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100bef:	c7 03 48 1f 10 f0    	movl   $0xf0101f48,(%ebx)
	info->eip_line = 0;
f0100bf5:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100bfc:	c7 43 08 48 1f 10 f0 	movl   $0xf0101f48,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100c03:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100c0a:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100c0d:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100c14:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100c1a:	76 12                	jbe    f0100c2e <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c1c:	b8 5b fe 10 f0       	mov    $0xf010fe5b,%eax
f0100c21:	3d 09 6f 10 f0       	cmp    $0xf0106f09,%eax
f0100c26:	0f 86 a7 01 00 00    	jbe    f0100dd3 <debuginfo_eip+0x1f3>
f0100c2c:	eb 1c                	jmp    f0100c4a <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100c2e:	c7 44 24 08 52 1f 10 	movl   $0xf0101f52,0x8(%esp)
f0100c35:	f0 
f0100c36:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100c3d:	00 
f0100c3e:	c7 04 24 5f 1f 10 f0 	movl   $0xf0101f5f,(%esp)
f0100c45:	e8 4a f4 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c4a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c4f:	80 3d 5a fe 10 f0 00 	cmpb   $0x0,0xf010fe5a
f0100c56:	0f 85 83 01 00 00    	jne    f0100ddf <debuginfo_eip+0x1ff>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c5c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c63:	b8 08 6f 10 f0       	mov    $0xf0106f08,%eax
f0100c68:	2d 80 21 10 f0       	sub    $0xf0102180,%eax
f0100c6d:	c1 f8 02             	sar    $0x2,%eax
f0100c70:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100c76:	48                   	dec    %eax
f0100c77:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c7a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c7e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100c85:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c88:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c8b:	b8 80 21 10 f0       	mov    $0xf0102180,%eax
f0100c90:	e8 6b fe ff ff       	call   f0100b00 <stab_binsearch>
	if (lfile == 0)
f0100c95:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100c98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100c9d:	85 d2                	test   %edx,%edx
f0100c9f:	0f 84 3a 01 00 00    	je     f0100ddf <debuginfo_eip+0x1ff>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ca5:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100ca8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cab:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100cae:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100cb2:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100cb9:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100cbc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100cbf:	b8 80 21 10 f0       	mov    $0xf0102180,%eax
f0100cc4:	e8 37 fe ff ff       	call   f0100b00 <stab_binsearch>

	if (lfun <= rfun) {
f0100cc9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ccc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100ccf:	39 d0                	cmp    %edx,%eax
f0100cd1:	7f 3e                	jg     f0100d11 <debuginfo_eip+0x131>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100cd3:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100cd6:	8d b9 80 21 10 f0    	lea    -0xfefde80(%ecx),%edi
f0100cdc:	8b 89 80 21 10 f0    	mov    -0xfefde80(%ecx),%ecx
f0100ce2:	89 4d c0             	mov    %ecx,-0x40(%ebp)
f0100ce5:	b9 5b fe 10 f0       	mov    $0xf010fe5b,%ecx
f0100cea:	81 e9 09 6f 10 f0    	sub    $0xf0106f09,%ecx
f0100cf0:	39 4d c0             	cmp    %ecx,-0x40(%ebp)
f0100cf3:	73 0c                	jae    f0100d01 <debuginfo_eip+0x121>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100cf5:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0100cf8:	81 c1 09 6f 10 f0    	add    $0xf0106f09,%ecx
f0100cfe:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100d01:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100d04:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100d07:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100d09:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100d0c:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100d0f:	eb 0f                	jmp    f0100d20 <debuginfo_eip+0x140>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100d11:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100d14:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d17:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100d1a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d1d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100d20:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100d27:	00 
f0100d28:	8b 43 08             	mov    0x8(%ebx),%eax
f0100d2b:	89 04 24             	mov    %eax,(%esp)
f0100d2e:	e8 3f 08 00 00       	call   f0101572 <strfind>
f0100d33:	2b 43 08             	sub    0x8(%ebx),%eax
f0100d36:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100d39:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d3d:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100d44:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100d47:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100d4a:	b8 80 21 10 f0       	mov    $0xf0102180,%eax
f0100d4f:	e8 ac fd ff ff       	call   f0100b00 <stab_binsearch>
    if(lline <= rline){
f0100d54:	8b 55 d4             	mov    -0x2c(%ebp),%edx
        info->eip_line = stabs[lline].n_desc;
    } else {
        return -1;
f0100d57:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if(lline <= rline){
f0100d5c:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100d5f:	7f 7e                	jg     f0100ddf <debuginfo_eip+0x1ff>
        info->eip_line = stabs[lline].n_desc;
f0100d61:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100d64:	0f b7 82 86 21 10 f0 	movzwl -0xfefde7a(%edx),%eax
f0100d6b:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d6e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d71:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d74:	eb 01                	jmp    f0100d77 <debuginfo_eip+0x197>
f0100d76:	48                   	dec    %eax
f0100d77:	89 c6                	mov    %eax,%esi
f0100d79:	39 c7                	cmp    %eax,%edi
f0100d7b:	7f 26                	jg     f0100da3 <debuginfo_eip+0x1c3>
	       && stabs[lline].n_type != N_SOL
f0100d7d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100d80:	8d 0c 95 80 21 10 f0 	lea    -0xfefde80(,%edx,4),%ecx
f0100d87:	8a 51 04             	mov    0x4(%ecx),%dl
f0100d8a:	80 fa 84             	cmp    $0x84,%dl
f0100d8d:	74 58                	je     f0100de7 <debuginfo_eip+0x207>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d8f:	80 fa 64             	cmp    $0x64,%dl
f0100d92:	75 e2                	jne    f0100d76 <debuginfo_eip+0x196>
f0100d94:	83 79 08 00          	cmpl   $0x0,0x8(%ecx)
f0100d98:	74 dc                	je     f0100d76 <debuginfo_eip+0x196>
f0100d9a:	eb 4b                	jmp    f0100de7 <debuginfo_eip+0x207>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d9c:	05 09 6f 10 f0       	add    $0xf0106f09,%eax
f0100da1:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100da3:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100da6:	8b 55 d8             	mov    -0x28(%ebp),%edx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100da9:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100dae:	39 d1                	cmp    %edx,%ecx
f0100db0:	7d 2d                	jge    f0100ddf <debuginfo_eip+0x1ff>
		for (lline = lfun + 1;
f0100db2:	8d 41 01             	lea    0x1(%ecx),%eax
f0100db5:	eb 03                	jmp    f0100dba <debuginfo_eip+0x1da>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100db7:	ff 43 14             	incl   0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100dba:	39 d0                	cmp    %edx,%eax
f0100dbc:	7d 1c                	jge    f0100dda <debuginfo_eip+0x1fa>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100dbe:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100dc1:	40                   	inc    %eax
f0100dc2:	80 3c 8d 84 21 10 f0 	cmpb   $0xa0,-0xfefde7c(,%ecx,4)
f0100dc9:	a0 
f0100dca:	74 eb                	je     f0100db7 <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100dcc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dd1:	eb 0c                	jmp    f0100ddf <debuginfo_eip+0x1ff>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100dd3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100dd8:	eb 05                	jmp    f0100ddf <debuginfo_eip+0x1ff>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100dda:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ddf:	83 c4 4c             	add    $0x4c,%esp
f0100de2:	5b                   	pop    %ebx
f0100de3:	5e                   	pop    %esi
f0100de4:	5f                   	pop    %edi
f0100de5:	5d                   	pop    %ebp
f0100de6:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100de7:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100dea:	8b 86 80 21 10 f0    	mov    -0xfefde80(%esi),%eax
f0100df0:	ba 5b fe 10 f0       	mov    $0xf010fe5b,%edx
f0100df5:	81 ea 09 6f 10 f0    	sub    $0xf0106f09,%edx
f0100dfb:	39 d0                	cmp    %edx,%eax
f0100dfd:	72 9d                	jb     f0100d9c <debuginfo_eip+0x1bc>
f0100dff:	eb a2                	jmp    f0100da3 <debuginfo_eip+0x1c3>
f0100e01:	00 00                	add    %al,(%eax)
	...

f0100e04 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100e04:	55                   	push   %ebp
f0100e05:	89 e5                	mov    %esp,%ebp
f0100e07:	57                   	push   %edi
f0100e08:	56                   	push   %esi
f0100e09:	53                   	push   %ebx
f0100e0a:	83 ec 3c             	sub    $0x3c,%esp
f0100e0d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e10:	89 d7                	mov    %edx,%edi
f0100e12:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e15:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100e18:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e1e:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100e21:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100e24:	85 c0                	test   %eax,%eax
f0100e26:	75 08                	jne    f0100e30 <printnum+0x2c>
f0100e28:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e2b:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100e2e:	77 57                	ja     f0100e87 <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100e30:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100e34:	4b                   	dec    %ebx
f0100e35:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100e39:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e3c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e40:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100e44:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100e48:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e4f:	00 
f0100e50:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e53:	89 04 24             	mov    %eax,(%esp)
f0100e56:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e59:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e5d:	e8 1e 09 00 00       	call   f0101780 <__udivdi3>
f0100e62:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100e66:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100e6a:	89 04 24             	mov    %eax,(%esp)
f0100e6d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e71:	89 fa                	mov    %edi,%edx
f0100e73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e76:	e8 89 ff ff ff       	call   f0100e04 <printnum>
f0100e7b:	eb 0f                	jmp    f0100e8c <printnum+0x88>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e7d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e81:	89 34 24             	mov    %esi,(%esp)
f0100e84:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e87:	4b                   	dec    %ebx
f0100e88:	85 db                	test   %ebx,%ebx
f0100e8a:	7f f1                	jg     f0100e7d <printnum+0x79>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e8c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e90:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e94:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e97:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e9b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100ea2:	00 
f0100ea3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ea6:	89 04 24             	mov    %eax,(%esp)
f0100ea9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eac:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100eb0:	e8 eb 09 00 00       	call   f01018a0 <__umoddi3>
f0100eb5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100eb9:	0f be 80 6d 1f 10 f0 	movsbl -0xfefe093(%eax),%eax
f0100ec0:	89 04 24             	mov    %eax,(%esp)
f0100ec3:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100ec6:	83 c4 3c             	add    $0x3c,%esp
f0100ec9:	5b                   	pop    %ebx
f0100eca:	5e                   	pop    %esi
f0100ecb:	5f                   	pop    %edi
f0100ecc:	5d                   	pop    %ebp
f0100ecd:	c3                   	ret    

f0100ece <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100ece:	55                   	push   %ebp
f0100ecf:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100ed1:	83 fa 01             	cmp    $0x1,%edx
f0100ed4:	7e 0e                	jle    f0100ee4 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100ed6:	8b 10                	mov    (%eax),%edx
f0100ed8:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100edb:	89 08                	mov    %ecx,(%eax)
f0100edd:	8b 02                	mov    (%edx),%eax
f0100edf:	8b 52 04             	mov    0x4(%edx),%edx
f0100ee2:	eb 22                	jmp    f0100f06 <getuint+0x38>
	else if (lflag)
f0100ee4:	85 d2                	test   %edx,%edx
f0100ee6:	74 10                	je     f0100ef8 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100ee8:	8b 10                	mov    (%eax),%edx
f0100eea:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100eed:	89 08                	mov    %ecx,(%eax)
f0100eef:	8b 02                	mov    (%edx),%eax
f0100ef1:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ef6:	eb 0e                	jmp    f0100f06 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100ef8:	8b 10                	mov    (%eax),%edx
f0100efa:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100efd:	89 08                	mov    %ecx,(%eax)
f0100eff:	8b 02                	mov    (%edx),%eax
f0100f01:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100f06:	5d                   	pop    %ebp
f0100f07:	c3                   	ret    

f0100f08 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100f08:	55                   	push   %ebp
f0100f09:	89 e5                	mov    %esp,%ebp
f0100f0b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100f0e:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0100f11:	8b 10                	mov    (%eax),%edx
f0100f13:	3b 50 04             	cmp    0x4(%eax),%edx
f0100f16:	73 08                	jae    f0100f20 <sprintputch+0x18>
		*b->buf++ = ch;
f0100f18:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100f1b:	88 0a                	mov    %cl,(%edx)
f0100f1d:	42                   	inc    %edx
f0100f1e:	89 10                	mov    %edx,(%eax)
}
f0100f20:	5d                   	pop    %ebp
f0100f21:	c3                   	ret    

f0100f22 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100f22:	55                   	push   %ebp
f0100f23:	89 e5                	mov    %esp,%ebp
f0100f25:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100f28:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f2b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f2f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f32:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f36:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f39:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f3d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f40:	89 04 24             	mov    %eax,(%esp)
f0100f43:	e8 02 00 00 00       	call   f0100f4a <vprintfmt>
	va_end(ap);
}
f0100f48:	c9                   	leave  
f0100f49:	c3                   	ret    

f0100f4a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100f4a:	55                   	push   %ebp
f0100f4b:	89 e5                	mov    %esp,%ebp
f0100f4d:	57                   	push   %edi
f0100f4e:	56                   	push   %esi
f0100f4f:	53                   	push   %ebx
f0100f50:	83 ec 4c             	sub    $0x4c,%esp
f0100f53:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f56:	8b 75 10             	mov    0x10(%ebp),%esi
f0100f59:	eb 12                	jmp    f0100f6d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100f5b:	85 c0                	test   %eax,%eax
f0100f5d:	0f 84 6b 03 00 00    	je     f01012ce <vprintfmt+0x384>
				return;
			putch(ch, putdat);
f0100f63:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f67:	89 04 24             	mov    %eax,(%esp)
f0100f6a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f6d:	0f b6 06             	movzbl (%esi),%eax
f0100f70:	46                   	inc    %esi
f0100f71:	83 f8 25             	cmp    $0x25,%eax
f0100f74:	75 e5                	jne    f0100f5b <vprintfmt+0x11>
f0100f76:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100f7a:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100f81:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100f86:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100f8d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f92:	eb 26                	jmp    f0100fba <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f94:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f97:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100f9b:	eb 1d                	jmp    f0100fba <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f9d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100fa0:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100fa4:	eb 14                	jmp    f0100fba <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa6:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100fa9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100fb0:	eb 08                	jmp    f0100fba <vprintfmt+0x70>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100fb2:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0100fb5:	bf ff ff ff ff       	mov    $0xffffffff,%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fba:	0f b6 06             	movzbl (%esi),%eax
f0100fbd:	8d 56 01             	lea    0x1(%esi),%edx
f0100fc0:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100fc3:	8a 16                	mov    (%esi),%dl
f0100fc5:	83 ea 23             	sub    $0x23,%edx
f0100fc8:	80 fa 55             	cmp    $0x55,%dl
f0100fcb:	0f 87 e1 02 00 00    	ja     f01012b2 <vprintfmt+0x368>
f0100fd1:	0f b6 d2             	movzbl %dl,%edx
f0100fd4:	ff 24 95 fc 1f 10 f0 	jmp    *-0xfefe004(,%edx,4)
f0100fdb:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100fde:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100fe3:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0100fe6:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0100fea:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100fed:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100ff0:	83 fa 09             	cmp    $0x9,%edx
f0100ff3:	77 2a                	ja     f010101f <vprintfmt+0xd5>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100ff5:	46                   	inc    %esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100ff6:	eb eb                	jmp    f0100fe3 <vprintfmt+0x99>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100ff8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ffb:	8d 50 04             	lea    0x4(%eax),%edx
f0100ffe:	89 55 14             	mov    %edx,0x14(%ebp)
f0101001:	8b 38                	mov    (%eax),%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101003:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101006:	eb 17                	jmp    f010101f <vprintfmt+0xd5>

		case '.':
			if (width < 0)
f0101008:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010100c:	78 98                	js     f0100fa6 <vprintfmt+0x5c>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010100e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101011:	eb a7                	jmp    f0100fba <vprintfmt+0x70>
f0101013:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101016:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f010101d:	eb 9b                	jmp    f0100fba <vprintfmt+0x70>

		process_precision:
			if (width < 0)
f010101f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101023:	79 95                	jns    f0100fba <vprintfmt+0x70>
f0101025:	eb 8b                	jmp    f0100fb2 <vprintfmt+0x68>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101027:	41                   	inc    %ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101028:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010102b:	eb 8d                	jmp    f0100fba <vprintfmt+0x70>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010102d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101030:	8d 50 04             	lea    0x4(%eax),%edx
f0101033:	89 55 14             	mov    %edx,0x14(%ebp)
f0101036:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010103a:	8b 00                	mov    (%eax),%eax
f010103c:	89 04 24             	mov    %eax,(%esp)
f010103f:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101042:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101045:	e9 23 ff ff ff       	jmp    f0100f6d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010104a:	8b 45 14             	mov    0x14(%ebp),%eax
f010104d:	8d 50 04             	lea    0x4(%eax),%edx
f0101050:	89 55 14             	mov    %edx,0x14(%ebp)
f0101053:	8b 00                	mov    (%eax),%eax
f0101055:	85 c0                	test   %eax,%eax
f0101057:	79 02                	jns    f010105b <vprintfmt+0x111>
f0101059:	f7 d8                	neg    %eax
f010105b:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010105d:	83 f8 06             	cmp    $0x6,%eax
f0101060:	7f 0b                	jg     f010106d <vprintfmt+0x123>
f0101062:	8b 04 85 54 21 10 f0 	mov    -0xfefdeac(,%eax,4),%eax
f0101069:	85 c0                	test   %eax,%eax
f010106b:	75 23                	jne    f0101090 <vprintfmt+0x146>
				printfmt(putch, putdat, "error %d", err);
f010106d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101071:	c7 44 24 08 85 1f 10 	movl   $0xf0101f85,0x8(%esp)
f0101078:	f0 
f0101079:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010107d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101080:	89 04 24             	mov    %eax,(%esp)
f0101083:	e8 9a fe ff ff       	call   f0100f22 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101088:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010108b:	e9 dd fe ff ff       	jmp    f0100f6d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0101090:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101094:	c7 44 24 08 8e 1f 10 	movl   $0xf0101f8e,0x8(%esp)
f010109b:	f0 
f010109c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010a0:	8b 55 08             	mov    0x8(%ebp),%edx
f01010a3:	89 14 24             	mov    %edx,(%esp)
f01010a6:	e8 77 fe ff ff       	call   f0100f22 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010ab:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01010ae:	e9 ba fe ff ff       	jmp    f0100f6d <vprintfmt+0x23>
f01010b3:	89 f9                	mov    %edi,%ecx
f01010b5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010b8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01010bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01010be:	8d 50 04             	lea    0x4(%eax),%edx
f01010c1:	89 55 14             	mov    %edx,0x14(%ebp)
f01010c4:	8b 30                	mov    (%eax),%esi
f01010c6:	85 f6                	test   %esi,%esi
f01010c8:	75 05                	jne    f01010cf <vprintfmt+0x185>
				p = "(null)";
f01010ca:	be 7e 1f 10 f0       	mov    $0xf0101f7e,%esi
			if (width > 0 && padc != '-')
f01010cf:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01010d3:	0f 8e 84 00 00 00    	jle    f010115d <vprintfmt+0x213>
f01010d9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01010dd:	74 7e                	je     f010115d <vprintfmt+0x213>
				for (width -= strnlen(p, precision); width > 0; width--)
f01010df:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010e3:	89 34 24             	mov    %esi,(%esp)
f01010e6:	e8 53 03 00 00       	call   f010143e <strnlen>
f01010eb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01010ee:	29 c2                	sub    %eax,%edx
f01010f0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
f01010f3:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01010f7:	89 75 d0             	mov    %esi,-0x30(%ebp)
f01010fa:	89 7d cc             	mov    %edi,-0x34(%ebp)
f01010fd:	89 de                	mov    %ebx,%esi
f01010ff:	89 d3                	mov    %edx,%ebx
f0101101:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101103:	eb 0b                	jmp    f0101110 <vprintfmt+0x1c6>
					putch(padc, putdat);
f0101105:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101109:	89 3c 24             	mov    %edi,(%esp)
f010110c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010110f:	4b                   	dec    %ebx
f0101110:	85 db                	test   %ebx,%ebx
f0101112:	7f f1                	jg     f0101105 <vprintfmt+0x1bb>
f0101114:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0101117:	89 f3                	mov    %esi,%ebx
f0101119:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f010111c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010111f:	85 c0                	test   %eax,%eax
f0101121:	79 05                	jns    f0101128 <vprintfmt+0x1de>
f0101123:	b8 00 00 00 00       	mov    $0x0,%eax
f0101128:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010112b:	29 c2                	sub    %eax,%edx
f010112d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101130:	eb 2b                	jmp    f010115d <vprintfmt+0x213>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101132:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101136:	74 18                	je     f0101150 <vprintfmt+0x206>
f0101138:	8d 50 e0             	lea    -0x20(%eax),%edx
f010113b:	83 fa 5e             	cmp    $0x5e,%edx
f010113e:	76 10                	jbe    f0101150 <vprintfmt+0x206>
					putch('?', putdat);
f0101140:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101144:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010114b:	ff 55 08             	call   *0x8(%ebp)
f010114e:	eb 0a                	jmp    f010115a <vprintfmt+0x210>
				else
					putch(ch, putdat);
f0101150:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101154:	89 04 24             	mov    %eax,(%esp)
f0101157:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010115a:	ff 4d e4             	decl   -0x1c(%ebp)
f010115d:	0f be 06             	movsbl (%esi),%eax
f0101160:	46                   	inc    %esi
f0101161:	85 c0                	test   %eax,%eax
f0101163:	74 21                	je     f0101186 <vprintfmt+0x23c>
f0101165:	85 ff                	test   %edi,%edi
f0101167:	78 c9                	js     f0101132 <vprintfmt+0x1e8>
f0101169:	4f                   	dec    %edi
f010116a:	79 c6                	jns    f0101132 <vprintfmt+0x1e8>
f010116c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010116f:	89 de                	mov    %ebx,%esi
f0101171:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101174:	eb 18                	jmp    f010118e <vprintfmt+0x244>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101176:	89 74 24 04          	mov    %esi,0x4(%esp)
f010117a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101181:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101183:	4b                   	dec    %ebx
f0101184:	eb 08                	jmp    f010118e <vprintfmt+0x244>
f0101186:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101189:	89 de                	mov    %ebx,%esi
f010118b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010118e:	85 db                	test   %ebx,%ebx
f0101190:	7f e4                	jg     f0101176 <vprintfmt+0x22c>
f0101192:	89 7d 08             	mov    %edi,0x8(%ebp)
f0101195:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101197:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010119a:	e9 ce fd ff ff       	jmp    f0100f6d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010119f:	83 f9 01             	cmp    $0x1,%ecx
f01011a2:	7e 10                	jle    f01011b4 <vprintfmt+0x26a>
		return va_arg(*ap, long long);
f01011a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a7:	8d 50 08             	lea    0x8(%eax),%edx
f01011aa:	89 55 14             	mov    %edx,0x14(%ebp)
f01011ad:	8b 30                	mov    (%eax),%esi
f01011af:	8b 78 04             	mov    0x4(%eax),%edi
f01011b2:	eb 26                	jmp    f01011da <vprintfmt+0x290>
	else if (lflag)
f01011b4:	85 c9                	test   %ecx,%ecx
f01011b6:	74 12                	je     f01011ca <vprintfmt+0x280>
		return va_arg(*ap, long);
f01011b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01011bb:	8d 50 04             	lea    0x4(%eax),%edx
f01011be:	89 55 14             	mov    %edx,0x14(%ebp)
f01011c1:	8b 30                	mov    (%eax),%esi
f01011c3:	89 f7                	mov    %esi,%edi
f01011c5:	c1 ff 1f             	sar    $0x1f,%edi
f01011c8:	eb 10                	jmp    f01011da <vprintfmt+0x290>
	else
		return va_arg(*ap, int);
f01011ca:	8b 45 14             	mov    0x14(%ebp),%eax
f01011cd:	8d 50 04             	lea    0x4(%eax),%edx
f01011d0:	89 55 14             	mov    %edx,0x14(%ebp)
f01011d3:	8b 30                	mov    (%eax),%esi
f01011d5:	89 f7                	mov    %esi,%edi
f01011d7:	c1 ff 1f             	sar    $0x1f,%edi
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011da:	85 ff                	test   %edi,%edi
f01011dc:	78 0a                	js     f01011e8 <vprintfmt+0x29e>
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011de:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011e3:	e9 8c 00 00 00       	jmp    f0101274 <vprintfmt+0x32a>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f01011e8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011ec:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01011f3:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01011f6:	f7 de                	neg    %esi
f01011f8:	83 d7 00             	adc    $0x0,%edi
f01011fb:	f7 df                	neg    %edi
			}
			base = 10;
f01011fd:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101202:	eb 70                	jmp    f0101274 <vprintfmt+0x32a>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101204:	89 ca                	mov    %ecx,%edx
f0101206:	8d 45 14             	lea    0x14(%ebp),%eax
f0101209:	e8 c0 fc ff ff       	call   f0100ece <getuint>
f010120e:	89 c6                	mov    %eax,%esi
f0101210:	89 d7                	mov    %edx,%edi
			base = 10;
f0101212:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0101217:	eb 5b                	jmp    f0101274 <vprintfmt+0x32a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101219:	89 ca                	mov    %ecx,%edx
f010121b:	8d 45 14             	lea    0x14(%ebp),%eax
f010121e:	e8 ab fc ff ff       	call   f0100ece <getuint>
f0101223:	89 c6                	mov    %eax,%esi
f0101225:	89 d7                	mov    %edx,%edi
			base = 8;
f0101227:	b8 08 00 00 00       	mov    $0x8,%eax
            goto number;
f010122c:	eb 46                	jmp    f0101274 <vprintfmt+0x32a>
		// pointer
		case 'p':
			putch('0', putdat);
f010122e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101232:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101239:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010123c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101240:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101247:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010124a:	8b 45 14             	mov    0x14(%ebp),%eax
f010124d:	8d 50 04             	lea    0x4(%eax),%edx
f0101250:	89 55 14             	mov    %edx,0x14(%ebp)
            goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101253:	8b 30                	mov    (%eax),%esi
f0101255:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010125a:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010125f:	eb 13                	jmp    f0101274 <vprintfmt+0x32a>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101261:	89 ca                	mov    %ecx,%edx
f0101263:	8d 45 14             	lea    0x14(%ebp),%eax
f0101266:	e8 63 fc ff ff       	call   f0100ece <getuint>
f010126b:	89 c6                	mov    %eax,%esi
f010126d:	89 d7                	mov    %edx,%edi
			base = 16;
f010126f:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101274:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f0101278:	89 54 24 10          	mov    %edx,0x10(%esp)
f010127c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010127f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101283:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101287:	89 34 24             	mov    %esi,(%esp)
f010128a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010128e:	89 da                	mov    %ebx,%edx
f0101290:	8b 45 08             	mov    0x8(%ebp),%eax
f0101293:	e8 6c fb ff ff       	call   f0100e04 <printnum>
			break;
f0101298:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010129b:	e9 cd fc ff ff       	jmp    f0100f6d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01012a0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012a4:	89 04 24             	mov    %eax,(%esp)
f01012a7:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012aa:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01012ad:	e9 bb fc ff ff       	jmp    f0100f6d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01012b2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012b6:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01012bd:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012c0:	eb 01                	jmp    f01012c3 <vprintfmt+0x379>
f01012c2:	4e                   	dec    %esi
f01012c3:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01012c7:	75 f9                	jne    f01012c2 <vprintfmt+0x378>
f01012c9:	e9 9f fc ff ff       	jmp    f0100f6d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f01012ce:	83 c4 4c             	add    $0x4c,%esp
f01012d1:	5b                   	pop    %ebx
f01012d2:	5e                   	pop    %esi
f01012d3:	5f                   	pop    %edi
f01012d4:	5d                   	pop    %ebp
f01012d5:	c3                   	ret    

f01012d6 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012d6:	55                   	push   %ebp
f01012d7:	89 e5                	mov    %esp,%ebp
f01012d9:	83 ec 28             	sub    $0x28,%esp
f01012dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01012df:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012e2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012e5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012e9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012ec:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012f3:	85 c0                	test   %eax,%eax
f01012f5:	74 30                	je     f0101327 <vsnprintf+0x51>
f01012f7:	85 d2                	test   %edx,%edx
f01012f9:	7e 33                	jle    f010132e <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01012fb:	8b 45 14             	mov    0x14(%ebp),%eax
f01012fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101302:	8b 45 10             	mov    0x10(%ebp),%eax
f0101305:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101309:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010130c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101310:	c7 04 24 08 0f 10 f0 	movl   $0xf0100f08,(%esp)
f0101317:	e8 2e fc ff ff       	call   f0100f4a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010131c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010131f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101322:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101325:	eb 0c                	jmp    f0101333 <vsnprintf+0x5d>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101327:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010132c:	eb 05                	jmp    f0101333 <vsnprintf+0x5d>
f010132e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101333:	c9                   	leave  
f0101334:	c3                   	ret    

f0101335 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101335:	55                   	push   %ebp
f0101336:	89 e5                	mov    %esp,%ebp
f0101338:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010133b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010133e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101342:	8b 45 10             	mov    0x10(%ebp),%eax
f0101345:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101349:	8b 45 0c             	mov    0xc(%ebp),%eax
f010134c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101350:	8b 45 08             	mov    0x8(%ebp),%eax
f0101353:	89 04 24             	mov    %eax,(%esp)
f0101356:	e8 7b ff ff ff       	call   f01012d6 <vsnprintf>
	va_end(ap);

	return rc;
}
f010135b:	c9                   	leave  
f010135c:	c3                   	ret    
f010135d:	00 00                	add    %al,(%eax)
	...

f0101360 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101360:	55                   	push   %ebp
f0101361:	89 e5                	mov    %esp,%ebp
f0101363:	57                   	push   %edi
f0101364:	56                   	push   %esi
f0101365:	53                   	push   %ebx
f0101366:	83 ec 1c             	sub    $0x1c,%esp
f0101369:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010136c:	85 c0                	test   %eax,%eax
f010136e:	74 10                	je     f0101380 <readline+0x20>
		cprintf("%s", prompt);
f0101370:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101374:	c7 04 24 8e 1f 10 f0 	movl   $0xf0101f8e,(%esp)
f010137b:	e8 66 f7 ff ff       	call   f0100ae6 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101380:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101387:	e8 4d f2 ff ff       	call   f01005d9 <iscons>
f010138c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010138e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101393:	e8 30 f2 ff ff       	call   f01005c8 <getchar>
f0101398:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010139a:	85 c0                	test   %eax,%eax
f010139c:	79 17                	jns    f01013b5 <readline+0x55>
			cprintf("read error: %e\n", c);
f010139e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013a2:	c7 04 24 70 21 10 f0 	movl   $0xf0102170,(%esp)
f01013a9:	e8 38 f7 ff ff       	call   f0100ae6 <cprintf>
			return NULL;
f01013ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01013b3:	eb 69                	jmp    f010141e <readline+0xbe>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013b5:	83 f8 08             	cmp    $0x8,%eax
f01013b8:	74 05                	je     f01013bf <readline+0x5f>
f01013ba:	83 f8 7f             	cmp    $0x7f,%eax
f01013bd:	75 17                	jne    f01013d6 <readline+0x76>
f01013bf:	85 f6                	test   %esi,%esi
f01013c1:	7e 13                	jle    f01013d6 <readline+0x76>
			if (echoing)
f01013c3:	85 ff                	test   %edi,%edi
f01013c5:	74 0c                	je     f01013d3 <readline+0x73>
				cputchar('\b');
f01013c7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01013ce:	e8 e5 f1 ff ff       	call   f01005b8 <cputchar>
			i--;
f01013d3:	4e                   	dec    %esi
f01013d4:	eb bd                	jmp    f0101393 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01013d6:	83 fb 1f             	cmp    $0x1f,%ebx
f01013d9:	7e 1d                	jle    f01013f8 <readline+0x98>
f01013db:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01013e1:	7f 15                	jg     f01013f8 <readline+0x98>
			if (echoing)
f01013e3:	85 ff                	test   %edi,%edi
f01013e5:	74 08                	je     f01013ef <readline+0x8f>
				cputchar(c);
f01013e7:	89 1c 24             	mov    %ebx,(%esp)
f01013ea:	e8 c9 f1 ff ff       	call   f01005b8 <cputchar>
			buf[i++] = c;
f01013ef:	88 9e 40 a5 11 f0    	mov    %bl,-0xfee5ac0(%esi)
f01013f5:	46                   	inc    %esi
f01013f6:	eb 9b                	jmp    f0101393 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01013f8:	83 fb 0a             	cmp    $0xa,%ebx
f01013fb:	74 05                	je     f0101402 <readline+0xa2>
f01013fd:	83 fb 0d             	cmp    $0xd,%ebx
f0101400:	75 91                	jne    f0101393 <readline+0x33>
			if (echoing)
f0101402:	85 ff                	test   %edi,%edi
f0101404:	74 0c                	je     f0101412 <readline+0xb2>
				cputchar('\n');
f0101406:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f010140d:	e8 a6 f1 ff ff       	call   f01005b8 <cputchar>
			buf[i] = 0;
f0101412:	c6 86 40 a5 11 f0 00 	movb   $0x0,-0xfee5ac0(%esi)
			return buf;
f0101419:	b8 40 a5 11 f0       	mov    $0xf011a540,%eax
		}
	}
}
f010141e:	83 c4 1c             	add    $0x1c,%esp
f0101421:	5b                   	pop    %ebx
f0101422:	5e                   	pop    %esi
f0101423:	5f                   	pop    %edi
f0101424:	5d                   	pop    %ebp
f0101425:	c3                   	ret    
	...

f0101428 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101428:	55                   	push   %ebp
f0101429:	89 e5                	mov    %esp,%ebp
f010142b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010142e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101433:	eb 01                	jmp    f0101436 <strlen+0xe>
		n++;
f0101435:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101436:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010143a:	75 f9                	jne    f0101435 <strlen+0xd>
		n++;
	return n;
}
f010143c:	5d                   	pop    %ebp
f010143d:	c3                   	ret    

f010143e <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010143e:	55                   	push   %ebp
f010143f:	89 e5                	mov    %esp,%ebp
f0101441:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
f0101444:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101447:	b8 00 00 00 00       	mov    $0x0,%eax
f010144c:	eb 01                	jmp    f010144f <strnlen+0x11>
		n++;
f010144e:	40                   	inc    %eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010144f:	39 d0                	cmp    %edx,%eax
f0101451:	74 06                	je     f0101459 <strnlen+0x1b>
f0101453:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101457:	75 f5                	jne    f010144e <strnlen+0x10>
		n++;
	return n;
}
f0101459:	5d                   	pop    %ebp
f010145a:	c3                   	ret    

f010145b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010145b:	55                   	push   %ebp
f010145c:	89 e5                	mov    %esp,%ebp
f010145e:	53                   	push   %ebx
f010145f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101462:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101465:	ba 00 00 00 00       	mov    $0x0,%edx
f010146a:	8a 0c 13             	mov    (%ebx,%edx,1),%cl
f010146d:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101470:	42                   	inc    %edx
f0101471:	84 c9                	test   %cl,%cl
f0101473:	75 f5                	jne    f010146a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101475:	5b                   	pop    %ebx
f0101476:	5d                   	pop    %ebp
f0101477:	c3                   	ret    

f0101478 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101478:	55                   	push   %ebp
f0101479:	89 e5                	mov    %esp,%ebp
f010147b:	53                   	push   %ebx
f010147c:	83 ec 08             	sub    $0x8,%esp
f010147f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101482:	89 1c 24             	mov    %ebx,(%esp)
f0101485:	e8 9e ff ff ff       	call   f0101428 <strlen>
	strcpy(dst + len, src);
f010148a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010148d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101491:	01 d8                	add    %ebx,%eax
f0101493:	89 04 24             	mov    %eax,(%esp)
f0101496:	e8 c0 ff ff ff       	call   f010145b <strcpy>
	return dst;
}
f010149b:	89 d8                	mov    %ebx,%eax
f010149d:	83 c4 08             	add    $0x8,%esp
f01014a0:	5b                   	pop    %ebx
f01014a1:	5d                   	pop    %ebp
f01014a2:	c3                   	ret    

f01014a3 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014a3:	55                   	push   %ebp
f01014a4:	89 e5                	mov    %esp,%ebp
f01014a6:	56                   	push   %esi
f01014a7:	53                   	push   %ebx
f01014a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ab:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014ae:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014b1:	b9 00 00 00 00       	mov    $0x0,%ecx
f01014b6:	eb 0c                	jmp    f01014c4 <strncpy+0x21>
		*dst++ = *src;
f01014b8:	8a 1a                	mov    (%edx),%bl
f01014ba:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01014bd:	80 3a 01             	cmpb   $0x1,(%edx)
f01014c0:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014c3:	41                   	inc    %ecx
f01014c4:	39 f1                	cmp    %esi,%ecx
f01014c6:	75 f0                	jne    f01014b8 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01014c8:	5b                   	pop    %ebx
f01014c9:	5e                   	pop    %esi
f01014ca:	5d                   	pop    %ebp
f01014cb:	c3                   	ret    

f01014cc <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01014cc:	55                   	push   %ebp
f01014cd:	89 e5                	mov    %esp,%ebp
f01014cf:	56                   	push   %esi
f01014d0:	53                   	push   %ebx
f01014d1:	8b 75 08             	mov    0x8(%ebp),%esi
f01014d4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014d7:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01014da:	85 d2                	test   %edx,%edx
f01014dc:	75 0a                	jne    f01014e8 <strlcpy+0x1c>
f01014de:	89 f0                	mov    %esi,%eax
f01014e0:	eb 1a                	jmp    f01014fc <strlcpy+0x30>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01014e2:	88 18                	mov    %bl,(%eax)
f01014e4:	40                   	inc    %eax
f01014e5:	41                   	inc    %ecx
f01014e6:	eb 02                	jmp    f01014ea <strlcpy+0x1e>
strlcpy(char *dst, const char *src, size_t size)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01014e8:	89 f0                	mov    %esi,%eax
		while (--size > 0 && *src != '\0')
f01014ea:	4a                   	dec    %edx
f01014eb:	74 0a                	je     f01014f7 <strlcpy+0x2b>
f01014ed:	8a 19                	mov    (%ecx),%bl
f01014ef:	84 db                	test   %bl,%bl
f01014f1:	75 ef                	jne    f01014e2 <strlcpy+0x16>
f01014f3:	89 c2                	mov    %eax,%edx
f01014f5:	eb 02                	jmp    f01014f9 <strlcpy+0x2d>
f01014f7:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01014f9:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01014fc:	29 f0                	sub    %esi,%eax
}
f01014fe:	5b                   	pop    %ebx
f01014ff:	5e                   	pop    %esi
f0101500:	5d                   	pop    %ebp
f0101501:	c3                   	ret    

f0101502 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101502:	55                   	push   %ebp
f0101503:	89 e5                	mov    %esp,%ebp
f0101505:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101508:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010150b:	eb 02                	jmp    f010150f <strcmp+0xd>
		p++, q++;
f010150d:	41                   	inc    %ecx
f010150e:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010150f:	8a 01                	mov    (%ecx),%al
f0101511:	84 c0                	test   %al,%al
f0101513:	74 04                	je     f0101519 <strcmp+0x17>
f0101515:	3a 02                	cmp    (%edx),%al
f0101517:	74 f4                	je     f010150d <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101519:	0f b6 c0             	movzbl %al,%eax
f010151c:	0f b6 12             	movzbl (%edx),%edx
f010151f:	29 d0                	sub    %edx,%eax
}
f0101521:	5d                   	pop    %ebp
f0101522:	c3                   	ret    

f0101523 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101523:	55                   	push   %ebp
f0101524:	89 e5                	mov    %esp,%ebp
f0101526:	53                   	push   %ebx
f0101527:	8b 45 08             	mov    0x8(%ebp),%eax
f010152a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010152d:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
f0101530:	eb 03                	jmp    f0101535 <strncmp+0x12>
		n--, p++, q++;
f0101532:	4a                   	dec    %edx
f0101533:	40                   	inc    %eax
f0101534:	41                   	inc    %ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101535:	85 d2                	test   %edx,%edx
f0101537:	74 14                	je     f010154d <strncmp+0x2a>
f0101539:	8a 18                	mov    (%eax),%bl
f010153b:	84 db                	test   %bl,%bl
f010153d:	74 04                	je     f0101543 <strncmp+0x20>
f010153f:	3a 19                	cmp    (%ecx),%bl
f0101541:	74 ef                	je     f0101532 <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101543:	0f b6 00             	movzbl (%eax),%eax
f0101546:	0f b6 11             	movzbl (%ecx),%edx
f0101549:	29 d0                	sub    %edx,%eax
f010154b:	eb 05                	jmp    f0101552 <strncmp+0x2f>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010154d:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101552:	5b                   	pop    %ebx
f0101553:	5d                   	pop    %ebp
f0101554:	c3                   	ret    

f0101555 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101555:	55                   	push   %ebp
f0101556:	89 e5                	mov    %esp,%ebp
f0101558:	8b 45 08             	mov    0x8(%ebp),%eax
f010155b:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010155e:	eb 05                	jmp    f0101565 <strchr+0x10>
		if (*s == c)
f0101560:	38 ca                	cmp    %cl,%dl
f0101562:	74 0c                	je     f0101570 <strchr+0x1b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101564:	40                   	inc    %eax
f0101565:	8a 10                	mov    (%eax),%dl
f0101567:	84 d2                	test   %dl,%dl
f0101569:	75 f5                	jne    f0101560 <strchr+0xb>
		if (*s == c)
			return (char *) s;
	return 0;
f010156b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101570:	5d                   	pop    %ebp
f0101571:	c3                   	ret    

f0101572 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101572:	55                   	push   %ebp
f0101573:	89 e5                	mov    %esp,%ebp
f0101575:	8b 45 08             	mov    0x8(%ebp),%eax
f0101578:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010157b:	eb 05                	jmp    f0101582 <strfind+0x10>
		if (*s == c)
f010157d:	38 ca                	cmp    %cl,%dl
f010157f:	74 07                	je     f0101588 <strfind+0x16>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101581:	40                   	inc    %eax
f0101582:	8a 10                	mov    (%eax),%dl
f0101584:	84 d2                	test   %dl,%dl
f0101586:	75 f5                	jne    f010157d <strfind+0xb>
		if (*s == c)
			break;
	return (char *) s;
}
f0101588:	5d                   	pop    %ebp
f0101589:	c3                   	ret    

f010158a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010158a:	55                   	push   %ebp
f010158b:	89 e5                	mov    %esp,%ebp
f010158d:	57                   	push   %edi
f010158e:	56                   	push   %esi
f010158f:	53                   	push   %ebx
f0101590:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101593:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101596:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101599:	85 c9                	test   %ecx,%ecx
f010159b:	74 30                	je     f01015cd <memset+0x43>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010159d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015a3:	75 25                	jne    f01015ca <memset+0x40>
f01015a5:	f6 c1 03             	test   $0x3,%cl
f01015a8:	75 20                	jne    f01015ca <memset+0x40>
		c &= 0xFF;
f01015aa:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015ad:	89 d3                	mov    %edx,%ebx
f01015af:	c1 e3 08             	shl    $0x8,%ebx
f01015b2:	89 d6                	mov    %edx,%esi
f01015b4:	c1 e6 18             	shl    $0x18,%esi
f01015b7:	89 d0                	mov    %edx,%eax
f01015b9:	c1 e0 10             	shl    $0x10,%eax
f01015bc:	09 f0                	or     %esi,%eax
f01015be:	09 d0                	or     %edx,%eax
f01015c0:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01015c2:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01015c5:	fc                   	cld    
f01015c6:	f3 ab                	rep stos %eax,%es:(%edi)
f01015c8:	eb 03                	jmp    f01015cd <memset+0x43>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015ca:	fc                   	cld    
f01015cb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015cd:	89 f8                	mov    %edi,%eax
f01015cf:	5b                   	pop    %ebx
f01015d0:	5e                   	pop    %esi
f01015d1:	5f                   	pop    %edi
f01015d2:	5d                   	pop    %ebp
f01015d3:	c3                   	ret    

f01015d4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015d4:	55                   	push   %ebp
f01015d5:	89 e5                	mov    %esp,%ebp
f01015d7:	57                   	push   %edi
f01015d8:	56                   	push   %esi
f01015d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01015dc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015df:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015e2:	39 c6                	cmp    %eax,%esi
f01015e4:	73 34                	jae    f010161a <memmove+0x46>
f01015e6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015e9:	39 d0                	cmp    %edx,%eax
f01015eb:	73 2d                	jae    f010161a <memmove+0x46>
		s += n;
		d += n;
f01015ed:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015f0:	f6 c2 03             	test   $0x3,%dl
f01015f3:	75 1b                	jne    f0101610 <memmove+0x3c>
f01015f5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015fb:	75 13                	jne    f0101610 <memmove+0x3c>
f01015fd:	f6 c1 03             	test   $0x3,%cl
f0101600:	75 0e                	jne    f0101610 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101602:	83 ef 04             	sub    $0x4,%edi
f0101605:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101608:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010160b:	fd                   	std    
f010160c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010160e:	eb 07                	jmp    f0101617 <memmove+0x43>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101610:	4f                   	dec    %edi
f0101611:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101614:	fd                   	std    
f0101615:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101617:	fc                   	cld    
f0101618:	eb 20                	jmp    f010163a <memmove+0x66>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010161a:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101620:	75 13                	jne    f0101635 <memmove+0x61>
f0101622:	a8 03                	test   $0x3,%al
f0101624:	75 0f                	jne    f0101635 <memmove+0x61>
f0101626:	f6 c1 03             	test   $0x3,%cl
f0101629:	75 0a                	jne    f0101635 <memmove+0x61>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010162b:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010162e:	89 c7                	mov    %eax,%edi
f0101630:	fc                   	cld    
f0101631:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101633:	eb 05                	jmp    f010163a <memmove+0x66>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101635:	89 c7                	mov    %eax,%edi
f0101637:	fc                   	cld    
f0101638:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010163a:	5e                   	pop    %esi
f010163b:	5f                   	pop    %edi
f010163c:	5d                   	pop    %ebp
f010163d:	c3                   	ret    

f010163e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010163e:	55                   	push   %ebp
f010163f:	89 e5                	mov    %esp,%ebp
f0101641:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101644:	8b 45 10             	mov    0x10(%ebp),%eax
f0101647:	89 44 24 08          	mov    %eax,0x8(%esp)
f010164b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010164e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101652:	8b 45 08             	mov    0x8(%ebp),%eax
f0101655:	89 04 24             	mov    %eax,(%esp)
f0101658:	e8 77 ff ff ff       	call   f01015d4 <memmove>
}
f010165d:	c9                   	leave  
f010165e:	c3                   	ret    

f010165f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010165f:	55                   	push   %ebp
f0101660:	89 e5                	mov    %esp,%ebp
f0101662:	57                   	push   %edi
f0101663:	56                   	push   %esi
f0101664:	53                   	push   %ebx
f0101665:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101668:	8b 75 0c             	mov    0xc(%ebp),%esi
f010166b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010166e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101673:	eb 16                	jmp    f010168b <memcmp+0x2c>
		if (*s1 != *s2)
f0101675:	8a 04 17             	mov    (%edi,%edx,1),%al
f0101678:	42                   	inc    %edx
f0101679:	8a 4c 16 ff          	mov    -0x1(%esi,%edx,1),%cl
f010167d:	38 c8                	cmp    %cl,%al
f010167f:	74 0a                	je     f010168b <memcmp+0x2c>
			return (int) *s1 - (int) *s2;
f0101681:	0f b6 c0             	movzbl %al,%eax
f0101684:	0f b6 c9             	movzbl %cl,%ecx
f0101687:	29 c8                	sub    %ecx,%eax
f0101689:	eb 09                	jmp    f0101694 <memcmp+0x35>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010168b:	39 da                	cmp    %ebx,%edx
f010168d:	75 e6                	jne    f0101675 <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010168f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101694:	5b                   	pop    %ebx
f0101695:	5e                   	pop    %esi
f0101696:	5f                   	pop    %edi
f0101697:	5d                   	pop    %ebp
f0101698:	c3                   	ret    

f0101699 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101699:	55                   	push   %ebp
f010169a:	89 e5                	mov    %esp,%ebp
f010169c:	8b 45 08             	mov    0x8(%ebp),%eax
f010169f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01016a2:	89 c2                	mov    %eax,%edx
f01016a4:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016a7:	eb 05                	jmp    f01016ae <memfind+0x15>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016a9:	38 08                	cmp    %cl,(%eax)
f01016ab:	74 05                	je     f01016b2 <memfind+0x19>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01016ad:	40                   	inc    %eax
f01016ae:	39 d0                	cmp    %edx,%eax
f01016b0:	72 f7                	jb     f01016a9 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01016b2:	5d                   	pop    %ebp
f01016b3:	c3                   	ret    

f01016b4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016b4:	55                   	push   %ebp
f01016b5:	89 e5                	mov    %esp,%ebp
f01016b7:	57                   	push   %edi
f01016b8:	56                   	push   %esi
f01016b9:	53                   	push   %ebx
f01016ba:	8b 55 08             	mov    0x8(%ebp),%edx
f01016bd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016c0:	eb 01                	jmp    f01016c3 <strtol+0xf>
		s++;
f01016c2:	42                   	inc    %edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016c3:	8a 02                	mov    (%edx),%al
f01016c5:	3c 20                	cmp    $0x20,%al
f01016c7:	74 f9                	je     f01016c2 <strtol+0xe>
f01016c9:	3c 09                	cmp    $0x9,%al
f01016cb:	74 f5                	je     f01016c2 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01016cd:	3c 2b                	cmp    $0x2b,%al
f01016cf:	75 08                	jne    f01016d9 <strtol+0x25>
		s++;
f01016d1:	42                   	inc    %edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01016d2:	bf 00 00 00 00       	mov    $0x0,%edi
f01016d7:	eb 13                	jmp    f01016ec <strtol+0x38>
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01016d9:	3c 2d                	cmp    $0x2d,%al
f01016db:	75 0a                	jne    f01016e7 <strtol+0x33>
		s++, neg = 1;
f01016dd:	8d 52 01             	lea    0x1(%edx),%edx
f01016e0:	bf 01 00 00 00       	mov    $0x1,%edi
f01016e5:	eb 05                	jmp    f01016ec <strtol+0x38>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01016e7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016ec:	85 db                	test   %ebx,%ebx
f01016ee:	74 05                	je     f01016f5 <strtol+0x41>
f01016f0:	83 fb 10             	cmp    $0x10,%ebx
f01016f3:	75 28                	jne    f010171d <strtol+0x69>
f01016f5:	8a 02                	mov    (%edx),%al
f01016f7:	3c 30                	cmp    $0x30,%al
f01016f9:	75 10                	jne    f010170b <strtol+0x57>
f01016fb:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016ff:	75 0a                	jne    f010170b <strtol+0x57>
		s += 2, base = 16;
f0101701:	83 c2 02             	add    $0x2,%edx
f0101704:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101709:	eb 12                	jmp    f010171d <strtol+0x69>
	else if (base == 0 && s[0] == '0')
f010170b:	85 db                	test   %ebx,%ebx
f010170d:	75 0e                	jne    f010171d <strtol+0x69>
f010170f:	3c 30                	cmp    $0x30,%al
f0101711:	75 05                	jne    f0101718 <strtol+0x64>
		s++, base = 8;
f0101713:	42                   	inc    %edx
f0101714:	b3 08                	mov    $0x8,%bl
f0101716:	eb 05                	jmp    f010171d <strtol+0x69>
	else if (base == 0)
		base = 10;
f0101718:	bb 0a 00 00 00       	mov    $0xa,%ebx
f010171d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101722:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101724:	8a 0a                	mov    (%edx),%cl
f0101726:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101729:	80 fb 09             	cmp    $0x9,%bl
f010172c:	77 08                	ja     f0101736 <strtol+0x82>
			dig = *s - '0';
f010172e:	0f be c9             	movsbl %cl,%ecx
f0101731:	83 e9 30             	sub    $0x30,%ecx
f0101734:	eb 1e                	jmp    f0101754 <strtol+0xa0>
		else if (*s >= 'a' && *s <= 'z')
f0101736:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0101739:	80 fb 19             	cmp    $0x19,%bl
f010173c:	77 08                	ja     f0101746 <strtol+0x92>
			dig = *s - 'a' + 10;
f010173e:	0f be c9             	movsbl %cl,%ecx
f0101741:	83 e9 57             	sub    $0x57,%ecx
f0101744:	eb 0e                	jmp    f0101754 <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
f0101746:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101749:	80 fb 19             	cmp    $0x19,%bl
f010174c:	77 12                	ja     f0101760 <strtol+0xac>
			dig = *s - 'A' + 10;
f010174e:	0f be c9             	movsbl %cl,%ecx
f0101751:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101754:	39 f1                	cmp    %esi,%ecx
f0101756:	7d 0c                	jge    f0101764 <strtol+0xb0>
			break;
		s++, val = (val * base) + dig;
f0101758:	42                   	inc    %edx
f0101759:	0f af c6             	imul   %esi,%eax
f010175c:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f010175e:	eb c4                	jmp    f0101724 <strtol+0x70>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101760:	89 c1                	mov    %eax,%ecx
f0101762:	eb 02                	jmp    f0101766 <strtol+0xb2>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101764:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101766:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010176a:	74 05                	je     f0101771 <strtol+0xbd>
		*endptr = (char *) s;
f010176c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010176f:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101771:	85 ff                	test   %edi,%edi
f0101773:	74 04                	je     f0101779 <strtol+0xc5>
f0101775:	89 c8                	mov    %ecx,%eax
f0101777:	f7 d8                	neg    %eax
}
f0101779:	5b                   	pop    %ebx
f010177a:	5e                   	pop    %esi
f010177b:	5f                   	pop    %edi
f010177c:	5d                   	pop    %ebp
f010177d:	c3                   	ret    
	...

f0101780 <__udivdi3>:
#endif

#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
f0101780:	55                   	push   %ebp
f0101781:	57                   	push   %edi
f0101782:	56                   	push   %esi
f0101783:	83 ec 10             	sub    $0x10,%esp
f0101786:	8b 74 24 20          	mov    0x20(%esp),%esi
f010178a:	8b 4c 24 28          	mov    0x28(%esp),%ecx
static inline __attribute__ ((__always_inline__))
#endif
UDWtype
__udivmoddi4 (UDWtype n, UDWtype d, UDWtype *rp)
{
  const DWunion nn = {.ll = n};
f010178e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101792:	8b 7c 24 24          	mov    0x24(%esp),%edi
  const DWunion dd = {.ll = d};
f0101796:	89 cd                	mov    %ecx,%ebp
f0101798:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  d1 = dd.s.high;
  n0 = nn.s.low;
  n1 = nn.s.high;

#if !UDIV_NEEDS_NORMALIZATION
  if (d1 == 0)
f010179c:	85 c0                	test   %eax,%eax
f010179e:	75 2c                	jne    f01017cc <__udivdi3+0x4c>
    {
      if (d0 > n1)
f01017a0:	39 f9                	cmp    %edi,%ecx
f01017a2:	77 68                	ja     f010180c <__udivdi3+0x8c>
	}
      else
	{
	  /* qq = NN / 0d */

	  if (d0 == 0)
f01017a4:	85 c9                	test   %ecx,%ecx
f01017a6:	75 0b                	jne    f01017b3 <__udivdi3+0x33>
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */
f01017a8:	b8 01 00 00 00       	mov    $0x1,%eax
f01017ad:	31 d2                	xor    %edx,%edx
f01017af:	f7 f1                	div    %ecx
f01017b1:	89 c1                	mov    %eax,%ecx

	  udiv_qrnnd (q1, n1, 0, n1, d0);
f01017b3:	31 d2                	xor    %edx,%edx
f01017b5:	89 f8                	mov    %edi,%eax
f01017b7:	f7 f1                	div    %ecx
f01017b9:	89 c7                	mov    %eax,%edi
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f01017bb:	89 f0                	mov    %esi,%eax
f01017bd:	f7 f1                	div    %ecx
f01017bf:	89 c6                	mov    %eax,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f01017c1:	89 f0                	mov    %esi,%eax
f01017c3:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f01017c5:	83 c4 10             	add    $0x10,%esp
f01017c8:	5e                   	pop    %esi
f01017c9:	5f                   	pop    %edi
f01017ca:	5d                   	pop    %ebp
f01017cb:	c3                   	ret    
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f01017cc:	39 f8                	cmp    %edi,%eax
f01017ce:	77 2c                	ja     f01017fc <__udivdi3+0x7c>
	}
      else
	{
	  /* 0q = NN / dd */

	  count_leading_zeros (bm, d1);
f01017d0:	0f bd f0             	bsr    %eax,%esi
	  if (bm == 0)
f01017d3:	83 f6 1f             	xor    $0x1f,%esi
f01017d6:	75 4c                	jne    f0101824 <__udivdi3+0xa4>

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f01017d8:	39 f8                	cmp    %edi,%eax
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f01017da:	bf 00 00 00 00       	mov    $0x0,%edi

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f01017df:	72 0a                	jb     f01017eb <__udivdi3+0x6b>
f01017e1:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f01017e5:	0f 87 ad 00 00 00    	ja     f0101898 <__udivdi3+0x118>
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f01017eb:	be 01 00 00 00       	mov    $0x1,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f01017f0:	89 f0                	mov    %esi,%eax
f01017f2:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f01017f4:	83 c4 10             	add    $0x10,%esp
f01017f7:	5e                   	pop    %esi
f01017f8:	5f                   	pop    %edi
f01017f9:	5d                   	pop    %ebp
f01017fa:	c3                   	ret    
f01017fb:	90                   	nop
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f01017fc:	31 ff                	xor    %edi,%edi
f01017fe:	31 f6                	xor    %esi,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0101800:	89 f0                	mov    %esi,%eax
f0101802:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0101804:	83 c4 10             	add    $0x10,%esp
f0101807:	5e                   	pop    %esi
f0101808:	5f                   	pop    %edi
f0101809:	5d                   	pop    %ebp
f010180a:	c3                   	ret    
f010180b:	90                   	nop
    {
      if (d0 > n1)
	{
	  /* 0q = nn / 0D */

	  udiv_qrnnd (q0, n0, n1, n0, d0);
f010180c:	89 fa                	mov    %edi,%edx
f010180e:	89 f0                	mov    %esi,%eax
f0101810:	f7 f1                	div    %ecx
f0101812:	89 c6                	mov    %eax,%esi
f0101814:	31 ff                	xor    %edi,%edi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0101816:	89 f0                	mov    %esi,%eax
f0101818:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f010181a:	83 c4 10             	add    $0x10,%esp
f010181d:	5e                   	pop    %esi
f010181e:	5f                   	pop    %edi
f010181f:	5d                   	pop    %ebp
f0101820:	c3                   	ret    
f0101821:	8d 76 00             	lea    0x0(%esi),%esi
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
f0101824:	89 f1                	mov    %esi,%ecx
f0101826:	d3 e0                	shl    %cl,%eax
f0101828:	89 44 24 0c          	mov    %eax,0xc(%esp)
	  else
	    {
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;
f010182c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101831:	29 f0                	sub    %esi,%eax

	      d1 = (d1 << bm) | (d0 >> b);
f0101833:	89 ea                	mov    %ebp,%edx
f0101835:	88 c1                	mov    %al,%cl
f0101837:	d3 ea                	shr    %cl,%edx
f0101839:	8b 4c 24 0c          	mov    0xc(%esp),%ecx
f010183d:	09 ca                	or     %ecx,%edx
f010183f:	89 54 24 08          	mov    %edx,0x8(%esp)
	      d0 = d0 << bm;
f0101843:	89 f1                	mov    %esi,%ecx
f0101845:	d3 e5                	shl    %cl,%ebp
f0101847:	89 6c 24 0c          	mov    %ebp,0xc(%esp)
	      n2 = n1 >> b;
f010184b:	89 fd                	mov    %edi,%ebp
f010184d:	88 c1                	mov    %al,%cl
f010184f:	d3 ed                	shr    %cl,%ebp
	      n1 = (n1 << bm) | (n0 >> b);
f0101851:	89 fa                	mov    %edi,%edx
f0101853:	89 f1                	mov    %esi,%ecx
f0101855:	d3 e2                	shl    %cl,%edx
f0101857:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010185b:	88 c1                	mov    %al,%cl
f010185d:	d3 ef                	shr    %cl,%edi
f010185f:	09 d7                	or     %edx,%edi
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
f0101861:	89 f8                	mov    %edi,%eax
f0101863:	89 ea                	mov    %ebp,%edx
f0101865:	f7 74 24 08          	divl   0x8(%esp)
f0101869:	89 d1                	mov    %edx,%ecx
f010186b:	89 c7                	mov    %eax,%edi
	      umul_ppmm (m1, m0, q0, d0);
f010186d:	f7 64 24 0c          	mull   0xc(%esp)

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0101871:	39 d1                	cmp    %edx,%ecx
f0101873:	72 17                	jb     f010188c <__udivdi3+0x10c>
f0101875:	74 09                	je     f0101880 <__udivdi3+0x100>
f0101877:	89 fe                	mov    %edi,%esi
f0101879:	31 ff                	xor    %edi,%edi
f010187b:	e9 41 ff ff ff       	jmp    f01017c1 <__udivdi3+0x41>

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
	      n0 = n0 << bm;
f0101880:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101884:	89 f1                	mov    %esi,%ecx
f0101886:	d3 e2                	shl    %cl,%edx

	      udiv_qrnnd (q0, n1, n2, n1, d1);
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0101888:	39 c2                	cmp    %eax,%edx
f010188a:	73 eb                	jae    f0101877 <__udivdi3+0xf7>
		{
		  q0--;
f010188c:	8d 77 ff             	lea    -0x1(%edi),%esi
		  sub_ddmmss (m1, m0, m1, m0, d1, d0);
f010188f:	31 ff                	xor    %edi,%edi
f0101891:	e9 2b ff ff ff       	jmp    f01017c1 <__udivdi3+0x41>
f0101896:	66 90                	xchg   %ax,%ax

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0101898:	31 f6                	xor    %esi,%esi
f010189a:	e9 22 ff ff ff       	jmp    f01017c1 <__udivdi3+0x41>
	...

f01018a0 <__umoddi3>:
#endif

#ifdef L_umoddi3
UDWtype
__umoddi3 (UDWtype u, UDWtype v)
{
f01018a0:	55                   	push   %ebp
f01018a1:	57                   	push   %edi
f01018a2:	56                   	push   %esi
f01018a3:	83 ec 20             	sub    $0x20,%esp
f01018a6:	8b 44 24 30          	mov    0x30(%esp),%eax
f01018aa:	8b 4c 24 38          	mov    0x38(%esp),%ecx
static inline __attribute__ ((__always_inline__))
#endif
UDWtype
__udivmoddi4 (UDWtype n, UDWtype d, UDWtype *rp)
{
  const DWunion nn = {.ll = n};
f01018ae:	89 44 24 14          	mov    %eax,0x14(%esp)
f01018b2:	8b 74 24 34          	mov    0x34(%esp),%esi
  const DWunion dd = {.ll = d};
f01018b6:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01018ba:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
  UWtype q0, q1;
  UWtype b, bm;

  d0 = dd.s.low;
  d1 = dd.s.high;
  n0 = nn.s.low;
f01018be:	89 c7                	mov    %eax,%edi
  n1 = nn.s.high;
f01018c0:	89 f2                	mov    %esi,%edx

#if !UDIV_NEEDS_NORMALIZATION
  if (d1 == 0)
f01018c2:	85 ed                	test   %ebp,%ebp
f01018c4:	75 16                	jne    f01018dc <__umoddi3+0x3c>
    {
      if (d0 > n1)
f01018c6:	39 f1                	cmp    %esi,%ecx
f01018c8:	0f 86 a6 00 00 00    	jbe    f0101974 <__umoddi3+0xd4>

	  if (d0 == 0)
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */

	  udiv_qrnnd (q1, n1, 0, n1, d0);
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f01018ce:	f7 f1                	div    %ecx

      if (rp != 0)
	{
	  rr.s.low = n0;
	  rr.s.high = 0;
	  *rp = rr.ll;
f01018d0:	89 d0                	mov    %edx,%eax
f01018d2:	31 d2                	xor    %edx,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f01018d4:	83 c4 20             	add    $0x20,%esp
f01018d7:	5e                   	pop    %esi
f01018d8:	5f                   	pop    %edi
f01018d9:	5d                   	pop    %ebp
f01018da:	c3                   	ret    
f01018db:	90                   	nop
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f01018dc:	39 f5                	cmp    %esi,%ebp
f01018de:	0f 87 ac 00 00 00    	ja     f0101990 <__umoddi3+0xf0>
	}
      else
	{
	  /* 0q = NN / dd */

	  count_leading_zeros (bm, d1);
f01018e4:	0f bd c5             	bsr    %ebp,%eax
	  if (bm == 0)
f01018e7:	83 f0 1f             	xor    $0x1f,%eax
f01018ea:	89 44 24 10          	mov    %eax,0x10(%esp)
f01018ee:	0f 84 a8 00 00 00    	je     f010199c <__umoddi3+0xfc>
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
f01018f4:	8a 4c 24 10          	mov    0x10(%esp),%cl
f01018f8:	d3 e5                	shl    %cl,%ebp
	  else
	    {
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;
f01018fa:	bf 20 00 00 00       	mov    $0x20,%edi
f01018ff:	2b 7c 24 10          	sub    0x10(%esp),%edi

	      d1 = (d1 << bm) | (d0 >> b);
f0101903:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101907:	89 f9                	mov    %edi,%ecx
f0101909:	d3 e8                	shr    %cl,%eax
f010190b:	09 e8                	or     %ebp,%eax
f010190d:	89 44 24 18          	mov    %eax,0x18(%esp)
	      d0 = d0 << bm;
f0101911:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101915:	8a 4c 24 10          	mov    0x10(%esp),%cl
f0101919:	d3 e0                	shl    %cl,%eax
f010191b:	89 44 24 0c          	mov    %eax,0xc(%esp)
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
f010191f:	89 f2                	mov    %esi,%edx
f0101921:	d3 e2                	shl    %cl,%edx
	      n0 = n0 << bm;
f0101923:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101927:	d3 e0                	shl    %cl,%eax
f0101929:	89 44 24 1c          	mov    %eax,0x1c(%esp)
	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
f010192d:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101931:	89 f9                	mov    %edi,%ecx
f0101933:	d3 e8                	shr    %cl,%eax
f0101935:	09 d0                	or     %edx,%eax

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
f0101937:	d3 ee                	shr    %cl,%esi
	      n1 = (n1 << bm) | (n0 >> b);
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
f0101939:	89 f2                	mov    %esi,%edx
f010193b:	f7 74 24 18          	divl   0x18(%esp)
f010193f:	89 d6                	mov    %edx,%esi
	      umul_ppmm (m1, m0, q0, d0);
f0101941:	f7 64 24 0c          	mull   0xc(%esp)
f0101945:	89 c5                	mov    %eax,%ebp
f0101947:	89 d1                	mov    %edx,%ecx

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0101949:	39 d6                	cmp    %edx,%esi
f010194b:	72 67                	jb     f01019b4 <__umoddi3+0x114>
f010194d:	74 75                	je     f01019c4 <__umoddi3+0x124>
	      q1 = 0;

	      /* Remainder in (n1n0 - m1m0) >> bm.  */
	      if (rp != 0)
		{
		  sub_ddmmss (n1, n0, n1, n0, m1, m0);
f010194f:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0101953:	29 e8                	sub    %ebp,%eax
f0101955:	19 ce                	sbb    %ecx,%esi
		  rr.s.low = (n1 << b) | (n0 >> bm);
f0101957:	8a 4c 24 10          	mov    0x10(%esp),%cl
f010195b:	d3 e8                	shr    %cl,%eax
f010195d:	89 f2                	mov    %esi,%edx
f010195f:	89 f9                	mov    %edi,%ecx
f0101961:	d3 e2                	shl    %cl,%edx
		  rr.s.high = n1 >> bm;
		  *rp = rr.ll;
f0101963:	09 d0                	or     %edx,%eax
f0101965:	89 f2                	mov    %esi,%edx
f0101967:	8a 4c 24 10          	mov    0x10(%esp),%cl
f010196b:	d3 ea                	shr    %cl,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f010196d:	83 c4 20             	add    $0x20,%esp
f0101970:	5e                   	pop    %esi
f0101971:	5f                   	pop    %edi
f0101972:	5d                   	pop    %ebp
f0101973:	c3                   	ret    
	}
      else
	{
	  /* qq = NN / 0d */

	  if (d0 == 0)
f0101974:	85 c9                	test   %ecx,%ecx
f0101976:	75 0b                	jne    f0101983 <__umoddi3+0xe3>
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */
f0101978:	b8 01 00 00 00       	mov    $0x1,%eax
f010197d:	31 d2                	xor    %edx,%edx
f010197f:	f7 f1                	div    %ecx
f0101981:	89 c1                	mov    %eax,%ecx

	  udiv_qrnnd (q1, n1, 0, n1, d0);
f0101983:	89 f0                	mov    %esi,%eax
f0101985:	31 d2                	xor    %edx,%edx
f0101987:	f7 f1                	div    %ecx
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f0101989:	89 f8                	mov    %edi,%eax
f010198b:	e9 3e ff ff ff       	jmp    f01018ce <__umoddi3+0x2e>
	  /* Remainder in n1n0.  */
	  if (rp != 0)
	    {
	      rr.s.low = n0;
	      rr.s.high = n1;
	      *rp = rr.ll;
f0101990:	89 f2                	mov    %esi,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0101992:	83 c4 20             	add    $0x20,%esp
f0101995:	5e                   	pop    %esi
f0101996:	5f                   	pop    %edi
f0101997:	5d                   	pop    %ebp
f0101998:	c3                   	ret    
f0101999:	8d 76 00             	lea    0x0(%esi),%esi

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f010199c:	39 f5                	cmp    %esi,%ebp
f010199e:	72 04                	jb     f01019a4 <__umoddi3+0x104>
f01019a0:	39 f9                	cmp    %edi,%ecx
f01019a2:	77 06                	ja     f01019aa <__umoddi3+0x10a>
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f01019a4:	89 f2                	mov    %esi,%edx
f01019a6:	29 cf                	sub    %ecx,%edi
f01019a8:	19 ea                	sbb    %ebp,%edx

	      if (rp != 0)
		{
		  rr.s.low = n0;
		  rr.s.high = n1;
		  *rp = rr.ll;
f01019aa:	89 f8                	mov    %edi,%eax
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f01019ac:	83 c4 20             	add    $0x20,%esp
f01019af:	5e                   	pop    %esi
f01019b0:	5f                   	pop    %edi
f01019b1:	5d                   	pop    %ebp
f01019b2:	c3                   	ret    
f01019b3:	90                   	nop
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
		{
		  q0--;
		  sub_ddmmss (m1, m0, m1, m0, d1, d0);
f01019b4:	89 d1                	mov    %edx,%ecx
f01019b6:	89 c5                	mov    %eax,%ebp
f01019b8:	2b 6c 24 0c          	sub    0xc(%esp),%ebp
f01019bc:	1b 4c 24 18          	sbb    0x18(%esp),%ecx
f01019c0:	eb 8d                	jmp    f010194f <__umoddi3+0xaf>
f01019c2:	66 90                	xchg   %ax,%ax
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f01019c4:	39 44 24 1c          	cmp    %eax,0x1c(%esp)
f01019c8:	72 ea                	jb     f01019b4 <__umoddi3+0x114>
f01019ca:	89 f1                	mov    %esi,%ecx
f01019cc:	eb 81                	jmp    f010194f <__umoddi3+0xaf>
