@echo off
rem
    rem （概要）
    rem Coverity スナップショット取得および問題報告書作成スクリプト
    rem 
    rem cov_snap_2.bat は、Coverity Connect サーバー（以下 CC）に登録した特定のスナップショットのすべての指摘を抽出するスクリプトです
    rem ハンバーガーメニューからエクスポートしても取得できないソースコードビューのメインイベント他の指摘情報を取得できます
    rem さらに Azure OpenAI Service を利用して、指摘結果のCSVファイルから問題報告書を作成します（bug_report_2.py が担当）
    rem 
    rem ※ Coverity ライセンス上の制約により、ライセンスを保有する認定ユーザーだけが指摘結果を取得できます
    rem   （CCに登録されている認定ユーザーのみに配信します）
    rem 
    rem （機能）
    rem Outlook を使い、件名が、先頭から識別子 [cov_snap] で始まり、空白区切りで複数の引数が書かれたメールが、
    rem sender@sample.com 宛てに届くとこのバッチファイルが起動します（Outlook VBA から起動されます）
    rem 
    rem 引数の数により処理を切り替えます
    rem ・引数の数が3個:
    rem   CC から指摘を取得し（cov_snap）、bug_report を起動後、CSVファイル（を圧縮したZIPファイル）を依頼者のみに返信します
    rem   （ソースコードを GitLab から取得しません）
    rem   第1引数: CC_ストリーム名
    rem   第2引数: CC_スナップショットID
    rem   第3引数: メール送信者（Outlook VBAが付加します）
    rem 
    rem   件名の例: [cov_snap] cc_stream_name 14090
    rem   バッチファイルの呼び出し例: cov_snap_2.bat cc_stream_name 14090 sender@sample.com
    rem 
    rem ・引数の数が4個:
    rem   CC から指摘を取得し（cov_snap）、bug_report を起動後、CSVファイル（を圧縮したZIPファイル）をアドレスファイルに登録されたメールアドレスに返信します
    rem   （ソースコードを GitLab から取得しません）
    rem   第1引数: GitLab_グループ名
    rem   第2引数: CC_ストリーム名
    rem   第3引数: CC_スナップショットID
    rem   第4引数: メール送信者（Outlook VBAが付加します）
    rem 
    rem   件名の例: [cov_snap] gitlab_group_name cc_stream_name 14090
    rem   バッチファイルの呼び出し例: cov_snap_2.bat gitlab_group_name cc_stream_name 14090 sender@sample.com
    rem 
    rem ・引数の数が7個:
    rem   ソースコードを GitLab から取得し、cov_snap, bug_report を起動後、CSVファイル（を圧縮したZIPファイル）をアドレスファイルに登録されたメールアドレスに返信します
    rem   第1引数: GitLab_グループ名
    rem   第2引数: GitLab_プロジェクト名
    rem   第3引数: GitLab_ブランチ名
    rem   第4引数: CC_グループ名
    rem   第5引数: CC_ストリーム名
    rem   第6引数: CC_スナップショットID
    rem   第7引数: メール送信者（Outlook VBAが付加します）
    rem 
    rem   件名の例: [cov_snap] gitlab_group_name gitlab_project_name gitlab_branch_name cc_group_name cc_stream_name 15076 sender@sample.com
    rem   バッチファイルの呼び出し例: cov_snap_2.bat gitlab_group_name gitlab_project_name gitlab_branch_name cc_group_name cc_stream_name 15076 sender@sample.com
    rem 
    rem   ※ CSVファイルのB列ファイル名（変更前）と、CSVファイルのB列ファイル名（変更後）は、projects.cfg から取得します
    rem 
    rem ・引数の数が8個:
    rem   ソースコードを Perforce から取得し、cov_snap を起動後、CSVファイル（を圧縮したZIPファイル）をアドレスファイルに登録されたメールアドレスに返信します
    rem   （bug_report は起動しません）
    rem   第1引数: p4（固定識別子）
    rem   第2引数: Perforce_グループ名
    rem   第3引数: Perforce_depot_path
    rem   第4引数: Perforce_revision
    rem   第5引数: CC_グループ名
    rem   第6引数: CC_ストリーム名
    rem   第7引数: CC_スナップショットID
    rem   第8引数: メール送信者（Outlook VBAが付加します）
    rem 
    rem   件名の例: [cov_snap] p4_group_name //depot/p4_group_name/ head cc_group_name cc_stream_name 15048 sender@sample.com
    rem   バッチファイルの呼び出し例:  p4_group_name //depot/p4_group_name/ head cc_group_name cc_stream_name 15048 sender@sample.com
    rem 
    rem   ※ CSVファイルのB列ファイル名（変更前）と、CSVファイルのB列ファイル名（変更後）は、projects.cfg から取得する
    rem 
    rem すべての情報を SOAP API を使って取得します（mergeKey による結合不要）
    rem CSVファイルを生成し、ZIPファイルに圧縮します
    rem 結果は CC 画面の設定（歯車アイコン）で、「発生箇所を表示」にチェックが入った条件で取得した結果と同等です
    rem エクセルで CSVファイルを開き、CID の重複データを削除すると、「発生箇所を表示」にチェックが入らない条件で取得した結果と同等になります
    rem 
    rem CSVファイル（を圧縮したZIPファイル）を送信後、問題報告書を作成し、PDFファイル他をメール送信者宛に配布します
    rem
    rem （実行環境）
    rem Windows10 c:\cov
    rem あらかじめ c:\cov, c:\cov\groups, c:\cov\log, S:\path\to\coverity\config, S:\path\to\coverity\address ディレクトリが必要です
    rem このバッチファイルは、Outlook VBA ThisOutlookSession_2.vba から起動されます
    rem 
    rem （前提）
    rem 各引数の情報が必要です
    rem 例:
    rem  - CC_ストリーム名: cc_stream_name
    rem  - CC_スナップショットID: 14090
    rem  - メール送信者アドレス: ご自身のメールアドレス（自動取得）
    rem 
    rem （単独起動する場合の使い方）
    rem バッチファイルを起動する場合
    rem 例:
    rem > cov_snap_2.bat cc_stream_name 14090 sender@sample.com
    rem 
    rem ※cov_snap_2.bat を引数なしで実行すると、cov_snap.py は全プロジェクトを巡回しますが正常終了しても、
    rem 引数が足りないため異常終了します。全プロジェクトを巡回する場合は、cov_snap.py を直接実行してください
    rem ※バッチファイルが ThisOutlookSession_2.vba から起動された場合は、メール送信者アドレスは不要です
    rem 
    rem Python スクリプト cov_snap.py を直接起動する場合、メールによる配信を行いません
    rem 1. 特定のスナップショットにおける指摘を取得する場合
    rem  > cd C:cov\
    rem  > py cov_snap.py CC_ストリーム名 CC_スナップショットID メール送信者アドレス
    rem  e.g.
    rem  > py cov_snap.py cc_stream_name 14090 sender@sample.com
    rem 
    rem 2. すべてのプロジェクトにおける追加されたスナップショットの指摘を取得する場合
    rem 引数を指定しないで Python スクリプト cov_snap.py を直接起動した場合は、前回実施したときから比較して今回追加された
    rem すべてのスナップショットの指摘を取得できます。メールからは起動できませんし、メールでの返信も行いません。
    rem  > cd C:cov\
    rem  > py cov_snap.py
    rem 
    rem （注意）1万件のCIDを取得するのに約40分かかりますので大変多くのリソースを消費します
    rem  
    rem （入力）
    rem - Sドライブの Coverity > configフォルダーにあるプロジェクト一覧 projects.cfg ファイル
    rem - Sドライブの Coverity > configフォルダーにあるプロジェクトごとの project_name.cfg ファイル
    rem - Sドライブの Coverity > addressフォルダーにあるメールアドレスファイル
    rem - CC_ストリーム名、CC_スナップショットID、メール送信者
    rem 
    rem （出力）
    rem - 指摘結果のCSVファイル
    rem - 指摘結果のCSVファイルを圧縮したZIPファイル
    rem これらを生成し、メールに添付して配信します
    rem ファイル名は、snapshot_id_<snapshotId>.csv, snapshot_id_<snapshotId>.zip
    rem  例: snapshot_id_11890.csv, snapshot_id_11890.zip
    rem ファイル保存ディレクトリは、BASE_DIR\cov\snapshots\CC_グループ名\CC_ストリーム名\csv_zip
    rem  例: C:\cov\snapshots\cc_group_name\cc_stream_name\csv_zip\
    rem 
    rem 問題報告書のPDFファイルと、グラフなどをあわせて圧縮したZIPファイルを生成し、メールに添付して配信します
    rem  例: bug_report_14090.zip
    rem 
    rem （呼び出すスクリプト）
    rem - cov_check_auth_user.py
    rem - cov_snap.py
    rem - bug_report_2.py
    rem - send_mail_cov_snap.vbs
    rem - send_mail_cov_snap_address.vbs
    rem - send_mail_bug_report.vbs
    rem - send_mail_bug_report_address.vbs
rem

echo Outlook から cov_snap_2.bat が呼ばれました
echo カレントディレクトリは: 
cd

rem デバッグ対応（どちらかをコメント）
rem set DEBUG_BAT=ENABLE
set DEBUG_BAT=DISABLE

rem 環境変数をローカル変数として扱う。環境変数を遅延展開する
setlocal enabledelayedexpansion

rem シフトJIS対応
set LANG=ja_JP.SJIS
rem locale

rem Coverity Connect サーバーに接続するための proxy 設定
set HTTP_PROXY=http://proxy.sample.com:xxxx/
set HTTPS_PROXY=http://proxy.sample.com:xxxx/

