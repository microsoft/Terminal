#include "pch.h"
#include "TSFInputControl.h"
#include "TSFInputControl.g.cpp"

using namespace winrt::Windows::Foundation;
using namespace winrt::Windows::Graphics::Display;
using namespace winrt::Windows::UI::Core;
using namespace winrt::Windows::UI::Text;
using namespace winrt::Windows::UI::Text::Core;
using namespace winrt::Windows::UI::Xaml;

namespace winrt::Microsoft::Terminal::TerminalControl::implementation
{

    TSFInputControl::TSFInputControl() :
        _editContext{ nullptr }
    {
        _Create();
    }

    // Method Description:
    // - Creates XAML controls for displaying user input and hooks up CoreTextEditContext handlers
    //   for handling text input from the Text Services Framework.
    // Arguments:
    // - <none>
    // Return Value:
    // - <none>
    void TSFInputControl::_Create()
    {
        // TextBlock for user input form TSF
        _textBlock = Controls::TextBlock();
        _textBlock.Visibility(Visibility::Collapsed);
        _textBlock.IsTextSelectionEnabled(false);
        _textBlock.TextDecorations(TextDecorations::Underline);

        // canvas for controlling exact position of the TextBlock
        _canvas = Windows::UI::Xaml::Controls::Canvas();
        _canvas.Visibility(Visibility::Collapsed);

        // add the textblock to the canvas
        _canvas.Children().Append(_textBlock);

        // set the content of this control to be the canvas
        this->Content(_canvas);

        // Create a CoreTextEditingContext for since we are like a custom edit control
        auto manager = Core::CoreTextServicesManager::GetForCurrentView();
        _editContext = manager.CreateEditContext();

        // sets the Input Pane display policy to Manual for now so that it can manually show the
        // software keyboard when the control gains focus and dismiss it when the control loses focus.
        // Should look at Automatic int he Future Add WI TODO
        _editContext.InputPaneDisplayPolicy(Core::CoreTextInputPaneDisplayPolicy::Manual);

        // set the input scope to Text because this control is for any text.
        _editContext.InputScope(Core::CoreTextInputScope::Text);

        _editContext.TextRequested({ this, &TSFInputControl::_textRequestedHandler });

        _editContext.SelectionRequested({ this, &TSFInputControl::_selectionRequestedHandler });

        _editContext.FocusRemoved({ this, &TSFInputControl::_focusRemovedHandler });

        _editContext.TextUpdating({ this, &TSFInputControl::_textUpdatingHandler });

        _editContext.SelectionUpdating({ this, &TSFInputControl::_selectionUpdatingHandler });

        _editContext.FormatUpdating({ this, &TSFInputControl::_formatUpdatingHandler });

        _editContext.LayoutRequested({ this, &TSFInputControl::_layoutRequestedHandler });

        _editContext.CompositionStarted({ this, &TSFInputControl::_compositionStartedHandler });

        _editContext.CompositionCompleted({ this, &TSFInputControl::_compositionCompletedHandler });
    }

    Windows::UI::Xaml::DependencyProperty TSFInputControl::_fontHeightProperty =
        Windows::UI::Xaml::DependencyProperty::Register(
            L"FontHeight",
            winrt::xaml_typename<double>(),
            winrt::xaml_typename<TerminalControl::TSFInputControl>(),
            nullptr);

    Windows::UI::Xaml::DependencyProperty TSFInputControl::_fontWidthProperty =
        Windows::UI::Xaml::DependencyProperty::Register(
            L"FontWidth",
            winrt::xaml_typename<double>(),
            winrt::xaml_typename<TerminalControl::TSFInputControl>(),
            nullptr);

    // Method Description:
    // - NotifyFocusEnter handler for notifying CoreEditTextContext of focus enter
    //   when TerminalControl receives focus.
    // Arguments:
    // - <none>
    // Return Value:
    // - <none>
    void TSFInputControl::NotifyFocusEnter()
    {
        if (_editContext != nullptr)
        {
            OutputDebugString(L"_NotifyFocusEnter\n");
            _editContext.NotifyFocusEnter();
        }
    }

    // Method Description:
    // - NotifyFocusEnter handler for notifying CoreEditTextContext of focus leaving.
    //   when TerminalControl no longer has focus.
    // Arguments:
    // - <none>
    // Return Value:
    // - <none>
    void TSFInputControl::NotifyFocusLeave()
    {
        if (_editContext != nullptr)
        {
            OutputDebugString(L"_NotifyFocusLeave\n");
            //_editContext.NotifyFocusLeave();
        }
    }

