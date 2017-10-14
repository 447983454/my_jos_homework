
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
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

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
f010004e:	c7 04 24 80 1a 10 f0 	movl   $0xf0101a80,(%esp)
f0100055:	e8 9d 09 00 00       	call   f01009f7 <cprintf>
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
f0100082:	e8 1b 07 00 00       	call   f01007a2 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 9c 1a 10 f0 	movl   $0xf0101a9c,(%esp)
f0100092:	e8 60 09 00 00       	call   f01009f7 <cprintf>
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
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 da 14 00 00       	call   f010159f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 b7 1a 10 f0 	movl   $0xf0101ab7,(%esp)
f01000d9:	e8 19 09 00 00       	call   f01009f7 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 79 07 00 00       	call   f010086f <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 d2 1a 10 f0 	movl   $0xf0101ad2,(%esp)
f010012c:	e8 c6 08 00 00       	call   f01009f7 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 87 08 00 00       	call   f01009c4 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 0e 1b 10 f0 	movl   $0xf0101b0e,(%esp)
f0100144:	e8 ae 08 00 00       	call   f01009f7 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 1a 07 00 00       	call   f010086f <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ea 1a 10 f0 	movl   $0xf0101aea,(%esp)
f0100176:	e8 7c 08 00 00       	call   f01009f7 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 3a 08 00 00       	call   f01009c4 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 0e 1b 10 f0 	movl   $0xf0101b0e,(%esp)
f0100191:	e8 61 08 00 00       	call   f01009f7 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 44 25 11 f0    	mov    %ecx,0xf0112544
f01001d9:	88 90 40 23 11 f0    	mov    %dl,-0xfeedcc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 60 1c 10 f0 	movzbl -0xfefe3a0(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 60 1c 10 f0 	movzbl -0xfefe3a0(%edx),%eax
f0100289:	0b 05 20 23 11 f0    	or     0xf0112320,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a 60 1b 10 f0 	movzbl -0xfefe4a0(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 20 23 11 f0       	mov    %eax,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 40 1b 10 f0 	mov    -0xfefe4c0(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 04 1b 10 f0 	movl   $0xf0101b04,(%esp)
f01002e9:	e8 09 07 00 00       	call   f01009f7 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100314:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100319:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 21                	jne    f010033f <cons_putc+0x36>
f010031e:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100323:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100328:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032d:	89 ca                	mov    %ecx,%edx
f010032f:	ec                   	in     (%dx),%al
f0100330:	ec                   	in     (%dx),%al
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	89 f2                	mov    %esi,%edx
f0100335:	ec                   	in     (%dx),%al
f0100336:	a8 20                	test   $0x20,%al
f0100338:	75 05                	jne    f010033f <cons_putc+0x36>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033a:	83 eb 01             	sub    $0x1,%ebx
f010033d:	75 ee                	jne    f010032d <cons_putc+0x24>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f010033f:	89 f8                	mov    %edi,%eax
f0100341:	0f b6 c0             	movzbl %al,%eax
f0100344:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100347:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010034c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034d:	b2 79                	mov    $0x79,%dl
f010034f:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100350:	84 c0                	test   %al,%al
f0100352:	78 21                	js     f0100375 <cons_putc+0x6c>
f0100354:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100359:	b9 84 00 00 00       	mov    $0x84,%ecx
f010035e:	be 79 03 00 00       	mov    $0x379,%esi
f0100363:	89 ca                	mov    %ecx,%edx
f0100365:	ec                   	in     (%dx),%al
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	ec                   	in     (%dx),%al
f0100369:	89 f2                	mov    %esi,%edx
f010036b:	ec                   	in     (%dx),%al
f010036c:	84 c0                	test   %al,%al
f010036e:	78 05                	js     f0100375 <cons_putc+0x6c>
f0100370:	83 eb 01             	sub    $0x1,%ebx
f0100373:	75 ee                	jne    f0100363 <cons_putc+0x5a>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100375:	ba 78 03 00 00       	mov    $0x378,%edx
f010037a:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010037e:	ee                   	out    %al,(%dx)
f010037f:	b2 7a                	mov    $0x7a,%dl
f0100381:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100386:	ee                   	out    %al,(%dx)
f0100387:	b8 08 00 00 00       	mov    $0x8,%eax
f010038c:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010038d:	89 fa                	mov    %edi,%edx
f010038f:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100395:	89 f8                	mov    %edi,%eax
f0100397:	80 cc 07             	or     $0x7,%ah
f010039a:	85 d2                	test   %edx,%edx
f010039c:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010039f:	89 f8                	mov    %edi,%eax
f01003a1:	0f b6 c0             	movzbl %al,%eax
f01003a4:	83 f8 09             	cmp    $0x9,%eax
f01003a7:	74 79                	je     f0100422 <cons_putc+0x119>
f01003a9:	83 f8 09             	cmp    $0x9,%eax
f01003ac:	7f 0a                	jg     f01003b8 <cons_putc+0xaf>
f01003ae:	83 f8 08             	cmp    $0x8,%eax
f01003b1:	74 19                	je     f01003cc <cons_putc+0xc3>
f01003b3:	e9 9e 00 00 00       	jmp    f0100456 <cons_putc+0x14d>
f01003b8:	83 f8 0a             	cmp    $0xa,%eax
f01003bb:	90                   	nop
f01003bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01003c0:	74 3a                	je     f01003fc <cons_putc+0xf3>
f01003c2:	83 f8 0d             	cmp    $0xd,%eax
f01003c5:	74 3d                	je     f0100404 <cons_putc+0xfb>
f01003c7:	e9 8a 00 00 00       	jmp    f0100456 <cons_putc+0x14d>
	case '\b':
		if (crt_pos > 0) {
f01003cc:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003d3:	66 85 c0             	test   %ax,%ax
f01003d6:	0f 84 e5 00 00 00    	je     f01004c1 <cons_putc+0x1b8>
			crt_pos--;
f01003dc:	83 e8 01             	sub    $0x1,%eax
f01003df:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e5:	0f b7 c0             	movzwl %ax,%eax
f01003e8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ed:	83 cf 20             	or     $0x20,%edi
f01003f0:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f01003f6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003fa:	eb 78                	jmp    f0100474 <cons_putc+0x16b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003fc:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f0100403:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100404:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010040b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100411:	c1 e8 16             	shr    $0x16,%eax
f0100414:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100417:	c1 e0 04             	shl    $0x4,%eax
f010041a:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f0100420:	eb 52                	jmp    f0100474 <cons_putc+0x16b>
		break;
	case '\t':
		cons_putc(' ');
f0100422:	b8 20 00 00 00       	mov    $0x20,%eax
f0100427:	e8 dd fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010042c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100431:	e8 d3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100436:	b8 20 00 00 00       	mov    $0x20,%eax
f010043b:	e8 c9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100440:	b8 20 00 00 00       	mov    $0x20,%eax
f0100445:	e8 bf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010044a:	b8 20 00 00 00       	mov    $0x20,%eax
f010044f:	e8 b5 fe ff ff       	call   f0100309 <cons_putc>
f0100454:	eb 1e                	jmp    f0100474 <cons_putc+0x16b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100456:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010045d:	8d 50 01             	lea    0x1(%eax),%edx
f0100460:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
f0100467:	0f b7 c0             	movzwl %ax,%eax
f010046a:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100470:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100474:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f010047b:	cf 07 
f010047d:	76 42                	jbe    f01004c1 <cons_putc+0x1b8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010047f:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f0100484:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010048b:	00 
f010048c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100492:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100496:	89 04 24             	mov    %eax,(%esp)
f0100499:	e8 4e 11 00 00       	call   f01015ec <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010049e:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004a4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004a9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004af:	83 c0 01             	add    $0x1,%eax
f01004b2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004b7:	75 f0                	jne    f01004a9 <cons_putc+0x1a0>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b9:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f01004c0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004c1:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01004c7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004cc:	89 ca                	mov    %ecx,%edx
f01004ce:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004cf:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004d6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d9:	89 d8                	mov    %ebx,%eax
f01004db:	66 c1 e8 08          	shr    $0x8,%ax
f01004df:	89 f2                	mov    %esi,%edx
f01004e1:	ee                   	out    %al,(%dx)
f01004e2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e7:	89 ca                	mov    %ecx,%edx
f01004e9:	ee                   	out    %al,(%dx)
f01004ea:	89 d8                	mov    %ebx,%eax
f01004ec:	89 f2                	mov    %esi,%edx
f01004ee:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ef:	83 c4 1c             	add    $0x1c,%esp
f01004f2:	5b                   	pop    %ebx
f01004f3:	5e                   	pop    %esi
f01004f4:	5f                   	pop    %edi
f01004f5:	5d                   	pop    %ebp
f01004f6:	c3                   	ret    

f01004f7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f7:	83 3d 54 25 11 f0 00 	cmpl   $0x0,0xf0112554
f01004fe:	74 11                	je     f0100511 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100500:	55                   	push   %ebp
f0100501:	89 e5                	mov    %esp,%ebp
f0100503:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100506:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f010050b:	e8 ac fc ff ff       	call   f01001bc <cons_intr>
}
f0100510:	c9                   	leave  
f0100511:	f3 c3                	repz ret 

f0100513 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100513:	55                   	push   %ebp
f0100514:	89 e5                	mov    %esp,%ebp
f0100516:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100519:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010051e:	e8 99 fc ff ff       	call   f01001bc <cons_intr>
}
f0100523:	c9                   	leave  
f0100524:	c3                   	ret    

f0100525 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100525:	55                   	push   %ebp
f0100526:	89 e5                	mov    %esp,%ebp
f0100528:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010052b:	e8 c7 ff ff ff       	call   f01004f7 <serial_intr>
	kbd_intr();
f0100530:	e8 de ff ff ff       	call   f0100513 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100535:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f010053a:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f0100540:	74 26                	je     f0100568 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100542:	8d 50 01             	lea    0x1(%eax),%edx
f0100545:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f010054b:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100552:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100554:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055a:	75 11                	jne    f010056d <cons_getc+0x48>
			cons.rpos = 0;
f010055c:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f0100563:	00 00 00 
f0100566:	eb 05                	jmp    f010056d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100568:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010056d:	c9                   	leave  
f010056e:	c3                   	ret    

f010056f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056f:	55                   	push   %ebp
f0100570:	89 e5                	mov    %esp,%ebp
f0100572:	57                   	push   %edi
f0100573:	56                   	push   %esi
f0100574:	53                   	push   %ebx
f0100575:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100578:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100586:	5a a5 
	if (*cp != 0xA55A) {
f0100588:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100593:	74 11                	je     f01005a6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100595:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f010059c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005a4:	eb 16                	jmp    f01005bc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005ad:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f01005b4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005bc:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01005c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ca:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	89 da                	mov    %ebx,%edx
f01005cf:	ec                   	in     (%dx),%al
f01005d0:	0f b6 f0             	movzbl %al,%esi
f01005d3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005db:	89 ca                	mov    %ecx,%edx
f01005dd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005de:	89 da                	mov    %ebx,%edx
f01005e0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005e1:	89 3d 4c 25 11 f0    	mov    %edi,0xf011254c
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e7:	0f b6 d8             	movzbl %al,%ebx
f01005ea:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005ec:	66 89 35 48 25 11 f0 	mov    %si,0xf0112548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fd:	89 f2                	mov    %esi,%edx
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b2 fb                	mov    $0xfb,%dl
f0100602:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100607:	ee                   	out    %al,(%dx)
f0100608:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100612:	89 da                	mov    %ebx,%edx
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 f9                	mov    $0xf9,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fb                	mov    $0xfb,%dl
f010061f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 fc                	mov    $0xfc,%dl
f0100627:	b8 00 00 00 00       	mov    $0x0,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 f9                	mov    $0xf9,%dl
f010062f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100634:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100635:	b2 fd                	mov    $0xfd,%dl
f0100637:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100638:	3c ff                	cmp    $0xff,%al
f010063a:	0f 95 c1             	setne  %cl
f010063d:	0f b6 c9             	movzbl %cl,%ecx
f0100640:	89 0d 54 25 11 f0    	mov    %ecx,0xf0112554
f0100646:	89 f2                	mov    %esi,%edx
f0100648:	ec                   	in     (%dx),%al
f0100649:	89 da                	mov    %ebx,%edx
f010064b:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010064c:	85 c9                	test   %ecx,%ecx
f010064e:	75 0c                	jne    f010065c <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f0100650:	c7 04 24 10 1b 10 f0 	movl   $0xf0101b10,(%esp)
f0100657:	e8 9b 03 00 00       	call   f01009f7 <cprintf>
}
f010065c:	83 c4 1c             	add    $0x1c,%esp
f010065f:	5b                   	pop    %ebx
f0100660:	5e                   	pop    %esi
f0100661:	5f                   	pop    %edi
f0100662:	5d                   	pop    %ebp
f0100663:	c3                   	ret    

f0100664 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100664:	55                   	push   %ebp
f0100665:	89 e5                	mov    %esp,%ebp
f0100667:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010066a:	8b 45 08             	mov    0x8(%ebp),%eax
f010066d:	e8 97 fc ff ff       	call   f0100309 <cons_putc>
}
f0100672:	c9                   	leave  
f0100673:	c3                   	ret    

f0100674 <getchar>:

int
getchar(void)
{
f0100674:	55                   	push   %ebp
f0100675:	89 e5                	mov    %esp,%ebp
f0100677:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010067a:	e8 a6 fe ff ff       	call   f0100525 <cons_getc>
f010067f:	85 c0                	test   %eax,%eax
f0100681:	74 f7                	je     f010067a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100683:	c9                   	leave  
f0100684:	c3                   	ret    

f0100685 <iscons>:

int
iscons(int fdnum)
{
f0100685:	55                   	push   %ebp
f0100686:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100688:	b8 01 00 00 00       	mov    $0x1,%eax
f010068d:	5d                   	pop    %ebp
f010068e:	c3                   	ret    
f010068f:	90                   	nop

f0100690 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100696:	c7 44 24 08 60 1d 10 	movl   $0xf0101d60,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 7e 1d 10 	movl   $0xf0101d7e,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 83 1d 10 f0 	movl   $0xf0101d83,(%esp)
f01006ad:	e8 45 03 00 00       	call   f01009f7 <cprintf>
f01006b2:	c7 44 24 08 08 1e 10 	movl   $0xf0101e08,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 8c 1d 10 	movl   $0xf0101d8c,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 83 1d 10 f0 	movl   $0xf0101d83,(%esp)
f01006c9:	e8 29 03 00 00       	call   f01009f7 <cprintf>
f01006ce:	c7 44 24 08 30 1e 10 	movl   $0xf0101e30,0x8(%esp)
f01006d5:	f0 
f01006d6:	c7 44 24 04 95 1d 10 	movl   $0xf0101d95,0x4(%esp)
f01006dd:	f0 
f01006de:	c7 04 24 83 1d 10 f0 	movl   $0xf0101d83,(%esp)
f01006e5:	e8 0d 03 00 00       	call   f01009f7 <cprintf>
	return 0;
}
f01006ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ef:	c9                   	leave  
f01006f0:	c3                   	ret    

f01006f1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006f1:	55                   	push   %ebp
f01006f2:	89 e5                	mov    %esp,%ebp
f01006f4:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006f7:	c7 04 24 9f 1d 10 f0 	movl   $0xf0101d9f,(%esp)
f01006fe:	e8 f4 02 00 00       	call   f01009f7 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100703:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010070a:	00 
f010070b:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100712:	f0 
f0100713:	c7 04 24 5c 1e 10 f0 	movl   $0xf0101e5c,(%esp)
f010071a:	e8 d8 02 00 00       	call   f01009f7 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010071f:	c7 44 24 08 67 1a 10 	movl   $0x101a67,0x8(%esp)
f0100726:	00 
f0100727:	c7 44 24 04 67 1a 10 	movl   $0xf0101a67,0x4(%esp)
f010072e:	f0 
f010072f:	c7 04 24 80 1e 10 f0 	movl   $0xf0101e80,(%esp)
f0100736:	e8 bc 02 00 00       	call   f01009f7 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073b:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100742:	00 
f0100743:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010074a:	f0 
f010074b:	c7 04 24 a4 1e 10 f0 	movl   $0xf0101ea4,(%esp)
f0100752:	e8 a0 02 00 00       	call   f01009f7 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100757:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f010075e:	00 
f010075f:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f0100766:	f0 
f0100767:	c7 04 24 c8 1e 10 f0 	movl   $0xf0101ec8,(%esp)
f010076e:	e8 84 02 00 00       	call   f01009f7 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100773:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100778:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010077d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100783:	85 c0                	test   %eax,%eax
f0100785:	0f 48 c2             	cmovs  %edx,%eax
f0100788:	c1 f8 0a             	sar    $0xa,%eax
f010078b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078f:	c7 04 24 ec 1e 10 f0 	movl   $0xf0101eec,(%esp)
f0100796:	e8 5c 02 00 00       	call   f01009f7 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010079b:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a0:	c9                   	leave  
f01007a1:	c3                   	ret    

f01007a2 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007a2:	55                   	push   %ebp
f01007a3:	89 e5                	mov    %esp,%ebp
f01007a5:	57                   	push   %edi
f01007a6:	56                   	push   %esi
f01007a7:	53                   	push   %ebx
f01007a8:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
	cprintf("Stack Backteace:\n");
f01007ab:	c7 04 24 b8 1d 10 f0 	movl   $0xf0101db8,(%esp)
f01007b2:	e8 40 02 00 00       	call   f01009f7 <cprintf>

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007b7:	89 e8                	mov    %ebp,%eax
f01007b9:	89 c3                	mov    %eax,%ebx

	//cprintf("eip %08x\n", eip_r);
	//cprintf("eip %08x\n", *(uint32_t*)(ebp+4));

	int i=5;
	while(ebp!=-1){
f01007bb:	83 f8 ff             	cmp    $0xffffffff,%eax
f01007be:	0f 84 9e 00 00 00    	je     f0100862 <mon_backtrace+0xc0>
		eip=ebp+4;
f01007c4:	8d 7b 04             	lea    0x4(%ebx),%edi
f01007c7:	8d 43 08             	lea    0x8(%ebx),%eax
f01007ca:	8d 4b 1c             	lea    0x1c(%ebx),%ecx
f01007cd:	8d 75 d4             	lea    -0x2c(%ebp),%esi
f01007d0:	89 f2                	mov    %esi,%edx
f01007d2:	29 da                	sub    %ebx,%edx
		int ii=1;
		while(ii<=5){
			args[ii-1]=*(uint32_t*)(ii*4+eip);
f01007d4:	8b 30                	mov    (%eax),%esi
f01007d6:	89 74 02 f8          	mov    %esi,-0x8(%edx,%eax,1)
f01007da:	83 c0 04             	add    $0x4,%eax

	int i=5;
	while(ebp!=-1){
		eip=ebp+4;
		int ii=1;
		while(ii<=5){
f01007dd:	39 c8                	cmp    %ecx,%eax
f01007df:	75 f3                	jne    f01007d4 <mon_backtrace+0x32>
			args[ii-1]=*(uint32_t*)(ii*4+eip);
			ii++;
		}
		eip=*(uint32_t*)(eip);
f01007e1:	8b 07                	mov    (%edi),%eax
		if(ebp==0){
f01007e3:	85 db                	test   %ebx,%ebx
f01007e5:	74 40                	je     f0100827 <mon_backtrace+0x85>
			ebp=-1;
		}else
			ebp=*(uint32_t*)(ebp);
f01007e7:	8b 1b                	mov    (%ebx),%ebx
		cprintf("ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",ebp,eip,args[0],args[1], args[2], args[3], args[4]);
f01007e9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01007ec:	89 54 24 1c          	mov    %edx,0x1c(%esp)
f01007f0:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01007f3:	89 54 24 18          	mov    %edx,0x18(%esp)
f01007f7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01007fa:	89 54 24 14          	mov    %edx,0x14(%esp)
f01007fe:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100801:	89 54 24 10          	mov    %edx,0x10(%esp)
f0100805:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100808:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010080c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100810:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100814:	c7 04 24 18 1f 10 f0 	movl   $0xf0101f18,(%esp)
f010081b:	e8 d7 01 00 00       	call   f01009f7 <cprintf>

	//cprintf("eip %08x\n", eip_r);
	//cprintf("eip %08x\n", *(uint32_t*)(ebp+4));

	int i=5;
	while(ebp!=-1){
f0100820:	83 fb ff             	cmp    $0xffffffff,%ebx
f0100823:	75 9f                	jne    f01007c4 <mon_backtrace+0x22>
f0100825:	eb 3b                	jmp    f0100862 <mon_backtrace+0xc0>
		eip=*(uint32_t*)(eip);
		if(ebp==0){
			ebp=-1;
		}else
			ebp=*(uint32_t*)(ebp);
		cprintf("ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",ebp,eip,args[0],args[1], args[2], args[3], args[4]);
f0100827:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010082a:	89 54 24 1c          	mov    %edx,0x1c(%esp)
f010082e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100831:	89 54 24 18          	mov    %edx,0x18(%esp)
f0100835:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100838:	89 54 24 14          	mov    %edx,0x14(%esp)
f010083c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010083f:	89 54 24 10          	mov    %edx,0x10(%esp)
f0100843:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100846:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010084a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010084e:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
f0100855:	ff 
f0100856:	c7 04 24 18 1f 10 f0 	movl   $0xf0101f18,(%esp)
f010085d:	e8 95 01 00 00       	call   f01009f7 <cprintf>
		i--;
	}
	return 0;
}
f0100862:	b8 00 00 00 00       	mov    $0x0,%eax
f0100867:	83 c4 4c             	add    $0x4c,%esp
f010086a:	5b                   	pop    %ebx
f010086b:	5e                   	pop    %esi
f010086c:	5f                   	pop    %edi
f010086d:	5d                   	pop    %ebp
f010086e:	c3                   	ret    

f010086f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010086f:	55                   	push   %ebp
f0100870:	89 e5                	mov    %esp,%ebp
f0100872:	57                   	push   %edi
f0100873:	56                   	push   %esi
f0100874:	53                   	push   %ebx
f0100875:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100878:	c7 04 24 4c 1f 10 f0 	movl   $0xf0101f4c,(%esp)
f010087f:	e8 73 01 00 00       	call   f01009f7 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100884:	c7 04 24 70 1f 10 f0 	movl   $0xf0101f70,(%esp)
f010088b:	e8 67 01 00 00       	call   f01009f7 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100890:	c7 04 24 ca 1d 10 f0 	movl   $0xf0101dca,(%esp)
f0100897:	e8 54 0a 00 00       	call   f01012f0 <readline>
f010089c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010089e:	85 c0                	test   %eax,%eax
f01008a0:	74 ee                	je     f0100890 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008a2:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008a9:	be 00 00 00 00       	mov    $0x0,%esi
f01008ae:	eb 0a                	jmp    f01008ba <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008b0:	c6 03 00             	movb   $0x0,(%ebx)
f01008b3:	89 f7                	mov    %esi,%edi
f01008b5:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008b8:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008ba:	0f b6 03             	movzbl (%ebx),%eax
f01008bd:	84 c0                	test   %al,%al
f01008bf:	74 6a                	je     f010092b <monitor+0xbc>
f01008c1:	0f be c0             	movsbl %al,%eax
f01008c4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c8:	c7 04 24 ce 1d 10 f0 	movl   $0xf0101dce,(%esp)
f01008cf:	e8 6a 0c 00 00       	call   f010153e <strchr>
f01008d4:	85 c0                	test   %eax,%eax
f01008d6:	75 d8                	jne    f01008b0 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008d8:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008db:	74 4e                	je     f010092b <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008dd:	83 fe 0f             	cmp    $0xf,%esi
f01008e0:	75 16                	jne    f01008f8 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008e2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008e9:	00 
f01008ea:	c7 04 24 d3 1d 10 f0 	movl   $0xf0101dd3,(%esp)
f01008f1:	e8 01 01 00 00       	call   f01009f7 <cprintf>
f01008f6:	eb 98                	jmp    f0100890 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008f8:	8d 7e 01             	lea    0x1(%esi),%edi
f01008fb:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f01008ff:	0f b6 03             	movzbl (%ebx),%eax
f0100902:	84 c0                	test   %al,%al
f0100904:	75 0c                	jne    f0100912 <monitor+0xa3>
f0100906:	eb b0                	jmp    f01008b8 <monitor+0x49>
			buf++;
f0100908:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010090b:	0f b6 03             	movzbl (%ebx),%eax
f010090e:	84 c0                	test   %al,%al
f0100910:	74 a6                	je     f01008b8 <monitor+0x49>
f0100912:	0f be c0             	movsbl %al,%eax
f0100915:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100919:	c7 04 24 ce 1d 10 f0 	movl   $0xf0101dce,(%esp)
f0100920:	e8 19 0c 00 00       	call   f010153e <strchr>
f0100925:	85 c0                	test   %eax,%eax
f0100927:	74 df                	je     f0100908 <monitor+0x99>
f0100929:	eb 8d                	jmp    f01008b8 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010092b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100932:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100933:	85 f6                	test   %esi,%esi
f0100935:	0f 84 55 ff ff ff    	je     f0100890 <monitor+0x21>
f010093b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100940:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100943:	8b 04 85 a0 1f 10 f0 	mov    -0xfefe060(,%eax,4),%eax
f010094a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010094e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100951:	89 04 24             	mov    %eax,(%esp)
f0100954:	e8 61 0b 00 00       	call   f01014ba <strcmp>
f0100959:	85 c0                	test   %eax,%eax
f010095b:	75 24                	jne    f0100981 <monitor+0x112>
			return commands[i].func(argc, argv, tf);
f010095d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100960:	8b 55 08             	mov    0x8(%ebp),%edx
f0100963:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100967:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010096a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010096e:	89 34 24             	mov    %esi,(%esp)
f0100971:	ff 14 85 a8 1f 10 f0 	call   *-0xfefe058(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100978:	85 c0                	test   %eax,%eax
f010097a:	78 25                	js     f01009a1 <monitor+0x132>
f010097c:	e9 0f ff ff ff       	jmp    f0100890 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100981:	83 c3 01             	add    $0x1,%ebx
f0100984:	83 fb 03             	cmp    $0x3,%ebx
f0100987:	75 b7                	jne    f0100940 <monitor+0xd1>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100989:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010098c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100990:	c7 04 24 f0 1d 10 f0 	movl   $0xf0101df0,(%esp)
f0100997:	e8 5b 00 00 00       	call   f01009f7 <cprintf>
f010099c:	e9 ef fe ff ff       	jmp    f0100890 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009a1:	83 c4 5c             	add    $0x5c,%esp
f01009a4:	5b                   	pop    %ebx
f01009a5:	5e                   	pop    %esi
f01009a6:	5f                   	pop    %edi
f01009a7:	5d                   	pop    %ebp
f01009a8:	c3                   	ret    

f01009a9 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01009a9:	55                   	push   %ebp
f01009aa:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01009ac:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01009af:	5d                   	pop    %ebp
f01009b0:	c3                   	ret    

f01009b1 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009b1:	55                   	push   %ebp
f01009b2:	89 e5                	mov    %esp,%ebp
f01009b4:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ba:	89 04 24             	mov    %eax,(%esp)
f01009bd:	e8 a2 fc ff ff       	call   f0100664 <cputchar>
	*cnt++;
}
f01009c2:	c9                   	leave  
f01009c3:	c3                   	ret    

f01009c4 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009c4:	55                   	push   %ebp
f01009c5:	89 e5                	mov    %esp,%ebp
f01009c7:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009ca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009d1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009d4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01009db:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009df:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009e2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009e6:	c7 04 24 b1 09 10 f0 	movl   $0xf01009b1,(%esp)
f01009ed:	e8 92 04 00 00       	call   f0100e84 <vprintfmt>
	return cnt;
}
f01009f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009f5:	c9                   	leave  
f01009f6:	c3                   	ret    

f01009f7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009f7:	55                   	push   %ebp
f01009f8:	89 e5                	mov    %esp,%ebp
f01009fa:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009fd:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a00:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a04:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a07:	89 04 24             	mov    %eax,(%esp)
f0100a0a:	e8 b5 ff ff ff       	call   f01009c4 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a0f:	c9                   	leave  
f0100a10:	c3                   	ret    
f0100a11:	66 90                	xchg   %ax,%ax
f0100a13:	66 90                	xchg   %ax,%ax
f0100a15:	66 90                	xchg   %ax,%ax
f0100a17:	66 90                	xchg   %ax,%ax
f0100a19:	66 90                	xchg   %ax,%ax
f0100a1b:	66 90                	xchg   %ax,%ax
f0100a1d:	66 90                	xchg   %ax,%ax
f0100a1f:	90                   	nop

f0100a20 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a20:	55                   	push   %ebp
f0100a21:	89 e5                	mov    %esp,%ebp
f0100a23:	57                   	push   %edi
f0100a24:	56                   	push   %esi
f0100a25:	53                   	push   %ebx
f0100a26:	83 ec 10             	sub    $0x10,%esp
f0100a29:	89 c6                	mov    %eax,%esi
f0100a2b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a2e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a31:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a34:	8b 1a                	mov    (%edx),%ebx
f0100a36:	8b 01                	mov    (%ecx),%eax
f0100a38:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a3b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100a42:	eb 77                	jmp    f0100abb <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a44:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a47:	01 d8                	add    %ebx,%eax
f0100a49:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a4e:	99                   	cltd   
f0100a4f:	f7 f9                	idiv   %ecx
f0100a51:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a53:	eb 01                	jmp    f0100a56 <stab_binsearch+0x36>
			m--;
f0100a55:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a56:	39 d9                	cmp    %ebx,%ecx
f0100a58:	7c 1d                	jl     f0100a77 <stab_binsearch+0x57>
f0100a5a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a5d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a62:	39 fa                	cmp    %edi,%edx
f0100a64:	75 ef                	jne    f0100a55 <stab_binsearch+0x35>
f0100a66:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a69:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a6c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a70:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a73:	73 18                	jae    f0100a8d <stab_binsearch+0x6d>
f0100a75:	eb 05                	jmp    f0100a7c <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a77:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a7a:	eb 3f                	jmp    f0100abb <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a7c:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a7f:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a81:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a84:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a8b:	eb 2e                	jmp    f0100abb <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a8d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a90:	73 15                	jae    f0100aa7 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a92:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a95:	48                   	dec    %eax
f0100a96:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a99:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a9c:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a9e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100aa5:	eb 14                	jmp    f0100abb <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100aa7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100aaa:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100aad:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100aaf:	ff 45 0c             	incl   0xc(%ebp)
f0100ab2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ab4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100abb:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100abe:	7e 84                	jle    f0100a44 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ac0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100ac4:	75 0d                	jne    f0100ad3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100ac6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ac9:	8b 00                	mov    (%eax),%eax
f0100acb:	48                   	dec    %eax
f0100acc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100acf:	89 07                	mov    %eax,(%edi)
f0100ad1:	eb 22                	jmp    f0100af5 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ad3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ad6:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ad8:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100adb:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100add:	eb 01                	jmp    f0100ae0 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100adf:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae0:	39 c1                	cmp    %eax,%ecx
f0100ae2:	7d 0c                	jge    f0100af0 <stab_binsearch+0xd0>
f0100ae4:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100ae7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100aec:	39 fa                	cmp    %edi,%edx
f0100aee:	75 ef                	jne    f0100adf <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100af0:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100af3:	89 07                	mov    %eax,(%edi)
	}
}
f0100af5:	83 c4 10             	add    $0x10,%esp
f0100af8:	5b                   	pop    %ebx
f0100af9:	5e                   	pop    %esi
f0100afa:	5f                   	pop    %edi
f0100afb:	5d                   	pop    %ebp
f0100afc:	c3                   	ret    

f0100afd <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100afd:	55                   	push   %ebp
f0100afe:	89 e5                	mov    %esp,%ebp
f0100b00:	57                   	push   %edi
f0100b01:	56                   	push   %esi
f0100b02:	53                   	push   %ebx
f0100b03:	83 ec 2c             	sub    $0x2c,%esp
f0100b06:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b09:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b0c:	c7 03 c4 1f 10 f0    	movl   $0xf0101fc4,(%ebx)
	info->eip_line = 0;
f0100b12:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b19:	c7 43 08 c4 1f 10 f0 	movl   $0xf0101fc4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b20:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b27:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b2a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b31:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b37:	76 12                	jbe    f0100b4b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b39:	b8 c5 74 10 f0       	mov    $0xf01074c5,%eax
f0100b3e:	3d 45 5b 10 f0       	cmp    $0xf0105b45,%eax
f0100b43:	0f 86 8b 01 00 00    	jbe    f0100cd4 <debuginfo_eip+0x1d7>
f0100b49:	eb 1c                	jmp    f0100b67 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b4b:	c7 44 24 08 ce 1f 10 	movl   $0xf0101fce,0x8(%esp)
f0100b52:	f0 
f0100b53:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b5a:	00 
f0100b5b:	c7 04 24 db 1f 10 f0 	movl   $0xf0101fdb,(%esp)
f0100b62:	e8 91 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b67:	80 3d c4 74 10 f0 00 	cmpb   $0x0,0xf01074c4
f0100b6e:	0f 85 67 01 00 00    	jne    f0100cdb <debuginfo_eip+0x1de>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b74:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b7b:	b8 44 5b 10 f0       	mov    $0xf0105b44,%eax
f0100b80:	2d fc 21 10 f0       	sub    $0xf01021fc,%eax
f0100b85:	c1 f8 02             	sar    $0x2,%eax
f0100b88:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b8e:	83 e8 01             	sub    $0x1,%eax
f0100b91:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b94:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b98:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b9f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ba2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ba5:	b8 fc 21 10 f0       	mov    $0xf01021fc,%eax
f0100baa:	e8 71 fe ff ff       	call   f0100a20 <stab_binsearch>
	if (lfile == 0)
f0100baf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bb2:	85 c0                	test   %eax,%eax
f0100bb4:	0f 84 28 01 00 00    	je     f0100ce2 <debuginfo_eip+0x1e5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bba:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bbd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bc0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bc3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bc7:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bce:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bd1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bd4:	b8 fc 21 10 f0       	mov    $0xf01021fc,%eax
f0100bd9:	e8 42 fe ff ff       	call   f0100a20 <stab_binsearch>

	if (lfun <= rfun) {
f0100bde:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100be1:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100be4:	7f 2e                	jg     f0100c14 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100be6:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100be9:	8d 90 fc 21 10 f0    	lea    -0xfefde04(%eax),%edx
f0100bef:	8b 80 fc 21 10 f0    	mov    -0xfefde04(%eax),%eax
f0100bf5:	b9 c5 74 10 f0       	mov    $0xf01074c5,%ecx
f0100bfa:	81 e9 45 5b 10 f0    	sub    $0xf0105b45,%ecx
f0100c00:	39 c8                	cmp    %ecx,%eax
f0100c02:	73 08                	jae    f0100c0c <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c04:	05 45 5b 10 f0       	add    $0xf0105b45,%eax
f0100c09:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c0c:	8b 42 08             	mov    0x8(%edx),%eax
f0100c0f:	89 43 10             	mov    %eax,0x10(%ebx)
f0100c12:	eb 06                	jmp    f0100c1a <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c14:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c17:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c1a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c21:	00 
f0100c22:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c25:	89 04 24             	mov    %eax,(%esp)
f0100c28:	e8 47 09 00 00       	call   f0101574 <strfind>
f0100c2d:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c30:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c33:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100c36:	39 cf                	cmp    %ecx,%edi
f0100c38:	7c 5c                	jl     f0100c96 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100c3a:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100c3d:	8d b0 fc 21 10 f0    	lea    -0xfefde04(%eax),%esi
f0100c43:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0100c47:	80 fa 84             	cmp    $0x84,%dl
f0100c4a:	74 2b                	je     f0100c77 <debuginfo_eip+0x17a>
f0100c4c:	05 f0 21 10 f0       	add    $0xf01021f0,%eax
f0100c51:	eb 15                	jmp    f0100c68 <debuginfo_eip+0x16b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c53:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c56:	39 cf                	cmp    %ecx,%edi
f0100c58:	7c 3c                	jl     f0100c96 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100c5a:	89 c6                	mov    %eax,%esi
f0100c5c:	83 e8 0c             	sub    $0xc,%eax
f0100c5f:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0100c63:	80 fa 84             	cmp    $0x84,%dl
f0100c66:	74 0f                	je     f0100c77 <debuginfo_eip+0x17a>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c68:	80 fa 64             	cmp    $0x64,%dl
f0100c6b:	75 e6                	jne    f0100c53 <debuginfo_eip+0x156>
f0100c6d:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0100c71:	74 e0                	je     f0100c53 <debuginfo_eip+0x156>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c73:	39 f9                	cmp    %edi,%ecx
f0100c75:	7f 1f                	jg     f0100c96 <debuginfo_eip+0x199>
f0100c77:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100c7a:	8b 87 fc 21 10 f0    	mov    -0xfefde04(%edi),%eax
f0100c80:	ba c5 74 10 f0       	mov    $0xf01074c5,%edx
f0100c85:	81 ea 45 5b 10 f0    	sub    $0xf0105b45,%edx
f0100c8b:	39 d0                	cmp    %edx,%eax
f0100c8d:	73 07                	jae    f0100c96 <debuginfo_eip+0x199>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c8f:	05 45 5b 10 f0       	add    $0xf0105b45,%eax
f0100c94:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c96:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c99:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c9c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ca1:	39 ca                	cmp    %ecx,%edx
f0100ca3:	7d 5e                	jge    f0100d03 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
f0100ca5:	8d 42 01             	lea    0x1(%edx),%eax
f0100ca8:	39 c1                	cmp    %eax,%ecx
f0100caa:	7e 3d                	jle    f0100ce9 <debuginfo_eip+0x1ec>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cac:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100caf:	80 ba 00 22 10 f0 a0 	cmpb   $0xa0,-0xfefde00(%edx)
f0100cb6:	75 38                	jne    f0100cf0 <debuginfo_eip+0x1f3>
f0100cb8:	81 c2 f0 21 10 f0    	add    $0xf01021f0,%edx
		     lline++)
			info->eip_fn_narg++;
f0100cbe:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100cc2:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100cc5:	39 c1                	cmp    %eax,%ecx
f0100cc7:	7e 2e                	jle    f0100cf7 <debuginfo_eip+0x1fa>
f0100cc9:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100ccc:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0100cd0:	74 ec                	je     f0100cbe <debuginfo_eip+0x1c1>
f0100cd2:	eb 2a                	jmp    f0100cfe <debuginfo_eip+0x201>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100cd4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cd9:	eb 28                	jmp    f0100d03 <debuginfo_eip+0x206>
f0100cdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ce0:	eb 21                	jmp    f0100d03 <debuginfo_eip+0x206>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ce2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ce7:	eb 1a                	jmp    f0100d03 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100ce9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cee:	eb 13                	jmp    f0100d03 <debuginfo_eip+0x206>
f0100cf0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cf5:	eb 0c                	jmp    f0100d03 <debuginfo_eip+0x206>
f0100cf7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cfc:	eb 05                	jmp    f0100d03 <debuginfo_eip+0x206>
f0100cfe:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d03:	83 c4 2c             	add    $0x2c,%esp
f0100d06:	5b                   	pop    %ebx
f0100d07:	5e                   	pop    %esi
f0100d08:	5f                   	pop    %edi
f0100d09:	5d                   	pop    %ebp
f0100d0a:	c3                   	ret    
f0100d0b:	66 90                	xchg   %ax,%ax
f0100d0d:	66 90                	xchg   %ax,%ax
f0100d0f:	90                   	nop

f0100d10 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d10:	55                   	push   %ebp
f0100d11:	89 e5                	mov    %esp,%ebp
f0100d13:	57                   	push   %edi
f0100d14:	56                   	push   %esi
f0100d15:	53                   	push   %ebx
f0100d16:	83 ec 3c             	sub    $0x3c,%esp
f0100d19:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d1c:	89 d7                	mov    %edx,%edi
f0100d1e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d21:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d24:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100d27:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100d2a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d2d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d32:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d35:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d38:	39 f1                	cmp    %esi,%ecx
f0100d3a:	72 14                	jb     f0100d50 <printnum+0x40>
f0100d3c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d3f:	76 0f                	jbe    f0100d50 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d41:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d44:	8d 70 ff             	lea    -0x1(%eax),%esi
f0100d47:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100d4a:	85 f6                	test   %esi,%esi
f0100d4c:	7f 60                	jg     f0100dae <printnum+0x9e>
f0100d4e:	eb 72                	jmp    f0100dc2 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d50:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d53:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d57:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0100d5a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100d5d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d61:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d65:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d69:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d6d:	89 c3                	mov    %eax,%ebx
f0100d6f:	89 d6                	mov    %edx,%esi
f0100d71:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d74:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d77:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d7b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d7f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d82:	89 04 24             	mov    %eax,(%esp)
f0100d85:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d88:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d8c:	e8 4f 0a 00 00       	call   f01017e0 <__udivdi3>
f0100d91:	89 d9                	mov    %ebx,%ecx
f0100d93:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d97:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d9b:	89 04 24             	mov    %eax,(%esp)
f0100d9e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100da2:	89 fa                	mov    %edi,%edx
f0100da4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100da7:	e8 64 ff ff ff       	call   f0100d10 <printnum>
f0100dac:	eb 14                	jmp    f0100dc2 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dae:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100db2:	8b 45 18             	mov    0x18(%ebp),%eax
f0100db5:	89 04 24             	mov    %eax,(%esp)
f0100db8:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100dba:	83 ee 01             	sub    $0x1,%esi
f0100dbd:	75 ef                	jne    f0100dae <printnum+0x9e>
f0100dbf:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100dc2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dc6:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100dca:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100dcd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100dd0:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dd4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100dd8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ddb:	89 04 24             	mov    %eax,(%esp)
f0100dde:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100de1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100de5:	e8 26 0b 00 00       	call   f0101910 <__umoddi3>
f0100dea:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dee:	0f be 80 e9 1f 10 f0 	movsbl -0xfefe017(%eax),%eax
f0100df5:	89 04 24             	mov    %eax,(%esp)
f0100df8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dfb:	ff d0                	call   *%eax
}
f0100dfd:	83 c4 3c             	add    $0x3c,%esp
f0100e00:	5b                   	pop    %ebx
f0100e01:	5e                   	pop    %esi
f0100e02:	5f                   	pop    %edi
f0100e03:	5d                   	pop    %ebp
f0100e04:	c3                   	ret    

