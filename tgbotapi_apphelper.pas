{
  This file is a part of example.
  look more in TgBotAPI.lpr
}

unit TgBotAPI_AppHelper;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  wcApplication,
  ECommonObjs, OGLFastNumList;

type

  { TRESTJsonConfigInitHelper }

  TRESTJsonConfigInitHelper = class(TWCHTTPAppConfigInitHelper)
  public
    procedure  DoHelp(AData : TObject); override;
  end;

  { TRESTJsonConfigHelper }

  TRESTJsonConfigHelper = class(TWCHTTPAppConfigRecordHelper)
  private
    FUsersDB : TThreadUtf8String;
    FBotToken : TThreadUtf8String;
    FBotName : TThreadUtf8String;
    function GetUsersDb : UTF8String;
    function GetBotToken : UTF8String;
    function GetBotName : UTF8String;
  public
    constructor Create;
    procedure  DoHelp(AData : TObject); override;
    destructor Destroy; override;

    property   UsersDB : UTF8String read GetUsersDb;
    property   BotToken : UTF8String read GetBotToken;
    property   BotName : UTF8String read GetBotName;

    class function Config : TRESTJsonConfigHelper;
  end;

  { TRESTJsonIdleHelper }

  TRESTJsonIdleHelper = class(TWCHTTPAppIdleHelper)
  private
    MTick10s, MTick60s : QWord;
    MinutTimer : Byte;
  public
    constructor Create;
    procedure DoHelp(aData : TObject); override;
  end;

implementation

uses wcConfig, TgBotAPI_Main, TgBotAPI_Jobs, HTTP2HTTP1Conv, extuhpack;

const CFG_RESTJSON_SEC      = $2000;
      CFG_RESTJSON_DB       = $2001;
      CFG_RESTJSON_TOKEN    = $2002;
      CFG_RESTJSON_BOT_NAME = $2003;

      cUsersDb = 'users.db';

      RESTJSON_CFG_CONFIGURATION : TWCConfiguration = (
        (ParentHash:CFG_ROOT_HASH;   Hash:CFG_RESTJSON_SEC; Name:'RESTServer'),
        (ParentHash:CFG_RESTJSON_SEC; Hash:CFG_RESTJSON_DB; Name:'UsersDB'),
        (ParentHash:CFG_RESTJSON_SEC; Hash:CFG_RESTJSON_TOKEN; Name:'Token'),
        (ParentHash:CFG_RESTJSON_SEC; Hash:CFG_RESTJSON_BOT_NAME; Name:'BotName')
        );

var vRJServerConfigHelper : TRESTJsonConfigHelper = nil;

{ TRESTJsonIdleHelper }

constructor TRESTJsonIdleHelper.Create;
begin
  MTick10s := GetTickCount64;
  MTick60s := MTick10s;
  MinutTimer := 0;
end;

procedure TRESTJsonIdleHelper.DoHelp(aData : TObject);
var ids : TFastMapUInt;
begin
  With TWCTimeStampObj(aData) do
  begin
    //every 10 sec
    if (Tick > MTick10s) and ((Tick - MTick10s) > 10000) then
    begin
      TRESTTgBotAPIUsersDB.UsersDB.MaintainStep10s;
      MTick10s := Tick;
    end;
    //every 60 sec
    if (Tick > MTick60s) and ((Tick - MTick60s) > 60000) then
    begin
      TRESTTgBotAPIUsersDB.UsersDB.MaintainStep60s;
      MTick60s := Tick;
      Inc(MinutTimer);
    end;
    //every hour
    if (MinutTimer >= 60) then
    begin
      MinutTimer := 0;
      TRESTTgBotAPIUsersDB.UsersDB.MaintainStep1hr;
    end;
  end;
end;

{ TRESTJsonConfigInitHelper }

procedure TRESTJsonConfigInitHelper.DoHelp(AData : TObject);
var
  RJSection : TWCConfigRecord;
begin
  AddWCConfiguration(RESTJSON_CFG_CONFIGURATION);

  with TWCConfig(AData) do begin
    RJSection := Root.AddSection(HashToConfig(CFG_RESTJSON_SEC)^.NAME_STR);
    RJSection.AddValue(CFG_RESTJSON_DB, wccrString);
    RJSection.AddValue(CFG_RESTJSON_TOKEN, wccrString);
    RJSection.AddValue(CFG_RESTJSON_BOT_NAME, wccrString);
  end;
end;

{ TRESTJsonConfigHelper }

function TRESTJsonConfigHelper.GetUsersDb : UTF8String;
begin
  Result := FUsersDB.Value;
end;

function TRESTJsonConfigHelper.GetBotToken : UTF8String;
begin
  Result := FBotToken.Value;
end;

function TRESTJsonConfigHelper.GetBotName : UTF8String;
begin
  Result := FBotName.Value;
end;

constructor TRESTJsonConfigHelper.Create;
begin
  FUsersDB  := TThreadUtf8String.Create(cUsersDb);
  FBotToken := TThreadUtf8String.Create('');
  FBotName  := TThreadUtf8String.Create('Test');
end;

procedure TRESTJsonConfigHelper.DoHelp(AData : TObject);
begin
  case TWCConfigRecord(AData).HashName of
    CFG_RESTJSON_DB :
      FUsersDB.Value := TWCConfigRecord(AData).Value;
    CFG_RESTJSON_TOKEN :
    begin
      FBotToken.Value := TWCConfigRecord(AData).Value;
      DisposeJobsTree;
      InitializeJobsTree(FBotToken.Value);
    end;
    CFG_RESTJSON_BOT_NAME :
    begin
      FBotName.Value := TWCConfigRecord(AData).Value;
    end;
  end;
end;

destructor TRESTJsonConfigHelper.Destroy;
begin
  FUsersDB.Free;
  FBotToken.Free;
  FBotName.Free;
  inherited Destroy;
end;

class function TRESTJsonConfigHelper.Config : TRESTJsonConfigHelper;
begin
  if not assigned(vRJServerConfigHelper) then
    vRJServerConfigHelper := TRESTJsonConfigHelper.Create;
  Result := vRJServerConfigHelper;
end;

end.

