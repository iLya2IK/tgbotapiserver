{REST Telegram Bot API Server

Copyright (c) 2024, Ilya Medvedkov

The server operates in the REST architecture mode.
The server can accept POST requests and respond with JSON objects.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}

program tgbotapi;

{$mode objfpc}{$H+}
{$DEFINE UseCThreads}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}
  {$ENDIF}
  Classes,
  SysUtils,
  Interfaces,
  {$IFDEF LOAD_DYNAMICALLY}
  SQLite3Dyn,
  {$ENDIF}
  TgBotAPI_Main,
  TgBotAPI_Jobs,
  TgBotAPI_AppHelper,
  wcapplication,
  fphttp,
  http2consts,
  fpjson,
  wcconfig,
  wcNetworking,
  SortedThreadPool,
  {avaible decoders}
  wcdecoders,
  wcdeflatedecoder;

{$ifdef linux}
{$linklib libc}
{$endif}

type

{ TWCJSONFloatNumber }

TWCJSONFloatNumber = class(TJSONFloatNumber)
public
  function GetAsString: TJSONStringType; override;
end;

var Conf : TWCConfig;

{ TWCJSONFloatNumber }

function TWCJSONFloatNumber.GetAsString : TJSONStringType;
var
  test, v : Extended;
  c : Integer;
begin
  v := GetAsFloat;
  Result := Format('%.15g', [GetAsFloat]);
  Val(Result, test, C);
  if (C = 0) and (test <> v) then
  begin
    Result := Format('%.17g', [GetAsFloat]);
  end;
end;

{$IFDEF LOAD_DYNAMICALLY}
vLibPath : String;
{$ENDIF}
begin
  Randomize;

  SetJSONInstanceType(jitNumberFloat, TWCJSONFloatNumber);

  Application.AddHelper(TRESTJsonConfigInitHelper.Create);
  Application.AddHelper(TRESTJsonConfigHelper.Config);
  Application.AddHelper(TRESTJsonIdleHelper.Create);
  Application.AddHelper(TRESTTgBotAPIUsersDB.UsersDB);

  Application.ConfigFileName := ExtractFilePath(Application.ExeName) + 'server.cfg';
  if not assigned(Application.Config) then
     raise Exception.Create('Unexpected config error');
  {$IFDEF LOAD_DYNAMICALLY}
  vLibPath := ExtractFilePath(Application.ExeName);
  {$IFDEF Windows}
  {$IF defined(Win32)}
  vLibPath := vLibPath + 'libs\win32\';
  {$ElseIf defined(Win64)}
  vLibPath := vLibPath + 'libs\win64\';
  {$ENDIF}
  {$else}
  {$ENDIF}
  InitializeSQLite(UnicodeString(vLibPath + Sqlite3Lib));
  {$ENDIF}
  Application.LegacyRouting := true;
  Application.Threaded:=True;
  Conf := Application.Config;
  Conf.SetDefaultValue(CFG_SERVER_NAME, 'WCTgBotAPIServer');
  // WebFilesLoc - location of site files
  // for example if location of executable is /home/folder/
  // then site location will be home/folder/CFG_SITE_FOLDER/
  Conf.SetDefaultValue(CFG_SITE_FOLDER, 'none');
  // LogDb - location of database with log
  // then log database location will be home/folder/CFG_LOG_DB
  Conf.SetDefaultValue(CFG_LOG_DB, 'logbotapi.db');
  //SSL/TLS configuration
  Conf.SetDefaultValue(CFG_USE_SSL, true);
  Conf.SetDefaultValue(CFG_HOST_NAME, 'localhost');
  // SSLLoc - location of openssl keys, certificates and logs
  // then openssl location will be home/folder/CFG_SSL_LOC
  Conf.SetDefaultValue(CFG_SSL_LOC, 'openssl');
  Conf.SetDefaultValue(CFG_SSL_CIPHER,
                'ECDHE-RSA-AES128-GCM-SHA256:'+
                'ECDHE-ECDSA-AES128-GCM-SHA256:'+
                'ECDHE-ECDSA-CHACHA20-POLY1305:'+
                'ECDHE-RSA-AES128-SHA256:'+
                'AES128-GCM-SHA256:'+
                'ECDHE-ECDSA-AES256-GCM-SHA384:'+
                'ECDHE-ECDSA-AES256-SHA384'+
                '');
  // PrivateKey - location of openssl keys
  // then keys location will be home/folder/CFG_SSL_LOC/CFG_PRIVATE_KEY
  Conf.SetDefaultValue(CFG_PRIVATE_KEY, 'localhost.key');
  // Certificate - location of openssl certificates
  // then certificates location will be home/folder/CFG_SSL_LOC/CFG_CERTIFICATE
  Conf.SetDefaultValue(CFG_CERTIFICATE, 'localhost.crt');
  // SSLMasterKeyLog - location of openssl keys log
  // then tls keys log location will be home/folder/CFG_SSL_LOC/CFG_TLSKEY_LOG
  Conf.SetDefaultValue(CFG_TLSKEY_LOG, ''); // tlskey.log
  Conf.SetDefaultValue(CFG_SSL_VER, 'TLSv1.2'); //if TLSv1.3 - do not forget to change cipher list
  Conf.SetDefaultValue(CFG_ALPN_USE_HTTP2, True);
  Conf.SetDefaultValue(CFG_IO_THREAD_CNT, 1);
  Conf.SetDefaultValue(CFG_MAIN_THREAD_CNT, 6);
  Conf.SetDefaultValue(CFG_PRE_THREAD_CNT, 5);
  Conf.SetDefaultValue(CFG_JOB_TO_JOB_WAIT, DefaultJobToJobWait.DefaultValue);
  Conf.SetDefaultValue(CFG_JOB_TO_JOB_WAIT_ADAPT_MAX, DefaultJobToJobWait.AdaptMax);
  Conf.SetDefaultValue(CFG_JOB_TO_JOB_WAIT_ADAPT_MIN, DefaultJobToJobWait.AdaptMin);
  Conf.SetDefaultValue(CFG_CLIENT_ALLOW_ENCODE, 'deflate');

  with Application.WCServer.HTTP2Settings do
  if Count = 0 then begin
    Add(H2SET_MAX_CONCURRENT_STREAMS, 100);
    Add(H2SET_INITIAL_WINDOW_SIZE, $ffff);
    Add(H2SET_HEADER_TABLE_SIZE, HTTP2_SET_INITIAL_VALUES[H2SET_HEADER_TABLE_SIZE]);
  end;

  {$IFDEF WC_WEB_SOCKETS}
  Conf.SetDefaultValue(CFG_WEBSOCKET_SUB_PROTO, 'chat');
  {$ENDIF}

  Application.ServerAnalizeJobClass := TgBotAPI_Main.TTBAPreThread;
  InitializeJobsTree(TRESTJsonConfigHelper.Config.BotToken);
  try
    Application.Initialize;
    Application.Run;
  finally
    DisposeJobsTree;
  end;
end.
