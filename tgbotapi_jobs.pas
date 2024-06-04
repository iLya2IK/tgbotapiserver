{
  This file is a part of example.
  look more in TgBotAPI.lpr
}

unit TgBotAPI_Jobs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, variants,
  httpdefs, httpprotocol,
  jsonscanner, jsonparser, fpjson,
  ExtSqlite3DS, OGLFastList, ECommonObjs, OGLRegExprWrapper, OGLFastVariantHash,
  db, wcApplication, HTTP2Consts;

type

  TDBID = Int64;

  { TTBAAddClient }

  TTBAAddClient = class(TWCMainClientJob)
  public
    procedure Execute; override;
  end;

  { TTBAGetMe }

  TTBAGetMe = class(TWCMainClientJob)
  public
    procedure Execute; override;
  end;

  { TTBAGetUpdates }

  TTBAGetUpdates = class(TWCMainClientJob)
  public
    procedure Execute; override;
  end;

  { TTBAClientGetUpdates }

  TTBAClientGetUpdates = class(TWCMainClientJob)
  public
    procedure Execute; override;
  end;

  { TTBASendMessage }

  TTBASendMessage = class(TWCMainClientJob)
  public
    procedure Execute; override;
  end;

  { TTBAClientSendUpdate }

  TTBAClientSendUpdate = class(TWCMainClientJob)
  public
    procedure Execute; override;
  end;

  { TTBAClientGetCommands }

  TTBAClientGetCommands = class(TWCMainClientJob)
  public
    procedure Execute; override;
  end;

  { TTBAAnsCallback }

  TTBAAnsCallback = class(TWCMainClientJob)
  public
    procedure Execute; override;
  end;

  { TTBASetMyCommands }

  TTBASetMyCommands = class(TWCMainClientJob)
  public
    procedure Execute; override;
  end;

  { TTBAGetMyCommands }

  TTBAGetMyCommands = class(TWCMainClientJob)
  public
    procedure Execute; override;
  end;

  { TRESTTgBotAPIUsersDB }

  TRESTTgBotAPIUsersDB = class(TWCHTTPAppInitHelper)
  private
    FUsersDB : TExtSqlite3Dataset;
  public
    PREP_GetClient,
    PREP_GetClientID,
    PREP_AddClient,
    PREP_SetLastOffset,
    PREP_GetTotalOffset,
    PREP_GetLastOffset,
    PREP_SetCommands,
    PREP_GetCommands,
    PREP_AddUpdate,
    PREP_AddMessage,
    PREP_AddMessageEntity,
    PREP_AddInlineKeyboardRow,
    PREP_AddInlineKeyboardBtn,
    PREP_AddQuery,
    PREP_GetUpdates,
    PREP_GetMessage,
    PREP_GetCallbackQuery,
    PREP_GetUser,
    PREP_ClearNotify,
    PREP_AddNotify : TSqlite3Prepared;

    BotId : TDBID;

    constructor Create;
    procedure DoHelp({%H-}aData : TObject); override;
    destructor Destroy; override;

    procedure Execute(const Str : String);

    procedure MaintainStep10s;
    procedure MaintainStep60s;
    procedure MaintainStep1hr;

    class function UsersDB : TRESTTgBotAPIUsersDB;
  end;

  TUCId = record
    uid, cid : TDBID;
  end;

  { TSerializeMessage }

  TSerializeMessage = class(TSqlite3Function)
  public
    constructor Create;
    procedure ScalarFunc(argc : integer); override;
  end;

  { TSerializeUser }

  TSerializeUser = class(TSqlite3Function)
  public
    constructor Create;
    procedure ScalarFunc(argc : integer); override;
  end;

  { TSerializeChat }

  TSerializeChat = class(TSqlite3Function)
  public
    constructor Create;
    procedure ScalarFunc(argc : integer); override;
  end;

  { TSerializeTextEntity }

  TSerializeTextEntity = class(TSqlite3Function)
  public
    constructor Create;
    procedure ScalarFunc(argc : integer); override;
  end;

  { TSerializeInlineButton }

  TSerializeInlineButton = class(TSqlite3Function)
  public
    constructor Create;
    procedure ScalarFunc(argc : integer); override;
  end;

  { TSerializeCallbackQuery }

  TSerializeCallbackQuery = class(TSqlite3Function)
  public
    constructor Create;
    procedure ScalarFunc(argc : integer); override;
  end;

  THTMLTagKind = (
    tgtNone,
    tgtBold,
    tgtItalic,
    tgtUnderline,
    tgtStrikethrough,
    tgtSpoiler,
    tgtUrl,
    tgtBotCommand,
    tgtCode,
    tgtPre,
    tgtBlockquote
  );

  { THTMLTagCheckResult }

  THTMLTagCheckResult = record
    result : Boolean;
    tagid : THTMLTagKind;
    tag : String;
    param : String;
  end;

  { THTMLTag }

  THTMLTag = class(TThreadSafeObject)
  private
    RegExp : String;
    RegExpObj : TRegExprWrapper;
    TgName : THTMLTagKind;
  protected
    procedure FillResult(var res : THTMLTagCheckResult); virtual;
  public
    constructor Create(const aExp : String; aTag : THTMLTagKind);
    destructor Destroy; override;
    function Check(const aTag : String; var res : THTMLTagCheckResult) : Boolean;
  end;

  { THTMLHrefTag }

  THTMLHrefTag = class(THTMLTag)
  protected
    procedure FillResult(var res : THTMLTagCheckResult); override;
  end;

  { THTMLCodeTag }

  THTMLCodeTag = class(THTMLTag)
  protected
    procedure FillResult(var res : THTMLTagCheckResult); override;
  end;

  { THTMLToken }

  THTMLToken = class
  private
    function GetKind : String;
  public
    TagId : THTMLTagKind;
    Offset, Len : integer;
    Param : string;
    constructor Create(aTagID: THTMLTagKind; aOffset : Integer);
    constructor CreateFromToken(aToken : THTMLToken);
    property Kind : String read GetKind;
  end;

  { THTMLExpression }

  THTMLExpression = class (specialize TFastBaseCollection<THTMLToken>)
  public
    type
      THTMLTagClass = class of THTMLTag;
    const TG_KINDS : Array [THTMLTagKind] of string = (
       'none',
       'bold',
       'italic',
       'underline',
       'strikethrough',
       'spoiler',
       'url',
       'bot_command',
       'code',
       'pre',
       'blockquote'
    );
    const TG_KIND_CLASSES : Array [THTMLTagKind] of THTMLTagClass = (
       THTMLTag,
       THTMLTag,
       THTMLTag,
       THTMLTag,
       THTMLTag,
       THTMLTag,
       THTMLHrefTag,
       THTMLTag,
       THTMLCodeTag,
       THTMLTag,
       THTMLTag
    );
    const RE_KINDS : Array [THTMLTagKind] of String = (
    '',
    '\<(b|strong)\>',
    '\<(i|em)\>',
    '\<(u|ins)\>',
    '\<(s|strike|del)\>',
    '\<(span(\s+)class(\s*)\=(\s*)\"tg-spoiler\"|tg\-spoiler)\>',
    '\<(a(\s+)href(\s*)\=(\s*)\"(http([A-Za-z0-9_.~!*''();:@&=+$,\/?#\[%\-\]+]+))\")\>',
    '\<(a(\s+)href(\s*)\=(\s*)\"\/[A-Za-z0-9_]+\")\>',
    '\<code((\s+)class(\s*)\=(\s*)\"language\-([A-Za-z0-9\-]+)\"){0,1}\>',
    '\<pre\>',
    '\<blockquote\>');

    class var RegExpHTMLTags : Array [THTMLTagKind] of THTMLTag;
    class var RegExpBotCommandTag : THTMLTag;

    class procedure InitParser;
    class procedure DoneParser;

    class function TagKindToStr(aTag : THTMLTagKind) : String;
    class function GetTag(const aTag : String) : THTMLTagCheckResult;

    function ParseHTML(const aStr : WideString) : WideString;
    procedure ExtractCommands(const aStr : String);

    function Find(tag : THTMLTagKind; const s : String): Integer;
  end;

  { TWCRequestHelper }

  TWCRequestHelper = class helper for TWCRequest
  public
    procedure ProcessQueryString(const FQueryString: String; SL: TStrings);
  end;

implementation

