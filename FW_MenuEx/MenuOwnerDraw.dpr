program MenuOwnerDraw;

uses
  Forms,
  uMain in 'uMain.pas' {Form7};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm7, Form7);
  Application.Run;
end.