rem Python3 コマンド
echo PC: %COMPUTERNAME%
if %COMPUTERNAME%==BUILD_SERVER (
    echo このPCは、ビルドサーバーです
    rem Python3 コマンド
    set PYTHON=python
	
) else (
    echo このPCは、ビルドサーバーではありません
    rem set PYTHON=python3
    set PYTHON=python
)

rem 基底ディレクトリ
rem for /f "usebackq delims=" %%A in (`hostname`) do set host=%%A
rem echo %host%
rem if %host%==BUILD_SERVER (...)
set BASE_DIR=C:
set SCRIPT_DIR=!BASE_DIR!\cov
set GROUPS_DIR=%SCRIPT_DIR%\groups
set LOG_DIR=%SCRIPT_DIR%\log
rem config フォルダー
rem Linux ビルドに対応するため config フォルダーを変更
set CFG_DIR=S:\path\to\coverity\config
rem 指摘結果配信用 address フォルダー
set ADDRESS_DIR=S:\path\to\coverity\address
echo.

rem フォルダーの確認
echo BASE_DIR: %BASE_DIR%
echo SCRIPT_DIR: %SCRIPT_DIR%
echo GROUPS_DIR: %GROUPS_DIR%
echo LOG_DIR: %LOG_DIR%
echo CFG_DIR: %CFG_DIR%
echo.

rem カレントディレクトリ c:\cov へ移動
cd %SCRIPT_DIR%
cd

rem ログファイル名作成
set DT=%date:~0,4%%date:~5,2%%date:~8,2%
rem 空白文字を0に置換
set TIME2=%time: =0%
set TM=%TIME2:~0,2%%time:~3,2%%time:~6,2%
rem echo date+time=%DT%%TM%
rem DONE: CC_STREAM, CC_SNAPSHOT が決まっていないのでログファイル名に使用しない
rem set LOGFILE=%LOG_DIR%\cov_snap_%CC_STREAM%-%CC_SNAPSHOT%-%DT%%TM%.log
set LOGFILE=%LOG_DIR%\cov_snap_2-%DT%%TM%.log

rem ここからログファイル使用可
echo ■ cov_snap_2.bat 開始（ログファイルを作成する）
echo ■ cov_snap_2.bat 開始（ログファイルを作成する） > %LOGFILE%

rem ----------------------------------------
rem Main
rem ----------------------------------------
call :logger_echo "[cov_snap_2.bat][main] 開始"

call :logger_echo "ログファイル:" %LOGFILE%
call :logger_crlf

rem 引数の数を取得
set arg_count=0
for %%A in (%*) do (
    set /a arg_count+=1
)

rem 引数の数に応じて処理を切り替える
rem バッチファイル引数の最大値は9個
if %arg_count%==0 (
    call :no_args
    set error_value=705

) else if %arg_count%==3 (
    call :three_args %1 %2 %3
    rem error_value は、サブルーチン内でセット

) else if %arg_count%==4 (
    call :four_args %1 %2 %3 %4
    rem error_value は、サブルーチン内でセット

) else if %arg_count%==7 (
    call :seven_args %1 %2 %3 %4 %5 %6 %7
    rem error_value は、サブルーチン内でセット

) else if %arg_count%==8 (
    call :eight_args %1 %2 %3 %4 %5 %6 %7 %8
    rem error_value は、サブルーチン内でセット

) else (
    call :logger_echo "[cov_snap_2.bat][main] 引数の数がマッチしません:" %arg_count%
    set error_value=705

)

rem :error_proc_requester の最後で set error_value=%errorlevel%
call :logger_echo "[cov_snap_2.bat][main] 各引数別サブルーチンから main に戻りました. Error_value:" !error_value!
call :logger_crlf

rem End
call :logger_echo "■ cov_snap_2.bat 全て終了しました"
call :logger_crlf

endlocal
rem exit /b ありで呼び出し元に戻る、/b なしでプロセス全体を終了
rem ただし、Outlook VBAから起動する場合は /b の有無に関係なく、バッチファイル終了時にコマンドプロンプトは閉じます
exit /b


rem ----------------------------------------
rem 引数別サブルーチン
rem ----------------------------------------
:no_args
    call :logger_echo "[cov_snap_2.bat][no_args] が呼び出されました"
    call :logger_echo "[cov_snap_2.bat][no_args] Error: 引数がありません"
    call :logger_crlf

exit /b


:three_args
    rem cov_snap, bug_report を起動後、CSVファイル（を圧縮したZIPファイル）を依頼者のみに返信します
    rem 第1引数: CC_ストリーム名、第2引数: CC_スナップショットID、第3引数: メール送信者
    call :logger_echo "[cov_snap_2.bat][three_args] が呼び出されました"
    call :logger_echo "[cov_snap_2.bat][three_args] 引数が 3つです:" %1 %2 %3
    call :logger_crlf

    rem バッチファイル引数の確認
    set CC_STREAM=%1
    set CC_SNAPSHOT=%2
    set SENDEREMAILADDRESS=%3
    echo.

    call :logger_echo "・CC_ストリーム名:" %CC_STREAM%
    call :logger_echo "・CC_スナップショットID:" %CC_SNAPSHOT%
    call :logger_echo "・メール送信者:" %SENDEREMAILADDRESS%
    call :logger_crlf

    rem ------------------
    rem スナップショット取得
    rem ------------------
    rem SOAP API を利用した Coverity ソースコード指摘の取得
    call :logger_echo "■ call :cov_snap"
    call :cov_snap %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS%
    rem :cov_snap の最後で set error_value=%errorlevel%
    call :logger_crlf

    call :logger_echo "[cov_snap_2.bat][three_args] :cov_snap から :three_args に戻りました"
    call :logger_crlf

    rem ZIPファイルパスからCSVファイルパス作成
    set "CSV_FILE_PATH=!ZIP_FILE_PATH:.zip=.csv!"
    call :logger_echo "[cov_snap_2.bat][three_args] CSV_FILE_PATH:" !CSV_FILE_PATH!
    call :logger_crlf

    rem if文の中は %error_value% ではなく !error_value! を使うこと
    rem 依頼者のみに送信するので、%GITLAB_GROUP% が不要

    call :logger_echo "■ call :error_proc_requester"
    rem %1: 呼び出し元 (bug_report, cov_snap, その他)
    rem %2: エラーレベル (例: 0, 1100, 700, etc.)
    rem 以下は bug_report, cov_snap の場合のみ
    rem %3: CC_STREAM
    rem %4: CC_SNAPSHOT
    rem %5: SENDEREMAILADDRESS
    rem %6: ログファイルまたはZIPファイルパス
    call :error_proc_requester cov_snap !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !ZIP_FILE_PATH!

    rem 変わっていないことを確認
    call :logger_echo "[cov_snap_2.bat][three_args] CSV_FILE_PATH（error_proc 呼び出し後）:" !CSV_FILE_PATH!
    call :logger_crlf


    rem -----------
    rem 報告書の作成
    rem -----------
    call :logger_echo "■ call :bug_report"

    rem ファイルパスの拡張子をZIPからCSVに置換 → cov_snap で置換済みなので省く
    rem cov_snap.py から print(error_level, zip_file_path) で受け取った !ZIP_FILE_PATH!
    rem 拡張子を除くファイル名を取得する
    rem call :get_file_path !ZIP_FILE_PATH!
    rem set CSV_FILE_PATH=!FILE_PATH!.csv
    rem call :logger_echo CSV_FILE_PATH: !CSV_FILE_PATH!

    rem CSVファイルパスを引数に実行
    if exist bug_report_2.py (
        call :bug_report !CSV_FILE_PATH!
    ) else (
        call :logger_echo "[SKIP] bug_report_2.py が見つからないため、レポート生成をスキップします"
    )
 
    call :logger_echo "[cov_snap_2.bat][three_args] :bug_report から :three_args に戻りました"
    call :logger_crlf

    rem pause
    rem if文の中は %error_value% ではなく !error_value! を使うこと
    rem 依頼者のみに送信するので、%GITLAB_GROUP% が不要
    call :logger_echo "■ call :error_proc_requester"
    call :error_proc_requester bug_report !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !REPORT_ZIP_FILE_PATH!

exit /b !error_value!


