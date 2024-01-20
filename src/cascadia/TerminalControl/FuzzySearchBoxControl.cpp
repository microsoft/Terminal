// Copyright (c) Microsoft Corporation
// Licensed under the MIT license.

#include "pch.h"
#include "FuzzySearchBoxControl.h"
#include "FuzzySearchBoxControl.g.cpp"
#include <LibraryResources.h>
using namespace winrt::Windows::UI::Xaml::Media;

using namespace winrt;
using namespace winrt::Windows::UI::Xaml;
using namespace winrt::Windows::UI::Core;

namespace winrt::Microsoft::Terminal::Control::implementation
{
    FuzzySearchBoxControl::FuzzySearchBoxControl()
    {
        InitializeComponent();

        _focusableElements.insert(FuzzySearchTextBox());

        FuzzySearchTextBox().KeyUp([this](const IInspectable& sender, Input::KeyRoutedEventArgs const& e) {
            auto textBox{ sender.try_as<Controls::TextBox>() };

            if (ListBox() != nullptr)
            {
                if (e.OriginalKey() == winrt::Windows::System::VirtualKey::Down || e.OriginalKey() == winrt::Windows::System::VirtualKey::Up)
                {
                    auto selectedIndex = ListBox().SelectedIndex();

                    if (e.OriginalKey() == winrt::Windows::System::VirtualKey::Down)
                    {
                        selectedIndex++;
                    }
                    else if (e.OriginalKey() == winrt::Windows::System::VirtualKey::Up)
                    {
                        selectedIndex--;
                    }

                    if (selectedIndex >= 0 && selectedIndex < static_cast<int32_t>(ListBox().Items().Size()))
                    {
                        ListBox().SelectedIndex(selectedIndex);
                        ListBox().ScrollIntoView(ListBox().SelectedItem());
                    }

                    e.Handled(true);
                }
            }
            else if (e.OriginalKey() == winrt::Windows::System::VirtualKey::Enter)
            {
                auto selectedItem = ListBox().SelectedItem();
                if (selectedItem)
                {
                    auto castedItem = selectedItem.try_as<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>();
                    if (castedItem)
                    {
                        _OnReturnHandlers(*this, castedItem);
                        e.Handled(true);
                    }
                }
            }
        });
        this->FuzzySearchSwapChainPanel().SizeChanged({ this, &FuzzySearchBoxControl::OnSwapChainPanelSizeChanged });
    }

    bool FuzzySearchBoxControl::ContainsFocus()
    {
        auto focusedElement = Input::FocusManager::GetFocusedElement(this->XamlRoot());
        if (_focusableElements.count(focusedElement) > 0)
        {
            return true;
        }

        return false;
    }

    double FuzzySearchBoxControl::PreviewActualHeight()
    {
        return FuzzySearchSwapChainPanel().ActualHeight();
    }
    double FuzzySearchBoxControl::PreviewActualWidth()
    {
        return FuzzySearchSwapChainPanel().ActualWidth();
    }
    float FuzzySearchBoxControl::PreviewCompositionScaleX()
    {
        return FuzzySearchSwapChainPanel().CompositionScaleX();
    }

    DependencyProperty FuzzySearchBoxControl::ItemsSourceProperty()
    {
        static DependencyProperty dp = DependencyProperty::Register(
            L"ItemsSource",
            xaml_typename<Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>>(),
            xaml_typename<winrt::Microsoft::Terminal::Control::FuzzySearchBoxControl>(),
            PropertyMetadata{ nullptr });

        return dp;
    }

    void FuzzySearchBoxControl::SetStatus(int32_t totalRowsSearched, int32_t numberOfResults)
    {
        hstring result;
        if (totalRowsSearched == 0)
        {
            result = RS_(L"TermControl_NoMatch");
        }
        else
        {
            result = winrt::hstring{ fmt::format(RS_(L"TermControl_NumResults").c_str(), numberOfResults, totalRowsSearched) };
        }

        StatusBox().Text(result);
    }

    Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine> FuzzySearchBoxControl::ItemsSource()
    {
        return GetValue(ItemsSourceProperty()).as<Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>>();
    }

