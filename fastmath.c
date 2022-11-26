using namespace std;
unsigned long xrander = 123456789, yrander = 362436069, zrander = 521288629;
unsigned long trander;
double compbase = 2.3025850929940456840179914546844d;
double basecomp = 1.0d;
int shift1 = 1;
int shift2 = 5;
int shift3 = 16;

float Fast_Sqrt(float val) // log2(n) approximation  //this is not used in the LN approximation
{
    // float chk
    union {
        int tmp;
        float val;
    } vals;
    vals.val = val;
    vals.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    // tmp is now an approximation to logbase2(val)
    vals.tmp >>= 1;      // divide by 2
    vals.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    // vals.tmp = (1<<29) + (vals.tmp >> 1) - (1<<22) + 0x4C000;  // I am working on a way to improve this value
    //  that represents (e/2)-64 but want e/2
    return vals.val;
}

float Fast_InvSqrt(float number) // originally by Silicon Graphics slightly higher accuracy variant below.
{
    long i;
    float x2, y;
    const float threehalfs = 1.5F;
    x2 = number * 0.5F;
    y = number;
    i = *(long *)&y;           // evil floating point bit level hacking [sic]
    i = 0x5f375a86 - (i >> 1); // what the fuck? [sic]   original silicon graphics constant: 0x5f3759df
    y = *(float *)&i;
    y = y * (threehalfs - (x2 * y * y)); // 1st iteration
                                         // y  = y * ( threehalfs - ( x2 * y * y ) );   // 2nd iteration, this can be removed
    return y;
}

double Fast_Pow(double a, double b) // fastpower originally developed by Martin Ankerl
{
    int tmp = (*(1 + (int *)&a));
    int tmp2 = (int)(b * (tmp - 1072632447) + 1072632447);
    double p = 0.0;
    *(1 + (int *)&p) = tmp2;
    // p = p * a / 2.71828F ; failed attempt to auto correct the accuracy
    return tmp;
}

double Fast_Exp(double y) // 2.87921
{
    double d;
    //*((int*)(&d) + 0) = 0;
    *((int *)(&d) + 1) = (int)(1512775 * y + 1072632447);
    return d;
}

double Fast_XLnX(double x) // Borchardt's algorithm only accurate close to the origin
{
    union {
        int tmp;
        float val;
    } vals;
    vals.val = x;
    vals.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    vals.tmp >>= 1;      // divide by 2
    vals.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    return 6.0F * x * (x - 1.0F) / (x + 4.0F * vals.val++);
}

double Fast_LnX(double x) {
    union {
        int tmp;
        float val;
    } vals;
    vals.val = x;
    vals.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    vals.tmp >>= 1;      // divide by 2
    vals.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    return 6.0F * x * (x - 1.0F) / (x * (x + 4.0F * vals.val++));
}

double Fast_Log10(double x) {
    union {
        int tmp;
        float val;
    } vals;
    vals.val = x;
    vals.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    vals.tmp >>= 1;      // divide by 2
    vals.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    return 6.0F * x * (x - 1.0F) / (x * 2.302585092994F * (x + 4.0F * vals.val++));
}

double Fast_LogPi(double x) {
    union {
        int tmp;
        float val;
    } vals;
    vals.val = x;
    vals.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    vals.tmp >>= 1;      // divide by 2
    vals.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    return 6.0F * x * (x - 1.0F) / (x * 1.1447298858494F * (x + 4.0F * vals.val++));
}

double Fast_Sin(double x) // currently only supports range between -3 * pi and 3 * pi
{
    double sine;
    // always wrap input angle to -PI..PI I know it is abit of a compicated algorithm but hey
    int Piintdiv = x * 0.15915494309189F;
    double Pix = x - 6.2831853071796F * Piintdiv;
    if (Pix < -3.14159265F)
        Pix += 6.28318531F;
    else if (Pix > 3.14159265F)
        Pix -= 6.28318531F;
    if (Pix < 0)
        sine = (0.405284735F * Pix + 1.27323954F) * Pix;
    // sine = 1.27323954 * x + .405284735 * x * x; // I do so love horner form
    else
        sine = (1.27323954 - 0.405284735 * Pix) * Pix;
    return sine;
}

