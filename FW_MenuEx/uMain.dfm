object Form7: TForm7
  Left = 230
  Top = 132
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'FW MenuEx'
  ClientHeight = 137
  ClientWidth = 474
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 120
  TextHeight = 17
  object Edit1: TEdit
    Left = 160
    Top = 8
    Width = 305
    Height = 25
    PopupMenu = FWPopupMenu1
    ReadOnly = True
    TabOrder = 0
    Text = 'OwnerDraw '#1084#1077#1085#1102' '#1089' '#1086#1090#1088#1080#1089#1086#1074#1082#1086#1081' NC '#1086#1073#1083#1072#1089#1090#1080
  end
  object Edit3: TEdit
    Left = 8
    Top = 8
    Width = 145
    Height = 25
    PopupMenu = FWPopupMenu3
    ReadOnly = True
    TabOrder = 1
    Text = #1057#1090#1072#1085#1076#1072#1088#1090#1085#1086#1077' '#1084#1077#1085#1102
  end
  object FWPopupMenu1: TFWPopupMenu
    OwnerDraw = True
    OnNCPaint = FWPopupMenu1NCPaint
    Left = 168
    Top = 40
    object N12: TMenuItem
      Tag = 1
      Caption = #1058#1077#1089#1090#1086#1074#1072#1103' '#1089#1090#1088#1086#1082#1072' '#8470'1'
      OnAdvancedDrawItem = N12AdvancedDrawItem
      OnMeasureItem = N12MeasureItem
    end
    object N22: TMenuItem
      Tag = 2
      Caption = #1058#1077#1089#1090#1086#1074#1072#1103' '#1089#1090#1088#1086#1082#1072' '#8470'2'
      OnAdvancedDrawItem = N12AdvancedDrawItem
      OnMeasureItem = N12MeasureItem
      object N11: TMenuItem
        Tag = 5
        Caption = #1058#1077#1089#1090#1086#1074#1086#1077' '#1087#1086#1076#1084#1077#1085#1102' '#8470'1'
        OnAdvancedDrawItem = N12AdvancedDrawItem
        OnMeasureItem = N12MeasureItem
      end
      object N21: TMenuItem
        Tag = 6
        Caption = #1058#1077#1089#1090#1086#1074#1086#1077' '#1087#1086#1076#1084#1077#1085#1102' '#8470'2'
        OnAdvancedDrawItem = N12AdvancedDrawItem
        OnMeasureItem = N12MeasureItem
      end
      object N2: TMenuItem
        Caption = '-'
        OnAdvancedDrawItem = N12AdvancedDrawItem
        OnMeasureItem = N12MeasureItem
      end
      object N31: TMenuItem
        Tag = 7
        Caption = #1058#1077#1089#1090#1086#1074#1086#1077' '#1087#1086#1076#1084#1077#1085#1102' '#8470'3'
        OnAdvancedDrawItem = N12AdvancedDrawItem
        OnMeasureItem = N12MeasureItem
      end
    end
    object N1: TMenuItem
      Caption = '-'
      OnAdvancedDrawItem = N12AdvancedDrawItem
      OnMeasureItem = N12MeasureItem
    end
    object N32: TMenuItem
      Tag = 3
      Caption = #1058#1077#1089#1090#1086#1074#1072#1103' '#1089#1090#1088#1086#1082#1072' '#8470'3'
      OnAdvancedDrawItem = N12AdvancedDrawItem
      OnMeasureItem = N12MeasureItem
    end
    object N41: TMenuItem
      Tag = 4
      Caption = #1058#1077#1089#1090#1086#1074#1072#1103' '#1089#1090#1088#1086#1082#1072' '#8470'4'
      OnAdvancedDrawItem = N12AdvancedDrawItem
      OnMeasureItem = N12MeasureItem
      object N42: TMenuItem
        Tag = 8
        Caption = #1058#1077#1089#1090#1086#1074#1086#1077' '#1087#1086#1076#1084#1077#1085#1102' '#8470'4'
        OnAdvancedDrawItem = N12AdvancedDrawItem
        OnMeasureItem = N12MeasureItem
      end
      object N51: TMenuItem
        Tag = 9
        Caption = #1058#1077#1089#1090#1086#1074#1086#1077' '#1087#1086#1076#1084#1077#1085#1102' '#8470'5'
        OnAdvancedDrawItem = N12AdvancedDrawItem
        OnMeasureItem = N12MeasureItem
      end
    end
  end
  object FWPopupMenu3: TFWPopupMenu
    Left = 16
    Top = 40
    object MenuItem12: TMenuItem
      Tag = 1
      Caption = #1058#1077#1089#1090#1086#1074#1072#1103' '#1089#1090#1088#1086#1082#1072' '#8470'1'
    end
    object MenuItem13: TMenuItem
      Tag = 2
      Caption = #1058#1077#1089#1090#1086#1074#1072#1103' '#1089#1090#1088#1086#1082#1072' '#8470'2'
      object MenuItem14: TMenuItem
        Tag = 5
        Caption = #1058#1077#1089#1090#1086#1074#1086#1077' '#1087#1086#1076#1084#1077#1085#1102' '#8470'1'
      end
      object MenuItem15: TMenuItem
        Tag = 6
        Caption = #1058#1077#1089#1090#1086#1074#1086#1077' '#1087#1086#1076#1084#1077#1085#1102' '#8470'2'
      end
      object MenuItem16: TMenuItem
        Caption = '-'
      end
      object MenuItem17: TMenuItem
        Tag = 7
        Caption = #1058#1077#1089#1090#1086#1074#1086#1077' '#1087#1086#1076#1084#1077#1085#1102' '#8470'3'
      end
    end
    object MenuItem18: TMenuItem
      Caption = '-'
    end
    object MenuItem19: TMenuItem
      Tag = 3
      Caption = #1058#1077#1089#1090#1086#1074#1072#1103' '#1089#1090#1088#1086#1082#1072' '#8470'3'
    end
    object MenuItem20: TMenuItem
      Tag = 4
      Caption = #1058#1077#1089#1090#1086#1074#1072#1103' '#1089#1090#1088#1086#1082#1072' '#8470'4'
      object MenuItem21: TMenuItem
        Tag = 8
        Caption = #1058#1077#1089#1090#1086#1074#1086#1077' '#1087#1086#1076#1084#1077#1085#1102' '#8470'4'
      end
      object MenuItem22: TMenuItem
        Tag = 9
        Caption = #1058#1077#1089#1090#1086#1074#1086#1077' '#1087#1086#1076#1084#1077#1085#1102' '#8470'5'
      end
    end
  end
end