f0100e05 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e05:	55                   	push   %ebp
f0100e06:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e08:	83 fa 01             	cmp    $0x1,%edx
f0100e0b:	7e 0e                	jle    f0100e1b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e0d:	8b 10                	mov    (%eax),%edx
f0100e0f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e12:	89 08                	mov    %ecx,(%eax)
f0100e14:	8b 02                	mov    (%edx),%eax
f0100e16:	8b 52 04             	mov    0x4(%edx),%edx
f0100e19:	eb 22                	jmp    f0100e3d <getuint+0x38>
	else if (lflag)
f0100e1b:	85 d2                	test   %edx,%edx
f0100e1d:	74 10                	je     f0100e2f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e1f:	8b 10                	mov    (%eax),%edx
f0100e21:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e24:	89 08                	mov    %ecx,(%eax)
f0100e26:	8b 02                	mov    (%edx),%eax
f0100e28:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e2d:	eb 0e                	jmp    f0100e3d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e2f:	8b 10                	mov    (%eax),%edx
f0100e31:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e34:	89 08                	mov    %ecx,(%eax)
f0100e36:	8b 02                	mov    (%edx),%eax
f0100e38:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e3d:	5d                   	pop    %ebp
f0100e3e:	c3                   	ret    

f0100e3f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e3f:	55                   	push   %ebp
f0100e40:	89 e5                	mov    %esp,%ebp
f0100e42:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e45:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e49:	8b 10                	mov    (%eax),%edx
f0100e4b:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e4e:	73 0a                	jae    f0100e5a <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e50:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e53:	89 08                	mov    %ecx,(%eax)
f0100e55:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e58:	88 02                	mov    %al,(%edx)
}
f0100e5a:	5d                   	pop    %ebp
f0100e5b:	c3                   	ret    

