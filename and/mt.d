module mt;

/*
   A D-program ported by Derek Parnell 2006/04/12,
   based on the C-program for MT19937,  with initialization improved 2002/1/26,
      coded by Takuji Nishimura and Makoto Matsumoto.

   Before using, initialize the state by using init_genrand(seed)
   or init_by_array(init_key). However, if you do not
   a seed is generated based on the current date-time of the system.

   Derek Parnell: init_genrand, init_bt_array, and genrand_int32 all
   now take an optional boolean parameter. If 'true' then an new seed
   is generated using some limited entropy (clock and previous random).
   This is to increase the non-sequential set of returned values.

   Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura,
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

     1. Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

     2. Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.

     3. The names of its contributors may not be used to endorse or promote
        products derived from this software without specific prior written
        permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


   Any feedback is very welcome.
   http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html
   email: m-mat @ math.sci.hiroshima-u.ac.jp (remove space)
*/

private
{
  import and.platform;

    /* Period parameters */
    const uint N          = 624;
    const uint M          = 397;
    const uint MATRIX_A   = 0x9908b0df;   /* constant vector a */
    const uint UPPER_MASK = 0x80000000; /* most significant w-r bits */
    const uint LOWER_MASK = 0x7fffffff; /* least significant r bits */

    uint[N] mt; /* the array for the state vector  */
    uint mti=mt.length+1; /* mti==mt.length+1 means mt[] is not initialized */
    uint vLastRand; /* The most recent random uint returned. */
}

/* initializes mt[] with a seed */
void init_genrand(uint s, bool pAddEntropy = false)
{
    mt[0]= (s + (pAddEntropy ? vLastRand + /+std.date.getUTCtime()+/ Clock.currStdTime() + cast(uint)&init_genrand
                      : 0))
            &  0xffffffffUL;
    for (mti=1; mti<mt.length; mti++)
    {
        mt[mti] = cast(uint)(1812433253UL * (mt[mti-1] ^ (mt[mti-1] >> 30)) + mti);
        /* See Knuth TAOCP Vol2. 3rd Ed. P.106 for multiplier. */
        /* In the previous versions, MSBs of the seed affect   */
        /* only MSBs of the array mt[].                        */
        /* 2002/01/09 modified by Makoto Matsumoto             */
        mt[mti] &= 0xffffffffUL;
        /* for >32 bit machines */
    }
}

/* initialize by an array with array-length */
/* init_key is the array for initializing keys */
/* slight change for C++, 2004/2/26 */
void init_by_array(uint[] init_key, bool pAddEntropy = false)
{
    int i, j, k;
    init_genrand( 19650218UL, pAddEntropy);
    i=1;
    j=0;

    for (k = (mt.length > init_key.length ? mt.length : init_key.length); k; k--)
    {
        mt[i] = cast(uint)(mt[i] ^ ((mt[i-1] ^ (mt[i-1] >> 30)) * 1664525UL))
          + init_key[j] + j; /* non linear */
        mt[i] &=  0xffffffffUL; /* for WORDSIZE > 32 machines */
        i++;
        j++;

        if (i >= mt.length)
        {
            mt[0] = mt[mt.length-1];
            i=1;
        }

        if (j >= init_key.length)
            j=0;
    }

    for (k=mt.length-1; k; k--)
    {
        mt[i] = cast(uint)(mt[i] ^ ((mt[i-1] ^ (mt[i-1] >> 30)) * 1566083941UL))
          - i; /* non linear */
        mt[i] &=  0xffffffffUL; /* for WORDSIZE > 32 machines */
        i++;

        if (i>=mt.length)
        {
            mt[0] = mt[mt.length-1];
            i=1;
        }
    }
    mt[0] |=  0x80000000UL; /* MSB is 1; assuring non-zero initial array */
    mti=0;

}

/* generates a random number on [0,0xffffffff]-interval */
uint genrand_int32(bool pAddEntropy = false)
{
    uint y;
    static uint mag01[2] =[0, MATRIX_A];
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= mt.length) { /* fill the entire mt[] at one time */
        int kk;

        if (pAddEntropy || mti > mt.length)   /* if init_genrand() has not been called, */
        {
            init_genrand( 5489UL, pAddEntropy ); /* a default initial seed is used */
        }

        for (kk=0;kk<mt.length-M;kk++)
        {
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 1UL];
        }
        for (;kk<mt.length-1;kk++) {
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
            mt[kk] = mt[kk+(M-mt.length)] ^ (y >> 1) ^ mag01[y & 1UL];
        }
        y = (mt[mt.length-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
        mt[mt.length-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 1UL];

        mti = 0;
    }

    y = mt[mti++];

    /* Tempering */
    y ^= (y >> 11);
    y ^= (y << 7)  &  0x9d2c5680UL;
    y ^= (y << 15) &  0xefc60000UL;
    y ^= (y >> 18);

    vLastRand = y;
    return y;
}

