{
  This file is a part of example.
  look more in TgBotAPI.lpr
}

unit TgBotAPI_Main;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  wcApplication,
  HTTP1Utils;

type

  { TTBAPreThread }

  TTBAPreThread = class(TWCPreAnalizeNoSessionNoClientJob)
  public
    function GenerateClientJob: TWCMainClientJob; override;
  end;

procedure InitializeJobsTree(const aToken : String);
procedure DisposeJobsTree;

implementation

uses TgBotAPI_Jobs, AvgLvlTree;

var TgJobsTree : TStringToPointerTree;

procedure InitializeJobsTree(const aToken : String);

function GenBotCommand(const aCmd : String) : String;
begin
  Result := Format('/bot%s/%s', [aToken, aCmd]);
end;

begin
  TgJobsTree := TStringToPointerTree.Create(true);

  // client routes
  TgJobsTree.Values['/authClient.json'] := TTBAAddClient;
  TgJobsTree.Values['/clientGetUpdates.json'] := TTBAClientGetUpdates;
  TgJobsTree.Values['/clientSendUpdate.json'] := TTBAClientSendUpdate;
  TgJobsTree.Values['/clientGetCommands.json'] := TTBAClientGetCommands;

  // bot routes
  TgJobsTree.Values[GenBotCommand('getMe')]               := TTBAGetMe;
  TgJobsTree.Values[GenBotCommand('getUpdates')]          := TTBAGetUpdates;
  TgJobsTree.Values[GenBotCommand('sendMessage')]         := TTBASendMessage;
  TgJobsTree.Values[GenBotCommand('answerCallbackQuery')] := TTBAAnsCallback;
  TgJobsTree.Values[GenBotCommand('setMyCommands')]       := TTBASetMyCommands;
  TgJobsTree.Values[GenBotCommand('getMyCommands')]       := TTBAGetMyCommands;
end;

procedure DisposeJobsTree;
begin
  if assigned(TgJobsTree) then
    FreeAndNil(TgJobsTree);
end;

{ TTBAPreThread }

function TTBAPreThread.GenerateClientJob : TWCMainClientJob;
var ResultClass : TWCMainClientJobClass;
begin
  if CompareText(Request.Method, HTTPPOSTMethod)=0 then
  begin
    ResultClass := TWCMainClientJobClass(TgJobsTree.Values[Request.PathInfo]);
    if assigned(ResultClass) then
       Result := ResultClass.Create(Connection) else
    begin
      Application.SendError(Connection.Response, 404);
      Result := nil;
    end;
  end else begin
    Application.SendError(Connection.Response, 405);
    Result := nil;
  end;
end;

end.