    // Method Description:
    // - Scales a Rect based on a scale factor
    // Arguments:
    // - rect: Rect to scale by scale
    // - scale: amount to scale rect by
    // Return Value:
    // - Rect scaled by scale
    inline Rect ScaleRect(Rect rect, double scale)
    {
        const float scaleLocal = gsl::narrow<float>(scale);
        rect.X *= scaleLocal;
        rect.Y *= scaleLocal;
        rect.Width *= scaleLocal;
        rect.Height *= scaleLocal;
        return rect;
    }

    // Method Description:
    // - Converts a COLORREF to Color
    // Arguments:
    // - colorref: COLORREF to convert to Color
    // Return Value:
    // - Color containing the RGB values from colorref
    inline winrt::Windows::UI::Color ColorRefToColor(const COLORREF& colorref)
    {
        winrt::Windows::UI::Color color;
        color.R = GetRValue(colorref);
        color.G = GetGValue(colorref);
        color.B = GetBValue(colorref);
        return color;
    }

    // Method Description:
    // - Handler for LayoutRequested event by CoreEditContext responsible
    //   for returning the current position the IME should be placed
    //   in screen coordinates on the screen.  TSFInputControls internal
    //   XAML controls (TextBlock/Canvas) are also positioned and updated.
    //   NOTE: documentation says application should handle this event
    // Arguments:
    // - sender: CoreTextEditContext sending the request.
    // - args: CoreTextLayoutRequestedEventArgs to be updated with position information.
    // Return Value:
    // - <none>
    void TSFInputControl::_layoutRequestedHandler(CoreTextEditContext sender, CoreTextLayoutRequestedEventArgs const& args)
    {
        OutputDebugString(L"_editContextlayoutRequested\n");
        auto request = args.Request();

        // Get window in screen coordinates, this is the entire window including tabs
        auto windowBounds = Window::Current().CoreWindow().Bounds();

        // Get the cursor position in text buffer position
        auto cursorArgs = winrt::make_self<CursorPositionEventArgs>();
        _currentCursorPositionHandlers(*this, *cursorArgs);
        COORD cursorPos = { gsl::narrow_cast<SHORT>(cursorArgs->CurrentPosition().X), gsl::narrow_cast<SHORT>(cursorArgs->CurrentPosition().Y) }; //_terminal->GetCursorPosition();

        WCHAR buff[100];
        StringCchPrintfW(buff, sizeof(buff), L"Cursor x:%d, y:%d\n", cursorPos.X, cursorPos.Y);
        OutputDebugString(buff);

        // Get Font Info as we use this is the pixel size for characters in the display
        auto fontArgs = winrt::make_self<FontInfoEventArgs>();
        _currentFontInfoHandlers(*this, *fontArgs);

        const float fontWidth = fontArgs->FontSize().X;
        const float fontHeight = fontArgs->FontSize().Y;

        StringCchPrintfW(buff, sizeof(buff), L"Window x:%f,y:%f\n", windowBounds.X, windowBounds.Y);

        OutputDebugString(buff);

        // Convert text buffer cursor position to client coordinate position within the window
        COORD clientCursorPos;
        COORD screenCursorPos;
        THROW_IF_FAILED(ShortMult(cursorPos.X, gsl::narrow<SHORT>(fontWidth), &clientCursorPos.X));
        THROW_IF_FAILED(ShortMult(cursorPos.Y, gsl::narrow<SHORT>(fontHeight), &clientCursorPos.Y));

        // Convert from client coordinate to screen coordinate by adding window position
        THROW_IF_FAILED(ShortAdd(clientCursorPos.X, gsl::narrow_cast<SHORT>(windowBounds.X), &screenCursorPos.X));
        THROW_IF_FAILED(ShortAdd(clientCursorPos.Y, gsl::narrow_cast<SHORT>(windowBounds.Y), &screenCursorPos.Y));

        // TODO: add tabs offset, currently a hack, since we can't determine the actual screen position of the control
        THROW_IF_FAILED(ShortAdd(screenCursorPos.Y, 34, &screenCursorPos.Y));

        // Get scale factor for view
        double scaleFactor = DisplayInformation::GetForCurrentView().RawPixelsPerViewPixel();

        // TODO set real layout bounds
        Rect selectionRect = Rect(screenCursorPos.X, screenCursorPos.Y, 0, fontHeight);
        request.LayoutBounds().TextBounds(ScaleRect(selectionRect, scaleFactor));

        //This is the bounds of the whole control
        Rect controlRect = Rect(screenCursorPos.X, screenCursorPos.Y, 0, fontHeight);
        request.LayoutBounds().ControlBounds(ScaleRect(controlRect, scaleFactor));

        StringCchPrintfW(buff, sizeof(buff), L"clientCursorPos - x:%d,y:%d\n", clientCursorPos.X, clientCursorPos.Y);

        OutputDebugString(buff);

        // position textblock to cursor position
        _canvas.SetLeft(_textBlock, clientCursorPos.X);
        _canvas.SetTop(_textBlock, clientCursorPos.Y + 2); // TODO figure out how to align

        // width is cursor to end of canvas
        _textBlock.Width(200); // TODO figure out proper width
        _textBlock.Height(fontHeight);

        //SHORT foo = _actualFont.GetUnscaledSize().Y;
        // TODO: font claims to be 12, but on screen 14 looks correct
        _textBlock.FontSize(14);

        _textBlock.FontFamily(Media::FontFamily(fontArgs->FontFace()));
    }