:four_args
    rem cov_snap, bug_report を起動後、CSVファイル（を圧縮したZIPファイル）をアドレスファイルに登録されたメールアドレスに返信します
    rem 第1引数: GitLab_グループ名、第2引数: CC_ストリーム名、第3引数: CC_スナップショットID、第4引数: メール送信者（不要だが引数の数による分岐のために使う）
    call :logger_echo "[cov_snap_2.bat][four_args] が呼び出されました"
    call :logger_echo "[cov_snap_2.bat][four_args] 引数が 4つです:" %1 %2 %3 %4
    call :logger_crlf

    rem バッチファイル引数の確認
    set GITLAB_GROUP=%1
    set CC_STREAM=%2
    set CC_SNAPSHOT=%3
    set SENDEREMAILADDRESS=%4
    echo.

    call :logger_echo "・GitLab_グループ名:" %GITLAB_GROUP%
    call :logger_echo "・CC_ストリーム名:" %CC_STREAM%
    call :logger_echo "・CC_スナップショットID:" %CC_SNAPSHOT%
    call :logger_echo "・メール送信者（Outlook VBAが付加します）:" %SENDEREMAILADDRESS%
    call :logger_crlf

    rem ------------------
    rem スナップショット取得
    rem ------------------
    rem SOAP API を利用した Coverity ソースコード指摘の取得
    call :logger_echo "■ call :cov_snap"
    call :cov_snap %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS%
    rem :cov_snap の最後で set error_value=%errorlevel%
    call :logger_crlf

    call :logger_echo "[cov_snap_2.bat][four_args] :cov_snap から :four_args に戻りました"
    call :logger_crlf

    rem ZIPファイルパスからCSVファイルパス作成
    set "CSV_FILE_PATH=!ZIP_FILE_PATH:.zip=.csv!"
    call :logger_echo "[cov_snap_2.bat][four_args] CSV_FILE_PATH:" !CSV_FILE_PATH!
    call :logger_crlf

    rem if文の中は %error_value% ではなく !error_value! を使うこと
    call :logger_echo "■ call :error_proc_address"
    rem アドレスファイルの宛先に送信するために %GITLAB_GROUP% が必要
    call :error_proc_address cov_snap %GITLAB_GROUP% %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !error_value! !ZIP_FILE_PATH!

    rem 変わっていないことを確認
    call :logger_echo "[cov_snap_2.bat][four_args] CSV_FILE_PATH（error_proc 呼び出し後）:" !CSV_FILE_PATH!
    call :logger_crlf


    rem -----------
    rem 報告書の作成
    rem -----------
    call :logger_echo "■ call :bug_report"

    rem ファイルパスの拡張子をZIPからCSVに置換 → cov_snap で置換済みなので省く
    rem cov_snap.py から print(error_level, zip_file_path) で受け取った !ZIP_FILE_PATH!
    rem 拡張子を除くファイル名を取得する
    rem call :get_file_path !ZIP_FILE_PATH!
    rem set CSV_FILE_PATH=!FILE_PATH!.csv
    rem call :logger_echo CSV_FILE_PATH: !CSV_FILE_PATH!

    rem CSVファイルパスを引数に実行
    if exist bug_report_2.py (
        call :bug_report !CSV_FILE_PATH!
    ) else (
        call :logger_echo "[SKIP] bug_report_2.py が見つからないため、レポート生成をスキップします"
    )

    call :logger_echo "[cov_snap_2.bat][four_args] :bug_report から :four_args に戻りました"
    call :logger_crlf

    rem pause
    rem if文の中は %error_value% ではなく !error_value! を使うこと
    call :logger_echo "■ call :error_proc_address"
    rem アドレスファイルの宛先に送信するために %GITLAB_GROUP% が必要
    call :error_proc_address bug_report %GITLAB_GROUP% %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !error_value! !REPORT_ZIP_FILE_PATH!

exit /b


:seven_args
    rem ソースコードを GitLab から取得し、cov_snap, bug_report を起動後、CSVファイル（を圧縮したZIPファイル）をアドレスファイルに登録されたメールアドレスに返信します
    rem 第1引数: GitLab_グループ名
    rem 第2引数: GitLab_プロジェクト名
    rem 第3引数: GitLabブランチ名
    rem 第4引数: CC_グループ名
    rem 第5引数: CC_ストリーム名
    rem 第6引数: CC_スナップショットID
    rem 第7引数: メール送信者（Outlook VBAが付加します）
    rem CSVファイルのB列ファイル名（変更前）と、CSVファイルのB列ファイル名（変更後）は、projects.cfg から取得する

    call :logger_echo "[cov_snap_2.bat][seven_args] が呼び出されました"
    call :logger_echo "[cov_snap_2.bat][seven_args] 引数が 7つです:" %1 %2 %3 %4 %5 %6 %7
    call :logger_crlf

    rem バッチファイル引数の確認
    set GITLAB_GROUP=%1
    set GITLAB_PROJECT=%2
    set GITLAB_BRANCH=%3
    set CC_GROUP=%4
    set CC_STREAM=%5
    set CC_SNAPSHOT=%6
    set SENDEREMAILADDRESS=%7
    rem CSVファイルのB列ファイル名（変更前と変更後）は、projects.cfg　から読み取る
    rem set BEFORE_REPLACEMENT=%7
    rem set AFTER_REPLACEMENT=%8
    echo.

    call :logger_echo "・1.GitLab_グループ名:" %GITLAB_GROUP%
    call :logger_echo "・2.GitLab_プロジェクト名:" %GITLAB_PROJECT%
    call :logger_echo "・3.GitLab_ブランチ名:" %GITLAB_BRANCH%
    call :logger_echo "・4.CC_グループ名:" %CC_GROUP%
    call :logger_echo "・5.CC_ストリーム名:" %CC_STREAM%
    call :logger_echo "・6.CC_スナップショットID:" %CC_SNAPSHOT%
    call :logger_echo "・7.メール送信者:" %SENDEREMAILADDRESS%
    rem call :logger_echo "・7.CSVファイルのB列ファイル名（変更前）:" %BEFORE_REPLACEMENT%
    rem call :logger_echo "・8.CSVファイルのB列ファイル名（変更後）:" %AFTER_REPLACEMENT%
    call :logger_crlf

    rem exist_project シーケンス
    rem projects.cfg ファイルを読み込み、実施対象プロジェクトのみ継続
    call :logger_echo "■ call :exist_project"
    call :exist_project
    set error_value=%errorlevel%
    call :logger_echo "[cov_snap_2.bat][seven_args] :exist_project から :seven_args に戻りました"
    call :logger_crlf

    if !error_value!==0 (
        rem 正常時はパス
        call :logger_echo "[seven_args] exist_project 正常終了につきメールを送信しません"
        call :logger_crlf

    ) else (
        rem 異常終了につきログファイルを送信
        call :error_proc_requester exist_project !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
        call :logger_echo "■ cov_snap_2.bat 異常終了します"
        exit /b
    )

    rem Git シーケンス
    if not %DEBUG_BAT%==ENABLE (
        rem 本番（デバッグ時スキップ）
        call :logger_echo "■ call :git"
        call :git
        set error_value=%errorlevel%
        call :logger_echo "[cov_snap_2.bat][seven_args] :git から :seven_args に戻りました"
        call :logger_crlf

        if !error_value!==0 (
            rem 正常時はパス
            call :logger_echo "[seven_args] git 正常終了につきメールを送信しません"
            call :logger_crlf

        ) else (
            rem 異常終了につきログファイルを送信
            call :error_proc_requester git !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "■ cov_snap_2.bat 異常終了します"
            exit /b

        )

    ) else (
        rem デバッグ
        call :logger_echo "[error_proc_requester] デバッグ中につき :git をスキップします"
        call :logger_crlf

    )

    rem ------------------
    rem スナップショット取得
    rem ------------------
    rem SOAP API を利用した Coverity ソースコード指摘の取得
    call :logger_echo "■ call :cov_snap"
    call :cov_snap %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS%
    rem :cov_snap の最後で set error_value=%errorlevel%
    call :logger_crlf

    call :logger_echo "[cov_snap_2.bat][seven_args] :cov_snap から :seven_args に戻りました"
    call :logger_crlf

    rem ZIPファイルパスからCSVファイルパス作成
    set "CSV_FILE_PATH=!ZIP_FILE_PATH:.zip=.csv!"
    call :logger_echo "[cov_snap_2.bat][seven_args] CSV_FILE_PATH:" !CSV_FILE_PATH!
    call :logger_crlf

    rem ZIPファイルを送信
    call :logger_echo "■ call :error_proc_address"
    rem アドレスファイルの宛先に送信するために %GITLAB_GROUP% が必要
    call :error_proc_address cov_snap %GITLAB_GROUP% %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !error_value! !ZIP_FILE_PATH!

    rem 変わっていないことを確認
    call :logger_echo "[cov_snap_2.bat][seven_args] CSV_FILE_PATH（error_proc 呼び出し後）:" !CSV_FILE_PATH!
    call :logger_crlf
   
    rem echo BEFORE_REPLACEMENT: !BEFORE_REPLACEMENT!
    rem echo AFTER_REPLACEMENT: !AFTER_REPLACEMENT!
    rem pause

    rem CSVファイルのファイル名を置換する
    if not !BEFORE_REPLACEMENT!=="" (
        rem 変更前ファイルパスの記述がある場合のみ実施
        call :logger_echo "■ CSVファイルのファイル名をバグレポート（ウェブ版）用に置換します"
        rem call :replace_file_name !CSV_FILE_PATH! !BEFORE_REPLACEMENT! !AFTER_REPLACEMENT! は、全角空白であっても分割されてしまう
        call :replace_file_name
        set error_value=%errorlevel%
        call :logger_echo "[cov_snap_2.bat][seven_args] :replace_file_name から :seven_args に戻りました"

        if !error_value!==0 (
            rem 正常時はパス
            call :logger_echo "[seven_args] replace_file_name 正常終了につきメールを送信しません"
            call :logger_crlf

        ) else (
            rem 異常終了につきログファイルを送信
            call :error_proc_requester replace_file_name !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "■ cov_snap_2.bat 異常終了します"
            exit /b
        
        )
    )


    rem -----------
    rem 報告書の作成
    rem -----------
    call :logger_echo "■ call :bug_report"

    rem ファイルパスの拡張子をZIPからCSVに置換 → cov_snap で置換済みなので省く
    rem cov_snap.py から print(error_level, zip_file_path) で受け取った !ZIP_FILE_PATH!
    rem 拡張子を除くファイル名を取得する
    rem call :get_file_path !ZIP_FILE_PATH!
    rem set CSV_FILE_PATH=!FILE_PATH!.csv
    rem call :logger_echo CSV_FILE_PATH: !CSV_FILE_PATH!

    rem CSVファイルパスを引数に実行
    if exist bug_report_2.py (
        call :bug_report !CSV_FILE_PATH!
    ) else (
        call :logger_echo "[SKIP] bug_report_2.py が見つからないため、レポート生成をスキップします"
    )

    call :logger_echo "[cov_snap_2.bat][seven_args] :bug_report から :seven_args に戻りました"
    call :logger_crlf

    rem pause
    rem ZIPファイルを送信
    call :logger_echo "■ call :error_proc_address"
    rem アドレスファイルの宛先に送信するために %GITLAB_GROUP% が必要
    call :error_proc_address bug_report %GITLAB_GROUP% %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !error_value! !REPORT_ZIP_FILE_PATH!

exit /b


