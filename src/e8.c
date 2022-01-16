#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <conio.h>

typedef unsigned char uint8_t;
typedef unsigned int  uint16_t;
typedef unsigned long uint32_t;

// Interface to assembler:

extern void init_e_calc();
extern void nxt_dvsr();
extern uint8_t* asm_e;

// extern uint16_t e_sz;
// extern uint8_t  efrac[];
// extern uint8_t  term[];
// extern uint16_t n_terms;
// extern uint16_t divisor;

typedef struct
{
    size_t   size;
    uint8_t* data;
} big_num;

#define E_SZ 1024
#define E_DIGITS 2465
const uint16_t e_sz = E_SZ;
const uint16_t n_digits = E_DIGITS;
const uint16_t n_terms = 970;

// #define E_SZ 256
// #define E_DIGITS 615
// const uint16_t e_sz = E_SZ;
// const uint16_t n_digits = E_DIGITS;
// const uint16_t n_terms = 306;

// #define E_SZ 128
// const uint16_t e_sz = E_SZ;
// const uint16_t n_digits = 306;
// const uint16_t n_terms = 170;

// #define E_SZ     64
// #define E_DIGITS 154
// const uint16_t e_sz = E_SZ;
// const uint16_t n_digits = E_DIGITS;
// const uint16_t n_terms = 98;


uint8_t  efrac_[ E_SZ ];
uint8_t  term_[ E_SZ ];
//uint16_t divisor;

uint8_t  big_t_[ E_SZ ];
char     str_[ E_DIGITS + 1 ];

void big_zero( big_num* n )
{
    const size_t sz = n->size;
    uint8_t* p = n->data;
    size_t i;
    for( i=0; i<sz; ++i ) {
        *p++ = 0;
    }
}

void big_cpy( const big_num* a, big_num* b )
{
    const uint8_t* p    = a->data;
    uint8_t *q          = b->data;
    const size_t sz     = a->size;
    size_t i;
    for( i=0; i<sz; ++i ) {
        *q++ = *p++;
    }
}

int big_mul100( big_num* a )
{
    // FIXME: lookup tables?
    uint16_t ov = 0;
    const size_t sz = a->size;
    uint8_t* p = a->data + sz - 1;
    size_t i;
    for ( i = 0; i<sz; ++i ) {
        uint16_t m = 100 * (uint16_t)(*p) + ov;
        *p = (uint8_t)m;
        ov = ( m >> 8 ) & 0xff;
        --p;
    }
    return ov;
}

uint16_t mul100_tbl[256];

void init_mul100_tbl()
{
    uint16_t i;
    for( i=0; i<256; ++i ) {
        mul100_tbl[ i ] = 100 * i;
    }
}

int big_mul100_2( big_num* a )
{
    uint16_t ov = 0;
    const size_t sz = a->size;
    uint8_t* p = a->data + sz - 1;
    size_t i;
    for ( i = 0; i<sz; ++i ) {
        uint16_t m = mul100_tbl[ *p ] + ov;
        *p = (uint8_t)m;
        ov = ( m >> 8 ) & 0xff;
        --p;
    }
    return ov;
}

int big_mul100_3( big_num* a )
{
    uint8_t ov = 0;
    const size_t sz = a->size;
    uint8_t* p = a->data + sz - 1;
    uint8_t* q = a->data;
    while (p >= q) {
        uint16_t m = mul100_tbl[ *p ] + ov;
        *p = (uint8_t)m;
        ov = (uint8_t)( m >> 8 );
        --p;
    }
    return ov;
}


void big_to_str( big_num* a, size_t n_digits, big_num* tmp, char* str )
{
    const size_t n = n_digits / 2;
    char *p = str;
    size_t i;

    big_cpy( a, tmp );
    for ( i = 0; i < n; ++i ) {
        int ov = big_mul100( tmp );
        sprintf( p, "%02d", ov );
        p += 2 ;
    }
    *p = '\0';
}

char _units[256];
char _tens[256];

void init_to_str2()
{
    size_t i;
    for (i=0; i<256; ++i) {
        _tens[i] = '0' + ( ( i / 10 ) % 10 );
        _units[i] = '0' + i % 10; 
    }
}

void big_to_str2( big_num* a, size_t n_digits, big_num* tmp, char* str )
{
    const size_t n = n_digits / 2;
    char *p = str;
    size_t i;

    big_cpy( a, tmp );
    for ( i = 0; i < n; ++i ) {
        int ov = big_mul100_3( tmp );
        // // sprintf( p, "%02d", ov );
        // *p++ = '0' + ( (ov / 10) % 10 );
        // *p++ = '0' + ( ov % 10 );
        *p++ = _tens[ ov ];
        *p++ = _units[ ov ];
    }
    *p = '\0';
}

void print_bignum( big_num* a, size_t n_digits, big_num* tmp )
{
    const size_t n = n_digits / 2;
    size_t i;

    big_cpy( a, tmp );
    for ( i = 0; i < n; ++i ) {
        int ov = big_mul100_3( tmp );
        printf( "%c%c", _tens[ ov ], _units[ ov ] );
    }
}


static clock_t _clk;
void timer_reset()
{
    _clk = clock();
}