    void FuzzySearchBoxControl::ItemsSource(Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine> const& value)
    {
        SetValue(ItemsSourceProperty(), value);
    }

    void FuzzySearchBoxControl::SearchString(const winrt::hstring searchString)
    {
        FuzzySearchTextBox().Text(searchString);
    }

    void FuzzySearchBoxControl::SelectFirstItem()
    {
        if (ItemsSource().Size() > 0)
        {
            ListBox().SelectedIndex(0);
        }
    }

    void FuzzySearchBoxControl::SetFontSize(til::size fontSize)
    {
        _fontSize = fontSize;
    }

    void FuzzySearchBoxControl::SetSwapChainHandle(HANDLE handle)
    {
        auto nativePanel = FuzzySearchSwapChainPanel().as<ISwapChainPanelNative2>();
        nativePanel->SetSwapChainHandle(handle);
    }

    void FuzzySearchBoxControl::TextBoxTextChanged(winrt::Windows::Foundation::IInspectable const& /*sender*/, winrt::Windows::UI::Xaml::RoutedEventArgs const& /*e*/)
    {
        auto a = FuzzySearchTextBox().Text();
        _SearchHandlers(a, false, true);
    }

    void FuzzySearchBoxControl::TextBoxKeyDown(const winrt::Windows::Foundation::IInspectable& /*sender*/, const Input::KeyRoutedEventArgs& e)
    {
        if (e.OriginalKey() == winrt::Windows::System::VirtualKey::Escape)
        {
            _ClosedHandlers(*this, e);
            e.Handled(true);
        }
        else if (e.OriginalKey() == winrt::Windows::System::VirtualKey::Enter)
        {
            auto selectedItem = ListBox().SelectedItem();
            if (selectedItem)
            {
                auto castedItem = selectedItem.try_as<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>();
                if (castedItem)
                {
                    _OnReturnHandlers(*this, castedItem);
                    e.Handled(true);
                }
            }
        }
    }

    void FuzzySearchBoxControl::OnListBoxSelectionChanged(winrt::Windows::Foundation::IInspectable const&, Windows::UI::Xaml::Controls::SelectionChangedEventArgs const& /*e*/)
    {
        auto selectedItem = ListBox().SelectedItem();
        if (selectedItem)
        {
            auto castedItem = selectedItem.try_as<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>();
            if (castedItem)
            {
                _SelectionChangedHandlers(*this, castedItem);
            }
        }
    }

    void FuzzySearchBoxControl::OnSwapChainPanelSizeChanged(winrt::Windows::Foundation::IInspectable const&, winrt::Windows::UI::Xaml::SizeChangedEventArgs const& e)
    {
        _PreviewSwapChainPanelSizeChangedHandlers(*this, e);
    }

    void FuzzySearchBoxControl::SetFocusOnTextbox()
    {
        if (FuzzySearchTextBox())
        {
            Input::FocusManager::TryFocusAsync(FuzzySearchTextBox(), FocusState::Keyboard);
            FuzzySearchTextBox().SelectAll();
        }
    }

    til::point FuzzySearchBoxControl::_toPosInDips(const Core::Point terminalCellPos)
    {
        const til::point terminalPos{ terminalCellPos };
        const til::size marginsInDips{ til::math::rounding, FuzzySearchSwapChainPanel().Margin().Left, FuzzySearchSwapChainPanel().Margin().Top };
        const til::point posInPixels{ terminalPos * _fontSize };
        const auto scale{ FuzzySearchSwapChainPanel().CompositionScaleX() };
        const til::point posInDIPs{ til::math::flooring, posInPixels.x / scale, posInPixels.y / scale };
        return posInDIPs + marginsInDips;
    }
}