f0100e5c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e5c:	55                   	push   %ebp
f0100e5d:	89 e5                	mov    %esp,%ebp
f0100e5f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e62:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e65:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e69:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e6c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e70:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e73:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e77:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e7a:	89 04 24             	mov    %eax,(%esp)
f0100e7d:	e8 02 00 00 00       	call   f0100e84 <vprintfmt>
	va_end(ap);
}
f0100e82:	c9                   	leave  
f0100e83:	c3                   	ret    

f0100e84 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e84:	55                   	push   %ebp
f0100e85:	89 e5                	mov    %esp,%ebp
f0100e87:	57                   	push   %edi
f0100e88:	56                   	push   %esi
f0100e89:	53                   	push   %ebx
f0100e8a:	83 ec 3c             	sub    $0x3c,%esp
f0100e8d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100e90:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e93:	eb 18                	jmp    f0100ead <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e95:	85 c0                	test   %eax,%eax
f0100e97:	0f 84 c3 03 00 00    	je     f0101260 <vprintfmt+0x3dc>
				return;
			putch(ch, putdat);
f0100e9d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ea1:	89 04 24             	mov    %eax,(%esp)
f0100ea4:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ea7:	89 f3                	mov    %esi,%ebx
f0100ea9:	eb 02                	jmp    f0100ead <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100eab:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ead:	8d 73 01             	lea    0x1(%ebx),%esi
f0100eb0:	0f b6 03             	movzbl (%ebx),%eax
f0100eb3:	83 f8 25             	cmp    $0x25,%eax
f0100eb6:	75 dd                	jne    f0100e95 <vprintfmt+0x11>
f0100eb8:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f0100ebc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100ec3:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100eca:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100ed1:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ed6:	eb 1d                	jmp    f0100ef5 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed8:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100eda:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f0100ede:	eb 15                	jmp    f0100ef5 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee0:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ee2:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0100ee6:	eb 0d                	jmp    f0100ef5 <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100ee8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100eeb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100eee:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef5:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100ef8:	0f b6 06             	movzbl (%esi),%eax
f0100efb:	0f b6 c8             	movzbl %al,%ecx
f0100efe:	83 e8 23             	sub    $0x23,%eax
f0100f01:	3c 55                	cmp    $0x55,%al
f0100f03:	0f 87 2f 03 00 00    	ja     f0101238 <vprintfmt+0x3b4>
f0100f09:	0f b6 c0             	movzbl %al,%eax
f0100f0c:	ff 24 85 78 20 10 f0 	jmp    *-0xfefdf88(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f13:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0100f16:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0100f19:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100f1d:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100f20:	83 f9 09             	cmp    $0x9,%ecx
f0100f23:	77 50                	ja     f0100f75 <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f25:	89 de                	mov    %ebx,%esi
f0100f27:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f2a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100f2d:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f30:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f34:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f37:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f3a:	83 fb 09             	cmp    $0x9,%ebx
f0100f3d:	76 eb                	jbe    f0100f2a <vprintfmt+0xa6>
f0100f3f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100f42:	eb 33                	jmp    f0100f77 <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f44:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f47:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f4a:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f4d:	8b 00                	mov    (%eax),%eax
f0100f4f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f52:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f54:	eb 21                	jmp    f0100f77 <vprintfmt+0xf3>
f0100f56:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f59:	85 c9                	test   %ecx,%ecx
f0100f5b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f60:	0f 49 c1             	cmovns %ecx,%eax
f0100f63:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f66:	89 de                	mov    %ebx,%esi
f0100f68:	eb 8b                	jmp    f0100ef5 <vprintfmt+0x71>
f0100f6a:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f6c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f73:	eb 80                	jmp    f0100ef5 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f75:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100f77:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f7b:	0f 89 74 ff ff ff    	jns    f0100ef5 <vprintfmt+0x71>
f0100f81:	e9 62 ff ff ff       	jmp    f0100ee8 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f86:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f89:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f8b:	e9 65 ff ff ff       	jmp    f0100ef5 <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f90:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f93:	8d 50 04             	lea    0x4(%eax),%edx
f0100f96:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f99:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f9d:	8b 00                	mov    (%eax),%eax
f0100f9f:	89 04 24             	mov    %eax,(%esp)
f0100fa2:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100fa5:	e9 03 ff ff ff       	jmp    f0100ead <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100faa:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fad:	8d 50 04             	lea    0x4(%eax),%edx
f0100fb0:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fb3:	8b 00                	mov    (%eax),%eax
f0100fb5:	99                   	cltd   
f0100fb6:	31 d0                	xor    %edx,%eax
f0100fb8:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fba:	83 f8 06             	cmp    $0x6,%eax
f0100fbd:	7f 0b                	jg     f0100fca <vprintfmt+0x146>
f0100fbf:	8b 14 85 d0 21 10 f0 	mov    -0xfefde30(,%eax,4),%edx
f0100fc6:	85 d2                	test   %edx,%edx
f0100fc8:	75 20                	jne    f0100fea <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
f0100fca:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fce:	c7 44 24 08 01 20 10 	movl   $0xf0102001,0x8(%esp)
f0100fd5:	f0 
f0100fd6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fda:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fdd:	89 04 24             	mov    %eax,(%esp)
f0100fe0:	e8 77 fe ff ff       	call   f0100e5c <printfmt>
f0100fe5:	e9 c3 fe ff ff       	jmp    f0100ead <vprintfmt+0x29>
			else
				printfmt(putch, putdat, "%s", p);
f0100fea:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100fee:	c7 44 24 08 0a 20 10 	movl   $0xf010200a,0x8(%esp)
f0100ff5:	f0 
f0100ff6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ffa:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ffd:	89 04 24             	mov    %eax,(%esp)
f0101000:	e8 57 fe ff ff       	call   f0100e5c <printfmt>
f0101005:	e9 a3 fe ff ff       	jmp    f0100ead <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010100a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010100d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101010:	8b 45 14             	mov    0x14(%ebp),%eax
f0101013:	8d 50 04             	lea    0x4(%eax),%edx
f0101016:	89 55 14             	mov    %edx,0x14(%ebp)
f0101019:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f010101b:	85 c0                	test   %eax,%eax
f010101d:	ba fa 1f 10 f0       	mov    $0xf0101ffa,%edx
f0101022:	0f 45 d0             	cmovne %eax,%edx
f0101025:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f0101028:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f010102c:	74 04                	je     f0101032 <vprintfmt+0x1ae>
f010102e:	85 f6                	test   %esi,%esi
f0101030:	7f 19                	jg     f010104b <vprintfmt+0x1c7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101032:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101035:	8d 70 01             	lea    0x1(%eax),%esi
f0101038:	0f b6 10             	movzbl (%eax),%edx
f010103b:	0f be c2             	movsbl %dl,%eax
f010103e:	85 c0                	test   %eax,%eax
f0101040:	0f 85 95 00 00 00    	jne    f01010db <vprintfmt+0x257>
f0101046:	e9 85 00 00 00       	jmp    f01010d0 <vprintfmt+0x24c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010104b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010104f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101052:	89 04 24             	mov    %eax,(%esp)
f0101055:	e8 88 03 00 00       	call   f01013e2 <strnlen>
f010105a:	29 c6                	sub    %eax,%esi
f010105c:	89 f0                	mov    %esi,%eax
f010105e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101061:	85 f6                	test   %esi,%esi
f0101063:	7e cd                	jle    f0101032 <vprintfmt+0x1ae>
					putch(padc, putdat);
f0101065:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101069:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010106c:	89 c3                	mov    %eax,%ebx
f010106e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101072:	89 34 24             	mov    %esi,(%esp)
f0101075:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101078:	83 eb 01             	sub    $0x1,%ebx
f010107b:	75 f1                	jne    f010106e <vprintfmt+0x1ea>
f010107d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101080:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101083:	eb ad                	jmp    f0101032 <vprintfmt+0x1ae>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101085:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101089:	74 1e                	je     f01010a9 <vprintfmt+0x225>
f010108b:	0f be d2             	movsbl %dl,%edx
f010108e:	83 ea 20             	sub    $0x20,%edx
f0101091:	83 fa 5e             	cmp    $0x5e,%edx
f0101094:	76 13                	jbe    f01010a9 <vprintfmt+0x225>
					putch('?', putdat);
f0101096:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101099:	89 44 24 04          	mov    %eax,0x4(%esp)
f010109d:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010a4:	ff 55 08             	call   *0x8(%ebp)
f01010a7:	eb 0d                	jmp    f01010b6 <vprintfmt+0x232>
				else
					putch(ch, putdat);
f01010a9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01010ac:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010b0:	89 04 24             	mov    %eax,(%esp)
f01010b3:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010b6:	83 ef 01             	sub    $0x1,%edi
f01010b9:	83 c6 01             	add    $0x1,%esi
f01010bc:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01010c0:	0f be c2             	movsbl %dl,%eax
f01010c3:	85 c0                	test   %eax,%eax
f01010c5:	75 20                	jne    f01010e7 <vprintfmt+0x263>
f01010c7:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01010ca:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010cd:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010d0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01010d4:	7f 25                	jg     f01010fb <vprintfmt+0x277>
f01010d6:	e9 d2 fd ff ff       	jmp    f0100ead <vprintfmt+0x29>
f01010db:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010de:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010e1:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010e4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010e7:	85 db                	test   %ebx,%ebx
f01010e9:	78 9a                	js     f0101085 <vprintfmt+0x201>
f01010eb:	83 eb 01             	sub    $0x1,%ebx
f01010ee:	79 95                	jns    f0101085 <vprintfmt+0x201>
f01010f0:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01010f3:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010f6:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01010f9:	eb d5                	jmp    f01010d0 <vprintfmt+0x24c>
f01010fb:	8b 75 08             	mov    0x8(%ebp),%esi
f01010fe:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101101:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101104:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101108:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010110f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101111:	83 eb 01             	sub    $0x1,%ebx
f0101114:	75 ee                	jne    f0101104 <vprintfmt+0x280>
f0101116:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101119:	e9 8f fd ff ff       	jmp    f0100ead <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010111e:	83 fa 01             	cmp    $0x1,%edx
f0101121:	7e 16                	jle    f0101139 <vprintfmt+0x2b5>
		return va_arg(*ap, long long);
f0101123:	8b 45 14             	mov    0x14(%ebp),%eax
f0101126:	8d 50 08             	lea    0x8(%eax),%edx
f0101129:	89 55 14             	mov    %edx,0x14(%ebp)
f010112c:	8b 50 04             	mov    0x4(%eax),%edx
f010112f:	8b 00                	mov    (%eax),%eax
f0101131:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101134:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101137:	eb 32                	jmp    f010116b <vprintfmt+0x2e7>
	else if (lflag)
f0101139:	85 d2                	test   %edx,%edx
f010113b:	74 18                	je     f0101155 <vprintfmt+0x2d1>
		return va_arg(*ap, long);
f010113d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101140:	8d 50 04             	lea    0x4(%eax),%edx
f0101143:	89 55 14             	mov    %edx,0x14(%ebp)
f0101146:	8b 30                	mov    (%eax),%esi
f0101148:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010114b:	89 f0                	mov    %esi,%eax
f010114d:	c1 f8 1f             	sar    $0x1f,%eax
f0101150:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101153:	eb 16                	jmp    f010116b <vprintfmt+0x2e7>
	else
		return va_arg(*ap, int);
f0101155:	8b 45 14             	mov    0x14(%ebp),%eax
f0101158:	8d 50 04             	lea    0x4(%eax),%edx
f010115b:	89 55 14             	mov    %edx,0x14(%ebp)
f010115e:	8b 30                	mov    (%eax),%esi
f0101160:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101163:	89 f0                	mov    %esi,%eax
f0101165:	c1 f8 1f             	sar    $0x1f,%eax
f0101168:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010116b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010116e:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101171:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101176:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010117a:	0f 89 80 00 00 00    	jns    f0101200 <vprintfmt+0x37c>
				putch('-', putdat);
f0101180:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101184:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010118b:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010118e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101191:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101194:	f7 d8                	neg    %eax
f0101196:	83 d2 00             	adc    $0x0,%edx
f0101199:	f7 da                	neg    %edx
			}
			base = 10;