    // Method Description:
    // - Handler for CompositionStarted event by CoreEditContext responsible
    //   for making internal TSFInputControl controls visisble.
    // Arguments:
    // - sender: CoreTextEditContext sending the request. Not used in method.
    // - args: CoreTextCompositionStartedEventArgs. Not used in method.
    // Return Value:
    // - <none>
    void TSFInputControl::_compositionStartedHandler(CoreTextEditContext sender, CoreTextCompositionStartedEventArgs const& args)
    {
        OutputDebugString(L"CompositionStarted\n");
        _canvas.Visibility(Visibility::Visible);
        _textBlock.Visibility(Visibility::Visible);
    }

    // Method Description:
    // - Handler for CompositionCompleted event by CoreEditContext responsible
    //   for making internal TSFInputControl controls visisble.
    // Arguments:
    // - sender: CoreTextEditContext sending the request. Not used in method.
    // - args: CoreTextCompositionCompletedEventArgs. Not used in method.
    // Return Value:
    // - <none>
    void TSFInputControl::_compositionCompletedHandler(CoreTextEditContext sender, CoreTextCompositionCompletedEventArgs const& args)
    {
        if (!_inputBuffer.empty())
        {
            WCHAR buff[255];

            swprintf_s(buff, ARRAYSIZE(buff), L"Completed Text: %s\n", _inputBuffer.c_str());

            OutputDebugString(buff);

            auto hstr = to_hstring(_inputBuffer.c_str());

            // call event handler with data handled by parent
            _compositionCompletedHandlers(hstr);

            // tell the server that we've cleared the buffer
            CoreTextRange newTextRange;
            newTextRange.StartCaretPosition = 0;
            newTextRange.EndCaretPosition = 0;

            CoreTextRange newTextRange2;
            newTextRange2.StartCaretPosition = 0;
            newTextRange2.EndCaretPosition = 0; //_inputBuffer.length();

            _editContext.NotifyTextChanged(newTextRange2, 0, newTextRange);
            _editContext.NotifySelectionChanged(newTextRange);
        }

        // clear the buffer for next round
        _inputBuffer.clear();
        _textBlock.Text(L"");
        _canvas.Visibility(Visibility::Collapsed);
        _textBlock.Visibility(Visibility::Collapsed);
        OutputDebugString(L"CompositionCompleted\n");
    }

    // Method Description:
    // - Handler for FocusRemoved event by CoreEditContext responsible
    //   for removing focus for the TSFInputControl control accordingly
    //   when focus was forecibly removed from text input control. (TODO)
    //   NOTE: Documentation says application should handle this event
    // Arguments:
    // - sender: CoreTextEditContext sending the request. Not used in method.
    // - object: CoreTextCompositionStartedEventArgs. Not used in method.
    // Return Value:
    // - <none>
    void TSFInputControl::_focusRemovedHandler(CoreTextEditContext sender, winrt::Windows::Foundation::IInspectable const& object)
    {
        OutputDebugString(L"FocusRemoved\n");
    }