/* generates a random number on [0,0x7fffffff]-interval */
long genrand_int31()
{
    return cast(long)(genrand_int32()>>1);
}

/* generates a random number on [0,1]-real-interval */
double genrand_real1()
{
    return genrand_int32()*(1.0/cast(double)uint.max);
    /* divided by 2^32-1 */
}

/* generates a random number on [0,1)-real-interval */
double genrand_real2()
{
    return genrand_int32()*(1.0/(cast(double)uint.max+1.0));
    /* divided by 2^32 */
}

/* generates a random number on (0,1)-real-interval */
double genrand_real3()
{
    return ((cast(double)genrand_int32()) + 0.5)*(1.0/(cast(double)uint.max+1.0));
    /* divided by 2^32 */
}

/* generates a random number on [0,1) with 53-bit resolution*/
double genrand_res53()
{
    uint a=genrand_int32()>>5, b=genrand_int32()>>6;
    return(a*67108864.0+b)*(1.0/9007199254740992.0);
}
/* These real versions are due to Isaku Wada, 2002/01/09 added */

/* generates a random number in [low,high] interval - Derek Parnell */
template genrand_range(T)
{
T genrand_range(T pLow, T pHigh,bool pAddEntropy = false)
{
    T lResult;
    T lInterval;
    T lTemp;
    uint lRand;

    if (pLow == pHigh)
        return pLow;

    if (pLow > pHigh)
    {
        lResult = pHigh;
        pHigh = pLow;
        pLow = lResult;
    }
    lRand = genrand_int32(pAddEntropy);

    static if ( is(T == real) ||
                is(T == double)  ||
                is(T == float) )
    {
        lRand = genrand_int32(pAddEntropy);
        lInterval = cast(real)pHigh - cast(real)pLow;
        lTemp = cast(real)lRand / uint.max;
        lResult =  lInterval * lTemp + pLow;
    }
    else static if ( is(T == ulong) ||
                     is(T == long)  ||
                     is(T == uint)  ||
                     is(T == int)   ||
                     is(T == ushort)||
                     is(T == short) ||
                     is(T == ubyte) ||
                     is(T == byte) )
    {
        lInterval = pHigh - pLow + 1;
        lResult = lRand % lInterval + pLow;
    }
    else
    {
        pragma(msg, "ERROR! genrand_range!() Can only use an integer or floating point type");
        static assert(0);
    }

    return lResult;
}
}

struct MT_State
{
    uint Index;
    uint[N] Seeds;
}

MT_State* GetState()
{
    MT_State* lTemp = new MT_State;
    lTemp.Index = mti;
    lTemp.Seeds[] = mt[];

    return lTemp;
}

void SetState(MT_State* pSaved)
{
    mti = pSaved.Index;
    mt[] = pSaved.Seeds[];

}

version(main)
{
int main()
{
    const int lCnt = 20;
    int i;
    uint[] lInit;

    lInit.length = 0;
    lInit ~= 0x123;
    lInit ~= 0x234;
    lInit ~= 0x345;
    lInit ~= 0x456;
    init_by_array(lInit);
    writefln("\n%s outputs of genrand_int32()", lCnt);
    for (i=0; i<lCnt; i++) {
      writef("%10s ", genrand_int32());
      if (i%5==4) writefln("\n");
    }

    lInit.length = 0;
    lInit ~= 0x123;
    lInit ~= 0x234;
    lInit ~= 0x345;
    lInit ~= 0x456;
    init_by_array(lInit,true);
    writefln("\n%s outputs of genrand_int32()", lCnt);
    for (i=0; i<lCnt; i++) {
      writef("%10s ", genrand_int32());
      if (i%5==4) writefln("\n");
    }

    writefln("\n%s outputs of genrand_real2()", lCnt);
    for (i=0; i<lCnt; i++) {
      writef("%10.8s ", genrand_real2());
      if (i%5==4) writefln("\n");
    }

    writefln("\n%s outputs of genrand_range(1,10)", lCnt);
    for (i=0; i<lCnt; i++) {
      writef("%2s ", genrand_range!(uint)(1,10));
      if (i%30==29) writefln("\n");
    }

    writefln("\n%s outputs of genrand_range(-0.5,0.5)", lCnt);
    for (i=0; i<lCnt; i++) {
      writef("%10.8s ", genrand_range!(float)(-0.5, 0.5));
      if (i%5==4) writefln("\n");
    }

    return 0;
}
}
