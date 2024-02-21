

#pragma once

#include "FuzzySearchBoxControl.g.h"

namespace winrt::Microsoft::Terminal::Control::implementation
{
    struct FuzzySearchBoxControl : FuzzySearchBoxControlT<FuzzySearchBoxControl>
    {
        FuzzySearchBoxControl();

        static winrt::Windows::UI::Xaml::DependencyProperty ItemsSourceProperty();

        void SetStatus(int32_t totalRowsSearched, int32_t numberOfResults);

        winrt::Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine> ItemsSource();
        void ItemsSource(winrt::Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine> const& value);
        void SearchString(const winrt::hstring searchString);

        void SelectFirstItem();
        void SetFontSize(til::size fontSize);
        void SetSwapChainHandle(HANDLE swapChainHandle);

        void SetFocusOnTextbox();
        bool ContainsFocus();

        double PreviewActualHeight();
        double PreviewActualWidth();
        float PreviewCompositionScaleX();

        void OnListBoxSelectionChanged(winrt::Windows::Foundation::IInspectable const&, Windows::UI::Xaml::Controls::SelectionChangedEventArgs const& e);
        void OnSwapChainPanelSizeChanged(winrt::Windows::Foundation::IInspectable const&, winrt::Windows::UI::Xaml::SizeChangedEventArgs const& e);

        void TextBoxTextChanged(winrt::Windows::Foundation::IInspectable const& sender, winrt::Windows::UI::Xaml::RoutedEventArgs const& e);
        void TextBoxKeyDown(const winrt::Windows::Foundation::IInspectable& /*sender*/, const winrt::Windows::UI::Xaml::Input::KeyRoutedEventArgs& e);
        WINRT_CALLBACK(Search, FuzzySearchHandler);
        TYPED_EVENT(Closed, Control::FuzzySearchBoxControl, Windows::UI::Xaml::RoutedEventArgs);
        TYPED_EVENT(SelectionChanged, Control::FuzzySearchBoxControl, winrt::Microsoft::Terminal::Control::FuzzySearchTextLine);
        TYPED_EVENT(OnReturn, Control::FuzzySearchBoxControl, winrt::Microsoft::Terminal::Control::FuzzySearchTextLine);
        TYPED_EVENT(PreviewSwapChainPanelSizeChanged, Control::FuzzySearchBoxControl, winrt::Windows::UI::Xaml::SizeChangedEventArgs);

        private:
        til::point _toPosInDips(const Core::Point terminalCellPos);
        std::unordered_set<winrt::Windows::Foundation::IInspectable> _focusableElements;
        til::size _fontSize;
    };
}

namespace winrt::Microsoft::Terminal::Control::factory_implementation
{
    BASIC_FACTORY(FuzzySearchBoxControl);
}