double Fast_Cos(double x) {
    double Cosine;
    int Piintdiv = x * 0.15915494309189F;
    double Pix = x - 6.2831853071796F * Piintdiv;
    Pix += 1.57079632;
    if (Pix < -3.14159265F)
        Pix += 6.28318531F;
    else if (Pix > 3.14159265F)
        Pix -= 6.28318531F;
    if (Pix < 0)
        Cosine = (1.27323954 + 0.405284735 * Pix) * Pix;
    else
        Cosine = (1.27323954 - 0.405284735 * Pix) * Pix;
    return Cosine;
}

double Fast_Tan(double x) {
    double Cosine;
    double sine;
    // always wrap input angle to -PI..PI
    if (x < -3.14159265F)
        x += 6.28318531F;
    else if (x > 3.14159265F)
        x -= 6.28318531F;
    // compute sine
    if (x < 0)
        sine = (0.405284735F * x + 1.27323954F) * x; // I do so love horner form the alernative on the nex line is slower
                                                     // sine = 1.27323954 * x + .405284735 * x * x;
    else
        sine = (1.27323954 - 0.405284735 * x) * x;
    x += 1.57079632;
    if (x < 0)
        Cosine = (1.27323954 + 0.405284735 * x) * x;
    else
        Cosine = (1.27323954 - 0.405284735 * x) * x;
    return sine / Cosine;
}

double Fast_CoTan(double x) {
    double Cosine;
    double sine;
    // always wrap input angle to -PI..PI
    if (x < -3.14159265F)
        x += 6.28318531F;
    else if (x > 3.14159265F)
        x -= 6.28318531F;
    // compute sine
    if (x < 0)
        sine = (0.405284735F * x + 1.27323954F) * x; // I do so love horner form the alernative on the nex line is slower
                                                     // sine = 1.27323954 * x + .405284735 * x * x;
    else
        sine = (1.27323954 - 0.405284735 * x) * x;
    x += 1.57079632;
    if (x < 0)
        Cosine = (1.27323954 + 0.405284735 * x) * x;
    else
        Cosine = (1.27323954 - 0.405284735 * x) * x;
    return Cosine / sine;
}

double Fast_Sec(double x) {
    double Cosine;
    x += 1.57079632;
    if (x > 3.14159265)
        x -= 6.28318531;
    if (x < 0)
        Cosine = (1.27323954 + 0.405284735 * x) * x;
    else
        Cosine = (1.27323954 - 0.405284735 * x) * x;
    return 1 / Cosine;
}

double Fast_Csc(double x) {
    double sine;
    // always wrap input angle to -PI..PI
    if (x < -3.14159265F)
        x += 6.28318531F;
    else if (x > 3.14159265F)
        x -= 6.28318531F;
    // compute sine
    if (x < 0)
        sine = (0.405284735F * x + 1.27323954F) * x;
    // sine = 1.27323954 * x + .405284735 * x * x; // I do so love horner form
    else
        sine = (1.27323954 - 0.405284735 * x) * x;
    return 1 / sine;
}

// |error| < 0.005
float Fast_Atan2(float y, float x) {
    float PIBY2_FLOAT = 1.5707963F;
    float PI_FLOAT = 3.14159265F;
    if (x == 0.0f) {
        if (y > 0.0f)
            return PIBY2_FLOAT;
        if (y == 0.0f)
            return 0.0f;
        return 0 - PIBY2_FLOAT;
    }
    float atan;
    float z = y / x;
    if (fabsf(z) < 1.0f) {
        atan = z / (1.0f + 0.28f * z * z);
        if (x < 0.0f) {
            if (y < 0.0f)
                return atan - PI_FLOAT;
            return atan + PI_FLOAT;
        }
    } else {
        atan = PIBY2_FLOAT - z / (z * z + 0.28f);
        if (y < 0.0f)
            return atan - PI_FLOAT;
    }
    return atan;
}

float Fast_Atan(float y) {
    float x = 1.0F;
    float PIBY2_FLOAT = 1.5707963F;
    float PI_FLOAT = 3.14159265F;
    float atan;
    float z = y / x;
    if (fabsf(z) < 1.0f) {
        atan = z / (1.0f + 0.28f * z * z);
        if (x < 0.0f) {
            if (y < 0.0f)
                return atan - PI_FLOAT;
            return atan + PI_FLOAT;
        }
    } else {
        atan = PIBY2_FLOAT - z / (z * z + 0.28f);
        if (y < 0.0f)
            return atan - PI_FLOAT;
    }
    return atan;
}

