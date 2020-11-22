/*++
Copyright (c) Microsoft Corporation
Licensed under the MIT license.

Module Name:
- LineRendition.hpp

Abstract:
- Enumerated type for the VT line rendition attribute. This determines the
  width and height scaling with which each line is rendered.

--*/

#pragma once

enum class LineRendition
{
    SingleWidth,
    DoubleWidth,
    DoubleHeightTop,
    DoubleHeightBottom
};

constexpr SMALL_RECT ScreenToBufferLine(const SMALL_RECT& line, const LineRendition lineRendition)
{
    const auto scale = lineRendition == LineRendition::SingleWidth ? 0 : 1;
    return { line.Left >> scale, line.Top, line.Right >> scale, line.Bottom };
}
