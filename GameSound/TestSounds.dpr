program TestSounds;

uses
  System.StartUpCopy,
  FMX.Forms,
  frmMain in 'frmMain.pas' {MainFrm},
  uGameSound in 'uGameSound.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainFrm, MainFrm);
  Application.Run;
end.
