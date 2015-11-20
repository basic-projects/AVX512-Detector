;------------------------------------------------------------------------------;
;          Processor and OS AVX and NVRAM support features detector            ;
;------------------------------------------------------------------------------;

format PE64 GUI
entry start
include 'win64a.inc'

;---------- Code section ------------------------------------------------------;

section '.text' code readable executable
start:
;--- Prepare context ---
sub rsp,8*5  ; Reserve stack for API use and make stack dqword aligned
cld

;--- Detect minimum ---
; Don't check EFLAGS.21, if control at this point, means CPUID supported
xor eax,eax         ; Function = 00000000h, check standard CPUID functions
cpuid
cmp eax,1
jb Lerror           ; Go error if CPUID function 80000001h not supported 
mov eax,80000000h   ; Function = 80000000h, check for extended CPUID functions
cpuid
cmp eax,80000004h
jb Lerror           ; Go error if CPUID function 80000004h not supported

;--- Read CPU name string ---
mov esi,80000002h
lea rdi,[NameBuffer]
L0:
mov eax,esi
cpuid
stosd
xchg eax,ebx
stosd
xchg eax,ecx
stosd
xchg eax,edx
stosd
inc esi
cmp esi,80000004h
jbe L0
;--- Pre-clear R14, R15 used as features bitmaps ---
xor r14d,r14d
xor r15d,r15d
;--- Check support AVX (Sandy Bridge) ---
; AVX feature = CPUID#1 bit ECX.28
;---
mov eax,1
cpuid           ; Get ECX:EDX = CPU Standard Features List
mov r14d,ecx    ; R14[31-0] = Storage for CPUID#1 ECX
;--- Check support OS context management features ---
; XMM128     context = XCR0.1
; YMM256     context = XCR0.2
; ZMM[0-15]  context = XCR0.6
; ZMM[16-31] context = XCR0.7
; K[0-7]     context = XCR0.5
;---
mov eax,008000000h
and ecx,eax
cmp ecx,eax
jne L1          ; Go skip if OSXSAVE(ECX.27) not supported
xor ecx,ecx
xgetbv
shl rax,32
or r14,rax      ; R14[63-32] = Storage for XCR0[31-00]
L1:
;--- Check support AVX2 (Haswell) ---
; AVX2 feature = CPUID#7 Subfunction#0 EBX.5 
;--- Check support AVX3 / AVX512F=Foundation (Skylake Xeon) ---
; AVX512F    feature = CPUID#7 Subfunction#0 EBX.16
; AVX512CD   feature = CPUID#7 Subfunction#0 EBX.28
; AVX512PF   feature = CPUID#7 Subfunction#0 EBX.26
; AVX512ER   feature = CPUID#7 Subfunction#0 EBX.27
; AVX512VL   feature = CPUID#7 Subfunction#0 EBX.31
; AVX512BW   feature = CPUID#7 Subfunction#0 EBX.30
; AVX512DQ   feature = CPUID#7 Subfunction#0 EBX.17
; AVX512IFMA feature = CPUID#7 Subfunction#0 EBX.21
; AVX512VBM  feature = CPUID#7 Subfunction#0 ECX.1
;--- Check support NV memory ---
; PCOMMIT instruction    = CPUID#7 Subfunction#0 EBX.22
; CLFLUSHOPT instruction = CPUID#7 Subfunction#0 EBX.23
; CLWB instruction       = CPUID#7 Subfunction#0 EBX.24
;---
xor eax,eax
cpuid
cmp eax,7
jb L2
mov eax,7
xor ecx,ecx
cpuid
mov r15d,ebx    ; R15[31-00] = Storage for CPUID#7 EBX
shl rcx,32
or r15,rcx      ; R15[63-32] = Storage for CPUID#7 ECX
L2:
;--- Copy CPU name string, skip left spaces ---
lea rsi,[NameBuffer]
lea rdi,[WinMessage]
mov ecx,48
L10:            ; Skip left spaces in the CPU name string
lodsb
cmp al,' '
loope L10
jrcxz L11
dec rsi
L17:              ; Copy CPU name string without left spaces and zeroes
lodsb
cmp al,0
jne L16
mov al,' '
L16:
stosb
loop L17
L11:
;--- Built text block ---
lea rbx,[VisualEntries]
L12:
mov rdi,[rbx]         ; Get destination string from Visual Entry (VE)
mov cl,[rbx+8]        ; Get control byte from Visual Entry (VE) 
mov rax,r14
test cl,40h           ; Control byte, bit[6] = Select 0=R14, 1=R15
jz L14
mov rax,r15
L14:
mov edx,ecx
and edx,3Fh           ; Control byte, bits[5-0] = tested bit number
bt rax,rdx            ; Test selected feature bit, set CF=1 if bit=1
lea rsi,[Sup]         ; RSI = Pointer to string "supported"
jc L13                ; If "1" means supported
lea rsi,[Nsup]        ; RSI = Pointer to string "not supported"
L13:                  ; Cycle for copy string
lodsb
cmp al,0
je L15
stosb
jmp L13
L15:
add rbx,9
test cl,cl            ; Control byte, bit[7] = Termination flag (1 = last entry)
jns L12               ; Cycle if this entry not last
;--- Visualize text strings in the window ---
lea rdx,[WinMessage]  ; RDX = Parm #2 = Message
lea r8,[WinCaption]   ; R8  = Parm #3 = Caption (upper message)
xor r9d,r9d           ; R9  = Parm #4 = Message flags
Lmsg:
xor ecx,ecx           ; RCX = Parm #1 = Parent window
call [MessageBoxA]
;--- Exit program ---
xor ecx,ecx           ; ECX = Parm #1
call [ExitProcess]
;--- Errors handling: if too old CPU ---
Lerror:
lea rdx,[WinError]
xor r8d,r8d           ; 0 means error message window
mov r9d,MB_ICONERROR  ; Message Box = Icon Error
jmp Lmsg 