double Fast_ACos(double x) {
    float retval = (-0.69813170079773212F * x * x - 0.87266462599716477F) * x + 1.5707963267948966F;
    return retval;
}

double Fast_ASin(double x) {
    float retval = (0.69813170079773212F * x * x + 0.87266462599716477F) * x;
    return retval;
}

double Fast_SinH(double x) {
    double y = -x;
    double k;
    double d;
    //*((int*)(&d) + 0) = 0;
    *((int *)(&d) + 1) = (int)(1512775 * y + 1072632447);
    //*((int*)(&k) + 0) = 0;
    *((int *)(&k) + 1) = (int)(1512775 * x + 1072632447);
    return (k - d) / 2;
}

double Fast_CosH(double x) {
    double y = -x;
    double k;
    double d;
    //*((int*)(&d) + 0) = 0;
    *((int *)(&d) + 1) = (int)(1512775 * y + 1072632447);
    //*((int*)(&k) + 0) = 0;
    *((int *)(&k) + 1) = (int)(1512775 * x + 1072632447);
    return (k + d) / 2;
}

double Fast_TanH(double x) // from http://www.musicdsp.org/showone.php?id=238
{
    // double xt;
    if (x < -3) {
        return -1;
    } else if (x > 3) {
        return 1;
    } else {
        double xz = x * x;
        return x * (27 + xz) / (27 + 9 * xz);
    }
    // return xt
}

double Fast_ATanH(double x) {
    double mlnx = 1 - x;
    double plnx = 1 + x;
    union {
        int tmp;
        float val;
    } vals;
    union {
        int tmp;
        float val;
    } vals2;
    vals.val = plnx;
    vals.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    vals.tmp >>= 1;      // divide by 2
    vals.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    vals2.val = mlnx;
    vals2.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    vals2.tmp >>= 1;      // divide by 2
    vals2.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    return (6.0F * mlnx * (mlnx - 1.0F) / (mlnx * (mlnx + 4.0F * vals.val++)) - 6.0F * plnx * (plnx - 1.0F) / (plnx * (plnx + 4.0F * vals2.val++))) * 0.5f;
}

double Fast_ACosH(double val) {
    double zsqrz;
    // float chk
    union {
        int tmp;
        float val;
    } vals;
    union {
        int tmp;
        float val;
    } val2s;
    vals.val = val + 1;
    vals.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    // tmp is now an approximation to logbase2(val)
    vals.tmp >>= 1;      // divide by 2
    vals.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    val2s.val = val - 1;
    val2s.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    // tmp is now an approximation to logbase2(val)
    val2s.tmp >>= 1;      // divide by 2
    val2s.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    zsqrz = val + vals.val * val2s.val;
    return log(zsqrz);
}

double Fast_ASinH(double x) {
    union {
        int tmp;
        float val;
    } vals;
    vals.val = x * x + 1;
    vals.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    // tmp is now an approximation to logbase2(val)
    vals.tmp >>= 1;      // divide by 2
    vals.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    return log(x + vals.val);
}

double Fast_ASecH(double x) {
    double zsqrz;
    // float chk
    union {
        int tmp;
        float val;
    } vals;
    union {
        int tmp;
        float val;
    } val2s;
    vals.val = 1 / x + 1;
    vals.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    // tmp is now an approximation to logbase2(val)
    vals.tmp >>= 1;      // divide by 2
    vals.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    val2s.val = 1 / x - 1;
    val2s.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    // tmp is now an approximation to logbase2(val)
    val2s.tmp >>= 1;      // divide by 2
    val2s.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    zsqrz = 1 / x + vals.val * val2s.val;
    return log(zsqrz);
}

double Fast_ACscH(double val) {
    double x = 1 / val;
    union {
        int tmp;
        float val;
    } vals;
    vals.val = x * x + 1;
    vals.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    // tmp is now an approximation to logbase2(val)
    vals.tmp >>= 1;      // divide by 2
    vals.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    return log(x + vals.val);
}

