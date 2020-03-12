// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#ifdef UNIT_TESTING
class PointTests;
#endif

namespace til // Terminal Implementation Library. Also: "Today I Learned"
{
    class point
    {
    public:
        constexpr point() noexcept :
            point(0, 0)
        {

        }

        // On 64-bit processors, int and ptrdiff_t are different fundamental types.
        // On 32-bit processors, they're the same which makes this a double-definition
        // with the `ptrdiff_t` one below.
#if defined(_M_AMD64) || defined(_M_ARM64)
        constexpr point(int x, int y) noexcept :
            point(static_cast<ptrdiff_t>(x), static_cast<ptrdiff_t>(y))
        {
        }
#endif

        point(size_t x, size_t y)
        {
            THROW_HR_IF(E_ABORT, !base::MakeCheckedNum(x).AssignIfValid(&_x));
            THROW_HR_IF(E_ABORT, !base::MakeCheckedNum(y).AssignIfValid(&_y));
        }

        constexpr point(ptrdiff_t x, ptrdiff_t y) noexcept :
            _x(x),
            _y(y)
        {

        }

        // This template will convert to size from anything that has an X and a Y field that appear convertable to an integer value
        template<typename TOther>
        constexpr point(const TOther& other, std::enable_if_t<std::is_integral_v<decltype(std::declval<TOther>().X)> && std::is_integral_v<decltype(std::declval<TOther>().Y)>, int> /*sentinel*/ = 0) :
            point(static_cast<ptrdiff_t>(other.X), static_cast<ptrdiff_t>(other.Y))
        {

        }

        // This template will convert to size from anything that has a x and a y field that appear convertable to an integer value
        template<typename TOther>
        constexpr point(const TOther& other, std::enable_if_t<std::is_integral_v<decltype(std::declval<TOther>().x)> && std::is_integral_v<decltype(std::declval<TOther>().y)>, int> /*sentinel*/ = 0) :
            point(static_cast<ptrdiff_t>(other.x), static_cast<ptrdiff_t>(other.y))
        {

        }

        constexpr bool operator==(const point& other) const noexcept
        {
            return _x == other._x &&
                   _y == other._y;
        }

        constexpr bool operator!=(const point& other) const noexcept
        {
            return !(*this == other);
        }

        operator bool() const noexcept
        {
            return _x != 0 || _y != 0;
        }

        constexpr bool operator<(const point& other) const noexcept
        {
            if (_y < other._y)
            {
                return true;
            }
            else if (_y > other._y)
            {
                return false;
            }
            else
            {
                return _x < other._x;
            }
        }

        constexpr bool operator>(const point& other) const noexcept
        {
            if (_y > other._y)
            {
                return true;
            }
            else if (_y < other._y)
            {
                return false;
            }
            else
            {
                return _x > other._x;
            }
        }

        point operator+(const point& other) const
        {
            ptrdiff_t x;
            THROW_HR_IF(E_ABORT, !base::CheckAdd(_x, other._x).AssignIfValid(&x));

            ptrdiff_t y;
            THROW_HR_IF(E_ABORT, !base::CheckAdd(_y, other._y).AssignIfValid(&y));

            return point{ x, y };
        }

        point operator-(const point& other) const
        {
            ptrdiff_t x;
            THROW_HR_IF(E_ABORT, !base::CheckSub(_x, other._x).AssignIfValid(&x));

            ptrdiff_t y;
            THROW_HR_IF(E_ABORT, !base::CheckSub(_y, other._y).AssignIfValid(&y));

            return point{ x, y };
        }

        point operator*(const point& other) const
        {
            ptrdiff_t x;
            THROW_HR_IF(E_ABORT, !base::CheckMul(_x, other._x).AssignIfValid(&x));

            ptrdiff_t y;
            THROW_HR_IF(E_ABORT, !base::CheckMul(_y, other._y).AssignIfValid(&y));

            return point{ x, y };
        }

        point operator/(const point& other) const
        {
            ptrdiff_t x;
            THROW_HR_IF(E_ABORT, !base::CheckDiv(_x, other._x).AssignIfValid(&x));

            ptrdiff_t y;
            THROW_HR_IF(E_ABORT, !base::CheckDiv(_y, other._y).AssignIfValid(&y));

            return point{ x, y };
        }

        constexpr ptrdiff_t x() const noexcept
        {
            return _x;
        }

        template<typename T>
        T x() const
        {
            T ret;
            THROW_HR_IF(E_ABORT, !base::MakeCheckedNum(x()).AssignIfValid(&ret));
            return ret;
        }

        constexpr ptrdiff_t y() const noexcept
        {
            return _y;
        }

        template<typename T>
        T y() const
        {
            T ret;
            THROW_HR_IF(E_ABORT, !base::MakeCheckedNum(y()).AssignIfValid(&ret));
            return ret;
        }

#ifdef _WINCONTYPES_
        operator COORD() const
        {
            COORD ret;
            THROW_HR_IF(E_ABORT, !base::MakeCheckedNum(_x).AssignIfValid(&ret.X));
            THROW_HR_IF(E_ABORT, !base::MakeCheckedNum(_y).AssignIfValid(&ret.Y));
            return ret;
        }
#endif

#ifdef _WINDEF_
        operator POINT() const
        {
            POINT ret;
            THROW_HR_IF(E_ABORT, !base::MakeCheckedNum(_x).AssignIfValid(&ret.x));
            THROW_HR_IF(E_ABORT, !base::MakeCheckedNum(_y).AssignIfValid(&ret.y));
            return ret;
        }
#endif

#ifdef DCOMMON_H_INCLUDED
        constexpr operator D2D1_POINT_2F() const noexcept
        {
            return D2D1_POINT_2F{ gsl::narrow_cast<float>(_x), gsl::narrow_cast<float>(_y) };
        }
#endif

    protected:
        ptrdiff_t _x;
        ptrdiff_t _y;

#ifdef UNIT_TESTING
        friend class ::PointTests;
#endif
    };
}

#ifdef __WEX_COMMON_H__
namespace WEX::TestExecution
{
    template<>
    class VerifyOutputTraits<::til::point>
    {
    public:
        static WEX::Common::NoThrowString ToString(const ::til::point& point)
        {
            return WEX::Common::NoThrowString().Format(L"(X:%td, Y:%td)", point.x(), point.y());
        }
    };

    template<>
    class VerifyCompareTraits<::til::point, ::til::point>
    {
    public:
        static bool AreEqual(const ::til::point& expected, const ::til::point& actual) noexcept
        {
            return expected == actual;
        }

        static bool AreSame(const ::til::point& expected, const ::til::point& actual) noexcept
        {
            return &expected == &actual;
        }

        static bool IsLessThan(const ::til::point& expectedLess, const ::til::point& expectedGreater) = delete;

        static bool IsGreaterThan(const ::til::point& expectedGreater, const ::til::point& expectedLess) = delete;

        static bool IsNull(const ::til::point& object) noexcept
        {
            return object == til::point{};
        }
    };
};
#endif