    // Method Description:
    // - Handler for TextRequested event by CoreEditContext responsible
    //   for returning the range of text requeted.
    //   NOTE: Documentation says application should handle this event
    // Arguments:
    // - sender: CoreTextEditContext sending the request. Not used in method.
    // - args: CoreTextTextRequestedEventArgs to be updated with requested range text.
    // Return Value:
    // - <none>
    void TSFInputControl::_textRequestedHandler(CoreTextEditContext sender, CoreTextTextRequestedEventArgs const& args)
    {
        OutputDebugString(L"_editContextTextRequested\n");

        // the range the TSF wants to know about
        auto range = args.Request().Range();

        WCHAR buff[255];

        swprintf_s(buff, ARRAYSIZE(buff), L"Requested Range: Start:%x, End:%x\n", range.StartCaretPosition, range.EndCaretPosition);

        OutputDebugString(buff);

        auto textRequested = _inputBuffer.substr(range.StartCaretPosition, range.EndCaretPosition - range.StartCaretPosition);

        swprintf_s(buff, ARRAYSIZE(buff), L"Text Requested: %s\n", textRequested.c_str());

        OutputDebugString(buff);

        args.Request().Text(winrt::to_hstring(textRequested.c_str()));
    }

    // Method Description:
    // - Handler for SelectionRequested event by CoreEditContext responsible
    //   for returning the currently selected text.
    //   TSFInputControl currently doesn't allow selection, so nothing happens.
    //   NOTE: Documentation says application should handle this event
    // Arguments:
    // - sender: CoreTextEditContext sending the request. Not used in method.
    // - args: CoreTextSelectionRequestedEventArgs for providing data for the SelectionRequested event. Not used in method.
    // Return Value:
    // - <none>
    void TSFInputControl::_selectionRequestedHandler(CoreTextEditContext sender, CoreTextSelectionRequestedEventArgs const& args)
    {
        OutputDebugString(L"_editContextSelectionRequested\n");
    }

    // Method Description:
    // - Handler for SelectionUpdating event by CoreEditContext responsible
    //   for handling modifications to the range of text currently selected.
    //   TSFInputControl doesn't currently allow selection, so nothing happens.
    //   NOTE: Documentation says application should set its selection range accordingly
    // Arguments:
    // - sender: CoreTextEditContext sending the request. Not used in method.
    // - args: CoreTextSelectionUpdatingEventArgs for providing data for the SelectionUpdating event. Not used in method.
    // Return Value:
    // - <none>
    void TSFInputControl::_selectionUpdatingHandler(CoreTextEditContext sender, CoreTextSelectionUpdatingEventArgs const& args)
    {
        OutputDebugString(L"_editContextSelectionUpdating\n");
    }

    // Method Description:
    // - Handler for TextUpdating event by CoreEditContext responsible
    //   for handling text updates.
    // Arguments:
    // - sender: CoreTextEditContext sending the request. Not used in method.
    // - args: CoreTextTextUpdatingEventArgs contains new text to update buffer with.
    // Return Value:
    // - <none>
    void TSFInputControl::_textUpdatingHandler(CoreTextEditContext sender, CoreTextTextUpdatingEventArgs const& args)
    {
        OutputDebugString(L"_editContextTextUpdating\n");
        auto text = args.Text();
        auto range = args.Range();

        WCHAR buff[255];
        swprintf_s(buff, ARRAYSIZE(buff), L"Text: %s\n", text.c_str());
        OutputDebugString(buff);

        _inputBuffer = _inputBuffer.replace(
            range.StartCaretPosition,
            range.EndCaretPosition - range.StartCaretPosition,
            text.c_str());

        _textBlock.Text(_inputBuffer);

        // Notify the TSF that the update succeeded
        args.Result(CoreTextTextUpdatingResult::Succeeded);
    }

    // Method Description:
    // - Handler for FormatUpdating event by CoreEditContext responsible
    //   for handling different format updates for a particular range of text.
    //   TSFInputControl doesn't do anything with this event.
    // Arguments:
    // - sender: CoreTextEditContext sending the request. Not used in method.
    // - args: CoreTextFormatUpdatingEventArgs Provides data for the FormatUpdating event. Not used in method.
    // Return Value:
    // - <none>
    void TSFInputControl::_formatUpdatingHandler(CoreTextEditContext sender, CoreTextFormatUpdatingEventArgs const& args)
    {
        OutputDebugString(L"_editContextFormatUpdating\n");
    }

    DEFINE_EVENT_WITH_TYPED_EVENT_HANDLER(TSFInputControl, CurrentCursorPosition, _currentCursorPositionHandlers, TerminalControl::TSFInputControl, TerminalControl::CursorPositionEventArgs);
    DEFINE_EVENT_WITH_TYPED_EVENT_HANDLER(TSFInputControl, CurrentFontInfo, _currentFontInfoHandlers, TerminalControl::TSFInputControl, TerminalControl::FontInfoEventArgs);
    DEFINE_EVENT(TSFInputControl, CompositionCompleted, _compositionCompletedHandlers, TerminalControl::CompositionCompletedEventArgs);
}