double Fast_ACotH(double valts) {
    double x = 1 / valts;
    double mlnx = 1 - x;
    double plnx = 1 + x;
    union {
        int tmp;
        float val;
    } vals;
    union {
        int tmp;
        float val;
    } vals2;
    vals.val = plnx;
    vals.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    vals.tmp >>= 1;      // divide by 2
    vals.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    vals2.val = mlnx;
    vals2.tmp -= 1 << 23; // Remove last bit so 1.0 gives 1.0
    vals2.tmp >>= 1;      // divide by 2
    vals2.tmp += 1 << 29; // add 64 to exponent: (e+127)/2 =(e/2)+63;
    return (6.0F * mlnx * (mlnx - 1.0F) / (mlnx * (mlnx + 4.0F * vals.val++)) - 6.0F * plnx * (plnx - 1.0F) / (plnx * (plnx + 4.0F * vals2.val++))) / 2;
}

void Fast_RandInit(float x, int i, int j, int k) {
    float ftl;
    float ftl2;
    float ftl3;
    ftl = 10000 * sin(x * 7);
    xrander = *(long *)&ftl;
    ftl2 = 10000 * cos(x * 3);
    yrander = *(long *)&ftl2;
    ftl3 = 10000 * sin(x * 2);
    zrander = *(long *)&ftl3;
    if ((i == 0) || (j == 0) || (k == 0)) {
        shift1 = 1;
        shift2 = 5;
        shift3 = 16;
    } else {
        shift1 = i; // 8 * sin(x) + 9;
        shift3 = k; // 8 * cos(x) + 9;
        shift2 = j; //(shift1 + shift3) / 2;
    }
}

inline float Fast_Rand(void) // based off of George Marsaglia's XORSHIFT algorithms
{                            //
    xrander ^= xrander << shift1;
    xrander ^= xrander >> shift2;
    xrander ^= xrander << shift3;
    trander = xrander;
    xrander = yrander;
    yrander = zrander;
    zrander = trander ^ xrander ^ yrander;
    return float(zrander) / 4294967295;
}

inline float Fast_Sign(float f) {
    float r = 1.0f;
    (int &)r |= ((int &)f & 0x80000000);
    return r;
}

double High_ATanH(double x) { return (log(1 + x) - log(1 - x)) / 2; }

double High_ACosH(double x) { return log(x + sqrt(x + 1) * sqrt(x - 1)); }

double High_ASinH(double x) { return log(x + sqrt(x * x + 1)); }

double High_ASecH(double x) {
    double xz = 1 / x;
    return log(sqrt(xz - 1) * sqrt(xz + 1) + xz);
}

double High_ACscH(double x) { return log(sqrt(1 + 1 / (x * x)) + 1 / x); }

double High_ACotH(double x) {
    double xz = 1 / x;
    return (log(1 + xz) - log(1 - xz)) / 2;
}

inline float High_Sign(float f) {
    // this may or may not be used in QB64 in the future
    if (((int &)f & 0x7FFFFFFF) == 0) {
        return 0.0f;
    } else {
        float r = 1.0f;
        (int &)r |= ((int &)f & 0x80000000);
        return r;
    }
}
int Misc_TrailZCount(unsigned int v) {
    // unsigned int v;     // 32-bit word input to count zero bits on right
    unsigned int c; // c will be the number of zero bits on the right,
                    // so if v is 1101000 (base 2), then c will be 3
                    // NOTE: if 0 == v, then c = 31.
    if (v & 0x1) {
        // special case for odd v (assumed to happen half of the time)
        c = 0;
    } else {
        c = 1;
        if ((v & 0xffff) == 0) {
            v >>= 16;
            c += 16;
        }
        if ((v & 0xff) == 0) {
            v >>= 8;
            c += 8;
        }
        if ((v & 0xf) == 0) {
            v >>= 4;
            c += 4;
        }
        if ((v & 0x3) == 0) {
            v >>= 2;
            c += 2;
        }
        c -= v & 0x1;
    }
    return c;
}

int Misc_Parity(int v) // is the number of 1 bits odd? true if so
{
    // unsigned int v; // 32-bit word
    v ^= v >> 1;
    v ^= v >> 2;
    v = (v & 0x11111111U) * 0x11111111U;
    return (v >> 28) & 1;
}

int Misc_BitSet(int v)
// u//nsigned int v; // count the number of bits set in v
{
    unsigned int c; // c accumulates the total bits set in v
    for (c = 0; v; c++) {
        v &= v - 1; // clear the least significant bit set
    }
    return c;
}

long Misc_FloatToLong(float y) // 1132462080
{
    return *(long *)&y;
}

float Misc_LongToFloat(long y) { return *(float *)&y; }

long Misc_UnSetRMBit(long x) { return x & (x - 1); }
