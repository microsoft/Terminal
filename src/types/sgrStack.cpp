// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "precomp.h"
#include "inc/sgrStack.hpp"

using namespace Microsoft::Console::VirtualTerminal::DispatchTypes;

namespace Microsoft::Console::VirtualTerminal
{
    SgrStack::SgrStack() noexcept :
        _nextPushIndex{ 0 },
        _numSavedAttrs{ 0 }
    {
    }

    void SgrStack::Push(const TextAttribute& currentAttributes,
                        const VTParameters options) noexcept
    {
        AttrBitset validParts;

        try
        {
            if (options.empty())
            {
                // We save all current attributes.
                validParts.set(static_cast<size_t>(SgrSaveRestoreStackOptions::All));
            }
            else
            {
                // Each option is encoded as a bit in validParts. All options (that fit) are
                // encoded; options that aren't supported are ignored when read back (popped).
                // So if you try to save only unsupported aspects of the current text
                // attributes, you'll do what is effectively an "empty" push (the subsequent
                // pop will not change the current attributes), which is the correct behavior.

                for (size_t i = 0; i < options.size(); i++)
                {
                    // TRICKY: The VTParameter could be a fake/materialized parameter, in
                    // which case it has a default value, and the default value of a
                    // VTParameter depends on what you are assigning to: if you assign /
                    // convert directly to a size_t, then the default is "1", but for other
                    // size_t-sized types, the default is "0". We want "default is 0", so we
                    // convert to a SgrSaveRestoreStackOptions first.
                    const SgrSaveRestoreStackOptions option = options.at(i);
                    const size_t optionAsIndex = static_cast<size_t>(option);

                    // Options must be specified singly; not in combination. Values that are
                    // out of range will be ignored.
                    if (optionAsIndex < validParts.size())
                    {
                        validParts.set(optionAsIndex);
                    }
                }
            }
        }
        catch (std::out_of_range&)
        {
            // We should not be able to reach here: we pre-check that everything should be
            // in range.
            RaiseFailFastException(nullptr, nullptr, 0);
        }

        if (_numSavedAttrs < gsl::narrow<int>(_storedSgrAttributes.size()))
        {
            _numSavedAttrs++;
        }

        _storedSgrAttributes.at(_nextPushIndex) = { currentAttributes, validParts };
        _nextPushIndex = (_nextPushIndex + 1) % gsl::narrow<int>(_storedSgrAttributes.size());
    }

    const TextAttribute SgrStack::Pop(const TextAttribute& currentAttributes) noexcept
    {
        if (_numSavedAttrs > 0)
        {
            _numSavedAttrs--;

            if (_nextPushIndex == 0)
            {
                _nextPushIndex = gsl::narrow<int>(_storedSgrAttributes.size() - 1);
            }
            else
            {
                _nextPushIndex--;
            }

            SavedSgrAttributes& restoreMe = _storedSgrAttributes.at(_nextPushIndex);

            try
            {
                if (restoreMe.ValidParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::All)))
                {
                    return restoreMe.TextAttributes;
                }
                else
                {
                    return _CombineWithCurrentAttributes(currentAttributes,
                                                         restoreMe.TextAttributes,
                                                         restoreMe.ValidParts);
                }
            }
            catch (std::out_of_range&)
            {
                // We should not be able to reach here: we pre-check that everything
                // should be in range.
                RaiseFailFastException(nullptr, nullptr, 0);
            }
        }

        return currentAttributes;
    }

    TextAttribute SgrStack::_CombineWithCurrentAttributes(const TextAttribute& currentAttributes,
                                                          const TextAttribute& savedAttribute,
                                                          const AttrBitset validParts) // of savedAttribute
    {
        // If we are restoring all attributes, we should have just taken savedAttribute
        // before we even got here.
        FAIL_FAST_IF(validParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::All)));

        TextAttribute result = currentAttributes;

        // From xterm documentation:
        //
        //  CSI # {
        //  CSI Ps ; Ps # {
        //            Push video attributes onto stack (XTPUSHSGR), xterm.  The
        //            optional parameters correspond to the SGR encoding for video
        //            attributes, except for colors (which do not have a unique SGR
        //            code):
        //              Ps = 1  -> Bold.
        //              Ps = 2  -> Faint.
        //              Ps = 3  -> Italicized.
        //              Ps = 4  -> Underlined.
        //              Ps = 5  -> Blink.
        //              Ps = 7  -> Inverse.
        //              Ps = 8  -> Invisible.
        //              Ps = 9  -> Crossed-out characters.
        //              Ps = 2 1  -> Doubly-underlined.
        //              Ps = 3 0  -> Foreground color.
        //              Ps = 3 1  -> Background color.
        //
        //  (some closing braces for people with editors that get thrown off without them: }})
        //
        // Note that not all of these attributes are actually supported by
        // renderers/conhost, despite setters/getters on TextAttribute.

        try
        {
            // Boldness = 1,
            if (validParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::Boldness)))
            {
                result.SetBold(savedAttribute.IsBold());
            }

            // Faintness = 2,
            if (validParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::Faintness)))
            {
                result.SetFaint(savedAttribute.IsFaint());
            }

            // Italics = 3,
            if (validParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::Italics)))
            {
                result.SetItalic(savedAttribute.IsItalic());
            }

            // Underline = 4,
            if (validParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::Underline)))
            {
                result.SetUnderlined(savedAttribute.IsUnderlined());
            }

            // Blink = 5,
            if (validParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::Blink)))
            {
                result.SetBlinking(savedAttribute.IsBlinking());
            }

            // Negative = 7,
            if (validParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::Negative)))
            {
                if (savedAttribute.IsReverseVideo())
                {
                    if (!result.IsReverseVideo())
                    {
                        result.Invert();
                    }
                }
                else
                {
                    if (result.IsReverseVideo())
                    {
                        result.Invert();
                    }
                }
            }

            // Invisible = 8,
            if (validParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::Invisible)))
            {
                result.SetInvisible(savedAttribute.IsInvisible());
            }

            // CrossedOut = 9,
            if (validParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::CrossedOut)))
            {
                result.SetCrossedOut(savedAttribute.IsCrossedOut());
            }

            // DoublyUnderlined = 21,
            if (validParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::DoublyUnderlined)))
            {
                result.SetDoublyUnderlined(savedAttribute.IsDoublyUnderlined());
            }

            // SaveForegroundColor = 30,
            if (validParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::SaveForegroundColor)))
            {
                result.SetForegroundFrom(savedAttribute);
            }

            // SaveBackgroundColor = 31,
            if (validParts.test(static_cast<size_t>(SgrSaveRestoreStackOptions::SaveBackgroundColor)))
            {
                result.SetBackgroundFrom(savedAttribute);
            }
        }
        catch (std::out_of_range&)
        {
            // We should not be able to reach here: all values passed to bitset::test are
            // constants, clearly in range of the bitset.
            RaiseFailFastException(nullptr, nullptr, 0);
        }

        return result;
    }

}
