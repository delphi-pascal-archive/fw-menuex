////////////////////////////////////////////////////////////////////////////////
//
//  ****************************************************************************
//  * Unit Name : FWMenuEx
//  * Purpose   : ��������� ������������ TPopupMenu c ��������������
//  *           : �������� OnNCPaint, ����������� ������������ ������������
//  *           : ������� ����.
//  * Author    : ��������� (Rouse_) ������
//  * Copyright : � Fangorn Wizards Lab 1998 - 2008
//  * Version   : 1.00
//  * Home Page : http://rouse.drkb.ru
//  ****************************************************************************
//

unit FWMenuEx;

interface

uses
  Windows,
  Messages,
  Graphics,
  Menus,
  Controls,
  Classes;

type
  // ���������� ������ �������
  TFWOnNCPaintEvent = procedure(Sender: TObject;
    ACanvas: TCanvas; ARect: TRect) of object;

  TFWPopupMenu = class(TPopupMenu)
  private
    FOnNCPaint: TFWOnNCPaintEvent;
    FItemsTree,          // ������ �������� ���� ����
    FMenuHandles: TList; // � �� �������
  protected
    function DoNCPaint(ACanvas: TCanvas; ARect: TRect): Boolean; virtual;
    procedure WndProc(var Message: TMessage); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;  
    procedure Popup(X, Y: Integer); override;
  published
    property OnNCPaint: TFWOnNCPaintEvent read FOnNCPaint write FOnNCPaint;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Fangorn Wizards Lab', [TFWPopupMenu]);
end;

const
  GlobalMapFileName = 'TFWPopupMenuMapFile';
  CM_CREATE = CM_BASE + WM_CREATE;
  CM_DESTROY = CM_BASE + WM_DESTROY;
  CM_PRINT = CM_BASE + WM_PRINT;
  CM_ACTIVEHANDLE = WM_USER;  

type
  // ��������� ��������� ������
  PMapData = ^TMapData;
  TMapData = record
    hCBTHook: THandle;          // ����� CBT ����
    hPopupMenuWndProc: THandle; // ����� ������� ��������� ����
  end;

//  ������� ���������� ��������� � �������, ����������� � MMF
// =============================================================================
function GetMapFileData: TMapData;
var
  hMap: THandle;
  MapFileData: PMapData;
begin
  ZeroMemory(@Result, SizeOf(TMapData));
  // ��������� MMF �� ������
  hMap := OpenFileMapping(FILE_MAP_READ, False, PChar(GlobalMapFileName));
  if hMap <> 0 then
  try
        // ���������� MMF �� �������� ������������ ��������
    MapFileData := MapViewOfFile(hMap, FILE_MAP_READ, 0, 0, 0);
    if MapFileData <> nil then
    try
      // ������ ������
      Move(MapFileData^, Result, SizeOf(TMapData));
    finally
      // ��������� ���������
      UnmapViewOfFile(MapFileData);
    end;
  finally
    // ��������� MMF
    CloseHandle(hMap);  
  end;
end;

