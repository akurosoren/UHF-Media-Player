#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <string>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // If an instance of UHF Media is already open, forward arguments via WM_COPYDATA and exit immediately.
  HWND existing_window = ::FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"UHF Media");
  if (existing_window != nullptr) {
    const wchar_t* cmd = ::GetCommandLineW();
    if (cmd != nullptr) {
      COPYDATASTRUCT cds;
      cds.dwData = 0x5548464D;  // 'UHFM'
      cds.cbData = static_cast<DWORD>((wcslen(cmd) + 1) * sizeof(wchar_t));
      cds.lpData = const_cast<wchar_t*>(cmd);
      ::SendMessage(existing_window, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&cds));
    }
    if (::IsIconic(existing_window)) {
      ::ShowWindow(existing_window, SW_RESTORE);
    }
    ::SetForegroundWindow(existing_window);
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"UHF Media", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
