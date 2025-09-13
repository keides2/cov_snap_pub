' ログ出力版 send_mail_3.vbs
' ZIPファイル添付版 send_mail_4.vbs
' 差分3種 cov_diff 対応版 send_mail_cov_diff.vbs
' 正常・異常共通版 send_mail_cov_diff_2.vbs
' cov_snap.bat 用作成 send_mail_cov_snap.vbs
' bug_report 用 send_mail_bug_report.vbs
' アドレスファイルに記載の宛先全員に送信する

'------------------------------------
' 変数を定義
'------------------------------------
Option Explicit

Dim strLogFilePath
Dim text
Dim log
Dim oParam, oMsg
Dim fileRead, fileText
Dim strConfigurationField, strMessage

Dim strGroup, strStream, strSnapshotID, strZipFilePath, strZipFileName, strSenderEmailAddress, strErrorlevel
Dim strAddressDir, strAddressFile
Dim objFS, objText
Dim i
Dim arrField, strItem, strAddress
Dim strAddressToList, strAddressCcList, strAddressBccList

' 動的配列
Dim arrAddress()

' yyyymmddhhmmss 形式で現在日時を取得
Dim strFormattedDateTime
Dim LOG_NAME

' ログ出力関数
Function WriteLog(Byval msg, Byval level)

	Dim strDate, strTime, header
	strDate = Date()
	strTime = Time()

	' ファイルシステムオブジェクトの作成
	Dim fso
	Set fso = CreateObject("Scripting.FileSystemObject")

	' テキストファイルのオープン(追記モード)
	Dim logFile
	' Set logFile = fso.OpenTextFile(LOG_PATH & "\" & Replace(LOG_NAME , ".", "_" & Replace(strDate, "/", "") & "."), 8, True)
	Set logFile = fso.OpenTextFile(LOG_PATH & "\" & LOG_NAME, 8, True)

	' ヘッダーの作成
	header = "[" & strDate & " " & strTime & "][" & level & "] "

	' ログの書き込み
	logFile.WriteLine(header & msg)

	' ログのクローズ
	logFile.Close

	' ファイルシステムオブジェクトの破棄
	Set fso = Nothing

End Function


'------------------------------------
' 開始
'------------------------------------
Wscript.Echo vbCrLf & "■ send_mail_cov_snap_2.vbs 開始"
' yyyymmdd 形式で現在日付を取得
' strFormattedDate = Replace(Left(Now(),10), "/", "")
strFormattedDateTime = Replace(Replace(Replace(Now(), "/", ""), ":", ""), " ", "")
Wscript.Echo strFormattedDateTime

' ログの出力先
Const LOG_PATH = "C:\cov\log"
' ログのファイル名
LOG_NAME = "send_mail_cov_snap_2-" & strFormattedDateTime & ".log"
' ログレベル(INFO)
Const LOG_INFO = "INFO"
' ログレベル(ERROR)
Const LOG_ERROR = "ERROR"

' ログ出力開始
Call WriteLog("■ send_mail_cov_snap_2.vbs ログ出力開始", LOG_INFO)

' 引数
Set oParam = WScript.Arguments

'If oParam.Count <> 0 then
'  for i = 0 to oParam.Count -1
'    MsgBox i + 1 & "個目のパラメータは、" & oParam(i) & "です。"
'  next
'End If

' GitLab_グループ名、ストリーム名、スナップショットID、、メール送信者名、エラーレベル、添付するZIPファイルパス
' %1: %GROUP%, %2: %STREAM%, %3: %SNAPSHOT1%, %4: %SENDEREMAILADDRESS%, %5: %error_value%, %6: %ZIP_FILE_PATH%
' 添付ファイルは絶対パス指定のこと（相対パスでは添付されない）
strGroup = oParam(0)
strStream = oParam(1)
strSnapshotID = oParam(2)
strSenderEmailAddress = oParam(3)
strErrorlevel = oParam(4)
strZipFilePath = oParam(5)

Call WriteLog("strGroup: " & strGroup, LOG_INFO)
Call WriteLog("strStream: " & strStream, LOG_INFO)
Call WriteLog("strSnapshotID: " & strSnapshotID, LOG_INFO)
Call WriteLog("strSenderEmailAddress: " & strSenderEmailAddress, LOG_INFO)
Call WriteLog("strErrorlevel: " & strErrorlevel, LOG_INFO)
Call WriteLog("strZipFilePath: " & strZipFilePath, LOG_INFO)
Call WriteLog(vbCrLf, LOG_INFO)

' ベースディレクトリ
' 255文字超に対応するために基底ディレクトリを移動
' strBaseDir = "C:\Users\shimatani\Docs\GitLab\cov_auto\"
' strBaseDir = "C:\cov\"
' strAttachBaseDir = "C:\cov\"
strAddressDir = "S:\空調生産本部ITソリューション開発Ｇ\開発g\脆弱性情報\coverity\address\"

'------------------------------------
' アドレス・ファイルの読み込み
'------------------------------------
strAddressFile = strAddressDir & strGroup & "_address_auth.csv"
Wscript.Echo strAddressFile
Call WriteLog("strAddressFile: " & strAddressFile, LOG_INFO)
' 
' ' ファイルシステムオブジェクト作成
Set objFS = CreateObject("Scripting.FileSystemObject")
' 
'エラー発生時はエラーを無視して次の処理に移ります。
On Error Resume Next

' ファイルオープン（SHIFT-JIS）
Set objText = objFS.OpenTextFile(strAddressFile)

if Err.Number = 0 then
    ' カウンタ
    i = 0

    ' AtEndOfLine が True になるまでループ
    Do While objText.AtEndOfLine <> True
        ' 配列の要素数を変更
        ReDim Preserve arrAddress(i)
        ' 1行読み込み
        arrAddress(i) = objText.ReadLine
        i = i + 1

    Loop

    ' ファイルクローズ
    objText.close

    ' 配列から代入
    For i = 0 To UBound(arrAddress)
        arrField = Split(arrAddress(i), ",")
        strItem = arrField(0)
        strAddress = arrField(1)

        if strItem = "To" then
            strAddressToList = strAddressToList & strAddress & "; "
        elseif strItem = "Cc" then
            strAddressCcList = strAddressCcList & strAddress & "; "
        elseif strItem = "Bcc" then
            strAddressBccList = strAddressBccList & strAddress & "; "
        elseif strItem = ";" then
            ' 何もしない
        end if
    Next

else
    ' ファイルを開けないエラー
    WScript.Echo "アドレス・ファイルを開くことができません (Err.Description): " & Err.Description
    Call WriteLog("アドレス・ファイルを開くことができません (Err.Description): " & Err.Description, LOG_ERROR)
    Call WriteLog("■ 異常終了", LOG_ERROR)
    WScript.Quit

End if

Wscript.Echo strAddressToList
Wscript.Echo strAddressCcList
Wscript.Echo strAddressBccList
Call WriteLog("strAddressToList: " & strAddressToList, LOG_INFO)
Call WriteLog("strAddressCcList: " & strAddressCcList, LOG_INFO)
Call WriteLog("strAddressBccList: " & strAddressBccList, LOG_INFO)
Call WriteLog(vbCrLf, LOG_INFO)


'------------------------------------
'   添付ファイルパスの指定
'------------------------------------
if strErrorlevel = 000 then
    ' 正常時メールの場合のみ
    ' strZipFilePath = strAttachBaseDir & strGroup &  "\" & strProj &  "\"  &  "cov_issues\" & strZipFileName
    ' strDiffFilePath = strAttachBaseDir & strGroup &  "\" & strProj &  "\"  &  "cov_issues\" & strDiffFileName
    Wscript.Echo strZipFilePath
    ' Wscript.Echo strDiffFilePath
    Call WriteLog("strZipFilePath: " & strZipFilePath, LOG_INFO)
    ' Call WriteLog("strDiffFilePath: " & strDiffFilePath, LOG_INFO)
    Call WriteLog(vbCrLf, LOG_INFO)

    ' Zipファイルの存在チェック
    if Not objFS.FileExists(strZipFilePath) then
        ' ファイルが存在しないエラー
        WScript.Echo "添付するZipファイルが存在しません (strZipFilePath): " & strZipFilePath
        Call WriteLog("添付するZipファイルが存在しません (strZipFilePath): " & strZipFilePath, LOG_ERROR)
        Call WriteLog("■ 異常終了", LOG_ERROR)
        WScript.Quit

    End if

End if


'------------------------------------
'            本文
'------------------------------------
'text = vbCrLf & Date & " " & Time & vbCrLf
'strBranch_2 = Replace(strBranch, "\\", "/")
'strBranch_2 = Replace(strBranch_2, "{}", "/")

if strErrorlevel = 000 then
    ' 正常時メール
    text = "依頼者各位" & vbCrLf & vbCrLf
    text = text & "Coverity 指摘結果取得スクリプト（cov_snap）からの報告です " & vbCrLf
    text = text & "※このメールはシステムから自動送信しています" & vbCrLf & vbCrLf
    text = text & "・ストリーム名: " & strStream & vbCrLf
    text = text & "・スナップショットID: " & strSnapshotID & vbCrLf
    text = text & vbCrLf
    text = text & "スナップショットID の指摘結果をすべて取得しました" & vbCrLf
    text = text & "添付ファイルは、CSVファイルを ZIP形式に圧縮していますので、保存後解凍してご確認ください" & vbCrLf
    text = text & "※指摘件数がゼロの場合もありますので、添付ファイルを確認してください" & vbCrLf
    text = text & vbCrLf
    text = text & vbCrLf
    text = text & "---" & vbCrLf
    text = text & "添付ファイル保存パス（@DAA201900719）: " & vbCrLf
    text = text & "・Zipファイル: " & strZipFilePath & vbCrLf
    text = text & vbCrLf

else
    ' 異常時メール
    text = "依頼者各位" & vbCrLf & vbCrLf
    text = text & "Coverity 指摘結果取得スクリプト（cov_snap）からの報告です " & vbCrLf
    text = text & "※このメールはシステムから自動送信しています" & vbCrLf & vbCrLf
    text = text & "・ストリーム名: " & strStream & vbCrLf
    text = text & "・スナップショットID: " & strSnapshotID & vbCrLf
    text = text & vbCrLf
    text = text & "※エラーが発生しました" & vbCrLf
    text = text & "  ・Errorlevel: " & strErrorlevel & vbCrLf

    text = text & "| Errorlevel | 意味 " & vbCrLf
    text = text & "| -----------|-----------------------------------" & vbCrLf
    text = text & "| 700        | last.json ファイルが無い " & vbCrLf
    text = text & "| 701        | ZIPファイルがない " & vbCrLf
    text = text & "| 702        | last_l が空（[]）" & vbCrLf
    text = text & "| 703        | ストリームが存在しない可能性 " & vbCrLf
    text = text & "| 704        | KeyError " & vbCrLf
    text = text & "| 705        | 引数の数が不一致 " & vbCrLf
    text = text & "| 706        | 指摘件数がゼロ/スナップショットIDが存在しない " & vbCrLf
    text = text & "| 707        | CID 詳細が空 (get_cid_info() の戻り値) " & vbCrLf
    text = text & "| 708        | 環境変数エラー " & vbCrLf
    text = text & "| 709        | （ライセンスを持たない）認定ユーザー以外からの要求 " & vbCrLf
    text = text & vbCrLf
    text = text & "| Errorlevel | 意味 (cov_license)" & vbCrLf
    text = text & "| -----------|-----------------------------------" & vbCrLf
    text = text & "| 1201       |  File Not Found error " & vbCrLf
    text = text & "| 1202       |  CSV file read error " & vbCrLf
    text = text & "| 1203       |  ユーザー削除エラー " & vbCrLf
    text = text & "| 1204       |  新規ユーザー登録エラー（CC上で、認定ユーザー数を超えている場合を含む） " & vbCrLf
    text = text & "| 1205       |  引数の数が不一致 " & vbCrLf
    text = text & "| 1206       |  管理シート上で、認定ユーザー最大数を過えているエラー " & vbCrLf
    text = text & vbCrLf
    text = text & "---"
    text = text & vbCrLf

End if

Wscript.Echo text

'------------------------------------
'         ファイルの読み込み                                 'メール本文にログファイルの内容を記載する場合この設定をする
'------------------------------------
'Set fileRead = CreateObject("Scripting.FileSystemObject")   'ファイルの読み込みのオブジェクト設定
'Set fileText = fileRead.GetFile(strCsvFilePath).OpenAsTextStream  'ファイルの中身をテキスト化する設定
'log = fileText.ReadAll                                      'ファイルを1行ずつ読み込む
'fileText.close                                              'テキスト化の終了
'Set fileRead = Nothing                                      '読み込み設定の終了

'------------------------------------
'         オブジェクトの定義
'------------------------------------
Set oMsg = CreateObject("CDO.Message")

'------------------------------------
'         送信元・送信先を定義
'------------------------------------
oMsg.From = "Coverity <keisuke.shimatani@daikin.co.jp>"
oMsg.To = strAddressToList
oMsg.Cc = strAddressCcList
oMsg.Bcc = strAddressBccList

'旧仕様
'oMsg.To = strSenderEmailAddress
'oMsg.Cc = "嶋谷圭介 <keisuke.shimatani@daikin.co.jp>"
'oMsg.Bcc = strAddressBccList

'------------------------------------
'             件名・本文
'------------------------------------
if strErrorlevel = 000 then
    ' 正常時メール
    oMsg.Subject = "[Coverity Snapshot] 全 CID の指摘結果 (" & strStream & ";" & strSnapshotID & ")"
    oMsg.TextBody = text & vbCrLf                      'ファイルを添付する場合、変数logはいらない

else
    ' 異常時メール
    oMsg.Subject = "[Coverity Snapshot] エラー発生 (" & strStream & ";" & strSnapshotID & ")"
    oMsg.TextBody = text & vbCrLf & vbCrLf & log       'textとログファイルの設定を本文にする(vbCrLf は改行)

End if

'------------------------------------
'            サーバー設定 (CDO)
'------------------------------------
strConfigurationField ="http://schemas.microsoft.com/cdo/configuration/"
With oMsg.Configuration.Fields
   .Item(strConfigurationField & "sendusing") = 2
   '1: ローカルSMTPサービスにメールを配置する
   '2: SMTPポートに接続して送信する
   '3: OLE DBを利用してローカルのExchangeに接続する
   .Item(strConfigurationField & "smtpserver") = "smtp.daikin.co.jp"
   .Item(strConfigurationField & "smtpserverport") = "25"
   .Item(strConfigurationField & "smtpusessl") = false           'use sslの設定
   '------------------- smtp認証を設定する場合以下を設定 ------------
   '.Item(strConfigurationField & "smtpauthenticate") = 2              '1(Basic認証)/2(NTLM認証)
   '.Item(strConfigurationField & "sendusername") = "送信ユーザー名"     'smtp-authを利用する場合必要
   '.Item(strConfigurationField & "sendpassword") = "送信パスワード"     'smtp-authを利用する場合必要
   '.Item(strConfigurationField & "smtpconnectiontimeout") = 60
   '--------------------------------------------------------------
   .Update

end With


'------------------------------------
'          添付ファイルの設定 (ファイルを添付しない場合は設定しない)
'------------------------------------
if strErrorlevel = 000 then
    ' 正常時メール
    oMsg.AddAttachment(strZipFilePath)          '添付Zipファイルの設定

End if


'------------------------------------
'               送信
'------------------------------------
' エラーを無視して続行する
on error resume next
oMsg.Send                               'メール送信設定(この設定のみでも問題ない)
if Err.Number <> 0 then
  strMessage = Err.Description          'メール送信に失敗した場合、エラーをコマンドに出力
  Call WriteLog("メールの送信に失敗しました（Err.Description）: " & Err.Description, LOG_ERROR)

else
  strMessage = "Email has been sent."   '送信が完了したらコマンドに出力
  Call WriteLog("メールの送信が完了しました", LOG_INFO)

end if
' エラーを無視する範囲ここまで
on error goto 0

Wscript.Echo strMessage


' 処理終了
Call WriteLog("■ メール送信終了", LOG_INFO)
WScript.Quit
