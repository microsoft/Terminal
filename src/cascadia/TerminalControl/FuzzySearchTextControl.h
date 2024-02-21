#pragma once

#include "winrt/Microsoft.UI.Xaml.Controls.h"

#include "FuzzySearchTextSegment.g.h"
#include "FuzzySearchTextControl.g.h"

namespace winrt::Microsoft::Terminal::Control::implementation
{
    struct FuzzySearchTextControl : FuzzySearchTextControlT<FuzzySearchTextControl>
    {
        FuzzySearchTextControl();

        static Windows::UI::Xaml::DependencyProperty TextProperty();

        winrt::Microsoft::Terminal::Control::FuzzySearchTextLine Text();
        void Text(const winrt::Microsoft::Terminal::Control::FuzzySearchTextLine& value);

        Windows::UI::Xaml::Controls::TextBlock TextView();

    private:
        static Windows::UI::Xaml::DependencyProperty _textProperty;
        static void _onTextChanged(const Windows::UI::Xaml::DependencyObject& o, const Windows::UI::Xaml::DependencyPropertyChangedEventArgs& e);
    };
}

namespace winrt::Microsoft::Terminal::Control::factory_implementation
{
    BASIC_FACTORY(FuzzySearchTextControl);
}
