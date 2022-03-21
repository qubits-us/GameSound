unit frmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Memo,FMX.TextLayout.GPU,uGameSound;

type
  TMainFrm = class(TForm)
    btnCreate: TButton;
    btnLoad: TButton;
    btnPlay: TButton;
    memDisplay: TMemo;
    btnBGStart: TButton;
    btnBGStop: TButton;
    procedure btnCreateClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnBGStartClick(Sender: TObject);
    procedure btnBGStopClick(Sender: TObject);
    procedure OnSoundLoaded(Sender:tObject;aSoundID:integer;aStatus:integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainFrm: TMainFrm;

implementation



{$R *.fmx}


procedure WiggleHandle;
begin
{$IF RTLVersion111}
TGPUObjectsPool.Instance.Free;
{$ENDIF}
end;



procedure TMainFrm.btnBGStartClick(Sender: TObject);
var
aPath:String;
begin
  if Assigned(GameSound) then
     begin
      if GameSound.MusicFile='' then
       begin
        {$IFDEF ANDROID}
        aPath:=TPath.GetDocumentsPath;
          {$ENDIF}
        {$IFDEF MSWINDOWS}
        aPath:=ExtractFilePath(ParamStr(0));
         {$ENDIF}
        aPath:=TPath.Combine(aPath,'music.mp3');
        if TFile.Exists(aPath) then
        GameSound.MusicFile:=aPath else
          memDisplay.Lines.Insert(0,'Background music file not found.');
       end;

      GameSound.MusicPlaying:=true;

     end;
end;

procedure TMainFrm.btnBGStopClick(Sender: TObject);
begin
if Assigned(GameSound) then
   GameSound.MusicPlaying:=False;
end;

procedure TMainFrm.btnCreateClick(Sender: TObject);
begin
try
GameSound:=tGameSound.Create;
{$IFDEF ANDROID}
GameSound.OnLoadCompleted:=OnSoundLoaded;
{$ENDIF}
memDisplay.Lines.Insert(0,'Game Sounds Created');
except on e:exception do
 begin
  memDisplay.Lines.Insert(0,e.Message);
 end;
end;

end;

procedure TMainFrm.btnLoadClick(Sender: TObject);
var
aPath:String;
begin
//load the sound
{$IFDEF ANDROID}
aPath:=TPath.GetDocumentsPath;
{$ENDIF}
{$IFDEF MSWINDOWS}
aPath:=ExtractFilePath(ParamStr(0));
{$ENDIF}

aPath:=TPath.Combine(aPath,'fire.wav');
if Assigned(GameSound) then
  begin
   memDisplay.Lines.Insert(0,'Loading sound: '+aPath);
   GameSound.Add(aPath,'Fire');
  end;




end;


procedure TMainFRm.OnSoundLoaded(Sender: TObject; aSoundID: Integer; aStatus: Integer);
begin

  memDisplay.Lines.Insert(0,'Sound Loaded ID:'+IntToStr(aSoundID)+' Status:'+IntToStr(aStatus));

end;

procedure TMainFrm.btnPlayClick(Sender: TObject);
begin
if Assigned(GameSound) then
  if GameSound.CountSounds>0 then
      GameSound.Play(0);

end;

procedure TMainFrm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
if Assigned(GameSound) then
  GameSound.Free;

{$IFDEF MSWINDOWS}
 WiggleHandle;
{$ENDIF}
end;

procedure TMainFrm.FormCreate(Sender: TObject);
var
aPath:String;
begin
REportMemoryLeaksOnShutdown:=true;

{$IFDEF ANDROID}
aPath:=TPath.GetDocumentsPath;
{$ENDIF}
{$IFDEF MSWINDOWS}
aPath:=ExtractFilePath(ParamStr(0));
{$ENDIF}
memDisplay.Lines.Insert(0,aPath);

end;

end.
