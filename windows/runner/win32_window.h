#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}\n  };\n\n  struct Size {\n    unsigned int width;\n    unsigned int height;\n    Size(unsigned int width, unsigned int height)\n        : width(width), height(height) {}\n  };\n\n  Win32Window();\n  virtual ~Win32Window();\n\n  bool Create(const std::wstring& title, const Point& origin, const Size& size);\n  bool Show();\n  void Destroy();\n  void SetChildContent(HWND content);\n  HWND GetHandle();\n  void SetQuitOnClose(bool quit_on_close);\n  RECT GetClientArea();\n\n protected:\n  virtual LRESULT MessageHandler(HWND window,\n                                 UINT const message,\n                                 WPARAM const wparam,\n                                 LPARAM const lparam) noexcept;\n\n  virtual bool OnCreate();\n  virtual void OnDestroy();\n\n private:\n  friend class WindowClassRegistrar;\n\n  static LRESULT CALLBACK WndProc(HWND const window,\n                                  UINT const message,\n                                  WPARAM const wparam,\n                                  LPARAM const lparam) noexcept;\n\n  static Win32Window* GetThisFromHandle(HWND const window) noexcept;\n  static void UpdateTheme(HWND const window);\n\n  bool quit_on_close_ = false;\n  HWND window_handle_ = nullptr;\n  HWND child_content_ = nullptr;\n};\n\n#endif  // RUNNER_WIN32_WINDOW_H_\n