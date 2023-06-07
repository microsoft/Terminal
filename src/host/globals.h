/*++
Copyright (c) Microsoft Corporation
Licensed under the MIT license.

Module Name:
- globals.h

Abstract:
- This module contains the global variables used by the console server DLL.

Author:
- Jerry Shea (jerrysh) 21-Sep-1993

Revision History:
- Modified to reduce globals over Console V2 project (MiNiksa/PaulCam, 2014)
--*/

#pragma once

#include "selection.hpp"
#include "server.h"
#include "ConsoleArguments.hpp"
#include "ApiRoutines.h"

#include "../propslib/DelegationConfig.hpp"
#include "../renderer/base/Renderer.hpp"
#include "../server/DeviceComm.h"
#include "../server/ConDrvDeviceComm.h"

#include <TraceLoggingProvider.h>
#include <winmeta.h>
TRACELOGGING_DECLARE_PROVIDER(g_hConhostV2EventTraceProvider);

class Globals
{
public:
    Globals();

    UINT uiOEMCP = GetOEMCP();
    UINT uiWindowsCP = GetACP();
    HINSTANCE hInstance;
    UINT uiDialogBoxCount;

    ConsoleArguments launchArgs;

    CONSOLE_INFORMATION& getConsoleInformation();

    IDeviceComm* pDeviceComm{ nullptr };

    wil::unique_event_nothrow hInputEvent;

    int sVerticalScrollSize;
    int sHorizontalScrollSize;

    int dpi = USER_DEFAULT_SCREEN_DPI;
    ULONG cursorPixelWidth = 1;

    NTSTATUS ntstatusConsoleInputInitStatus;
    wil::unique_event_nothrow hConsoleInputInitEvent;
    DWORD dwInputThreadId;

    std::vector<wchar_t> WordDelimiters;

    Microsoft::Console::Render::Renderer* pRender;

    Microsoft::Console::Render::IFontDefaultList* pFontDefaultList;

    bool IsHeadless() const;

    IApiRoutines* api;

    bool handoffTarget = false;

    DelegationConfig::DelegationPair delegationPair;
    wil::unique_hfile handoffInboxConsoleHandle;
    wil::unique_threadpool_wait handoffInboxConsoleExitWait;
    bool defaultTerminalMarkerCheckRequired = false;

#ifdef UNIT_TESTING
    void EnableConptyModeForTests(std::unique_ptr<Microsoft::Console::Render::VtEngine> vtRenderEngine);
#endif
};

// Define inline functions outside the class declaration

inline Globals::Globals()
{
    uiOEMCP = GetOEMCP();
    uiWindowsCP = GetACP();
    pDeviceComm = nullptr;
    sVerticalScrollSize = 0;
    sHorizontalScrollSize = 0;
    dpi = USER_DEFAULT_SCREEN_DPI;
    cursorPixelWidth = 1;
    ntstatusConsoleInputInitStatus = 0;
    dwInputThreadId = 0;
    pRender = nullptr;
    pFontDefaultList = nullptr;
    api = nullptr;
    handoffTarget = false;
    defaultTerminalMarkerCheckRequired = false;
}

inline CONSOLE_INFORMATION& Globals::getConsoleInformation()
{
    return ciConsoleInformation;
}

inline bool Globals::IsHeadless() const
{
    // Add your implementation here
    // Return whether the console is running in headless mode
}

#ifdef UNIT_TESTING
inline void Globals::EnableConptyModeForTests(std::unique_ptr<Microsoft::Console::Render::VtEngine> vtRenderEngine)
{
    // Add your implementation here
    // Enable ConPTY mode for unit testing using the provided vtRenderEngine
}
#endif