f010119b:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01011a0:	eb 5e                	jmp    f0101200 <vprintfmt+0x37c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01011a2:	8d 45 14             	lea    0x14(%ebp),%eax
f01011a5:	e8 5b fc ff ff       	call   f0100e05 <getuint>
			base = 10;
f01011aa:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01011af:	eb 4f                	jmp    f0101200 <vprintfmt+0x37c>
			// putch('X', putdat);
			// putch('X', putdat);
			// putch('X', putdat);
			// break;
			//just immitate case 'x'
			num =getuint(&ap, lflag);
f01011b1:	8d 45 14             	lea    0x14(%ebp),%eax
f01011b4:	e8 4c fc ff ff       	call   f0100e05 <getuint>
			base=8;
f01011b9:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01011be:	eb 40                	jmp    f0101200 <vprintfmt+0x37c>
			
		// pointer
		case 'p':
			putch('0', putdat);
f01011c0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011c4:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011cb:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011ce:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011d2:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011d9:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011dc:	8b 45 14             	mov    0x14(%ebp),%eax
f01011df:	8d 50 04             	lea    0x4(%eax),%edx
f01011e2:	89 55 14             	mov    %edx,0x14(%ebp)
			
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01011e5:	8b 00                	mov    (%eax),%eax
f01011e7:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01011ec:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01011f1:	eb 0d                	jmp    f0101200 <vprintfmt+0x37c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01011f3:	8d 45 14             	lea    0x14(%ebp),%eax
f01011f6:	e8 0a fc ff ff       	call   f0100e05 <getuint>
			base = 16;
