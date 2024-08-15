// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "pch.h"
#include "ShortcutActionDispatch.h"

#include "ShortcutActionDispatch.g.cpp"

using namespace winrt::Microsoft::Terminal;
using namespace winrt::Microsoft::Terminal::Settings::Model;
using namespace winrt::TerminalApp;

#define ACTION_CASE(action)              \
    case ShortcutAction::action:         \
    {                                    \
        action.raise(sender, eventArgs); \
        break;                           \
    }

namespace winrt::TerminalApp::implementation
{
    std::wstring ExtractAction(const ActionAndArgs& actionAndArgs)
    {
        std::wstring id{ actionAndArgs.GenerateID() };
        const auto segment1 = id.find(L'.');
        const auto segment2 = id.find(L'.', segment1 + 1);
        if (segment1 != std::wstring::npos)
        {
            if (segment2 != std::wstring::npos)
            {
                return id.substr(segment1 + 1, segment2 - segment1 - 1);
            }
            else
            {
                return id.substr(segment1 + 1);
            }
        }
        // This shouldn't be possible.
        // GenerateID() returns L"User.{}" unless it's invalid
        return nullptr;
    }

    // Method Description:
    // - Dispatch the appropriate event for the given ActionAndArgs. Constructs
    //   an ActionEventArgs to hold the IActionArgs payload for the event, and
    //   calls the matching handlers for that event.
    // Arguments:
    // - actionAndArgs: the ShortcutAction and associated args to raise an event for.
    // Return Value:
    // - true if we handled the event was handled, else false.
    bool ShortcutActionDispatch::DoAction(const winrt::Windows::Foundation::IInspectable& sender,
                                          const ActionAndArgs& actionAndArgs)
    {
        if (!actionAndArgs)
        {
            return false;
        }

        const auto& action = actionAndArgs.Action();
        const auto& args = actionAndArgs.Args();
        auto eventArgs = args ? ActionEventArgs{ args } :
                                ActionEventArgs{};

        switch (action)
        {
#define ON_ALL_ACTIONS(id) ACTION_CASE(id);
            ALL_SHORTCUT_ACTIONS
            INTERNAL_SHORTCUT_ACTIONS
#undef ON_ALL_ACTIONS
        default:
            return false;
        }
        const auto handled = eventArgs.Handled();

        if (handled)
        {
            TraceLoggingWrite(
                g_hTerminalAppProvider,
                "ActionDispatched",
                TraceLoggingDescription("Event emitted when an action was successfully performed"),
                TraceLoggingValue(ExtractAction(actionAndArgs).data(), "Action"),
                TraceLoggingKeyword(MICROSOFT_KEYWORD_MEASURES),
                TelemetryPrivacyDataTag(PDT_ProductAndServiceUsage));
        }

        return handled;
    }

    bool ShortcutActionDispatch::DoAction(const ActionAndArgs& actionAndArgs)
    {
        return DoAction(nullptr, actionAndArgs);
    }
}
