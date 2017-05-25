/++
Low level ndslice wrapper for BLAS.

Authors: Ilya Yaroshenko
Copyright:  Copyright © 2017, Symmetry Investments & Kaleidic Associates
+/
module mir.blas;

import mir.ndslice.slice;
import mir.ndslice.dynamic;
import mir.ndslice.topology;
static import cblas;

public import cblas: Uplo, Side;

///
T dot(T,
    SliceKind kindX,
    SliceKind kindY,
    )(
    Slice!(kindX, [1], T*) x,
    Slice!(kindY, [1], T*) y,
    )
{
    assert(x.length == y.length);
    return cblas.dot(
        cast(cblas.blasint) x.length,

        x.iterator,
        cast(cblas.blasint) x._stride,

        y.iterator,
        cast(cblas.blasint) y._stride,
    );
}

///
void gemv(T,
    SliceKind kindA,
    SliceKind kindX,
    SliceKind kindY,
    )(
    T alpha,
    Slice!(kindA, [2], T*) a,
    Slice!(kindX, [1], T*) x,
    T beta,
    Slice!(kindY, [1], T*) y,
    )
{
    assert(a.length!1 == x.length);
    assert(a.length!0 == y.length);
    static if (kindA == Universal)
    {
        bool transA;
        if (a._stride!1 != 1)
        {
            a = a.transposed;
            transA = true;
        }
        assert(a._stride!1 == 1, "Matrix A must have a stride equal to 1.");
    }
    else
        enum transA = false;
    cblas.gemv(
        cblas.Order.RowMajor,
        transA ? cblas.Transpose.Trans : cblas.Transpose.NoTrans,
        
        cast(cblas.blasint) y.length,
        cast(cblas.blasint) x.length,

        alpha,

        a.iterator,
        cast(cblas.blasint) a._stride,

        x.iterator,
        cast(cblas.blasint) x._stride,

        beta,

        y.iterator,
        cast(cblas.blasint) y._stride,
    );
}

///
void gemm(T,
    SliceKind kindA,
    SliceKind kindB,
    SliceKind kindC,
    )(
    T alpha,
    Slice!(kindA, [2], T*) a,
    Slice!(kindB, [2], T*) b,
    T beta,
    Slice!(kindC, [2], T*) c,
    )
{
    assert(a.length!1 == b.length!0);
    assert(a.length!0 == c.length!0);
    assert(c.length!1 == b.length!1);
    auto k = a.length!1;
    static if (kindC == Universal)
    {
        if (c._stride!1 != 1)
        {
            assert(c._stride!0 == 1, "Matrix C must have a stride equal to 1.");
            gemv(
                alpha,
                b.universal.transposed,
                a.universal.transposed,
                beta,
                c.transposed.assumeCanonical);
            return;
        }
        assert(c._stride!1 == 1, "Matrix C must have a stride equal to 1.");
    }
    static if (kindA == Universal)
    {
        bool transA;
        if (a._stride!1 != 1)
        {
            a = a.transposed;
            transA = true;
        }
        assert(a._stride!1 == 1, "Matrix A must have a stride equal to 1.");
    }
    else
        enum transA = false;
    static if (kindB == Universal)
    {
        bool transB;
        if (b._stride!1 != 1)
        {
            b = b.transposed;
            transB = true;
        }
        assert(b._stride!1 == 1, "Matrix B must have a stride equal to 1.");
    }
    else
        enum transB = false;
    cblas.gemm(
        cblas.Order.RowMajor,
        transA ? cblas.Transpose.Trans : cblas.Transpose.NoTrans,
        transB ? cblas.Transpose.Trans : cblas.Transpose.NoTrans,
        
        cast(cblas.blasint) c.length!0,
        cast(cblas.blasint) c.length!1,
        cast(cblas.blasint) k,

        alpha,

        a.iterator,
        cast(cblas.blasint) a._stride,

        b.iterator,
        cast(cblas.blasint) b._stride,

        beta,

        c.iterator,
        cast(cblas.blasint) c._stride,
    );
}

///
void syrk(T,
    SliceKind kindA,
    SliceKind kindC,
    )(
    Uplo uplo,
    T alpha,
    Slice!(kindA, [2], T*) a,
    T beta,
    Slice!(kindC, [2], T*) c,
    )
{
    assert(a.length!0 == c.length!0);
    assert(c.length!1 == c.length!0);
    auto k = a.length!1;
    static if (kindC == Universal)
    {
        if (c._stride!1 != 1)
        {
            c = c.transposed;
            uplo = uplo == Uplo.Lower ? Uplo.Upper : Uplo.Lower;
        }
        assert(c._stride!1 == 1, "Matrix C must have a stride equal to 1.");
    }
    else
        enum transC = false;
    static if (kindA == Universal)
    {
        bool transA;
        if (a._stride!1 != 1)
        {
            a = a.transposed;
            transA = true;
        }
        assert(a._stride!1 == 1, "Matrix A must have a stride equal to 1.");
    }
    else
        enum transA = false;
    cblas.syrk(
        cblas.Order.RowMajor,
        uplo,
        transA ? cblas.Transpose.Trans : cblas.Transpose.NoTrans,

        cast(cblas.blasint) c.length!0,
        cast(cblas.blasint) k,

        alpha,

        a.iterator,
        cast(cblas.blasint) a._stride,

        beta,

        c.iterator,
        cast(cblas.blasint) c._stride,
    );
}