f01011fb:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101200:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101204:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101208:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010120b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010120f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101213:	89 04 24             	mov    %eax,(%esp)
f0101216:	89 54 24 04          	mov    %edx,0x4(%esp)
f010121a:	89 fa                	mov    %edi,%edx
f010121c:	8b 45 08             	mov    0x8(%ebp),%eax
f010121f:	e8 ec fa ff ff       	call   f0100d10 <printnum>
			break;
f0101224:	e9 84 fc ff ff       	jmp    f0100ead <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101229:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010122d:	89 0c 24             	mov    %ecx,(%esp)
f0101230:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101233:	e9 75 fc ff ff       	jmp    f0100ead <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101238:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010123c:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101243:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101246:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010124a:	0f 84 5b fc ff ff    	je     f0100eab <vprintfmt+0x27>
f0101250:	89 f3                	mov    %esi,%ebx
f0101252:	83 eb 01             	sub    $0x1,%ebx
f0101255:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101259:	75 f7                	jne    f0101252 <vprintfmt+0x3ce>
f010125b:	e9 4d fc ff ff       	jmp    f0100ead <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
f0101260:	83 c4 3c             	add    $0x3c,%esp
f0101263:	5b                   	pop    %ebx
f0101264:	5e                   	pop    %esi
f0101265:	5f                   	pop    %edi
f0101266:	5d                   	pop    %ebp
f0101267:	c3                   	ret    

f0101268 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101268:	55                   	push   %ebp
f0101269:	89 e5                	mov    %esp,%ebp
f010126b:	83 ec 28             	sub    $0x28,%esp
f010126e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101271:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101274:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101277:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010127b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010127e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101285:	85 c0                	test   %eax,%eax
f0101287:	74 30                	je     f01012b9 <vsnprintf+0x51>
f0101289:	85 d2                	test   %edx,%edx
f010128b:	7e 2c                	jle    f01012b9 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010128d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101290:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101294:	8b 45 10             	mov    0x10(%ebp),%eax
f0101297:	89 44 24 08          	mov    %eax,0x8(%esp)
f010129b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010129e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012a2:	c7 04 24 3f 0e 10 f0 	movl   $0xf0100e3f,(%esp)
f01012a9:	e8 d6 fb ff ff       	call   f0100e84 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012b1:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012b7:	eb 05                	jmp    f01012be <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012b9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012be:	c9                   	leave  
f01012bf:	c3                   	ret    

f01012c0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012c0:	55                   	push   %ebp
f01012c1:	89 e5                	mov    %esp,%ebp
f01012c3:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012c6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012cd:	8b 45 10             	mov    0x10(%ebp),%eax
f01012d0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012d4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012d7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012db:	8b 45 08             	mov    0x8(%ebp),%eax
f01012de:	89 04 24             	mov    %eax,(%esp)
f01012e1:	e8 82 ff ff ff       	call   f0101268 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012e6:	c9                   	leave  
f01012e7:	c3                   	ret    
f01012e8:	66 90                	xchg   %ax,%ax
f01012ea:	66 90                	xchg   %ax,%ax
f01012ec:	66 90                	xchg   %ax,%ax
f01012ee:	66 90                	xchg   %ax,%ax

f01012f0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012f0:	55                   	push   %ebp
f01012f1:	89 e5                	mov    %esp,%ebp
f01012f3:	57                   	push   %edi
f01012f4:	56                   	push   %esi
f01012f5:	53                   	push   %ebx
f01012f6:	83 ec 1c             	sub    $0x1c,%esp
f01012f9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012fc:	85 c0                	test   %eax,%eax
f01012fe:	74 10                	je     f0101310 <readline+0x20>
		cprintf("%s", prompt);
f0101300:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101304:	c7 04 24 0a 20 10 f0 	movl   $0xf010200a,(%esp)
f010130b:	e8 e7 f6 ff ff       	call   f01009f7 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101310:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101317:	e8 69 f3 ff ff       	call   f0100685 <iscons>
f010131c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010131e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101323:	e8 4c f3 ff ff       	call   f0100674 <getchar>
f0101328:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010132a:	85 c0                	test   %eax,%eax
f010132c:	79 17                	jns    f0101345 <readline+0x55>
			cprintf("read error: %e\n", c);
f010132e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101332:	c7 04 24 ec 21 10 f0 	movl   $0xf01021ec,(%esp)
f0101339:	e8 b9 f6 ff ff       	call   f01009f7 <cprintf>
			return NULL;
f010133e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101343:	eb 6d                	jmp    f01013b2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101345:	83 f8 7f             	cmp    $0x7f,%eax
f0101348:	74 05                	je     f010134f <readline+0x5f>
f010134a:	83 f8 08             	cmp    $0x8,%eax
f010134d:	75 19                	jne    f0101368 <readline+0x78>
f010134f:	85 f6                	test   %esi,%esi
f0101351:	7e 15                	jle    f0101368 <readline+0x78>
			if (echoing)
f0101353:	85 ff                	test   %edi,%edi
f0101355:	74 0c                	je     f0101363 <readline+0x73>
				cputchar('\b');
f0101357:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010135e:	e8 01 f3 ff ff       	call   f0100664 <cputchar>
			i--;
f0101363:	83 ee 01             	sub    $0x1,%esi
f0101366:	eb bb                	jmp    f0101323 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101368:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010136e:	7f 1c                	jg     f010138c <readline+0x9c>
f0101370:	83 fb 1f             	cmp    $0x1f,%ebx
f0101373:	7e 17                	jle    f010138c <readline+0x9c>
			if (echoing)
