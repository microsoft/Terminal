[1mdiff --git a/src/cascadia/TerminalApp/AppActionHandlers.cpp b/src/cascadia/TerminalApp/AppActionHandlers.cpp[m
[1mindex 481fce336..a65aa9d71 100644[m
[1m--- a/src/cascadia/TerminalApp/AppActionHandlers.cpp[m
[1m+++ b/src/cascadia/TerminalApp/AppActionHandlers.cpp[m
[36m@@ -561,6 +561,17 @@[m [mnamespace winrt::TerminalApp::implementation[m
         args.Handled(true);[m
     }[m
 [m
[32m+[m[32m    void TerminalPage::_HandleFuzzyFind(const IInspectable& sender,[m[41m[m
[32m+[m[32m                                   const ActionEventArgs& args)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        if (const auto activeTab{ _senderOrFocusedTab(sender) })[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            _SetFocusedTab(*activeTab);[m[41m[m
[32m+[m[32m            _FuzzyFind(*activeTab);[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[32m        args.Handled(true);[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
     void TerminalPage::_HandleResetFontSize(const IInspectable& /*sender*/,[m
                                             const ActionEventArgs& args)[m
     {[m
[1mdiff --git a/src/cascadia/TerminalApp/TerminalPage.cpp b/src/cascadia/TerminalApp/TerminalPage.cpp[m
[1mindex d8673377c..066e98fcc 100644[m
[1m--- a/src/cascadia/TerminalApp/TerminalPage.cpp[m
[1m+++ b/src/cascadia/TerminalApp/TerminalPage.cpp[m
[36m@@ -3532,6 +3532,14 @@[m [mnamespace winrt::TerminalApp::implementation[m
         }[m
     }[m
 [m
[32m+[m[32m    void TerminalPage::_FuzzyFind(const TerminalTab& tab)[m
[32m+[m[32m    {[m
[32m+[m[32m        if (const auto& control{ tab.GetActiveTerminalControl() })[m
[32m+[m[32m        {[m
[32m+[m[32m            control.CreateFuzzySearchBoxControl();[m
[32m+[m[32m        }[m
[32m+[m[32m    }[m
[32m+[m
     // Method Description:[m
     // - Toggles borderless mode. Hides the tab row, and raises our[m
     //   FocusModeChanged event.[m
[1mdiff --git a/src/cascadia/TerminalApp/TerminalPage.h b/src/cascadia/TerminalApp/TerminalPage.h[m
[1mindex 90caedf4a..7860fbef1 100644[m
[1m--- a/src/cascadia/TerminalApp/TerminalPage.h[m
[1m+++ b/src/cascadia/TerminalApp/TerminalPage.h[m
[36m@@ -441,6 +441,7 @@[m [mnamespace winrt::TerminalApp::implementation[m
         void _OnSwitchToTabRequested(const IInspectable& sender, const winrt::TerminalApp::TabBase& tab);[m
 [m
         void _Find(const TerminalTab& tab);[m
[32m+[m[32m        void _FuzzyFind(const TerminalTab& tab);[m
 [m
         winrt::Microsoft::Terminal::Control::TermControl _CreateNewControlAndContent(const winrt::Microsoft::Terminal::Settings::Model::TerminalSettingsCreateResult& settings,[m
                                                                                      const winrt::Microsoft::Terminal::TerminalConnection::ITerminalConnection& connection);[m
[1mdiff --git a/src/cascadia/TerminalControl/ControlCore.cpp b/src/cascadia/TerminalControl/ControlCore.cpp[m
[1mindex 4efcabf71..35f4845d2 100644[m
[1m--- a/src/cascadia/TerminalControl/ControlCore.cpp[m
[1m+++ b/src/cascadia/TerminalControl/ControlCore.cpp[m
[36m@@ -22,6 +22,9 @@[m
 #include "ControlCore.g.cpp"[m
 #include "SelectionColor.g.cpp"[m
 [m
[32m+[m[32m#include "FuzzySearchTextSegment.h"[m[41m[m
[32m+[m[32m#include "fzf/fzf.h"[m[41m[m
[32m+[m[41m[m
 using namespace ::Microsoft::Console::Types;[m
 using namespace ::Microsoft::Console::VirtualTerminal;[m
 using namespace ::Microsoft::Terminal::Core;[m
[36m@@ -148,11 +151,175 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
             _renderer->SetRendererEnteredErrorStateCallback([this]() { _RendererEnteredErrorStateHandlers(nullptr, nullptr); });[m
 [m
             THROW_IF_FAILED(localPointerToThread->Initialize(_renderer.get()));[m
[32m+[m[41m[m
[32m+[m[32m            auto fuzzySearchRenderThread = std::make_unique<::Microsoft::Console::Render::RenderThread>();[m[41m[m
[32m+[m[32m            auto* const localPointerToFuzzySearchThread = fuzzySearchRenderThread.get();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            _fuzzySearchRenderData = std::make_unique<FuzzySearchRenderData>(_terminal.get());[m[41m[m
[32m+[m[32m            _fuzzySearchRenderer = std::make_unique<::Microsoft::Console::Render::Renderer>(renderSettings, _fuzzySearchRenderData.get(), nullptr, 0, std::move(fuzzySearchRenderThread));[m[41m[m
[32m+[m[32m            _fuzzySearchRenderData->SetRenderer(_fuzzySearchRenderer.get());[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            _fuzzySearchRenderer->SetBackgroundColorChangedCallback([this]() { _rendererBackgroundColorChanged(); });[m[41m[m
[32m+[m[32m            _fuzzySearchRenderer->SetFrameColorChangedCallback([this]() { _rendererTabColorChanged(); });[m[41m[m
[32m+[m[32m            _fuzzySearchRenderer->SetRendererEnteredErrorStateCallback([this]() { _RendererEnteredErrorStateHandlers(nullptr, nullptr); });[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            THROW_IF_FAILED(localPointerToFuzzySearchThread->Initialize(_fuzzySearchRenderer.get()));[m[41m[m
         }[m
 [m
         UpdateSettings(settings, unfocusedAppearance);[m
     }[m
 [m
[32m+[m[32m    bool ControlCore::InitializeFuzzySearch(const float actualWidth,[m[41m[m
[32m+[m[32m                                            const float actualHeight,[m[41m[m
[32m+[m[32m                                            const float compositionScale)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        assert(_settings);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        _fuzzySearchPanelWidth = actualWidth;[m[41m[m
[32m+[m[32m        _fuzzySearchPanelHeight = actualHeight;[m[41m[m
[32m+[m[32m        _fuzzySearchCompositionScale = compositionScale;[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        { // scope for terminalLock[m[41m[m
[32m+[m[32m            const auto lock = _terminal->LockForWriting();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            const auto windowWidth = actualWidth * compositionScale;[m[41m[m
[32m+[m[32m            const auto windowHeight = actualHeight * compositionScale;[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            if (windowWidth == 0 || windowHeight == 0)[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                return false;[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            if (_settings->UseAtlasEngine())[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                _fuzzySearchRenderEngine = std::make_unique<::Microsoft::Console::Render::AtlasEngine>();[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[32m            else[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                _fuzzySearchRenderEngine = std::make_unique<::Microsoft::Console::Render::DxEngine>();[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            _fuzzySearchRenderer->AddRenderEngine(_fuzzySearchRenderEngine.get());[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            const til::size windowSize{ til::math::rounding, windowWidth, windowHeight };[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            // First set up the dx engine with the window size in pixels.[m[41m[m
[32m+[m[32m            // Then, using the font, get the number of characters that can fit.[m[41m[m
[32m+[m[32m            // Resize our terminal connection to match that size, and initialize the terminal with that size.[m[41m[m
[32m+[m[32m            const auto viewInPixels = Viewport::FromDimensions({ 0, 0 }, windowSize);[m[41m[m
[32m+[m[32m            LOG_IF_FAILED(_fuzzySearchRenderEngine->SetWindowSize({ viewInPixels.Width(), viewInPixels.Height() }));[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            // Update DxEngine's SelectionBackground[m[41m[m
[32m+[m[32m            _fuzzySearchRenderEngine->SetSelectionBackground(til::color{ _settings->SelectionBackground() });[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            _fuzzySearchRenderEngine->SetWarningCallback(std::bind(&ControlCore::_rendererWarning, this, std::placeholders::_1));[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            // Tell the render engine to notify us when the swap chain changes.[m[41m[m
[32m+[m[32m            // We do this after we initially set the swapchain so as to avoid[m[41m[m
[32m+[m[32m            // unnecessary callbacks (and locking problems)[m[41m[m
[32m+[m[32m            _fuzzySearchRenderEngine->SetCallback([this](HANDLE handle) {[m[41m[m
[32m+[m[32m                _fuzzySearchRenderEngineSwapChainChanged(handle);[m[41m[m
[32m+[m[32m            });[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            _fuzzySearchRenderEngine->SetRetroTerminalEffect(_settings->RetroTerminalEffect());[m[41m[m
[32m+[m[32m            _fuzzySearchRenderEngine->SetPixelShaderPath(_settings->PixelShaderPath());[m[41m[m
[32m+[m[32m            _fuzzySearchRenderEngine->SetForceFullRepaintRendering(_settings->ForceFullRepaintRendering());[m[41m[m
[32m+[m[32m            _fuzzySearchRenderEngine->SetSoftwareRendering(_settings->SoftwareRendering());[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            // GH#5098: Inform the engine of the opacity of the default text background.[m[41m[m
[32m+[m[32m            // GH#11315: Always do this, even if they don't have acrylic on.[m[41m[m
[32m+[m[32m            _fuzzySearchRenderEngine->EnableTransparentBackground(_isBackgroundTransparent());[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            THROW_IF_FAILED(_fuzzySearchRenderEngine->Enable());[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            const auto newDpi = static_cast<int>(lrint(_compositionScale * USER_DEFAULT_SCREEN_DPI));[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            std::unordered_map<std::wstring_view, uint32_t> featureMap;[m[41m[m
[32m+[m[32m            if (const auto fontFeatures = _settings->FontFeatures())[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                featureMap.reserve(fontFeatures.Size());[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                for (const auto& [tag, param] : fontFeatures)[m[41m[m
[32m+[m[32m                {[m[41m[m
[32m+[m[32m                    featureMap.emplace(tag, param);[m[41m[m
[32m+[m[32m                }[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[32m            std::unordered_map<std::wstring_view, float> axesMap;[m[41m[m
[32m+[m[32m            if (const auto fontAxes = _settings->FontAxes())[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                axesMap.reserve(fontAxes.Size());[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                for (const auto& [axis, value] : fontAxes)[m[41m[m
[32m+[m[32m                {[m[41m[m
[32m+[m[32m                    axesMap.emplace(axis, value);[m[41m[m
[32m+[m[32m                }[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            // TODO: MSFT:20895307 If the font doesn't exist, this doesn't[m[41m[m
[32m+[m[32m            //      actually fail. We need a way to gracefully fallback.[m[41m[m
[32m+[m[32m            LOG_IF_FAILED(_fuzzySearchRenderEngine->UpdateDpi(newDpi));[m[41m[m
[32m+[m[32m            LOG_IF_FAILED(_fuzzySearchRenderEngine->UpdateFont(_desiredFont, _actualFont, featureMap, axesMap));[m[41m[m
[32m+[m[32m        } // scope for TerminalLock[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        return true;[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void ControlCore::EnterFuzzySearchMode()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        _fuzzySearchActive = true;[m[41m[m
[32m+[m[32m        _sizeFuzzySearchPreview();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void ControlCore::ExitFuzzySearchMode()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        _fuzzySearchActive = false;[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void ControlCore::SelectChar(int32_t row, int32_t col)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        const auto lock = _terminal->LockForWriting();[m[41m[m
[32m+[m[32m        _terminal->SelectNewRegion(til::point{ col, row }, til::point{ col, row });[m[41m[m
[32m+[m[32m        if (_terminal->SelectionMode() != ::Terminal::SelectionInteractionMode::Mark)[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            _terminal->ToggleMarkMode();[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[32m        else[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            _updateSelectionUI();[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[32m        _renderer->TriggerSelection();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    winrt::fire_and_forget ControlCore::_fuzzySearchRenderEngineSwapChainChanged(const HANDLE sourceHandle)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        // `sourceHandle` is a weak ref to a HANDLE that's ultimately owned by the[m[41m[m
[32m+[m[32m        // render engine's own unique_handle. We'll add another ref to it here.[m[41m[m
[32m+[m[32m        // This will make sure that we always have a valid HANDLE to give to[m[41m[m
[32m+[m[32m        // callers of our own SwapChainHandle method, even if the renderer is[m[41m[m
[32m+[m[32m        // currently in the process of discarding this value and creating a new[m[41m[m
[32m+[m[32m        // one. Callers should have already set up the SwapChainChanged[m[41m[m
[32m+[m[32m        // callback, so this all works out.[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        winrt::handle duplicatedHandle;[m[41m[m
[32m+[m[32m        const auto processHandle = GetCurrentProcess();[m[41m[m
[32m+[m[32m        THROW_IF_WIN32_BOOL_FALSE(DuplicateHandle(processHandle, sourceHandle, processHandle, duplicatedHandle.put(), 0, FALSE, DUPLICATE_SAME_ACCESS));[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        const auto weakThis{ get_weak() };[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        // Concurrent read of _dispatcher is safe, because Detach() calls WaitForPaintCompletionAndDisable()[m[41m[m
[32m+[m[32m        // which blocks until this call returns. _dispatcher will only be changed afterwards.[m[41m[m
[32m+[m[32m        co_await wil::resume_foreground(_dispatcher);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        if (auto core{ weakThis.get() })[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            // `this` is safe to use now[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            _fuzzySearchLastSwapChainHandle = std::move(duplicatedHandle);[m[41m[m
[32m+[m[32m            // Now bubble the event up to the control.[m[41m[m
[32m+[m[32m            _FuzzySearchSwapChainChangedHandlers(*this, winrt::box_value<uint64_t>(reinterpret_cast<uint64_t>(_fuzzySearchLastSwapChainHandle.get())));[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
     void ControlCore::_setupDispatcherAndCallbacks()[m
     {[m
         // Get our dispatcher. If we're hosted in-proc with XAML, this will get[m
[36m@@ -1136,6 +1303,10 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
                                   const float height)[m
     {[m
         SizeOrScaleChanged(width, height, _compositionScale);[m
[32m+[m[32m        if (_fuzzySearchActive)[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            _sizeFuzzySearchPreview();[m[41m[m
[32m+[m[32m        }[m[41m[m
     }[m
 [m
     void ControlCore::ScaleChanged(const float scale)[m
[36m@@ -1708,6 +1879,242 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
         return _cachedSearchResultRows;[m
     }[m
 [m
[32m+[m[32m    Control::FuzzySearchResult ControlCore::FuzzySearch(const winrt::hstring& text)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        struct RowResult[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            std::wstring rowFullText;[m[41m[m
[32m+[m[32m            std::string asciiRowText;[m[41m[m
[32m+[m[32m            fzf_position_t* pos;[m[41m[m
[32m+[m[32m            int score;[m[41m[m
[32m+[m[32m            int rowNumber;[m[41m[m
[32m+[m[32m            long long length;[m[41m[m
[32m+[m[32m        };[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        const auto lock = _terminal->LockForWriting();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        auto searchResults = winrt::single_threaded_observable_vector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>();[m[41m[m
[32m+[m[32m        auto renderData = this->GetRenderData();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        auto searchTextNotBlank = std::any_of(text.begin(), text.end(), [](wchar_t ch) {[m[41m[m
[32m+[m[32m            return !std::iswspace(ch);[m[41m[m
[32m+[m[32m        });[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        if (!searchTextNotBlank)[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            return winrt::make<FuzzySearchResult>(searchResults, 0, 0);[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        fzf_slab_t* slab = fzf_make_default_slab();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        std::wstring searchTextCStr = text.c_str();[m[41m[m
[32m+[m[32m        int sizeOfSearchTextCStr = WideCharToMultiByte(CP_UTF8, 0, searchTextCStr.c_str(), -1, nullptr, 0, nullptr, nullptr);[m[41m[m
[32m+[m[32m        std::string asciiSearchString(sizeOfSearchTextCStr, 0);[m[41m[m
[32m+[m[32m        WideCharToMultiByte(CP_UTF8, 0, searchTextCStr.c_str(), -1, &asciiSearchString[0], sizeOfSearchTextCStr, nullptr, nullptr);[m[41m[m
[32m+[m[32m        asciiSearchString.pop_back();[m[41m[m
[32m+[m[32m        char* asciiSearchStringCStr = const_cast<char*>(asciiSearchString.c_str());[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        fzf_pattern_t* pattern = fzf_parse_pattern(CaseSmart, false, asciiSearchStringCStr, true);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        auto rowResults = std::vector<RowResult>();[m[41m[m
[32m+[m[32m        auto rowCount = renderData->GetTextBuffer().GetLastNonSpaceCharacter().y + 1;[m[41m[m
[32m+[m[32m        int numberOfNonSpaceLines = 0;[m[41m[m
[32m+[m[32m        int minScore = 0;[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        for (int rowNumber = 0; rowNumber < rowCount; rowNumber++)[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            std::wstring_view rowText = renderData->GetTextBuffer().GetRowByOffset(rowNumber).GetText();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            auto findLastNonBlankIndex = [](const std::wstring& str) {[m[41m[m
[32m+[m[32m                auto it = std::find_if(str.rbegin(), str.rend(), [](wchar_t ch) {[m[41m[m
[32m+[m[32m                    return !std::iswspace(ch);[m[41m[m
[32m+[m[32m                });[m[41m[m
[32m+[m[32m                return it == str.rend() ? -1 : std::distance(it, str.rend()) - 1;[m[41m[m
[32m+[m[32m            };[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            auto length = findLastNonBlankIndex(std::wstring(rowText));[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            if (length > 0)[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                numberOfNonSpaceLines++;[m[41m[m
[32m+[m[32m                std::wstring rowFullText = rowText.data();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                int bufferSize = WideCharToMultiByte(CP_UTF8, 0, rowText.data(), -1, nullptr, 0, nullptr, nullptr);[m[41m[m
[32m+[m[32m                std::string asciiRowText(bufferSize, 0);[m[41m[m
[32m+[m[32m                WideCharToMultiByte(CP_UTF8, 0, rowText.data(), -1, &asciiRowText[0], bufferSize, nullptr, nullptr);[m[41m[m
[32m+[m[32m                asciiRowText.pop_back();[m[41m[m
[32m+[m[32m                char* asciiRowTextCStr = const_cast<char*>(asciiRowText.c_str());[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                int rowScore = fzf_get_score(asciiRowTextCStr, pattern, slab);[m[41m[m
[32m+[m[32m                if (rowScore > minScore)[m[41m[m
[32m+[m[32m                {[m[41m[m
[32m+[m[32m                    fzf_position_t* pos = fzf_get_positions(asciiRowTextCStr, pattern, slab);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                    auto rowResult = RowResult{};[m[41m[m
[32m+[m[32m                    rowResult.rowFullText = rowFullText;[m[41m[m
[32m+[m[32m                    rowResult.asciiRowText = asciiRowText;[m[41m[m
[32m+[m[32m                    rowResult.pos = pos;[m[41m[m
[32m+[m[32m                    rowResult.rowNumber = rowNumber;[m[41m[m
[32m+[m[32m                    rowResult.score = rowScore;[m[41m[m
[32m+[m[32m                    rowResult.length = length;[m[41m[m
[32m+[m[32m                    rowResults.push_back(rowResult);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                    std::sort(rowResults.begin(), rowResults.end(), [](const auto& a, const auto& b) {[m[41m[m
[32m+[m[32m                        if (a.score != b.score)[m[41m[m
[32m+[m[32m                        {[m[41m[m
[32m+[m[32m                            return a.score > b.score;[m[41m[m
[32m+[m[32m                        }[m[41m[m
[32m+[m[32m                        return a.length < b.length;[m[41m[m
[32m+[m[32m                    });[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                    if (rowResults.size() > 100)[m[41m[m
[32m+[m[32m                    {[m[41m[m
[32m+[m[32m                        fzf_free_positions(rowResults[100].pos);[m[41m[m
[32m+[m[32m                        rowResults.pop_back();[m[41m[m
[32m+[m[32m                        minScore = rowResults[99].score;[m[41m[m
[32m+[m[32m                    }[m[41m[m
[32m+[m[32m                }[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        fzf_free_pattern(pattern);[m[41m[m
[32m+[m[32m        fzf_free_slab(slab);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        for (auto p : rowResults)[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            std::sort(p.pos->data, p.pos->data + p.pos->size, [](uint32_t a, uint32_t b) {[m[41m[m
[32m+[m[32m                return a > b;[m[41m[m
[32m+[m[32m            });[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            std::vector<size_t> wideCharPositions;[m[41m[m
[32m+[m[32m            size_t wideCharIndex = 0;[m[41m[m
[32m+[m[32m            size_t asciiCharIndex = 0;[m[41m[m
[32m+[m[32m            while (wideCharIndex < p.rowFullText.length() && asciiCharIndex < p.asciiRowText.length())[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                if (std::find(p.pos->data, p.pos->data + p.pos->size, asciiCharIndex) != p.pos->data + p.pos->size)[m[41m[m
[32m+[m[32m                {[m[41m[m
[32m+[m[32m                    wideCharPositions.push_back(wideCharIndex);[m[41m[m
[32m+[m[32m                }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                wchar_t wideChar = p.rowFullText[wideCharIndex];[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                char utf8Char[5];[m[41m[m
[32m+[m[32m                size_t length = WideCharToMultiByte(CP_UTF8, 0, &wideChar, 1, utf8Char, 5, nullptr, nullptr);[m[41m[m
[32m+[m[32m                wideCharIndex++;[m[41m[m
[32m+[m[32m                asciiCharIndex += length;[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            auto runs = winrt::single_threaded_observable_vector<winrt::Microsoft::Terminal::Control::FuzzySearchTextSegment>();[m[41m[m
[32m+[m[32m            std::wstring currentRun;[m[41m[m
[32m+[m[32m            bool isCurrentRunHighlighted = false;[m[41m[m
[32m+[m[32m            size_t highlightIndex = 0;[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            for (uint32_t i = 0; i < p.rowFullText.length() - 1; ++i)[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                if (highlightIndex < wideCharPositions.size() && i == wideCharPositions[highlightIndex])[m[41m[m
[32m+[m[32m                {[m[41m[m
[32m+[m[32m                    if (!isCurrentRunHighlighted)[m[41m[m
[32m+[m[32m                    {[m[41m[m
[32m+[m[32m                        if (!currentRun.empty())[m[41m[m
[32m+[m[32m                        {[m[41m[m
[32m+[m[32m                            auto textSegmentHstr = winrt::hstring(currentRun);[m[41m[m
[32m+[m[32m                            auto textSegment = winrt::make<FuzzySearchTextSegment>(textSegmentHstr, false);[m[41m[m
[32m+[m[32m                            runs.Append(textSegment);[m[41m[m
[32m+[m[32m                            currentRun.clear();[m[41m[m
[32m+[m[32m                        }[m[41m[m
[32m+[m[32m                        isCurrentRunHighlighted = true;[m[41m[m
[32m+[m[32m                    }[m[41m[m
[32m+[m[32m                    highlightIndex++;[m[41m[m
[32m+[m[32m                }[m[41m[m
[32m+[m[32m                else[m[41m[m
[32m+[m[32m                {[m[41m[m
[32m+[m[32m                    if (isCurrentRunHighlighted)[m[41m[m
[32m+[m[32m                    {[m[41m[m
[32m+[m[32m                        if (!currentRun.empty())[m[41m[m
[32m+[m[32m                        {[m[41m[m
[32m+[m[32m                            winrt::hstring textSegmentHstr = winrt::hstring(currentRun);[m[41m[m
[32m+[m[32m                            auto textSegment = winrt::make<FuzzySearchTextSegment>(textSegmentHstr, true);[m[41m[m
[32m+[m[32m                            runs.Append(textSegment);[m[41m[m
[32m+[m[32m                            currentRun.clear();[m[41m[m
[32m+[m[32m                        }[m[41m[m
[32m+[m[32m                        isCurrentRunHighlighted = false;[m[41m[m
[32m+[m[32m                    }[m[41m[m
[32m+[m[32m                }[m[41m[m
[32m+[m[32m                currentRun += p.rowFullText[i];[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            if (!currentRun.empty())[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                winrt::hstring textSegmentHstr = winrt::hstring(currentRun);[m[41m[m
[32m+[m[32m                auto textSegment = winrt::make<FuzzySearchTextSegment>(textSegmentHstr, false);[m[41m[m
[32m+[m[32m                runs.Append(textSegment);[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            auto findLastNonBlankIndex = [](const std::string& str) {[m[41m[m
[32m+[m[32m                auto it = std::find_if(str.rbegin(), str.rend(), [](unsigned char ch) {[m[41m[m
[32m+[m[32m                    return !std::isspace(ch);[m[41m[m
[32m+[m[32m                });[m[41m[m
[32m+[m[32m                return std::distance(it, str.rend()) - 1;[m[41m[m
[32m+[m[32m            };[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            auto line = winrt::make<FuzzySearchTextLine>(runs, p.score, p.rowNumber, static_cast<int32_t>(p.pos->data[p.pos->size - 1]), static_cast<int32_t>(p.length));[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            searchResults.Append(line);[m[41m[m
[32m+[m[32m            fzf_free_positions(p.pos);[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        auto fuzzySearchResult = winrt::make<FuzzySearchResult>(searchResults, numberOfNonSpaceLines, searchResults.Size());[m[41m[m
[32m+[m[32m        return fuzzySearchResult;[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void ControlCore::FuzzySearchSelectionChanged(int32_t row)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        _fuzzySearchRenderData->SetTopRow(row);[m[41m[m
[32m+[m[32m        LOG_IF_FAILED(_fuzzySearchRenderEngine->InvalidateAll());[m[41m[m
[32m+[m[32m        _fuzzySearchRenderer->NotifyPaintFrame();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void ControlCore::FuzzySearchPreviewSizeChanged(const float width,[m[41m[m
[32m+[m[32m                                                    const float height)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        _fuzzySearchPanelWidth = width;[m[41m[m
[32m+[m[32m        _fuzzySearchPanelHeight = height;[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        _fuzzySearchRenderer->EnablePainting();[m[41m[m
[32m+[m[32m        _sizeFuzzySearchPreview();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void ControlCore::_sizeFuzzySearchPreview()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        auto lock = _terminal->LockForWriting();[m[41m[m
[32m+[m[32m        auto lock2 = _fuzzySearchRenderData->LockForWriting();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        auto cx = gsl::narrow_cast<til::CoordType>(lrint(_fuzzySearchPanelWidth * _compositionScale));[m[41m[m
[32m+[m[32m        auto cy = gsl::narrow_cast<til::CoordType>(lrint(_fuzzySearchPanelHeight * _compositionScale));[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        cx = std::max(cx, _actualFont.GetSize().width);[m[41m[m
[32m+[m[32m        cy = std::max(cy, _actualFont.GetSize().height);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        const auto viewInPixels = Viewport::FromDimensions({ 0, 0 }, { cx, cy });[m[41m[m
[32m+[m[32m        const auto vp = _renderEngine->GetViewportInCharacters(viewInPixels);[m[41m[m
[32m+[m[32m        _fuzzySearchRenderData->SetSize(vp.Dimensions());[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        auto size = til::size{ til::math::rounding, static_cast<float>(_terminal->GetViewport().Width()), static_cast<float>(_terminal->GetTextBuffer().TotalRowCount()) };[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        auto newTextBuffer = std::make_unique<TextBuffer>(size,[m[41m[m
[32m+[m[32m                                                          TextAttribute{},[m[41m[m
[32m+[m[32m                                                          0,[m[41m[m
[32m+[m[32m                                                          true,[m[41m[m
[32m+[m[32m                                                          *_fuzzySearchRenderer);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        TextBuffer::Reflow(_terminal->GetTextBuffer(), *newTextBuffer.get());[m[41m[m
[32m+[m[32m        _fuzzySearchRenderData->SetTextBuffer(std::move(newTextBuffer));[m[41m[m
[32m+[m[32m        THROW_IF_FAILED(_fuzzySearchRenderEngine->SetWindowSize({ cx, cy }));[m[41m[m
[32m+[m[32m        LOG_IF_FAILED(_fuzzySearchRenderEngine->InvalidateAll());[m[41m[m
[32m+[m[32m        _fuzzySearchRenderer->NotifyPaintFrame();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[41m[m
     void ControlCore::ClearSearch()[m
     {[m
         _terminal->AlwaysNotifyOnBufferRotation(false);[m
[1mdiff --git a/src/cascadia/TerminalControl/ControlCore.h b/src/cascadia/TerminalControl/ControlCore.h[m
[1mindex 90cc5fca4..8b5b97c46 100644[m
[1m--- a/src/cascadia/TerminalControl/ControlCore.h[m
[1m+++ b/src/cascadia/TerminalControl/ControlCore.h[m
[36m@@ -24,6 +24,7 @@[m
 #include "../../cascadia/TerminalCore/Terminal.hpp"[m
 #include "../buffer/out/search.h"[m
 #include "../buffer/out/TextColor.h"[m
[32m+[m[32m#include "../../cascadia/TerminalCore/FuzzySearchRenderData.hpp"[m[41m[m
 [m
 namespace ControlUnitTests[m
 {[m
[36m@@ -245,6 +246,16 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
         bool ShouldShowSelectCommand();[m
         bool ShouldShowSelectOutput();[m
 [m
[32m+[m[32m        Control::FuzzySearchResult FuzzySearch(const winrt::hstring& text);[m[41m[m
[32m+[m[32m        bool InitializeFuzzySearch(const float actualWidth,[m[41m[m
[32m+[m[32m                                   const float actualHeight,[m[41m[m
[32m+[m[32m                                   const float compositionScale);[m[41m[m
[32m+[m[32m        void FuzzySearchSelectionChanged(int32_t row);[m[41m[m
[32m+[m[32m        void FuzzySearchPreviewSizeChanged(const float width, const float height);[m[41m[m
[32m+[m[32m        void EnterFuzzySearchMode();[m[41m[m
[32m+[m[32m        void ExitFuzzySearchMode();[m[41m[m
[32m+[m[32m        void SelectChar(int32_t row, int32_t col);[m[41m[m
[32m+[m[41m[m
         RUNTIME_SETTING(double, Opacity, _settings->Opacity());[m
         RUNTIME_SETTING(double, FocusedOpacity, FocusedAppearance().Opacity());[m
         RUNTIME_SETTING(bool, UseAcrylic, _settings->UseAcrylic());[m
[36m@@ -274,6 +285,7 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
         TYPED_EVENT(UpdateSelectionMarkers,    IInspectable, Control::UpdateSelectionMarkersEventArgs);[m
         TYPED_EVENT(OpenHyperlink,             IInspectable, Control::OpenHyperlinkEventArgs);[m
         TYPED_EVENT(CompletionsChanged,        IInspectable, Control::CompletionsChangedEventArgs);[m
[32m+[m[32m        TYPED_EVENT(FuzzySearchSwapChainChanged,          IInspectable, IInspectable);[m[41m[m
 [m
         TYPED_EVENT(CloseTerminalRequested,    IInspectable, IInspectable);[m
         TYPED_EVENT(RestartTerminalRequested,    IInspectable, IInspectable);[m
[36m@@ -370,6 +382,16 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
                                    const std::chrono::microseconds duration);[m
 [m
         winrt::fire_and_forget _terminalCompletionsChanged(std::wstring_view menuJson, unsigned int replaceLength);[m
[32m+[m[32m        float _fuzzySearchPanelWidth{ 0 };[m[41m[m
[32m+[m[32m        float _fuzzySearchPanelHeight{ 0 };[m[41m[m
[32m+[m[32m        float _fuzzySearchCompositionScale{ 0 };[m[41m[m
[32m+[m[32m        std::unique_ptr<::Microsoft::Console::Render::IRenderEngine> _fuzzySearchRenderEngine{ nullptr };[m[41m[m
[32m+[m[32m        std::unique_ptr<::Microsoft::Console::Render::Renderer> _fuzzySearchRenderer{ nullptr };[m[41m[m
[32m+[m[32m        std::shared_ptr<FuzzySearchRenderData> _fuzzySearchRenderData{ nullptr };[m[41m[m
[32m+[m[32m        winrt::fire_and_forget _fuzzySearchRenderEngineSwapChainChanged(const HANDLE handle);[m[41m[m
[32m+[m[32m        winrt::handle _fuzzySearchLastSwapChainHandle{ nullptr };[m[41m[m
[32m+[m[32m        void _sizeFuzzySearchPreview();[m[41m[m
[32m+[m[32m        bool _fuzzySearchActive = false;[m[41m[m
 [m
 #pragma endregion[m
 [m
[1mdiff --git a/src/cascadia/TerminalControl/ControlCore.idl b/src/cascadia/TerminalControl/ControlCore.idl[m
[1mindex 01223fb1a..054176d88 100644[m
[1m--- a/src/cascadia/TerminalControl/ControlCore.idl[m
[1m+++ b/src/cascadia/TerminalControl/ControlCore.idl[m
[36m@@ -4,6 +4,7 @@[m
 import "ICoreState.idl";[m
 import "IControlSettings.idl";[m
 import "EventArgs.idl";[m
[32m+[m[32mimport "FuzzySearchTextSegment.idl";[m[41m[m
 [m
 namespace Microsoft.Terminal.Control[m
 {[m
[36m@@ -159,6 +160,16 @@[m [mnamespace Microsoft.Terminal.Control[m
         Boolean ShouldShowSelectCommand();[m
         Boolean ShouldShowSelectOutput();[m
 [m
[32m+[m[32m        FuzzySearchResult FuzzySearch(String text);[m[41m[m
[32m+[m[32m        Boolean InitializeFuzzySearch(Single actualWidth,[m[41m[m
[32m+[m[32m                                      Single actualHeight,[m[41m[m
[32m+[m[32m                                      Single compositionScale);[m[41m[m
[32m+[m[32m        void FuzzySearchSelectionChanged(Int32 row);[m[41m[m
[32m+[m[32m        void FuzzySearchPreviewSizeChanged(Single width, Single height);[m[41m[m
[32m+[m[32m        void EnterFuzzySearchMode();[m[41m[m
[32m+[m[32m        void ExitFuzzySearchMode();[m[41m[m
[32m+[m[32m        void SelectChar(Int32 row, Int32 col);[m[41m[m
[32m+[m[41m[m
         // These events are called from some background thread[m
         event Windows.Foundation.TypedEventHandler<Object, CopyToClipboardEventArgs> CopyToClipboard;[m
         event Windows.Foundation.TypedEventHandler<Object, TitleChangedEventArgs> TitleChanged;[m
[36m@@ -185,6 +196,7 @@[m [mnamespace Microsoft.Terminal.Control[m
         event Windows.Foundation.TypedEventHandler<Object, OpenHyperlinkEventArgs> OpenHyperlink;[m
         event Windows.Foundation.TypedEventHandler<Object, Object> CloseTerminalRequested;[m
         event Windows.Foundation.TypedEventHandler<Object, Object> RestartTerminalRequested;[m
[32m+[m[32m        event Windows.Foundation.TypedEventHandler<Object, Object> FuzzySearchSwapChainChanged;[m[41m[m
 [m
         event Windows.Foundation.TypedEventHandler<Object, Object> Attached;[m
 [m
[1mdiff --git a/src/cascadia/TerminalControl/FuzzySearchBoxControl.cpp b/src/cascadia/TerminalControl/FuzzySearchBoxControl.cpp[m
[1mnew file mode 100644[m
[1mindex 000000000..af3a41d40[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/FuzzySearchBoxControl.cpp[m
[36m@@ -0,0 +1,214 @@[m
[32m+[m[32m// Copyright (c) Microsoft Corporation[m[41m[m
[32m+[m[32m// Licensed under the MIT license.[m[41m[m
[32m+[m[41m[m
[32m+[m[32m#include "pch.h"[m[41m[m
[32m+[m[32m#include "FuzzySearchBoxControl.h"[m[41m[m
[32m+[m[32m#include "FuzzySearchBoxControl.g.cpp"[m[41m[m
[32m+[m[32m#include <LibraryResources.h>[m[41m[m
[32m+[m[32musing namespace winrt::Windows::UI::Xaml::Media;[m[41m[m
[32m+[m[41m[m
[32m+[m[32musing namespace winrt;[m[41m[m
[32m+[m[32musing namespace winrt::Windows::UI::Xaml;[m[41m[m
[32m+[m[32musing namespace winrt::Windows::UI::Core;[m[41m[m
[32m+[m[41m[m
[32m+[m[32mnamespace winrt::Microsoft::Terminal::Control::implementation[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    FuzzySearchBoxControl::FuzzySearchBoxControl()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        InitializeComponent();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        _focusableElements.insert(FuzzySearchTextBox());[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        FuzzySearchTextBox().KeyUp([this](const IInspectable& sender, Input::KeyRoutedEventArgs const& e) {[m[41m[m
[32m+[m[32m            auto textBox{ sender.try_as<Controls::TextBox>() };[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            if (ListBox() != nullptr)[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                if (e.OriginalKey() == winrt::Windows::System::VirtualKey::Down || e.OriginalKey() == winrt::Windows::System::VirtualKey::Up)[m[41m[m
[32m+[m[32m                {[m[41m[m
[32m+[m[32m                    auto selectedIndex = ListBox().SelectedIndex();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                    if (e.OriginalKey() == winrt::Windows::System::VirtualKey::Down)[m[41m[m
[32m+[m[32m                    {[m[41m[m
[32m+[m[32m                        selectedIndex++;[m[41m[m
[32m+[m[32m                    }[m[41m[m
[32m+[m[32m                    else if (e.OriginalKey() == winrt::Windows::System::VirtualKey::Up)[m[41m[m
[32m+[m[32m                    {[m[41m[m
[32m+[m[32m                        selectedIndex--;[m[41m[m
[32m+[m[32m                    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                    if (selectedIndex >= 0 && selectedIndex < static_cast<int32_t>(ListBox().Items().Size()))[m[41m[m
[32m+[m[32m                    {[m[41m[m
[32m+[m[32m                        ListBox().SelectedIndex(selectedIndex);[m[41m[m
[32m+[m[32m                        ListBox().ScrollIntoView(ListBox().SelectedItem());[m[41m[m
[32m+[m[32m                    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                    e.Handled(true);[m[41m[m
[32m+[m[32m                }[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[32m            else if (e.OriginalKey() == winrt::Windows::System::VirtualKey::Enter)[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                auto selectedItem = ListBox().SelectedItem();[m[41m[m
[32m+[m[32m                if (selectedItem)[m[41m[m
[32m+[m[32m                {[m[41m[m
[32m+[m[32m                    auto castedItem = selectedItem.try_as<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>();[m[41m[m
[32m+[m[32m                    if (castedItem)[m[41m[m
[32m+[m[32m                    {[m[41m[m
[32m+[m[32m                        _OnReturnHandlers(*this, castedItem);[m[41m[m
[32m+[m[32m                        e.Handled(true);[m[41m[m
[32m+[m[32m                    }[m[41m[m
[32m+[m[32m                }[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[32m        });[m[41m[m
[32m+[m[32m        this->FuzzySearchSwapChainPanel().SizeChanged({ this, &FuzzySearchBoxControl::OnSwapChainPanelSizeChanged });[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    bool FuzzySearchBoxControl::ContainsFocus()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        auto focusedElement = Input::FocusManager::GetFocusedElement(this->XamlRoot());[m[41m[m
[32m+[m[32m        if (_focusableElements.count(focusedElement) > 0)[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            return true;[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        return false;[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    double FuzzySearchBoxControl::PreviewActualHeight()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        return FuzzySearchSwapChainPanel().ActualHeight();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[32m    double FuzzySearchBoxControl::PreviewActualWidth()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        return FuzzySearchSwapChainPanel().ActualWidth();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[32m    float FuzzySearchBoxControl::PreviewCompositionScaleX()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        return FuzzySearchSwapChainPanel().CompositionScaleX();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    DependencyProperty FuzzySearchBoxControl::ItemsSourceProperty()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        static DependencyProperty dp = DependencyProperty::Register([m[41m[m
[32m+[m[32m            L"ItemsSource",[m[41m[m
[32m+[m[32m            xaml_typename<Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>>(),[m[41m[m
[32m+[m[32m            xaml_typename<winrt::Microsoft::Terminal::Control::FuzzySearchBoxControl>(),[m[41m[m
[32m+[m[32m            PropertyMetadata{ nullptr });[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        return dp;[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void FuzzySearchBoxControl::SetStatus(int32_t totalRowsSearched, int32_t numberOfResults)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        hstring result;[m[41m[m
[32m+[m[32m        if (totalRowsSearched == 0)[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            result = RS_(L"TermControl_NoMatch");[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[32m        else[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            result = winrt::hstring{ fmt::format(RS_(L"TermControl_NumResults").c_str(), numberOfResults, totalRowsSearched) };[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        StatusBox().Text(result);[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine> FuzzySearchBoxControl::ItemsSource()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        return GetValue(ItemsSourceProperty()).as<Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>>();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void FuzzySearchBoxControl::ItemsSource(Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine> const& value)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        SetValue(ItemsSourceProperty(), value);[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void FuzzySearchBoxControl::SearchString(const winrt::hstring searchString)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        FuzzySearchTextBox().Text(searchString);[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void FuzzySearchBoxControl::SelectFirstItem()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        if (ItemsSource().Size() > 0)[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            ListBox().SelectedIndex(0);[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void FuzzySearchBoxControl::SetFontSize(til::size fontSize)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        _fontSize = fontSize;[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void FuzzySearchBoxControl::SetSwapChainHandle(HANDLE handle)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        auto nativePanel = FuzzySearchSwapChainPanel().as<ISwapChainPanelNative2>();[m[41m[m
[32m+[m[32m        nativePanel->SetSwapChainHandle(handle);[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void FuzzySearchBoxControl::TextBoxTextChanged(winrt::Windows::Foundation::IInspectable const& /*sender*/, winrt::Windows::UI::Xaml::RoutedEventArgs const& /*e*/)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        auto a = FuzzySearchTextBox().Text();[m[41m[m
[32m+[m[32m        _SearchHandlers(a, false, true);[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void FuzzySearchBoxControl::TextBoxKeyDown(const winrt::Windows::Foundation::IInspectable& /*sender*/, const Input::KeyRoutedEventArgs& e)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        if (e.OriginalKey() == winrt::Windows::System::VirtualKey::Escape)[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            _ClosedHandlers(*this, e);[m[41m[m
[32m+[m[32m            e.Handled(true);[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[32m        else if (e.OriginalKey() == winrt::Windows::System::VirtualKey::Enter)[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            auto selectedItem = ListBox().SelectedItem();[m[41m[m
[32m+[m[32m            if (selectedItem)[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                auto castedItem = selectedItem.try_as<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>();[m[41m[m
[32m+[m[32m                if (castedItem)[m[41m[m
[32m+[m[32m                {[m[41m[m
[32m+[m[32m                    _OnReturnHandlers(*this, castedItem);[m[41m[m
[32m+[m[32m                    e.Handled(true);[m[41m[m
[32m+[m[32m                }[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void FuzzySearchBoxControl::OnListBoxSelectionChanged(winrt::Windows::Foundation::IInspectable const&, Windows::UI::Xaml::Controls::SelectionChangedEventArgs const& /*e*/)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        auto selectedItem = ListBox().SelectedItem();[m[41m[m
[32m+[m[32m        if (selectedItem)[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            auto castedItem = selectedItem.try_as<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>();[m[41m[m
[32m+[m[32m            if (castedItem)[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                _SelectionChangedHandlers(*this, castedItem);[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void FuzzySearchBoxControl::OnSwapChainPanelSizeChanged(winrt::Windows::Foundation::IInspectable const&, winrt::Windows::UI::Xaml::SizeChangedEventArgs const& e)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        _PreviewSwapChainPanelSizeChangedHandlers(*this, e);[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void FuzzySearchBoxControl::SetFocusOnTextbox()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        if (FuzzySearchTextBox())[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            Input::FocusManager::TryFocusAsync(FuzzySearchTextBox(), FocusState::Keyboard);[m[41m[m
[32m+[m[32m            FuzzySearchTextBox().SelectAll();[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    til::point FuzzySearchBoxControl::_toPosInDips(const Core::Point terminalCellPos)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        const til::point terminalPos{ terminalCellPos };[m[41m[m
[32m+[m[32m        const til::size marginsInDips{ til::math::rounding, FuzzySearchSwapChainPanel().Margin().Left, FuzzySearchSwapChainPanel().Margin().Top };[m[41m[m
[32m+[m[32m        const til::point posInPixels{ terminalPos * _fontSize };[m[41m[m
[32m+[m[32m        const auto scale{ FuzzySearchSwapChainPanel().CompositionScaleX() };[m[41m[m
[32m+[m[32m        const til::point posInDIPs{ til::math::flooring, posInPixels.x / scale, posInPixels.y / scale };[m[41m[m
[32m+[m[32m        return posInDIPs + marginsInDips;[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[32m}[m[41m[m
[1mdiff --git a/src/cascadia/TerminalControl/FuzzySearchBoxControl.h b/src/cascadia/TerminalControl/FuzzySearchBoxControl.h[m
[1mnew file mode 100644[m
[1mindex 000000000..323b1457c[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/FuzzySearchBoxControl.h[m
[36m@@ -0,0 +1,53 @@[m
[32m+[m[41m[m
[32m+[m[41m[m
[32m+[m[32m#pragma once[m[41m[m
[32m+[m[41m[m
[32m+[m[32m#include "FuzzySearchBoxControl.g.h"[m[41m[m
[32m+[m[41m[m
[32m+[m[32mnamespace winrt::Microsoft::Terminal::Control::implementation[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    struct FuzzySearchBoxControl : FuzzySearchBoxControlT<FuzzySearchBoxControl>[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        FuzzySearchBoxControl();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        static winrt::Windows::UI::Xaml::DependencyProperty ItemsSourceProperty();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        void SetStatus(int32_t totalRowsSearched, int32_t numberOfResults);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        winrt::Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine> ItemsSource();[m[41m[m
[32m+[m[32m        void ItemsSource(winrt::Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine> const& value);[m[41m[m
[32m+[m[32m        void SearchString(const winrt::hstring searchString);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        void SelectFirstItem();[m[41m[m
[32m+[m[32m        void SetFontSize(til::size fontSize);[m[41m[m
[32m+[m[32m        void SetSwapChainHandle(HANDLE swapChainHandle);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        void SetFocusOnTextbox();[m[41m[m
[32m+[m[32m        bool ContainsFocus();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        double PreviewActualHeight();[m[41m[m
[32m+[m[32m        double PreviewActualWidth();[m[41m[m
[32m+[m[32m        float PreviewCompositionScaleX();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        void OnListBoxSelectionChanged(winrt::Windows::Foundation::IInspectable const&, Windows::UI::Xaml::Controls::SelectionChangedEventArgs const& e);[m[41m[m
[32m+[m[32m        void OnSwapChainPanelSizeChanged(winrt::Windows::Foundation::IInspectable const&, winrt::Windows::UI::Xaml::SizeChangedEventArgs const& e);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        void TextBoxTextChanged(winrt::Windows::Foundation::IInspectable const& sender, winrt::Windows::UI::Xaml::RoutedEventArgs const& e);[m[41m[m
[32m+[m[32m        void TextBoxKeyDown(const winrt::Windows::Foundation::IInspectable& /*sender*/, const winrt::Windows::UI::Xaml::Input::KeyRoutedEventArgs& e);[m[41m[m
[32m+[m[32m        WINRT_CALLBACK(Search, FuzzySearchHandler);[m[41m[m
[32m+[m[32m        TYPED_EVENT(Closed, Control::FuzzySearchBoxControl, Windows::UI::Xaml::RoutedEventArgs);[m[41m[m
[32m+[m[32m        TYPED_EVENT(SelectionChanged, Control::FuzzySearchBoxControl, winrt::Microsoft::Terminal::Control::FuzzySearchTextLine);[m[41m[m
[32m+[m[32m        TYPED_EVENT(OnReturn, Control::FuzzySearchBoxControl, winrt::Microsoft::Terminal::Control::FuzzySearchTextLine);[m[41m[m
[32m+[m[32m        TYPED_EVENT(PreviewSwapChainPanelSizeChanged, Control::FuzzySearchBoxControl, winrt::Windows::UI::Xaml::SizeChangedEventArgs);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        private:[m[41m[m
[32m+[m[32m        til::point _toPosInDips(const Core::Point terminalCellPos);[m[41m[m
[32m+[m[32m        std::unordered_set<winrt::Windows::Foundation::IInspectable> _focusableElements;[m[41m[m
[32m+[m[32m        til::size _fontSize;[m[41m[m
[32m+[m[32m    };[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mnamespace winrt::Microsoft::Terminal::Control::factory_implementation[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    BASIC_FACTORY(FuzzySearchBoxControl);[m[41m[m
[32m+[m[32m}[m[41m[m
[1mdiff --git a/src/cascadia/TerminalControl/FuzzySearchBoxControl.idl b/src/cascadia/TerminalControl/FuzzySearchBoxControl.idl[m
[1mnew file mode 100644[m
[1mindex 000000000..9f138b92b[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/FuzzySearchBoxControl.idl[m
[36m@@ -0,0 +1,31 @@[m
[32m+[m[32m// Copyright (c) Microsoft Corporation.[m[41m[m
[32m+[m[32m// Licensed under the MIT license.[m[41m[m
[32m+[m[41m[m
[32m+[m[32mimport "FuzzySearchTextSegment.idl";[m[41m[m
[32m+[m[41m[m
[32m+[m[32mnamespace Microsoft.Terminal.Control[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    delegate void FuzzySearchHandler(String query, Boolean goForward, Boolean isCaseSensitive);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    [default_interface] runtimeclass FuzzySearchBoxControl : Windows.UI.Xaml.Controls.UserControl[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        FuzzySearchBoxControl();[m[41m[m
[32m+[m[32m        void SetFocusOnTextbox();[m[41m[m
[32m+[m[32m        void SelectFirstItem();[m[41m[m
[32m+[m[32m        void SearchString(String searchString);[m[41m[m
[32m+[m[32m        event FuzzySearchHandler Search;[m[41m[m
[32m+[m[32m        Boolean ContainsFocus();[m[41m[m
[32m+[m[32m        Double PreviewActualHeight();[m[41m[m
[32m+[m[32m        Double PreviewActualWidth();[m[41m[m
[32m+[m[32m        Single PreviewCompositionScaleX();[m[41m[m
[32m+[m[32m        IObservableVector<FuzzySearchTextLine> ItemsSource[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            get;[m[41m[m
[32m+[m[32m            set;[m[41m[m
[32m+[m[32m        };[m[41m[m
[32m+[m[32m        event Windows.Foundation.TypedEventHandler<FuzzySearchBoxControl, Windows.UI.Xaml.RoutedEventArgs> Closed;[m[41m[m
[32m+[m[32m        event Windows.Foundation.TypedEventHandler<FuzzySearchBoxControl, FuzzySearchTextLine> SelectionChanged;[m[41m[m
[32m+[m[32m        event Windows.Foundation.TypedEventHandler<FuzzySearchBoxControl, FuzzySearchTextLine> OnReturn;[m[41m[m
[32m+[m[32m        event Windows.Foundation.TypedEventHandler<FuzzySearchBoxControl, Windows.UI.Xaml.SizeChangedEventArgs> PreviewSwapChainPanelSizeChanged;[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[32m}[m[41m[m
[1mdiff --git a/src/cascadia/TerminalControl/FuzzySearchBoxControl.xaml b/src/cascadia/TerminalControl/FuzzySearchBoxControl.xaml[m
[1mnew file mode 100644[m
[1mindex 000000000..f62db20ad[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/FuzzySearchBoxControl.xaml[m
[36m@@ -0,0 +1,80 @@[m
[32m+[m[32m<UserControl x:Class="Microsoft.Terminal.Control.FuzzySearchBoxControl"[m[41m[m
[32m+[m[32m             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"[m[41m[m
[32m+[m[32m             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"[m[41m[m
[32m+[m[32m             xmlns:d="http://schemas.microsoft.com/expression/blend/2008"[m[41m[m
[32m+[m[32m             xmlns:local="using:Microsoft.Terminal.Control"[m[41m[m
[32m+[m[32m             xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"[m[41m[m
[32m+[m[32m             x:Name="Root"[m[41m[m
[32m+[m[32m             HorizontalAlignment="Stretch"[m[41m[m
[32m+[m[32m             VerticalAlignment="Stretch"[m[41m[m
[32m+[m[32m             d:DesignHeight="55"[m[41m[m
[32m+[m[32m             d:DesignWidth="285"[m[41m[m
[32m+[m[32m             Opacity="1"[m[41m[m
[32m+[m[32m             TabNavigation="Cycle"[m[41m[m
[32m+[m[32m             mc:Ignorable="d">[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    <UserControl.Resources>[m[41m[m
[32m+[m[32m        <Style x:Key="FuzzySearchTextBoxStyle" TargetType="TextBox">[m[41m[m
[32m+[m[32m            <Setter Property="BorderThickness" Value="0"/>[m[41m[m
[32m+[m[32m        </Style>[m[41m[m
[32m+[m[32m        <Style x:Key="FuzzySearchBorder" TargetType="Border">[m[41m[m
[32m+[m[32m            <Setter Property="BorderThickness" Value="2"/>[m[41m[m
[32m+[m[32m            <Setter Property="BorderBrush" Value="#665c54"/>[m[41m[m
[32m+[m[32m            <Setter Property="CornerRadius" Value="4"/>[m[41m[m
[32m+[m[32m            <Setter Property="Margin" Value="0,0,0,8" />[m[41m[m
[32m+[m[32m        </Style>[m[41m[m
[32m+[m[32m    </UserControl.Resources>[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    <Grid Margin="8" Padding="4,8" Background="{Binding Background, ElementName=Root}">[m[41m[m
[32m+[m[32m        <Grid.RowDefinitions>[m[41m[m
[32m+[m[32m            <RowDefinition Height="1*"/>[m[41m[m
[32m+[m[32m            <RowDefinition Height="1*"/>[m[41m[m
[32m+[m[32m            <RowDefinition Height="Auto"/>[m[41m[m
[32m+[m[32m        </Grid.RowDefinitions>[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        <Border Style="{StaticResource FuzzySearchBorder}" Grid.Row="0">[m[41m[m
[32m+[m[32m            <SwapChainPanel x:Name="FuzzySearchSwapChainPanel"  HorizontalAlignment="Stretch" VerticalAlignment="Stretch">[m[41m[m
[32m+[m[32m            </SwapChainPanel>[m[41m[m
[32m+[m[32m        </Border>[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        <Border Style="{StaticResource FuzzySearchBorder}" Grid.Row="1">[m[41m[m
[32m+[m[32m            <ListBox[m[41m[m
[32m+[m[32m            ItemsSource="{x:Bind ItemsSource, Mode=OneWay}"[m[41m[m
[32m+[m[32m            x:Name="ListBox"[m[41m       [m
[32m+[m[32m            SelectionChanged="OnListBoxSelectionChanged"[m[41m[m
[32m+[m[32m                BorderBrush="#32302F"[m[41m[m
[32m+[m[32m                BorderThickness="3"[m[41m[m
[32m+[m[32m                VerticalAlignment="Stretch">[m[41m[m
[32m+[m[32m                <ListBox.ItemTemplate>[m[41m[m
[32m+[m[32m                    <DataTemplate x:DataType="local:FuzzySearchTextLine">[m[41m[m
[32m+[m[32m                        <local:FuzzySearchTextControl Text="{x:Bind}" HorizontalAlignment="Stretch"/>[m[41m[m
[32m+[m[32m                    </DataTemplate>[m[41m[m
[32m+[m[32m                </ListBox.ItemTemplate>[m[41m[m
[32m+[m[32m            </ListBox>[m[41m[m
[32m+[m[32m        </Border>[m[41m[m
[32m+[m[32m        <Border Style="{StaticResource FuzzySearchBorder}"  Grid.Row="2">[m[41m[m
[32m+[m[32m            <Grid>[m[41m[m
[32m+[m[32m                <Grid.ColumnDefinitions>[m[41m[m
[32m+[m[32m                    <ColumnDefinition Width="*" />[m[41m[m
[32m+[m[32m                    <ColumnDefinition Width="auto" />[m[41m[m
[32m+[m[32m                </Grid.ColumnDefinitions>[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                <TextBox x:Name="FuzzySearchTextBox"[m[41m[m
[32m+[m[32m                         Style="{StaticResource FuzzySearchTextBoxStyle}"[m[41m[m
[32m+[m[32m                         IsSpellCheckEnabled="False"[m[41m[m
[32m+[m[32m                         KeyDown="TextBoxKeyDown"[m[41m[m
[32m+[m[32m                         HorizontalAlignment="Stretch"[m[41m[m
[32m+[m[32m                         TextChanged="TextBoxTextChanged"[m[41m[m
[32m+[m[32m                         Grid.Column="0"/>[m[41m[m
[32m+[m[32m                <TextBlock x:Name="StatusBox"[m[41m[m
[32m+[m[32m                           MinWidth="70"[m[41m[m
[32m+[m[32m                           Grid.Column="1"[m[41m[m
[32m+[m[32m                           x:Uid="SearchBox_StatusBox"[m[41m[m
[32m+[m[32m                           HorizontalAlignment="Right"[m[41m[m
[32m+[m[32m                           TextAlignment="Center"[m[41m[m
[32m+[m[32m                           Margin="10,0,10,0"[m[41m[m
[32m+[m[32m                           VerticalAlignment="Center"/>[m[41m[m
[32m+[m[32m            </Grid>[m[41m[m
[32m+[m[32m        </Border>[m[41m[m
[32m+[m[32m    </Grid>[m[41m[m
[32m+[m[32m</UserControl>[m[41m[m
[1mdiff --git a/src/cascadia/TerminalControl/FuzzySearchTextControl.cpp b/src/cascadia/TerminalControl/FuzzySearchTextControl.cpp[m
[1mnew file mode 100644[m
[1mindex 000000000..67d6254a9[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/FuzzySearchTextControl.cpp[m
[36m@@ -0,0 +1,102 @@[m
[32m+[m[32m// Copyright (c) Microsoft Corporation.[m[41m[m
[32m+[m[32m// Licensed under the MIT license.[m[41m[m
[32m+[m[41m[m
[32m+[m[32m#include "pch.h"[m[41m[m
[32m+[m[32m#include "winrt/Windows.UI.Xaml.Interop.h"[m[41m[m
[32m+[m[32m#include "FuzzySearchTextControl.h"[m[41m[m
[32m+[m[41m[m
[32m+[m[32m#include "FuzzySearchTextControl.g.cpp"[m[41m[m
[32m+[m[41m[m
[32m+[m[32musing namespace winrt;[m[41m[m
[32m+[m[32musing namespace winrt::Windows::UI::Core;[m[41m[m
[32m+[m[32musing namespace winrt::Windows::UI::Xaml;[m[41m[m
[32m+[m[32musing namespace winrt::Windows::System;[m[41m[m
[32m+[m[32musing namespace winrt::Windows::UI::Text;[m[41m[m
[32m+[m[32musing namespace winrt::Windows::Foundation;[m[41m[m
[32m+[m[32musing namespace winrt::Windows::Foundation::Collections;[m[41m[m
[32m+[m[41m[m
[32m+[m[32mnamespace winrt::Microsoft::Terminal::Control::implementation[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    // Our control exposes a "Text" property to be used with Data Binding[m[41m[m
[32m+[m[32m    // To allow this we need to register a Dependency Property Identifier to be used by the property system[m[41m[m
[32m+[m[32m    // (https://docs.microsoft.com/en-us/windows/uwp/xaml-platform/custom-dependency-properties)[m[41m[m
[32m+[m[32m    DependencyProperty FuzzySearchTextControl::_textProperty = DependencyProperty::Register([m[41m[m
[32m+[m[32m        L"Text",[m[41m[m
[32m+[m[32m        xaml_typename<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>(),[m[41m[m
[32m+[m[32m        xaml_typename<winrt::Microsoft::Terminal::Control::FuzzySearchTextControl>(),[m[41m[m
[32m+[m[32m        PropertyMetadata(nullptr, FuzzySearchTextControl::_onTextChanged));[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    FuzzySearchTextControl::FuzzySearchTextControl()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        InitializeComponent();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    // Method Description:[m[41m[m
[32m+[m[32m    // - Returns the Identifier of the "Text" dependency property[m[41m[m
[32m+[m[32m    DependencyProperty FuzzySearchTextControl::TextProperty()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        return _textProperty;[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    // Method Description:[m[41m[m
[32m+[m[32m    // - Returns the TextBlock view used to render the highlighted text[m[41m[m
[32m+[m[32m    // Can be used when the Text property change is triggered by the event system to update the view[m[41m[m
[32m+[m[32m    // We need to expose it rather than simply bind a data source because we update the runs in code-behind[m[41m[m
[32m+[m[32m    Controls::TextBlock FuzzySearchTextControl::TextView()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        return _textView();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    winrt::Microsoft::Terminal::Control::FuzzySearchTextLine FuzzySearchTextControl::Text()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        return winrt::unbox_value<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>(GetValue(_textProperty));[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void FuzzySearchTextControl::Text(const winrt::Microsoft::Terminal::Control::FuzzySearchTextLine& value)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        SetValue(_textProperty, winrt::box_value(value));[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    // Method Description:[m[41m[m
[32m+[m[32m    // - This callback is triggered when the Text property is changed. Responsible for updating the view[m[41m[m
[32m+[m[32m    // Arguments:[m[41m[m
[32m+[m[32m    // - o - dependency object that was modified, expected to be an instance of this control[m[41m[m
[32m+[m[32m    // - e - event arguments of the property changed event fired by the event system upon Text property change.[m[41m[m
[32m+[m[32m    // The new value is expected to be an instance of HighlightedText[m[41m[m
[32m+[m[32m    void FuzzySearchTextControl::_onTextChanged(const DependencyObject& o, const DependencyPropertyChangedEventArgs& e)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        const auto control = o.try_as<winrt::Microsoft::Terminal::Control::FuzzySearchTextControl>();[m[41m[m
[32m+[m[32m        const auto highlightedText = e.NewValue().try_as<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        if (control && highlightedText)[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            // Replace all the runs on the TextBlock[m[41m[m
[32m+[m[32m            // Use IsHighlighted to decide if the run should be highlighted.[m[41m[m
[32m+[m[32m            // To do - export the highlighting style into XAML[m[41m[m
[32m+[m[32m            const auto inlinesCollection = control.TextView().Inlines();[m[41m[m
[32m+[m[32m            inlinesCollection.Clear();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m            for (const auto& match : highlightedText.Segments())[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                const auto matchText = match.TextSegment();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                Documents::Run run;[m[41m[m
[32m+[m[32m                run.Text(matchText);[m[41m[m
[32m+[m[41m                [m
[32m+[m[32m                if (match.IsHighlighted())[m[41m[m
[32m+[m[32m                {[m[41m[m
[32m+[m[32m                    Windows::UI::Xaml::Media::SolidColorBrush foregroundBrush;[m[41m[m
[32m+[m[32m                    foregroundBrush.Color(Windows::UI::Colors::OrangeRed());[m[41m[m
[32m+[m[32m                    run.Foreground(foregroundBrush);[m[41m[m
[32m+[m[32m                    run.FontWeight(FontWeights::Bold());[m[41m[m
[32m+[m[32m                }[m[41m[m
[32m+[m[32m                else[m[41m[m
[32m+[m[32m                {[m[41m[m
[32m+[m[32m                    run.Foreground(control.Foreground());[m[41m[m
[32m+[m[32m                }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m                inlinesCollection.Append(run);[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[32m}[m[41m[m
[1mdiff --git a/src/cascadia/TerminalControl/FuzzySearchTextControl.h b/src/cascadia/TerminalControl/FuzzySearchTextControl.h[m
[1mnew file mode 100644[m
[1mindex 000000000..b8c46c636[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/FuzzySearchTextControl.h[m
[36m@@ -0,0 +1,30 @@[m
[32m+[m[32m#pragma once[m[41m[m
[32m+[m[41m[m
[32m+[m[32m#include "winrt/Microsoft.UI.Xaml.Controls.h"[m[41m[m
[32m+[m[41m[m
[32m+[m[32m#include "FuzzySearchTextSegment.g.h"[m[41m[m
[32m+[m[32m#include "FuzzySearchTextControl.g.h"[m[41m[m
[32m+[m[41m[m
[32m+[m[32mnamespace winrt::Microsoft::Terminal::Control::implementation[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    struct FuzzySearchTextControl : FuzzySearchTextControlT<FuzzySearchTextControl>[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        FuzzySearchTextControl();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        static Windows::UI::Xaml::DependencyProperty TextProperty();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        winrt::Microsoft::Terminal::Control::FuzzySearchTextLine Text();[m[41m[m
[32m+[m[32m        void Text(const winrt::Microsoft::Terminal::Control::FuzzySearchTextLine& value);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        Windows::UI::Xaml::Controls::TextBlock TextView();[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    private:[m[41m[m
[32m+[m[32m        static Windows::UI::Xaml::DependencyProperty _textProperty;[m[41m[m
[32m+[m[32m        static void _onTextChanged(const Windows::UI::Xaml::DependencyObject& o, const Windows::UI::Xaml::DependencyPropertyChangedEventArgs& e);[m[41m[m
[32m+[m[32m    };[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mnamespace winrt::Microsoft::Terminal::Control::factory_implementation[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    BASIC_FACTORY(FuzzySearchTextControl);[m[41m[m
[32m+[m[32m}[m[41m[m
[1mdiff --git a/src/cascadia/TerminalControl/FuzzySearchTextControl.idl b/src/cascadia/TerminalControl/FuzzySearchTextControl.idl[m
[1mnew file mode 100644[m
[1mindex 000000000..8a7221009[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/FuzzySearchTextControl.idl[m
[36m@@ -0,0 +1,15 @@[m
[32m+[m[32m// Copyright (c) Microsoft Corporation.[m[41m[m
[32m+[m[32m// Licensed under the MIT license.[m[41m[m
[32m+[m[41m[m
[32m+[m[32mimport "FuzzySearchTextSegment.idl";[m[41m[m
[32m+[m[41m[m
[32m+[m[32mnamespace Microsoft.Terminal.Control[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    [default_interface] runtimeclass FuzzySearchTextControl : Windows.UI.Xaml.Controls.Control[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        FuzzySearchTextControl();[m[41m[m
[32m+[m[32m        Windows.UI.Xaml.DependencyProperty TextProperty { get; };[m[41m[m
[32m+[m[32m        FuzzySearchTextLine Text;[m[41m[m
[32m+[m[32m        Windows.UI.Xaml.Controls.TextBlock TextView { get; };[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[32m}[m[41m[m
[1mdiff --git a/src/cascadia/TerminalControl/FuzzySearchTextControl.xaml b/src/cascadia/TerminalControl/FuzzySearchTextControl.xaml[m
[1mnew file mode 100644[m
[1mindex 000000000..ab4317c44[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/FuzzySearchTextControl.xaml[m
[36m@@ -0,0 +1,12 @@[m
[32m+[m[32m<UserControl x:Class="Microsoft.Terminal.Control.FuzzySearchTextControl"[m[41m[m
[32m+[m[32m             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"[m[41m[m
[32m+[m[32m             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"[m[41m[m
[32m+[m[32m             xmlns:d="http://schemas.microsoft.com/expression/blend/2008"[m[41m[m
[32m+[m[32m             xmlns:local="using:Microsoft.Terminal.Control"[m[41m[m
[32m+[m[32m             xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"[m[41m[m
[32m+[m[32m             Background="Transparent"[m[41m[m
[32m+[m[32m             mc:Ignorable="d">[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    <TextBlock x:Name="_textView" HorizontalAlignment="Stretch" TextWrapping="Wrap" />[m[41m[m
[32m+[m[32m</UserControl>[m[41m[m
[32m+[m[41m[m
[1mdiff --git a/src/cascadia/TerminalControl/FuzzySearchTextSegment.cpp b/src/cascadia/TerminalControl/FuzzySearchTextSegment.cpp[m
[1mnew file mode 100644[m
[1mindex 000000000..de8067c52[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/FuzzySearchTextSegment.cpp[m
[36m@@ -0,0 +1,37 @@[m
[32m+[m[32m#include "pch.h"[m
[32m+[m
[32m+[m[32m#include "FuzzySearchTextSegment.h"[m
[32m+[m[32m#include "FuzzySearchTextSegment.g.cpp"[m
[32m+[m[32m#include "FuzzySearchTextLine.g.cpp"[m
[32m+[m[32m#include "FuzzySearchResult.g.cpp"[m
[32m+[m
[32m+[m[32musing namespace winrt::Windows::Foundation;[m
[32m+[m
[32m+[m[32mnamespace winrt::Microsoft::Terminal::Control::implementation[m
[32m+[m[32m{[m
[32m+[m[32m    FuzzySearchTextSegment::FuzzySearchTextSegment()[m
[32m+[m[32m    {[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    FuzzySearchTextSegment::FuzzySearchTextSegment(const winrt::hstring& textSegment, bool isHighlighted) :[m
[32m+[m[32m        _TextSegment(textSegment),[m
[32m+[m[32m        _IsHighlighted(isHighlighted)[m
[32m+[m[32m    {[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    FuzzySearchTextLine::FuzzySearchTextLine(const Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextSegment>& segments, int32_t score, int32_t row, int32_t firstPosition, int32_t length) :[m
[32m+[m[32m        _Segments(segments),[m
[32m+[m[32m        _Score(score),[m
[32m+[m[32m        _Row(row),[m
[32m+[m[32m        _FirstPosition(firstPosition),[m
[32m+[m[32m        _Length(length)[m
[32m+[m[32m    {[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    FuzzySearchResult::FuzzySearchResult(const Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>& results, int32_t totalRowsSearched, int32_t numberOfResults) :[m
[32m+[m[32m        _Results(results),[m
[32m+[m[32m        _TotalRowsSearched(totalRowsSearched),[m
[32m+[m[32m        _NumberOfResults(numberOfResults)[m
[32m+[m[32m    {[m
[32m+[m[32m    }[m
[32m+[m[32m}[m
[1mdiff --git a/src/cascadia/TerminalControl/FuzzySearchTextSegment.h b/src/cascadia/TerminalControl/FuzzySearchTextSegment.h[m
[1mnew file mode 100644[m
[1mindex 000000000..4a10f392e[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/FuzzySearchTextSegment.h[m
[36m@@ -0,0 +1,49 @@[m
[32m+[m[32m#pragma once[m[41m[m
[32m+[m[41m[m
[32m+[m[32m#include <winrt/Windows.Foundation.h>[m[41m[m
[32m+[m[32m#include "FuzzySearchTextSegment.g.h"[m[41m[m
[32m+[m[32m#include "FuzzySearchTextLine.g.h"[m[41m[m
[32m+[m[32m#include "FuzzySearchResult.g.h"[m[41m[m
[32m+[m[41m[m
[32m+[m[32mnamespace winrt::Microsoft::Terminal::Control::implementation[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    struct FuzzySearchTextSegment : FuzzySearchTextSegmentT<FuzzySearchTextSegment>[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        FuzzySearchTextSegment();[m[41m[m
[32m+[m[32m        FuzzySearchTextSegment(const winrt::hstring& textSegment, bool isHighlighted);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        WINRT_CALLBACK(PropertyChanged, Windows::UI::Xaml::Data::PropertyChangedEventHandler);[m[41m[m
[32m+[m[32m        WINRT_OBSERVABLE_PROPERTY(winrt::hstring, TextSegment, _PropertyChangedHandlers);[m[41m[m
[32m+[m[32m        WINRT_OBSERVABLE_PROPERTY(bool, IsHighlighted, _PropertyChangedHandlers);[m[41m[m
[32m+[m[32m    };[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    struct FuzzySearchTextLine : FuzzySearchTextLineT<FuzzySearchTextLine>[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        FuzzySearchTextLine() = default;[m[41m[m
[32m+[m[32m        FuzzySearchTextLine(const Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextSegment>& segments, int32_t score, int32_t row, int32_t firstPosition, int32_t length);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        WINRT_CALLBACK(PropertyChanged, Windows::UI::Xaml::Data::PropertyChangedEventHandler);[m[41m[m
[32m+[m[32m        WINRT_OBSERVABLE_PROPERTY(Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextSegment>, Segments, _PropertyChangedHandlers);[m[41m[m
[32m+[m[32m        WINRT_OBSERVABLE_PROPERTY(int32_t, Score, _PropertyChangedHandlers);[m[41m[m
[32m+[m[32m        WINRT_OBSERVABLE_PROPERTY(int32_t, Row, _PropertyChangedHandlers);[m[41m[m
[32m+[m[32m        WINRT_OBSERVABLE_PROPERTY(int32_t, FirstPosition, _PropertyChangedHandlers);[m[41m[m
[32m+[m[32m        WINRT_OBSERVABLE_PROPERTY(int32_t, Length, _PropertyChangedHandlers);[m[41m[m
[32m+[m[32m    };[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    struct FuzzySearchResult : FuzzySearchResultT<FuzzySearchResult>[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        FuzzySearchResult() = default;[m[41m[m
[32m+[m[32m        FuzzySearchResult(const Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>& results, int32_t totalRowsSearched, int32_t numberOfResults);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        WINRT_PROPERTY(Windows::Foundation::Collections::IVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>, Results);[m[41m[m
[32m+[m[32m        WINRT_PROPERTY(int32_t, TotalRowsSearched);[m[41m[m
[32m+[m[32m        WINRT_PROPERTY(int32_t, NumberOfResults);[m[41m[m
[32m+[m[32m    };[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mnamespace winrt::Microsoft::Terminal::Control::factory_implementation[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    BASIC_FACTORY(FuzzySearchTextSegment);[m[41m[m
[32m+[m[32m    BASIC_FACTORY(FuzzySearchTextLine);[m[41m[m
[32m+[m[32m    BASIC_FACTORY(FuzzySearchResult);[m[41m[m
[32m+[m[32m}[m[41m[m
[1mdiff --git a/src/cascadia/TerminalControl/FuzzySearchTextSegment.idl b/src/cascadia/TerminalControl/FuzzySearchTextSegment.idl[m
[1mnew file mode 100644[m
[1mindex 000000000..8d51881e3[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/FuzzySearchTextSegment.idl[m
[36m@@ -0,0 +1,33 @@[m
[32m+[m[32mnamespace Microsoft.Terminal.Control[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    [default_interface] runtimeclass FuzzySearchTextSegment : Windows.UI.Xaml.Data.INotifyPropertyChanged[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        FuzzySearchTextSegment();[m[41m[m
[32m+[m[32m        FuzzySearchTextSegment(String text, Boolean isHighlighted);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        String TextSegment { get; };[m[41m[m
[32m+[m[32m        Boolean IsHighlighted { get; };[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    [default_interface] runtimeclass FuzzySearchTextLine : Windows.UI.Xaml.Data.INotifyPropertyChanged[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        FuzzySearchTextLine();[m[41m[m
[32m+[m[32m        FuzzySearchTextLine(Windows.Foundation.Collections.IObservableVector<FuzzySearchTextSegment> segments, Int32 score, Int32 row, Int32 firstPosition, Int32 length);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        Windows.Foundation.Collections.IObservableVector<FuzzySearchTextSegment> Segments;[m[41m[m
[32m+[m[32m        Int32 Score { get; };[m[41m[m
[32m+[m[32m        Int32 Row { get; };[m[41m[m
[32m+[m[32m        Int32 FirstPosition { get; set; };[m[41m[m
[32m+[m[32m        Int32 Length { get; set; };[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    runtimeclass FuzzySearchResult[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        FuzzySearchResult();[m[41m[m
[32m+[m[32m        FuzzySearchResult(Windows.Foundation.Collections.IObservableVector<FuzzySearchTextLine> results, Int32 totalRowsSearched, Int32 numberOfResults);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        Windows.Foundation.Collections.IVector<FuzzySearchTextLine> Results;[m[41m[m
[32m+[m[32m        Int32 TotalRowsSearched { get; set; };[m[41m[m
[32m+[m[32m        Int32 NumberOfResults { get; set; };[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[32m}[m[41m[m
[1mdiff --git a/src/cascadia/TerminalControl/TermControl.cpp b/src/cascadia/TerminalControl/TermControl.cpp[m
[1mindex 4c59d027a..f4971632a 100644[m
[1m--- a/src/cascadia/TerminalControl/TermControl.cpp[m
[1m+++ b/src/cascadia/TerminalControl/TermControl.cpp[m
[36m@@ -65,6 +65,8 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
     {[m
         InitializeComponent();[m
 [m
[32m+[m[32m        _fuzzySearchResults = winrt::single_threaded_observable_vector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine>();[m[41m[m
[32m+[m[41m[m
         _core = _interactivity.Core();[m
 [m
         // This event is specifically triggered by the renderer thread, a BG thread. Use a weak ref here.[m
[36m@@ -106,6 +108,7 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
         _revokers.RestartTerminalRequested = _core.RestartTerminalRequested(winrt::auto_revoke, { get_weak(), &TermControl::_bubbleRestartTerminalRequested });[m
 [m
         _revokers.PasteFromClipboard = _interactivity.PasteFromClipboard(winrt::auto_revoke, { get_weak(), &TermControl::_bubblePasteFromClipboard });[m
[32m+[m[32m        _revokers.FuzzySearchSwapChainChanged = _core.FuzzySearchSwapChainChanged(winrt::auto_revoke, { get_weak(), &TermControl::FuzzySearchRenderEngineSwapChainChanged });[m[41m[m
 [m
         // Initialize the terminal only once the swapchainpanel is loaded - that[m
         //      way, we'll be able to query the real pixel size it got on layout[m
[36m@@ -478,6 +481,82 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
         _core.Search(text, goForward, caseSensitive);[m
     }[m
 [m
[32m+[m[32m    Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine> TermControl::FuzzySearchResults()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        return _fuzzySearchResults;[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void TermControl::_FuzzySearch(const winrt::hstring& text, const bool /*goForward*/, const bool /*caseSensitive*/)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        auto fuzzySearchResult = _core.FuzzySearch(text);[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        _fuzzySearchResults.Clear();[m[41m[m
[32m+[m[32m        for (auto result : fuzzySearchResult.Results())[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            _fuzzySearchResults.Append(result);[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        _fuzzySearchBox->SetStatus(fuzzySearchResult.TotalRowsSearched(), fuzzySearchResult.NumberOfResults());[m[41m[m
[32m+[m[32m        FuzzySearchBox().SelectFirstItem();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void TermControl::FuzzySearch_OnSelection(Control::FuzzySearchBoxControl const& /*sender*/, winrt::Microsoft::Terminal::Control::FuzzySearchTextLine const& args)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        _fuzzySearchBox->Visibility(Visibility::Collapsed);[m[41m[m
[32m+[m[32m        _core.SelectChar(args.Row(), args.FirstPosition());[m[41m[m
[32m+[m[32m        _core.ExitFuzzySearchMode();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void TermControl::FuzzySearch_SelectionChanged(Control::FuzzySearchBoxControl const& /*sender*/, winrt::Microsoft::Terminal::Control::FuzzySearchTextLine const& args)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        auto row = args.Row();[m[41m[m
[32m+[m[32m        _core.FuzzySearchSelectionChanged(row);[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void TermControl::_FuzzySearchPreviewSwapChainSizeChanged(const Windows::Foundation::IInspectable& /*sender*/, const Windows::UI::Xaml::SizeChangedEventArgs& e)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        _core.FuzzySearchPreviewSizeChanged(e.NewSize().Width, e.NewSize().Height);[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void TermControl::_CloseFuzzySearchBoxControl(const winrt::Windows::Foundation::IInspectable& /*sender*/,[m[41m[m
[32m+[m[32m                                             const RoutedEventArgs& /*args*/)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        _fuzzySearchBox->Visibility(Visibility::Collapsed);[m[41m[m
[32m+[m[32m        this->Focus(FocusState::Programmatic);[m[41m[m
[32m+[m[32m        _core.ExitFuzzySearchMode();[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void TermControl::FuzzySearchRenderEngineSwapChainChanged(IInspectable /*sender*/, IInspectable args)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        // This event comes in on the UI thread[m[41m[m
[32m+[m[32m        HANDLE h = reinterpret_cast<HANDLE>(winrt::unbox_value<uint64_t>(args));[m[41m[m
[32m+[m[32m        _AttachDxgiFuzzySearchSwapChainToXaml(h);[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void TermControl::_AttachDxgiFuzzySearchSwapChainToXaml(HANDLE swapChainHandle)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        _fuzzySearchBox->SetSwapChainHandle(swapChainHandle);[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    void TermControl::CreateFuzzySearchBoxControl()[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        // Lazy load the search box control.[m[41m[m
[32m+[m[32m        if (auto loadedSearchBox{ FindName(L"FuzzySearchBox") })[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            if (auto searchBox{ loadedSearchBox.try_as<::winrt::Microsoft::Terminal::Control::FuzzySearchBoxControl>() })[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                // get at its private implementation[m[41m[m
[32m+[m[32m                _fuzzySearchBox.copy_from(winrt::get_self<::winrt::Microsoft::Terminal::Control::implementation::FuzzySearchBoxControl>(searchBox));[m[41m[m
[32m+[m[32m                _fuzzySearchBox->FuzzySearchTextBox().Text(L"");[m[41m[m
[32m+[m[32m                _fuzzySearchBox->Visibility(Visibility::Visible);[m[41m[m
[32m+[m[32m                _fuzzySearchBox->SetStatus(0, 0);[m[41m[m
[32m+[m[32m                _fuzzySearchBox->SetFocusOnTextbox();[m[41m[m
[32m+[m[32m                _core.CursorOn(false);[m[41m[m
[32m+[m[32m                _core.EnterFuzzySearchMode();[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
     // Method Description:[m
     // - The handler for the "search criteria changed" event. Clears selection and initiates a new search.[m
     // Arguments:[m
[36m@@ -875,6 +954,7 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
         _PropertyChangedHandlers(*this, Data::PropertyChangedEventArgs{ L"BackgroundBrush" });[m
 [m
         _isBackgroundLight = _isColorLight(bg);[m
[32m+[m[32m        FuzzySearchBox().Background(_BackgroundBrush);[m[41m[m
     }[m
 [m
     bool TermControl::_isColorLight(til::color bg) noexcept[m
[36m@@ -1065,6 +1145,13 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
             {[m
                 return false;[m
             }[m
[32m+[m[41m[m
[32m+[m[32m            const auto fuzzyPreviewInitalized = _core.InitializeFuzzySearch(panelWidth, panelHeight, panelScaleX);[m[41m[m
[32m+[m[32m            if (!fuzzyPreviewInitalized)[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                return false;[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[41m[m
             _interactivity.Initialize();[m
         }[m
         else[m
[36m@@ -1298,6 +1385,12 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
             return;[m
         }[m
 [m
[32m+[m[32m        if (_fuzzySearchBox && _fuzzySearchBox->ContainsFocus())[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            return;[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[41m[m
[32m+[m[41m[m
         const auto keyStatus = e.KeyStatus();[m
         const auto vkey = gsl::narrow_cast<WORD>(e.OriginalKey());[m
         const auto scanCode = gsl::narrow_cast<WORD>(keyStatus.ScanCode);[m
[36m@@ -3400,6 +3493,17 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
         };[m
         scaleMarker(SelectionStartMarker());[m
         scaleMarker(SelectionEndMarker());[m
[32m+[m[41m[m
[32m+[m[32m        if (auto loadedSearchBox{ FindName(L"FuzzySearchBox") })[m[41m[m
[32m+[m[32m        {[m[41m[m
[32m+[m[32m            if (auto searchBox{ loadedSearchBox.try_as<::winrt::Microsoft::Terminal::Control::FuzzySearchBoxControl>() })[m[41m[m
[32m+[m[32m            {[m[41m[m
[32m+[m[32m                // get at its private implementation[m[41m[m
[32m+[m[32m                _fuzzySearchBox.copy_from(winrt::get_self<::winrt::Microsoft::Terminal::Control::implementation::FuzzySearchBoxControl>(searchBox));[m[41m[m
[32m+[m[32m            }[m[41m[m
[32m+[m[32m        }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m        _fuzzySearchBox->SetFontSize(til::size{ args.Width(), args.Height() });[m[41m[m
     }[m
 [m
     void TermControl::_coreRaisedNotice(const IInspectable& /*sender*/,[m
[1mdiff --git a/src/cascadia/TerminalControl/TermControl.h b/src/cascadia/TerminalControl/TermControl.h[m
[1mindex 441ca5f57..efaca8437 100644[m
[1m--- a/src/cascadia/TerminalControl/TermControl.h[m
[1m+++ b/src/cascadia/TerminalControl/TermControl.h[m
[36m@@ -15,6 +15,8 @@[m
 [m
 #include "ControlInteractivity.h"[m
 #include "ControlSettings.h"[m
[32m+[m[32m#include "FuzzySearchBoxControl.h"[m[41m[m
[32m+[m[32m#include "FuzzySearchTextSegment.h"[m[41m[m
 [m
 namespace Microsoft::Console::VirtualTerminal[m
 {[m
[36m@@ -56,6 +58,12 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
         void WindowVisibilityChanged(const bool showOrHide);[m
 [m
         void ColorSelection(Control::SelectionColor fg, Control::SelectionColor bg, Core::MatchMode matchMode);[m
[32m+[m[32m        Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine> FuzzySearchResults();[m[41m[m
[32m+[m[32m        void FuzzySearch_SelectionChanged(Control::FuzzySearchBoxControl const& sender, winrt::Microsoft::Terminal::Control::FuzzySearchTextLine const& args);[m[41m[m
[32m+[m[32m        void FuzzySearch_OnSelection(Control::FuzzySearchBoxControl const& sender, winrt::Microsoft::Terminal::Control::FuzzySearchTextLine const& args);[m[41m[m
[32m+[m[32m        void FuzzySearchRenderEngineSwapChainChanged(IInspectable sender, IInspectable args);[m[41m[m
[32m+[m[32m        void _AttachDxgiFuzzySearchSwapChainToXaml(HANDLE swapChainHandle);[m[41m[m
[32m+[m[32m        void _FuzzySearchPreviewSwapChainSizeChanged(const Windows::Foundation::IInspectable& /*sender*/, const Windows::UI::Xaml::SizeChangedEventArgs& e);[m[41m[m
 [m
 #pragma region ICoreState[m
         const uint64_t TaskbarState() const noexcept;[m
[36m@@ -111,6 +119,7 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
                                                 Control::RendererWarningArgs args);[m
 [m
         void CreateSearchBoxControl();[m
[32m+[m[32m        void CreateFuzzySearchBoxControl();[m[41m[m
 [m
         void SearchMatch(const bool goForward);[m
 [m
[36m@@ -213,6 +222,7 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
         Control::ControlCore _core{ nullptr };[m
 [m
         winrt::com_ptr<SearchBoxControl> _searchBox;[m
[32m+[m[32m        winrt::com_ptr<FuzzySearchBoxControl> _fuzzySearchBox;[m[41m[m
 [m
         bool _closing{ false };[m
         bool _focused{ false };[m
[36m@@ -259,6 +269,7 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
         Windows::Foundation::Collections::IObservableVector<Windows::UI::Xaml::Controls::ICommandBarElement> _originalSelectedSecondaryElements{ nullptr };[m
 [m
         Control::CursorDisplayState _cursorVisibility{ Control::CursorDisplayState::Default };[m
[32m+[m[32m        Windows::Foundation::Collections::IObservableVector<winrt::Microsoft::Terminal::Control::FuzzySearchTextLine> _fuzzySearchResults;[m[41m[m
 [m
         inline bool _IsClosing() const noexcept[m
         {[m
[36m@@ -346,9 +357,11 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
         double _GetAutoScrollSpeed(double cursorDistanceFromBorder) const;[m
 [m
         void _Search(const winrt::hstring& text, const bool goForward, const bool caseSensitive);[m
[32m+[m[32m        void _FuzzySearch(const winrt::hstring& text, const bool goForward, const bool caseSensitive);[m[41m[m
 [m
         void _SearchChanged(const winrt::hstring& text, const bool goForward, const bool caseSensitive);[m
         void _CloseSearchBoxControl(const winrt::Windows::Foundation::IInspectable& sender, const Windows::UI::Xaml::RoutedEventArgs& args);[m
[32m+[m[32m        void _CloseFuzzySearchBoxControl(const winrt::Windows::Foundation::IInspectable& sender, const Windows::UI::Xaml::RoutedEventArgs& args);[m[41m[m
 [m
         // TSFInputControl Handlers[m
         void _CompositionCompleted(winrt::hstring text);[m
[36m@@ -403,6 +416,7 @@[m [mnamespace winrt::Microsoft::Terminal::Control::implementation[m
             Control::ControlCore::CloseTerminalRequested_revoker CloseTerminalRequested;[m
             Control::ControlCore::CompletionsChanged_revoker CompletionsChanged;[m
             Control::ControlCore::RestartTerminalRequested_revoker RestartTerminalRequested;[m
[32m+[m[32m            Control::ControlCore::FuzzySearchSwapChainChanged_revoker FuzzySearchSwapChainChanged;[m[41m[m
 [m
             // These are set up in _InitializeTerminal[m
             Control::ControlCore::RendererWarning_revoker RendererWarning;[m
[1mdiff --git a/src/cascadia/TerminalControl/TermControl.idl b/src/cascadia/TerminalControl/TermControl.idl[m
[1mindex 667276900..ecab3931a 100644[m
[1m--- a/src/cascadia/TerminalControl/TermControl.idl[m
[1m+++ b/src/cascadia/TerminalControl/TermControl.idl[m
[36m@@ -8,6 +8,7 @@[m [mimport "IDirectKeyListener.idl";[m
 import "EventArgs.idl";[m
 import "ICoreState.idl";[m
 import "ControlCore.idl";[m
[32m+[m[32mimport "FuzzySearchTextSegment.idl";[m[41m[m
 [m
 namespace Microsoft.Terminal.Control[m
 {[m
[36m@@ -138,5 +139,8 @@[m [mnamespace Microsoft.Terminal.Control[m
         void ShowContextMenu();[m
 [m
         void Detach();[m
[32m+[m[41m[m
[32m+[m[32m        Windows.Foundation.Collections.IObservableVector<FuzzySearchTextLine> FuzzySearchResults { get; };[m[41m[m
[32m+[m[32m        void CreateFuzzySearchBoxControl();[m[41m[m
     }[m
 }[m
[1mdiff --git a/src/cascadia/TerminalControl/TermControl.xaml b/src/cascadia/TerminalControl/TermControl.xaml[m
[1mindex 57bc4fa93..7d7bbf3c6 100644[m
[1m--- a/src/cascadia/TerminalControl/TermControl.xaml[m
[1m+++ b/src/cascadia/TerminalControl/TermControl.xaml[m
[36m@@ -1358,6 +1358,20 @@[m
                 </StackPanel>[m
             </Border>[m
         </Grid>[m
[32m+[m[32m        <local:FuzzySearchBoxControl x:Name="FuzzySearchBox"[m[41m[m
[32m+[m[32m                                     Background="{Binding BackgroundBrush, Mode=OneWay}"[m[41m[m
[32m+[m[32m                                     Grid.Row="0"[m[41m[m
[32m+[m[32m                                     Margin="25,25,25,25"[m[41m[m
[32m+[m[32m                                     Search="_FuzzySearch"[m[41m[m
[32m+[m[32m                                     VerticalAlignment="Stretch"[m[41m[m
[32m+[m[32m                                     HorizontalAlignment="Stretch"[m[41m[m
[32m+[m[32m                                     Closed="_CloseFuzzySearchBoxControl"[m[41m[m
[32m+[m[32m                                     Visibility="Collapsed"[m[41m[m
[32m+[m[32m                                     SelectionChanged="FuzzySearch_SelectionChanged"[m[41m[m
[32m+[m[32m                                     OnReturn="FuzzySearch_OnSelection"[m[41m[m
[32m+[m[32m                                     PreviewSwapChainPanelSizeChanged="_FuzzySearchPreviewSwapChainSizeChanged"[m[41m[m
[32m+[m[32m                                     ItemsSource="{x:Bind FuzzySearchResults}"/>[m[41m[m
[32m+[m[41m[m
 [m
     </Grid>[m
 [m
[1mdiff --git a/src/cascadia/TerminalControl/TerminalControlLib.vcxproj b/src/cascadia/TerminalControl/TerminalControlLib.vcxproj[m
[1mindex 151fe3593..aa66e3aed 100644[m
[1m--- a/src/cascadia/TerminalControl/TerminalControlLib.vcxproj[m
[1m+++ b/src/cascadia/TerminalControl/TerminalControlLib.vcxproj[m
[36m@@ -9,7 +9,6 @@[m
     <ConfigurationType>StaticLibrary</ConfigurationType>[m
     <SubSystem>Console</SubSystem>[m
     <OpenConsoleUniversalApp>true</OpenConsoleUniversalApp>[m
[31m-[m
     <!-- C++/WinRT sets the depth to 1 if there is a XAML file in the project[m
          Unfortunately for us, we need it to be 3. When the namespace merging[m
          depth is 1, Microsoft.Terminal.Control becomes "Microsoft",[m
[36m@@ -20,20 +19,17 @@[m
     -->[m
     <CppWinRTNamespaceMergeDepth>3</CppWinRTNamespaceMergeDepth>[m
     <XamlComponentResourceLocation>nested</XamlComponentResourceLocation>[m
[31m-[m
   </PropertyGroup>[m
[31m-[m
   <PropertyGroup Label="NuGet Dependencies">[m
     <TerminalCppWinrt>true</TerminalCppWinrt>[m
     <TerminalMUX>true</TerminalMUX>[m
   </PropertyGroup>[m
[31m-[m
   <Import Project="..\..\..\common.openconsole.props" Condition="'$(OpenConsoleDir)'==''" />[m
   <Import Project="$(OpenConsoleDir)src\common.nugetversions.props" />[m
   <Import Project="$(OpenConsoleDir)src\cppwinrt.build.pre.props" />[m
[31m-  [m
   <!-- ========================= Headers ======================== -->[m
   <ItemGroup>[m
[32m+[m[32m    <ClInclude Include="fzf\fzf.h" />[m[41m[m
     <ClInclude Include="pch.h" />[m
     <ClInclude Include="ControlCore.h">[m
       <DependentUpon>ControlCore.idl</DependentUpon>[m
[36m@@ -53,6 +49,15 @@[m
     <ClInclude Include="SearchBoxControl.h">[m
       <DependentUpon>SearchBoxControl.xaml</DependentUpon>[m
     </ClInclude>[m
[32m+[m[32m    <ClInclude Include="FuzzySearchTextControl.h">[m[41m[m
[32m+[m[32m      <DependentUpon>FuzzySearchTextControl.xaml</DependentUpon>[m[41m[m
[32m+[m[32m    </ClInclude>[m[41m[m
[32m+[m[32m    <ClInclude Include="FuzzySearchTextSegment.h">[m[41m[m
[32m+[m[32m      <DependentUpon>FuzzySearchTextSegment.idl</DependentUpon>[m[41m[m
[32m+[m[32m    </ClInclude>[m[41m[m
[32m+[m[32m    <ClInclude Include="FuzzySearchBoxControl.h">[m[41m[m
[32m+[m[32m      <DependentUpon>FuzzySearchBoxControl.xaml</DependentUpon>[m[41m[m
[32m+[m[32m    </ClInclude>[m[41m[m
     <ClInclude Include="XamlLights.h">[m
       <DependentUpon>XamlLights.idl</DependentUpon>[m
     </ClInclude>[m
[36m@@ -74,6 +79,10 @@[m
   </ItemGroup>[m
   <!-- ========================= Cpp Files ======================== -->[m
   <ItemGroup>[m
[32m+[m[32m    <ClCompile Include="fzf\fzf.c">[m[41m[m
[32m+[m[32m      <PrecompiledHeader Condition="'$(Configuration)|$(Platform)'=='Debug|x64'">NotUsing</PrecompiledHeader>[m[41m[m
[32m+[m[32m      <PrecompiledHeader Condition="'$(Configuration)|$(Platform)'=='Release|x64'">NotUsing</PrecompiledHeader>[m[41m[m
[32m+[m[32m    </ClCompile>[m[41m[m
     <ClCompile Include="pch.cpp">[m
       <PrecompiledHeader>Create</PrecompiledHeader>[m
     </ClCompile>[m
[36m@@ -96,6 +105,15 @@[m
     <ClCompile Include="SearchBoxControl.cpp">[m
       <DependentUpon>SearchBoxControl.xaml</DependentUpon>[m
     </ClCompile>[m
[32m+[m[32m    <ClCompile Include="FuzzySearchTextControl.cpp">[m[41m[m
[32m+[m[32m      <DependentUpon>FuzzySearchTextControl.xaml</DependentUpon>[m[41m[m
[32m+[m[32m    </ClCompile>[m[41m[m
[32m+[m[32m    <ClCompile Include="FuzzySearchTextSegment.cpp">[m[41m[m
[32m+[m[32m      <DependentUpon>FuzzySearchTextSegment.idl</DependentUpon>[m[41m[m
[32m+[m[32m    </ClCompile>[m[41m[m
[32m+[m[32m    <ClCompile Include="FuzzySearchBoxControl.cpp">[m[41m[m
[32m+[m[32m      <DependentUpon>FuzzySearchBoxControl.xaml</DependentUpon>[m[41m[m
[32m+[m[32m    </ClCompile>[m[41m[m
     <ClCompile Include="XamlLights.cpp">[m
       <DependentUpon>XamlLights.idl</DependentUpon>[m
     </ClCompile>[m
[36m@@ -131,6 +149,14 @@[m
     <Midl Include="SearchBoxControl.idl">[m
       <DependentUpon>SearchBoxControl.xaml</DependentUpon>[m
     </Midl>[m
[32m+[m[32m    <Midl Include="FuzzySearchTextControl.idl">[m[41m[m
[32m+[m[32m      <DependentUpon>FuzzySearchTextControl.xaml</DependentUpon>[m[41m[m
[32m+[m[32m    </Midl>[m[41m[m
[32m+[m[32m    <Midl Include="FuzzySearchTextSegment.idl">[m[41m[m
[32m+[m[32m    </Midl>[m[41m[m
[32m+[m[32m    <Midl Include="FuzzySearchBoxControl.idl">[m[41m[m
[32m+[m[32m      <DependentUpon>FuzzySearchBoxControl.xaml</DependentUpon>[m[41m[m
[32m+[m[32m    </Midl>[m[41m[m
     <Midl Include="XamlLights.idl" />[m
     <Midl Include="TermControl.idl">[m
       <DependentUpon>TermControl.xaml</DependentUpon>[m
[36m@@ -147,6 +173,8 @@[m
     <Page Include="SearchBoxControl.xaml">[m
       <SubType>Designer</SubType>[m
     </Page>[m
[32m+[m[32m    <Page Include="FuzzySearchTextControl.xaml" />[m[41m[m
[32m+[m[32m    <Page Include="FuzzySearchBoxControl.xaml" />[m[41m[m
     <Page Include="TermControl.xaml">[m
       <SubType>Designer</SubType>[m
     </Page>[m
[36m@@ -180,6 +208,9 @@[m
       <ReferenceOutputAssembly>false</ReferenceOutputAssembly>[m
     </ProjectReference>[m
   </ItemGroup>[m
[32m+[m[32m  <ItemGroup>[m[41m[m
[32m+[m[32m    <None Include="fzf\LICENSE" />[m[41m[m
[32m+[m[32m  </ItemGroup>[m[41m[m
   <!-- ====================== Compiler & Linker Flags ===================== -->[m
   <ItemDefinitionGroup>[m
     <ClCompile>[m
[36m@@ -192,9 +223,7 @@[m
   </ItemDefinitionGroup>[m
   <!-- ========================= Globals ======================== -->[m
   <Import Project="$(OpenConsoleDir)src\cppwinrt.build.post.props" />[m
[31m-[m
   <!-- This -must- go after cppwinrt.build.post.props because that includes many VS-provided props including appcontainer.common.props, which stomps on what cppwinrt.targets did. -->[m
   <Import Project="$(OpenConsoleDir)src\common.nugetversions.targets" />[m
[31m-[m
   <Import Project="$(SolutionDir)build\rules\CollectWildcardResources.targets" />[m
[31m-</Project>[m
[32m+[m[32m</Project>[m
\ No newline at end of file[m
[1mdiff --git a/src/cascadia/TerminalControl/fzf/LICENSE b/src/cascadia/TerminalControl/fzf/LICENSE[m
[1mnew file mode 100644[m
[1mindex 000000000..57a10051e[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/fzf/LICENSE[m
[36m@@ -0,0 +1,21 @@[m
[32m+[m[32mMIT License[m
[32m+[m
[32m+[m[32mCopyright (c) 2021 Simon Hauser[m
[32m+[m
[32m+[m[32mPermission is hereby granted, free of charge, to any person obtaining a copy[m
[32m+[m[32mof this software and associated documentation files (the "Software"), to deal[m
[32m+[m[32min the Software without restriction, including without limitation the rights[m
[32m+[m[32mto use, copy, modify, merge, publish, distribute, sublicense, and/or sell[m
[32m+[m[32mcopies of the Software, and to permit persons to whom the Software is[m
[32m+[m[32mfurnished to do so, subject to the following conditions:[m
[32m+[m
[32m+[m[32mThe above copyright notice and this permission notice shall be included in all[m
[32m+[m[32mcopies or substantial portions of the Software.[m
[32m+[m
[32m+[m[32mTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR[m
[32m+[m[32mIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,[m
[32m+[m[32mFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE[m
[32m+[m[32mAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER[m
[32m+[m[32mLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,[m
[32m+[m[32mOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE[m
[32m+[m[32mSOFTWARE.[m
[1mdiff --git a/src/cascadia/TerminalControl/fzf/fzf.c b/src/cascadia/TerminalControl/fzf/fzf.c[m
[1mnew file mode 100644[m
[1mindex 000000000..99d2877db[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/fzf/fzf.c[m
[36m@@ -0,0 +1,1282 @@[m
[32m+[m[32m#define _CRT_SECURE_NO_WARNINGS[m
[32m+[m[32m#pragma warning(push, 0)[m
[32m+[m[32m#pragma warning(disable : 4100)[m
[32m+[m
[32m+[m[32m#include "fzf.h"[m
[32m+[m
[32m+[m[32m#include <string.h>[m
[32m+[m[32m#include <ctype.h>[m
[32m+[m[32m#include <stdlib.h>[m
[32m+[m
[32m+[m[32m// TODO(conni2461): UNICODE HEADER[m
[32m+[m[32m#define UNICODE_MAXASCII 0x7f[m
[32m+[m
[32m+[m[32m#define SFREE(x)                                                               \[m
[32m+[m[32m  if (x) {                                                                     \[m
[32m+[m[32m    free(x);                                                                   \[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m/* Helpers */[m
[32m+[m[32m#define free_alloc(obj)                                                        \[m
[32m+[m[32m  if ((obj).allocated) {                                                       \[m
[32m+[m[32m    free((obj).data);                                                          \[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m#define gen_simple_slice(name, type)                                           \[m
[32m+[m[32m  typedef struct {                                                             \[m
[32m+[m[32m    type *data;                                                                \[m
[32m+[m[32m    size_t size;                                                               \[m
[32m+[m[32m  } name##_slice_t;                                                            \[m
[32m+[m[32m  static name##_slice_t slice_##name(type *input, size_t from, size_t to) {    \[m
[32m+[m[32m    return (name##_slice_t){.data = input + from, .size = to - from};          \[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m#define gen_slice(name, type)                                                  \[m
[32m+[m[32m  gen_simple_slice(name, type);                                                \[m
[32m+[m[32m  static name##_slice_t slice_##name##_right(type *input, size_t to) {         \[m
[32m+[m[32m    return slice_##name(input, 0, to);                                         \[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32mgen_slice(i16, int16_t);[m
[32m+[m[32mgen_simple_slice(i32, int32_t);[m
[32m+[m[32mgen_slice(str, const char);[m
[32m+[m[32m#undef gen_slice[m
[32m+[m[32m#undef gen_simple_slice[m
[32m+[m
[32m+[m[32m/* TODO(conni2461): additional types (utf8) */[m
[32m+[m[32mtypedef int32_t char_class;[m
[32m+[m[32mtypedef char byte;[m
[32m+[m
[32m+[m[32mtypedef enum {[m
[32m+[m[32m  ScoreMatch = 16,[m
[32m+[m[32m  ScoreGapStart = -3,[m
[32m+[m[32m  ScoreGapExtention = -1,[m
[32m+[m[32m  BonusBoundary = ScoreMatch / 2,[m
[32m+[m[32m  BonusNonWord = ScoreMatch / 2,[m
[32m+[m[32m  BonusCamel123 = BonusBoundary + ScoreGapExtention,[m
[32m+[m[32m  BonusConsecutive = -(ScoreGapStart + ScoreGapExtention),[m
[32m+[m[32m  BonusFirstCharMultiplier = 2,[m
[32m+[m[32m} score_t;[m
[32m+[m
[32m+[m[32mtypedef enum {[m
[32m+[m[32m  CharNonWord = 0,[m
[32m+[m[32m  CharLower,[m
[32m+[m[32m  CharUpper,[m
[32m+[m[32m  CharLetter,[m
[32m+[m[32m  CharNumber[m
[32m+[m[32m} char_types;[m
[32m+[m
[32m+[m[32mstatic int32_t index_byte(fzf_string_t *string, char b) {[m
[32m+[m[32m  for (size_t i = 0; i < string->size; i++) {[m
[32m+[m[32m    if (string->data[i] == b) {[m
[32m+[m[32m      return (int32_t)i;[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m[32m  return -1;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic size_t leading_whitespaces(fzf_string_t *str) {[m
[32m+[m[32m  size_t whitespaces = 0;[m
[32m+[m[32m  for (size_t i = 0; i < str->size; i++) {[m
[32m+[m[32m    if (!isspace((uint8_t)str->data[i])) {[m
[32m+[m[32m      break;[m
[32m+[m[32m    }[m
[32m+[m[32m    whitespaces++;[m
[32m+[m[32m  }[m
[32m+[m[32m  return whitespaces;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic size_t trailing_whitespaces(fzf_string_t *str) {[m
[32m+[m[32m  size_t whitespaces = 0;[m
[32m+[m[32m  for (size_t i = str->size - 1; i >= 0; i--) {[m
[32m+[m[32m    if (!isspace((uint8_t)str->data[i])) {[m
[32m+[m[32m      break;[m
[32m+[m[32m    }[m
[32m+[m[32m    whitespaces++;[m
[32m+[m[32m  }[m
[32m+[m[32m  return whitespaces;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic void copy_runes(fzf_string_t *src, fzf_i32_t *destination) {[m
[32m+[m[32m  for (size_t i = 0; i < src->size; i++) {[m
[32m+[m[32m    destination->data[i] = (int32_t)src->data[i];[m
[32m+[m[32m  }[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic void copy_into_i16(i16_slice_t *src, fzf_i16_t *dest) {[m
[32m+[m[32m  for (size_t i = 0; i < src->size; i++) {[m
[32m+[m[32m    dest->data[i] = src->data[i];[m
[32m+[m[32m  }[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32m// char* helpers[m
[32m+[m[32mstatic char *trim_whitespace_left(char *str, size_t *len) {[m
[32m+[m[32m  for (size_t i = 0; i < *len; i++) {[m
[32m+[m[32m    if (str[0] == ' ') {[m
[32m+[m[32m      (*len)--;[m
[32m+[m[32m      str++;[m
[32m+[m[32m    } else {[m
[32m+[m[32m      break;[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m[32m  return str;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic bool has_prefix(const char *str, const char *prefix, size_t prefix_len) {[m
[32m+[m[32m  return strncmp(prefix, str, prefix_len) == 0;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic bool has_suffix(const char *str, size_t len, const char *suffix,[m
[32m+[m[32m                       size_t suffix_len) {[m
[32m+[m[32m  return len >= suffix_len &&[m
[32m+[m[32m         strncmp(slice_str(str, len - suffix_len, len).data, suffix,[m
[32m+[m[32m                 suffix_len) == 0;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic char *str_replace_char(char *str, char find, char replace) {[m
[32m+[m[32m  char *current_pos = strchr(str, find);[m
[32m+[m[32m  while (current_pos) {[m
[32m+[m[32m    *current_pos = replace;[m
[32m+[m[32m    current_pos = strchr(current_pos, find);[m
[32m+[m[32m  }[m
[32m+[m[32m  return str;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic char *str_replace(char *orig, char *rep, char *with) {[m
[32m+[m[32m  if (!orig || !rep || !with) {[m
[32m+[m[32m    return NULL;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  char *result;[m
[32m+[m[32m  char *ins;[m
[32m+[m[32m  char *tmp;[m
[32m+[m
[32m+[m[32m  size_t len_rep = strlen(rep);[m
[32m+[m[32m  size_t len_front = 0;[m
[32m+[m[32m  size_t len_orig = strlen(orig);[m
[32m+[m[32m  size_t len_with = strlen(with);[m
[32m+[m[32m  size_t count = 0;[m
[32m+[m
[32m+[m[32m  if (len_rep == 0) {[m
[32m+[m[32m    return NULL;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  ins = orig;[m
[32m+[m[32m  for (; (tmp = strstr(ins, rep)); ++count) {[m
[32m+[m[32m    ins = tmp + len_rep;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  tmp = result = (char *)malloc(len_orig + (len_with - len_rep) * count + 1);[m
[32m+[m[32m  if (!result) {[m
[32m+[m[32m    return NULL;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  while (count--) {[m
[32m+[m[32m    ins = strstr(orig, rep);[m
[32m+[m[32m    len_front = (size_t)(ins - orig);[m
[32m+[m[32m    tmp = strncpy(tmp, orig, len_front) + len_front;[m
[32m+[m[32m    tmp = strcpy(tmp, with) + len_with;[m
[32m+[m[32m    orig += len_front + len_rep;[m
[32m+[m[32m    len_orig -= len_front + len_rep;[m
[32m+[m[32m  }[m
[32m+[m[32m  strncpy(tmp, orig, len_orig);[m
[32m+[m[32m  tmp[len_orig] = 0;[m
[32m+[m[32m  return result;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32m// TODO(conni2461): REFACTOR[m
[32m+[m[32mstatic char *str_tolower(char *str, size_t size) {[m
[32m+[m[32m  char *lower_str = (char *)malloc((size + 1) * sizeof(char));[m
[32m+[m[32m  for (size_t i = 0; i < size; i++) {[m
[32m+[m[32m    lower_str[i] = (char)tolower((uint8_t)str[i]);[m
[32m+[m[32m  }[m
[32m+[m[32m  lower_str[size] = '\0';[m
[32m+[m[32m  return lower_str;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic int16_t max16(int16_t a, int16_t b) {[m
[32m+[m[32m  return (a > b) ? a : b;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic size_t min64u(size_t a, size_t b) {[m
[32m+[m[32m  return (a < b) ? a : b;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mfzf_position_t *fzf_pos_array(size_t len) {[m
[32m+[m[32m  fzf_position_t *pos = (fzf_position_t *)malloc(sizeof(fzf_position_t));[m
[32m+[m[32m  pos->size = 0;[m
[32m+[m[32m  pos->cap = len;[m
[32m+[m[32m  if (len > 0) {[m
[32m+[m[32m    pos->data = (uint32_t *)malloc(len * sizeof(uint32_t));[m
[32m+[m[32m  } else {[m
[32m+[m[32m    pos->data = NULL;[m
[32m+[m[32m  }[m
[32m+[m[32m  return pos;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic void resize_pos(fzf_position_t *pos, size_t add_len, size_t comp) {[m
[32m+[m[32m  if (!pos) {[m
[32m+[m[32m    return;[m
[32m+[m[32m  }[m
[32m+[m[32m  if (pos->size + comp > pos->cap) {[m
[32m+[m[32m    pos->cap += add_len > 0 ? add_len : 1;[m
[32m+[m[32m    pos->data = (uint32_t *)realloc(pos->data, sizeof(uint32_t) * pos->cap);[m
[32m+[m[32m  }[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic void unsafe_append_pos(fzf_position_t *pos, size_t value) {[m
[32m+[m[32m  resize_pos(pos, pos->cap, 1);[m
[32m+[m[32m  pos->data[pos->size] = value;[m
[32m+[m[32m  pos->size++;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic void append_pos(fzf_position_t *pos, size_t value) {[m
[32m+[m[32m  if (pos) {[m
[32m+[m[32m    unsafe_append_pos(pos, value);[m
[32m+[m[32m  }[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic void insert_range(fzf_position_t *pos, size_t start, size_t end) {[m
[32m+[m[32m  if (!pos) {[m
[32m+[m[32m    return;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  int32_t diff = ((int32_t)end - (int32_t)start);[m
[32m+[m[32m  if (diff <= 0) {[m
[32m+[m[32m    return;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  resize_pos(pos, end - start, end - start);[m
[32m+[m[32m  for (size_t k = start; k < end; k++) {[m
[32m+[m[32m    pos->data[pos->size] = k;[m
[32m+[m[32m    pos->size++;[m
[32m+[m[32m  }[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic fzf_i16_t alloc16(size_t *offset, fzf_slab_t *slab, size_t size) {[m
[32m+[m[32m  if (slab != NULL && slab->I16.cap > *offset + size) {[m
[32m+[m[32m    i16_slice_t slice = slice_i16(slab->I16.data, *offset, (*offset) + size);[m
[32m+[m[32m    *offset = *offset + size;[m
[32m+[m[32m    return (fzf_i16_t){.data = slice.data,[m
[32m+[m[32m                       .size = slice.size,[m
[32m+[m[32m                       .cap = slice.size,[m
[32m+[m[32m                       .allocated = false};[m
[32m+[m[32m  }[m
[32m+[m[32m  int16_t *data = (int16_t *)malloc(size * sizeof(int16_t));[m
[32m+[m[32m  memset(data, 0, size * sizeof(int16_t));[m
[32m+[m[32m  return (fzf_i16_t){[m
[32m+[m[32m      .data = data, .size = size, .cap = size, .allocated = true};[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic fzf_i32_t alloc32(size_t *offset, fzf_slab_t *slab, size_t size) {[m
[32m+[m[32m  if (slab != NULL && slab->I32.cap > *offset + size) {[m
[32m+[m[32m    i32_slice_t slice = slice_i32(slab->I32.data, *offset, (*offset) + size);[m
[32m+[m[32m    *offset = *offset + size;[m
[32m+[m[32m    return (fzf_i32_t){.data = slice.data,[m
[32m+[m[32m                       .size = slice.size,[m
[32m+[m[32m                       .cap = slice.size,[m
[32m+[m[32m                       .allocated = false};[m
[32m+[m[32m  }[m
[32m+[m[32m  int32_t *data = (int32_t *)malloc(size * sizeof(int32_t));[m
[32m+[m[32m  memset(data, 0, size * sizeof(int32_t));[m
[32m+[m[32m  return (fzf_i32_t){[m
[32m+[m[32m      .data = data, .size = size, .cap = size, .allocated = true};[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic char_class char_class_of_ascii(char ch) {[m
[32m+[m[32m  if (ch >= 'a' && ch <= 'z') {[m
[32m+[m[32m    return CharLower;[m
[32m+[m[32m  }[m
[32m+[m[32m  if (ch >= 'A' && ch <= 'Z') {[m
[32m+[m[32m    return CharUpper;[m
[32m+[m[32m  }[m
[32m+[m[32m  if (ch >= '0' && ch <= '9') {[m
[32m+[m[32m    return CharNumber;[m
[32m+[m[32m  }[m
[32m+[m[32m  return CharNonWord;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32m// static char_class char_class_of_non_ascii(char ch) {[m
[32m+[m[32m//   return 0;[m
[32m+[m[32m// }[m
[32m+[m
[32m+[m[32mstatic char_class char_class_of(char ch) {[m
[32m+[m[32m  return char_class_of_ascii(ch);[m
[32m+[m[32m  // if (ch <= 0x7f) {[m
[32m+[m[32m  //   return char_class_of_ascii(ch);[m
[32m+[m[32m  // }[m
[32m+[m[32m  // return char_class_of_non_ascii(ch);[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic int16_t bonus_for(char_class prev_class, char_class class) {[m
[32m+[m[32m  if (prev_class == CharNonWord && class != CharNonWord) {[m
[32m+[m[32m    return BonusBoundary;[m
[32m+[m[32m  }[m
[32m+[m[32m  if ((prev_class == CharLower && class == CharUpper) ||[m
[32m+[m[32m      (prev_class != CharNumber && class == CharNumber)) {[m
[32m+[m[32m    return BonusCamel123;[m
[32m+[m[32m  }[m
[32m+[m[32m  if (class == CharNonWord) {[m
[32m+[m[32m    return BonusNonWord;[m
[32m+[m[32m  }[m
[32m+[m[32m  return 0;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic int16_t bonus_at(fzf_string_t *input, size_t idx) {[m
[32m+[m[32m  if (idx == 0) {[m
[32m+[m[32m    return BonusBoundary;[m
[32m+[m[32m  }[m
[32m+[m[32m  return bonus_for(char_class_of(input->data[idx - 1]),[m
[32m+[m[32m                   char_class_of(input->data[idx]));[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32m/* TODO(conni2461): maybe just not do this */[m
[32m+[m[32mstatic char normalize_rune(char r) {[m
[32m+[m[32m  // TODO(conni2461)[m
[32m+[m[32m  /* if (r < 0x00C0 || r > 0x2184) { */[m
[32m+[m[32m  /*   return r; */[m
[32m+[m[32m  /* } */[m
[32m+[m[32m  /* rune n = normalized[r]; */[m
[32m+[m[32m  /* if n > 0 { */[m
[32m+[m[32m  /*   return n; */[m
[32m+[m[32m  /* } */[m
[32m+[m[32m  return r;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic int32_t try_skip(fzf_string_t *input, bool case_sensitive, byte b,[m
[32m+[m[32m                        int32_t from) {[m
[32m+[m[32m  str_slice_t slice = slice_str(input->data, (size_t)from, input->size);[m
[32m+[m[32m  fzf_string_t byte_array = {.data = slice.data, .size = slice.size};[m
[32m+[m[32m  int32_t idx = index_byte(&byte_array, b);[m
[32m+[m[32m  if (idx == 0) {[m
[32m+[m[32m    return from;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  if (!case_sensitive && b >= 'a' && b <= 'z') {[m
[32m+[m[32m    if (idx > 0) {[m
[32m+[m[32m      str_slice_t tmp = slice_str_right(byte_array.data, (size_t)idx);[m
[32m+[m[32m      byte_array.data = tmp.data;[m
[32m+[m[32m      byte_array.size = tmp.size;[m
[32m+[m[32m    }[m
[32m+[m[32m    int32_t uidx = index_byte(&byte_array, b - (byte)32);[m
[32m+[m[32m    if (uidx >= 0) {[m
[32m+[m[32m      idx = uidx;[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m[32m  if (idx < 0) {[m
[32m+[m[32m    return -1;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  return from + idx;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic bool is_ascii(const char *runes, size_t size) {[m
[32m+[m[32m  // TODO(conni2461): future use[m
[32m+[m[32m  /* for (size_t i = 0; i < size; i++) { */[m
[32m+[m[32m  /*   if (runes[i] >= 256) { */[m
[32m+[m[32m  /*     return false; */[m
[32m+[m[32m  /*   } */[m
[32m+[m[32m  /* } */[m
[32m+[m[32m  return true;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic int32_t ascii_fuzzy_index(fzf_string_t *input, const char *pattern,[m
[32m+[m[32m                                 size_t size, bool case_sensitive) {[m
[32m+[m[32m  if (!is_ascii(pattern, size)) {[m
[32m+[m[32m    return -1;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  int32_t first_idx = 0;[m
[32m+[m[32m  int32_t idx = 0;[m
[32m+[m[32m  for (size_t pidx = 0; pidx < size; pidx++) {[m
[32m+[m[32m    idx = try_skip(input, case_sensitive, pattern[pidx], idx);[m
[32m+[m[32m    if (idx < 0) {[m
[32m+[m[32m      return -1;[m
[32m+[m[32m    }[m
[32m+[m[32m    if (pidx == 0 && idx > 0) {[m
[32m+[m[32m      first_idx = idx - 1;[m
[32m+[m[32m    }[m
[32m+[m[32m    idx++;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  return first_idx;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic int32_t calculate_score(bool case_sensitive, bool normalize,[m
[32m+[m[32m                               fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                               size_t sidx, size_t eidx, fzf_position_t *pos) {[m
[32m+[m[32m  const size_t M = pattern->size;[m
[32m+[m
[32m+[m[32m  size_t pidx = 0;[m
[32m+[m[32m  int32_t score = 0;[m
[32m+[m[32m  int32_t consecutive = 0;[m
[32m+[m[32m  bool in_gap = false;[m
[32m+[m[32m  int16_t first_bonus = 0;[m
[32m+[m
[32m+[m[32m  resize_pos(pos, M, M);[m
[32m+[m[32m  int32_t prev_class = CharNonWord;[m
[32m+[m[32m  if (sidx > 0) {[m
[32m+[m[32m    prev_class = char_class_of(text->data[sidx - 1]);[m
[32m+[m[32m  }[m
[32m+[m[32m  for (size_t idx = sidx; idx < eidx; idx++) {[m
[32m+[m[32m    char c = text->data[idx];[m
[32m+[m[32m    int32_t class = char_class_of(c);[m
[32m+[m[32m    if (!case_sensitive) {[m
[32m+[m[32m      /* TODO(conni2461): He does some unicode stuff here, investigate */[m
[32m+[m[32m      c = (char)tolower((uint8_t)c);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (normalize) {[m
[32m+[m[32m      c = normalize_rune(c);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (c == pattern->data[pidx]) {[m
[32m+[m[32m      append_pos(pos, idx);[m
[32m+[m[32m      score += ScoreMatch;[m
[32m+[m[32m      int16_t bonus = bonus_for(prev_class, class);[m
[32m+[m[32m      if (consecutive == 0) {[m
[32m+[m[32m        first_bonus = bonus;[m
[32m+[m[32m      } else {[m
[32m+[m[32m        if (bonus == BonusBoundary) {[m
[32m+[m[32m          first_bonus = bonus;[m
[32m+[m[32m        }[m
[32m+[m[32m        bonus = max16(max16(bonus, first_bonus), BonusConsecutive);[m
[32m+[m[32m      }[m
[32m+[m[32m      if (pidx == 0) {[m
[32m+[m[32m        score += (int32_t)(bonus * BonusFirstCharMultiplier);[m
[32m+[m[32m      } else {[m
[32m+[m[32m        score += (int32_t)bonus;[m
[32m+[m[32m      }[m
[32m+[m[32m      in_gap = false;[m
[32m+[m[32m      consecutive++;[m
[32m+[m[32m      pidx++;[m
[32m+[m[32m    } else {[m
[32m+[m[32m      if (in_gap) {[m
[32m+[m[32m        score += ScoreGapExtention;[m
[32m+[m[32m      } else {[m
[32m+[m[32m        score += ScoreGapStart;[m
[32m+[m[32m      }[m
[32m+[m[32m      in_gap = true;[m
[32m+[m[32m      consecutive = 0;[m
[32m+[m[32m      first_bonus = 0;[m
[32m+[m[32m    }[m
[32m+[m[32m    prev_class = class;[m
[32m+[m[32m  }[m
[32m+[m[32m  return score;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mfzf_result_t fzf_fuzzy_match_v1(bool case_sensitive, bool normalize,[m
[32m+[m[32m                                fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                                fzf_position_t *pos, fzf_slab_t *slab) {[m
[32m+[m[32m  const size_t M = pattern->size;[m
[32m+[m[32m  const size_t N = text->size;[m
[32m+[m[32m  if (M == 0) {[m
[32m+[m[32m    return (fzf_result_t){0, 0, 0};[m
[32m+[m[32m  }[m
[32m+[m[32m  if (ascii_fuzzy_index(text, pattern->data, M, case_sensitive) < 0) {[m
[32m+[m[32m    return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  int32_t pidx = 0;[m
[32m+[m[32m  int32_t sidx = -1;[m
[32m+[m[32m  int32_t eidx = -1;[m
[32m+[m[32m  for (size_t idx = 0; idx < N; idx++) {[m
[32m+[m[32m    char c = text->data[idx];[m
[32m+[m[32m    /* TODO(conni2461): Common pattern maybe a macro would be good here */[m
[32m+[m[32m    if (!case_sensitive) {[m
[32m+[m[32m      /* TODO(conni2461): He does some unicode stuff here, investigate */[m
[32m+[m[32m      c = (char)tolower((uint8_t)c);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (normalize) {[m
[32m+[m[32m      c = normalize_rune(c);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (c == pattern->data[pidx]) {[m
[32m+[m[32m      if (sidx < 0) {[m
[32m+[m[32m        sidx = (int32_t)idx;[m
[32m+[m[32m      }[m
[32m+[m[32m      pidx++;[m
[32m+[m[32m      if (pidx == M) {[m
[32m+[m[32m        eidx = (int32_t)idx + 1;[m
[32m+[m[32m        break;[m
[32m+[m[32m      }[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m[32m  if (sidx >= 0 && eidx >= 0) {[m
[32m+[m[32m    size_t start = (size_t)sidx;[m
[32m+[m[32m    size_t end = (size_t)eidx;[m
[32m+[m[32m    pidx--;[m
[32m+[m[32m    for (size_t idx = end - 1; idx >= start; idx--) {[m
[32m+[m[32m      char c = text->data[idx];[m
[32m+[m[32m      if (!case_sensitive) {[m
[32m+[m[32m        /* TODO(conni2461): He does some unicode stuff here, investigate */[m
[32m+[m[32m        c = (char)tolower((uint8_t)c);[m
[32m+[m[32m      }[m
[32m+[m[32m      if (c == pattern->data[pidx]) {[m
[32m+[m[32m        pidx--;[m
[32m+[m[32m        if (pidx < 0) {[m
[32m+[m[32m          start = idx;[m
[32m+[m[32m          break;[m
[32m+[m[32m        }[m
[32m+[m[32m      }[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    int32_t score = calculate_score(case_sensitive, normalize, text, pattern,[m
[32m+[m[32m                                    start, end, pos);[m
[32m+[m[32m    return (fzf_result_t){(int32_t)start, (int32_t)end, score};[m
[32m+[m[32m  }[m
[32m+[m[32m  return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mfzf_result_t fzf_fuzzy_match_v2(bool case_sensitive, bool normalize,[m
[32m+[m[32m                                fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                                fzf_position_t *pos, fzf_slab_t *slab) {[m
[32m+[m[32m  const size_t M = pattern->size;[m
[32m+[m[32m  const size_t N = text->size;[m
[32m+[m[32m  if (M == 0) {[m
[32m+[m[32m    return (fzf_result_t){0, 0, 0};[m
[32m+[m[32m  }[m
[32m+[m[32m  if (slab != NULL && N * M > slab->I16.cap) {[m
[32m+[m[32m    return fzf_fuzzy_match_v1(case_sensitive, normalize, text, pattern, pos,[m
[32m+[m[32m                              slab);[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  size_t idx;[m
[32m+[m[32m  {[m
[32m+[m[32m    int32_t tmp_idx = ascii_fuzzy_index(text, pattern->data, M, case_sensitive);[m
[32m+[m[32m    if (tmp_idx < 0) {[m
[32m+[m[32m      return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m    }[m
[32m+[m[32m    idx = (size_t)tmp_idx;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  size_t offset16 = 0;[m
[32m+[m[32m  size_t offset32 = 0;[m
[32m+[m
[32m+[m[32m  fzf_i16_t h0 = alloc16(&offset16, slab, N);[m
[32m+[m[32m  fzf_i16_t c0 = alloc16(&offset16, slab, N);[m
[32m+[m[32m  // Bonus point for each positions[m
[32m+[m[32m  fzf_i16_t bo = alloc16(&offset16, slab, N);[m
[32m+[m[32m  // The first occurrence of each character in the pattern[m
[32m+[m[32m  fzf_i32_t f = alloc32(&offset32, slab, M);[m
[32m+[m[32m  // Rune array[m
[32m+[m[32m  fzf_i32_t t = alloc32(&offset32, slab, N);[m
[32m+[m[32m  copy_runes(text, &t); // input.CopyRunes(T)[m
[32m+[m
[32m+[m[32m  // Phase 2. Calculate bonus for each point[m
[32m+[m[32m  int16_t max_score = 0;[m
[32m+[m[32m  size_t max_score_pos = 0;[m
[32m+[m
[32m+[m[32m  size_t pidx = 0;[m
[32m+[m[32m  size_t last_idx = 0;[m
[32m+[m
[32m+[m[32m  char pchar0 = pattern->data[0];[m
[32m+[m[32m  char pchar = pattern->data[0];[m
[32m+[m[32m  int16_t prev_h0 = 0;[m
[32m+[m[32m  int32_t prev_class = CharNonWord;[m
[32m+[m[32m  bool in_gap = false;[m
[32m+[m
[32m+[m[32m  i32_slice_t t_sub = slice_i32(t.data, idx, t.size); // T[idx:];[m
[32m+[m[32m  i16_slice_t h0_sub =[m
[32m+[m[32m      slice_i16_right(slice_i16(h0.data, idx, h0.size).data, t_sub.size);[m
[32m+[m[32m  i16_slice_t c0_sub =[m
[32m+[m[32m      slice_i16_right(slice_i16(c0.data, idx, c0.size).data, t_sub.size);[m
[32m+[m[32m  i16_slice_t b_sub =[m
[32m+[m[32m      slice_i16_right(slice_i16(bo.data, idx, bo.size).data, t_sub.size);[m
[32m+[m
[32m+[m[32m  for (size_t off = 0; off < t_sub.size; off++) {[m
[32m+[m[32m    char_class class;[m
[32m+[m[32m    char c = (char)t_sub.data[off];[m
[32m+[m[32m    class = char_class_of_ascii(c);[m
[32m+[m[32m    if (!case_sensitive && class == CharUpper) {[m
[32m+[m[32m      /* TODO(conni2461): unicode support */[m
[32m+[m[32m      c = (char)tolower((uint8_t)c);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (normalize) {[m
[32m+[m[32m      c = normalize_rune(c);[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    t_sub.data[off] = (uint8_t)c;[m
[32m+[m[32m    int16_t bonus = bonus_for(prev_class, class);[m
[32m+[m[32m    b_sub.data[off] = bonus;[m
[32m+[m[32m    prev_class = class;[m
[32m+[m[32m    if (c == pchar) {[m
[32m+[m[32m      if (pidx < M) {[m
[32m+[m[32m        f.data[pidx] = (int32_t)(idx + off);[m
[32m+[m[32m        pidx++;[m
[32m+[m[32m        pchar = pattern->data[min64u(pidx, M - 1)];[m
[32m+[m[32m      }[m
[32m+[m[32m      last_idx = idx + off;[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    if (c == pchar0) {[m
[32m+[m[32m      int16_t score = ScoreMatch + bonus * BonusFirstCharMultiplier;[m
[32m+[m[32m      h0_sub.data[off] = score;[m
[32m+[m[32m      c0_sub.data[off] = 1;[m
[32m+[m[32m      if (M == 1 && (score > max_score)) {[m
[32m+[m[32m        max_score = score;[m
[32m+[m[32m        max_score_pos = idx + off;[m
[32m+[m[32m        if (bonus == BonusBoundary) {[m
[32m+[m[32m          break;[m
[32m+[m[32m        }[m
[32m+[m[32m      }[m
[32m+[m[32m      in_gap = false;[m
[32m+[m[32m    } else {[m
[32m+[m[32m      if (in_gap) {[m
[32m+[m[32m        h0_sub.data[off] = max16(prev_h0 + ScoreGapExtention, 0);[m
[32m+[m[32m      } else {[m
[32m+[m[32m        h0_sub.data[off] = max16(prev_h0 + ScoreGapStart, 0);[m
[32m+[m[32m      }[m
[32m+[m[32m      c0_sub.data[off] = 0;[m
[32m+[m[32m      in_gap = true;[m
[32m+[m[32m    }[m
[32m+[m[32m    prev_h0 = h0_sub.data[off];[m
[32m+[m[32m  }[m
[32m+[m[32m  if (pidx != M) {[m
[32m+[m[32m    free_alloc(t);[m
[32m+[m[32m    free_alloc(f);[m
[32m+[m[32m    free_alloc(bo);[m
[32m+[m[32m    free_alloc(c0);[m
[32m+[m[32m    free_alloc(h0);[m
[32m+[m[32m    return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m  }[m
[32m+[m[32m  if (M == 1) {[m
[32m+[m[32m    free_alloc(t);[m
[32m+[m[32m    free_alloc(f);[m
[32m+[m[32m    free_alloc(bo);[m
[32m+[m[32m    free_alloc(c0);[m
[32m+[m[32m    free_alloc(h0);[m
[32m+[m[32m    fzf_result_t res = {(int32_t)max_score_pos, (int32_t)max_score_pos + 1,[m
[32m+[m[32m                        max_score};[m
[32m+[m[32m    append_pos(pos, max_score_pos);[m
[32m+[m[32m    return res;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  size_t f0 = (size_t)f.data[0];[m
[32m+[m[32m  size_t width = last_idx - f0 + 1;[m
[32m+[m[32m  fzf_i16_t h = alloc16(&offset16, slab, width * M);[m
[32m+[m[32m  {[m
[32m+[m[32m    i16_slice_t h0_tmp_slice = slice_i16(h0.data, f0, last_idx + 1);[m
[32m+[m[32m    copy_into_i16(&h0_tmp_slice, &h);[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  fzf_i16_t c = alloc16(&offset16, slab, width * M);[m
[32m+[m[32m  {[m
[32m+[m[32m    i16_slice_t c0_tmp_slice = slice_i16(c0.data, f0, last_idx + 1);[m
[32m+[m[32m    copy_into_i16(&c0_tmp_slice, &c);[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  i32_slice_t f_sub = slice_i32(f.data, 1, f.size);[m
[32m+[m[32m  str_slice_t p_sub =[m
[32m+[m[32m      slice_str_right(slice_str(pattern->data, 1, M).data, f_sub.size);[m
[32m+[m[32m  for (size_t off = 0; off < f_sub.size; off++) {[m
[32m+[m[32m    size_t f = (size_t)f_sub.data[off];[m
[32m+[m[32m    pchar = p_sub.data[off];[m
[32m+[m[32m    pidx = off + 1;[m
[32m+[m[32m    size_t row = pidx * width;[m
[32m+[m[32m    in_gap = false;[m
[32m+[m[32m    t_sub = slice_i32(t.data, f, last_idx + 1);[m
[32m+[m[32m    b_sub = slice_i16_right(slice_i16(bo.data, f, bo.size).data, t_sub.size);[m
[32m+[m[32m    i16_slice_t c_sub = slice_i16_right([m
[32m+[m[32m        slice_i16(c.data, row + f - f0, c.size).data, t_sub.size);[m
[32m+[m[32m    i16_slice_t c_diag = slice_i16_right([m
[32m+[m[32m        slice_i16(c.data, row + f - f0 - 1 - width, c.size).data, t_sub.size);[m
[32m+[m[32m    i16_slice_t h_sub = slice_i16_right([m
[32m+[m[32m        slice_i16(h.data, row + f - f0, h.size).data, t_sub.size);[m
[32m+[m[32m    i16_slice_t h_diag = slice_i16_right([m
[32m+[m[32m        slice_i16(h.data, row + f - f0 - 1 - width, h.size).data, t_sub.size);[m
[32m+[m[32m    i16_slice_t h_left = slice_i16_right([m
[32m+[m[32m        slice_i16(h.data, row + f - f0 - 1, h.size).data, t_sub.size);[m
[32m+[m[32m    h_left.data[0] = 0;[m
[32m+[m[32m    for (size_t j = 0; j < t_sub.size; j++) {[m
[32m+[m[32m      char ch = (char)t_sub.data[j];[m
[32m+[m[32m      size_t col = j + f;[m
[32m+[m[32m      int16_t s1 = 0;[m
[32m+[m[32m      int16_t s2 = 0;[m
[32m+[m[32m      int16_t consecutive = 0;[m
[32m+[m
[32m+[m[32m      if (in_gap) {[m
[32m+[m[32m        s2 = h_left.data[j] + ScoreGapExtention;[m
[32m+[m[32m      } else {[m
[32m+[m[32m        s2 = h_left.data[j] + ScoreGapStart;[m
[32m+[m[32m      }[m
[32m+[m
[32m+[m[32m      if (pchar == ch) {[m
[32m+[m[32m        s1 = h_diag.data[j] + ScoreMatch;[m
[32m+[m[32m        int16_t b = b_sub.data[j];[m
[32m+[m[32m        consecutive = c_diag.data[j] + 1;[m
[32m+[m[32m        if (b == BonusBoundary) {[m
[32m+[m[32m          consecutive = 1;[m
[32m+[m[32m        } else if (consecutive > 1) {[m
[32m+[m[32m          b = max16(b, max16(BonusConsecutive,[m
[32m+[m[32m                             bo.data[col - ((size_t)consecutive) + 1]));[m
[32m+[m[32m        }[m
[32m+[m[32m        if (s1 + b < s2) {[m
[32m+[m[32m          s1 += b_sub.data[j];[m
[32m+[m[32m          consecutive = 0;[m
[32m+[m[32m        } else {[m
[32m+[m[32m          s1 += b;[m
[32m+[m[32m        }[m
[32m+[m[32m      }[m
[32m+[m[32m      c_sub.data[j] = consecutive;[m
[32m+[m[32m      in_gap = s1 < s2;[m
[32m+[m[32m      int16_t score = max16(max16(s1, s2), 0);[m
[32m+[m[32m      if (pidx == M - 1 && (score > max_score)) {[m
[32m+[m[32m        max_score = score;[m
[32m+[m[32m        max_score_pos = col;[m
[32m+[m[32m      }[m
[32m+[m[32m      h_sub.data[j] = score;[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  resize_pos(pos, M, M);[m
[32m+[m[32m  size_t j = max_score_pos;[m
[32m+[m[32m  if (pos) {[m
[32m+[m[32m    size_t i = M - 1;[m
[32m+[m[32m    bool prefer_match = true;[m
[32m+[m[32m    for (;;) {[m
[32m+[m[32m      size_t ii = i * width;[m
[32m+[m[32m      size_t j0 = j - f0;[m
[32m+[m[32m      int16_t s = h.data[ii + j0];[m
[32m+[m
[32m+[m[32m      int16_t s1 = 0;[m
[32m+[m[32m      int16_t s2 = 0;[m
[32m+[m[32m      if (i > 0 && j >= f.data[i]) {[m
[32m+[m[32m        s1 = h.data[ii - width + j0 - 1];[m
[32m+[m[32m      }[m
[32m+[m[32m      if (j > f.data[i]) {[m
[32m+[m[32m        s2 = h.data[ii + j0 - 1];[m
[32m+[m[32m      }[m
[32m+[m
[32m+[m[32m      if (s > s1 && (s > s2 || (s == s2 && prefer_match))) {[m
[32m+[m[32m        unsafe_append_pos(pos, j);[m
[32m+[m[32m        if (i == 0) {[m
[32m+[m[32m          break;[m
[32m+[m[32m        }[m
[32m+[m[32m        i--;[m
[32m+[m[32m      }[m
[32m+[m[32m      prefer_match = c.data[ii + j0] > 1 || (ii + width + j0 + 1 < c.size &&[m
[32m+[m[32m                                             c.data[ii + width + j0 + 1] > 0);[m
[32m+[m[32m      j--;[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  free_alloc(h);[m
[32m+[m[32m  free_alloc(c);[m
[32m+[m[32m  free_alloc(t);[m
[32m+[m[32m  free_alloc(f);[m
[32m+[m[32m  free_alloc(bo);[m
[32m+[m[32m  free_alloc(c0);[m
[32m+[m[32m  free_alloc(h0);[m
[32m+[m[32m  return (fzf_result_t){(int32_t)j, (int32_t)max_score_pos + 1,[m
[32m+[m[32m                        (int32_t)max_score};[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mfzf_result_t fzf_exact_match_naive(bool case_sensitive, bool normalize,[m
[32m+[m[32m                                   fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                                   fzf_position_t *pos, fzf_slab_t *slab) {[m
[32m+[m[32m  const size_t M = pattern->size;[m
[32m+[m[32m  const size_t N = text->size;[m
[32m+[m
[32m+[m[32m  if (M == 0) {[m
[32m+[m[32m    return (fzf_result_t){0, 0, 0};[m
[32m+[m[32m  }[m
[32m+[m[32m  if (N < M) {[m
[32m+[m[32m    return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m  }[m
[32m+[m[32m  if (ascii_fuzzy_index(text, pattern->data, M, case_sensitive) < 0) {[m
[32m+[m[32m    return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  size_t pidx = 0;[m
[32m+[m[32m  int32_t best_pos = -1;[m
[32m+[m[32m  int16_t bonus = 0;[m
[32m+[m[32m  int16_t best_bonus = -1;[m
[32m+[m[32m  for (size_t idx = 0; idx < N; idx++) {[m
[32m+[m[32m    char c = text->data[idx];[m
[32m+[m[32m    if (!case_sensitive) {[m
[32m+[m[32m      /* TODO(conni2461): He does some unicode stuff here, investigate */[m
[32m+[m[32m      c = (char)tolower((uint8_t)c);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (normalize) {[m
[32m+[m[32m      c = normalize_rune(c);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (c == pattern->data[pidx]) {[m
[32m+[m[32m      if (pidx == 0) {[m
[32m+[m[32m        bonus = bonus_at(text, idx);[m
[32m+[m[32m      }[m
[32m+[m[32m      pidx++;[m
[32m+[m[32m      if (pidx == M) {[m
[32m+[m[32m        if (bonus > best_bonus) {[m
[32m+[m[32m          best_pos = (int32_t)idx;[m
[32m+[m[32m          best_bonus = bonus;[m
[32m+[m[32m        }[m
[32m+[m[32m        if (bonus == BonusBoundary) {[m
[32m+[m[32m          break;[m
[32m+[m[32m        }[m
[32m+[m[32m        idx -= pidx - 1;[m
[32m+[m[32m        pidx = 0;[m
[32m+[m[32m        bonus = 0;[m
[32m+[m[32m      }[m
[32m+[m[32m    } else {[m
[32m+[m[32m      idx -= pidx;[m
[32m+[m[32m      pidx = 0;[m
[32m+[m[32m      bonus = 0;[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m[32m  if (best_pos >= 0) {[m
[32m+[m[32m    size_t bp = (size_t)best_pos;[m
[32m+[m[32m    size_t sidx = bp - M + 1;[m
[32m+[m[32m    size_t eidx = bp + 1;[m
[32m+[m[32m    int32_t score = calculate_score(case_sensitive, normalize, text, pattern,[m
[32m+[m[32m                                    sidx, eidx, NULL);[m
[32m+[m[32m    insert_range(pos, sidx, eidx);[m
[32m+[m[32m    return (fzf_result_t){(int32_t)sidx, (int32_t)eidx, score};[m
[32m+[m[32m  }[m
[32m+[m[32m  return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mfzf_result_t fzf_prefix_match(bool case_sensitive, bool normalize,[m
[32m+[m[32m                              fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                              fzf_position_t *pos, fzf_slab_t *slab) {[m
[32m+[m[32m  const size_t M = pattern->size;[m
[32m+[m[32m  if (M == 0) {[m
[32m+[m[32m    return (fzf_result_t){0, 0, 0};[m
[32m+[m[32m  }[m
[32m+[m[32m  size_t trimmed_len = 0;[m
[32m+[m[32m  /* TODO(conni2461): i feel this is wrong */[m
[32m+[m[32m  if (!isspace((uint8_t)pattern->data[0])) {[m
[32m+[m[32m    trimmed_len = leading_whitespaces(text);[m
[32m+[m[32m  }[m
[32m+[m[32m  if (text->size - trimmed_len < M) {[m
[32m+[m[32m    return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m  }[m
[32m+[m[32m  for (size_t i = 0; i < M; i++) {[m
[32m+[m[32m    char c = text->data[trimmed_len + i];[m
[32m+[m[32m    if (!case_sensitive) {[m
[32m+[m[32m      c = (char)tolower((uint8_t)c);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (normalize) {[m
[32m+[m[32m      c = normalize_rune(c);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (c != pattern->data[i]) {[m
[32m+[m[32m      return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m[32m  size_t start = trimmed_len;[m
[32m+[m[32m  size_t end = trimmed_len + M;[m
[32m+[m[32m  int32_t score = calculate_score(case_sensitive, normalize, text, pattern,[m
[32m+[m[32m                                  start, end, NULL);[m
[32m+[m[32m  insert_range(pos, start, end);[m
[32m+[m[32m  return (fzf_result_t){(int32_t)start, (int32_t)end, score};[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mfzf_result_t fzf_suffix_match(bool case_sensitive, bool normalize,[m
[32m+[m[32m                              fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                              fzf_position_t *pos, fzf_slab_t *slab) {[m
[32m+[m[32m  size_t trimmed_len = text->size;[m
[32m+[m[32m  const size_t M = pattern->size;[m
[32m+[m[32m  /* TODO(conni2461): i think this is wrong */[m
[32m+[m[32m  if (M == 0 || !isspace((uint8_t)pattern->data[M - 1])) {[m
[32m+[m[32m    trimmed_len -= trailing_whitespaces(text);[m
[32m+[m[32m  }[m
[32m+[m[32m  if (M == 0) {[m
[32m+[m[32m    return (fzf_result_t){(int32_t)trimmed_len, (int32_t)trimmed_len, 0};[m
[32m+[m[32m  }[m
[32m+[m[32m  size_t diff = trimmed_len - M;[m
[32m+[m[32m  if (diff < 0) {[m
[32m+[m[32m    return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  for (size_t idx = 0; idx < M; idx++) {[m
[32m+[m[32m    char c = text->data[idx + diff];[m
[32m+[m[32m    if (!case_sensitive) {[m
[32m+[m[32m      c = (char)tolower((uint8_t)c);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (normalize) {[m
[32m+[m[32m      c = normalize_rune(c);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (c != pattern->data[idx]) {[m
[32m+[m[32m      return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m[32m  size_t start = trimmed_len - M;[m
[32m+[m[32m  size_t end = trimmed_len;[m
[32m+[m[32m  int32_t score = calculate_score(case_sensitive, normalize, text, pattern,[m
[32m+[m[32m                                  start, end, NULL);[m
[32m+[m[32m  insert_range(pos, start, end);[m
[32m+[m[32m  return (fzf_result_t){(int32_t)start, (int32_t)end, score};[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mfzf_result_t fzf_equal_match(bool case_sensitive, bool normalize,[m
[32m+[m[32m                             fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                             fzf_position_t *pos, fzf_slab_t *slab) {[m
[32m+[m[32m  const size_t M = pattern->size;[m
[32m+[m[32m  if (M == 0) {[m
[32m+[m[32m    return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  size_t trimmed_len = leading_whitespaces(text);[m
[32m+[m[32m  size_t trimmed_end_len = trailing_whitespaces(text);[m
[32m+[m
[32m+[m[32m  if ((text->size - trimmed_len - trimmed_end_len) != M) {[m
[32m+[m[32m    return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  bool match = true;[m
[32m+[m[32m  if (normalize) {[m
[32m+[m[32m    // TODO(conni2461): to rune[m
[32m+[m[32m    for (size_t idx = 0; idx < M; idx++) {[m
[32m+[m[32m      char pchar = pattern->data[idx];[m
[32m+[m[32m      char c = text->data[trimmed_len + idx];[m
[32m+[m[32m      if (!case_sensitive) {[m
[32m+[m[32m        c = (char)tolower((uint8_t)c);[m
[32m+[m[32m      }[m
[32m+[m[32m      if (normalize_rune(c) != normalize_rune(pchar)) {[m
[32m+[m[32m        match = false;[m
[32m+[m[32m        break;[m
[32m+[m[32m      }[m
[32m+[m[32m    }[m
[32m+[m[32m  } else {[m
[32m+[m[32m    // TODO(conni2461): to rune[m
[32m+[m[32m    for (size_t idx = 0; idx < M; idx++) {[m
[32m+[m[32m      char pchar = pattern->data[idx];[m
[32m+[m[32m      char c = text->data[trimmed_len + idx];[m
[32m+[m[32m      if (!case_sensitive) {[m
[32m+[m[32m        c = (char)tolower((uint8_t)c);[m
[32m+[m[32m      }[m
[32m+[m[32m      if (c != pchar) {[m
[32m+[m[32m        match = false;[m
[32m+[m[32m        break;[m
[32m+[m[32m      }[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m[32m  if (match) {[m
[32m+[m[32m    insert_range(pos, trimmed_len, trimmed_len + M);[m
[32m+[m[32m    return (fzf_result_t){(int32_t)trimmed_len,[m
[32m+[m[32m                          ((int32_t)trimmed_len + (int32_t)M),[m
[32m+[m[32m                          (ScoreMatch + BonusBoundary) * (int32_t)M +[m
[32m+[m[32m                              (BonusFirstCharMultiplier - 1) * BonusBoundary};[m
[32m+[m[32m  }[m
[32m+[m[32m  return (fzf_result_t){-1, -1, 0};[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic void append_set(fzf_term_set_t *set, fzf_term_t value) {[m
[32m+[m[32m  if (set->cap == 0) {[m
[32m+[m[32m    set->cap = 1;[m
[32m+[m[32m    set->ptr = (fzf_term_t *)malloc(sizeof(fzf_term_t));[m
[32m+[m[32m  } else if (set->size + 1 > set->cap) {[m
[32m+[m[32m    set->cap *= 2;[m
[32m+[m[32m    set->ptr = realloc(set->ptr, sizeof(fzf_term_t) * set->cap);[m
[32m+[m[32m  }[m
[32m+[m[32m  set->ptr[set->size] = value;[m
[32m+[m[32m  set->size++;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mstatic void append_pattern(fzf_pattern_t *pattern, fzf_term_set_t *value) {[m
[32m+[m[32m  if (pattern->cap == 0) {[m
[32m+[m[32m    pattern->cap = 1;[m
[32m+[m[32m    pattern->ptr = (fzf_term_set_t **)malloc(sizeof(fzf_term_set_t *));[m
[32m+[m[32m  } else if (pattern->size + 1 > pattern->cap) {[m
[32m+[m[32m    pattern->cap *= 2;[m
[32m+[m[32m    pattern->ptr =[m
[32m+[m[32m        realloc(pattern->ptr, sizeof(fzf_term_set_t *) * pattern->cap);[m
[32m+[m[32m  }[m
[32m+[m[32m  pattern->ptr[pattern->size] = value;[m
[32m+[m[32m  pattern->size++;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32m#define CALL_ALG(term, normalize, input, pos, slab)                            \[m
[32m+[m[32m  term->fn((term)->case_sensitive, normalize, &(input),                        \[m
[32m+[m[32m           (fzf_string_t *)(term)->text, pos, slab)[m
[32m+[m
[32m+[m[32m// TODO(conni2461): REFACTOR[m
[32m+[m[32m/* assumption (maybe i change that later)[m
[32m+[m[32m * - always v2 alg[m
[32m+[m[32m * - bool extended always true (thats the whole point of this isn't it)[m
[32m+[m[32m */[m
[32m+[m[32mfzf_pattern_t *fzf_parse_pattern(fzf_case_types case_mode, bool normalize,[m
[32m+[m[32m                                 char *pattern, bool fuzzy) {[m
[32m+[m[32m  fzf_pattern_t *pat_obj = (fzf_pattern_t *)malloc(sizeof(fzf_pattern_t));[m
[32m+[m[32m  memset(pat_obj, 0, sizeof(*pat_obj));[m
[32m+[m
[32m+[m[32m  size_t pat_len = strlen(pattern);[m
[32m+[m[32m  if (pat_len == 0) {[m
[32m+[m[32m    return pat_obj;[m
[32m+[m[32m  }[m
[32m+[m[32m  pattern = trim_whitespace_left(pattern, &pat_len);[m
[32m+[m[32m  while (has_suffix(pattern, pat_len, " ", 1) &&[m
[32m+[m[32m         !has_suffix(pattern, pat_len, "\\ ", 2)) {[m
[32m+[m[32m    pattern[pat_len - 1] = 0;[m
[32m+[m[32m    pat_len--;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  char *pattern_copy = str_replace(pattern, "\\ ", "\t");[m
[32m+[m[32m  const char *delim = " ";[m
[32m+[m[32m  char *ptr = strtok(pattern_copy, delim);[m
[32m+[m
[32m+[m[32m  fzf_term_set_t *set = (fzf_term_set_t *)malloc(sizeof(fzf_term_set_t));[m
[32m+[m[32m  memset(set, 0, sizeof(*set));[m
[32m+[m
[32m+[m[32m  bool switch_set = false;[m
[32m+[m[32m  bool after_bar = false;[m
[32m+[m[32m  while (ptr != NULL) {[m
[32m+[m[32m    fzf_algo_t fn = fzf_fuzzy_match_v2;[m
[32m+[m[32m    bool inv = false;[m
[32m+[m
[32m+[m[32m    size_t len = strlen(ptr);[m
[32m+[m[32m    str_replace_char(ptr, '\t', ' ');[m
[32m+[m[32m    char* text = malloc(len + 1);[m
[32m+[m[32m    if (text == NULL)[m
[32m+[m[32m    {[m
[32m+[m[32m      return NULL;[m
[32m+[m[32m    }[m
[32m+[m[32m    strcpy(text, ptr);[m
[32m+[m[32m    //char *text = strdup(ptr);[m
[32m+[m
[32m+[m[32m    char *og_str = text;[m
[32m+[m[32m    char *lower_text = str_tolower(text, len);[m
[32m+[m[32m    bool case_sensitive =[m
[32m+[m[32m        case_mode == CaseRespect ||[m
[32m+[m[32m        (case_mode == CaseSmart && strcmp(text, lower_text) != 0);[m
[32m+[m[32m    if (!case_sensitive) {[m
[32m+[m[32m      SFREE(text);[m
[32m+[m[32m      text = lower_text;[m
[32m+[m[32m      og_str = lower_text;[m
[32m+[m[32m    } else {[m
[32m+[m[32m      SFREE(lower_text);[m
[32m+[m[32m    }[m
[32m+[m[32m    if (!fuzzy) {[m
[32m+[m[32m      fn = fzf_exact_match_naive;[m
[32m+[m[32m    }[m
[32m+[m[32m    if (set->size > 0 && !after_bar && strcmp(text, "|") == 0) {[m
[32m+[m[32m      switch_set = false;[m
[32m+[m[32m      after_bar = true;[m
[32m+[m[32m      ptr = strtok(NULL, delim);[m
[32m+[m[32m      SFREE(og_str);[m
[32m+[m[32m      continue;[m
[32m+[m[32m    }[m
[32m+[m[32m    after_bar = false;[m
[32m+[m[32m    if (has_prefix(text, "!", 1)) {[m
[32m+[m[32m      inv = true;[m
[32m+[m[32m      fn = fzf_exact_match_naive;[m
[32m+[m[32m      text++;[m
[32m+[m[32m      len--;[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    if (strcmp(text, "$") != 0 && has_suffix(text, len, "$", 1)) {[m
[32m+[m[32m      fn = fzf_suffix_match;[m
[32m+[m[32m      text[len - 1] = 0;[m
[32m+[m[32m      len--;[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    if (has_prefix(text, "'", 1)) {[m
[32m+[m[32m      if (fuzzy && !inv) {[m
[32m+[m[32m        fn = fzf_exact_match_naive;[m
[32m+[m[32m        text++;[m
[32m+[m[32m        len--;[m
[32m+[m[32m      } else {[m
[32m+[m[32m        fn = fzf_fuzzy_match_v2;[m
[32m+[m[32m        text++;[m
[32m+[m[32m        len--;[m
[32m+[m[32m      }[m
[32m+[m[32m    } else if (has_prefix(text, "^", 1)) {[m
[32m+[m[32m      if (fn == fzf_suffix_match) {[m
[32m+[m[32m        fn = fzf_equal_match;[m
[32m+[m[32m      } else {[m
[32m+[m[32m        fn = fzf_prefix_match;[m
[32m+[m[32m      }[m
[32m+[m[32m      text++;[m
[32m+[m[32m      len--;[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    if (len > 0) {[m
[32m+[m[32m      if (switch_set) {[m
[32m+[m[32m        append_pattern(pat_obj, set);[m
[32m+[m[32m        set = (fzf_term_set_t *)malloc(sizeof(fzf_term_set_t));[m
[32m+[m[32m        set->cap = 0;[m
[32m+[m[32m        set->size = 0;[m
[32m+[m[32m      }[m
[32m+[m[32m      fzf_string_t *text_ptr = (fzf_string_t *)malloc(sizeof(fzf_string_t));[m
[32m+[m[32m      text_ptr->data = text;[m
[32m+[m[32m      text_ptr->size = len;[m
[32m+[m[32m      append_set(set, (fzf_term_t){.fn = fn,[m
[32m+[m[32m                                   .inv = inv,[m
[32m+[m[32m                                   .ptr = og_str,[m
[32m+[m[32m                                   .text = text_ptr,[m
[32m+[m[32m                                   .case_sensitive = case_sensitive});[m
[32m+[m[32m      switch_set = true;[m
[32m+[m[32m    } else {[m
[32m+[m[32m      SFREE(og_str);[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    ptr = strtok(NULL, delim);[m
[32m+[m[32m  }[m
[32m+[m[32m  if (set->size > 0) {[m
[32m+[m[32m    append_pattern(pat_obj, set);[m
[32m+[m[32m  } else {[m
[32m+[m[32m    SFREE(set->ptr);[m
[32m+[m[32m    SFREE(set);[m
[32m+[m[32m  }[m
[32m+[m[32m  bool only = true;[m
[32m+[m[32m  for (size_t i = 0; i < pat_obj->size; i++) {[m
[32m+[m[32m    fzf_term_set_t *term_set = pat_obj->ptr[i];[m
[32m+[m[32m    if (term_set->size > 1) {[m
[32m+[m[32m      only = false;[m
[32m+[m[32m      break;[m
[32m+[m[32m    }[m
[32m+[m[32m    if (term_set->ptr[0].inv == false) {[m
[32m+[m[32m      only = false;[m
[32m+[m[32m      break;[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m[32m  pat_obj->only_inv = only;[m
[32m+[m[32m  SFREE(pattern_copy);[m
[32m+[m[32m  return pat_obj;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mvoid fzf_free_pattern(fzf_pattern_t *pattern) {[m
[32m+[m[32m  if (pattern->ptr) {[m
[32m+[m[32m    for (size_t i = 0; i < pattern->size; i++) {[m
[32m+[m[32m      fzf_term_set_t *term_set = pattern->ptr[i];[m
[32m+[m[32m      for (size_t j = 0; j < term_set->size; j++) {[m
[32m+[m[32m        fzf_term_t *term = &term_set->ptr[j];[m
[32m+[m[32m        free(term->ptr);[m
[32m+[m[32m        free(term->text);[m
[32m+[m[32m      }[m
[32m+[m[32m      free(term_set->ptr);[m
[32m+[m[32m      free(term_set);[m
[32m+[m[32m    }[m
[32m+[m[32m    free(pattern->ptr);[m
[32m+[m[32m  }[m
[32m+[m[32m  SFREE(pattern);[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mint32_t fzf_get_score(const char *text, fzf_pattern_t *pattern,[m
[32m+[m[32m                      fzf_slab_t *slab) {[m
[32m+[m[32m  // If the pattern is an empty string then pattern->ptr will be NULL and we[m
[32m+[m[32m  // basically don't want to filter. Return 1 for telescope[m
[32m+[m[32m  if (pattern->ptr == NULL) {[m
[32m+[m[32m    return 1;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  fzf_string_t input = {.data = text, .size = strlen(text)};[m
[32m+[m[32m  if (pattern->only_inv) {[m
[32m+[m[32m    int final = 0;[m
[32m+[m[32m    for (size_t i = 0; i < pattern->size; i++) {[m
[32m+[m[32m      fzf_term_set_t *term_set = pattern->ptr[i];[m
[32m+[m[32m      fzf_term_t *term = &term_set->ptr[0];[m
[32m+[m
[32m+[m[32m      final += CALL_ALG(term, false, input, NULL, slab).score;[m
[32m+[m[32m    }[m
[32m+[m[32m    return (final > 0) ? 0 : 1;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  int32_t total_score = 0;[m
[32m+[m[32m  for (size_t i = 0; i < pattern->size; i++) {[m
[32m+[m[32m    fzf_term_set_t *term_set = pattern->ptr[i];[m
[32m+[m[32m    int32_t current_score = 0;[m
[32m+[m[32m    bool matched = false;[m
[32m+[m[32m    for (size_t j = 0; j < term_set->size; j++) {[m
[32m+[m[32m      fzf_term_t *term = &term_set->ptr[j];[m
[32m+[m[32m      fzf_result_t res = CALL_ALG(term, false, input, NULL, slab);[m
[32m+[m[32m      if (res.start >= 0) {[m
[32m+[m[32m        if (term->inv) {[m
[32m+[m[32m          continue;[m
[32m+[m[32m        }[m
[32m+[m[32m        current_score = res.score;[m
[32m+[m[32m        matched = true;[m
[32m+[m[32m        break;[m
[32m+[m[32m      }[m
[32m+[m
[32m+[m[32m      if (term->inv) {[m
[32m+[m[32m        current_score = 0;[m
[32m+[m[32m        matched = true;[m
[32m+[m[32m      }[m
[32m+[m[32m    }[m
[32m+[m[32m    if (matched) {[m
[32m+[m[32m      total_score += current_score;[m
[32m+[m[32m    } else {[m
[32m+[m[32m      total_score = 0;[m
[32m+[m[32m      break;[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  return total_score;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mfzf_position_t *fzf_get_positions(const char *text, fzf_pattern_t *pattern,[m
[32m+[m[32m                                  fzf_slab_t *slab) {[m
[32m+[m[32m  // If the pattern is an empty string then pattern->ptr will be NULL and we[m
[32m+[m[32m  // basically don't want to filter. Return 1 for telescope[m
[32m+[m[32m  if (pattern->ptr == NULL) {[m
[32m+[m[32m    return NULL;[m
[32m+[m[32m  }[m
[32m+[m
[32m+[m[32m  fzf_string_t input = {.data = text, .size = strlen(text)};[m
[32m+[m[32m  fzf_position_t *all_pos = fzf_pos_array(0);[m
[32m+[m[32m  for (size_t i = 0; i < pattern->size; i++) {[m
[32m+[m[32m    fzf_term_set_t *term_set = pattern->ptr[i];[m
[32m+[m[32m    bool matched = false;[m
[32m+[m[32m    for (size_t j = 0; j < term_set->size; j++) {[m
[32m+[m[32m      fzf_term_t *term = &term_set->ptr[j];[m
[32m+[m[32m      if (term->inv) {[m
[32m+[m[32m        // If we have an inverse term we need to check if we have a match, but[m
[32m+[m[32m        // we are not interested in the positions (for highlights) so to speed[m
[32m+[m[32m        // this up we can pass in NULL here and don't calculate the positions[m
[32m+[m[32m        fzf_result_t res = CALL_ALG(term, false, input, NULL, slab);[m
[32m+[m[32m        if (res.start < 0) {[m
[32m+[m[32m          matched = true;[m
[32m+[m[32m        }[m
[32m+[m[32m        continue;[m
[32m+[m[32m      }[m
[32m+[m[32m      fzf_result_t res = CALL_ALG(term, false, input, all_pos, slab);[m
[32m+[m[32m      if (res.start >= 0) {[m
[32m+[m[32m        matched = true;[m
[32m+[m[32m        break;[m
[32m+[m[32m      }[m
[32m+[m[32m    }[m
[32m+[m[32m    if (!matched) {[m
[32m+[m[32m      fzf_free_positions(all_pos);[m
[32m+[m[32m      return NULL;[m
[32m+[m[32m    }[m
[32m+[m[32m  }[m
[32m+[m[32m  return all_pos;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mvoid fzf_free_positions(fzf_position_t *pos) {[m
[32m+[m[32m  if (pos) {[m
[32m+[m[32m    SFREE(pos->data);[m
[32m+[m[32m    free(pos);[m
[32m+[m[32m  }[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mfzf_slab_t *fzf_make_slab(fzf_slab_config_t config) {[m
[32m+[m[32m  fzf_slab_t *slab = (fzf_slab_t *)malloc(sizeof(fzf_slab_t));[m
[32m+[m[32m  memset(slab, 0, sizeof(*slab));[m
[32m+[m
[32m+[m[32m  slab->I16.data = (int16_t *)malloc(config.size_16 * sizeof(int16_t));[m
[32m+[m[32m  memset(slab->I16.data, 0, config.size_16 * sizeof(*slab->I16.data));[m
[32m+[m[32m  slab->I16.cap = config.size_16;[m
[32m+[m[32m  slab->I16.size = 0;[m
[32m+[m[32m  slab->I16.allocated = true;[m
[32m+[m
[32m+[m[32m  slab->I32.data = (int32_t *)malloc(config.size_32 * sizeof(int32_t));[m
[32m+[m[32m  memset(slab->I32.data, 0, config.size_32 * sizeof(*slab->I32.data));[m
[32m+[m[32m  slab->I32.cap = config.size_32;[m
[32m+[m[32m  slab->I32.size = 0;[m
[32m+[m[32m  slab->I32.allocated = true;[m
[32m+[m
[32m+[m[32m  return slab;[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mfzf_slab_t *fzf_make_default_slab(void) {[m
[32m+[m[32m  return fzf_make_slab((fzf_slab_config_t){(size_t)100 * 1024, 2048});[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mvoid fzf_free_slab(fzf_slab_t *slab) {[m
[32m+[m[32m  if (slab) {[m
[32m+[m[32m    free(slab->I16.data);[m
[32m+[m[32m    free(slab->I32.data);[m
[32m+[m[32m    free(slab);[m
[32m+[m[32m  }[m
[32m+[m[32m}[m
[32m+[m[32m#pragma warning(pop)[m
[32m+[m[32m#undef _CRT_SECURE_NO_WARNINGS[m
[1mdiff --git a/src/cascadia/TerminalControl/fzf/fzf.h b/src/cascadia/TerminalControl/fzf/fzf.h[m
[1mnew file mode 100644[m
[1mindex 000000000..fa309401d[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalControl/fzf/fzf.h[m
[36m@@ -0,0 +1,119 @@[m
[32m+[m[32m#ifdef __cplusplus[m
[32m+[m[32mextern "C" {[m
[32m+[m[32m#endif[m
[32m+[m
[32m+[m[32m#ifndef FZF_H_[m
[32m+[m[32m#define FZF_H_[m
[32m+[m
[32m+[m[32m#include <stdbool.h>[m
[32m+[m[32m#include <stdint.h>[m
[32m+[m[32m#include <stddef.h>[m
[32m+[m
[32m+[m[32mtypedef struct {[m
[32m+[m[32m  int16_t *data;[m
[32m+[m[32m  size_t size;[m
[32m+[m[32m  size_t cap;[m
[32m+[m[32m  bool allocated;[m
[32m+[m[32m} fzf_i16_t;[m
[32m+[m
[32m+[m[32mtypedef struct {[m
[32m+[m[32m  int32_t *data;[m
[32m+[m[32m  size_t size;[m
[32m+[m[32m  size_t cap;[m
[32m+[m[32m  bool allocated;[m
[32m+[m[32m} fzf_i32_t;[m
[32m+[m
[32m+[m[32mtypedef struct {[m
[32m+[m[32m  uint32_t *data;[m
[32m+[m[32m  size_t size;[m
[32m+[m[32m  size_t cap;[m
[32m+[m[32m} fzf_position_t;[m
[32m+[m
[32m+[m[32mtypedef struct {[m
[32m+[m[32m  int32_t start;[m
[32m+[m[32m  int32_t end;[m
[32m+[m[32m  int32_t score;[m
[32m+[m[32m} fzf_result_t;[m
[32m+[m
[32m+[m[32mtypedef struct {[m
[32m+[m[32m  fzf_i16_t I16;[m
[32m+[m[32m  fzf_i32_t I32;[m
[32m+[m[32m} fzf_slab_t;[m
[32m+[m
[32m+[m[32mtypedef struct {[m
[32m+[m[32m  size_t size_16;[m
[32m+[m[32m  size_t size_32;[m
[32m+[m[32m} fzf_slab_config_t;[m
[32m+[m
[32m+[m[32mtypedef struct {[m
[32m+[m[32m  const char *data;[m
[32m+[m[32m  size_t size;[m
[32m+[m[32m} fzf_string_t;[m
[32m+[m
[32m+[m[32mtypedef fzf_result_t (*fzf_algo_t)(bool, bool, fzf_string_t *, fzf_string_t *,[m
[32m+[m[32m                                   fzf_position_t *, fzf_slab_t *);[m
[32m+[m
[32m+[m[32mtypedef enum { CaseSmart = 0, CaseIgnore, CaseRespect } fzf_case_types;[m
[32m+[m
[32m+[m[32mtypedef struct {[m
[32m+[m[32m  fzf_algo_t fn;[m
[32m+[m[32m  bool inv;[m
[32m+[m[32m  char *ptr;[m
[32m+[m[32m  void *text;[m
[32m+[m[32m  bool case_sensitive;[m
[32m+[m[32m} fzf_term_t;[m
[32m+[m
[32m+[m[32mtypedef struct {[m
[32m+[m[32m  fzf_term_t *ptr;[m
[32m+[m[32m  size_t size;[m
[32m+[m[32m  size_t cap;[m
[32m+[m[32m} fzf_term_set_t;[m
[32m+[m
[32m+[m[32mtypedef struct {[m
[32m+[m[32m  fzf_term_set_t **ptr;[m
[32m+[m[32m  size_t size;[m
[32m+[m[32m  size_t cap;[m
[32m+[m[32m  bool only_inv;[m
[32m+[m[32m} fzf_pattern_t;[m
[32m+[m
[32m+[m[32mfzf_result_t fzf_fuzzy_match_v1(bool case_sensitive, bool normalize,[m
[32m+[m[32m                                fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                                fzf_position_t *pos, fzf_slab_t *slab);[m
[32m+[m[32mfzf_result_t fzf_fuzzy_match_v2(bool case_sensitive, bool normalize,[m
[32m+[m[32m                                fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                                fzf_position_t *pos, fzf_slab_t *slab);[m
[32m+[m[32mfzf_result_t fzf_exact_match_naive(bool case_sensitive, bool normalize,[m
[32m+[m[32m                                   fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                                   fzf_position_t *pos, fzf_slab_t *slab);[m
[32m+[m[32mfzf_result_t fzf_prefix_match(bool case_sensitive, bool normalize,[m
[32m+[m[32m                              fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                              fzf_position_t *pos, fzf_slab_t *slab);[m
[32m+[m[32mfzf_result_t fzf_suffix_match(bool case_sensitive, bool normalize,[m
[32m+[m[32m                              fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                              fzf_position_t *pos, fzf_slab_t *slab);[m
[32m+[m[32mfzf_result_t fzf_equal_match(bool case_sensitive, bool normalize,[m
[32m+[m[32m                             fzf_string_t *text, fzf_string_t *pattern,[m
[32m+[m[32m                             fzf_position_t *pos, fzf_slab_t *slab);[m
[32m+[m
[32m+[m[32m/* interface */[m
[32m+[m[32mfzf_pattern_t *fzf_parse_pattern(fzf_case_types case_mode, bool normalize,[m
[32m+[m[32m                                 char *pattern, bool fuzzy);[m
[32m+[m[32mvoid fzf_free_pattern(fzf_pattern_t *pattern);[m
[32m+[m
[32m+[m[32mint32_t fzf_get_score(const char *text, fzf_pattern_t *pattern,[m
[32m+[m[32m                      fzf_slab_t *slab);[m
[32m+[m
[32m+[m[32mfzf_position_t *fzf_pos_array(size_t len);[m
[32m+[m[32mfzf_position_t *fzf_get_positions(const char *text, fzf_pattern_t *pattern,[m
[32m+[m[32m                                  fzf_slab_t *slab);[m
[32m+[m[32mvoid fzf_free_positions(fzf_position_t *pos);[m
[32m+[m
[32m+[m[32mfzf_slab_t *fzf_make_slab(fzf_slab_config_t config);[m
[32m+[m[32mfzf_slab_t *fzf_make_default_slab(void);[m
[32m+[m[32mvoid fzf_free_slab(fzf_slab_t *slab);[m
[32m+[m
[32m+[m[32m#endif // FZF_H_[m
[32m+[m
[32m+[m[32m#ifdef __cplusplus[m
[32m+[m[32m}[m
[32m+[m[32m#endif[m
[1mdiff --git a/src/cascadia/TerminalCore/FuzzySearchRenderData.cpp b/src/cascadia/TerminalCore/FuzzySearchRenderData.cpp[m
[1mnew file mode 100644[m
[1mindex 000000000..2a348affa[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalCore/FuzzySearchRenderData.cpp[m
[36m@@ -0,0 +1,219 @@[m
[32m+[m[32m#pragma once[m[41m[m
[32m+[m[32m#include "pch.h"[m[41m[m
[32m+[m[32m#include "FuzzySearchRenderData.hpp"[m[41m[m
[32m+[m[41m[m
[32m+[m[32mFuzzySearchRenderData::FuzzySearchRenderData(IRenderData* pData) :[m[41m[m
[32m+[m[32m    _pData(pData)[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    auto vp = Microsoft::Console::Types::Viewport{};[m[41m[m
[32m+[m[32m    _viewPort = vp.FromDimensions(til::point{ 0, 5 }, _size);[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mvoid FuzzySearchRenderData::Show()[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    TextAttribute ta{};[m[41m[m
[32m+[m[32m    auto tb = std::make_unique<TextBuffer>(_size, ta, 0, true, *_renderer);[m[41m[m
[32m+[m[32m    _textBuffer.swap(tb);[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mvoid FuzzySearchRenderData::SetSize(til::size size)[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    _size = size;[m[41m[m
[32m+[m[32m    _viewPort = _viewPort.FromDimensions(til::point{ 0, 0 }, til::size{ _size.width, _size.height });[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mvoid FuzzySearchRenderData::SetRenderer(::Microsoft::Console::Render::Renderer* renderer)[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    _renderer = renderer;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mvoid FuzzySearchRenderData::SetTopRow(til::CoordType row)[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    _row = row;[m[41m[m
[32m+[m[32m    til::CoordType newY;[m[41m[m
[32m+[m[32m    auto textBufferHeight = _textBuffer->GetSize().Height();[m[41m[m
[32m+[m[32m    auto viewPortHeight = _viewPort.Height();[m[41m[m
[32m+[m[32m    if (row + viewPortHeight > textBufferHeight)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        newY = textBufferHeight - viewPortHeight;[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[32m    else[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        newY = std::max(0, row - 3);[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    _viewPort = _viewPort.FromDimensions(til::point{ 0, std::max(0, newY) }, til::size{ _size.width, _size.height });[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mMicrosoft::Console::Types::Viewport FuzzySearchRenderData::GetViewport() noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return _viewPort;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mtil::point FuzzySearchRenderData::GetTextBufferEndPosition() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return {};[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst void FuzzySearchRenderData::SetTextBuffer(std::unique_ptr<TextBuffer> value)[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    _textBuffer.swap(value);[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst TextBuffer& FuzzySearchRenderData::GetTextBuffer() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return *_textBuffer;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst FontInfo& FuzzySearchRenderData::GetFontInfo() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return _pData->GetFontInfo();[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mstd::vector<Microsoft::Console::Types::Viewport> FuzzySearchRenderData::GetSelectionRects() noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    auto rects = _textBuffer->GetTextRects(til::point{ 0, _row }, til::point{ _viewPort.Width() - 1, _row }, false, false);[m[41m[m
[32m+[m[32m    std::vector<Microsoft::Console::Types::Viewport> result;[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    for (const auto& lineRect : rects)[m[41m[m
[32m+[m[32m    {[m[41m[m
[32m+[m[32m        result.emplace_back(Microsoft::Console::Types::Viewport::FromInclusive(lineRect));[m[41m[m
[32m+[m[32m    }[m[41m[m
[32m+[m[41m[m
[32m+[m[32m    return result;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mstd::vector<Microsoft::Console::Types::Viewport> FuzzySearchRenderData::GetSearchSelectionRects() noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return std::vector<Microsoft::Console::Types::Viewport>{};[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32m[[nodiscard]] std::unique_lock<til::recursive_ticket_lock> FuzzySearchRenderData::LockForReading() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m#pragma warning(suppress : 26447) // The function is declared 'noexcept' but calls function 'recursive_ticket_lock>()' which may throw exceptions (f.6).[m[41m[m
[32m+[m[32m#pragma warning(suppress : 26492) // Don't use const_cast to cast away const or volatile[m[41m[m
[32m+[m[32m    return std::unique_lock{ const_cast<til::recursive_ticket_lock&>(_readWriteLock) };[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32m[[nodiscard]] std::unique_lock<til::recursive_ticket_lock> FuzzySearchRenderData::LockForWriting() noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m#pragma warning(suppress : 26447) // The function is declared 'noexcept' but calls function 'recursive_ticket_lock>()' which may throw exceptions (f.6).[m[41m[m
[32m+[m[32m    return std::unique_lock{ _readWriteLock };[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mvoid FuzzySearchRenderData::LockConsole() noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    _readWriteLock.lock();[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mvoid FuzzySearchRenderData::UnlockConsole() noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    _readWriteLock.unlock();[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mstd::pair<COLORREF, COLORREF> FuzzySearchRenderData::GetAttributeColors(const TextAttribute& attr) const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return _pData->GetAttributeColors(attr);[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mtil::point FuzzySearchRenderData::GetCursorPosition() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return {};[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mbool FuzzySearchRenderData::IsCursorVisible() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return false;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mbool FuzzySearchRenderData::IsCursorOn() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return false;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mULONG FuzzySearchRenderData::GetCursorHeight() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return 42ul;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mCursorType FuzzySearchRenderData::GetCursorStyle() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return CursorType::FullBox;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mULONG FuzzySearchRenderData::GetCursorPixelWidth() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return 12ul;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mbool FuzzySearchRenderData::IsCursorDoubleWidth() const[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return false;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst std::vector<Microsoft::Console::Render::RenderOverlay> FuzzySearchRenderData::GetOverlays() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return std::vector<Microsoft::Console::Render::RenderOverlay>{};[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst bool FuzzySearchRenderData::IsGridLineDrawingAllowed() noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return false;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst std::wstring_view FuzzySearchRenderData::GetConsoleTitle() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return std::wstring_view{};[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst bool FuzzySearchRenderData::IsSelectionActive() const[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return false;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst bool FuzzySearchRenderData::IsBlockSelection() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return false;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mvoid FuzzySearchRenderData::ClearSelection()[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mvoid FuzzySearchRenderData::SelectNewRegion(const til::point /*coordStart*/, const til::point /*coordEnd*/)[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mvoid FuzzySearchRenderData::SelectSearchRegions(std::vector<til::inclusive_rect> /*source*/)[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst til::point FuzzySearchRenderData::GetSelectionAnchor() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return {};[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst til::point FuzzySearchRenderData::GetSelectionEnd() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return {};[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst bool FuzzySearchRenderData::IsUiaDataInitialized() const noexcept[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return true;[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst std::wstring FuzzySearchRenderData::GetHyperlinkUri(uint16_t /*id*/) const[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return {};[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst std::wstring FuzzySearchRenderData::GetHyperlinkCustomId(uint16_t /*id*/) const[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return {};[m[41m[m
[32m+[m[32m}[m[41m[m
[32m+[m[41m[m
[32m+[m[32mconst std::vector<size_t> FuzzySearchRenderData::GetPatternId(const til::point /*location*/) const[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32m    return {};[m[41m[m
[32m+[m[32m}[m[41m[m
[1mdiff --git a/src/cascadia/TerminalCore/FuzzySearchRenderData.hpp b/src/cascadia/TerminalCore/FuzzySearchRenderData.hpp[m
[1mnew file mode 100644[m
[1mindex 000000000..d5f44603e[m
[1m--- /dev/null[m
[1m+++ b/src/cascadia/TerminalCore/FuzzySearchRenderData.hpp[m
[36m@@ -0,0 +1,58 @@[m
[32m+[m[32m#pragma once[m[41m[m
[32m+[m[41m[m
[32m+[m[32m#include "../../buffer/out/textBuffer.hpp"[m[41m[m
[32m+[m[32m#include "../../renderer/inc/IRenderData.hpp"[m[41m[m
[32m+[m[32m#include "../../types/inc/Viewport.hpp"[m[41m[m
[32m+[m[32m#include <til/ticket_lock.h>[m[41m[m
[32m+[m[41m[m
[32m+[m[32mclass FuzzySearchRenderData : public Microsoft::Console::Render::IRenderData[m[41m[m
[32m+[m[32m{[m[41m[m
[32m+[m[32mpublic:[m[41m[m
[32m+[m[32m    FuzzySearchRenderData(IRenderData* pData);[m[41m[m
[32m+[m[32m    void Show();[m[41m[m
[32m+[m[32m    void SetSize(til::size size);[m[41m[m
[32m+[m[32m    void SetRenderer(::Microsoft::Console::Render::Renderer* renderer);[m[41m[m
[32m+[m[32m    void SetTopRow(til::CoordType row);[m[41m[m
[32m+[m[32m    Microsoft::Console::Types::Viewport GetViewport() noexcept override;[m[41m[m
[32m+[m[32m    til::point GetTextBufferEndPosition() const noexcept override;[m[41m[m
[32m+[m[32m    const void SetTextBuffer(std::unique_ptr<TextBuffer> value);[m[41m[m
[32m+[m[32m    const TextBuffer& GetTextBuffer() const noexcept override;[m[41m[m
[32m+[m[32m    const FontInfo& GetFontInfo() const noexcept override;[m[41m[m
[32m+[m[32m    std::vector<Microsoft::Console::Types::Viewport> GetSelectionRects() noexcept override;[m[41m[m
[32m+[m[32m    std::vector<Microsoft::Console::Types::Viewport> GetSearchSelectionRects() noexcept override;[m[41m[m
[32m+[m[32m    [[nodiscard]] std::unique_lock<til::recursive_ticket_lock> LockForReading() const noexcept;[m[41m[m
[32m+[m[32m    [[nodiscard]] std::unique_lock<til::recursive_ticket_lock> LockForWriting() noexcept;[m[41m[m
[32m+[m[32m    void LockConsole() noexcept override;[m[41m[m
[32m+[m[32m    void UnlockConsole() noexcept override;[m[41m[m
[32m+[m[32m    std::pair<COLORREF, COLORREF> GetAttributeColors(const TextAttribute& attr) const noexcept override;[m[41m[m
[32m+[m[32m    til::point GetCursorPosition() const noexcept override;[m[41m[m
[32m+[m[32m    bool IsCursorVisible() const noexcept override;[m[41m[m
[32m+[m[32m    bool IsCursorOn() const noexcept override;[m[41m[m
[32m+[m[32m    ULONG GetCursorHeight() const noexcept override;[m[41m[m
[32m+[m[32m    CursorType GetCursorStyle() const noexcept override;[m[41m[m
[32m+[m[32m    ULONG GetCursorPixelWidth() const noexcept override;[m[41m[m
[32m+[m[32m    bool IsCursorDoubleWidth() const override;[m[41m[m
[32m+[m[32m    const std::vector<Microsoft::Console::Render::RenderOverlay> GetOverlays() const noexcept override;[m[41m[m
[32m+[m[32m    const bool IsGridLineDrawingAllowed() noexcept override;[m[41m[m
[32m+[m[32m    const std::wstring_view GetConsoleTitle() const noexcept override;[m[41m[m
[32m+[m[32m    const bool IsSelectionActive() const override;[m[41m[m
[32m+[m[32m    const bool IsBlockSelection() const noexcept override;[m[41m[m
[32m+[m[32m    void ClearSelection() override;[m[41m[m
[32m+[m[32m    void SelectNewRegion(const til::point /*coordStart*/, const til::point /*coordEnd*/) override;[m[41m[m
[32m+[m[32m    void SelectSearchRegions(std::vector<til::inclusive_rect> /*source*/) override;[m[41m[m
[32m+[m[32m    const til::point GetSelectionAnchor() const noexcept;[m[41m[m
[32m+[m[32m    const til::point GetSelectionEnd() const noexcept;[m[41m[m
[32m+[m[32m    const bool IsUiaDataInitialized() const noexcept;[m[41m[m
[32m+[m[32m    const std::wstring GetHyperlinkUri(uint16_t /*id*/) const;[m[41m[m
[32m+[m[32m    const std::wstring GetHyperlinkCustomId(uint16_t /*id*/) const;[m[41m[m
[32m+[m[32m    const std::vector<size_t> GetPatternId(const til::point /*location*/) const;[m[41m[m
[32m+[m[41m[m
[32m+[m[32mprivate:[m[41m[m
[32m+[m[32m    IRenderData* _pData;[m[41m[m
[32m+[m[32m    ::Microsoft::Console::Render::Renderer* _renderer = nullptr;[m[41m[m
[32m+[m[32m    std::unique_ptr<TextBuffer> _textBuffer;[m[41m[m
[32m+[m[32m    Microsoft::Console::Types::Viewport _viewPort;[m[41m[m
[32m+[m[32m    til::size _size;[m[41m[m
[32m+[m[32m    til::CoordType _row;[m[41m[m
[32m+[m[32m    til::recursive_ticket_lock _readWriteLock;[m[41m[m
[32m+[m[32m};[m[41m[m
[1mdiff --git a/src/cascadia/TerminalCore/terminalcore-common.vcxitems b/src/cascadia/TerminalCore/terminalcore-common.vcxitems[m
[1mindex 625805e72..a8982eb08 100644[m
[1m--- a/src/cascadia/TerminalCore/terminalcore-common.vcxitems[m
[1m+++ b/src/cascadia/TerminalCore/terminalcore-common.vcxitems[m
[36m@@ -6,6 +6,7 @@[m
     <ClCompile Include="..\TerminalSelection.cpp" />[m
     <ClCompile Include="..\TerminalApi.cpp" />[m
     <ClCompile Include="..\Terminal.cpp" />[m
[32m+[m[32m    <ClCompile Include="..\FuzzySearchRenderData.cpp" />[m[41m[m
     <ClCompile Include="..\pch.cpp">[m
       <PrecompiledHeader>Create</PrecompiledHeader>[m
     </ClCompile>[m
[36m@@ -16,6 +17,7 @@[m
     <ClInclude Include="..\pch.h" />[m
     <ClInclude Include="..\Terminal.hpp" />[m
     <ClInclude Include="..\tracing.hpp" />[m
[32m+[m[32m    <ClInclude Include="..\FuzzySearchRenderData.hpp" />[m[41m[m
   </ItemGroup>[m
 [m
 </Project>[m
[1mdiff --git a/src/cascadia/TerminalSettingsModel/ActionAndArgs.cpp b/src/cascadia/TerminalSettingsModel/ActionAndArgs.cpp[m
[1mindex e90a2b8dc..902734e5a 100644[m
[1m--- a/src/cascadia/TerminalSettingsModel/ActionAndArgs.cpp[m
[1m+++ b/src/cascadia/TerminalSettingsModel/ActionAndArgs.cpp[m
[36m@@ -20,6 +20,7 @@[m [mstatic constexpr std::string_view CopyTextKey{ "copy" };[m
 static constexpr std::string_view DuplicateTabKey{ "duplicateTab" };[m
 static constexpr std::string_view ExecuteCommandlineKey{ "wt" };[m
 static constexpr std::string_view FindKey{ "find" };[m
[32m+[m[32mstatic constexpr std::string_view FuzzyFindKey{ "fuzzyFind" };[m
 static constexpr std::string_view MoveFocusKey{ "moveFocus" };[m
 static constexpr std::string_view MovePaneKey{ "movePane" };[m
 static constexpr std::string_view SwapPaneKey{ "swapPane" };[m
[36m@@ -355,6 +356,7 @@[m [mnamespace winrt::Microsoft::Terminal::Settings::Model::implementation[m
                 { ShortcutAction::DuplicateTab, RS_(L"DuplicateTabCommandKey") },[m
                 { ShortcutAction::ExecuteCommandline, RS_(L"ExecuteCommandlineCommandKey") },[m
                 { ShortcutAction::Find, RS_(L"FindCommandKey") },[m
[32m+[m[32m                { ShortcutAction::FuzzyFind, RS_(L"FuzzyFindCommandKey") },[m
                 { ShortcutAction::Invalid, MustGenerate },[m
                 { ShortcutAction::MoveFocus, RS_(L"MoveFocusCommandKey") },[m
                 { ShortcutAction::MovePane, RS_(L"MovePaneCommandKey") },[m
[1mdiff --git a/src/cascadia/TerminalSettingsModel/AllShortcutActions.h b/src/cascadia/TerminalSettingsModel/AllShortcutActions.h[m
[1mindex f9d934e36..60a9d54a8 100644[m
[1m--- a/src/cascadia/TerminalSettingsModel/AllShortcutActions.h[m
[1m+++ b/src/cascadia/TerminalSettingsModel/AllShortcutActions.h[m
[36m@@ -56,6 +56,7 @@[m
     ON_ALL_ACTIONS(MovePane)                \[m
     ON_ALL_ACTIONS(SwapPane)                \[m
     ON_ALL_ACTIONS(Find)                    \[m
[32m+[m[32m    ON_ALL_ACTIONS(FuzzyFind)               \[m[41m[m
     ON_ALL_ACTIONS(ToggleShaderEffects)     \[m
     ON_ALL_ACTIONS(ToggleFocusMode)         \[m
     ON_ALL_ACTIONS(ToggleFullscreen)        \[m
[1mdiff --git a/src/cascadia/TerminalSettingsModel/Resources/en-US/Resources.resw b/src/cascadia/TerminalSettingsModel/Resources/en-US/Resources.resw[m
[1mindex d6d6d9565..7f3060863 100644[m
[1m--- a/src/cascadia/TerminalSettingsModel/Resources/en-US/Resources.resw[m
[1m+++ b/src/cascadia/TerminalSettingsModel/Resources/en-US/Resources.resw[m
[36m@@ -243,6 +243,9 @@[m
   <data name="FindPrevCommandKey" xml:space="preserve">[m
     <value>Find previous search match</value>[m
   </data>[m
[32m+[m[32m  <data name="FuzzyFindCommandKey" xml:space="preserve">[m[41m[m
[32m+[m[32m    <value>Fuzzy Find</value>[m[41m[m
[32m+[m[32m  </data>[m[41m[m
   <data name="IncreaseFontSizeCommandKey" xml:space="preserve">[m
     <value>Increase font size</value>[m
   </data>[m