:eight_args
    rem ソースコードを Perforce から取得し、cov_snap, bug_report を起動後、CSVファイル（を圧縮したZIPファイル）をアドレスファイルに登録されたメールアドレスに返信します
    rem 第1引数: p4（識別子）
    rem 第2引数: Perforce_グループ名
    rem 第3引数: Perforce_depot_path
    rem 第4引数: Perforce_revision
    rem 第5引数: CC_グループ名
    rem 第6引数: CC_ストリーム名
    rem 第7引数: CC_スナップショットID
    rem 第8引数: メール送信者（Outlook VBAが付加します）
    rem ※ CSVファイルのB列ファイル名（変更前）と、CSVファイルのB列ファイル名（変更後）は、projects.cfg から取得する

    call :logger_echo "[cov_snap_2.bat][eight_args] が呼び出されました"
    call :logger_echo "[cov_snap_2.bat][eight_args] 引数が 8つです:" %1 %2 %3 %4 %5 %6 %7 %8
    call :logger_crlf

    rem バッチファイル引数の確認
    rem %1は識別子p4
    set P4_GROUP=%2
    set P4_DEPOT_PATH=%3
    set P4_REVISION=%4
    set CC_GROUP=%5
    set CC_STREAM=%6
    set CC_SNAPSHOT=%7
    set SENDEREMAILADDRESS=%8
    rem CSVファイルのB列ファイル名（変更前と変更後）は、projects.cfg　から読み取る
    rem set BEFORE_REPLACEMENT=%8
    rem set AFTER_REPLACEMENT=%9
    echo.

    call :logger_echo "・1.P4_グループ名:" %P4_GROUP%
    call :logger_echo "・2.P4_ディポ・パス:" %P4_DEPOT_PATH%
    call :logger_echo "・3.P4_リビジョン:" %P4_REVISION%
    call :logger_echo "・4.CC_グループ名:" %CC_GROUP%
    call :logger_echo "・5.CC_ストリーム名:" %CC_STREAM%
    call :logger_echo "・6.CC_スナップショットID:" %CC_SNAPSHOT%
    call :logger_echo "・7.メール送信者:" %SENDEREMAILADDRESS%
    rem call :logger_echo "・8.CSVファイルのB列ファイル名（変更前）:" %BEFORE_REPLACEMENT%
    rem call :logger_echo "・9.CSVファイルのB列ファイル名（変更後）:" %AFTER_REPLACEMENT%
    call :logger_crlf

    rem exist_project シーケンス（プロジェクトの存在確認）
    call :logger_echo "■ call :exist_project_p4"
    call :exist_project_p4
    set error_value=%errorlevel%
    call :logger_echo "[cov_snap_2.bat][eight_args] :exist_project_p4 から :eight_args に戻りました"

    if !error_value!==0 (
        rem 正常時はパス
        call :logger_echo "[eight_args] exist_project 正常終了につきメールを送信しません"
        call :logger_crlf

    ) else (
        rem 異常終了につきログファイルを送信
        call :error_proc_requester exist_project !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
        call :logger_echo "■ cov_snap_2.bat 異常終了します"
        exit /b

    )

    rem P4 シーケンス
    call :logger_echo "■ call :p4"
    call :p4
    set error_value=%errorlevel%
    call :logger_echo "[cov_snap_2.bat][eight_args] :p4 から :eight_args に戻りました"
    call :logger_crlf

    if !error_value!==0 (
        rem 正常時はパス
        call :logger_echo "[eight_args] p4 正常終了につきメールを送信しません"
        call :logger_crlf

    ) else (
        rem 異常終了につきログファイルを送信
        call :error_proc_requester p4 !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
        call :logger_echo "■ cov_snap_2.bat 異常終了します"
        exit /b
        
    )

    rem ------------------
    rem スナップショット取得
    rem ------------------
    rem SOAP API を利用した Coverity ソースコード指摘の取得
    call :logger_echo "■ call :cov_snap"
    call :cov_snap %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS%
    rem :cov_snap の最後で set error_value=%errorlevel%
    call :logger_crlf

    call :logger_echo "[cov_snap_2.bat][eight_args] :cov_snap から :eight_args に戻りました"
    call :logger_crlf

    rem ZIPファイルパスからCSVファイルパス作成
    set "CSV_FILE_PATH=!ZIP_FILE_PATH:.zip=.csv!"
    call :logger_echo "[cov_snap_2.bat][eight_args] CSV_FILE_PATH:" !CSV_FILE_PATH!
    call :logger_crlf

    rem if文の中は %error_value% ではなく !error_value! を使うこと
    call :logger_echo "■ call :error_proc_address"

    rem 正常時、異常時ともにチームに返信
    rem アドレスファイルの宛先に送信するために %P4_GROUP%が必要
    call :error_proc_address cov_snap %P4_GROUP% %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !error_value! !ZIP_FILE_PATH!

    rem 変わっていないことを確認
    rem call :logger_echo "[cov_snap_2.bat][eight_args] CSV_FILE_PATH（error_proc 呼び出し後）:" !CSV_FILE_PATH!
    rem call :logger_crlf
    
    rem CSVファイルのファイル名を置換する
    if not !BEFORE_REPLACEMENT!=="" (
        rem 変更前ファイルパスの記述がある場合のみ実施
        call :logger_echo "■ CSVファイルのファイル名をバグレポート（ウェブ版）用に置換します"
        rem call :replace_file_name !CSV_FILE_PATH! !BEFORE_REPLACEMENT! !AFTER_REPLACEMENT!
        rem 引数を並べると、全角空白であっても分割されてしまう
        call :replace_file_name
        set error_value=!errorlevel!
        call :logger_echo "[cov_snap_2.bat] :replace_file_name から :eight_args に戻りました"

        if !error_value!==0 (
            rem 正常時はパス
            call :logger_echo "[eight_args] replace_file_name 正常終了につきメールを送信しません"
            call :logger_crlf

        ) else (
            rem 異常終了につきログファイルを送信
            call :error_proc_requester replace_file_name !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "■ cov_snap_2.bat 異常終了します"
            exit /b

        )

    )
    rem pause

    rem -----------------
    rem 報告書は作成しない
    rem -----------------

exit /b


rem ----------------------------------------
rem Subroutines
rem ----------------------------------------

rem 画面とログファイルに文字列を出力する（echo のみ実行）
:logger_echo
    rem Usage: call :logger_echo "arg1" ...
    rem  arg1~n に空白を含む場合は " で囲む（空白がない場合は不要）
    rem  e.g.1 call :logger_echo "■ ビルド開始"
    rem  e.g.2 call :logger_echo "・グループ名:" %GITLAB_GROUP% / %P4_GROUP%

    rem 引数文字列の初期化
    set args=

:loop_logger_echo
    rem " を削除して代入（行末に空白あり）
    set args=%args%%~1 
    shift
    rem 環境変数を[]で囲み、空と、空白、= を含む場合に対応
    rem if not "%1"=="" goto loop_logger_echo
    if not [%1] == [] goto loop_logger_echo

    rem 画面用（" を削除しない）
    echo %args%
    rem ログファイル用（" を削除しない）
    echo %args% >> %LOGFILE% 2>&1

exit /b 0


rem 画面とログファイルに CRLF を出力する
:logger_crlf
    rem Usage: call :logger_crlf
    echo.
    echo. >> %LOGFILE%

exit /b 0


rem コマンドを実行し、ログファイルにコマンドの出力結果を保存する
:logger
    rem Usage: call :logger command(arg1) "arg2" ...
    rem  arg1~n に空白を含む場合は " で囲む（空白がない場合は不要）
    rem  e.g.1 call :logger cd
    rem  e.g.2 call :logger del %LOCKFILE%
    rem  e.g.3 call :logger bash  -i -c "ls -l"

    rem 引数文字列の初期化
    set cmds=

:loop_logger
    rem " を削除して代入（行末に空白あり）
    set cmds=%cmds%%~1 
    shift
    rem 環境変数を[]で囲み、空と、空白、= を含む場合に対応
    rem if not "%1"=="" goto loop_logger
    if not [%1] == [] goto loop_logger
    
    rem call :logger_echo "[logger]" %1 %~2 %~3 %~4 %~5 %~6 "の実行"
    call :logger_echo "[logger]" %cmds% "の実行"
    rem %1 %~2 %~3 %~4 %~5 %~6 >> %LOGFILE% 2>&1
    rem echo %cmds%, !cmds!
    rem pause
    %cmds% >> %LOGFILE% 2>&1

    set error_value=!errorlevel!
    rem call :logger_echo "[logger]" %1 %~2 %~3 %~4 %~5 %~6 "を実行しました error_value=" !error_value!
    call :logger_echo "[logger] %cmds% を実行しました error_value= %error_value%"

exit /b %error_value%


rem ファイルパス取得
:get_file_path
    echo [get_file_path] ドライブ名、パス（拡張子を除くファイル名まで）を返します
    set FILE_PATH=%~dpn1
    call :logger_echo FILE_PATH=!FILE_PATH!
    call :logger_crlf

exit /b


rem 指摘結果配信先の認定ユーザーチェック
:cov_check_auth_user
    rem error_proc_address > send_mail_address から呼ばれる
    rem %1 は、%GITLAB_GROUP% か %P4_GROUP%
    call :logger_echo "[cov_check_auth_user] 指摘結果配信先の認定ユーザーチェック開始"
    call :logger_echo "[cov_check_auth_user] 引数(グループ名): " %1

    rem *_address.csv から *_address_auth.csv 生成
    %PYTHON% %SCRIPT_DIR%\cov_check_auth_user.py %ADDRESS_DIR%\%1_address.csv >> %LOGFILE% 2>&1
    set error_value=!errorlevel!

    call :logger_crlf

rem エラーは上にあげる
exit /b !error_value!


