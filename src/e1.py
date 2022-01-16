from   numpy import uint8, uint16
import numpy as np
import math

def div_term( term, divisor ):
    n = len( term )
    r = 0
    for i in range( 0, n ):
        a = int( term[ i ] ) + r
        ( q, r_ ) = divmod( a, divisor )
        r = r_
        print( ( a, divisor, q, r ) )
        term[ i ] = uint8( q )
    return term

def div_term2( term, divisor ):
    n = len( term )
    b = 0
    for i in range( 0, n ):
        a = int( term[ i ] )
        a = a * 2
        a_carry = 1 if a > 255 else 0
        a = a % 256
        for x in range( 0, 8 ):
            b = b * 2
            b = b % 32768
            b = b + a_carry
            if b >= divisor:
                b = b - divisor
                q = 1
            else:
                q = 0
            a = a * 2
            a_carry = 1 if a > 255 else 0
            a = a % 256
            a = a + q
        print( ( term[ i ], divisor, a, b ) )
        term[ i ] = a
    return term

# FIXME: bit testing/selection quicker than shift, test, mod
# FIXME: mod may be actually quicker than uint16 conversion...
def div_term3( term, divisor ):
    n = len( term )
    b = uint16( 0 )
    for i in range( 0, n ):
        a = term[ i ]
        a = a * 2
        a_carry = 1 if a > 255 else 0
        a = a % 256
        for x in range( 0, 8 ):
            b = uint16( b * 2 )
            b = b + a_carry
            if b >= divisor:
                b = b - divisor
                q = 1
            else:
                q = 0
            a = a * 2
            a_carry = 1 if a > 255 else 0
            a = a % 256
            a = a + q
        term[ i ] = uint8( a )
    return term

# FIXME: bit testing/selection quicker than shift, test, mod
# FIXME: mod may be actually quicker than uint16 conversion...
def div_term4( term, divisor ):
    n = len( term )
    b = int( 0 )
    for i in range( 0, n ):
        a = int( term[ i ] )
        a = a * 2
        a_carry = 1 if a > 255 else 0
        a = a % 256
        for x in range( 0, 8 ):
            b = b * 2
            b = b % 65536
            b = b + a_carry
            if b >= divisor:
                b = b - divisor
                q = 1
            else:
                q = 0
            a = a * 2
            a_carry = 1 if a > 255 else 0
            a = a % 256
            a = a + q
        term[ i ] = uint8( a )
    return term

# From here: https://en.wikipedia.org/wiki/Division_algorithm
def div_term5( num, divisor ):
    n = len( num )
    r = 0
    for i in range( 0, n ):
        a = int( num[ i ] )
        q = 0
        for j in range( 7, -1, -1 ):
            r = r * 2
            if a & ( 1 << j ):
                r = r + 1
            if r >= divisor:
                r = r - divisor
                q = q | ( 1 << j )
        num[ i ] = q
    return num

def add_e( e, term ):
    n = len( term )
    for i in range( 0, n ):
        idx = ( n - 1 ) - i
        a = int( e[ idx ] ) + int( term[ idx ] )
        #print a
        e[ idx ] = uint8( a % 256 )
        if False and a > 255:
            raise Exception( 'Should never be any overflow' )
        if a > 255:
            ov = uint8( a / 256 )
            # print( 'overflow: {}'.format( str( ov ) ) )
            if idx > 0:
                e[ idx - 1 ] = e[ idx - 1 ] + ov
    return e


# Wrong...
def add_e2( e, term ):
    n = len( term )
    for i in range( n - 1, -1, -1 ):
        a = e[ i ] + term[ i ] # Will overflow as needed
        e[ i ] = uint8( a )
        if a > 255:
            if i == 0:
                raise Exception( 'Overflow' )
            else:
                e[ i - 1 ] = e[ i  - 1 ] + 1 # Overflow is only ever one bit
    return e

def add_e3( e, term ):
    n = len( term )
    for i in range( n - 1, -1, -1 ):
        a = int( e[ i ] ) + int( term[ i ] ) # Will overflow as needed
        e[ i ] = uint8( a )
        if a > 255:
            if i == 0:
                raise Exception( 'Overflow' )
            else:
                e[ i - 1 ] = e[ i - 1 ] + 1 # Overflow is only ever one bit
    return e

def mul_100( x ):
    y = x.copy()
    o = 0
    for i in range( len( y ) - 1, -1, -1 ):
        a = 100 * int( y[ i ] ) + o
        a_l = a % 256
        y[ i ] = a_l
        o = a // 256
    return (o, y)