f0101375:	85 ff                	test   %edi,%edi
f0101377:	74 08                	je     f0101381 <readline+0x91>
				cputchar(c);
f0101379:	89 1c 24             	mov    %ebx,(%esp)
f010137c:	e8 e3 f2 ff ff       	call   f0100664 <cputchar>
			buf[i++] = c;
f0101381:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101387:	8d 76 01             	lea    0x1(%esi),%esi
f010138a:	eb 97                	jmp    f0101323 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010138c:	83 fb 0d             	cmp    $0xd,%ebx
f010138f:	74 05                	je     f0101396 <readline+0xa6>
f0101391:	83 fb 0a             	cmp    $0xa,%ebx
f0101394:	75 8d                	jne    f0101323 <readline+0x33>
			if (echoing)
f0101396:	85 ff                	test   %edi,%edi
f0101398:	74 0c                	je     f01013a6 <readline+0xb6>
				cputchar('\n');
f010139a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013a1:	e8 be f2 ff ff       	call   f0100664 <cputchar>
			buf[i] = 0;
f01013a6:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f01013ad:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f01013b2:	83 c4 1c             	add    $0x1c,%esp
f01013b5:	5b                   	pop    %ebx
f01013b6:	5e                   	pop    %esi
f01013b7:	5f                   	pop    %edi
f01013b8:	5d                   	pop    %ebp
f01013b9:	c3                   	ret    
f01013ba:	66 90                	xchg   %ax,%ax
f01013bc:	66 90                	xchg   %ax,%ax
f01013be:	66 90                	xchg   %ax,%ax

f01013c0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013c0:	55                   	push   %ebp
f01013c1:	89 e5                	mov    %esp,%ebp
f01013c3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013c6:	80 3a 00             	cmpb   $0x0,(%edx)
f01013c9:	74 10                	je     f01013db <strlen+0x1b>
f01013cb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01013d0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013d3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013d7:	75 f7                	jne    f01013d0 <strlen+0x10>
f01013d9:	eb 05                	jmp    f01013e0 <strlen+0x20>
f01013db:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01013e0:	5d                   	pop    %ebp
f01013e1:	c3                   	ret    

f01013e2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013e2:	55                   	push   %ebp
f01013e3:	89 e5                	mov    %esp,%ebp
f01013e5:	53                   	push   %ebx
f01013e6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01013e9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013ec:	85 c9                	test   %ecx,%ecx
f01013ee:	74 1c                	je     f010140c <strnlen+0x2a>
f01013f0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01013f3:	74 1e                	je     f0101413 <strnlen+0x31>
f01013f5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01013fa:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013fc:	39 ca                	cmp    %ecx,%edx
f01013fe:	74 18                	je     f0101418 <strnlen+0x36>
f0101400:	83 c2 01             	add    $0x1,%edx
f0101403:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101408:	75 f0                	jne    f01013fa <strnlen+0x18>
f010140a:	eb 0c                	jmp    f0101418 <strnlen+0x36>
f010140c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101411:	eb 05                	jmp    f0101418 <strnlen+0x36>
f0101413:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101418:	5b                   	pop    %ebx
f0101419:	5d                   	pop    %ebp
f010141a:	c3                   	ret    

f010141b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010141b:	55                   	push   %ebp
f010141c:	89 e5                	mov    %esp,%ebp
f010141e:	53                   	push   %ebx
f010141f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101422:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101425:	89 c2                	mov    %eax,%edx
f0101427:	83 c2 01             	add    $0x1,%edx
f010142a:	83 c1 01             	add    $0x1,%ecx
f010142d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101431:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101434:	84 db                	test   %bl,%bl
f0101436:	75 ef                	jne    f0101427 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101438:	5b                   	pop    %ebx
f0101439:	5d                   	pop    %ebp
f010143a:	c3                   	ret    

f010143b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010143b:	55                   	push   %ebp
f010143c:	89 e5                	mov    %esp,%ebp
f010143e:	56                   	push   %esi
f010143f:	53                   	push   %ebx
f0101440:	8b 75 08             	mov    0x8(%ebp),%esi
f0101443:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101446:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101449:	85 db                	test   %ebx,%ebx
f010144b:	74 17                	je     f0101464 <strncpy+0x29>
f010144d:	01 f3                	add    %esi,%ebx
f010144f:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f0101451:	83 c1 01             	add    $0x1,%ecx
f0101454:	0f b6 02             	movzbl (%edx),%eax
f0101457:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010145a:	80 3a 01             	cmpb   $0x1,(%edx)
f010145d:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101460:	39 d9                	cmp    %ebx,%ecx
f0101462:	75 ed                	jne    f0101451 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101464:	89 f0                	mov    %esi,%eax
f0101466:	5b                   	pop    %ebx
f0101467:	5e                   	pop    %esi
f0101468:	5d                   	pop    %ebp
f0101469:	c3                   	ret    

f010146a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010146a:	55                   	push   %ebp
f010146b:	89 e5                	mov    %esp,%ebp
f010146d:	57                   	push   %edi
f010146e:	56                   	push   %esi
f010146f:	53                   	push   %ebx
f0101470:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101473:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101476:	8b 75 10             	mov    0x10(%ebp),%esi
f0101479:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010147b:	85 f6                	test   %esi,%esi
f010147d:	74 34                	je     f01014b3 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f010147f:	83 fe 01             	cmp    $0x1,%esi
f0101482:	74 26                	je     f01014aa <strlcpy+0x40>
f0101484:	0f b6 0b             	movzbl (%ebx),%ecx
f0101487:	84 c9                	test   %cl,%cl
f0101489:	74 23                	je     f01014ae <strlcpy+0x44>
f010148b:	83 ee 02             	sub    $0x2,%esi
f010148e:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f0101493:	83 c0 01             	add    $0x1,%eax
f0101496:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101499:	39 f2                	cmp    %esi,%edx
f010149b:	74 13                	je     f01014b0 <strlcpy+0x46>
f010149d:	83 c2 01             	add    $0x1,%edx
f01014a0:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01014a4:	84 c9                	test   %cl,%cl
f01014a6:	75 eb                	jne    f0101493 <strlcpy+0x29>
f01014a8:	eb 06                	jmp    f01014b0 <strlcpy+0x46>
f01014aa:	89 f8                	mov    %edi,%eax
f01014ac:	eb 02                	jmp    f01014b0 <strlcpy+0x46>
f01014ae:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01014b0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01014b3:	29 f8                	sub    %edi,%eax
}
f01014b5:	5b                   	pop    %ebx
f01014b6:	5e                   	pop    %esi
f01014b7:	5f                   	pop    %edi
f01014b8:	5d                   	pop    %ebp
f01014b9:	c3                   	ret    

f01014ba <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014ba:	55                   	push   %ebp
f01014bb:	89 e5                	mov    %esp,%ebp
f01014bd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014c0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014c3:	0f b6 01             	movzbl (%ecx),%eax
f01014c6:	84 c0                	test   %al,%al
f01014c8:	74 15                	je     f01014df <strcmp+0x25>
f01014ca:	3a 02                	cmp    (%edx),%al
f01014cc:	75 11                	jne    f01014df <strcmp+0x25>
		p++, q++;
f01014ce:	83 c1 01             	add    $0x1,%ecx
f01014d1:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014d4:	0f b6 01             	movzbl (%ecx),%eax
f01014d7:	84 c0                	test   %al,%al
f01014d9:	74 04                	je     f01014df <strcmp+0x25>
f01014db:	3a 02                	cmp    (%edx),%al
f01014dd:	74 ef                	je     f01014ce <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014df:	0f b6 c0             	movzbl %al,%eax
f01014e2:	0f b6 12             	movzbl (%edx),%edx
f01014e5:	29 d0                	sub    %edx,%eax
}
f01014e7:	5d                   	pop    %ebp
f01014e8:	c3                   	ret    

f01014e9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014e9:	55                   	push   %ebp
f01014ea:	89 e5                	mov    %esp,%ebp
f01014ec:	56                   	push   %esi
f01014ed:	53                   	push   %ebx
f01014ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014f1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014f4:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f01014f7:	85 f6                	test   %esi,%esi
f01014f9:	74 29                	je     f0101524 <strncmp+0x3b>
f01014fb:	0f b6 03             	movzbl (%ebx),%eax
f01014fe:	84 c0                	test   %al,%al
f0101500:	74 30                	je     f0101532 <strncmp+0x49>
f0101502:	3a 02                	cmp    (%edx),%al
f0101504:	75 2c                	jne    f0101532 <strncmp+0x49>
f0101506:	8d 43 01             	lea    0x1(%ebx),%eax
f0101509:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f010150b:	89 c3                	mov    %eax,%ebx
f010150d:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101510:	39 f0                	cmp    %esi,%eax
f0101512:	74 17                	je     f010152b <strncmp+0x42>
f0101514:	0f b6 08             	movzbl (%eax),%ecx
f0101517:	84 c9                	test   %cl,%cl
f0101519:	74 17                	je     f0101532 <strncmp+0x49>
f010151b:	83 c0 01             	add    $0x1,%eax
f010151e:	3a 0a                	cmp    (%edx),%cl
f0101520:	74 e9                	je     f010150b <strncmp+0x22>
f0101522:	eb 0e                	jmp    f0101532 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101524:	b8 00 00 00 00       	mov    $0x0,%eax
f0101529:	eb 0f                	jmp    f010153a <strncmp+0x51>
f010152b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101530:	eb 08                	jmp    f010153a <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101532:	0f b6 03             	movzbl (%ebx),%eax
f0101535:	0f b6 12             	movzbl (%edx),%edx
f0101538:	29 d0                	sub    %edx,%eax
}
f010153a:	5b                   	pop    %ebx
f010153b:	5e                   	pop    %esi
f010153c:	5d                   	pop    %ebp
f010153d:	c3                   	ret    

f010153e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010153e:	55                   	push   %ebp
f010153f:	89 e5                	mov    %esp,%ebp
f0101541:	53                   	push   %ebx
f0101542:	8b 45 08             	mov    0x8(%ebp),%eax
f0101545:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101548:	0f b6 18             	movzbl (%eax),%ebx
f010154b:	84 db                	test   %bl,%bl
f010154d:	74 1d                	je     f010156c <strchr+0x2e>
f010154f:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101551:	38 d3                	cmp    %dl,%bl
f0101553:	75 06                	jne    f010155b <strchr+0x1d>
f0101555:	eb 1a                	jmp    f0101571 <strchr+0x33>
f0101557:	38 ca                	cmp    %cl,%dl
f0101559:	74 16                	je     f0101571 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010155b:	83 c0 01             	add    $0x1,%eax
f010155e:	0f b6 10             	movzbl (%eax),%edx
f0101561:	84 d2                	test   %dl,%dl
f0101563:	75 f2                	jne    f0101557 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0101565:	b8 00 00 00 00       	mov    $0x0,%eax
f010156a:	eb 05                	jmp    f0101571 <strchr+0x33>
f010156c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101571:	5b                   	pop    %ebx
f0101572:	5d                   	pop    %ebp
f0101573:	c3                   	ret    

f0101574 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101574:	55                   	push   %ebp
f0101575:	89 e5                	mov    %esp,%ebp
f0101577:	53                   	push   %ebx
f0101578:	8b 45 08             	mov    0x8(%ebp),%eax
f010157b:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010157e:	0f b6 18             	movzbl (%eax),%ebx
f0101581:	84 db                	test   %bl,%bl
f0101583:	74 17                	je     f010159c <strfind+0x28>
f0101585:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101587:	38 d3                	cmp    %dl,%bl
f0101589:	75 07                	jne    f0101592 <strfind+0x1e>
f010158b:	eb 0f                	jmp    f010159c <strfind+0x28>
f010158d:	38 ca                	cmp    %cl,%dl
f010158f:	90                   	nop
f0101590:	74 0a                	je     f010159c <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101592:	83 c0 01             	add    $0x1,%eax
f0101595:	0f b6 10             	movzbl (%eax),%edx
f0101598:	84 d2                	test   %dl,%dl
f010159a:	75 f1                	jne    f010158d <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f010159c:	5b                   	pop    %ebx
f010159d:	5d                   	pop    %ebp
f010159e:	c3                   	ret    

f010159f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010159f:	55                   	push   %ebp
f01015a0:	89 e5                	mov    %esp,%ebp
f01015a2:	57                   	push   %edi
f01015a3:	56                   	push   %esi
f01015a4:	53                   	push   %ebx
f01015a5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015a8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015ab:	85 c9                	test   %ecx,%ecx
f01015ad:	74 36                	je     f01015e5 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015af:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015b5:	75 28                	jne    f01015df <memset+0x40>
f01015b7:	f6 c1 03             	test   $0x3,%cl
f01015ba:	75 23                	jne    f01015df <memset+0x40>
		c &= 0xFF;
