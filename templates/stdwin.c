#define _WIN32_WINNT 0x0501
#include <Windows.h>

char *strClassName = "My Class";

LRESULT CALLBACK WndProc(HWND hWnd, UINT uMsg,
                         WPARAM wParam, LPARAM lParam)
{
    switch (uMsg)
    {
    case WM_DESTROY:
        PostQuitMessage(0);
        break;
    }
    return DefWindowProc(hWnd, uMsg, wParam, lParam);
}

int CALLBACK WinMain(HINSTANCE hInst, HINSTANCE hPreInst,
                     LPSTR strCmdLine, int nCmdShow)
{
    MSG msg;
    HWND hWnd;
    WNDCLASS wc =
    {
        CS_HREDRAW | CS_VREDRAW | CS_DBLCLKS,
        WndProc, 0, 0, hInst,
        LoadIcon(NULL, IDI_APPLICATION), LoadCursor(NULL, IDC_ARROW),
        (HBRUSH)GetStockObject(WHITE_BRUSH), NULL, strClassName
    };
    if (!RegisterClass(&wc))
        return 1;
    hWnd = CreateWindowEx(0,
                          strClassName, "My Window",
                          WS_OVERLAPPEDWINDOW,
                          CW_USEDEFAULT, CW_USEDEFAULT, 320, 240,
                          NULL, NULL, hInst, NULL);
    if (!IsWindow(hWnd))
        return 2;

    ShowWindow(hWnd, nCmdShow);
    UpdateWindow(hWnd);
    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return msg.wParam;
}

/* cc_flags = -mwindows -static */
