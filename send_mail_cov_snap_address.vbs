' ���O�o�͔� send_mail_3.vbs
' ZIP�t�@�C���Y�t�� send_mail_4.vbs
' ����3�� cov_diff �Ή��� send_mail_cov_diff.vbs
' ����E�ُ틤�ʔ� send_mail_cov_diff_2.vbs
' cov_snap.bat �p�쐬 send_mail_cov_snap.vbs
' bug_report �p send_mail_bug_report.vbs
' �A�h���X�t�@�C���ɋL�ڂ̈���S���ɑ��M����

'------------------------------------
' �ϐ����`
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

' ���I�z��
Dim arrAddress()

' yyyymmddhhmmss �`���Ō��ݓ������擾
Dim strFormattedDateTime
Dim LOG_NAME

' ���O�o�͊֐�
Function WriteLog(Byval msg, Byval level)

	Dim strDate, strTime, header
	strDate = Date()
	strTime = Time()

	' �t�@�C���V�X�e���I�u�W�F�N�g�̍쐬
	Dim fso
	Set fso = CreateObject("Scripting.FileSystemObject")

	' �e�L�X�g�t�@�C���̃I�[�v��(�ǋL���[�h)
	Dim logFile
	' Set logFile = fso.OpenTextFile(LOG_PATH & "\" & Replace(LOG_NAME , ".", "_" & Replace(strDate, "/", "") & "."), 8, True)
	Set logFile = fso.OpenTextFile(LOG_PATH & "\" & LOG_NAME, 8, True)

	' �w�b�_�[�̍쐬
	header = "[" & strDate & " " & strTime & "][" & level & "] "

	' ���O�̏�������
	logFile.WriteLine(header & msg)

	' ���O�̃N���[�Y
	logFile.Close

	' �t�@�C���V�X�e���I�u�W�F�N�g�̔j��
	Set fso = Nothing

End Function


'------------------------------------
' �J�n
'------------------------------------
Wscript.Echo vbCrLf & "�� send_mail_cov_snap_2.vbs �J�n"
' yyyymmdd �`���Ō��ݓ��t���擾
' strFormattedDate = Replace(Left(Now(),10), "/", "")
strFormattedDateTime = Replace(Replace(Replace(Now(), "/", ""), ":", ""), " ", "")
Wscript.Echo strFormattedDateTime

' ���O�̏o�͐�
Const LOG_PATH = "C:\cov\log"
' ���O�̃t�@�C����
LOG_NAME = "send_mail_cov_snap_2-" & strFormattedDateTime & ".log"
' ���O���x��(INFO)
Const LOG_INFO = "INFO"
' ���O���x��(ERROR)
Const LOG_ERROR = "ERROR"

' ���O�o�͊J�n
Call WriteLog("�� send_mail_cov_snap_2.vbs ���O�o�͊J�n", LOG_INFO)

' ����
Set oParam = WScript.Arguments

'If oParam.Count <> 0 then
'  for i = 0 to oParam.Count -1
'    MsgBox i + 1 & "�ڂ̃p�����[�^�́A" & oParam(i) & "�ł��B"
'  next
'End If

' GitLab_�O���[�v���A�X�g���[�����A�X�i�b�v�V���b�gID�A�A���[�����M�Җ��A�G���[���x���A�Y�t����ZIP�t�@�C���p�X
' %1: %GROUP%, %2: %STREAM%, %3: %SNAPSHOT1%, %4: %SENDEREMAILADDRESS%, %5: %error_value%, %6: %ZIP_FILE_PATH%
' �Y�t�t�@�C���͐�΃p�X�w��̂��Ɓi���΃p�X�ł͓Y�t����Ȃ��j
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

' �x�[�X�f�B���N�g��
' 255�������ɑΉ����邽�߂Ɋ��f�B���N�g�����ړ�
' strBaseDir = "C:\Users\shimatani\Docs\GitLab\cov_auto\"
' strBaseDir = "C:\cov\"
' strAttachBaseDir = "C:\cov\"
strAddressDir = "S:\�󒲐��Y�{��IT�\�����[�V�����J���f\�J��g\�Ǝ㐫���\coverity\address\"

'------------------------------------
' �A�h���X�E�t�@�C���̓ǂݍ���
'------------------------------------
strAddressFile = strAddressDir & strGroup & "_address_auth.csv"
Wscript.Echo strAddressFile
Call WriteLog("strAddressFile: " & strAddressFile, LOG_INFO)
' 
' ' �t�@�C���V�X�e���I�u�W�F�N�g�쐬
Set objFS = CreateObject("Scripting.FileSystemObject")
' 
'�G���[�������̓G���[�𖳎����Ď��̏����Ɉڂ�܂��B
On Error Resume Next

' �t�@�C���I�[�v���iSHIFT-JIS�j
Set objText = objFS.OpenTextFile(strAddressFile)

if Err.Number = 0 then
    ' �J�E���^
    i = 0

    ' AtEndOfLine �� True �ɂȂ�܂Ń��[�v
    Do While objText.AtEndOfLine <> True
        ' �z��̗v�f����ύX
        ReDim Preserve arrAddress(i)
        ' 1�s�ǂݍ���
        arrAddress(i) = objText.ReadLine
        i = i + 1

    Loop

    ' �t�@�C���N���[�Y
    objText.close

    ' �z�񂩂���
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
            ' �������Ȃ�
        end if
    Next

else
    ' �t�@�C�����J���Ȃ��G���[
    WScript.Echo "�A�h���X�E�t�@�C�����J�����Ƃ��ł��܂��� (Err.Description): " & Err.Description
    Call WriteLog("�A�h���X�E�t�@�C�����J�����Ƃ��ł��܂��� (Err.Description): " & Err.Description, LOG_ERROR)
    Call WriteLog("�� �ُ�I��", LOG_ERROR)
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
'   �Y�t�t�@�C���p�X�̎w��
'------------------------------------
if strErrorlevel = 000 then
    ' ���펞���[���̏ꍇ�̂�
    ' strZipFilePath = strAttachBaseDir & strGroup &  "\" & strProj &  "\"  &  "cov_issues\" & strZipFileName
    ' strDiffFilePath = strAttachBaseDir & strGroup &  "\" & strProj &  "\"  &  "cov_issues\" & strDiffFileName
    Wscript.Echo strZipFilePath
    ' Wscript.Echo strDiffFilePath
    Call WriteLog("strZipFilePath: " & strZipFilePath, LOG_INFO)
    ' Call WriteLog("strDiffFilePath: " & strDiffFilePath, LOG_INFO)
    Call WriteLog(vbCrLf, LOG_INFO)

    ' Zip�t�@�C���̑��݃`�F�b�N
    if Not objFS.FileExists(strZipFilePath) then
        ' �t�@�C�������݂��Ȃ��G���[
        WScript.Echo "�Y�t����Zip�t�@�C�������݂��܂��� (strZipFilePath): " & strZipFilePath
        Call WriteLog("�Y�t����Zip�t�@�C�������݂��܂��� (strZipFilePath): " & strZipFilePath, LOG_ERROR)
        Call WriteLog("�� �ُ�I��", LOG_ERROR)
        WScript.Quit

    End if

End if


'------------------------------------
'            �{��
'------------------------------------
'text = vbCrLf & Date & " " & Time & vbCrLf
'strBranch_2 = Replace(strBranch, "\\", "/")
'strBranch_2 = Replace(strBranch_2, "{}", "/")

if strErrorlevel = 000 then
    ' ���펞���[��
    text = "�˗��Ҋe��" & vbCrLf & vbCrLf
    text = text & "Coverity �w�E���ʎ擾�X�N���v�g�icov_snap�j����̕񍐂ł� " & vbCrLf
    text = text & "�����̃��[���̓V�X�e�����玩�����M���Ă��܂�" & vbCrLf & vbCrLf
    text = text & "�E�X�g���[����: " & strStream & vbCrLf
    text = text & "�E�X�i�b�v�V���b�gID: " & strSnapshotID & vbCrLf
    text = text & vbCrLf
    text = text & "�X�i�b�v�V���b�gID �̎w�E���ʂ����ׂĎ擾���܂���" & vbCrLf
    text = text & "�Y�t�t�@�C���́ACSV�t�@�C���� ZIP�`���Ɉ��k���Ă��܂��̂ŁA�ۑ���𓀂��Ă��m�F��������" & vbCrLf
    text = text & "���w�E�������[���̏ꍇ������܂��̂ŁA�Y�t�t�@�C�����m�F���Ă�������" & vbCrLf
    text = text & vbCrLf
    text = text & vbCrLf
    text = text & "---" & vbCrLf
    text = text & "�Y�t�t�@�C���ۑ��p�X�i@DAA201900719�j: " & vbCrLf
    text = text & "�EZip�t�@�C��: " & strZipFilePath & vbCrLf
    text = text & vbCrLf

else
    ' �ُ펞���[��
    text = "�˗��Ҋe��" & vbCrLf & vbCrLf
    text = text & "Coverity �w�E���ʎ擾�X�N���v�g�icov_snap�j����̕񍐂ł� " & vbCrLf
    text = text & "�����̃��[���̓V�X�e�����玩�����M���Ă��܂�" & vbCrLf & vbCrLf
    text = text & "�E�X�g���[����: " & strStream & vbCrLf
    text = text & "�E�X�i�b�v�V���b�gID: " & strSnapshotID & vbCrLf
    text = text & vbCrLf
    text = text & "���G���[���������܂���" & vbCrLf
    text = text & "  �EErrorlevel: " & strErrorlevel & vbCrLf

    text = text & "| Errorlevel | �Ӗ� " & vbCrLf
    text = text & "| -----------|-----------------------------------" & vbCrLf
    text = text & "| 700        | last.json �t�@�C�������� " & vbCrLf
    text = text & "| 701        | ZIP�t�@�C�����Ȃ� " & vbCrLf
    text = text & "| 702        | last_l ����i[]�j" & vbCrLf
    text = text & "| 703        | �X�g���[�������݂��Ȃ��\�� " & vbCrLf
    text = text & "| 704        | KeyError " & vbCrLf
    text = text & "| 705        | �����̐����s��v " & vbCrLf
    text = text & "| 706        | �w�E�������[��/�X�i�b�v�V���b�gID�����݂��Ȃ� " & vbCrLf
    text = text & "| 707        | CID �ڍׂ��� (get_cid_info() �̖߂�l) " & vbCrLf
    text = text & "| 708        | ���ϐ��G���[ " & vbCrLf
    text = text & "| 709        | �i���C�Z���X�������Ȃ��j�F�胆�[�U�[�ȊO����̗v�� " & vbCrLf
    text = text & vbCrLf
    text = text & "| Errorlevel | �Ӗ� (cov_license)" & vbCrLf
    text = text & "| -----------|-----------------------------------" & vbCrLf
    text = text & "| 1201       |  File Not Found error " & vbCrLf
    text = text & "| 1202       |  CSV file read error " & vbCrLf
    text = text & "| 1203       |  ���[�U�[�폜�G���[ " & vbCrLf
    text = text & "| 1204       |  �V�K���[�U�[�o�^�G���[�iCC��ŁA�F�胆�[�U�[���𒴂��Ă���ꍇ���܂ށj " & vbCrLf
    text = text & "| 1205       |  �����̐����s��v " & vbCrLf
    text = text & "| 1206       |  �Ǘ��V�[�g��ŁA�F�胆�[�U�[�ő吔���߂��Ă���G���[ " & vbCrLf
    text = text & vbCrLf
    text = text & "---"
    text = text & vbCrLf

End if

Wscript.Echo text

'------------------------------------
'         �t�@�C���̓ǂݍ���                                 '���[���{���Ƀ��O�t�@�C���̓��e���L�ڂ���ꍇ���̐ݒ������
'------------------------------------
'Set fileRead = CreateObject("Scripting.FileSystemObject")   '�t�@�C���̓ǂݍ��݂̃I�u�W�F�N�g�ݒ�
'Set fileText = fileRead.GetFile(strCsvFilePath).OpenAsTextStream  '�t�@�C���̒��g���e�L�X�g������ݒ�
'log = fileText.ReadAll                                      '�t�@�C����1�s���ǂݍ���
'fileText.close                                              '�e�L�X�g���̏I��
'Set fileRead = Nothing                                      '�ǂݍ��ݐݒ�̏I��

'------------------------------------
'         �I�u�W�F�N�g�̒�`
'------------------------------------
Set oMsg = CreateObject("CDO.Message")

'------------------------------------
'         ���M���E���M����`
'------------------------------------
oMsg.From = "Coverity <keisuke.shimatani@daikin.co.jp>"
oMsg.To = strAddressToList
oMsg.Cc = strAddressCcList
oMsg.Bcc = strAddressBccList

'���d�l
'oMsg.To = strSenderEmailAddress
'oMsg.Cc = "���J�\�� <keisuke.shimatani@daikin.co.jp>"
'oMsg.Bcc = strAddressBccList

'------------------------------------
'             �����E�{��
'------------------------------------
if strErrorlevel = 000 then
    ' ���펞���[��
    oMsg.Subject = "[Coverity Snapshot] �S CID �̎w�E���� (" & strStream & ";" & strSnapshotID & ")"
    oMsg.TextBody = text & vbCrLf                      '�t�@�C����Y�t����ꍇ�A�ϐ�log�͂���Ȃ�

else
    ' �ُ펞���[��
    oMsg.Subject = "[Coverity Snapshot] �G���[���� (" & strStream & ";" & strSnapshotID & ")"
    oMsg.TextBody = text & vbCrLf & vbCrLf & log       'text�ƃ��O�t�@�C���̐ݒ��{���ɂ���(vbCrLf �͉��s)

End if

'------------------------------------
'            �T�[�o�[�ݒ� (CDO)
'------------------------------------
strConfigurationField ="http://schemas.microsoft.com/cdo/configuration/"
With oMsg.Configuration.Fields
   .Item(strConfigurationField & "sendusing") = 2
   '1: ���[�J��SMTP�T�[�r�X�Ƀ��[����z�u����
   '2: SMTP�|�[�g�ɐڑ����đ��M����
   '3: OLE DB�𗘗p���ă��[�J����Exchange�ɐڑ�����
   .Item(strConfigurationField & "smtpserver") = "smtp.daikin.co.jp"
   .Item(strConfigurationField & "smtpserverport") = "25"
   .Item(strConfigurationField & "smtpusessl") = false           'use ssl�̐ݒ�
   '------------------- smtp�F�؂�ݒ肷��ꍇ�ȉ���ݒ� ------------
   '.Item(strConfigurationField & "smtpauthenticate") = 2              '1(Basic�F��)/2(NTLM�F��)
   '.Item(strConfigurationField & "sendusername") = "���M���[�U�[��"     'smtp-auth�𗘗p����ꍇ�K�v
   '.Item(strConfigurationField & "sendpassword") = "���M�p�X���[�h"     'smtp-auth�𗘗p����ꍇ�K�v
   '.Item(strConfigurationField & "smtpconnectiontimeout") = 60
   '--------------------------------------------------------------
   .Update

end With


'------------------------------------
'          �Y�t�t�@�C���̐ݒ� (�t�@�C����Y�t���Ȃ��ꍇ�͐ݒ肵�Ȃ�)
'------------------------------------
if strErrorlevel = 000 then
    ' ���펞���[��
    oMsg.AddAttachment(strZipFilePath)          '�Y�tZip�t�@�C���̐ݒ�

End if


'------------------------------------
'               ���M
'------------------------------------
' �G���[�𖳎����đ��s����
on error resume next
oMsg.Send                               '���[�����M�ݒ�(���̐ݒ�݂̂ł����Ȃ�)
if Err.Number <> 0 then
  strMessage = Err.Description          '���[�����M�Ɏ��s�����ꍇ�A�G���[���R�}���h�ɏo��
  Call WriteLog("���[���̑��M�Ɏ��s���܂����iErr.Description�j: " & Err.Description, LOG_ERROR)

else
  strMessage = "Email has been sent."   '���M������������R�}���h�ɏo��
  Call WriteLog("���[���̑��M���������܂���", LOG_INFO)

end if
' �G���[�𖳎�����͈͂����܂�
on error goto 0

Wscript.Echo strMessage


' �����I��
Call WriteLog("�� ���[�����M�I��", LOG_INFO)
WScript.Quit
