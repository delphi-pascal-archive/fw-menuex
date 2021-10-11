////////////////////////////////////////////////////////////////////////////////
//
//  ****************************************************************************
//  * Unit Name : FWMenuEx
//  * Purpose   : Наследник стандартного TPopupMenu c дополнительным
//  *           : событием OnNCPaint, позволяющим отрисовывать неклиентскую
//  *           : область меню.
//  * Author    : Александр (Rouse_) Багель
//  * Copyright : © Fangorn Wizards Lab 1998 - 2008
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
  // Декларация нового события
  TFWOnNCPaintEvent = procedure(Sender: TObject;
    ACanvas: TCanvas; ARect: TRect) of object;

  TFWPopupMenu = class(TPopupMenu)
  private
    FOnNCPaint: TFWOnNCPaintEvent;
    FItemsTree,          // список открытых окон меню
    FMenuHandles: TList; // и их хэндлов
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
  // Структура служебных данных
  PMapData = ^TMapData;
  TMapData = record
    hCBTHook: THandle;          // хэндл CBT хука
    hPopupMenuWndProc: THandle; // хэндл оконной процедуры меню
  end;

//  Функция возвращяет структуру с данными, хранищимися в MMF
// =============================================================================
function GetMapFileData: TMapData;
var
  hMap: THandle;
  MapFileData: PMapData;
begin
  ZeroMemory(@Result, SizeOf(TMapData));
  // Открываем MMF на чтение
  hMap := OpenFileMapping(FILE_MAP_READ, False, PChar(GlobalMapFileName));
  if hMap <> 0 then
  try
        // Отображаем MMF на адресное пространство процесса
    MapFileData := MapViewOfFile(hMap, FILE_MAP_READ, 0, 0, 0);
    if MapFileData <> nil then
    try
      // Читаем данные
      Move(MapFileData^, Result, SizeOf(TMapData));
    finally
      // Закрываем указатель
      UnmapViewOfFile(MapFileData);
    end;
  finally
    // закрываем MMF
    CloseHandle(hMap);  
  end;
end;