uint32_t timer_elapsed()
{
    // uint16_t t0 = ( 1000 * _clk  ) / CLOCKS_PER_SEC;
    // uint16_t t1 = ( 1000 * clock() ) / CLOCKS_PER_SEC;
    // uint32_t t0 = ( 100 * _clk  ) / ( CLOCKS_PER_SEC / 10 );
    // uint32_t t1 = ( 100 * clock() ) / ( CLOCKS_PER_SEC / 10 );
    // return t1 - t0;
    return ( 100 * ( clock() - _clk ) ) / ( CLOCKS_PER_SEC / 10 );
}


void big_div16( big_num* num, uint16_t divisor )
{
    const size_t sz = num->size;
    uint16_t r = 0;
    uint8_t* p = num->data;
    size_t i;
    for( i = 0; i < sz; ++i ) {
        uint16_t a = (uint16_t)( *p );
        uint8_t  q = 0;
        int j;
        for( j = 7; j >= 0; --j ) {
            r <<= 1;
            if ( a & ( 1 << j ) ) {
                r = r + 1;
            }
            if ( r >= divisor ) {
                r = r - divisor;
                q = q | ( 1 << j );
            }
        }
        *p = q;
        ++p;
    }
}

int big_add( big_num* a, big_num* b )
{
    if ( a->size != b->size ) {
        return -1;
    } else {
        const size_t sz = a->size;
        int ov = 0;
        if ( sz > 0 ) {
            uint8_t* p_a = a->data + sz - 1 ;
            uint8_t* p_b = b->data + sz - 1 ;
            size_t i;
            for( i = 0; i < sz; ++i ) {
                uint16_t a_b = *p_a;
                uint16_t b_b = *p_b;
                uint16_t s = a_b + b_b + ov;
                *p_a = (uint8_t)(s);
                ov = ( s > 255 ) ? 1 : 0;
                --p_a;
                --p_b;
            }
            return ov;
        } else {
            return 0;
        }
    }
}

#if 0
extern uint8_t* asm_start;
extern uint8_t* asm_end;
extern uint8_t* asm_addr;

void relocate_asm()
{
    uint8_t *p = asm_addr;
    uint8_t *q = asm_start;
    printf("Relocating machine code...");
    while( q < asm_end ) {
        *p++ = *q++;
    }
    printf("done\n");
}
#endif

int main( void )
{
    big_num efrac, term, tmp;
    uint32_t t;
    uint16_t divisor;
    size_t i;

    clrscr();

#if 0
    printf( "sizeof(uint8_t): %u\n", sizeof( uint8_t ) );
    printf( "sizeof(uint16_t): %u\n", sizeof( uint16_t ) );
    printf( "sizeof(size_t): %u\n", sizeof( size_t ) );
    printf( "sizeof(uint32_t): %u\n", sizeof( uint32_t ) );
    printf( "sizeof(clock_t): %u\n", sizeof( clock_t ) );
    printf( "sizeof(big_num): %u\n", sizeof( big_num ) );
    printf( "CLOCKS_PER_SEC: %u\n", CLOCKS_PER_SEC );
#endif

    // printf( "Relocating machine code...");
    // relocate_asm();
    // printf( "done\n");

    // printf( "Calling machine code..." );
    // nxt_dvsr();
    // printf( "ok\n" );


    printf( "Initialising... " );
    timer_reset();
    init_mul100_tbl();
    init_to_str2();
    init_e_calc();
    t = timer_elapsed();
    printf( "done, time: %lu\n", t );
    
#if 0
    // Initialise e_frac to 0.5
    efrac.size = e_sz;
    efrac.data = efrac_;
    big_zero( &efrac );
    efrac.data[0] = 0x80;

    // Initialise term to 0.5
    term.size = e_sz;
    term.data = term_;
    big_zero( &term );
    term.data[0] = 0x80;

    tmp.size = e_sz;
    tmp.data = big_t_;

    printf( "Calculating e... " );
    timer_reset();
    divisor = 3;
    for ( i=0 ; i < n_terms; ++i ) {
        big_div16( &term, divisor );
        ++divisor;
        big_add( &efrac, &term );
    }
    t = timer_elapsed();
    printf( "done, time: %lu\n", t );

    // timer_reset();
    // big_to_str( &efrac, n_digits, &tmp, str_ );
    // printf( "e: %s\n", str_ );
    // printf( "time: %lu\n", timer_elapsed() );
#if 0
    timer_reset();
    big_to_str2( &efrac, n_digits, &tmp, str_ );
    printf( "e: 2.%s\n", str_ );
    printf( "time: %lu\n", timer_elapsed() );
#endif
    printf( "e: 2." );
    print_bignum( &efrac, n_digits, &tmp );
    printf( "\n" );

    // big_to_str2( &term, n_digits, &tmp, str_ );
    // printf( "term: %s\n", str_ );
#endif
    efrac.size = e_sz;
    efrac.data = asm_e;

    tmp.size = e_sz;
    tmp.data = big_t_;

    big_zero( &efrac );
    //big_zero( &tmp );

    printf( "e addr: %x\n", asm_e );

    // printf( "e: 2." );
    // print_bignum( &efrac, n_digits, &tmp );
    // printf( "\n" );

    printf( "Calculating e (asm)... " );
    timer_reset();
    nxt_dvsr();
    t = timer_elapsed();
    printf( "done, time: %lu\n", t );

    printf( "e: 2.\n" );
    print_bignum( &efrac, n_digits, &tmp );
    printf( "\n" );

    return EXIT_SUCCESS;
}



