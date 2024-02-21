#pragma once

#include <winrt/Windows.Foundation.h>
#include "FuzzySearchTextSegment.g.h"
#include "FuzzySearchTextLine.g.h"
#include "FuzzySearchResult.g.h"

namespace winrt::Microsoft::Terminal::Control::implementation
{
    struct FuzzySearchTextSegment : FuzzySearchTextSegmentT<FuzzySearchTextSegment>
    {
        FuzzySearchTextSegment();
        FuzzySearchTextSegment(const winrt::hstring& textSegment, bool isHighlighted);

        WINRT_CALLBACK(PropertyChanged, Windows::UI::Xaml::Data::PropertyChangedEventHandler);
        WINRT_OBSERVABLE_PROPERTY(winrt::hstring, TextSegment, _PropertyChangedHandlers);
        WINRT_OBSERVABLE_PROPERTY(bool, IsHighlighted, _PropertyChangedHandlers);
    };

    struct FuzzySearchTextLine : FuzzySearchTextLineT<FuzzySearchTextLine>
    {
        FuzzySearchTextLine() = default;
        FuzzySearchTextLine(const Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextSegment>& segments, int32_t score, int32_t row, int32_t firstPosition, int32_t length);

        WINRT_CALLBACK(PropertyChanged, Windows::UI::Xaml::Data::PropertyChangedEventHandler);
        WINRT_OBSERVABLE_PROPERTY(Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextSegment>, Segments, _PropertyChangedHandlers);
        WINRT_OBSERVABLE_PROPERTY(int32_t, Score, _PropertyChangedHandlers);
        WINRT_OBSERVABLE_PROPERTY(int32_t, Row, _PropertyChangedHandlers);
        WINRT_OBSERVABLE_PROPERTY(int32_t, FirstPosition, _PropertyChangedHandlers);
        WINRT_OBSERVABLE_PROPERTY(int32_t, Length, _PropertyChangedHandlers);
    };

    struct FuzzySearchResult : FuzzySearchResultT<FuzzySearchResult>
    {
        FuzzySearchResult() = default;
        FuzzySearchResult(const Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>& results, int32_t totalRowsSearched, int32_t numberOfResults);

        WINRT_PROPERTY(Windows::Foundation::Collections::IVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>, Results);
        WINRT_PROPERTY(int32_t, TotalRowsSearched);
        WINRT_PROPERTY(int32_t, NumberOfResults);
    };
}

namespace winrt::Microsoft::Terminal::Control::factory_implementation
{
    BASIC_FACTORY(FuzzySearchTextSegment);
    BASIC_FACTORY(FuzzySearchTextLine);
    BASIC_FACTORY(FuzzySearchResult);
}
