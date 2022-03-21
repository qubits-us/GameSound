{Unit GameSound -provides basic background mucis and game sounds.
           Compatible with Windows and Android

  created:3/21/22 -q

Acknowledgements/Credits - This was a derived work from clos examination of the Audio Manager- Author Jim McKeeth
                           Also Audio Manager released by FMXExpress.com
                           Bit and pieces from StackOverFlow allowed for SoundLoadedListener - Remy Lebuae

                           Would not have been possible without you, THANK YOU!!!


Uses new PoolBuilder for lollipops and higher..




           }


unit uGameSound;

interface
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Threading, System.Generics.Collections, FMX.Media
  {$IFDEF ANDROID}
    ,Androidapi.jni.media, FMX.Helpers.Android, Androidapi.jni.JavaTypes, Androidapi.JNI.GraphicsContentViewText,Androidapi.JNIBridge,
    Androidapi.helpers, Androidapi.JNI.App, Androidapi.JNI.Os
  {$ENDIF}
  {$IFDEF MSWINDOWS}
    ,MMSystem
  {$ENDIF}
   ;


const
   MAX_STREAMS = 4;
   MAX_VOL     = 1;
   USAGE_GAME  = 14;
   CT_SONIF    = 4;
   LOLLIPOP    = 21;

type
   tMusicError_Event = procedure (sender:tObject;aErrorMsg:String) of object;

{$IFDEF ANDROID}

type
TSoundLoadedEvent = procedure(Sender: TObject; SampleId: integer; status: Integer) of object;

type
TSoundLoadedListener = class(TJavaLocal, JSoundPool_OnLoadCompleteListener)
  private
    FSoundPool       : JSoundPool;
    FOnJLoadCompleted : TSoundLoadedEvent;
  public
    procedure onLoadComplete(soundPool: JSoundPool; sampleId,status: Integer); cdecl;
    property  OnLoadCompleted: TSoundLoadedEvent read FOnJLoadCompleted write FOnJLoadCompleted;
    property  SoundPool: JSoundPool read FSoundPool;
  end;
{$ENDIF}


type
  TSound=record
    FileName  :string;
    SoundName :string;
    Id        :integer;
    Loaded    :boolean;
  end;

  TGameSound=Class
    Private
      fSounds:TList<TSound>;
      fMusic:tMediaPlayer;
      fMusicFile:string;
      fMusicPlaying:boolean;
      fMusicError:tMusicError_Event;
      {$IFDEF ANDROID}
      fJAudioMgr:JAudioManager;
      fJPool:JSoundPool;
      fSoundLoadedListener:TSoundLoadedListener;
      fOnPlatformLoadComplete:TSoundLoadedEvent;
      procedure DoOnLoadComplete(Sender:TObject;SampleId:integer;status:integer);
      {$ENDIF}
      procedure SetLoaded(aSampleId:integer);
      function  GetCount:integer;
      procedure SetMusicPlaying(aPlaying:boolean);
      procedure SetMusicFile(aFile:string);
      procedure DoMusicError(aMsg:String);
    Public
      Constructor Create;
      Destructor  Destroy;override;
      function  Add(aFileName:string;aName:string):integer;
      procedure Delete(aName:string);overload;
      procedure Delete(aIndex:integer);overload;
      procedure Play(aName:string);overload;
      procedure Play(aIndex:integer);overload;

     {$IFDEF ANDROID}
      property  OnLoadCompleted:TSoundLoadedEvent read fOnPlatformLoadComplete write fOnPlatformLoadComplete;
      {$ENDIF}
      property OnMusicError:tMusicError_Event read fMusicError write fMusicError;
      property CountSounds:Integer read GetCount;
      property MusicFile:string read fMusicFile write SetMusicFile;
      property MusicPlaying:boolean read fMusicPlaying write SetMusicPlaying;
  end;

  var
    GameSound:tGameSound;


implementation