rem 実施するプロジェクトを検索＋ URL 読み込み
:exist_project
    call :logger_echo "[exist_project] プロジェクトが実施対象か調べます"

    rem ファイル存在確認
    if not exist "%CFG_DIR%\projects.cfg" (
        call :logger_echo "projects.cfg が見つかりません。"
        exit /b 1
    )

    rem projects.cfg ファイルから読み込む
    rem /f で ; から始まる行を自動的にスキップ、空白がデリミタ（delim= 不要）
    set execution=False
    for /f "tokens=1,2,3,4,5,6,7,8,9 eol=;" %%a in (%CFG_DIR%\projects.cfg) do (
        rem 空行チェック
        if "%%a"=="" (
            echo WARNING: 無効な行をスキップしました。
            continue
        )
        
        call :logger_echo --------------------------------------
        rem %%a に 1. GitLabグループ名
        call :logger_echo GITLAB_GROUP: %%a

        rem %%b に 2. GitLab_プロジェクト名
        call :logger_echo GITLAB_PROJECT: %%b

        rem %%c に 3. build_dir
        call :logger_echo BUILD_DIR: %%c

        rem %%d に 4. projectKey
        call :logger_echo PROJECTKEY: %%d

        rem %%e に 5. GitLab_URL
        set url=%%e
        call :logger_echo GitLab_url: !url!

        rem %%f に 6. explanation
        call :logger_echo EXPLANATION: %%f

        rem %%g に 7. e-mail_address
        call :logger_echo E-MAIL_ADDRESS: %%g

        rem %%h に 8. 変更前のファイルパス
        set BEFORE_REPLACEMENT=%%h
        call :logger_echo BEFORE_REPLACEMENT: !BEFORE_REPLACEMENT!

        rem %%i に 9. 変更後のファイルパス
        set AFTER_REPLACEMENT=%%i
        call :logger_echo AFTER_REPLACEMENT: !AFTER_REPLACEMENT!
        call :logger_crlf
        echo.

        rem if not "%errorlevel%"=="0" (
        rem     call :logger_echo WARNING %%a の処理中にエラーが発生しました。
        rem     continue
        rem )

        call :logger_echo "Pass 1" !execution!
        if %%a==%GITLAB_GROUP% (
            rem グループ名あり
            if %%b==%GITLAB_PROJECT% (
                rem グループ名もプロジェクト名（ディポパス）も存在するので実施する
                set execution=True
                call :logger_echo "Pass 2 GOOD: GitLab_グループ名と、GitLab_プロジェクト名が存在する" !execution!

                rem GitLab URL の取切り替え（kbit-repo.net か、dev-gpf.com か）
                echo !url:~8! > temp.txt
                for /f "tokens=1,2 delims=/" %%a in (temp.txt) do (
                    rem %url:~8% で https:// を除く2つ目の`/`までを抽出
                    rem 具体的には kbit-repo.net/gitlab/ か dev-gpf.com/gitlab/
                    rem サブグループ区切り{}対応のため
                    set GITLAB_URL_HEAD=https://%%a/%%b/
                    call :logger_echo "GitLab を選択しました（kbit-repo.net/gitlab/ か、dev-gpf.com/gitlab/ か）:" !GITLAB_URL_HEAD!
                    call :logger_crlf
                )

                set error_value=0
                goto :exit_sub

            ) else (
                rem グループ名は存在するが、プロジェクト名が存在しない
                call :logger_echo "Pass 2 NG: GitLab_グループ名は存在するが、GitLab_プロジェクト名が存在しない" !execution!
                set /A "error_value = error_value | 2"

            )

        ) else (
            call :logger_echo "Pass 1 NG: GitLab_グループ名が存在しない" !execution!
            call :logger_crlf
            rem グループ名が存在しない
            set /A "error_value = error_value | 1"
            echo.
        )

    )

    :exit_sub
        rem ループからの脱出先
        call :logger_echo "[exist_project] ループから出ました。error_value=" !error_value!

    call :logger_echo "[exist_project] exit" !execution!
    if "%execution%"=="False" (
        echo.
        call :logger_echo "[exist_project] 実施対象ではないので何もしません。error_value=" !error_value!
        call :logger_echo "[exist_project]   error_value= 1 のとき GitLab_グループ名が存在しない"
        call :logger_echo "[exist_project]   error_value≧2 のとき GitLab_グループ名は存在するが、GitLab_プロジェクト名が存在しない"

    ) else (
        echo.
        call :logger_echo "[exist_project] 対象グループ、プロジェクトが存在しました。error_value=" !error_value!
        call :logger_echo "[exist_project]   error_value=0 のとき GitLab_グループ名もGitLab_プロジェクト名も存在する"

    )
    call :logger_crlf

exit /b !error_value!


rem 実施するプロジェクトを検索＋ Perforce URL 読み込み
:exist_project_p4
    call :logger_echo "[exist_project_p4] プロジェクトが実施対象か調べます"

    rem 引数から、P4 ローカルパスを作成する -> 引数で受け取る
    rem set P4_DEPOT_PATH=//depot/%P4_GROUP%/%P4_PROJECT%/
    call :logger_echo [exist_project_p4] Perforce_depot_path: %P4_DEPOT_PATH%

    rem ファイル存在確認
    if not exist "%CFG_DIR%\projects.cfg" (
        call :logger_echo "projects.cfg が見つかりません。"
        exit /b 1
    )

    rem pause

    rem projects.cfg ファイルから読み込む
    rem ; で始まる行を自動的にスキップ、空白がデリミタ（delim= 不要）
    set execution=False
    for /f "tokens=1,2,3,4,5,6,7,8,9,10 eol=;" %%a in (%CFG_DIR%\projects.cfg) do (
        rem 空行チェック
        if "%%a"=="" (
            echo WARNING: 無効な行をスキップしました。
            continue
        )
        rem pause

        rem %%a に 1. P4 DEPOT ID （識別子）
        rem call :logger_echo P4_DEPOT_ID %%a
        echo P4_DEPOT_ID: %%a
        rem {}depot
        rem if not "%errorlevel%"=="0" (
        rem     echo WARNING %%a の処理中にエラーが発生しました。
        rem     continue
        rem )

        rem %%b に 2. P4グループ名
        rem p4_group_name
        call :logger_echo P4_GROUP: %%b

        rem %%c に 3. P4ディポパス
        rem //depot/p4_group_name/
        call :logger_echo P4_DEPOT_PATH: %%c

        rem %%d に 4. P4リビジョン
        rem head
        call :logger_echo P4_REVISION: %%d

        rem %%e に 5. CC グループ名
        rem cc_group_name
        call :logger_echo CC_GROUP: %%e

        rem %%f に 6. CC ストリーム名
        rem cc_stream_name
        call :logger_echo CC_STREAM: %%f

        rem %%g に 7. CC スナップショットID
        rem 15048
        call :logger_echo CC_SNAPSHOT_ID: %%g

        rem %%h に 8.メールアドレス
        rem sender@sample.com
        call :logger_echo e-mail: %%h

        rem %%i に 9. 変更前のファイルパス
        set BEFORE_REPLACEMENT=%%i
        call :logger_echo BEFORE_REPLACEMENT: !BEFORE_REPLACEMENT!

        rem %%j に 10. 変更後のファイルパス
        set AFTER_REPLACEMENT=%%j
        call :logger_echo AFTER_REPLACEMENT: !AFTER_REPLACEMENT!
        call :logger_crlf
        echo.

        rem if not "%errorlevel%"=="0" (
        rem     call :logger_echo WARNING %%a の処理中にエラーが発生しました。
        rem     continue
        rem )

        call :logger_echo "Pass 1" !execution!
        if %%b==%P4_GROUP% (
            rem グループ名あり
            if %%c==%P4_DEPOT_PATH% (
                rem グループ名もプロジェクト名（ディポパス）も存在するので実施する
                set execution=True
                call :logger_echo "Pass 2 GOOD: グループ名もプロジェクト名も存在する" !execution!

                set error_value=0
                goto :exit_sub

            ) else (
                rem グループ名は存在するが、プロジェクト名が存在しない
                call :logger_echo "Pass 2 NG: グループ名は存在するが、プロジェクト名が存在しない" !execution!
                set /A "error_value = error_value | 2"

            )

        ) else (
            call :logger_echo "Pass 1 NG: グループ名が存在しない" !execution!
            rem グループ名が存在しない
            set /A "error_value = error_value | 1"
            echo.
        )

    )

    :exit_sub
        rem ループからの脱出先
        call :logger_echo "[exist_project_p4] ループから出ました。error_value=" !error_value!

    call :logger_echo "[exist_project_p4] exit" !execution!
    if "%execution%"=="False" (
        echo.
        call :logger_echo "[exist_project_p4] 実施対象ではないので何もしません。error_value=" !error_value!
        call :logger_echo "[exist_project_p4]   error_value= 1 グループ名が存在しない"
        call :logger_echo "[exist_project_p4]   error_value≧2 グループ名は存在するが、プロジェクト名が存在しない"

    ) else (
        echo.
        call :logger_echo "[exist_project_p4] 対象グループ、プロジェクトが存在しました。error_value=" !error_value!
        call :logger_echo "[exist_project_p4]   error_value=0 グループ名もプロジェクト名も存在する"

    )
    call :logger_crlf

exit /b !error_value!