f01015bc:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015c0:	89 d3                	mov    %edx,%ebx
f01015c2:	c1 e3 08             	shl    $0x8,%ebx
f01015c5:	89 d6                	mov    %edx,%esi
f01015c7:	c1 e6 18             	shl    $0x18,%esi
f01015ca:	89 d0                	mov    %edx,%eax
f01015cc:	c1 e0 10             	shl    $0x10,%eax
f01015cf:	09 f0                	or     %esi,%eax
f01015d1:	09 c2                	or     %eax,%edx
f01015d3:	89 d0                	mov    %edx,%eax
f01015d5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01015d7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01015da:	fc                   	cld    
f01015db:	f3 ab                	rep stos %eax,%es:(%edi)
f01015dd:	eb 06                	jmp    f01015e5 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015df:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015e2:	fc                   	cld    
f01015e3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015e5:	89 f8                	mov    %edi,%eax
f01015e7:	5b                   	pop    %ebx
f01015e8:	5e                   	pop    %esi
f01015e9:	5f                   	pop    %edi
f01015ea:	5d                   	pop    %ebp
f01015eb:	c3                   	ret    

f01015ec <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015ec:	55                   	push   %ebp
f01015ed:	89 e5                	mov    %esp,%ebp
f01015ef:	57                   	push   %edi
f01015f0:	56                   	push   %esi
f01015f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01015f4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015f7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015fa:	39 c6                	cmp    %eax,%esi
f01015fc:	73 35                	jae    f0101633 <memmove+0x47>
f01015fe:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101601:	39 d0                	cmp    %edx,%eax
f0101603:	73 2e                	jae    f0101633 <memmove+0x47>
		s += n;
		d += n;
f0101605:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101608:	89 d6                	mov    %edx,%esi
f010160a:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010160c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101612:	75 13                	jne    f0101627 <memmove+0x3b>
f0101614:	f6 c1 03             	test   $0x3,%cl
f0101617:	75 0e                	jne    f0101627 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101619:	83 ef 04             	sub    $0x4,%edi
f010161c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010161f:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101622:	fd                   	std    
f0101623:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101625:	eb 09                	jmp    f0101630 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101627:	83 ef 01             	sub    $0x1,%edi
f010162a:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010162d:	fd                   	std    
f010162e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101630:	fc                   	cld    
f0101631:	eb 1d                	jmp    f0101650 <memmove+0x64>
f0101633:	89 f2                	mov    %esi,%edx
f0101635:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101637:	f6 c2 03             	test   $0x3,%dl
f010163a:	75 0f                	jne    f010164b <memmove+0x5f>
f010163c:	f6 c1 03             	test   $0x3,%cl
f010163f:	75 0a                	jne    f010164b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101641:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101644:	89 c7                	mov    %eax,%edi
f0101646:	fc                   	cld    
f0101647:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101649:	eb 05                	jmp    f0101650 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010164b:	89 c7                	mov    %eax,%edi
f010164d:	fc                   	cld    
f010164e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101650:	5e                   	pop    %esi
f0101651:	5f                   	pop    %edi
f0101652:	5d                   	pop    %ebp
f0101653:	c3                   	ret    

f0101654 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101654:	55                   	push   %ebp
f0101655:	89 e5                	mov    %esp,%ebp
f0101657:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010165a:	8b 45 10             	mov    0x10(%ebp),%eax
f010165d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101661:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101664:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101668:	8b 45 08             	mov    0x8(%ebp),%eax
f010166b:	89 04 24             	mov    %eax,(%esp)
f010166e:	e8 79 ff ff ff       	call   f01015ec <memmove>
}
f0101673:	c9                   	leave  
f0101674:	c3                   	ret    

f0101675 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101675:	55                   	push   %ebp
f0101676:	89 e5                	mov    %esp,%ebp
f0101678:	57                   	push   %edi
f0101679:	56                   	push   %esi
f010167a:	53                   	push   %ebx
f010167b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010167e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101681:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101684:	8d 78 ff             	lea    -0x1(%eax),%edi
f0101687:	85 c0                	test   %eax,%eax
f0101689:	74 36                	je     f01016c1 <memcmp+0x4c>
		if (*s1 != *s2)
f010168b:	0f b6 03             	movzbl (%ebx),%eax
f010168e:	0f b6 0e             	movzbl (%esi),%ecx
f0101691:	ba 00 00 00 00       	mov    $0x0,%edx
f0101696:	38 c8                	cmp    %cl,%al
f0101698:	74 1c                	je     f01016b6 <memcmp+0x41>
f010169a:	eb 10                	jmp    f01016ac <memcmp+0x37>
f010169c:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01016a1:	83 c2 01             	add    $0x1,%edx
f01016a4:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01016a8:	38 c8                	cmp    %cl,%al
f01016aa:	74 0a                	je     f01016b6 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f01016ac:	0f b6 c0             	movzbl %al,%eax
f01016af:	0f b6 c9             	movzbl %cl,%ecx
f01016b2:	29 c8                	sub    %ecx,%eax
f01016b4:	eb 10                	jmp    f01016c6 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016b6:	39 fa                	cmp    %edi,%edx
f01016b8:	75 e2                	jne    f010169c <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01016bf:	eb 05                	jmp    f01016c6 <memcmp+0x51>
f01016c1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016c6:	5b                   	pop    %ebx
f01016c7:	5e                   	pop    %esi
f01016c8:	5f                   	pop    %edi
f01016c9:	5d                   	pop    %ebp
f01016ca:	c3                   	ret    

f01016cb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016cb:	55                   	push   %ebp
f01016cc:	89 e5                	mov    %esp,%ebp
f01016ce:	53                   	push   %ebx
f01016cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01016d2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f01016d5:	89 c2                	mov    %eax,%edx
f01016d7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016da:	39 d0                	cmp    %edx,%eax
f01016dc:	73 14                	jae    f01016f2 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016de:	89 d9                	mov    %ebx,%ecx
f01016e0:	38 18                	cmp    %bl,(%eax)
f01016e2:	75 06                	jne    f01016ea <memfind+0x1f>
f01016e4:	eb 0c                	jmp    f01016f2 <memfind+0x27>
f01016e6:	38 08                	cmp    %cl,(%eax)
f01016e8:	74 08                	je     f01016f2 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01016ea:	83 c0 01             	add    $0x1,%eax
f01016ed:	39 d0                	cmp    %edx,%eax
f01016ef:	90                   	nop
f01016f0:	75 f4                	jne    f01016e6 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01016f2:	5b                   	pop    %ebx
f01016f3:	5d                   	pop    %ebp
f01016f4:	c3                   	ret    

f01016f5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016f5:	55                   	push   %ebp
f01016f6:	89 e5                	mov    %esp,%ebp
f01016f8:	57                   	push   %edi
f01016f9:	56                   	push   %esi
f01016fa:	53                   	push   %ebx
f01016fb:	8b 55 08             	mov    0x8(%ebp),%edx
f01016fe:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101701:	0f b6 0a             	movzbl (%edx),%ecx
f0101704:	80 f9 09             	cmp    $0x9,%cl
f0101707:	74 05                	je     f010170e <strtol+0x19>
f0101709:	80 f9 20             	cmp    $0x20,%cl
f010170c:	75 10                	jne    f010171e <strtol+0x29>
		s++;
f010170e:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101711:	0f b6 0a             	movzbl (%edx),%ecx
f0101714:	80 f9 09             	cmp    $0x9,%cl
f0101717:	74 f5                	je     f010170e <strtol+0x19>
f0101719:	80 f9 20             	cmp    $0x20,%cl
f010171c:	74 f0                	je     f010170e <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f010171e:	80 f9 2b             	cmp    $0x2b,%cl
f0101721:	75 0a                	jne    f010172d <strtol+0x38>
		s++;
f0101723:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101726:	bf 00 00 00 00       	mov    $0x0,%edi
f010172b:	eb 11                	jmp    f010173e <strtol+0x49>
f010172d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101732:	80 f9 2d             	cmp    $0x2d,%cl
f0101735:	75 07                	jne    f010173e <strtol+0x49>
		s++, neg = 1;
f0101737:	83 c2 01             	add    $0x1,%edx
f010173a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010173e:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101743:	75 15                	jne    f010175a <strtol+0x65>
f0101745:	80 3a 30             	cmpb   $0x30,(%edx)
f0101748:	75 10                	jne    f010175a <strtol+0x65>
f010174a:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010174e:	75 0a                	jne    f010175a <strtol+0x65>
		s += 2, base = 16;
f0101750:	83 c2 02             	add    $0x2,%edx
f0101753:	b8 10 00 00 00       	mov    $0x10,%eax
f0101758:	eb 10                	jmp    f010176a <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f010175a:	85 c0                	test   %eax,%eax
f010175c:	75 0c                	jne    f010176a <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010175e:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101760:	80 3a 30             	cmpb   $0x30,(%edx)
f0101763:	75 05                	jne    f010176a <strtol+0x75>
		s++, base = 8;
f0101765:	83 c2 01             	add    $0x1,%edx
f0101768:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010176a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010176f:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101772:	0f b6 0a             	movzbl (%edx),%ecx
f0101775:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101778:	89 f0                	mov    %esi,%eax
f010177a:	3c 09                	cmp    $0x9,%al
f010177c:	77 08                	ja     f0101786 <strtol+0x91>
			dig = *s - '0';
f010177e:	0f be c9             	movsbl %cl,%ecx
f0101781:	83 e9 30             	sub    $0x30,%ecx
f0101784:	eb 20                	jmp    f01017a6 <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f0101786:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0101789:	89 f0                	mov    %esi,%eax
f010178b:	3c 19                	cmp    $0x19,%al
f010178d:	77 08                	ja     f0101797 <strtol+0xa2>
			dig = *s - 'a' + 10;
f010178f:	0f be c9             	movsbl %cl,%ecx
f0101792:	83 e9 57             	sub    $0x57,%ecx
f0101795:	eb 0f                	jmp    f01017a6 <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f0101797:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010179a:	89 f0                	mov    %esi,%eax
f010179c:	3c 19                	cmp    $0x19,%al
f010179e:	77 16                	ja     f01017b6 <strtol+0xc1>
			dig = *s - 'A' + 10;
f01017a0:	0f be c9             	movsbl %cl,%ecx
f01017a3:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01017a6:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01017a9:	7d 0f                	jge    f01017ba <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01017ab:	83 c2 01             	add    $0x1,%edx
f01017ae:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01017b2:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01017b4:	eb bc                	jmp    f0101772 <strtol+0x7d>
f01017b6:	89 d8                	mov    %ebx,%eax
f01017b8:	eb 02                	jmp    f01017bc <strtol+0xc7>
f01017ba:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01017bc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017c0:	74 05                	je     f01017c7 <strtol+0xd2>
		*endptr = (char *) s;
f01017c2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017c5:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01017c7:	f7 d8                	neg    %eax
f01017c9:	85 ff                	test   %edi,%edi
f01017cb:	0f 44 c3             	cmove  %ebx,%eax
}
f01017ce:	5b                   	pop    %ebx
f01017cf:	5e                   	pop    %esi
f01017d0:	5f                   	pop    %edi
f01017d1:	5d                   	pop    %ebp
f01017d2:	c3                   	ret    
f01017d3:	66 90                	xchg   %ax,%ax
f01017d5:	66 90                	xchg   %ax,%ax
f01017d7:	66 90                	xchg   %ax,%ax
f01017d9:	66 90                	xchg   %ax,%ax
f01017db:	66 90                	xchg   %ax,%ax
f01017dd:	66 90                	xchg   %ax,%ax
f01017df:	90                   	nop