def vec_to_bin( v ):
    return [ format( x, '08b' ) for x in v ]

def vec_to_hex( v ):
    return [ format( x, '02x' ) for x in v ]

def vec_to_float( v ):
    d = 1.0 / 256.0
    res = 0.0
    for x in v:
        res = res + ( float( x ) * d )
        d = d / 256.0
    return res

def main():
    # working_size = 14335
    # count = 9720
    working_size = 512
    count = 256
    # working_size = 256
    # count = 128
    # working_size = 128
    # count = 64
    # working_size = 8
    # count = 32
    term = np.zeros( working_size, dtype = uint8 )
    term[ 0 ] = uint8( 128 )
    e = np.zeros( working_size, dtype = uint8 )
    e[ 0 ] = uint8( 128 )
    divisor = uint8( 3 )
    for x in range( 0 , count ):
        #print( ''.join( vec_to_hex( term ) ) )
        #print( ''.join( vec_to_bin( term ) ) )
        # print( vec_to_float( e ), vec_to_float( term ) )
        ##print( ''.join( vec_to_hex( e ) ) )
        ##print( ''.join( vec_to_bin( e ) ) )
        #print( vec_to_float( e ) )
        term = div_term5( term, divisor )
        divisor = divisor + 1
        e = add_e3( e, term )
    print( '' )
    print( ''.join( vec_to_hex( term ) ) )
    print( ''.join( vec_to_bin( term ) ) )
    print( ''.join( vec_to_hex( e ) ) )
    print( ''.join( vec_to_bin( e ) ) )
    print( vec_to_float( e ) )

    #x = 0
    #for i in range( count ):
    #    y = int( e[ i ] )
    #    y = y - x
    #    y = y * 10
    #    d = 
    x = 0
    y = ( int( e[ 0 ] ) * 10 )
    print( ( y, hex( y ) ) )
    y_ = y // 256
    print( ( y_, hex( y_ ) ) )
    z = y % 256
    print( ( z, hex( z ) ) )
    z_ = z * 10
    print( ( z_, hex( z_ ) ) )
    z__ = z_ // 256
    print( ( z__, hex( z__ ) ) )
    x = z_ % 256
    print( (x, hex( x ) ) )
    y = ( int( e[ 1 ] ) * 10 )
    print( ( y, hex( y ) ) )
    y_ = y // 256
    print( ( y_, hex( y_ ) ) )
    z = y % 256
    print( ( z, hex( z ) ) )
    z_ = z * 10
    print( ( z_, hex( z_ ) ) )
    z__ = z_ // 256
    print( ( z__, hex( z__ ) ) )
    x = z_ % 256
    print( (x, hex( x ) ) )

    print( '' )
    y = ( int( e [ 0 ] ) ) * 10
    print( ( y, hex( y ) ) )
    z = ( int( e [ 0 ] ) ) * 100
    print( ( z, hex( z ) ) )

    ( o, e2 ) = mul_100( e )
    print( ( o, hex( o ) ) )
    print( ( e2[0], hex( e2[0] ) ) )

    ( o, e3 ) = mul_100( e2 )
    print( ( o, hex( o ) ) )
    print( ( e2[0], hex( e2[0] ) ) )

    e_ = e.copy()
    e_digits = []
    for i in range( working_size ):
        ( o, e_ ) = mul_100( e_ )
        e_digits.append( format( o, '02d' ) )
    print ''.join( e_digits )


    print( '' )
    print( 'first few float approximations' )
    d = 1.0 / 256.0
    e_ = 0.0
    for x in range( 5 ):
        e_ = e_ + float( e[ x ] ) * d
        d = d / 256.0
        print( e_ )
    print( '' )
    #e_ = float( e[0] ) / 256.0 + float( e[1] ) / ( 256.0 * 256.0 )
    #print( e_ )

    # Sanity check
    print( '' )
    print( 'float exp calc' )
    n = 32
    term = 0.5
    e = 0.5
    d = 3.0
    for x in range( 0, n ):
        term = term / d
        d = d + 1.0
        e = e + term
        #print( ( e, term ) )
    print( e )
    print( float.hex( e ) )

    print( 'math.exp' )
    e = math.exp( 1.0 ) - 2.0
    print( e )
    print( float.hex( e ) )

main()



# 100 * ( 256 + 255 ) = 0xc79c
# 100 * 255 = 0x639c
# 100 * 256 = 0x6400
# 100 * 1 = 0x64
#
# 100 * 255 = 0x639c + 0x0 = 0x639c -> 0x63, 0x9c
# 100 * 1 = 0x64 + 0x63 = 0xc7 -> 0x00, 0xc7


        