//  Перекрытая оконная процедура MENUCLASS
// =============================================================================
function SubclassedWndProc(hwndDlg: HWND; uMsg: UINT;
  WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  OrigWndProc: DWORD;
  hMenuItemDC: HDC;
  ps: TPaintStruct;
begin
  // Получаем адрес оригинальной оконной процедуры
  OrigWndProc := GetWindowLong(hwndDlg, GWL_USERDATA);
  case uMsg of
    WM_NCPAINT: // сообщение о необходимости перерисовки NC области
    begin
      // Уведомляем наше меню, какое окно меню активно
      // необходимо для того, чтобы дынные для отрисовки брались
      // из активного меню, т.к. при закрытии SubMenu первоначально
      // отправляется WM_NCPAINT родителю и только потом
      // WM_DESTROY для SubMenu
      SendMessage(GetMapFileData.hPopupMenuWndProc,
        CM_ACTIVEHANDLE, hwndDlg, 0);
      // Получаем контекст окна
      hMenuItemDC := GetWindowDC(hwndDlg);
      try
        // отрисовку будем производить в обработчике WM_PRINT
        SendMessage(hwndDlg, WM_PRINT, hMenuItemDC, PRF_NONCLIENT);
      finally
        // освобождаем контекст
        ReleaseDC(hwndDlg, hMenuItemDC);
      end;
      Result := 0;
      Exit;
    end;
    WM_PRINT: // сообщение о необходимости отрисовки на переданный контекст
    begin
      // вызываем оригинальный обработчик
      Result := CallWindowProc(Pointer(OrigWndProc),
        hwndDlg, uMsg, WParam, LParam);
      // проверяем - отрисовывается ли NC область?
      if (LParam and PRF_NONCLIENT) = PRF_NONCLIENT then
      begin
        // если необходимо отрисовать NC - уведомляем об этом наше меню
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
    WM_ERASEBKGND: // сообщение о необходимости отрисовки бэкграунда
    begin
      Result := 1; // говорим системе, что мы обработали данное событие
      Exit;
    end;
    WM_DESTROY: // сообщение о разрушении меню
    begin
      // отправляем нотификацию нашему меню,
      // для изменения списка открытых окон
      SendMessage(GetMapFileData.hPopupMenuWndProc,
        CM_DESTROY, hwndDlg, 0);
      // снимаем перекрытие оконной процедуры
      SetWindowLong(hwndDlg, GWL_WNDPROC, OrigWndProc);
    end;
  end;
  // вызов оригинальной оконной процедуры
  Result := CallWindowProc(Pointer(OrigWndProc),
    hwndDlg, uMsg, WParam, LParam);
end;

//  Обработчик локального CBT хука
// =============================================================================
function WHCBTProc(nCode: Integer; WParam:
  WPARAM; LParam: LPARAM): LRESULT; stdcall;
const
// #define MENUCLASS MAKEINTATOM(0x8000)
// STD_MENUCLASS := '#' + IntToStr($8000)
  STD_MENUCLASS = '#32768'; // наименование класса окна,
                            // которое будет контейнером для меню
var
  AClassName: array [0..MAX_PATH  -1] of Char;
  MapData: TMapData;
begin
  MapData := GetMapFileData;
  // проверка, пришло ли уведомлении о создании нового окна?
  if nCode = HCBT_CREATEWND then
  begin
    // проверяем имя класса
    if GetClassName(WParam, @AClassName[0], MAX_PATH) > 0 then
      // если создается окно меню, то:
      if String(AClassName) = STD_MENUCLASS then
      begin
        // уве домляем о создании нового окна наше меню
        SendMessage(MapData.hPopupMenuWndProc, CM_CREATE, WParam, 0);
        // запоминаем адрес старой оконной процедуры в свойствах окна
        SetWindowLong(WParam, GWL_USERDATA,
          GetWindowLong(WParam, GWL_WNDPROC));
        // подменяем оконную процедуру
        SetWindowLong(WParam, GWL_WNDPROC, Integer(@SubclassedWndProc));
      end;
  end;
  // вызываем следующий обработчик
  Result := CallNextHookEx(
    MapData.hCBTHook, nCode, WParam, LParam);
end;

{ TFWPopupMenu }

constructor TFWPopupMenu.Create(AOwner: TComponent);
begin
  inherited;
  // создаем 2 служебных списка, в которых будем хранить:
  FItemsTree := TList.Create;   // указатель на активные TMenuItem включая SubMenu
  FMenuHandles := TList.Create; // их хэндлы
end;

destructor TFWPopupMenu.Destroy;
begin
  // разрушаем списки
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

//  Процедура вызывается перед тем как будет отображено всплывающее меню
// =============================================================================
procedure TFWPopupMenu.Popup(X, Y: Integer);
var
  hMap: THandle;
  MapFileData: PMapData;
begin
  // проверка - если не выставлен стиль OwnerDraw - то отрисовка NC не требуется
  if not OwnerDraw then
  begin
    inherited;
    Exit;
  end;
  // Создаем MMF, в котором будем хранить служебные данные
  hMap := CreateFileMapping(INVALID_HANDLE_VALUE, nil,
    PAGE_READWRITE, 0, 4096, PChar(GlobalMapFileName));
  if hMap <> 0 then
  try
    // Отображаем MMF на адресное пространство процесса
    MapFileData := MapViewOfFile(hMap, FILE_MAP_WRITE, 0, 0, 0);
    if MapFileData <> nil then
    try
      // Создаем окно, которое будет получать уведомления
      // от CBT хука и перекрытых оконных процедур меню
      MapFileData^.hPopupMenuWndProc := AllocateHWnd(WndProc);
      try
        // Создаем CBT хук который будет реагировать на все
        // создаваемые окна в рамках текущей нити
        MapFileData^.hCBTHook :=
          SetWindowsHookEx(WH_CBT, @WHCBTProc, 0, GetCurrentThreadId);
        try
          // вызываем оригинальную функцию
          inherited;
        finally
          // снимаем хук
          UnhookWindowsHookEx(MapFileData^.hCBTHook);
        end;
      finally
        // разрушаем нотификационное окно
        DeallocateHWnd(MapFileData^.hPopupMenuWndProc);
      end;
    finally
      // закрываем MMF указатель
      UnmapViewOfFile(MapFileData);
    end;
  finally
    // закрываем MMF файл
    CloseHandle(hMap);
  end;
end;

//  Оконная процедура для получения уведомлений
// от CBT хука и перекрытых оконных процедур меню
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
    CM_CREATE: // сообщение о создании нового окна с классом STD_MENUCLASS
    begin
      // Если кол-во сохраненных элементов 0,
      // значит создалось главное окно нашего TPopupMenu
      if FItemsTree.Count = 0 then
        FItemsTree.Add(Items)
      else
      begin
        // в противном случае, создалось SubMenu
        // и нам нужно найти, какому TMenuItem оно соответвтует
        ZeroMemory(@lpmii, SizeOf(TMenuItemInfo));
        // берем текущий активный TMenuItem
        RootMenuItem := TMenuItem(FItemsTree[FItemsTree.Count - 1]);
        // ищем какой из его элементов находится в состоянии odInactive
        for I := 0 to RootMenuItem.Count - 1 do
        begin
          lpmii.cbSize := SizeOf(TMenuItemInfo);
          lpmii.fMask := MIIM_STATE;
          // для этого получаем состояние каждого элемента меню
          GetMenuItemInfo(RootMenuItem.Handle, I, True, lpmii);
          // как только нашли такой:
          if (lpmii.fState and ODS_INACTIVE) = ODS_INACTIVE then
          begin
            // перерисовываем текущее активное окно
            hWindow := THandle(FMenuHandles[FMenuHandles.Count - 1]);
            RedrawWindow(hWindow, nil, 0, RDW_INVALIDATE);
            // и добавляем выделенный элемент меню - в конец очереди
            FItemsTree.Add(RootMenuItem[I]);
            Break;
          end;
        end;
      end;
      // также запоминаем переданных хэндл окна
      FMenuHandles.Add(Pointer(Message.WParam));
    end;
    CM_DESTROY: // сообщение о разрушении окна
    begin
      // ищем его в списке ранее запомненных окон
      Index := FMenuHandles.IndexOf(Pointer(Message.WParam));
      if Index >= 0 then
        // и если таковое нашлось, удалем все, что было перед ним
        // включая его самого
        for I := FMenuHandles.Count - 1 downto Index do
        begin
          FItemsTree.Delete(I);
          FMenuHandles.Delete(I);
        end;
    end;
    CM_ACTIVEHANDLE: // сообщение о изменении активности окон
    begin
      // данное сообшение приходит до того как дочернее окно уничтожилось
      // поэтому по аналогии с CM_DESTROY - удаляем все окна, которые
      // были активными до текущего окна
      Index := FMenuHandles.IndexOf(Pointer(Message.WParam));
      for I := FMenuHandles.Count - 1 downto Index + 1 do
      begin
        FItemsTree.Delete(I);
        FMenuHandles.Delete(I);
      end;
      if FMenuHandles.Count > 0 then
      begin
        // а само текущее перерисовываем
        hWindow := THandle(FMenuHandles[FMenuHandles.Count - 1]);
        RedrawWindow(hWindow, nil, 0, RDW_INVALIDATE);
      end;
    end;
    CM_PRINT: // сообщение о необходимости перерисовки NC области окна
    begin
      // получаем координаты окна
      GetWindowRect(Message.WParam, ARect);
      OffsetRect(ARect, -ARect.Left, -ARect.Top);
      ACanvas := TCanvas.Create;
      try
        // создаем временный канвас
        ACanvas.Handle := Message.LParam;
        // и говорим что необходимо отрисовать NC область
        if DoNCPaint(ACanvas, ARect) then
        begin
          // если NC отрисовано, то необходимо на NC канвас,
          // расположенный на клиентской области отрисовать изображнеия
          // всех элементов меню
          lpdis.rcItem.Left := 0;
          TopOffset := 0;
          // для этого получаем координаты клиентской области (КО)
          GetClientRect(Message.WParam, ARect);
          OffsetRect(ARect,
            GetSystemMetrics(SM_CXDLGFRAME), GetSystemMetrics(SM_CXDLGFRAME));
          lpdis.hDC := Message.LParam;
          // создаем по ним регион отсечения
          hRegion := CreateRectRgnIndirect(ARect);
          try
            // ограничиваем область отрисовки только КО
            SelectClipRgn(Message.LParam, hRegion);
            // смещаем точку начала координат в верхний левый угол КО
            SetWindowOrgEx(lpdis.hDC, -ARect.Left, -ARect.Top, nil);
            try
              ZeroMemory(@lpmii, SizeOf(TMenuItemInfo));
              ZeroMemory(@lpmis, SizeOf(TMeasureItemStruct));
              // Получаем TMenuItem с которого будем брать информацию о элементах
              RootMenuItem := TMenuItem(FItemsTree[FItemsTree.Count - 1]);
              for I := 0 to RootMenuItem.Count - 1 do
              begin
                // Получаем ID каждого элемента
                lpmii.cbSize := SizeOf(TMenuItemInfo);
                lpmii.fMask := MIIM_ID;
                GetMenuItemInfo(RootMenuItem.Handle, I, True, lpmii);

                // Получаем размеры элемента на канвасе
                // Будет вызвано TMenuItem.OnMeasureItem
                lpmis.itemID := lpmii.wID;
                SendMessage(PopupList.Window, WM_MEASUREITEM, 0, Integer(@lpmis));

                // Заполняем структуру для отрисовки и посылаем сообщение
                // о необходимости отрисовки элемента
                // будет вызвано TMenuItem.OnAdvancedDrawItem
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
              // снимаем отсечение
              SelectClipRgn(lpdis.hDC, 0);
              // возвращаем начало координат на место
              SetWindowOrgEx(lpdis.hDC, 0, 0, nil);
            end;
          finally
            // разрушаем регион
            DeleteObject(hRegion);
          end;
        end;
      finally
        // освобождаем ненужный далее канвас
        ACanvas.Free;
      end;
    end;
  end;
end;

end.
