unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, StdCtrls, FWMenuEx;

type
  TForm7 = class(TForm)
    FWPopupMenu1: TFWPopupMenu;
    N12: TMenuItem;
    N22: TMenuItem;
    N32: TMenuItem;
    N41: TMenuItem;             
    Edit1: TEdit;
    N11: TMenuItem;
    N21: TMenuItem;
    N31: TMenuItem;
    N42: TMenuItem;
    N51: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    Edit3: TEdit;
    FWPopupMenu3: TFWPopupMenu;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    MenuItem19: TMenuItem;
    MenuItem20: TMenuItem;
    MenuItem21: TMenuItem;
    MenuItem22: TMenuItem;
    procedure FWPopupMenu1NCPaint(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect);
    procedure N12AdvancedDrawItem(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; State: TOwnerDrawState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure N12MeasureItem(Sender: TObject; ACanvas: TCanvas; var Width,
      Height: Integer);
  public
    GradientBitmap: TBitmap;
    FMenuWidth: Integer;
  end;

var
  Form7: TForm7;

implementation

{$R *.dfm}

procedure TForm7.FormCreate(Sender: TObject);
begin
  // подгружаем картинку с градиентом
  GradientBitmap := TBitmap.Create;
  GradientBitmap.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'gradient.bmp');
end;

procedure TForm7.FormDestroy(Sender: TObject);
begin
  GradientBitmap.Free;
end;

procedure TForm7.FWPopupMenu1NCPaint(Sender: TObject; ACanvas: TCanvas;
  ARect: TRect);
begin
  // отрисовка неклиентской области
  // очищаем всю область окна
  ACanvas.Brush.Color := clWhite;
  ACanvas.FillRect(ARect);
  // рисуем рамку по размеру окна
  ACanvas.Pen.Color := RGB(0, 45, 150);
  ACanvas.Rectangle(0, 0, ARect.Right, ARect.Bottom);
  // и отрисовываем изображение градиента
  ACanvas.StretchDraw(
    Rect(1, 1, GradientBitmap.Width, ARect.Bottom - 1), GradientBitmap);
end;

procedure TForm7.N12AdvancedDrawItem(Sender: TObject; ACanvas: TCanvas;
  ARect: TRect; State: TOwnerDrawState);
var
  GradientRect: TRect;
  ACaption: String;
  lpmii: TMenuItemInfo;
  bmArrow: TBitmap;
begin
  // отрисовываем каждый элемент
  // этот код не комментируется, т.к. потакому-же
  // принципу делается отрисовка элементов обычного TPopupMenu

  if TMenuItem(Sender).MenuIndex = 0 then
    FMenuWidth := ARect.Right;
  ACaption := StringReplace(
    TMenuItem(Sender).Caption, '&', '', [rfReplaceAll]);
  ACanvas.Brush.Color := clWhite;
  ACanvas.FillRect(ARect);
  GradientRect := ARect;
  OffsetRect(GradientRect, -GetSystemMetrics(SM_CXDLGFRAME), 0);
  GradientRect.Right := GradientRect.Left + GradientBitmap.Width;
  ACanvas.StretchDraw(GradientRect, GradientBitmap);
  if odSelected in State then
  begin
    ACanvas.Pen.Color := RGB(0, 0, 128);
    ACanvas.Brush.Color := RGB(255, 238, 194);
    ACanvas.Rectangle(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
  end;
  if odDisabled in State then
    ACanvas.Font.Color := RGB(141, 141, 141)
  else
    ACanvas.Font.Color := clBlack;
  if odDefault in State then
    ACanvas.Font.Style := [fsBold]
  else
    ACanvas.Font.Style := [];
  if ACaption = '-' then
  begin
    ACanvas.Pen.Color := RGB(106, 140, 203);
    ACanvas.MoveTo(ARect.Left + GradientBitmap.Width + 4, ARect.Top + 2);
    ACanvas.LineTo(FMenuWidth , ARect.Top + 2);
  end
  else
  begin
    ACanvas.Brush.Style := bsClear;
    ACanvas.TextOut(ARect.Left + GradientBitmap.Width + 4, ARect.Top + 3,
      ACaption);
    ACanvas.Brush.Style := bsSolid;
  end;
  if TMenuItem(Sender).Count > 0 then
  begin
    bmArrow := TBitmap.Create;
    try
      bmArrow.PixelFormat := pf24bit;
      bmArrow.Width := 6;
      bmArrow.Height := 8;
      if odSelected in State then
        bmArrow.Canvas.Brush.Color := RGB(255, 238, 194)
      else
        bmArrow.Canvas.Brush.Color := clWhite;
      bmArrow.Canvas.Fillrect(Rect(0, 0, 14, 14));
      bmArrow.Canvas.Font.Size := 10;
      bmArrow.Canvas.Font.Name := 'Marlett';
      bmArrow.Canvas.TextOut(-3, -2, #52);
      ACanvas.Draw(FMenuWidth, ARect.Top + 5, bmArrow);
    finally
      bmArrow.Free;
    end;
  end;
end;

procedure TForm7.N12MeasureItem(Sender: TObject; ACanvas: TCanvas; var Width,
  Height: Integer);
var
  lpRect: TRect;
  ACaption: String;
begin
  // указываем размеры каждого элемента
  // этот код не комментируется, т.к. потакому-же
  // принципу делается указание размеров элементов обычного TPopupMenu

  ACaption := StringReplace(
    TMenuItem(Sender).Caption, '&', '', [rfReplaceAll]);
  if TMenuItem(Sender).Caption = '-' then
    Height := 5
  else
  begin
    ZeroMemory(@lpRect, SizeOf(TRect));
    lpRect.Right := 1;
    lpRect.Bottom := 1;
    DrawText(ACanvas.Handle, PChar(ACaption),
      Length(ACaption), lpRect, DT_CALCRECT);
    Width := lpRect.Right + GradientBitmap.Width + 12;
    Height := 22;
  end;
end;

end.
