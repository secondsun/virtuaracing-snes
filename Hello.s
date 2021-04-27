; Hello
; David Lindecrantz <optiroc@gmail.com>
;
; Super basic example that decompresses and displays some graphics and plays an SPC song

.include "libSFX.i"

;read a byte from map, inc (mem), and save in x
.macro read_map_y
  ldy (mem)
  inc mem
.endmacro 

;VRAM destination addresses
VRAM_MAP_LOC     = $0000
VRAM_TILES_LOC   = $8000

Main:
  RW a16i16
  ldx #<MAP
  stx mapPointer ; map pointer is global
  ldx #mapPointer + 2
  stx heapPointer
  lda #$42
  jsr allocateA
  RW a8
  jsr unpack_array
  .dword unpack_model ;function pointer

: wai
  bra     :-

;function pointer at stack + 1
unpack_array: 
  RW a16i16
  lda #0; zero out accumulator
  RW a8
  jsr unpack_variant_to_a ; a has number of elements in array
  RW a16i16 ; A may be 16 bits
  tay ; move a to y
  pla ; get return
  ina
  ina ; modify return
  pha ; save new return addr
  dea ; a is function pointer now
  tax
  loop:
  jsr ($0, X)
  dey; countdown number of elements
  bne loop ;branch if not zero
  rts

unpack_model:
  pha
  lda #$DEAD
  pla
  rts

unpack_variant_to_a:
  phx ; push X
  RW a8i16
  ldx mapPointer ; read memory pointer
  lda $8000, X ; read map @x
  beq rtrn 
  bpl rtrn ; if A >= 0, return, else negate and shift
  and #$7F ; negate A
  xba ; swap high / low
  inc mapPointer ; mem++
  ldx mapPointer ; read memory
  lda $8000, X ; read map @x
rtrn: 
  inc mapPointer ; mem++
  plx ;pull x
  rts ;returns variant in a

;-------------------------------------------------------------------------------

;sets A to current heap
;adds value in A to heap
;requires a16i16
allocateA:
  phx
  ldx heapPointer ; X = old heap Pointer address
  adc heapPointer ; a = old Heap + memory on A
  sta heapPointer ; write a to heapPointer
  txa ; put old heap on A
  plx ; restore X;
  rts

;Import graphics
.segment "RODATA"
incbin MAP, "Data/title_map.bin"

.segment "LORAM"
mapPointer: .dword MAP ; mapPointer
heapPointer: .dword MAP+2