{$IFDEF ANDROID}
procedure TSoundLoadedListener.onLoadComplete(soundPool:JSoundPool; sampleId, status:integer);
begin
  FSoundPool := soundPool;
  if Assigned(FOnJLoadCompleted) then
    FOnJLoadCompleted(Self, sampleID, status);
end;
{$ENDIF}


constructor TGameSound.Create;
  {$IFDEF ANDROID}
var
poolBuilder:JSoundPool_Builder;
attribBuilder:JAudioAttributes_Builder;
attribs:JAudioAttributes;
  {$ENDIF}
begin
  try
    //background music player
    fMusic:=tMediaPlayer.Create(nil);
    fMusic.Volume:=MAX_VOL;

    fSounds := TList<TSound>.Create;
  {$IFDEF ANDROID}
  fJAudioMgr:=TJAudioManager.Wrap((TAndroidHelper.Activity.getSystemService(TJContext.JavaClass.AUDIO_SERVICE)as ILocalObject).GetObjectID);
   //create a pool.. check os version..
   if (TJBuild_VERSION.JavaClass.SDK_INT >= LOLLIPOP) then
     begin
      attribBuilder:=tJAudioAttributes_Builder.JavaClass.init;
      attribBuilder.setUsage(USAGE_GAME);
      attribBuilder.setContentType(CT_SONIF);
      attribs:=attribBuilder.build;
      poolBuilder:=tJSoundPool_Builder.JavaClass.init;
      poolBuilder.setMaxStreams(MAX_STREAMS);
      poolBuilder.setAudioAttributes(attribs);
      fJPool := PoolBuilder.build;
      attribBuilder:=nil;
      PoolBuilder:=nil;
     end else
        fJPool := TJSoundPool.JavaClass.init(MAX_STREAMS,TJAudioManager.JavaClass.STREAM_MUSIC, 0);
   //create our listener
    fSoundLoadedListener:=TSoundLoadedListener.Create;
    // set the listener callback
    fSoundLoadedListener.OnLoadCompleted:=DoOnLoadComplete;
    // inform JSoundPool that we have a listener
    fJPool.setOnLoadCompleteListener( fSoundLoadedListener );

  {$ENDIF}

  except
    On E:Exception do
      Raise Exception.create('Game Sound Create : '+E.message);
  end;
end;

destructor TGameSound.Destroy;
var
  i : integer;
begin
  try
    for i := fSounds.Count -1 downto 0 do
    begin
      fSounds.Delete(i);
    end;
    fSounds.Free;
    fMusic.Free;

    {$IFDEF ANDROID}
      fJPool := nil;
      fJAudioMgr := nil;
    {$ENDIF}
    inherited;
  except
    On E:Exception do
      Raise Exception.create('Game Sound : '+E.message);
  end;
end;

{$IFDEF ANDROID}
procedure TGameSound.DoOnLoadComplete(Sender: TObject; sampleId: Integer; status: Integer);
begin
  if status=0 then //0=success
  begin
    SetLoaded(sampleId);
    if Assigned(Self.fOnPlatformLoadComplete) then
      fOnPlatformLoadComplete( self, sampleID, status );
  end;
end;
{$ENDIF}


procedure tGameSound.SetLoaded(aSampleId:integer);
var
i : integer;
aSound:tSound;
begin
  try
    for i := 0 to fSounds.Count -1 do
    begin
      if TSound(fSounds[i]).Id=aSampleID then
      begin
        aSound:=fSounds[i];
        aSound.Loaded:=True;
        fSounds[i]:=aSound;
        Break;
      end;
    end;
  except
    On E:Exception do
      Raise Exception.create('Game Sound Loaded : '+E.message);
  end;
end;


function TGameSound.Add(aFileName: string; aName:String) : integer;
var
  aSound:tSound;