//  ���������� ������� ��������� MENUCLASS
// =============================================================================
function SubclassedWndProc(hwndDlg: HWND; uMsg: UINT;
  WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  OrigWndProc: DWORD;
  hMenuItemDC: HDC;
  ps: TPaintStruct;
begin
  // �������� ����� ������������ ������� ���������
  OrigWndProc := GetWindowLong(hwndDlg, GWL_USERDATA);
  case uMsg of
    WM_NCPAINT: // ��������� � ������������� ����������� NC �������
    begin
      // ���������� ���� ����, ����� ���� ���� �������
      // ���������� ��� ����, ����� ������ ��� ��������� �������
      // �� ��������� ����, �.�. ��� �������� SubMenu �������������
      // ������������ WM_NCPAINT �������� � ������ �����
      // WM_DESTROY ��� SubMenu
      SendMessage(GetMapFileData.hPopupMenuWndProc,
        CM_ACTIVEHANDLE, hwndDlg, 0);
      // �������� �������� ����
      hMenuItemDC := GetWindowDC(hwndDlg);
      try
        // ��������� ����� ����������� � ����������� WM_PRINT
        SendMessage(hwndDlg, WM_PRINT, hMenuItemDC, PRF_NONCLIENT);
      finally
        // ����������� ��������
        ReleaseDC(hwndDlg, hMenuItemDC);
      end;
      Result := 0;
      Exit;
    end;
    WM_PRINT: // ��������� � ������������� ��������� �� ���������� ��������
    begin
      // �������� ������������ ����������
      Result := CallWindowProc(Pointer(OrigWndProc),
        hwndDlg, uMsg, WParam, LParam);
      // ��������� - �������������� �� NC �������?
      if (LParam and PRF_NONCLIENT) = PRF_NONCLIENT then
      begin
        // ���� ���������� ���������� NC - ���������� �� ���� ���� ����
        BeginPaint(hwndDlg, ps);
        try
          SendMessage(GetMapFileData.hPopupMenuWndProc,
            CM_PRINT, hwndDlg, WParam);
        finally
          EndPaint(hwndDlg, ps);
        end;                    
        Exit;
      end;
    end;
    WM_ERASEBKGND: // ��������� � ������������� ��������� ����������
    begin
      Result := 1; // ������� �������, ��� �� ���������� ������ �������
      Exit;
    end;
    WM_DESTROY: // ��������� � ���������� ����
    begin
      // ���������� ����������� ������ ����,
      // ��� ��������� ������ �������� ����
      SendMessage(GetMapFileData.hPopupMenuWndProc,
        CM_DESTROY, hwndDlg, 0);
      // ������� ���������� ������� ���������
      SetWindowLong(hwndDlg, GWL_WNDPROC, OrigWndProc);
    end;
  end;
  // ����� ������������ ������� ���������
  Result := CallWindowProc(Pointer(OrigWndProc),
    hwndDlg, uMsg, WParam, LParam);
end;

//  ���������� ���������� CBT ����
// =============================================================================
function WHCBTProc(nCode: Integer; WParam:
  WPARAM; LParam: LPARAM): LRESULT; stdcall;
const
// #define MENUCLASS MAKEINTATOM(0x8000)
// STD_MENUCLASS := '#' + IntToStr($8000)
  STD_MENUCLASS = '#32768'; // ������������ ������ ����,
                            // ������� ����� ����������� ��� ����
var
  AClassName: array [0..MAX_PATH  -1] of Char;
  MapData: TMapData;
begin
  MapData := GetMapFileData;
  // ��������, ������ �� ����������� � �������� ������ ����?
  if nCode = HCBT_CREATEWND then
  begin
    // ��������� ��� ������
    if GetClassName(WParam, @AClassName[0], MAX_PATH) > 0 then
      // ���� ��������� ���� ����, ��:
      if String(AClassName) = STD_MENUCLASS then
      begin
        // ��� ������� � �������� ������ ���� ���� ����
        SendMessage(MapData.hPopupMenuWndProc, CM_CREATE, WParam, 0);
        // ���������� ����� ������ ������� ��������� � ��������� ����
        SetWindowLong(WParam, GWL_USERDATA,
          GetWindowLong(WParam, GWL_WNDPROC));
        // ��������� ������� ���������
        SetWindowLong(WParam, GWL_WNDPROC, Integer(@SubclassedWndProc));
      end;
  end;
  // �������� ��������� ����������
  Result := CallNextHookEx(
    MapData.hCBTHook, nCode, WParam, LParam);
end;

{ TFWPopupMenu }

constructor TFWPopupMenu.Create(AOwner: TComponent);
begin
  inherited;
  // ������� 2 ��������� ������, � ������� ����� �������:
  FItemsTree := TList.Create;   // ��������� �� �������� TMenuItem ������� SubMenu
  FMenuHandles := TList.Create; // �� ������
end;

destructor TFWPopupMenu.Destroy;
begin
  // ��������� ������
  FMenuHandles.Free;
  FItemsTree.Free;
  inherited;
end;

function TFWPopupMenu.DoNCPaint(ACanvas: TCanvas; ARect: TRect): Boolean;
begin
  Result := Assigned(FOnNCPaint);
  if Result then
    FOnNCPaint(Self, ACanvas, ARect);
end;

//  ��������� ���������� ����� ��� ��� ����� ���������� ����������� ����
// =============================================================================
procedure TFWPopupMenu.Popup(X, Y: Integer);
var
  hMap: THandle;
  MapFileData: PMapData;
begin
  // �������� - ���� �� ��������� ����� OwnerDraw - �� ��������� NC �� ���������
  if not OwnerDraw then
  begin
    inherited;
    Exit;
  end;
  // ������� MMF, � ������� ����� ������� ��������� ������
  hMap := CreateFileMapping(INVALID_HANDLE_VALUE, nil,
    PAGE_READWRITE, 0, 4096, PChar(GlobalMapFileName));
  if hMap <> 0 then
  try
    // ���������� MMF �� �������� ������������ ��������
    MapFileData := MapViewOfFile(hMap, FILE_MAP_WRITE, 0, 0, 0);
    if MapFileData <> nil then
    try
      // ������� ����, ������� ����� �������� �����������
      // �� CBT ���� � ���������� ������� �������� ����
      MapFileData^.hPopupMenuWndProc := AllocateHWnd(WndProc);
      try
        // ������� CBT ��� ������� ����� ����������� �� ���
        // ����������� ���� � ������ ������� ����
        MapFileData^.hCBTHook :=
          SetWindowsHookEx(WH_CBT, @WHCBTProc, 0, GetCurrentThreadId);
        try
          // �������� ������������ �������
          inherited;
        finally
          // ������� ���
          UnhookWindowsHookEx(MapFileData^.hCBTHook);
        end;
      finally
        // ��������� ��������������� ����
        DeallocateHWnd(MapFileData^.hPopupMenuWndProc);
      end;
    finally
      // ��������� MMF ���������
      UnmapViewOfFile(MapFileData);
    end;
  finally
    // ��������� MMF ����
    CloseHandle(hMap);
  end;
end;

//  ������� ��������� ��� ��������� �����������
// �� CBT ���� � ���������� ������� �������� ����
// =============================================================================
procedure TFWPopupMenu.WndProc(var Message: TMessage);
var
  I, TopOffset, Index: Integer;
  ARect: TRect;
  ACanvas: TCanvas;
  hRegion: HRGN;
  lpmii: TMenuItemInfo;
  lpmis: TMeasureItemStruct;
  lpdis: TDrawItemStruct;
  RootMenuItem: TMenuItem;
  hWindow: THandle;
begin
  case Message.Msg of
    CM_CREATE: // ��������� � �������� ������ ���� � ������� STD_MENUCLASS
    begin
      // ���� ���-�� ����������� ��������� 0,
      // ������ ��������� ������� ���� ������ TPopupMenu
      if FItemsTree.Count = 0 then
        FItemsTree.Add(Items)
      else
      begin
        // � ��������� ������, ��������� SubMenu
        // � ��� ����� �����, ������ TMenuItem ��� ������������
        ZeroMemory(@lpmii, SizeOf(TMenuItemInfo));
        // ����� ������� �������� TMenuItem
        RootMenuItem := TMenuItem(FItemsTree[FItemsTree.Count - 1]);
        // ���� ����� �� ��� ��������� ��������� � ��������� odInactive
        for I := 0 to RootMenuItem.Count - 1 do
        begin
          lpmii.cbSize := SizeOf(TMenuItemInfo);
          lpmii.fMask := MIIM_STATE;
          // ��� ����� �������� ��������� ������� �������� ����
          GetMenuItemInfo(RootMenuItem.Handle, I, True, lpmii);
          // ��� ������ ����� �����:
          if (lpmii.fState and ODS_INACTIVE) = ODS_INACTIVE then
          begin
            // �������������� ������� �������� ����
            hWindow := THandle(FMenuHandles[FMenuHandles.Count - 1]);
            RedrawWindow(hWindow, nil, 0, RDW_INVALIDATE);
            // � ��������� ���������� ������� ���� - � ����� �������
            FItemsTree.Add(RootMenuItem[I]);
            Break;
          end;
        end;
      end;
      // ����� ���������� ���������� ����� ����
      FMenuHandles.Add(Pointer(Message.WParam));
    end;
    CM_DESTROY: // ��������� � ���������� ����
    begin
      // ���� ��� � ������ ����� ����������� ����
      Index := FMenuHandles.IndexOf(Pointer(Message.WParam));
      if Index >= 0 then
        // � ���� ������� �������, ������ ���, ��� ���� ����� ���
        // ������� ��� ������
        for I := FMenuHandles.Count - 1 downto Index do
        begin
          FItemsTree.Delete(I);
          FMenuHandles.Delete(I);
        end;
    end;
    CM_ACTIVEHANDLE: // ��������� � ��������� ���������� ����
    begin
      // ������ ��������� �������� �� ���� ��� �������� ���� ������������
      // ������� �� �������� � CM_DESTROY - ������� ��� ����, �������
      // ���� ��������� �� �������� ����
      Index := FMenuHandles.IndexOf(Pointer(Message.WParam));
      for I := FMenuHandles.Count - 1 downto Index + 1 do
      begin
        FItemsTree.Delete(I);
        FMenuHandles.Delete(I);
      end;
      if FMenuHandles.Count > 0 then
      begin
        // � ���� ������� ��������������
        hWindow := THandle(FMenuHandles[FMenuHandles.Count - 1]);
        RedrawWindow(hWindow, nil, 0, RDW_INVALIDATE);
      end;
    end;
    CM_PRINT: // ��������� � ������������� ����������� NC ������� ����
    begin
      // �������� ���������� ����
      GetWindowRect(Message.WParam, ARect);
      OffsetRect(ARect, -ARect.Left, -ARect.Top);
      ACanvas := TCanvas.Create;
      try
        // ������� ��������� ������
        ACanvas.Handle := Message.LParam;
        // � ������� ��� ���������� ���������� NC �������
        if DoNCPaint(ACanvas, ARect) then
        begin
          // ���� NC ����������, �� ���������� �� NC ������,
          // ������������� �� ���������� ������� ���������� �����������
          // ���� ��������� ����
          lpdis.rcItem.Left := 0;
          TopOffset := 0;
          // ��� ����� �������� ���������� ���������� ������� (��)
          GetClientRect(Message.WParam, ARect);
          OffsetRect(ARect,
            GetSystemMetrics(SM_CXDLGFRAME), GetSystemMetrics(SM_CXDLGFRAME));
          lpdis.hDC := Message.LParam;
          // ������� �� ��� ������ ���������
          hRegion := CreateRectRgnIndirect(ARect);
          try
            // ������������ ������� ��������� ������ ��
            SelectClipRgn(Message.LParam, hRegion);
            // ������� ����� ������ ��������� � ������� ����� ���� ��
            SetWindowOrgEx(lpdis.hDC, -ARect.Left, -ARect.Top, nil);
            try
              ZeroMemory(@lpmii, SizeOf(TMenuItemInfo));
              ZeroMemory(@lpmis, SizeOf(TMeasureItemStruct));
              // �������� TMenuItem � �������� ����� ����� ���������� � ���������
              RootMenuItem := TMenuItem(FItemsTree[FItemsTree.Count - 1]);
              for I := 0 to RootMenuItem.Count - 1 do
              begin
                // �������� ID ������� ��������
                lpmii.cbSize := SizeOf(TMenuItemInfo);
                lpmii.fMask := MIIM_ID;
                GetMenuItemInfo(RootMenuItem.Handle, I, True, lpmii);

                // �������� ������� �������� �� �������
                // ����� ������� TMenuItem.OnMeasureItem
                lpmis.itemID := lpmii.wID;
                SendMessage(PopupList.Window, WM_MEASUREITEM, 0, Integer(@lpmis));

                // ��������� ��������� ��� ��������� � �������� ���������
                // � ������������� ��������� ��������
                // ����� ������� TMenuItem.OnAdvancedDrawItem
                lpdis.itemID := lpmii.wID;
                lpdis.itemState := 0;
                lpdis.rcItem.Top := TopOffset;
                Inc(TopOffset, lpmis.itemHeight);
                lpdis.rcItem.Right := lpdis.rcItem.Left +
                  Integer(lpmis.itemWidth);
                lpdis.rcItem.Bottom  := lpdis.rcItem.Top +
                  Integer(lpmis.itemHeight);
                SendMessage(PopupList.Window, WM_DRAWITEM, 0, Integer(@lpdis));
              end;
            finally
              // ������� ���������
              SelectClipRgn(lpdis.hDC, 0);
              // ���������� ������ ��������� �� �����
              SetWindowOrgEx(lpdis.hDC, 0, 0, nil);
            end;
          finally
            // ��������� ������
            DeleteObject(hRegion);
          end;
        end;
      finally
        // ����������� �������� ����� ������
        ACanvas.Free;
      end;
    end;
  end;
end;

end.