rem Git コマンド群の実行
:git
    call :logger_echo "[git] ソフトウェアの変更取得"

    rem グループ名のディレクトリが存在しないなら作成
    call :logger cd %GROUPS_DIR%%
    if not exist %GITLAB_GROUP% (
        call :logger_echo "[git] グループ・ディレクトリ %GITLAB_GROUP% が存在しないので作成します"
        call :logger mkdir %GITLAB_GROUP%
    
    )

    call :logger cd %GITLAB_GROUP%
    call :logger_crlf

    call :logger_echo "[git] カレントディレクトリ（:git 入口。GitLab_グループ名フォルダにいる）"
    call :logger cd
    call :logger_crlf

    rem バージョン表示
    call :logger_echo "[git] git --version"
    call :logger git --version
    rem git version 2.23.0.windows.
    call :logger_crlf
    
    rem プロジェクト・ディレクトリの存在確認
    if not exist %GITLAB_PROJECT% (
        echo.
        call :logger_echo "[git] プロジェクト・ディレクトリ %GITLAB_PROJECT% が存在しないので、グループ・ディレクトリに git clone します"

        rem サブグループがある場合、{} を / に置き換え
        rem call :logger_echo "[git] git clone" https://kbit-repo.net/gitlab/%GITLAB_GROUP:{}=/%/%GITLAB_PROJECT%.git %GITLAB_PROJECT%
        rem git clone https://kbit-repo.net/gitlab/%GITLAB_GROUP:{}=/%/%GITLAB_PROJECT%.git %GITLAB_PROJECT% >> %LOGFILE% 2>&1
        call :logger_echo "[git] GITLAB_URL_HEAD:" !GITLAB_URL_HEAD!
        call :logger_echo "[git] git clone" !GITLAB_URL_HEAD!%GITLAB_GROUP:{}=/%/%GITLAB_PROJECT%.git %GITLAB_PROJECT%
        git clone !GITLAB_URL_HEAD!%GITLAB_GROUP:{}=/%/%GITLAB_PROJECT%.git %GITLAB_PROJECT% >> %LOGFILE% 2>&1

        rem ・失敗しても（%errorlevel%=0）
        rem error: unable to create file path/to/*.h: Filename too long
        rem %errorlevel%=0 なのでエラー対応できない
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem 正常時はパス
            call :logger_echo "[git] git_clone 正常終了につきメールを送信しません"
            call :logger_crlf

        ) else (
            rem 異常終了につきログファイルを送信
            call :error_proc_requester git_clone !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "■ cov_snap_2.bat 異常終了します"
            exit /b

        )

        call :logger cd %GITLAB_PROJECT%
        call :logger_echo "[git] カレントディレクトリ（git clone 直後。プロジェクト名フォルダにいる）"
        call :logger cd
        call :logger_crlf

        call :logger_echo "[git] ブランチを切り替えます"
        
        call :logger_echo "[git] git switch" %GITLAB_BRANCH:{}=/%
        rem git switch -c DIT_Missing_device_information -> fatal: A branch named 'DIT_Missing_device_information' already exists.
        git switch %GITLAB_BRANCH:{}=/% >> %LOGFILE% 2>&1
        set error_value=!errorlevel!

        rem エラー対応
        rem ・失敗（%errorlevel%=128）
        rem fatal: invalid reference: master_2022
        rem fatal: A branch named 'main' already exists.
        if !error_value!==0 (
            rem 正常時はパス
            call :logger_echo "[git] git_switch 正常終了につきメールを送信しません"
            call :logger_crlf

        ) else (
            rem 異常終了につきログファイルを送信
            call :error_proc_requester git_switch !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "■ cov_snap_2.bat 異常終了します"
            exit /b

        )

    ) else (
        echo プロジェクト・ディレクトリが存在する
        call :logger cd %GITLAB_PROJECT%
        call :logger_echo "[git] カレントディレクトリ（git clone しない場合。プロジェクト名フォルダにいる）"
        call :logger cd
        call :logger_crlf

        call :logger_echo "[git] プロジェクト・ディレクトリ %GITLAB_PROJECT% が存在するので、ブランチを切り替え git fetch します"
        git fetch >> %LOGFILE% 2>&1

        call :logger_echo "[git] ブランチを確認します!"
        call :logger_echo "[git] git --no-pager branch"
        git --no-pager branch
        git --no-pager branch >> %LOGFILE%
        call :logger_crlf

        call :logger_echo "[git] マージ中止"
        call :logger_echo "[git] git merge --quit"
        rem pause
        git merge --quit >> %LOGFILE% 2>&1

        rem エラー対応
        rem ・失敗（%errorlevel%=?）
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem 正常時はパス
            call :logger_echo "[git] git_merge_quit 正常終了につきメールを送信しません"
            call :logger_crlf

        ) else (
            rem 異常終了につきログファイルを送信
            call :error_proc_requester git_merge_quit !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "■ cov_snap_2.bat 異常終了します"
            exit /b

        )

        call :logger_echo "[git] マージ未完了対策"
        call :logger_echo "[git] git reset --merge"
        rem pause
        git reset --merge >> %LOGFILE% 2>&1

        rem エラー対応
        rem ・失敗（%errorlevel%=?）
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem 正常時はパス
            call :logger_echo "[git] git_reset_merge 正常終了につきメールを送信しません"
            call :logger_crlf

        ) else (
            rem 異常終了につきログファイルを送信
            call :error_proc_requester git_reset_merge !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "■ cov_snap_2.bat 異常終了します"
            exit /b

        )

        call :logger_echo "[git] HEAD をリセットします"
        rem 作業コピー内に未コミットの内容があると switch に失敗するので、
        rem HEAD（前回ビルドしたコミット）までリセットする
        call :logger_echo "[git] git reset --hard HEAD"
        rem pause
        git reset --hard HEAD | nkf32.exe -s >> %LOGFILE% 2>&1

        rem エラー対応
        rem ・失敗（%errorlevel%=?）
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem 正常時はパス
            call :logger_echo "[git] git_reset 正常終了につきメールを送信しません"
            call :logger_crlf

        ) else (
            rem 異常終了につきログファイルを送信
            call :error_proc_requester git_reset !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "■ cov_snap_2.bat 異常終了します"
            exit /b

        )

        call :logger_echo "[git] 今回のビルド対象ブランチに切り替えます"
        call :logger_echo "[git] git switch" %GITLAB_BRANCH:{}=/%
        rem git switch -c DIT_Missing_device_information -> fatal: A branch named 'DIT_Missing_device_information' already exists.
        git switch %GITLAB_BRANCH:{}=/% >> %LOGFILE% 2>&1
            
        rem エラー対応
        rem ・失敗（%errorlevel%=128）
        rem fatal: invalid reference: master_2022
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem 正常時はパス
            call :logger_echo "[git] git_switch 正常終了につきメールを送信しません"
            call :logger_crlf

        ) else (
            rem 異常終了につきログファイルを送信
            call :error_proc_requester git_switch !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "■ cov_snap_2.bat 異常終了します"
            exit /b

        )

        call :logger_echo "[git] リモートの更新をローカルに取り込みます"
        call :logger_echo "[git] git fetch origin"
        rem pause
        git fetch origin  >> %LOGFILE% 2>&1

        rem エラー対応
        rem ・失敗（%errorlevel%=?）
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem 正常時はパス
            call :logger_echo "[git] git_fetch 正常終了につきメールを送信しません"
            call :logger_crlf

        ) else (
            rem 異常終了につきログファイルを送信
            call :error_proc_requester git_fetch !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "■ cov_snap_2.bat 異常終了します"
            exit /b

        )
        rem pause
    
        call :logger_echo "[git] git reset --hard origin/" %GITLAB_BRANCH:{}=/%
        rem pause
        git reset --hard origin/%GITLAB_BRANCH:{}=/% | nkf32.exe -s >> %LOGFILE% 2>&1

        rem エラー対応
        rem ・失敗（%errorlevel%=?）
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem 正常時はパス
            call :logger_echo "[git] git_reset 正常終了につきメールを送信しません"
            call :logger_crlf

        ) else (
            rem 異常終了につきログファイルを送信
            call :error_proc_requester git_reset !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "■ cov_snap_2.bat 異常終了します"
            exit /b

        )
        rem pause
    
    )

    call :logger_crlf

    call :logger_echo "[git] カレントディレクトリ（git clone か fetch 完了後。プロジェクト名フォルダにいる）"
    call :logger cd
    call :logger_crlf

    call :logger_echo "[git] ブランチを確認します"
    call :logger_echo "[git] git --no-pager branch"
    git --no-pager branch
    call :logger git --no-pager branch

    rem git clone エラー Filename too long 対応（実施済み）
    rem > git config --system core.longpaths true

    rem ブランチ名のディレクトリ存在確認
    if not exist %GITLAB_BRANCH% (
        rem ブランチ・ディレクトリなし
        echo.
        call :logger_echo "[git] ブランチ・ディレクトリ" %GITLAB_BRANCH% "が存在しないので作成します"
        call :logger mkdir %GITLAB_BRANCH%
    
    ) else (
        rem ブランチ・ディレクトリあり
        echo.
        call :logger_echo "[git] ブランチ・ディレクトリをフォルダごと削除します"
        rem pause
        rem del /S /Q %GITLAB_BRANCH% >> %LOGFILE% 2>&1
        rem ファイルだけ削除してフォルダーが残るので、rmdir に変更
        call :logger rmdir /S /Q %GITLAB_BRANCH%
        rem %Brnch% フォルダも削除されるので、もう一度作る
        call :logger mkdir %GITLAB_BRANCH%
    
    )
    call :logger_crlf
    rem pause

    call :logger_echo "[git] 現在のHEADが指すコミット内容をブランチフォルダに書き出します"
    call :logger_echo "[git] checkout-index -a -f --prefix=" %GROUPS_DIR%\%GITLAB_GROUP%\%GITLAB_PROJECT%\%GITLAB_BRANCH%\
    git checkout-index -a -f --prefix=%GROUPS_DIR%\%GITLAB_GROUP%\%GITLAB_PROJECT%\%GITLAB_BRANCH%\ >> %LOGFILE% 2>&1
    set error_value=!errorlevel!
    if !error_value!==0 (
        rem 正常時はパス
        call :logger_echo "[git] git_checkout_index 正常終了につきメールを送信しません"
        call :logger_crlf

    ) else (
        rem 異常終了につきログファイルを送信
        call :error_proc_requester git_checkout_index %error_value% %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "■ cov_snap_2.bat 異常終了します"
            exit /b

    )

    call :logger cd %GITLAB_BRANCH%
    call :logger_echo "[git] カレントディレクトリ（git checkout-index 後。ブランチ名フォルダにいる）"
    call :logger cd
    call :logger_crlf
    
    rem カレントディレクトリを元に戻す
    call :logger cd %SCRIPT_DIR%
    call :logger_crlf

exit /b !error_value!


rem cov_snap.py SOAP API を利用した Coverity ソースコード指摘の取得
:cov_snap
    rem 入力（引数）: %1: %CC_STREAM%, %2: %SNAPSHOTID%, %3: %SENDEREMAILADDRESS%
    rem 出力: %error_value%

    call :logger_echo "[cov_snap] cov_snap.py Pythonスクリプト実行開始"
    call :logger_echo "[cov_snap] %PYTHON%" %SCRIPT_DIR%\cov_snap.py %1 %2 !SENDEREMAILADDRESS!
    call :logger_crlf

    rem py %SCRIPT_DIR%\cov_snap.py %1 %2 %3 実行（%SENDEREMAILADDRESS% が認定ユーザーか判定する）
    for /f "usebackq tokens=1,2" %%A in (`%PYTHON% %SCRIPT_DIR%\cov_snap.py %1 %2 %3`) do (
        rem cov_snap.py から print(error_level, zip_file_path) で受け取る
        set error_value=%%A
        set ZIP_FILE_PATH=%%B
    )

    rem ※for /f ... の戻り値は異常の時でも %errorlevel% は 0 になるので、
    rem cov_snap.py から print文で、error_level と zip_file_path を受け取る
    rem echo %RET_VALUE%

    rem error_value は、3桁固定とする（1桁目から3桁取得）
    rem set error_value=%RET_VALUE:~0,3%
    rem echo %error_value%
    
    rem ZIP_FILE_PATH は、5桁目から末尾まで取得
    rem set ZIP_FILE_PATH=%RET_VALUE:~4%
    rem echo %ZIP_FILE_PATH%


    rem 正常の時、ZIP_FILE_PATH にファイルの相対パス（例: .\snapshots\assisnet_prj\assisnet_prj\csv_zip\snapshot_id_11655.zip）が入る
    rem 異常のとき ZIP_FILE_PATH に異常理由が入る
    call :logger_crlf
    call :logger_echo "cov_snap.py からの戻り値。errorlevel:" %error_value% ", ZIP_FILE_PATH:" %ZIP_FILE_PATH%
    
    rem 正常・異常判定
    if %ZIP_FILE_PATH:~-3%==zip (
        rem *.zip なら正常

        rem ZIP_FILE_PATH を相対パスから絶対パスに変換（.\ 削除: %S:~x% で(x+1)文字目から末尾まで切り出し）
        set ZIP_FILE_PATH=%SCRIPT_DIR%\%ZIP_FILE_PATH:~2%
        echo ZIP_FILE_PATH=!ZIP_FILE_PATH!
        rem pause
        
    ) else (
        rem 異常
        rem ZIP_FILE_PATH には FileNotFoundError, totalNumberOfCids_0 などの異常理由が入る
        rem error_value="704" などのパースは :error_proc_requester で行う
        echo ZIP_FILE_PATH=!ZIP_FILE_PATH!
        rem pause

    )

    echo error_value=%error_value%
    echo ZIP_FILE_PATH=%ZIP_FILE_PATH%
    rem pause

rem エラーは上にあげる
exit /b %error_value%


rem 問題報告書を作成する
:bug_report
    rem 報告書を作成する
    rem 入力（引数）: %1: %CSV_FILE_PATH%
    rem 出力: %error_value%

    call :logger_echo "[bug_report] bug_report_2.py Pythonスクリプト実行開始"
    call :logger_echo "[bug_report] %PYTHON%" %SCRIPT_DIR%\bug_report_2.py %1

    rem bug_report_2.py 実行
    %PYTHON% %SCRIPT_DIR%\bug_report_2.py %1
    set error_value=%errorlevel%

    rem *.py 側の print文の数に依存するので止める
    rem DONE: bug_report_file_path.txt にファイルパスの記載はある
    rem for /f "usebackq tokens=1,2" %%A in (`%PYTHON% %SCRIPT_DIR%\bug_report_2.py %1`) do (
    rem     rem bug_report_2.py から print(error_level, REPORT_ZIP_FILE_PATH) で受け取る
    rem     set error_value=%%A
    rem     set REPORT_ZIP_FILE_PATH=%%B
    rem     echo REPORT_ZIP_FILE_PATH: !REPORT_ZIP_FILE_PATH!
    rem     pause
    rem )

    call :logger_echo "[bug_report] bug_report_2.py が出力したファイル %SCRIPT_DIR%\bug_report_file_path.txt を読み込む"
    call :logger_echo "[bug_report] 報告書圧縮ファイルのパスが bug_report_file_path.txt に書かれている"
    call :logger_echo "[bug_report] ※errorlevel が0以外の時の bug_report_file_path.txt の内容は別物（更新されていない）"
    set /p REPORT_ZIP_FILE_PATH=<bug_report_file_path.txt

    rem REPORT_ZIP_FILE_PATH に問題報告書ファイルの絶対パスが入る
    rem 例: C:\Users\shimatani\Docs\GitLab\Security\cov_snap\snapshots\MESSIAH\messiah_tool\csv_zip\bug_report_14606.zip
    call :logger_echo "[bug_report] bug_report_2.py からの戻り値。errorlevel:" %error_value% ", REPORT_ZIP_FILE_PATH:" %REPORT_ZIP_FILE_PATH%
    call :logger_crlf

    rem 正常・異常判定
    if %REPORT_ZIP_FILE_PATH:~-3%==zip (
        rem *.zip なら正常
        call :logger_echo "[bug_report] !REPORT_ZIP_FILE_PATH! を正常に読み込みました"

    ) else (
        rem 異常
        call :logger_echo "[bug_report] !REPORT_ZIP_FILE_PATH! を正常に読み込めませんでした"
        rem REPORT_ZIP_FILE_PATH には FileNotFoundError, totalNumberOfCids_0 などの異常理由が入る
        rem error_value="704" などのパースは :error_proc_requester で行う

    )

    call :logger_crlf
    echo error_value=!error_value!
    echo REPORT_ZIP_FILE_PATH=!REPORT_ZIP_FILE_PATH!
    rem pause


rem エラーは上にあげる
exit /b %error_value%


rem p4 コマンドの実行
:p4
    call :logger_echo "[p4] リビジョンをフェッチします（Python スクリプト実行）"
    rem %1: p4_group, %2: depot_path, %3: revision, %4: snapshot_id
    call :logger_echo %PYTHON% p4.py %P4_GROUP% %P4_DEPOT_PATH% %P4_REVISION% %CC_SNAPSHOT%
    call %PYTHON% p4.py %P4_GROUP% %P4_DEPOT_PATH% %P4_REVISION% %CC_SNAPSHOT%

    rem p4.py 実行後のエラーレベルを確認
    set "error_value=%errorlevel%"
    if !error_value! equ 0 (
        call :logger_echo "[p4] 正常に完了しました"

    ) else (
        call :logger_echo "[p4] エラーが発生しました。エラーレベル: " !error_value!

    )

exit /b !error_value!


rem CSVファイルのファイル名をバグレポート（ウェブ版）用に置換する
:replace_file_name
    rem 全角空白であっても分割されてしまうので引数を設定しない
    rem %1: CSVファイル名, %2: 置換前文字列, %3: 置換後文字列
    rem set "csv_file=%1"
    rem set "before_replacement=%2"
    rem set "after_replacement=%3"

    rem 全角空白を半角空白に置換
    rem cov_snap_2.bat で定義された環境変数 CSV_FILE_PATH はローカルスコープなので使えない
    rem set "csv_file=!CSV_FILE_PATH!"
    rem ファイルから取得する
    rem set /p csv_file=<csv_file_path.txt
    rem call :logger_echo "[replace_file_name] CSV_FILE_PATH: %csv_file%"

    rem 全角空白を半角空白に変換
    set search_text=!BEFORE_REPLACEMENT:　= !
    set replace_text=!AFTER_REPLACEMENT:　= !

    call :logger_echo "[replace_file_name] search_text: " %search_text%
    call :logger_echo "[replace_file_name] replace_text: " %replace_text%

    rem search_text または replace_text が '-' の場合は置換しない（PowerShell を実行しない）
    if "%search_text%"=="-" (
        set "error_value=0"
        call :logger_echo "[replace_file_name] 変更前の文字列が '-' なので置換しません"
        call :logger_crlf
        exit /b !error_value!
    )
    if "%replace_text%"=="-" (
        set "error_value=0"
        call :logger_echo "[replace_file_name] 変更後の文字列が '-' なので置換しません"
        call :logger_crlf
        exit /b !error_value!
    )

    rem PowerShellで置換処理を行う
    rem 以下はCP932をエンコードできない
    rem powershell -Command ^
    rem     "Import-Csv -Path '%csv_file%' -Encoding CP932 | ForEach-Object {" ^
    rem     "   $_.'ファイル名' = $_.'ファイル名' -replace '%search_text%', '%replace_text%';" ^
    rem     "   $_" ^
    rem     "} | Export-Csv -Path '%csv_file%' -NoTypeInformation -Encoding CP932"

    rem Get-Content を使用して、ファイルを -Encoding Default で読み込み、ConvertFrom-Csv を使う
    rem CSV_FILE_PATH が使える
    powershell -Command ^
        "$csvFile = '%CSV_FILE_PATH%';" ^
        "$searchText = '%search_text%';" ^
        "$replaceText = '%replace_text%';" ^
        "$csvData = Get-Content -Path $csvFile -Encoding Default | ConvertFrom-Csv;" ^
        "$csvData | ForEach-Object {" ^
        "   $_.'ファイル名' = $_.'ファイル名' -replace $searchText, $replaceText;" ^
        "};" ^
        "$csvData | Export-Csv -Path $csvFile -NoTypeInformation -Encoding Default"
    
    rem PowerShell実行後のエラーレベルを確認
    set "error_value=%errorlevel%"
    if !error_value! equ 0 (
        call :logger_echo "[replace_file_name] 置換処理が正常に完了しました"
    ) else (
        call :logger_echo "[replace_file_name] エラーが発生しました。エラーレベル: " !error_value!
    )
    call :logger_crlf

exit /b !error_value!


rem bug_report, cov_snap, その他対応 共通エラー処理サブルーチン（依頼者個人に返信）
rem 正常時はメールを送信しない。異常時のみメールを送信して終了する
:error_proc_requester
    rem 呼び出し元が bug_report, cov_snap の時、引数は7個。その他の時、引数は2個
    rem %1: 呼び出し元 (例: bug_report, cov_snap その他)
    rem %2: エラーレベル (例: 0, 1100, 700, etc.)
    rem 以下は bug_report, cov_snap,  の場合のみ
    rem %3: (send_mail_5.vbs で GITLAB_GROUP が要るが、 send_mail_5.vbs は使わない)
    rem %3: CC_STREAM
    rem %4: CC_SNAPSHOT
    rem %5: SENDEREMAILADDRESS
    rem %6: ログファイルまたはZIPファイルパス

    rem %1: 呼び出し元 (例: bug_report, cov_snap,  以外の git_switch など)
    rem %2: エラーレベル

    call :logger_echo "[error_proc_requester] 開始 - 呼び出し元:" %1 ", エラーレベル:" %2

    rem エラーレベルを格納
    set "error_value=%2"

    if "%error_value%" == "0" (
        rem 正常処理
        call :logger_echo "[error_proc_requester] 正常終了。エラーレベル:" %error_value%

        rem メールを送信しないで戻る場合
        rem exit /b %error_value%

    ) else (
        rem 異常処理
        if "%1" == "bug_report" (
            if "%error_value%" == "1100" (
                call :logger_echo "[error_proc_requester] bug_report_2.py ChatGPT query error"

            ) else if "%error_value%" == "1101" (
                call :logger_echo "[error_proc_requester] bug_report_2.py FileNotFound"

            ) else (
                call :logger_echo "[error_proc_requester] bug_report その他の異常"

            )

        ) else if "%1" == "cov_snap" (
            if "%error_value%" == "700" (
                call :logger_echo "[error_proc_requester] cov_snap.py last.json ファイルが存在しません"

            ) else if "%error_value%" == "701" (
                call :logger_echo "[error_proc_requester] cov_snap.py ZIPファイルが存在しません"

            ) else (
                call :logger_echo "[error_proc_requester] cov_snap その他の異常"

            )

        ) else (
            rem その他の場合
            call :logger_echo "[error_proc_requester] その他の呼び出し元:" %1 ", エラーレベル:" %error_value%

        )
    )
    call :logger_crlf

    rem 正常・異常時メール送信処理（共通化）
    if not "%DEBUG_BAT%" == "ENABLE" (
        rem 本番
        if "%1" == "bug_report" (
            call :send_mail_requester send_mail_bug_report.vbs %3 %4 %5 %error_value% %6
        
        ) else if "%1" == "cov_snap" (
            call :send_mail_requester send_mail_cov_snap.vbs %3 %4 %5 %error_value% %6
        
        ) else (
            rem その他の場合
            rem TODO: 呼び出し時の引数不足対応要
            call :send_mail_requester send_mail_cov_snap.vbs %3 %4 %5 %error_value% %6
        )

    ) else (
        rem デバッグ中
        call :logger_echo "[error_proc_requester] デバッグ中につきメールを送信しません"

    )

    call :logger_echo "[error_proc_requester] ■ メールを送信し :error_proc_requester に戻ってきました"
    call :logger_crlf

exit /b %error_value%


rem 正常・異常終了時共通のメール送信サブルーチン（依頼者個人に返信）
:send_mail_requester
    rem 引数:
    rem %1: VBSスクリプト名 (send_mail_bug_report.vbs, send_mail_cov_snap.vbs)
    rem %2: CC_STREAM
    rem %3: CC_SNAPSHOT
    rem %4: SENDEREMAILADDRESS
    rem %5: error_value
    rem %6: ZIP_FILE_PATH または LOGFILE (オプション - 存在しない場合は空文字)

    call :logger_echo "[send_mail_requester] 開始 - VBSスクリプト:" %1
    call :logger_echo "[send_mail_requester] 引数: %2, %3, %4, %5, %6"

    rem 認定ユーザーチェックは行わない（引数グループ名を取得していないため）

    rem メール送信処理
    call :logger_echo "[send_mail_requester] cscript %SCRIPT_DIR%\%1 %2 %3 %4 %5 %6"
    cscript %SCRIPT_DIR%\%1 %2 %3 %4 %5 %6

    set error_value=%errorlevel%

    call :logger_echo "[send_mail_requester] 終了 - エラーレベル:" !error_value!
    echo !error_value!

exit /b %error_value%


rem cov_snap, bug_report 共通エラー対応サブルーチン（アドレスファイル利用）
:error_proc_address
    rem 引数:
    rem %1: 呼び出し元 (例: cov_snap, bug_report, p4)
    rem %2: GITLAB_GROUP / P4_GROUP
    rem %3: CC_STREAM
    rem %4: CC_SNAPSHOT
    rem %5: SENDEREMAILADDRESS
    rem %6: error_value
    rem %7: ログファイルまたはZIPファイルパス

    call :logger_echo "[error_proc_address] 開始 - 呼び出し元:" %1 ", エラーレベル:" %6
    call :logger_echo "[error_proc_address] 引数: " %1, %2, %3, %4, %5, %6, %7
    call :logger_crlf

    if "%6" == "0" (
        rem 正常処理
        call :logger_echo "[error_proc_address] 正常終了。エラーレベル:" %6

    ) else (
        rem 異常処理
        if "%1" == "bug_report" (
            if "%6" == "1100" (
                call :logger_echo "[error_proc_address] bug_report_2.py ChatGPT query error"

            ) else if "%6" == "1101" (
                call :logger_echo "[error_proc_address] bug_report_2.py FileNotFound"

            ) else (
                call :logger_echo "[error_proc_address] bug_report その他の異常"

            )

        ) else if "%1" == "cov_snap" (
            if "%6" == "700" (
                call :logger_echo "[error_proc_address] cov_snap.py last.json ファイルが存在しません"

            ) else if "%6" == "701" (
                call :logger_echo "[error_proc_address] cov_snap.py ZIPファイルが存在しません"

            ) else (
                call :logger_echo "[error_proc_address] cov_snap その他の異常"

            )

        ) else (
            call :logger_echo "[error_proc_address] 未知の呼び出し元です"

        )
    )
    call :logger_crlf

    rem 正常・異常メール送信
    if not "%DEBUG_BAT%" == "ENABLE" (
        rem 本番メール送信
        if "%1" == "bug_report" (
            call :send_mail_address send_mail_bug_report_address.vbs %2 %3 %4 %5 %error_value% %7

        ) else if "%1" == "cov_snap" (
            call :send_mail_address send_mail_cov_snap_address.vbs %2 %3 %4 %5 %error_value% %7
            
        ) else (
            rem その他の場合
            rem TODO: 呼び出し時の引数不足対応要
            call :send_mail_address send_mail_cov_snap_address.vbs %2 %3 %4 %5 %error_value% %7

        )

    ) else (
        rem デバッグ中
        call :logger_echo "[error_proc_address] デバッグ中につきメールを送信しません"

    )

    call :logger_echo "[error_proc_address] ■ メールを送信し :error_proc_requester に戻ってきました"
    call :logger_crlf

exit /b %6


rem 共通メール送信サブルーチン
:send_mail_address
    rem 引数:
    rem %1: 呼び出し元スクリプト名 (send_mail_bug_report_address.vbs, send_mail_cov_snap_address.vbs)
    rem %2: GITLAB_GROUP / P4_GROUP
    rem %3: CC_STREAM
    rem %4: CC_SNAPSHOT
    rem %5: SENDEREMAILADDRESS
    rem %6: error_value
    rem %7: ログファイルまたはZIPファイルパス

    call :logger_echo "[send_mail_address] 開始 - スクリプト名:" %1 ", エラーレベル:" %6
    call :logger_echo "[send_mail_address] 引数: " %1, %2, %3, %4, %5, %6, %7
    call :logger_crlf

    rem 認定ユーザーチェック
    call :logger_echo "■ 認定ユーザーチェック実行"
    call :logger_echo "■ call :cov_check_auth_user"
    call :cov_check_auth_user %2
    set error_value=!errorlevel!

    call :logger_echo "[send_mail_address] 認定ユーザーチェック完了 - エラーレベル:" !error_value!
    if not "!error_value!" == "0" (
        call :logger_echo "[send_mail_address] 認定ユーザーチェックでエラー発生"

        rem exit /b !error_value!
    )

    rem メール送信スクリプトの呼び出し
    call :logger_echo "[send_mail_address] スクリプト呼び出し: cscript %SCRIPT_DIR%\%1 %2 %3 %4 %5 !error_value! %7"
    cscript %SCRIPT_DIR%\%1 %2 %3 %4 %5 !error_value! %7
    set error_value=%errorlevel%
    call :logger_echo "[send_mail_address] スクリプト完了 - エラーレベル:" %error_value%

    exit /b %error_value%