uses wcutils, TgBotAPI_AppHelper, ExtSqliteUtils;

const BAD_JSON = '{"ok":false}';
      OK_JSON  = '{"ok":true,"result":true}';
      JSON_EMPTY_OBJ = '{}';
      JSON_EMPTY_ARRAY = '[]';
      JSON_EMPTY_NESTED_ARRAY = '[[]]';
      JSON_TRUE = 'true';
      JSON_FALSE = 'false';

      BAD_JSON_DATABASE_FAIL     = '{"ok":false,"result":"DB Fail"}';
      BAD_JSON_JSON_PARSER_FAIL  = '{"ok":false,"result":"JSON Parser Fail"}';
      BAD_JSON_JSON_FAIL         = '{"ok":false,"result":"JSON Fail"}';
      BAD_JSON_INTERNAL_UNK      = '{"ok":false,"result":"Internal Exception"}';
      BAD_JSON_MALFORMED_REQUEST = '{"ok":false,"result":"Malformed Request"}';

      cOK          = 'ok';
      cRESULT      = 'result';
      cMSG         = 'msg';
      cMSGS        = 'msgs';
      cTEXT        = 'text';
      cDATA        = 'data';
      cURL         = 'url';
      cID          = 'id';
      cDEFAULT     = 'default';
      cCOMMANDS    = 'commands';
      cSCOPE       = 'scope';
      cLANG        = 'language_code';
      cCBCKID      = 'callback_query_id';
      cCBCKDATA    = 'callback_data';
      cCID         = 'chat_id';
      cUID         = 'user_id';
      cMID         = 'message_id';
      CUPDID       = 'update_id';
      cFROM        = 'from';
      cCHAT        = 'chat';
      cSNDCHAT     = 'sender_chat';
      cDATE        = 'date';
      cISBOT       = 'is_bot';
      cFIRSTNAME   = 'first_name';
      cLASTNAME    = 'last_name';
      cUSERNAME    = 'username';
      cOFFSET      = 'offset';
      cTIMEOUT     = 'timeout';
      cLIMIT       = 'limit';
      cTYPE        = 'type';
      cPRIVATE     = 'private';
      cPARSEMODE   = 'parse_mode';
      cREPLYPARAMS = 'reply_parameters';
      cREPLYMARKUP = 'reply_markup';
      cFORCEREPLY  = 'force_reply';
      cINLINEKBRD  = 'inline_keyboard';
      cPAYLOAD     = 'payload';
      cMESSAGE     = 'message';
      cCMDSNOTIFY  = 'commands_notify';
      cCALLBACK    = 'callback_query';

var vUsersDB : TRESTTgBotAPIUsersDB = nil;
var vServerDateTimeFormat : TFormatSettings;

(* Add the new client (bot-user or bot itself) to the database.
   If a user with the specified username exists, the function will update
   other data in the local database and return the existing ID.
   @param(DB is link to the sqlite3 database)
   @param(aName is the user name (nickname))
   @param(aFirstName is the first name of the user)
   @param(aLastName is the last name of the user)
   @param(aLocale is the IETF language tag for the user)
   @param(IsBot - if @true then the user is bot)
   @returns(The existed or new user id in the local database) *)
function AddUserInternal(DB: TRESTTgBotAPIUsersDB;
                              const aName, aFirstName,
                              aLastName, aLocale : String;
                              IsBot : Boolean) : TDBID;
var
  ids : Array [0..0] of variant;
begin
  if DB.PREP_AddClient.ExecToValue(
                              [aName, aFirstName, aLastName, aLocale, IsBot],
                              @ids) = erOkWithData then
  begin
    Result := ids[0];
  end else
    Result := -1;
end;

(* Add the new client (bot-user or bot itself) to the local database
   @param(aName is the user name)
   @pram(aFirstName is the first name of the user)
   @pram(aLastName is the last name of the user)
   @pram(aLocale is the IETF language tag for the user)
   @pram(IsBot - if @true then the user is bot)
   @returns(String description for the user object in a json notation)  *)
function AddClient(const aName, aFirstName,
                                aLastName, aLocale : String;
                                IsBot : Boolean) : String;
var
  jsonObj : TJSONObject;
  uid : int64;
begin
  try
    uid := AddUserInternal(vUsersDB, aName, aFirstName, aLastName, aLocale, IsBot);
    if uid > 0 then
    begin
      jsonObj := TJSONObject.Create([cOK,     true,
                                     cRESULT, TJSONObject.Create([cCID, uid])]);
      try
        Result := jsonObj.AsJSON;
      finally
        jsonObj.Free;
      end;
    end;
  except
    on e : EDatabaseError do Result := BAD_JSON_DATABASE_FAIL;
    on e : EJSONParser do Result := BAD_JSON_JSON_PARSER_FAIL;
    on e : EJSON do Result := BAD_JSON_JSON_FAIL;
    else Result := BAD_JSON_INTERNAL_UNK;
  end;
end;

