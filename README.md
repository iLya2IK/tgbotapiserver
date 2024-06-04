# REST Telegram Bot API

## Short description
This server is designed to close an existing gap in the set of tools for testing bots by clients (without creating additional accounts and without using the [Telegram API](https://core.telegram.org/api/invoking)). Currently, the server implements a limited set of messages and methods sufficient for the development and testing of the simplest [service bots](https://core.telegram.org/bots/api#making-requests):
* Registration of the bot via Telegram Bot API [/getMe](https://core.telegram.org/bots/api#getme);
* Registration of multiple clients;
* Sending/updating a set of bot commands [/get-setMyCommands](https://core.telegram.org/bots/api#setmycommands);
* Sending, receiving updates (now text messages and callback_queries only) both for the bot (via Telegram Bot API) and for client applications [/getUpdates](https://core.telegram.org/bots/api#getupdates), [/sendMessage](https://core.telegram.org/bots/api#sendmessage);
* Support for ParseMode=HTML and [MessageEntities](https://core.telegram.org/bots/api#messageentity) for the body of a text message;
* Support for the built-in keyboard (under the message) [/inlineKeyboardMarkup](https://core.telegram.org/bots/api#inlinekeyboardmarkup);
* Force Reply support [/ForceReply](https://core.telegram.org/bots/api#forcereply).

# How to deal with the server example?
* Build it using the necessary development environment and libraries or download precompiled release.
* Do not forget to generate a certificate and key file for your localhost (put them in ./openssl folder). 
* Command-line to start your test server: "./tgbotapiserver {PORTNUM}" (PORTNUM - is a number of the listening port - 8080 for example).
* To create your own bot, use the appropriate tools. During development, to test it on your test server, use an arbitrary bot token and set the endpoint address:port of your test server. As example you can use the [SPS bot](https://github.com/iLya2IK/tgspsbot).
* To emulate the bot's client - use the [Telegram Bot API Client App](https://github.com/iLya2IK/tgbottestclient).

## Development environment
Free Pascal (v3.2.0) + Lazarus (v2.0.10)

## Necessary libraries
1. SQLite
2. OpenSSL (v1.1.0 or higher)
3. Zlib

## Additional libraries (to build from sources)
4. CommonUtils - you can download lpk and sources [here](https://github.com/iLya2IK/commonutils)
5. WCHTTPServer - you can download lpk and sources [here](https://github.com/iLya2IK/wchttpserver)

## Copyrights and contibutions
* [SQLite - database engine](https://www.sqlite.org)
* [OpenSSL - Cryptography and SSL/TLS Toolkit](https://www.openssl.org)
* [Zlib - Compression Library](https://zlib.net/)
* [CommonUtils - lightweight lists, collections, seqs and hashes, helping classes for sqlite3 extension, gz compression, data streams - Copyright (c) 2018-2021, Ilya Medvedkov](https://github.com/iLya2IK/commonutils)
* [WCHTTPServer - Copyright (c) 2020-2021, Ilya Medvedkov](https://github.com/iLya2IK/wchttpserver)