;---------- Data section ------------------------------------------------------;

section '.data' data readable writeable
WinError     DB 'Too old CPU',0
WinCaption   DB ' Processor and OS information',0
NameBuffer   DB 48 DUP (' ')
WinMessage   DB 48 DUP (' '),0Ah,0Dh,0Ah,0Dh
             DB 'Processor AVX features, detect by CPUID',0Ah,0Dh
             DB 'AVX 256-bit : '
s1           DB '             ',0Ah,0Dh
             DB 'AVX2 256-bit : '
s2           DB '             ',0Ah,0Dh
             DB 'AVX3 512-bit = AVX512F (Foundation) : '
s3           DB '             ',0Ah,0Dh
             DB 'AVX512CD (Conflict Detection) : '
scd          DB '             ',0Ah,0Dh          
             DB 'AVX512PF (Prefetch) : '
spf          DB '             ',0Ah,0Dh          
             DB 'AVX512ER (Exponential and Reciprocal) : '
ser          DB '             ',0Ah,0Dh          
             DB 'AVX512VL (Vector Length) : '
svl          DB '             ',0Ah,0Dh          
             DB 'AVX512BW (Byte and Word) : '
sbw          DB '             ',0Ah,0Dh          
             DB 'AVX512DQ (Doubleword and Quadword) : '
sdq          DB '             ',0Ah,0Dh          
             DB 'AVX512IFMA (Integer Fused Multiply and Add) : '
sif          DB '             ',0Ah,0Dh          
             DB 'AVX512VBM (Vector Byte Manipulation) : '
svb          DB '             ',0Ah,0Dh, 0Ah, 0Dh
             DB 'OS context management features, detect by XCR0',0Ah,0Dh
             DB 'SSE128 registers XMM[0-15] bits [0-127] : '
sc1          DB '             ',0Ah, 0Dh
             DB 'AVX256 registers YMM[0-15] bits [128-255] : '
sc2          DB '             ',0Ah, 0Dh
             DB 'AVX512 registers ZMM[0-15] bits[511-256] : '
sc3          DB '             ',0Ah, 0Dh
             DB 'AVX512 registers ZMM[16-31] bits[0-511] : '
sc4          DB '             ',0Ah, 0Dh
             DB 'AVX512 predicate registers K[0-7] : '
sc5          DB '             ',0Ah, 0Dh,0Ah,0Dh
             DB 'Processor NV memory features, detect by CPUID',0Ah,0Dh
             DB 'PCOMMIT : '
sm1          DB '             ',0Ah, 0Dh
             DB 'CLFLUSHOPT : '
sm2          DB '             ',0Ah, 0Dh
             DB 'CLWB : '
sm3          DB '             ',0Ah, 0Dh
             DB 0

Sup          DB 'supported',0
Nsup         DB 'not supported',0

; This macro for pointer to updated string = F (tested bit)
; VE means Visual Entry
MACRO VE x1,x2,x3,x4
{       
; Pointer to string for write " supported / not supported "
DQ  x1 
; x2 = bits[5-0] = bit number in the 64-bit register
; x3 = bit[6] = register number: 0=R14, 1=R15, 2=Reserved, 3=Reserved
; x4 = bit[7] = last entry indicator, "1" means this last, but valid
DB  x4 shl 7 + x3 shl 6 + x2    
}        

VisualEntries:
; CPU AVX features
VE  s1  , 28+00 , 0 , 0
VE  s2  , 05+00 , 1 , 0
VE  s3  , 16+00 , 1 , 0
VE  scd , 28+00 , 1 , 0
VE  spf , 26+00 , 1 , 0
VE  ser , 27+00 , 1 , 0
VE  svl , 31+00 , 1 , 0
VE  sbw , 30+00 , 1 , 0
VE  sdq , 17+00 , 1 , 0
VE  sif , 21+00 , 1 , 0
VE  svb , 01+32 , 1 , 0
; OS context management features
VE  sc1 , 01+32 , 0 , 0
VE  sc2 , 02+32 , 0 , 0
VE  sc3 , 06+32 , 0 , 0
VE  sc4 , 07+32 , 0 , 0
VE  sc5 , 05+32 , 0 , 0 
; CPU NV memory features
VE  sm1 , 22+00 , 1 , 0
VE  sm2 , 23+00 , 1 , 0
VE  sm3 , 24+00 , 1 , 1

;---------- Imported data section ---------------------------------------------;

section '.idata' import data readable writeable
library kernel32 , 'KERNEL32.DLL' , user32 , 'USER32.DLL'
include 'api\kernel32.inc'
include 'api\user32.inc'

;---------- Fixups section ----------------------------------------------------;

data fixups
end data
