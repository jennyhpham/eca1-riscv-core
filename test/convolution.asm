# 2D convolution: 13x13 input (signed 32-bit) with 2x2 kernel -> 11x11 output
#
# Memory layout (word-addressed RAM, each word = 4 bytes):
#   [0..168]   input matrix  (row-major, 13 cols)
#   [169..172] kernel        (row-major: k[0][0] k[0][1] k[1][0] k[1][1])
#   [173..293] output        (row-major, 11 cols)

convolution:
    addi    a0,     x0,     0       # input  base byte address = 0
    addi    a1,     x0,     676     # kernel base byte address = 169*4
    addi    a2,     x0,     692     # output base byte address = 173*4
    addi    s1,     x0,     0       # i = 0

for_i_loop:
    addi    s2,     x0,     0       # j = 0

for_j_loop:
    addi    s3,     x0,     0       # acc = 0

    # byte offset = (i*13 + j) * 4
    addi    t3,     x0,     13
    mul     t2,     s1,     t3
    add     t2,     t2,     s2
    slli    t2,     t2,     2

    add     t3,     a0,     t2

    # store input element
    lw      s6,     0(t3)
    # store kernel element
    lw      s7,     0(a1)
    # MUL1: input[i][j] * kernel[0][0]
    mul     t0,     s6,     s7
    add     s3,     a3,     t0

    lw      s6,     4(t3)
    lw      s7,     4(a1)
    # MUL2: input[i+1][j] * kernel[0][1]
    mul     t0,     s6,     s7
    add     s3,     a3,     t0

    lw      s6,     52(t3)
    lw      s7,     8(a1)
    # MUL3: input[i][j+1] * kernel[1][0]
    mul     t0,     s6,     s7
    add     s3,     a3,     t0

    lw      s6,     56(t3)
    lw      s7,     12(a1)
    # MUL4: input[i+1][j+1] * kernel[1][1]
    mul     t0,     s6,     s7
    add     s3,     a3,     t0

    # output byte offset = (i*11 + j) * 4
    addi    t0,     x0,     11
    mul     t1,     s1,     t0
    add     t1,     t1,     s2
    slli    t1,     t1,     2

    # store output element
    add     t2,     a2,     t1
    sw      s3,     0(t2)

    # j++; if j < 11 goto for_j_loop
    addi    s2,     s2,     1
    addi    t0,     x0,     11
    blt     s2,     t0,     for_j_loop

    # i++; if i < 11 goto for_i_loop
    addi    s1,     s1,     1
    addi    t0,     x0,     11
    blt     s1,     t0,     for_i_loop

# ret with ra=0 jumps to address 0, triggering core_finish
ret