f01017e0 <__udivdi3>:
f01017e0:	55                   	push   %ebp
f01017e1:	57                   	push   %edi
f01017e2:	56                   	push   %esi
f01017e3:	83 ec 0c             	sub    $0xc,%esp
f01017e6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01017ea:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01017ee:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01017f2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017f6:	85 c0                	test   %eax,%eax
f01017f8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017fc:	89 ea                	mov    %ebp,%edx
f01017fe:	89 0c 24             	mov    %ecx,(%esp)
f0101801:	75 2d                	jne    f0101830 <__udivdi3+0x50>
f0101803:	39 e9                	cmp    %ebp,%ecx
f0101805:	77 61                	ja     f0101868 <__udivdi3+0x88>
f0101807:	85 c9                	test   %ecx,%ecx
f0101809:	89 ce                	mov    %ecx,%esi
f010180b:	75 0b                	jne    f0101818 <__udivdi3+0x38>
f010180d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101812:	31 d2                	xor    %edx,%edx
f0101814:	f7 f1                	div    %ecx
f0101816:	89 c6                	mov    %eax,%esi
f0101818:	31 d2                	xor    %edx,%edx
f010181a:	89 e8                	mov    %ebp,%eax
f010181c:	f7 f6                	div    %esi
f010181e:	89 c5                	mov    %eax,%ebp
f0101820:	89 f8                	mov    %edi,%eax
f0101822:	f7 f6                	div    %esi
f0101824:	89 ea                	mov    %ebp,%edx
f0101826:	83 c4 0c             	add    $0xc,%esp
f0101829:	5e                   	pop    %esi
f010182a:	5f                   	pop    %edi
f010182b:	5d                   	pop    %ebp
f010182c:	c3                   	ret    
f010182d:	8d 76 00             	lea    0x0(%esi),%esi
f0101830:	39 e8                	cmp    %ebp,%eax
f0101832:	77 24                	ja     f0101858 <__udivdi3+0x78>
f0101834:	0f bd e8             	bsr    %eax,%ebp
f0101837:	83 f5 1f             	xor    $0x1f,%ebp
f010183a:	75 3c                	jne    f0101878 <__udivdi3+0x98>
f010183c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101840:	39 34 24             	cmp    %esi,(%esp)
f0101843:	0f 86 9f 00 00 00    	jbe    f01018e8 <__udivdi3+0x108>
f0101849:	39 d0                	cmp    %edx,%eax
f010184b:	0f 82 97 00 00 00    	jb     f01018e8 <__udivdi3+0x108>
f0101851:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101858:	31 d2                	xor    %edx,%edx
f010185a:	31 c0                	xor    %eax,%eax
f010185c:	83 c4 0c             	add    $0xc,%esp
f010185f:	5e                   	pop    %esi
f0101860:	5f                   	pop    %edi
f0101861:	5d                   	pop    %ebp
f0101862:	c3                   	ret    
f0101863:	90                   	nop
f0101864:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101868:	89 f8                	mov    %edi,%eax
f010186a:	f7 f1                	div    %ecx
f010186c:	31 d2                	xor    %edx,%edx
f010186e:	83 c4 0c             	add    $0xc,%esp
f0101871:	5e                   	pop    %esi
f0101872:	5f                   	pop    %edi
f0101873:	5d                   	pop    %ebp
f0101874:	c3                   	ret    
f0101875:	8d 76 00             	lea    0x0(%esi),%esi
f0101878:	89 e9                	mov    %ebp,%ecx
f010187a:	8b 3c 24             	mov    (%esp),%edi
f010187d:	d3 e0                	shl    %cl,%eax
f010187f:	89 c6                	mov    %eax,%esi
f0101881:	b8 20 00 00 00       	mov    $0x20,%eax
f0101886:	29 e8                	sub    %ebp,%eax
f0101888:	89 c1                	mov    %eax,%ecx
f010188a:	d3 ef                	shr    %cl,%edi
f010188c:	89 e9                	mov    %ebp,%ecx
f010188e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101892:	8b 3c 24             	mov    (%esp),%edi
f0101895:	09 74 24 08          	or     %esi,0x8(%esp)
f0101899:	89 d6                	mov    %edx,%esi
f010189b:	d3 e7                	shl    %cl,%edi
f010189d:	89 c1                	mov    %eax,%ecx
f010189f:	89 3c 24             	mov    %edi,(%esp)
f01018a2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018a6:	d3 ee                	shr    %cl,%esi
f01018a8:	89 e9                	mov    %ebp,%ecx
f01018aa:	d3 e2                	shl    %cl,%edx
f01018ac:	89 c1                	mov    %eax,%ecx
f01018ae:	d3 ef                	shr    %cl,%edi
f01018b0:	09 d7                	or     %edx,%edi
f01018b2:	89 f2                	mov    %esi,%edx
f01018b4:	89 f8                	mov    %edi,%eax
f01018b6:	f7 74 24 08          	divl   0x8(%esp)
f01018ba:	89 d6                	mov    %edx,%esi
f01018bc:	89 c7                	mov    %eax,%edi
f01018be:	f7 24 24             	mull   (%esp)
f01018c1:	39 d6                	cmp    %edx,%esi
f01018c3:	89 14 24             	mov    %edx,(%esp)
f01018c6:	72 30                	jb     f01018f8 <__udivdi3+0x118>
f01018c8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01018cc:	89 e9                	mov    %ebp,%ecx
f01018ce:	d3 e2                	shl    %cl,%edx
f01018d0:	39 c2                	cmp    %eax,%edx
f01018d2:	73 05                	jae    f01018d9 <__udivdi3+0xf9>
f01018d4:	3b 34 24             	cmp    (%esp),%esi
f01018d7:	74 1f                	je     f01018f8 <__udivdi3+0x118>
f01018d9:	89 f8                	mov    %edi,%eax
f01018db:	31 d2                	xor    %edx,%edx
f01018dd:	e9 7a ff ff ff       	jmp    f010185c <__udivdi3+0x7c>
f01018e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018e8:	31 d2                	xor    %edx,%edx
f01018ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01018ef:	e9 68 ff ff ff       	jmp    f010185c <__udivdi3+0x7c>
f01018f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018f8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01018fb:	31 d2                	xor    %edx,%edx
f01018fd:	83 c4 0c             	add    $0xc,%esp
f0101900:	5e                   	pop    %esi
f0101901:	5f                   	pop    %edi
f0101902:	5d                   	pop    %ebp
f0101903:	c3                   	ret    
f0101904:	66 90                	xchg   %ax,%ax
f0101906:	66 90                	xchg   %ax,%ax
f0101908:	66 90                	xchg   %ax,%ax
f010190a:	66 90                	xchg   %ax,%ax
f010190c:	66 90                	xchg   %ax,%ax
f010190e:	66 90                	xchg   %ax,%ax

f0101910 <__umoddi3>:
f0101910:	55                   	push   %ebp
f0101911:	57                   	push   %edi
f0101912:	56                   	push   %esi
f0101913:	83 ec 14             	sub    $0x14,%esp
f0101916:	8b 44 24 28          	mov    0x28(%esp),%eax
f010191a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010191e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101922:	89 c7                	mov    %eax,%edi
f0101924:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101928:	8b 44 24 30          	mov    0x30(%esp),%eax
f010192c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101930:	89 34 24             	mov    %esi,(%esp)
f0101933:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101937:	85 c0                	test   %eax,%eax
f0101939:	89 c2                	mov    %eax,%edx
f010193b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010193f:	75 17                	jne    f0101958 <__umoddi3+0x48>
f0101941:	39 fe                	cmp    %edi,%esi
f0101943:	76 4b                	jbe    f0101990 <__umoddi3+0x80>
f0101945:	89 c8                	mov    %ecx,%eax
f0101947:	89 fa                	mov    %edi,%edx
f0101949:	f7 f6                	div    %esi
f010194b:	89 d0                	mov    %edx,%eax
f010194d:	31 d2                	xor    %edx,%edx
f010194f:	83 c4 14             	add    $0x14,%esp
f0101952:	5e                   	pop    %esi
f0101953:	5f                   	pop    %edi
f0101954:	5d                   	pop    %ebp
f0101955:	c3                   	ret    
f0101956:	66 90                	xchg   %ax,%ax
f0101958:	39 f8                	cmp    %edi,%eax
f010195a:	77 54                	ja     f01019b0 <__umoddi3+0xa0>
f010195c:	0f bd e8             	bsr    %eax,%ebp
f010195f:	83 f5 1f             	xor    $0x1f,%ebp
f0101962:	75 5c                	jne    f01019c0 <__umoddi3+0xb0>
f0101964:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101968:	39 3c 24             	cmp    %edi,(%esp)
f010196b:	0f 87 e7 00 00 00    	ja     f0101a58 <__umoddi3+0x148>
f0101971:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101975:	29 f1                	sub    %esi,%ecx
f0101977:	19 c7                	sbb    %eax,%edi
f0101979:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010197d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101981:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101985:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101989:	83 c4 14             	add    $0x14,%esp
f010198c:	5e                   	pop    %esi
f010198d:	5f                   	pop    %edi
f010198e:	5d                   	pop    %ebp
f010198f:	c3                   	ret    
f0101990:	85 f6                	test   %esi,%esi
f0101992:	89 f5                	mov    %esi,%ebp
f0101994:	75 0b                	jne    f01019a1 <__umoddi3+0x91>
f0101996:	b8 01 00 00 00       	mov    $0x1,%eax
f010199b:	31 d2                	xor    %edx,%edx
f010199d:	f7 f6                	div    %esi
f010199f:	89 c5                	mov    %eax,%ebp
f01019a1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01019a5:	31 d2                	xor    %edx,%edx
f01019a7:	f7 f5                	div    %ebp
f01019a9:	89 c8                	mov    %ecx,%eax
f01019ab:	f7 f5                	div    %ebp
f01019ad:	eb 9c                	jmp    f010194b <__umoddi3+0x3b>
f01019af:	90                   	nop
f01019b0:	89 c8                	mov    %ecx,%eax
f01019b2:	89 fa                	mov    %edi,%edx
f01019b4:	83 c4 14             	add    $0x14,%esp
f01019b7:	5e                   	pop    %esi
f01019b8:	5f                   	pop    %edi
f01019b9:	5d                   	pop    %ebp
f01019ba:	c3                   	ret    
f01019bb:	90                   	nop
f01019bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019c0:	8b 04 24             	mov    (%esp),%eax
f01019c3:	be 20 00 00 00       	mov    $0x20,%esi
f01019c8:	89 e9                	mov    %ebp,%ecx
f01019ca:	29 ee                	sub    %ebp,%esi
f01019cc:	d3 e2                	shl    %cl,%edx
f01019ce:	89 f1                	mov    %esi,%ecx
f01019d0:	d3 e8                	shr    %cl,%eax
f01019d2:	89 e9                	mov    %ebp,%ecx
f01019d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019d8:	8b 04 24             	mov    (%esp),%eax
f01019db:	09 54 24 04          	or     %edx,0x4(%esp)
f01019df:	89 fa                	mov    %edi,%edx
f01019e1:	d3 e0                	shl    %cl,%eax
f01019e3:	89 f1                	mov    %esi,%ecx
f01019e5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019e9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01019ed:	d3 ea                	shr    %cl,%edx
f01019ef:	89 e9                	mov    %ebp,%ecx
f01019f1:	d3 e7                	shl    %cl,%edi
f01019f3:	89 f1                	mov    %esi,%ecx
f01019f5:	d3 e8                	shr    %cl,%eax
f01019f7:	89 e9                	mov    %ebp,%ecx
f01019f9:	09 f8                	or     %edi,%eax
f01019fb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01019ff:	f7 74 24 04          	divl   0x4(%esp)
f0101a03:	d3 e7                	shl    %cl,%edi
f0101a05:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a09:	89 d7                	mov    %edx,%edi
f0101a0b:	f7 64 24 08          	mull   0x8(%esp)
f0101a0f:	39 d7                	cmp    %edx,%edi
f0101a11:	89 c1                	mov    %eax,%ecx
f0101a13:	89 14 24             	mov    %edx,(%esp)
f0101a16:	72 2c                	jb     f0101a44 <__umoddi3+0x134>
f0101a18:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0101a1c:	72 22                	jb     f0101a40 <__umoddi3+0x130>
f0101a1e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101a22:	29 c8                	sub    %ecx,%eax
f0101a24:	19 d7                	sbb    %edx,%edi
f0101a26:	89 e9                	mov    %ebp,%ecx
f0101a28:	89 fa                	mov    %edi,%edx
f0101a2a:	d3 e8                	shr    %cl,%eax
f0101a2c:	89 f1                	mov    %esi,%ecx
f0101a2e:	d3 e2                	shl    %cl,%edx
f0101a30:	89 e9                	mov    %ebp,%ecx
f0101a32:	d3 ef                	shr    %cl,%edi
f0101a34:	09 d0                	or     %edx,%eax
f0101a36:	89 fa                	mov    %edi,%edx
f0101a38:	83 c4 14             	add    $0x14,%esp
f0101a3b:	5e                   	pop    %esi
f0101a3c:	5f                   	pop    %edi
f0101a3d:	5d                   	pop    %ebp
f0101a3e:	c3                   	ret    
f0101a3f:	90                   	nop
f0101a40:	39 d7                	cmp    %edx,%edi
f0101a42:	75 da                	jne    f0101a1e <__umoddi3+0x10e>
f0101a44:	8b 14 24             	mov    (%esp),%edx
f0101a47:	89 c1                	mov    %eax,%ecx
f0101a49:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101a4d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101a51:	eb cb                	jmp    f0101a1e <__umoddi3+0x10e>
f0101a53:	90                   	nop
f0101a54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a58:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101a5c:	0f 82 0f ff ff ff    	jb     f0101971 <__umoddi3+0x61>
f0101a62:	e9 1a ff ff ff       	jmp    f0101981 <__umoddi3+0x71>