begin
  Result:=-1;
  try
    aSound.FileName:=aFileName;
    aSound.SoundName:=aName;
    aSound.ID:=-1;//win don't use it
    aSound.Loaded:=true;

    {$IFDEF ANDROID}
    aSound.Loaded:=False;
    aSound.ID:=fJPool.load(StringToJString(aFileName) ,0);
    {$ENDIF}
    Result:=fSounds.Add(aSound);
  except
    On E:Exception do
      Raise Exception.create('Game Sound Add : '+E.message);
  end;
end;

procedure TGameSound.Delete(aIndex: integer);
var
aSound:tSound;
begin
  try
    if aIndex < fSounds.Count then
    begin
      aSound := fSounds[aIndex];
      {$IFDEF ANDROID}
        fJPool.unload(aSound.Id);
      {$ENDIF}
      fSounds.Delete(aIndex);
    end;
  except
    On E:Exception do
      Raise Exception.create('Game Sound Delete : '+E.message);
  end;
end;

procedure TGameSound.Delete(aName: String);
var
i:integer;
begin
  try
    for i:=0 to fSounds.Count -1 do
    begin
      if CompareText(TSound(fSounds[i]).SoundName, AName)=0 then
      begin
        Delete(i);
        Break;
      end;
    end;
  except
    On E:Exception do
      Raise Exception.create('Game Sound Delete : '+E.message);
  end;
end;


procedure TGameSound.Play(aIndex: integer);
var
  aSound:TSound;
  {$IFDEF ANDROID}
    CurrVol,MaxVol,WantVol:Double;
  {$ENDIF}
begin
  try
    if aIndex<fSounds.Count then
    begin
      aSound:=fSounds[aIndex];
      {$IFDEF ANDROID}
        if Assigned(fJAudioMgr) then
        begin
          CurrVol :=fJAudioMgr.getStreamVolume(TJAudioManager.JavaClass.STREAM_MUSIC);
          MaxVol  :=fJAudioMgr.getStreamMaxVolume(TJAudioManager.JavaClass.STREAM_MUSIC);
          WantVol :=CurrVol/MaxVol;
          fJPool.play(aSound.Id,WantVol, WantVol,1,0,1);
        end;
      {$ENDIF}
      {$IFDEF MSWINDOWS}
        sndPlaySound(Pchar(aSound.FileName), SND_NODEFAULT Or SND_ASYNC);
      {$ENDIF}
    end;
  except
    On E:Exception do
      Raise Exception.create('Game Sound Playback : '+E.message);
  end;
end;


procedure TGameSound.Play(aName: String);
var i : integer;
begin
  try
    for i := 0 to fSounds.Count -1 do
    begin
      if CompareText(TSound(fSounds[i]).SoundName , aName) = 0 then
      begin
        Play(i);
        Break;
      end;
    end;
  except
    On E:Exception do
      Raise Exception.create('Game Sound Playback : '+E.message);
  end;
end;

function TGameSound.GetCount: integer;
begin
  result:=fSounds.Count;
end;


//Background music

procedure TGameSound.SetMusicPlaying(aPlaying: Boolean);
begin
  if aPlaying=fMusicPlaying then exit;
  fMusicPlaying:=aPlaying;
try
  if fMusic.FileName<>'' then
     if fMusicPlaying then
         fMusic.Play else fMusic.Stop;
  except on e:exception do
    begin
      DoMusicError(e.Message);
    end;
end;
end;

procedure TGameSound.SetMusicFile(aFile: string);
begin
  if aFile=fMusicFile then exit;
  fMusicFile:=aFile;
try
  if fMusic.State =tMediaState.Playing then fMusic.Stop;
  fMusic.Clear;
  fMusic.FileName:=fMusicFile;
  except on e:exception do
    begin
      DoMusicError(e.Message);
    end;
end;
end;

procedure TGameSound.DoMusicError(aMsg:String);
begin
  if Assigned(fMusicError) then fMusicError(self,aMsg);
end;

end.