(* A simple method for testing bot's authentication token.
   Requires no parameters. Returns basic information about the bot
   in form of a User object.
   Telegram bot API getMe<=@link(https://core.telegram.org/bots/api#getme)
   @returns(User object - in a json notation *)
function GetMe() : String;
var
  jsonMe : String;
begin
  try
    vUsersDB.PREP_GetUser.Lock;
    try
      with vUsersDB.PREP_GetUser do
      if OpenDirect([vUsersDB.BotId]) then
      begin
        jsonMe := AsString[0];

        Result := Format('{"result":%s,"ok":true}', [jsonMe]);
      end;
      vUsersDB.PREP_GetUser.Close;
    finally
      vUsersDB.PREP_GetUser.UnLock;
    end;
  except
    on e : EDatabaseError do Result := BAD_JSON_DATABASE_FAIL;
    on e : EJSONParser do Result := BAD_JSON_JSON_PARSER_FAIL;
    on e : EJSON do Result := BAD_JSON_JSON_FAIL;
    else Result := BAD_JSON_INTERNAL_UNK;
  end;
end;

(* Just a stub.
   Telegram bot API Update<=@link(https://core.telegram.org/bots/api#update)
   @returns(Simple ok-result (Update object - in a json notation)) *)
function AnsCallback({%H-}cbkid : integer) : String;
begin
  // do nothing
  Result := OK_JSON;
end;

(* Get the message object.
   Telegram bot API Message<=@link(https://core.telegram.org/bots/api#message)
   @param(id is the message id in the locale database)
   @returns(Message object - in a json notation) *)
function GetMessage(id : int64) : String;
var
  req : array [0..1] of variant;
  obj0 : String;
begin
  if vUsersDB.PREP_GetMessage.ExecToValue([id], @req) = erOkWithData then
  begin
    Result := req[0];
    if req[1] > 0 then
    begin
      if vUsersDB.PREP_GetMessage.ExecToValue([int64(req[1])],
                                              @req) = erOkWithData then
      begin
        obj0 := req[0];
        Delete(Result, Length(Result), 1);
        Result += ',"reply_to_message":'+obj0+'}';
      end;
    end;
    Exit(Result);
  end;
  Exit(JSON_EMPTY_OBJ)
end;

(* Get the callback query object.
   Telegram bot API CallbackQuery<=@link(https://core.telegram.org/bots/api#callbackquery)
   @param(id is the query id in the locale database)
   @returns(CallbackQuery object - in a json notation) *)
function GetCallbackQuery(id : int64) : String;
var
  req : array [0..0] of variant;
begin
  if vUsersDB.PREP_GetCallbackQuery.ExecToValue([id], @req) = erOkWithData then
  begin
    Result := req[0];
  end else
    Result := JSON_EMPTY_OBJ;
end;

(* Send callback query from the client to a bot.
   Telegram bot API Result<=@link(https://core.telegram.org/bots/api#making-requests)
   @param(chatid is the id of the client's chat)
   @param(mid is the id of the message linked to the callback)
   @param(aData is data associated with the callback button - may be empty)
   @param(aUrl is the link associated with the callback button - may be empty)
   @returns(Result object - in a json notation) *)
function SendCallback(chatid, mid : int64; const aData, aUrl : String) : String;
var
  ids : array [0..0] of variant;
  upid : int64;
begin
  try
    if vUsersDB.PREP_AddUpdate.ExecToValue(
                                [chatid, cCALLBACK],
                                @ids) = erOkWithData then
    begin
      upid := ids[0];

      if upid > 0 then
      begin
        // upid, mid, "from", url, data
        vUsersDB.PREP_AddQuery.Execute([upid, mid, chatid, aUrl, aData]);
        Result := OK_JSON;
      end;
    end else
      Result := BAD_JSON_INTERNAL_UNK;
  except
    on e : EDatabaseError do Result := BAD_JSON_DATABASE_FAIL;
    on e : EJSONParser do Result := BAD_JSON_JSON_PARSER_FAIL;
    on e : EJSON do Result := BAD_JSON_JSON_FAIL;
    else Result := BAD_JSON_INTERNAL_UNK;
  end;
end;

(* Use this method to change the list of the bot's commands.
   Telegram bot API Result<=@link(https://core.telegram.org/bots/api#making-requests)
   Telegram bot API setMyCommands<=@link(https://core.telegram.org/bots/api#setmycommands)
   @param(aBotID is the user-id in the local database for the bot)
   @param(commands is the id of the client's chat)
   @param(scope is a JSON-serialized object, describing scope of users)
   @param(lang is the IETF language tag for the scope)
   @returns(Result object - in a json notation) *)
function SetMyCommands(aBotID : Int64;
                                const commands, scope, lang : String) : String;
var
  scopeObj : TJSONObject;
  scopeType, local, loc_scope : String;
  scopeCID : Int64;
begin
  try
    if length(scope) > 0 then
    begin
      scopeObj := TJSONObject(GetJSON(scope));
      try
        scopeType := scopeObj.Get(cTYPE, cDEFAULT);
        scopeCID := scopeObj.Get(cCID, 0);
        loc_scope := scopeObj.AsJSON;
      finally
        scopeObj.Free;
      end;
    end else
    begin
      scopeType := cDEFAULT;
      scopeCID := 0;
      loc_scope := '{}';
    end;
    if length(lang) > 0 then
      local := lang
    else
      local := cDEFAULT;
    if length(scopeType) > 0 then
    begin
      vUsersDB.PREP_SetCommands.Execute([aBotID,
                                         commands,
                                         scopeType,
                                         scopeCID,
                                         loc_scope,
                                         local]);
      vUsersDB.PREP_ClearNotify.Execute([aBotID, cCMDSNOTIFY]);
      vUsersDB.PREP_AddNotify.Execute([aBotID, cCMDSNOTIFY]);
      Result := OK_JSON;
    end else
      Result := BAD_JSON_MALFORMED_REQUEST;
  except
    on e : EDatabaseError do Result := BAD_JSON_DATABASE_FAIL;
    on e : EJSONParser do Result := BAD_JSON_JSON_PARSER_FAIL;
    on e : EJSON do Result := BAD_JSON_JSON_FAIL;
    else Result := BAD_JSON_INTERNAL_UNK;
  end;
end;

(* Get the current list of the bot's commands for the given scope and user language.
   Telegram bot API Result<=@link(https://core.telegram.org/bots/api#making-requests)
   Telegram bot API getMyCommands<=@link(https://core.telegram.org/bots/api#getmycommands)
   @param(aBotID is the user-id in the local database for the bot)
   @param(scope is a JSON-serialized object, describing scope of users)
   @param(lang is the IETF language tag for the scope)
   @returns(Result object - in a json notation) *)
function GetMyCommands(aBotID : Int64;
                                const scope, lang : String) : String;
var
  commandsObj : TJSONArray;
  scopeObj : TJSONObject;
  scopeType : String;
  scopeCID : Int64;
begin
  try
    scopeObj := TJSONObject(GetJSON(scope));
    try
      scopeType := scopeObj.Get(cTYPE, '');
      scopeCID := scopeObj.Get(cCID, 0);
      if length(scopeType) > 0 then
      begin
        result := vUsersDB.PREP_GetCommands.QuickQuery(
                                          [aBotID,
                                           scopeType,
                                           scopeCID,
                                           lang], nil, false);
        if Length(result) > 0 then
        begin
          commandsObj := TJSONArray(GetJSON(Result));
          try
            Result := Format('{"ok":true,"result":%s}', [commandsObj.AsJSON])
          finally
            commandsObj.Free;
          end;
        end else
          Result := BAD_JSON_MALFORMED_REQUEST;
      end else
        Result := BAD_JSON_MALFORMED_REQUEST;
    finally
      scopeObj.Free;
    end;
  except
    on e : EDatabaseError do Result := BAD_JSON_DATABASE_FAIL;
    on e : EJSONParser do Result := BAD_JSON_JSON_PARSER_FAIL;
    on e : EJSON do Result := BAD_JSON_JSON_FAIL;
    else Result := BAD_JSON_INTERNAL_UNK;
  end;
end;

(* Get the current list of the bot's commands for the given user.
   Telegram bot API Result<=@link(https://core.telegram.org/bots/api#making-requests)
   @param(aBotID is the user-id in the local database for the bot)
   @param(aChatID is the chat-id for whom the commands are sent)
   @returns(Result object - in a json notation) *)
function GetBotCommands(aBotID : Int64; aChatId : Int64) : String;
var
  ids : array [0..5] of variant;
  uid : int64;
  lang : String;
begin
  try
    if vUsersDB.PREP_GetClient.ExecToValue(
                                [aChatId],
                                @ids) = erOkWithData then
    begin
      uid := ids[0];
      lang := ids[4];
      Result := GetMyCommands(aBotID,
                              Format('{"type":"chat","chat_id":%d}', [uid]),
                              lang);
    end else
      Result := BAD_JSON_MALFORMED_REQUEST;
  except
    on e : EDatabaseError do Result := BAD_JSON_DATABASE_FAIL;
    on e : EJSONParser do Result := BAD_JSON_JSON_PARSER_FAIL;
    on e : EJSON do Result := BAD_JSON_JSON_FAIL;
    else Result := BAD_JSON_INTERNAL_UNK;
  end;
end;

(* Send text message from the client to a bot.
   Telegram bot API Result<=@link(https://core.telegram.org/bots/api#making-requests)
   Telegram bot API Message<=@link(https://core.telegram.org/bots/api#message)
   Telegram bot API ReplyParameters<=@link(https://core.telegram.org/bots/api#replyparameters)
   Telegram bot API InlineKeyboardMarkup<=@link(https://core.telegram.org/bots/inlinekeyboardmarkup)
   @param(fromid is the user-id of the sender)
   @param(chatid is the id of the client's chat)
   @param(aMsg the actual UTF-8 text of the message)
   @param(aParseMode the mode for parsing entities in the message text)
   @param(aReplyParams is the ReplyParameters object in a json notation)
   @param(aReplyMarkup is the InlineKeyboardMarkup object in a json notation)
   @returns(Result object - in a json notation) *)
function SendMessage(fromid, chatid : int64;
                              const aMsg, aParseMode,
                              aReplyParams, aReplyMarkup : String) : String;
var
  ids : array [0..0] of variant;
  upid, msgid, rowid : int64;
  is_force_reply, i, j : integer;
  reply_id : int64;
  obj, obj0, plain_msg : string;

  markup, inline_rows, inline_button : TJSONData;
  htmlexpr : THTMLExpression;
begin
  try
    if vUsersDB.PREP_AddUpdate.ExecToValue(
                                [chatid, cMESSAGE],
                                @ids) = erOkWithData then
    begin
      upid := ids[0];

      if upid > 0 then
      begin
        if Length(aReplyParams) > 0 then
        begin
          markup := GetJSON(aReplyParams);
          try
            if markup is TJSONObject then
              reply_id := TJSONObject(markup).Get(cMID, -1)
            else
              reply_id := -1;
          finally
            markup.Free;
          end;
        end;

        is_force_reply := 0;
        markup := GetJSON(aReplyMarkup);
        try
          if markup is TJSONObject then
          begin
            if Assigned(TJSONObject(markup).Find(cFORCEREPLY)) then
            begin
              // always true if this field exists
              is_force_reply := 1;
              inline_rows := nil;
            end
            else
            begin
              inline_rows:= TJSONObject(markup).Find(cINLINEKBRD);
            end;

            htmlexpr := THTMLExpression.Create;
            try
              if aParseMode = 'HTML' then begin
                 // parse text
                 plain_msg := UTF8Encode(htmlexpr.ParseHTML(WideString(aMsg)));
              end else begin
                 plain_msg := aMsg;
              end;
              htmlexpr.ExtractCommands(plain_msg);

              // upid, "from", cid, msg, reply_id, force_reply
              if vUsersDB.PREP_AddMessage.ExecToValue(
                                        [upid, fromid, chatid, plain_msg,
                                         reply_id, is_force_reply],
                                        @ids) = erOkWithData then
              begin
                msgid := ids[0];
                if msgid > 0 then
                begin
                  if Assigned(inline_rows) then
                  begin
                    for i := 0 to TJSONArray(inline_rows).Count-1 do
                    begin
                      if vUsersDB.PREP_AddInlineKeyboardRow.ExecToValue(
                                                [msgid, i],
                                                @ids) = erOkWithData then
                      begin
                        rowid := ids[0];
                        if rowid > 0 then
                        begin
                          if TJSONArray(inline_rows)[i] is TJSONArray then
                          begin
                             for j := 0 to TJSONArray(TJSONArray(inline_rows)[i]).Count-1 do
                             begin
                               inline_button := TJSONArray(TJSONArray(inline_rows)[i])[j];
                               if inline_button is TJSONObject then
                               with TJSONObject(inline_button) do
                               begin
                                 // rowid, "label", "url", "data"
                                 vUsersDB.PREP_AddInlineKeyboardBtn.Execute(
                                            [rowid,
                                             Get(cTEXT, ''),
                                             Get(cURL, ''),
                                             Get(cCBCKDATA, '')])
                               end;
                             end;
                          end;
                        end;
                      end;
                    end;
                  end;
                  if htmlexpr.Count > 0 then
                  begin
                    for i := 0 to htmlexpr.Count-1 do
                    if htmlexpr[i].TagId <> tgtNone then
                    begin
                      // mid, "offset", "length", "type", "url", "language"
                      case htmlexpr[i].TagId of
                        tgtUrl: begin
                          obj := htmlexpr[i].Param;
                          obj0 := '';
                        end;
                        tgtCode: begin
                          obj0 := htmlexpr[i].Param;
                          obj := '';
                        end;
                      else
                        obj := '';
                        obj0 := '';
                      end;
                      vUsersDB.PREP_AddMessageEntity.Execute(
                                                [msgid,
                                                 htmlexpr[i].Offset,
                                                 htmlexpr[i].Len,
                                                 htmlexpr[i].Kind, obj, obj0]);
                    end;
                  end;
                  //
                  obj := GetMessage(msgid);
                  if obj <> JSON_EMPTY_OBJ then
                  begin
                    Exit(Format('{"ok":true,"result":%s}',[obj]));
                  end;
                end;
              end;

              Result := BAD_JSON_INTERNAL_UNK;
            finally
              htmlexpr.Free;
            end;
          end;
        finally
          markup.Free;
        end;
      end;
    end else
      Result := BAD_JSON_INTERNAL_UNK;
  except
    on e : EDatabaseError do Result := BAD_JSON_DATABASE_FAIL;
    on e : EJSONParser do Result := BAD_JSON_JSON_PARSER_FAIL;
    on e : EJSON do Result := BAD_JSON_JSON_FAIL;
    else Result := BAD_JSON_INTERNAL_UNK;
  end;
end;

type
  
  { TUpdate }

  TUpdate = class
    Id : Int64;
    Kind : String;
    ObjId : Int64;
    Payload : String;
    constructor Create(aID : Int64; const aKind : String; aObjID : Int64);
  end;

(* Receiving updates for client using long polling.
   Telegram bot API getUpdates<=@link(https://core.telegram.org/bots/api#getupdates)
   Telegram bot API Update<=@link(https://core.telegram.org/bots/api#update)
   @param(fromid is the user-id of the requestor)
   @param(chatid is the id of the client's chat)
   @param(offset is the identifier of the first update to be returned.
          Must be greater by one than the highest among the identifiers of
          previously received updates)
   @param(limit is the limits the number of updates to be retrieved.
          Values between 1-100 are accepted. Defaults to 100.)
   @param(timeout is timeout in seconds for long polling.
          Defaults to 0, i.e. usual short polling. )
   @returns(An array of Update objects. object - in a json notation) *)
function GetUpdates(fromid, chatid: int64; offset, limit, timeout : integer) : String;
const DELTA_TIME = 250;
var
  Kind, obj : String;
  i, cnt, timecur : integer;
  last_uid, obj_id : int64;
  Arr : TFastCollection;
  u : TUpdate;
begin
  try
    Arr := TFastCollection.Create;
    try
      timeout *= 1000;  // to milliseconds
      timecur := 0;
      cnt := 0;
      repeat
        last_uid := -1;
        vUsersDB.PREP_GetUpdates.Lock;
        try
          //id, kind
          with vUsersDB.PREP_GetUpdates do
          if OpenDirect([fromid, chatid, offset]) then
          begin
            repeat
              last_uid := AsInt64[0];
              Kind := AsString[1];
              obj_id := AsInt64[2];

              if obj_id > 0 then
                Arr.Add(TUpdate.Create(last_uid, Kind, obj_id));
              inc(cnt)
            until (not Step) or (cnt >= limit);
          end;
          vUsersDB.PREP_GetUpdates.Close;
        finally
          vUsersDB.PREP_GetUpdates.UnLock;
        end;
        if last_uid > 0 then
        begin
          vUsersDB.PREP_SetLastOffset.Execute([fromid , last_uid+1]);
        end else begin
          Sleep(DELTA_TIME);
          Inc(timecur, DELTA_TIME);
        end;
      until (timecur >= timeout) or (cnt > 0);

      Result := '{"ok":true,"result":[';
      cnt := 0;
      for i := 0 to arr.Count-1 do
      begin
        u := TUpdate(Arr[i]);

        if u.Kind = cMESSAGE then
        begin
          obj := GetMessage(u.ObjId);
          if obj <> JSON_EMPTY_OBJ then
          begin
            if cnt > 0 then Result += ',';
            Result += Format('{"update_id":%d,"message":%s}',[u.Id, obj]);
            inc(cnt);
          end;
        end else
        if u.Kind = cCALLBACK then
        begin
          obj := GetCallbackQuery(u.ObjId);
          if obj <> JSON_EMPTY_OBJ then
          begin
            if cnt > 0 then Result += ',';
            Result += Format('{"update_id":%d,"callback_query":%s}',[u.Id, obj]);
            inc(cnt);
          end;
        end else
        if u.Kind = cCMDSNOTIFY then
        begin
          if cnt > 0 then Result += ',';
          Result += Format('{"update_id":%d,"notify":{"type":"%s"}}',[u.Id, cCMDSNOTIFY]);
          inc(cnt);
        end;
      end;
      Result += ']}';

    finally
      Arr.Free;
    end;
  except
    on e : EDatabaseError do Result := BAD_JSON_DATABASE_FAIL;
    on e : EJSONParser do Result := BAD_JSON_JSON_PARSER_FAIL;
    on e : EJSON do Result := BAD_JSON_JSON_FAIL;
    else Result := BAD_JSON_INTERNAL_UNK;
  end;
end;

{ TWCRequestHelper }

procedure TWCRequestHelper.ProcessQueryString(const FQueryString: String;
  SL: TStrings);
begin
  inherited ProcessQueryString(FQueryString, SL);
end;

{ THTMLCodeTag }

procedure THTMLCodeTag.FillResult(var res: THTMLTagCheckResult);
begin
  inherited FillResult(res);
  res.param:= RegExpObj.Match[5];
end;

{ THTMLHrefTag }

procedure THTMLHrefTag.FillResult(var res: THTMLTagCheckResult);
begin
  inherited FillResult(res);
  res.param:= RegExpObj.Match[5];
end;

{ THTMLTag }

procedure THTMLTag.FillResult(var res : THTMLTagCheckResult);
begin
  res.result := true;
  res.tag := THTMLExpression.TagKindToStr(TgName);
end;

constructor THTMLTag.Create(const aExp: String; aTag: THTMLTagKind);
begin
  RegExp:= aExp;
  RegExpObj := TRegExprWrapper.Create(aExp);
  TgName:=aTag;
end;

destructor THTMLTag.Destroy;
begin
  if Assigned(RegExpObj) then
    RegExpObj.Free;
end;

function THTMLTag.Check(const aTag: String; var res : THTMLTagCheckResult) : Boolean;
begin
  Lock;
  try
    if Assigned(RegExpObj) then
    begin
      if RegExpObj.Exec(aTag) then
      begin
        FillResult(res);
        Result := true;
      end else
        Result := false;
    end;
  finally
    UnLock;
  end;
end;

{ THTMLToken }

function THTMLToken.GetKind: String;
begin
  Result := THTMLExpression.TagKindToStr(TagId);
end;

constructor THTMLToken.Create(aTagID: THTMLTagKind; aOffset: Integer);
begin
  Offset := aOffset;
  Len := 0;
  TagId:= aTagID;
  Param := '';
end;

constructor THTMLToken.CreateFromToken(aToken: THTMLToken);
begin
  Offset := aToken.Offset;
  Len    := aToken.Len;
  TagId  := aToken.TagId;
  Param  := aToken.Param;
end;

{ THTMLExpression }

class procedure THTMLExpression.InitParser;
var
  kind : THTMLTagKind;
begin
  kind := Low(THTMLTagKind);
  while kind < High(THTMLTagKind) do
  begin
    inc(kind);
    RegExpHTMLTags[kind]:=TG_KIND_CLASSES[kind].Create(RE_KINDS[kind], kind);
  end;

  RegExpBotCommandTag := THTMLTag.Create('\/[a-z0-9_]+', tgtBotCommand);
end;

class procedure THTMLExpression.DoneParser;
var i : THTMLTagKind;
begin
  for i := Low(RegExpHTMLTags) to High(RegExpHTMLTags) do
  if Assigned(RegExpHTMLTags[i]) then
  begin
    RegExpHTMLTags[i].Free;
  end;
  RegExpBotCommandTag.Free;
end;

class function THTMLExpression.TagKindToStr(aTag: THTMLTagKind): String;
begin
  Result := TG_KINDS[aTag];
end;

class function THTMLExpression.GetTag(const aTag: String): THTMLTagCheckResult;
begin
  Result.result := false;
  Result.param := '';
  Result.tagid := tgtNone;
  while Result.tagid < High(RegExpHTMLTags) do
  begin
    inc(Result.tagid);
    if RegExpHTMLTags[Result.tagid].Check(aTag, Result) then
    begin
      Exit;
    end;
  end;
end;

(* Very simple parser without syntax checking
   to implement parsing entities in the message text. *)
function THTMLExpression.ParseHTML(const aStr : WideString) : WideString;
var
  L: Integer;
  TL, LTL: Integer;
  I: Integer;
  Done : boolean;
  TagStart,
  TextStart,
  P: PWideChar;   // Pointer to current char.
  C: Char;

  Tag : WideString;

  token : THTMLToken;
  token_tree : TFastSeq;
  strWriter : TStringStream;
  tagRes : THTMLTagCheckResult;
begin
  token_tree := TFastSeq.Create;
  strWriter := TStringStream.Create('', TUnicodeEncoding.Create);
  try
    token := nil;
    I:= 0;
    P:= PWideChar(aStr);
    TL:= Length(aStr);
    Done:= False;
    if P <> nil then
    begin
      TagStart:= nil;
      repeat
        TextStart:= P;
        { Get next tag position }
        while Not (P^ in [ '<', #0 ]) do
        begin
          Inc(P); Inc(I);
          if I >= TL then
          begin
            Done:= True;
            LTL:= P - TextStart;
            if LTL > 0 then
            begin
              strWriter.Write(TextStart^, LTL * Sizeof(WideChar));
            end;
            Break;
          end;
        end;
        if Done then Break;

        { Is there any text before ? }
        if (TextStart <> nil) and (P > TextStart) then
        begin
          LTL:= P - TextStart;
          { Yes, copy to buffer }
          if LTL > 0 then
          begin
            strWriter.Write(TextStart^, LTL * Sizeof(WideChar));
          end;
        end else
        begin
          TextStart:= nil;
          LTL := 0;
        end;
        { No }

        TagStart:= P;
        while Not (P^ in [ '>', #0]) do
        begin
          // Find string in tag
          if (P^ = '"') or (P^ = '''') then
          begin
            C:= P^;
            Inc(P); Inc(I); // Skip current char " or '

            // Skip until string end
            while Not (P^ in [C, #0]) do
            begin
              Inc(P);Inc(I);
            end;
          end;

          Inc(P);Inc(I);
          if I >= TL then
          begin
            Done:= True;
            Break;
          end;
        end;
        if Done then Break;

        { Copy this tag to buffer }
        L:= P - TagStart + 1;

        SetLength(Tag, L);
        StrLCopy(@Tag[1], TagStart, L);

        if Length(Tag) > 2 then
        begin
          if Tag[2] = '/' then // closing tag
          begin
            if assigned(token) then begin
              token.Len := LTL;
              if token.Len > 0 then
                Self.Add(token) else
                FreeAndNil(token);
            end;
            token := THTMLToken(token_tree.PopValue);
            if assigned(token) then
            begin
              token.Offset := strWriter.Position div Sizeof(WideChar);
            end;
          end else begin // opening tag
            if assigned(token) then begin
              token.Len := I - 1 - token.Offset;
              Self.Add(THTMLToken.CreateFromToken(token));
              token_tree.Push_back(token);
            end;
            tagRes := GetTag(UTF8Encode(Tag));
            if tagRes.result then
            begin
              token := THTMLToken.Create(tagRes.tagid, strWriter.Position div Sizeof(WideChar));
              token.Param:=tagRes.param;
            end else
              token := nil;
          end;
        end;
        Inc(P); Inc(I);
        if I >= TL then Break;
      until (Done);
      while assigned(token) do begin
        token.Len := I + 1 - token.Offset;
        Self.Add(token);
        token := THTMLToken(token_tree.PopValue);
      end;
    end;

    Result := strWriter.UnicodeDataString;
  finally
    strWriter.Free;
    token_tree.free;
  end;
end;

(* Extract commands from the string expression.
   Saving only uniq commands *)
procedure THTMLExpression.ExtractCommands(const aStr: String);
var
  token : THTMLToken;
  off, len : integer;
  comm : String;
begin
   RegExpBotCommandTag.Lock;
   try
     if RegExpBotCommandTag.RegExpObj.Exec(aStr) then
     begin
       repeat
          off := RegExpBotCommandTag.RegExpObj.MatchPos[0]-1;
          len := RegExpBotCommandTag.RegExpObj.MatchLen[0];
          comm := RegExpBotCommandTag.RegExpObj.Match[0];
          if Find(tgtBotCommand, comm) < 0 then
          begin
            token := THTMLToken.Create(tgtBotCommand, off);
            token.Len := len;
            token.Param := comm;
            Self.Add(token);
          end;
       until not RegExpBotCommandTag.RegExpObj.ExecNext;
     end;
   finally
     RegExpBotCommandTag.UnLock;
   end;
end;

(* Find tag with given kind and param value *)
function THTMLExpression.Find(tag : THTMLTagKind; const s : String): Integer;
var
  i: integer;
begin
  for i := 0 to Count-1 do
  begin
    if (Self[i].TagId = tag) and
       (Self[i].Param = s) then
    begin
      Exit(i);
    end;
  end;
  Result := -1;
end;

{ TUpdate }

constructor TUpdate.Create(aID: Int64; const aKind: String; aObjID : Int64);
begin
  ID := aID;
  Kind:= aKind;
  ObjId:= aObjID;
  Payload:= '';
end;


{ TSerializeCallbackQuery }

constructor TSerializeCallbackQuery.Create;
begin
  inherited Create('callback_query_to_json', 7, sqlteUtf8, sqlfScalar, true);
end;

procedure TSerializeCallbackQuery.ScalarFunc(argc: integer);
var
  id, from, ci, chat, url, data, res, mid : string;
begin
  id   := AsString(0);
  from := AsString(1);
  ci   := AsString(2);
  chat := AsString(3);
  mid  := AsString(4);
  url  := AsString(5);
  data := AsString(6);

  res := format('{"id":"%s","from":%s,"chat_instance":"%s",'+
                 '"message":{"chat":%s,"message_id":%s,"date":0}',
                [id, from, ci, chat, mid]);
  if (length(url) > 0) then
  begin
    res += format(',"url":"%s"', [StringToJSONString(url)]);
  end;
  if (length(data) > 0) then
  begin
    res += format(',"data":"%s"', [StringToJSONString(data)]);
  end;
  res += '}';
  SetResult(res);
end;

{ TSerializeInlineButton }

constructor TSerializeInlineButton.Create;
begin
  inherited Create('inline_btn_to_json', 3, sqlteUtf8, sqlfScalar, true);
end;

procedure TSerializeInlineButton.ScalarFunc(argc: integer);
var
  text, url, cbk_data,
  res : String;
begin
  text     := AsString(0);
  url      := AsString(1);
  cbk_data := AsString(2);

  res := format('{"text":"%s"', [StringToJSONString(text)]);
  if (length(url) > 0) then
  begin
    res += format(',"url":"%s"', [StringToJSONString(url)]);
  end;
  if (length(cbk_data) > 0) then
  begin
    res += format(',"callback_data":"%s"', [StringToJSONString(cbk_data)]);
  end;
  res += '}';
  SetResult(res);
end;

{ TSerializeTextEntity }

constructor TSerializeTextEntity.Create;
begin
  inherited Create('entity_to_json', 5, sqlteUtf8, sqlfScalar, true);
end;

procedure TSerializeTextEntity.ScalarFunc(argc: integer);
var
  tp, offset, len, url, lang,
  res : String;
begin
  tp     := AsString(0);
  offset := AsString(1);
  len    := AsString(2);
  url    := AsString(3);
  lang   := AsString(4);

  res := format('{"type":"%s","offset":%s,"length":%s',
                    [tp, offset, len]);
  if (length(url) > 0) then
  begin
    res += format(',"url":"%s"',[StringToJSONString(url)]);
  end;
  if (length(lang) > 0) then
  begin
    res += format(',"language":"%s"',[StringToJSONString(lang)]);
  end;
  res += '}';
  SetResult(res);
end;

{ TSerializeMessage }

constructor TSerializeMessage.Create;
begin
  inherited Create('msg_to_json', 8, sqlteUtf8, sqlfScalar, true);
end;

procedure TSerializeMessage.ScalarFunc(argc: integer);
var
  mid, date, msg, sender, target, text_entities, inline_kb, reply_markup,
  res : String;
  force_reply : integer;
begin
  mid           := AsString(0);
  sender        := AsString(1);
  target        := AsString(2);
  date          := AsString(3);
  msg           := AsString(4);
  text_entities := AsString(5);
  inline_kb     := AsString(6);
  force_reply   := AsInt(7);

  res := format('{"message_id":%s,"from":%s,"chat":%s,"date":%s,"text":"%s"',
                    [mid, sender, target, date, StringToJSONString(msg)]);

  if (length(text_entities) > 0) and (text_entities <> JSON_EMPTY_ARRAY) then
  begin
    res += ',"entities":'+text_entities;
  end;

  reply_markup := '';
  if force_reply > 0 then
  begin
    reply_markup := Format('{"force_reply":%s',
                           [BoolToStr(Boolean(force_reply),
                                             JSON_TRUE, JSON_FALSE)]);
  end;

  if (length(inline_kb) > 0) and
     (inline_kb <> JSON_EMPTY_NESTED_ARRAY) and
     (inline_kb <> JSON_EMPTY_ARRAY) then
  begin
    if (length(reply_markup) = 0) then
      reply_markup := '{"inline_keyboard":'+inline_kb
    else
      reply_markup += ',"inline_keyboard":'+inline_kb;
  end;

  if (length(reply_markup) > 0) then
  begin
    reply_markup+='}';
    res += ',"reply_markup":'+reply_markup;
  end;
  res += '}';
  SetResult(res);
end;

{ TSerializeUser }

constructor TSerializeUser.Create;
begin
  inherited Create('user_to_json', 6, sqlteUtf8, sqlfScalar, true);
end;

procedure TSerializeUser.ScalarFunc(argc: integer);
var
  id, username, fn, ln, lang,
  res : String;
  is_bot : integer;
begin
  id      := AsString(0);
  is_bot   := AsInt(1);
  username := AsString(2);
  fn       := AsString(3);
  ln       := AsString(4);
  lang     := AsString(5);

  res := format('{"id":%s,"is_bot":%s,"username":"%s",'+
                 '"first_name":"%s","last_name":"%s","language_code":"%s"}',
                    [id,
                     BoolToStr(Boolean(is_bot), JSON_TRUE, JSON_FALSE),
                     StringToJSONString(username), StringToJSONString(fn),
                     StringToJSONString(ln), StringToJSONString(lang)]);
  SetResult(res);
end;

{ TSerializeChat }

constructor TSerializeChat.Create;
begin
  inherited Create('chat_to_json', 3, sqlteUtf8, sqlfScalar, true);
end;

procedure TSerializeChat.ScalarFunc(argc: integer);
var
  id, username, fn,
  res : String;
begin
  id      := AsString(0);
  username := AsString(1);
  fn       := AsString(2);

  res := format('{"id":%s,"first_name":"%s","username":"%s","type":"private"}',
                    [id, StringToJSONString(fn), StringToJSONString(username)]);
  SetResult(res);
end;

{ TRESTTgBotAPIUsersDB }

constructor TRESTTgBotAPIUsersDB.Create;
begin
  FUsersDB := TExtSqlite3Dataset.Create(nil);
end;

procedure TRESTTgBotAPIUsersDB.DoHelp({%H-}aData : TObject);
begin
  try
    FUsersDB.FileName := Application.SitePath + TRESTJsonConfigHelper.Config.UsersDB;
    FUsersDB.AddFunction(TSerializeUser.Create);
    FUsersDB.AddFunction(TSerializeChat.Create);
    FUsersDB.AddFunction(TSerializeMessage.Create);
    FUsersDB.AddFunction(TSerializeInlineButton.Create);
    FUsersDB.AddFunction(TSerializeTextEntity.Create);
    FUsersDB.AddFunction(TSerializeCallbackQuery.Create);
    FUsersDB.ExecSQL(
    'create table if not exists clients'+
      '(uid integer primary key autoincrement, '+
       'username text,'+
       'first_name text,'+
       'last_name text,'+
       'language_code text default ''en'','+
       'is_bot int default 0,'+
       'offset integer,'+
       'unique (username));');
    FUsersDB.ExecSQL(
    'create table if not exists commands'+
      '(bid integer references clients(uid) on delete cascade, '+
       'scopeType text default ''default'','+
       'scopeCID int default 0,'+
       'scope text default ''{}'','+
       'lang text default ''default'','+
       'vals text default ''[]'','+
       'unique (bid, scopeType, scopeCID, lang));');
    FUsersDB.ExecSQL(
    'create table if not exists updates'+
      '(id integer primary key autoincrement, '+
       // target user/chat
       'cid integer references clients(uid) on delete cascade,'+
       'kind text,'+
       'stamp text default current_timestamp);');
    FUsersDB.ExecSQL(
    'create table if not exists messages'+
      '(id integer primary key autoincrement,'+
       // update id
       'upid integer references updates(id) on delete cascade,'+
       '"from" integer references clients(uid) on delete cascade,'+
       // target user chat (as all chats are private - cid == uid of chat-owner
       'cid integer references clients(uid) on delete cascade,'+
       'reply_id integer default null,'+ // reply-to message
       'date int default (strftime(''%s'', ''now'')),'+
       'msg text default '''','+
       'force_reply int default 0,'+
       'FOREIGN KEY (reply_id) REFERENCES messages(id) on delete set null);');
    FUsersDB.ExecSQL(
    'create table if not exists msg_text_entities'+
     // message id
      '(mid integer references messages(id) on delete cascade,'+
       '"offset" integer,'+
       '"length" integer,'+
       '"type" text default '''','+
       '"url" text default null,'+
       '"language" text default ''plain'');');
    FUsersDB.ExecSQL(
    'create table if not exists inline_button_rows'+
      '(id integer primary key autoincrement, '+
       'mid integer references messages(id) on delete cascade,'+
       '"rownum" integer default 0);');
    FUsersDB.ExecSQL(
    'create table if not exists inline_buttons'+
      '("rowid" integer references inline_button_rows(id) on delete cascade,'+
       '"label" text default '''','+
       '"url" text default '''','+
       '"data" text default '''');');
    FUsersDB.ExecSQL(
    'create table if not exists callback_queries'+
      '(id integer primary key autoincrement, '+
       '"from" integer references clients(uid) on delete cascade,'+
       'upid integer references updates(id) on delete cascade,'+
       'mid integer references messages(id) on delete cascade,'+
       'chat_instance int default 255,'+ // debug purps only
       '"url" text default '''','+
       '"data" text default '''');');


    PREP_ClearNotify := FUsersDB.AddNewPrep(
    'delete from updates where cid != ?1 and kind == ?2;');
    PREP_AddNotify := FUsersDB.AddNewPrep(
    'insert into updates (cid, kind) '+
    'select uid, ?2 from clients where uid != ?1;');

    PREP_GetClient := FUsersDB.AddNewPrep(
    'SELECT uid, username, first_name, '+
    'last_name,'+
    'language_code,'+
    'is_bot '+
    'FROM clients WHERE uid == ?1;');
    PREP_GetClientID := FUsersDB.AddNewPrep(
                          'SELECT uid,'+
                                 'first_name,'+
                                 'last_name,'+
                                 'is_bot,'+
                                 'language_code '+
                                 'FROM clients WHERE username == ?1;');

    PREP_AddClient := FUsersDB.AddNewPrep(
    'with _ex_ as (select * from clients where username = ?1 limit 1)'+
    'INSERT OR REPLACE INTO clients '+
    '(uid, username, first_name, last_name, language_code, is_bot, offset) '+
    'values('+
    'CASE WHEN EXISTS(select * from _ex_) THEN (select uid from _ex_) ELSE NULL end,'+
    '?1, ?2, ?3, ?4, ?5, '+
    'CASE WHEN EXISTS(select * from _ex_) THEN (select offset from _ex_) ELSE 0 end)'+
    'RETURNING uid;');
    PREP_SetCommands := FUsersDB.AddNewPrep(
    'INSERT OR REPLACE INTO commands '+
    '(bid, vals, scopeType, scopeCID, scope, lang) '+
    'values('+
    '?1, ?2, ?3, ?4, ?5, ?6);');
    PREP_GetCommands := FUsersDB.AddNewPrep(
    'with _ex_ as ('+
    'select vals, 1 as score from commands '+
      'where bid = ?1 and scopeType = ?2 and (scopeCID = ?3) and lang = ?4 '+
    'union all '+
    'select vals, 2 from commands '+
      'where bid = ?1 and scopeType = ?2 and (scopeCID = ?3) and lang = ''default'' '+
    'union all '+
    'select vals, 3 as score from commands '+
      'where bid = ?1 and scopeType = ''all_private_chats'' and lang = ?4 '+
    'union all '+
    'select vals, 4 from commands '+
      'where bid = ?1 and scopeType = ''all_private_chats'' and lang = ''default'' '+
    'union all '+
    'select vals, 5 from commands '+
      'where bid = ?1 and scopeType = ''default'' and lang = ?4 '+
    'union all '+
    'select vals, 6 from commands '+
      'where bid = ?1 and scopeType = ''default'' and lang = ''default'' '+
    'union all '+
    'select vals, 7 from commands '+
      'where bid = ?1 and scopeType = ''default'' and lang = ''en'' '+
    'order by score asc) '+
    'select vals from _ex_ limit 1;');
    PREP_AddUpdate:= FUsersDB.AddNewPrep(
    'INSERT INTO updates '+
    '(cid, kind) '+
    'values (?1, ?2) RETURNING id;');
    PREP_AddMessage:= FUsersDB.AddNewPrep(
    'INSERT INTO messages '+
    '(upid, "from", cid, msg, reply_id, force_reply) '+
    'values (?1, ?2, ?3, ?4, case when ?5 < 0 then null else ?5 end, ?6) '+
    'RETURNING id;');
    PREP_AddMessageEntity:= FUsersDB.AddNewPrep(
    'INSERT INTO msg_text_entities '+
    '(mid, "offset", "length", "type", "url", "language") '+
    'values (?1, ?2, ?3, ?4, ?5, ?6);');
    PREP_AddInlineKeyboardRow:= FUsersDB.AddNewPrep(
    'INSERT INTO inline_button_rows '+
    '(mid, "rownum") '+
    'values (?1, ?2) RETURNING id;');
    PREP_AddInlineKeyboardBtn:= FUsersDB.AddNewPrep(
    'INSERT INTO inline_buttons '+
    '("rowid", "label", "url", "data") '+
    'values (?1, ?2, ?3, ?4);');
    PREP_AddQuery:= FUsersDB.AddNewPrep(
    'INSERT INTO callback_queries '+
    '(upid, mid, "from", "url", "data") '+
    'values (?1, ?2, ?3, ?4, ?5) RETURNING id;');
    PREP_SetLastOffset := FUsersDB.AddNewPrep(
    'update clients set offset=?2 where uid == ?1;');
    PREP_GetTotalOffset := FUsersDB.AddNewPrep(
    'select max(id) from updates;');
    PREP_GetLastOffset := FUsersDB.AddNewPrep(
    'select offset from clients where (uid == ?1);');
    PREP_GetUpdates    := FUsersDB.AddNewPrep(
    'SELECT id, kind, ifnull(case '+
           'when kind=="message" then '+
            '(select messages.id from messages where '+
             'messages.upid == updates.id and messages."from" != ?1) '+
           'when kind=="callback_query" then '+
            '(select callback_queries.id from callback_queries where '+
             'callback_queries.upid == updates.id and '+
             'callback_queries."from" != ?1) '+
           'else -1 end, -1) as objid FROM updates '+
    'where ((cid == ?2) or (?2 < 0)) and (objid > 0) and '+
          '(id >= (case when ?3 > 0 then ?3 '+
                 'else (select offset from clients where (uid == ?1)) end)) '+
          'order by id asc limit 100;');
    PREP_GetCallbackQuery  := FUsersDB.AddNewPrep(
    'with _qr_ as (select id, '+
        'fr.uid as fr_uid, '+
        'fr.is_bot as fr_is_bot, '+
        'fr.username as fr_username, '+
        'fr.first_name as fr_first_name, '+
        'fr.last_name as fr_last_name, '+
        'fr.language_code as fr_language_code, '+
        'chat_instance,'+
        'mid,'+
        '"url",'+
        '"data" '+
        'from callback_queries inner join clients as fr on "from" == fr.uid '+
                                 'where callback_queries.id == ?1)'+
    'SELECT callback_query_to_json('+
          'id,'+
          'user_to_json(fr_uid, fr_is_bot, fr_username, fr_first_name, '+
                       'fr_last_name, fr_language_code),'+
          'chat_instance,'+
          'chat_to_json(fr_uid, fr_first_name, fr_username),'+
          'mid,'+
          '"url",'+
          '"data") '+
          'from _qr_;');
    PREP_GetMessage   := FUsersDB.AddNewPrep(
    'with _ikbrows_ as (select '+
          '''[''||group_concat('+
             'inline_btn_to_json(ibs."label",'+
                                'ibs."url",'+
                                'ibs."data"),'','')||'']'' as brows '+
          'from inline_button_rows inner join inline_buttons as ibs on '+
                                      'inline_button_rows.id == ibs."rowid" '+
                                   'where inline_button_rows.mid == ?1 '+
                                   'group by inline_button_rows.id),'+
    '_ikbuttons_ as (select '+
          '''[''||group_concat(_ikbrows_.brows,'','')||'']'' '+
          'from _ikbrows_),'+
    '_entities_ as (select '+
          '''[''||group_concat(entity_to_json(ent."type",ent."offset",'+
                                             'ent."length",ent."url",'+
                                             'ent."language"),'','')||'']'' '+
          'from msg_text_entities as ent where ent.mid == ?1),'+
    '_msgs_ as (select id, '+
          'fr.uid as fr_uid, '+
          'fr.is_bot as fr_is_bot, '+
          'fr.username as fr_username, '+
          'fr.first_name as fr_first_name, '+
          'fr.last_name as fr_last_name, '+
          'fr.language_code as fr_language_code, '+
          'trg.uid as trg_uid, '+
          'trg.first_name as trg_first_name, '+
          'trg.username as trg_username, '+
          'date,'+
          'msg,'+
          'reply_id,'+
          'force_reply '+
          'from messages join clients as fr on "from" == fr.uid, '+
                             'clients as trg on cid == trg.uid '+
                                   'where messages.id == ?1)'+
      'SELECT msg_to_json('+
            'id,'+
            'user_to_json(fr_uid, fr_is_bot, fr_username, fr_first_name, '+
                         'fr_last_name, fr_language_code),'+
            'chat_to_json(trg_uid, trg_first_name, trg_username),'+
            'date,'+
            'msg,'+
            'ifnull((select * from _entities_), ''[]''),'+
            'ifnull((select * from _ikbuttons_), ''[]''),'+
            'force_reply), ifnull(_msgs_.reply_id, -1) '+
            'from _msgs_;');
    PREP_GetUser    := FUsersDB.AddNewPrep(
    'SELECT user_to_json(uid, is_bot, username, first_name, '+
                        'last_name, language_code) '+
                        'from clients where (uid == ?1);');

    BotId:= AddUserInternal(Self,
                            TRESTJsonConfigHelper.Config.BotName,
                            TRESTJsonConfigHelper.Config.BotName,
                            '', 'en', true);
  except
    on E : Exception do
    begin
      Application.DoError(E.ToString);
      Application.NeedShutdown := true;
    end;
  end;
end;

destructor TRESTTgBotAPIUsersDB.Destroy;
begin
  FUsersDB.Free;
  inherited Destroy;
end;

procedure TRESTTgBotAPIUsersDB.Execute(const Str : String);
begin
  FUsersDB.ExecuteDirect(Str);
end;

procedure TRESTTgBotAPIUsersDB.MaintainStep10s;
begin
end;

procedure TRESTTgBotAPIUsersDB.MaintainStep60s;
begin
end;

procedure TRESTTgBotAPIUsersDB.MaintainStep1hr;
begin
end;

class function TRESTTgBotAPIUsersDB.UsersDB : TRESTTgBotAPIUsersDB;
begin
  if not assigned(vUsersDB) then
    vUsersDB := TRESTTgBotAPIUsersDB.Create;
  Result := vUsersDB;
end;

function DecodeHelper(Request : TWCRequest; const aNames : array of String;
                              aTarget : TFastHashList;
                              const aDefaults : array of variant):boolean;
var
  QF : TStrings;
  JSON : String;
begin
  if Request.ContentType = 'application/x-www-form-urlencoded' then
  begin
    QF := Request.ContentFields;
    Request.ProcessQueryString(Request.Content, QF);
    JSON := '';
  end else begin
    QF := Request.QueryFields;
    if Request.ContentType = 'application/json' then
      JSON := Request.Content
    else
      JSON := '';
  end;

  Result := DecodeParamsWithDefault(QF, aNames, JSON, aTarget, aDefaults);
end;

{ TTBAGetUpdates }

procedure TTBAGetUpdates.Execute;
begin
  if DecodeHelper(Request, [cOFFSET, cLIMIT, cTIMEOUT], Params, [0, 100, 60]) then
    Response.Content := GetUpdates(vUsersDB.BotId, -1, Params[0], Params[1], Params[2]) else
    Response.Content := BAD_JSON_MALFORMED_REQUEST;
  inherited Execute;
end;

{ TTBAGetMe }

procedure TTBAGetMe.Execute;
begin
  Response.Content := GetMe();
  inherited Execute;
end;

{ TTBAAddClient }

procedure TTBAAddClient.Execute;
begin
  if DecodeHelper(Request, [cUSERNAME, cFIRSTNAME, cLASTNAME, cLANG],
                           Params, ['', '', '', 'en']) then
  begin
    if (Length(Params[0]) > 0) then
      Response.Content := AddClient(Params[0], Params[1],
                                               Params[2],
                                               Params[3], false) else
      Response.Content := BAD_JSON_MALFORMED_REQUEST;
  end else Response.Content := BAD_JSON_MALFORMED_REQUEST;
  inherited Execute;
end;

{ TTBAClientGetUpdates }

procedure TTBAClientGetUpdates.Execute;
begin
  if DecodeHelper(Request, [cCID, cOFFSET, cLIMIT], Params, [0, 0, 100]) then
    Response.Content := GetUpdates(Params[0], Params[0],
                                              Params[1],
                                              Params[2], 0) else
    Response.Content := BAD_JSON_MALFORMED_REQUEST;
  inherited Execute;
end;

{ TTBAAnsCallback }

procedure TTBAAnsCallback.Execute;
begin
  Response.Content := OK_JSON;
  inherited Execute;
end;

{ TTBASetMyCommands }

procedure TTBASetMyCommands.Execute;
begin
  if DecodeHelper(Request, [cCOMMANDS, cSCOPE, cLANG],
                            Params, ['[]', '{}', 'en']) then
  begin
    if length(Params[0]) > 0 then
      Response.Content := SetMyCommands(vUsersDB.BotId,
                                                      Params[0],
                                                      Params[1],
                                                      Params[2]) else
      Response.Content := BAD_JSON_MALFORMED_REQUEST;
  end else Response.Content := BAD_JSON_MALFORMED_REQUEST;
  inherited Execute;
end;

{ TTBAGetMyCommands }

procedure TTBAGetMyCommands.Execute;
begin
  if DecodeHelper(Request, [cSCOPE, cLANG],
                            Params, ['{}', 'en']) then
  begin
    if length(Params[0]) > 0 then
      Response.Content := GetMyCommands(vUsersDB.BotId,
                                                      Params[0],
                                                      Params[1]) else
      Response.Content := BAD_JSON_MALFORMED_REQUEST;
  end else Response.Content := BAD_JSON_MALFORMED_REQUEST;
  inherited Execute;
end;

{ TTBAClientGetCommands }

procedure TTBAClientGetCommands.Execute;
begin
  if DecodeHelper(Request, [cCID], Params, [0]) then
  begin
    if length(Params[0]) > 0 then
      Response.Content := GetBotCommands(vUsersDB.BotId, Params[0]) else
      Response.Content := BAD_JSON_MALFORMED_REQUEST;
  end else Response.Content := BAD_JSON_MALFORMED_REQUEST;
  inherited Execute;
end;

{ TTBASendMessage }

procedure TTBASendMessage.Execute;
begin
  if DecodeHelper(Request, [cCID, cTEXT, cPARSEMODE, cREPLYPARAMS, cREPLYMARKUP],
                            Params, [0, '', '', '{}', '{}']) then
  begin
    if (Params[0] > 0) then
      Response.Content := SendMessage(vUsersDB.BotId, Params[0],
                                                      Params[1],
                                                      Params[2],
                                                      Params[3],
                                                      Params[4]) else
      Response.Content := BAD_JSON_MALFORMED_REQUEST;
  end else Response.Content := BAD_JSON_MALFORMED_REQUEST;
  inherited Execute;
end;

{ TTBAClientSendUpdate }

procedure TTBAClientSendUpdate.Execute;
var
  jsonObj, r : TJSONObject;
begin
  if DecodeHelper(Request, [cCID, cTYPE, cPAYLOAD],
                            Params, [0, '', '{}']) then
  begin
    if (Params[0] > 0) and (Length(Params[1]) > 0) then
    begin
      if Params[1] = cMESSAGE then
      begin
         jsonObj := TJSONObject(GetJSON(Params[2]));
         try
           r := TJSONObject.Create([cMID, 0]);
           try
             Response.Content := SendMessage(Params[0],
                                             Params[0],
                                             jsonObj.Get(cTEXT, ''),
                                             '',
                                             jsonObj.Get(cREPLYPARAMS, r).AsJSON,
                                             '{}');
           finally
             r.Free;
           end;
         finally
           jsonObj.Free;
         end;
      end else
      if Params[1] = cCALLBACK then
      begin
        jsonObj := TJSONObject(GetJSON(Params[2]));
        try
          r := TJSONObject.Create([cMID, 0]);
          try
            Response.Content := SendCallback(Params[0],
                                             jsonObj.Get(cMID, 0),
                                             jsonObj.Get(cDATA, ''),
                                             jsonObj.Get(cURL, ''));
          finally
            r.Free;
          end;
        finally
          jsonObj.Free
        end;
      end;
    end else
      Response.Content := BAD_JSON_MALFORMED_REQUEST;
  end else Response.Content := BAD_JSON_MALFORMED_REQUEST;
  inherited Execute;
end;

initialization
  TJSONData.CompressedJSON := true;
  vServerDateTimeFormat := DefaultFormatSettings;
  vServerDateTimeFormat.LongDateFormat:= 'dd.mm.yy';
  vServerDateTimeFormat.LongTimeFormat:= 'hh:nn:ss';
  THTMLExpression.InitParser;

finalization
  THTMLExpression.DoneParser;
end.

