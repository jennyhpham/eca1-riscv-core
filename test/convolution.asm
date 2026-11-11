# 2D convolution: 13x13 input (signed 32-bit) with 2x2 kernel -> 11x11 output
# OPTIMIZED: kernel register caching + loop-invariant code motion + 2x2 loop unrolling
#
# Memory layout (word-addressed RAM, each word = 4 bytes):
#   [0..168]   input matrix  (row-major, 13 cols)
#   [169..172] kernel        (row-major: k[0][0] k[0][1] k[1][0] k[1][1])
#   [173..293] output        (row-major, 11 cols)
#
# Register map:
#   a0 = input base, a1 = kernel base, a2 = output base
#   s1 = i, s2 = j, s3 = acc
#   s8..s11 = cached kernel values k00,k01,k10,k11
#   t0 = i*11 (output row base, words)  [moved out of j loop]
#   t1 = i*13 (input row base, words)   [moved out of j loop]
#   t2, t3 = scratch
#   t4 = 13 (constant), t5 = 11 (constant + loop bound)
#   t6 = 52 (row stride in bytes = 13*4; built via slli because the core
#          mis-executes `addi` with immediates 32..63 as MUL — see report)

convolution:
    addi    a0,     x0,     0       # input  base byte address = 0
    addi    a1,     x0,     676     # kernel base byte address = 169*4
    addi    a2,     x0,     692     # output base byte address = 173*4
    addi    t4,     x0,     13      # constant 13 computed ONCE
    addi    t5,     x0,     11      # constant 11 computed ONCE
    slli    t6,     t4,     2       # t6 = 52 (row stride bytes); addi with 52
                                    # would be mis-executed as MUL by the core

    # -KERNEL REGISTER CACHING: load all 4 kernel values ONCE 
    lw      s8,     0(a1)           # k[0][0]
    lw      s9,     4(a1)           # k[0][1]
    lw      s10,    8(a1)           # k[1][0]
    lw      s11,    12(a1)          # k[1][1]

    addi    s1,     x0,     0       # i = 0

for_i_loop:
    # ---- [LICM] these depend only on i, not on j -> compute once per i ----
    mul     t0,     s1,     t5      # output row base  = i*11 (words)
    mul     t1,     s1,     t4      # input  row base  = i*13 (words)
    addi    s2,     x0,     0       # j = 0

for_j_loop:
    addi    s3,     x0,     0       # acc = 0

    # ---- input address: &in[i][j] ----
    # [LICM] was: add,add,addi,mul,add,slli,add per load (constant 13 + i*13 recomputed)
    # now: i*13 already in t1, only add j
    add     t2,     t1,     s2      # word index = i*13 + j
    slli    t2,     t2,     2       # byte offset
    add     t3,     a0,     t2      # t3 = &in[i][j]

    # ---- 2x2 window, row ki=0: two adjacent elements ----
    lw      s6,     0(t3)           # in[i][j]
    lw      s7,     4(t3)           # in[i][j+1]
    mul     t2,     s6,     s8      # acc += in[i][j]   * k[0][0]   <- cached reg
    add     s3,     s3,     t2
    mul     t2,     s7,     s9      # acc += in[i][j+1] * k[0][1]   <- cached reg
    add     s3,     s3,     t2

    # ---- 2x2 window, row ki=1: same columns, one row down ----
    # one row down in a 13-wide row-major matrix = +13 words = +52 bytes
    add     t3,     t3,     t6      # t3 = &in[i+1][j]
    lw      s6,     0(t3)           # in[i+1][j]
    lw      s7,     4(t3)           # in[i+1][j+1]
    mul     t2,     s6,     s10     # acc += in[i+1][j]   * k[1][0] <- cached reg
    add     s3,     s3,     t2
    mul     t2,     s7,     s11     # acc += in[i+1][j+1] * k[1][1] <- cached reg
    add     s3,     s3,     t2

    # ---- store output ----
    # [LICM] was: addi,mul,add,slli,add per store (i*11 recomputed) -> now i*11 in t0
    add     t2,     t0,     s2      # word index = i*11 + j
    slli    t2,     t2,     2
    add     t2,     a2,     t2
    sw      s3,     0(t2)

    # j++; if j < 11 goto for_j_loop
    addi    s2,     s2,     1
    blt     s2,     t5,     for_j_loop

    # i++; if i < 11 goto for_i_loop
    addi    s1,     s1,     1
    blt     s1,     t5,     for_i_loop

# ret with ra=0 jumps to address 0, triggering core_finish
ret
