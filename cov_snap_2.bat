@echo off
rem
    rem �i�T�v�j
    rem Coverity �X�i�b�v�V���b�g�擾����і��񍐏��쐬�X�N���v�g
    rem 
    rem cov_snap_2.bat �́ACoverity Connect �T�[�o�[�i�ȉ� CC�j�ɓo�^��������̃X�i�b�v�V���b�g�̂��ׂĂ̎w�E�𒊏o����X�N���v�g�ł�
    rem �n���o�[�K�[���j���[����G�N�X�|�[�g���Ă��擾�ł��Ȃ��\�[�X�R�[�h�r���[�̃��C���C�x���g���̎w�E�����擾�ł��܂�
    rem ����� Azure OpenAI Service �𗘗p���āA�w�E���ʂ�CSV�t�@�C��������񍐏����쐬���܂��ibug_report_2.py ���S���j
    rem 
    rem �� Coverity ���C�Z���X��̐���ɂ��A���C�Z���X��ۗL����F�胆�[�U�[�������w�E���ʂ��擾�ł��܂�
    rem   �iCC�ɓo�^����Ă���F�胆�[�U�[�݂̂ɔz�M���܂��j
    rem 
    rem �i�@�\�j
    rem Outlook ���g���A�������A�擪���环�ʎq [cov_snap] �Ŏn�܂�A�󔒋�؂�ŕ����̈����������ꂽ���[�����A
    rem sender@sample.com ���Ăɓ͂��Ƃ��̃o�b�`�t�@�C�����N�����܂��iOutlook VBA ����N������܂��j
    rem 
    rem �����̐��ɂ�菈����؂�ւ��܂�
    rem �E�����̐���3��:
    rem   CC ����w�E���擾���icov_snap�j�Abug_report ���N����ACSV�t�@�C���i�����k����ZIP�t�@�C���j���˗��҂݂̂ɕԐM���܂�
    rem   �i�\�[�X�R�[�h�� GitLab ����擾���܂���j
    rem   ��1����: CC_�X�g���[����
    rem   ��2����: CC_�X�i�b�v�V���b�gID
    rem   ��3����: ���[�����M�ҁiOutlook VBA���t�����܂��j
    rem 
    rem   �����̗�: [cov_snap] cc_stream_name 14090
    rem   �o�b�`�t�@�C���̌Ăяo����: cov_snap_2.bat cc_stream_name 14090 sender@sample.com
    rem 
    rem �E�����̐���4��:
    rem   CC ����w�E���擾���icov_snap�j�Abug_report ���N����ACSV�t�@�C���i�����k����ZIP�t�@�C���j���A�h���X�t�@�C���ɓo�^���ꂽ���[���A�h���X�ɕԐM���܂�
    rem   �i�\�[�X�R�[�h�� GitLab ����擾���܂���j
    rem   ��1����: GitLab_�O���[�v��
    rem   ��2����: CC_�X�g���[����
    rem   ��3����: CC_�X�i�b�v�V���b�gID
    rem   ��4����: ���[�����M�ҁiOutlook VBA���t�����܂��j
    rem 
    rem   �����̗�: [cov_snap] gitlab_group_name cc_stream_name 14090
    rem   �o�b�`�t�@�C���̌Ăяo����: cov_snap_2.bat gitlab_group_name cc_stream_name 14090 sender@sample.com
    rem 
    rem �E�����̐���7��:
    rem   �\�[�X�R�[�h�� GitLab ����擾���Acov_snap, bug_report ���N����ACSV�t�@�C���i�����k����ZIP�t�@�C���j���A�h���X�t�@�C���ɓo�^���ꂽ���[���A�h���X�ɕԐM���܂�
    rem   ��1����: GitLab_�O���[�v��
    rem   ��2����: GitLab_�v���W�F�N�g��
    rem   ��3����: GitLab_�u�����`��
    rem   ��4����: CC_�O���[�v��
    rem   ��5����: CC_�X�g���[����
    rem   ��6����: CC_�X�i�b�v�V���b�gID
    rem   ��7����: ���[�����M�ҁiOutlook VBA���t�����܂��j
    rem 
    rem   �����̗�: [cov_snap] gitlab_group_name gitlab_project_name gitlab_branch_name cc_group_name cc_stream_name 15076 sender@sample.com
    rem   �o�b�`�t�@�C���̌Ăяo����: cov_snap_2.bat gitlab_group_name gitlab_project_name gitlab_branch_name cc_group_name cc_stream_name 15076 sender@sample.com
    rem 
    rem   �� CSV�t�@�C����B��t�@�C�����i�ύX�O�j�ƁACSV�t�@�C����B��t�@�C�����i�ύX��j�́Aprojects.cfg ����擾���܂�
    rem 
    rem �E�����̐���8��:
    rem   �\�[�X�R�[�h�� Perforce ����擾���Acov_snap ���N����ACSV�t�@�C���i�����k����ZIP�t�@�C���j���A�h���X�t�@�C���ɓo�^���ꂽ���[���A�h���X�ɕԐM���܂�
    rem   �ibug_report �͋N�����܂���j
    rem   ��1����: p4�i�Œ莯�ʎq�j
    rem   ��2����: Perforce_�O���[�v��
    rem   ��3����: Perforce_depot_path
    rem   ��4����: Perforce_revision
    rem   ��5����: CC_�O���[�v��
    rem   ��6����: CC_�X�g���[����
    rem   ��7����: CC_�X�i�b�v�V���b�gID
    rem   ��8����: ���[�����M�ҁiOutlook VBA���t�����܂��j
    rem 
    rem   �����̗�: [cov_snap] p4_group_name //depot/p4_group_name/ head cc_group_name cc_stream_name 15048 sender@sample.com
    rem   �o�b�`�t�@�C���̌Ăяo����:  p4_group_name //depot/p4_group_name/ head cc_group_name cc_stream_name 15048 sender@sample.com
    rem 
    rem   �� CSV�t�@�C����B��t�@�C�����i�ύX�O�j�ƁACSV�t�@�C����B��t�@�C�����i�ύX��j�́Aprojects.cfg ����擾����
    rem 
    rem ���ׂĂ̏��� SOAP API ���g���Ď擾���܂��imergeKey �ɂ�錋���s�v�j
    rem CSV�t�@�C���𐶐����AZIP�t�@�C���Ɉ��k���܂�
    rem ���ʂ� CC ��ʂ̐ݒ�i���ԃA�C�R���j�ŁA�u�����ӏ���\���v�Ƀ`�F�b�N�������������Ŏ擾�������ʂƓ����ł�
    rem �G�N�Z���� CSV�t�@�C�����J���ACID �̏d���f�[�^���폜����ƁA�u�����ӏ���\���v�Ƀ`�F�b�N������Ȃ������Ŏ擾�������ʂƓ����ɂȂ�܂�
    rem 
    rem CSV�t�@�C���i�����k����ZIP�t�@�C���j�𑗐M��A���񍐏����쐬���APDF�t�@�C���������[�����M�҈��ɔz�z���܂�
    rem
    rem �i���s���j
    rem Windows10 c:\cov
    rem ���炩���� c:\cov, c:\cov\groups, c:\cov\log, S:\path\to\coverity\config, S:\path\to\coverity\address �f�B���N�g�����K�v�ł�
    rem ���̃o�b�`�t�@�C���́AOutlook VBA ThisOutlookSession_2.vba ����N������܂�
    rem 
    rem �i�O��j
    rem �e�����̏�񂪕K�v�ł�
    rem ��:
    rem  - CC_�X�g���[����: cc_stream_name
    rem  - CC_�X�i�b�v�V���b�gID: 14090
    rem  - ���[�����M�҃A�h���X: �����g�̃��[���A�h���X�i�����擾�j
    rem 
    rem �i�P�ƋN������ꍇ�̎g�����j
    rem �o�b�`�t�@�C�����N������ꍇ
    rem ��:
    rem > cov_snap_2.bat cc_stream_name 14090 sender@sample.com
    rem 
    rem ��cov_snap_2.bat �������Ȃ��Ŏ��s����ƁAcov_snap.py �͑S�v���W�F�N�g�����񂵂܂�������I�����Ă��A
    rem ����������Ȃ����߈ُ�I�����܂��B�S�v���W�F�N�g�����񂷂�ꍇ�́Acov_snap.py �𒼐ڎ��s���Ă�������
    rem ���o�b�`�t�@�C���� ThisOutlookSession_2.vba ����N�����ꂽ�ꍇ�́A���[�����M�҃A�h���X�͕s�v�ł�
    rem 
    rem Python �X�N���v�g cov_snap.py �𒼐ڋN������ꍇ�A���[���ɂ��z�M���s���܂���
    rem 1. ����̃X�i�b�v�V���b�g�ɂ�����w�E���擾����ꍇ
    rem  > cd C:cov\
    rem  > py cov_snap.py CC_�X�g���[���� CC_�X�i�b�v�V���b�gID ���[�����M�҃A�h���X
    rem  e.g.
    rem  > py cov_snap.py cc_stream_name 14090 sender@sample.com
    rem 
    rem 2. ���ׂẴv���W�F�N�g�ɂ�����ǉ����ꂽ�X�i�b�v�V���b�g�̎w�E���擾����ꍇ
    rem �������w�肵�Ȃ��� Python �X�N���v�g cov_snap.py �𒼐ڋN�������ꍇ�́A�O����{�����Ƃ������r���č���ǉ����ꂽ
    rem ���ׂẴX�i�b�v�V���b�g�̎w�E���擾�ł��܂��B���[������͋N���ł��܂��񂵁A���[���ł̕ԐM���s���܂���B
    rem  > cd C:cov\
    rem  > py cov_snap.py
    rem 
    rem �i���Ӂj1������CID���擾����̂ɖ�40��������܂��̂ő�ϑ����̃��\�[�X������܂�
    rem  
    rem �i���́j
    rem - S�h���C�u�� Coverity > config�t�H���_�[�ɂ���v���W�F�N�g�ꗗ projects.cfg �t�@�C��
    rem - S�h���C�u�� Coverity > config�t�H���_�[�ɂ���v���W�F�N�g���Ƃ� project_name.cfg �t�@�C��
    rem - S�h���C�u�� Coverity > address�t�H���_�[�ɂ��郁�[���A�h���X�t�@�C��
    rem - CC_�X�g���[�����ACC_�X�i�b�v�V���b�gID�A���[�����M��
    rem 
    rem �i�o�́j
    rem - �w�E���ʂ�CSV�t�@�C��
    rem - �w�E���ʂ�CSV�t�@�C�������k����ZIP�t�@�C��
    rem �����𐶐����A���[���ɓY�t���Ĕz�M���܂�
    rem �t�@�C�����́Asnapshot_id_<snapshotId>.csv, snapshot_id_<snapshotId>.zip
    rem  ��: snapshot_id_11890.csv, snapshot_id_11890.zip
    rem �t�@�C���ۑ��f�B���N�g���́ABASE_DIR\cov\snapshots\CC_�O���[�v��\CC_�X�g���[����\csv_zip
    rem  ��: C:\cov\snapshots\cc_group_name\cc_stream_name\csv_zip\
    rem 
    rem ���񍐏���PDF�t�@�C���ƁA�O���t�Ȃǂ����킹�Ĉ��k����ZIP�t�@�C���𐶐����A���[���ɓY�t���Ĕz�M���܂�
    rem  ��: bug_report_14090.zip
    rem 
    rem �i�Ăяo���X�N���v�g�j
    rem - cov_check_auth_user.py
    rem - cov_snap.py
    rem - bug_report_2.py
    rem - send_mail_cov_snap.vbs
    rem - send_mail_cov_snap_address.vbs
    rem - send_mail_bug_report.vbs
    rem - send_mail_bug_report_address.vbs
rem

echo Outlook ���� cov_snap_2.bat ���Ă΂�܂���
echo �J�����g�f�B���N�g����: 
cd

rem �f�o�b�O�Ή��i�ǂ��炩���R�����g�j
rem set DEBUG_BAT=ENABLE
set DEBUG_BAT=DISABLE

rem ���ϐ������[�J���ϐ��Ƃ��Ĉ����B���ϐ���x���W�J����
setlocal enabledelayedexpansion

rem �V�t�gJIS�Ή�
set LANG=ja_JP.SJIS
rem locale

rem Coverity Connect �T�[�o�[�ɐڑ����邽�߂� proxy �ݒ�
set HTTP_PROXY=http://proxy.sample.com:xxxx/
set HTTPS_PROXY=http://proxy.sample.com:xxxx/

rem Python3 �R�}���h
echo PC: %COMPUTERNAME%
if %COMPUTERNAME%==BUILD_SERVER (
    echo ����PC�́A�r���h�T�[�o�[�ł�
    rem Python3 �R�}���h
    set PYTHON=python
	
) else (
    echo ����PC�́A�r���h�T�[�o�[�ł͂���܂���
    rem set PYTHON=python3
    set PYTHON=python
)

rem ���f�B���N�g��
rem for /f "usebackq delims=" %%A in (`hostname`) do set host=%%A
rem echo %host%
rem if %host%==BUILD_SERVER (...)
set BASE_DIR=C:
set SCRIPT_DIR=!BASE_DIR!\cov
set GROUPS_DIR=%SCRIPT_DIR%\groups
set LOG_DIR=%SCRIPT_DIR%\log
rem config �t�H���_�[
rem Linux �r���h�ɑΉ����邽�� config �t�H���_�[��ύX
set CFG_DIR=S:\path\to\coverity\config
rem �w�E���ʔz�M�p address �t�H���_�[
set ADDRESS_DIR=S:\path\to\coverity\address
echo.

rem �t�H���_�[�̊m�F
echo BASE_DIR: %BASE_DIR%
echo SCRIPT_DIR: %SCRIPT_DIR%
echo GROUPS_DIR: %GROUPS_DIR%
echo LOG_DIR: %LOG_DIR%
echo CFG_DIR: %CFG_DIR%
echo.

rem �J�����g�f�B���N�g�� c:\cov �ֈړ�
cd %SCRIPT_DIR%
cd

rem ���O�t�@�C�����쐬
set DT=%date:~0,4%%date:~5,2%%date:~8,2%
rem �󔒕�����0�ɒu��
set TIME2=%time: =0%
set TM=%TIME2:~0,2%%time:~3,2%%time:~6,2%
rem echo date+time=%DT%%TM%
rem DONE: CC_STREAM, CC_SNAPSHOT �����܂��Ă��Ȃ��̂Ń��O�t�@�C�����Ɏg�p���Ȃ�
rem set LOGFILE=%LOG_DIR%\cov_snap_%CC_STREAM%-%CC_SNAPSHOT%-%DT%%TM%.log
set LOGFILE=%LOG_DIR%\cov_snap_2-%DT%%TM%.log

rem �������烍�O�t�@�C���g�p��
echo �� cov_snap_2.bat �J�n�i���O�t�@�C�����쐬����j
echo �� cov_snap_2.bat �J�n�i���O�t�@�C�����쐬����j > %LOGFILE%

rem ----------------------------------------
rem Main
rem ----------------------------------------
call :logger_echo "[cov_snap_2.bat][main] �J�n"

call :logger_echo "���O�t�@�C��:" %LOGFILE%
call :logger_crlf

rem �����̐����擾
set arg_count=0
for %%A in (%*) do (
    set /a arg_count+=1
)

rem �����̐��ɉ����ď�����؂�ւ���
rem �o�b�`�t�@�C�������̍ő�l��9��
if %arg_count%==0 (
    call :no_args
    set error_value=705

) else if %arg_count%==3 (
    call :three_args %1 %2 %3
    rem error_value �́A�T�u���[�`�����ŃZ�b�g

) else if %arg_count%==4 (
    call :four_args %1 %2 %3 %4
    rem error_value �́A�T�u���[�`�����ŃZ�b�g

) else if %arg_count%==7 (
    call :seven_args %1 %2 %3 %4 %5 %6 %7
    rem error_value �́A�T�u���[�`�����ŃZ�b�g

) else if %arg_count%==8 (
    call :eight_args %1 %2 %3 %4 %5 %6 %7 %8
    rem error_value �́A�T�u���[�`�����ŃZ�b�g

) else (
    call :logger_echo "[cov_snap_2.bat][main] �����̐����}�b�`���܂���:" %arg_count%
    set error_value=705

)

rem :error_proc_requester �̍Ō�� set error_value=%errorlevel%
call :logger_echo "[cov_snap_2.bat][main] �e�����ʃT�u���[�`������ main �ɖ߂�܂���. Error_value:" !error_value!
call :logger_crlf

rem End
call :logger_echo "�� cov_snap_2.bat �S�ďI�����܂���"
call :logger_crlf

endlocal
rem exit /b ����ŌĂяo�����ɖ߂�A/b �Ȃ��Ńv���Z�X�S�̂��I��
rem �������AOutlook VBA����N������ꍇ�� /b �̗L���Ɋ֌W�Ȃ��A�o�b�`�t�@�C���I�����ɃR�}���h�v�����v�g�͕��܂�
exit /b


rem ----------------------------------------
rem �����ʃT�u���[�`��
rem ----------------------------------------
:no_args
    call :logger_echo "[cov_snap_2.bat][no_args] ���Ăяo����܂���"
    call :logger_echo "[cov_snap_2.bat][no_args] Error: ����������܂���"
    call :logger_crlf

exit /b


:three_args
    rem cov_snap, bug_report ���N����ACSV�t�@�C���i�����k����ZIP�t�@�C���j���˗��҂݂̂ɕԐM���܂�
    rem ��1����: CC_�X�g���[�����A��2����: CC_�X�i�b�v�V���b�gID�A��3����: ���[�����M��
    call :logger_echo "[cov_snap_2.bat][three_args] ���Ăяo����܂���"
    call :logger_echo "[cov_snap_2.bat][three_args] ������ 3�ł�:" %1 %2 %3
    call :logger_crlf

    rem �o�b�`�t�@�C�������̊m�F
    set CC_STREAM=%1
    set CC_SNAPSHOT=%2
    set SENDEREMAILADDRESS=%3
    echo.

    call :logger_echo "�ECC_�X�g���[����:" %CC_STREAM%
    call :logger_echo "�ECC_�X�i�b�v�V���b�gID:" %CC_SNAPSHOT%
    call :logger_echo "�E���[�����M��:" %SENDEREMAILADDRESS%
    call :logger_crlf

    rem ------------------
    rem �X�i�b�v�V���b�g�擾
    rem ------------------
    rem SOAP API �𗘗p���� Coverity �\�[�X�R�[�h�w�E�̎擾
    call :logger_echo "�� call :cov_snap"
    call :cov_snap %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS%
    rem :cov_snap �̍Ō�� set error_value=%errorlevel%
    call :logger_crlf

    call :logger_echo "[cov_snap_2.bat][three_args] :cov_snap ���� :three_args �ɖ߂�܂���"
    call :logger_crlf

    rem ZIP�t�@�C���p�X����CSV�t�@�C���p�X�쐬
    set "CSV_FILE_PATH=!ZIP_FILE_PATH:.zip=.csv!"
    call :logger_echo "[cov_snap_2.bat][three_args] CSV_FILE_PATH:" !CSV_FILE_PATH!
    call :logger_crlf

    rem if���̒��� %error_value% �ł͂Ȃ� !error_value! ���g������
    rem �˗��҂݂̂ɑ��M����̂ŁA%GITLAB_GROUP% ���s�v

    call :logger_echo "�� call :error_proc_requester"
    rem %1: �Ăяo���� (bug_report, cov_snap, ���̑�)
    rem %2: �G���[���x�� (��: 0, 1100, 700, etc.)
    rem �ȉ��� bug_report, cov_snap �̏ꍇ�̂�
    rem %3: CC_STREAM
    rem %4: CC_SNAPSHOT
    rem %5: SENDEREMAILADDRESS
    rem %6: ���O�t�@�C���܂���ZIP�t�@�C���p�X
    call :error_proc_requester cov_snap !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !ZIP_FILE_PATH!

    rem �ς���Ă��Ȃ����Ƃ��m�F
    call :logger_echo "[cov_snap_2.bat][three_args] CSV_FILE_PATH�ierror_proc �Ăяo����j:" !CSV_FILE_PATH!
    call :logger_crlf


    rem -----------
    rem �񍐏��̍쐬
    rem -----------
    call :logger_echo "�� call :bug_report"

    rem �t�@�C���p�X�̊g���q��ZIP����CSV�ɒu�� �� cov_snap �Œu���ς݂Ȃ̂ŏȂ�
    rem cov_snap.py ���� print(error_level, zip_file_path) �Ŏ󂯎���� !ZIP_FILE_PATH!
    rem �g���q�������t�@�C�������擾����
    rem call :get_file_path !ZIP_FILE_PATH!
    rem set CSV_FILE_PATH=!FILE_PATH!.csv
    rem call :logger_echo CSV_FILE_PATH: !CSV_FILE_PATH!

    rem CSV�t�@�C���p�X�������Ɏ��s
    if exist bug_report_2.py (
        call :bug_report !CSV_FILE_PATH!
    ) else (
        call :logger_echo "[SKIP] bug_report_2.py ��������Ȃ����߁A���|�[�g�������X�L�b�v���܂�"
    )
 
    call :logger_echo "[cov_snap_2.bat][three_args] :bug_report ���� :three_args �ɖ߂�܂���"
    call :logger_crlf

    rem pause
    rem if���̒��� %error_value% �ł͂Ȃ� !error_value! ���g������
    rem �˗��҂݂̂ɑ��M����̂ŁA%GITLAB_GROUP% ���s�v
    call :logger_echo "�� call :error_proc_requester"
    call :error_proc_requester bug_report !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !REPORT_ZIP_FILE_PATH!

exit /b !error_value!


:four_args
    rem cov_snap, bug_report ���N����ACSV�t�@�C���i�����k����ZIP�t�@�C���j���A�h���X�t�@�C���ɓo�^���ꂽ���[���A�h���X�ɕԐM���܂�
    rem ��1����: GitLab_�O���[�v���A��2����: CC_�X�g���[�����A��3����: CC_�X�i�b�v�V���b�gID�A��4����: ���[�����M�ҁi�s�v���������̐��ɂ�镪��̂��߂Ɏg���j
    call :logger_echo "[cov_snap_2.bat][four_args] ���Ăяo����܂���"
    call :logger_echo "[cov_snap_2.bat][four_args] ������ 4�ł�:" %1 %2 %3 %4
    call :logger_crlf

    rem �o�b�`�t�@�C�������̊m�F
    set GITLAB_GROUP=%1
    set CC_STREAM=%2
    set CC_SNAPSHOT=%3
    set SENDEREMAILADDRESS=%4
    echo.

    call :logger_echo "�EGitLab_�O���[�v��:" %GITLAB_GROUP%
    call :logger_echo "�ECC_�X�g���[����:" %CC_STREAM%
    call :logger_echo "�ECC_�X�i�b�v�V���b�gID:" %CC_SNAPSHOT%
    call :logger_echo "�E���[�����M�ҁiOutlook VBA���t�����܂��j:" %SENDEREMAILADDRESS%
    call :logger_crlf

    rem ------------------
    rem �X�i�b�v�V���b�g�擾
    rem ------------------
    rem SOAP API �𗘗p���� Coverity �\�[�X�R�[�h�w�E�̎擾
    call :logger_echo "�� call :cov_snap"
    call :cov_snap %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS%
    rem :cov_snap �̍Ō�� set error_value=%errorlevel%
    call :logger_crlf

    call :logger_echo "[cov_snap_2.bat][four_args] :cov_snap ���� :four_args �ɖ߂�܂���"
    call :logger_crlf

    rem ZIP�t�@�C���p�X����CSV�t�@�C���p�X�쐬
    set "CSV_FILE_PATH=!ZIP_FILE_PATH:.zip=.csv!"
    call :logger_echo "[cov_snap_2.bat][four_args] CSV_FILE_PATH:" !CSV_FILE_PATH!
    call :logger_crlf

    rem if���̒��� %error_value% �ł͂Ȃ� !error_value! ���g������
    call :logger_echo "�� call :error_proc_address"
    rem �A�h���X�t�@�C���̈���ɑ��M���邽�߂� %GITLAB_GROUP% ���K�v
    call :error_proc_address cov_snap %GITLAB_GROUP% %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !error_value! !ZIP_FILE_PATH!

    rem �ς���Ă��Ȃ����Ƃ��m�F
    call :logger_echo "[cov_snap_2.bat][four_args] CSV_FILE_PATH�ierror_proc �Ăяo����j:" !CSV_FILE_PATH!
    call :logger_crlf


    rem -----------
    rem �񍐏��̍쐬
    rem -----------
    call :logger_echo "�� call :bug_report"

    rem �t�@�C���p�X�̊g���q��ZIP����CSV�ɒu�� �� cov_snap �Œu���ς݂Ȃ̂ŏȂ�
    rem cov_snap.py ���� print(error_level, zip_file_path) �Ŏ󂯎���� !ZIP_FILE_PATH!
    rem �g���q�������t�@�C�������擾����
    rem call :get_file_path !ZIP_FILE_PATH!
    rem set CSV_FILE_PATH=!FILE_PATH!.csv
    rem call :logger_echo CSV_FILE_PATH: !CSV_FILE_PATH!

    rem CSV�t�@�C���p�X�������Ɏ��s
    if exist bug_report_2.py (
        call :bug_report !CSV_FILE_PATH!
    ) else (
        call :logger_echo "[SKIP] bug_report_2.py ��������Ȃ����߁A���|�[�g�������X�L�b�v���܂�"
    )

    call :logger_echo "[cov_snap_2.bat][four_args] :bug_report ���� :four_args �ɖ߂�܂���"
    call :logger_crlf

    rem pause
    rem if���̒��� %error_value% �ł͂Ȃ� !error_value! ���g������
    call :logger_echo "�� call :error_proc_address"
    rem �A�h���X�t�@�C���̈���ɑ��M���邽�߂� %GITLAB_GROUP% ���K�v
    call :error_proc_address bug_report %GITLAB_GROUP% %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !error_value! !REPORT_ZIP_FILE_PATH!

exit /b


:seven_args
    rem �\�[�X�R�[�h�� GitLab ����擾���Acov_snap, bug_report ���N����ACSV�t�@�C���i�����k����ZIP�t�@�C���j���A�h���X�t�@�C���ɓo�^���ꂽ���[���A�h���X�ɕԐM���܂�
    rem ��1����: GitLab_�O���[�v��
    rem ��2����: GitLab_�v���W�F�N�g��
    rem ��3����: GitLab�u�����`��
    rem ��4����: CC_�O���[�v��
    rem ��5����: CC_�X�g���[����
    rem ��6����: CC_�X�i�b�v�V���b�gID
    rem ��7����: ���[�����M�ҁiOutlook VBA���t�����܂��j
    rem CSV�t�@�C����B��t�@�C�����i�ύX�O�j�ƁACSV�t�@�C����B��t�@�C�����i�ύX��j�́Aprojects.cfg ����擾����

    call :logger_echo "[cov_snap_2.bat][seven_args] ���Ăяo����܂���"
    call :logger_echo "[cov_snap_2.bat][seven_args] ������ 7�ł�:" %1 %2 %3 %4 %5 %6 %7
    call :logger_crlf

    rem �o�b�`�t�@�C�������̊m�F
    set GITLAB_GROUP=%1
    set GITLAB_PROJECT=%2
    set GITLAB_BRANCH=%3
    set CC_GROUP=%4
    set CC_STREAM=%5
    set CC_SNAPSHOT=%6
    set SENDEREMAILADDRESS=%7
    rem CSV�t�@�C����B��t�@�C�����i�ύX�O�ƕύX��j�́Aprojects.cfg�@����ǂݎ��
    rem set BEFORE_REPLACEMENT=%7
    rem set AFTER_REPLACEMENT=%8
    echo.

    call :logger_echo "�E1.GitLab_�O���[�v��:" %GITLAB_GROUP%
    call :logger_echo "�E2.GitLab_�v���W�F�N�g��:" %GITLAB_PROJECT%
    call :logger_echo "�E3.GitLab_�u�����`��:" %GITLAB_BRANCH%
    call :logger_echo "�E4.CC_�O���[�v��:" %CC_GROUP%
    call :logger_echo "�E5.CC_�X�g���[����:" %CC_STREAM%
    call :logger_echo "�E6.CC_�X�i�b�v�V���b�gID:" %CC_SNAPSHOT%
    call :logger_echo "�E7.���[�����M��:" %SENDEREMAILADDRESS%
    rem call :logger_echo "�E7.CSV�t�@�C����B��t�@�C�����i�ύX�O�j:" %BEFORE_REPLACEMENT%
    rem call :logger_echo "�E8.CSV�t�@�C����B��t�@�C�����i�ύX��j:" %AFTER_REPLACEMENT%
    call :logger_crlf

    rem exist_project �V�[�P���X
    rem projects.cfg �t�@�C����ǂݍ��݁A���{�Ώۃv���W�F�N�g�̂݌p��
    call :logger_echo "�� call :exist_project"
    call :exist_project
    set error_value=%errorlevel%
    call :logger_echo "[cov_snap_2.bat][seven_args] :exist_project ���� :seven_args �ɖ߂�܂���"
    call :logger_crlf

    if !error_value!==0 (
        rem ���펞�̓p�X
        call :logger_echo "[seven_args] exist_project ����I���ɂ����[���𑗐M���܂���"
        call :logger_crlf

    ) else (
        rem �ُ�I���ɂ����O�t�@�C���𑗐M
        call :error_proc_requester exist_project !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
        call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
        exit /b
    )

    rem Git �V�[�P���X
    if not %DEBUG_BAT%==ENABLE (
        rem �{�ԁi�f�o�b�O���X�L�b�v�j
        call :logger_echo "�� call :git"
        call :git
        set error_value=%errorlevel%
        call :logger_echo "[cov_snap_2.bat][seven_args] :git ���� :seven_args �ɖ߂�܂���"
        call :logger_crlf

        if !error_value!==0 (
            rem ���펞�̓p�X
            call :logger_echo "[seven_args] git ����I���ɂ����[���𑗐M���܂���"
            call :logger_crlf

        ) else (
            rem �ُ�I���ɂ����O�t�@�C���𑗐M
            call :error_proc_requester git !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
            exit /b

        )

    ) else (
        rem �f�o�b�O
        call :logger_echo "[error_proc_requester] �f�o�b�O���ɂ� :git ���X�L�b�v���܂�"
        call :logger_crlf

    )

    rem ------------------
    rem �X�i�b�v�V���b�g�擾
    rem ------------------
    rem SOAP API �𗘗p���� Coverity �\�[�X�R�[�h�w�E�̎擾
    call :logger_echo "�� call :cov_snap"
    call :cov_snap %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS%
    rem :cov_snap �̍Ō�� set error_value=%errorlevel%
    call :logger_crlf

    call :logger_echo "[cov_snap_2.bat][seven_args] :cov_snap ���� :seven_args �ɖ߂�܂���"
    call :logger_crlf

    rem ZIP�t�@�C���p�X����CSV�t�@�C���p�X�쐬
    set "CSV_FILE_PATH=!ZIP_FILE_PATH:.zip=.csv!"
    call :logger_echo "[cov_snap_2.bat][seven_args] CSV_FILE_PATH:" !CSV_FILE_PATH!
    call :logger_crlf

    rem ZIP�t�@�C���𑗐M
    call :logger_echo "�� call :error_proc_address"
    rem �A�h���X�t�@�C���̈���ɑ��M���邽�߂� %GITLAB_GROUP% ���K�v
    call :error_proc_address cov_snap %GITLAB_GROUP% %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !error_value! !ZIP_FILE_PATH!

    rem �ς���Ă��Ȃ����Ƃ��m�F
    call :logger_echo "[cov_snap_2.bat][seven_args] CSV_FILE_PATH�ierror_proc �Ăяo����j:" !CSV_FILE_PATH!
    call :logger_crlf
   
    rem echo BEFORE_REPLACEMENT: !BEFORE_REPLACEMENT!
    rem echo AFTER_REPLACEMENT: !AFTER_REPLACEMENT!
    rem pause

    rem CSV�t�@�C���̃t�@�C������u������
    if not !BEFORE_REPLACEMENT!=="" (
        rem �ύX�O�t�@�C���p�X�̋L�q������ꍇ�̂ݎ��{
        call :logger_echo "�� CSV�t�@�C���̃t�@�C�������o�O���|�[�g�i�E�F�u�Łj�p�ɒu�����܂�"
        rem call :replace_file_name !CSV_FILE_PATH! !BEFORE_REPLACEMENT! !AFTER_REPLACEMENT! �́A�S�p�󔒂ł����Ă���������Ă��܂�
        call :replace_file_name
        set error_value=%errorlevel%
        call :logger_echo "[cov_snap_2.bat][seven_args] :replace_file_name ���� :seven_args �ɖ߂�܂���"

        if !error_value!==0 (
            rem ���펞�̓p�X
            call :logger_echo "[seven_args] replace_file_name ����I���ɂ����[���𑗐M���܂���"
            call :logger_crlf

        ) else (
            rem �ُ�I���ɂ����O�t�@�C���𑗐M
            call :error_proc_requester replace_file_name !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
            exit /b
        
        )
    )


    rem -----------
    rem �񍐏��̍쐬
    rem -----------
    call :logger_echo "�� call :bug_report"

    rem �t�@�C���p�X�̊g���q��ZIP����CSV�ɒu�� �� cov_snap �Œu���ς݂Ȃ̂ŏȂ�
    rem cov_snap.py ���� print(error_level, zip_file_path) �Ŏ󂯎���� !ZIP_FILE_PATH!
    rem �g���q�������t�@�C�������擾����
    rem call :get_file_path !ZIP_FILE_PATH!
    rem set CSV_FILE_PATH=!FILE_PATH!.csv
    rem call :logger_echo CSV_FILE_PATH: !CSV_FILE_PATH!

    rem CSV�t�@�C���p�X�������Ɏ��s
    if exist bug_report_2.py (
        call :bug_report !CSV_FILE_PATH!
    ) else (
        call :logger_echo "[SKIP] bug_report_2.py ��������Ȃ����߁A���|�[�g�������X�L�b�v���܂�"
    )

    call :logger_echo "[cov_snap_2.bat][seven_args] :bug_report ���� :seven_args �ɖ߂�܂���"
    call :logger_crlf

    rem pause
    rem ZIP�t�@�C���𑗐M
    call :logger_echo "�� call :error_proc_address"
    rem �A�h���X�t�@�C���̈���ɑ��M���邽�߂� %GITLAB_GROUP% ���K�v
    call :error_proc_address bug_report %GITLAB_GROUP% %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !error_value! !REPORT_ZIP_FILE_PATH!

exit /b


:eight_args
    rem �\�[�X�R�[�h�� Perforce ����擾���Acov_snap, bug_report ���N����ACSV�t�@�C���i�����k����ZIP�t�@�C���j���A�h���X�t�@�C���ɓo�^���ꂽ���[���A�h���X�ɕԐM���܂�
    rem ��1����: p4�i���ʎq�j
    rem ��2����: Perforce_�O���[�v��
    rem ��3����: Perforce_depot_path
    rem ��4����: Perforce_revision
    rem ��5����: CC_�O���[�v��
    rem ��6����: CC_�X�g���[����
    rem ��7����: CC_�X�i�b�v�V���b�gID
    rem ��8����: ���[�����M�ҁiOutlook VBA���t�����܂��j
    rem �� CSV�t�@�C����B��t�@�C�����i�ύX�O�j�ƁACSV�t�@�C����B��t�@�C�����i�ύX��j�́Aprojects.cfg ����擾����

    call :logger_echo "[cov_snap_2.bat][eight_args] ���Ăяo����܂���"
    call :logger_echo "[cov_snap_2.bat][eight_args] ������ 8�ł�:" %1 %2 %3 %4 %5 %6 %7 %8
    call :logger_crlf

    rem �o�b�`�t�@�C�������̊m�F
    rem %1�͎��ʎqp4
    set P4_GROUP=%2
    set P4_DEPOT_PATH=%3
    set P4_REVISION=%4
    set CC_GROUP=%5
    set CC_STREAM=%6
    set CC_SNAPSHOT=%7
    set SENDEREMAILADDRESS=%8
    rem CSV�t�@�C����B��t�@�C�����i�ύX�O�ƕύX��j�́Aprojects.cfg�@����ǂݎ��
    rem set BEFORE_REPLACEMENT=%8
    rem set AFTER_REPLACEMENT=%9
    echo.

    call :logger_echo "�E1.P4_�O���[�v��:" %P4_GROUP%
    call :logger_echo "�E2.P4_�f�B�|�E�p�X:" %P4_DEPOT_PATH%
    call :logger_echo "�E3.P4_���r�W����:" %P4_REVISION%
    call :logger_echo "�E4.CC_�O���[�v��:" %CC_GROUP%
    call :logger_echo "�E5.CC_�X�g���[����:" %CC_STREAM%
    call :logger_echo "�E6.CC_�X�i�b�v�V���b�gID:" %CC_SNAPSHOT%
    call :logger_echo "�E7.���[�����M��:" %SENDEREMAILADDRESS%
    rem call :logger_echo "�E8.CSV�t�@�C����B��t�@�C�����i�ύX�O�j:" %BEFORE_REPLACEMENT%
    rem call :logger_echo "�E9.CSV�t�@�C����B��t�@�C�����i�ύX��j:" %AFTER_REPLACEMENT%
    call :logger_crlf

    rem exist_project �V�[�P���X�i�v���W�F�N�g�̑��݊m�F�j
    call :logger_echo "�� call :exist_project_p4"
    call :exist_project_p4
    set error_value=%errorlevel%
    call :logger_echo "[cov_snap_2.bat][eight_args] :exist_project_p4 ���� :eight_args �ɖ߂�܂���"

    if !error_value!==0 (
        rem ���펞�̓p�X
        call :logger_echo "[eight_args] exist_project ����I���ɂ����[���𑗐M���܂���"
        call :logger_crlf

    ) else (
        rem �ُ�I���ɂ����O�t�@�C���𑗐M
        call :error_proc_requester exist_project !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
        call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
        exit /b

    )

    rem P4 �V�[�P���X
    call :logger_echo "�� call :p4"
    call :p4
    set error_value=%errorlevel%
    call :logger_echo "[cov_snap_2.bat][eight_args] :p4 ���� :eight_args �ɖ߂�܂���"
    call :logger_crlf

    if !error_value!==0 (
        rem ���펞�̓p�X
        call :logger_echo "[eight_args] p4 ����I���ɂ����[���𑗐M���܂���"
        call :logger_crlf

    ) else (
        rem �ُ�I���ɂ����O�t�@�C���𑗐M
        call :error_proc_requester p4 !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
        call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
        exit /b
        
    )

    rem ------------------
    rem �X�i�b�v�V���b�g�擾
    rem ------------------
    rem SOAP API �𗘗p���� Coverity �\�[�X�R�[�h�w�E�̎擾
    call :logger_echo "�� call :cov_snap"
    call :cov_snap %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS%
    rem :cov_snap �̍Ō�� set error_value=%errorlevel%
    call :logger_crlf

    call :logger_echo "[cov_snap_2.bat][eight_args] :cov_snap ���� :eight_args �ɖ߂�܂���"
    call :logger_crlf

    rem ZIP�t�@�C���p�X����CSV�t�@�C���p�X�쐬
    set "CSV_FILE_PATH=!ZIP_FILE_PATH:.zip=.csv!"
    call :logger_echo "[cov_snap_2.bat][eight_args] CSV_FILE_PATH:" !CSV_FILE_PATH!
    call :logger_crlf

    rem if���̒��� %error_value% �ł͂Ȃ� !error_value! ���g������
    call :logger_echo "�� call :error_proc_address"

    rem ���펞�A�ُ펞�Ƃ��Ƀ`�[���ɕԐM
    rem �A�h���X�t�@�C���̈���ɑ��M���邽�߂� %P4_GROUP%���K�v
    call :error_proc_address cov_snap %P4_GROUP% %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% !error_value! !ZIP_FILE_PATH!

    rem �ς���Ă��Ȃ����Ƃ��m�F
    rem call :logger_echo "[cov_snap_2.bat][eight_args] CSV_FILE_PATH�ierror_proc �Ăяo����j:" !CSV_FILE_PATH!
    rem call :logger_crlf
    
    rem CSV�t�@�C���̃t�@�C������u������
    if not !BEFORE_REPLACEMENT!=="" (
        rem �ύX�O�t�@�C���p�X�̋L�q������ꍇ�̂ݎ��{
        call :logger_echo "�� CSV�t�@�C���̃t�@�C�������o�O���|�[�g�i�E�F�u�Łj�p�ɒu�����܂�"
        rem call :replace_file_name !CSV_FILE_PATH! !BEFORE_REPLACEMENT! !AFTER_REPLACEMENT!
        rem ��������ׂ�ƁA�S�p�󔒂ł����Ă���������Ă��܂�
        call :replace_file_name
        set error_value=!errorlevel!
        call :logger_echo "[cov_snap_2.bat] :replace_file_name ���� :eight_args �ɖ߂�܂���"

        if !error_value!==0 (
            rem ���펞�̓p�X
            call :logger_echo "[eight_args] replace_file_name ����I���ɂ����[���𑗐M���܂���"
            call :logger_crlf

        ) else (
            rem �ُ�I���ɂ����O�t�@�C���𑗐M
            call :error_proc_requester replace_file_name !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
            exit /b

        )

    )
    rem pause

    rem -----------------
    rem �񍐏��͍쐬���Ȃ�
    rem -----------------

exit /b


rem ----------------------------------------
rem Subroutines
rem ----------------------------------------

rem ��ʂƃ��O�t�@�C���ɕ�������o�͂���iecho �̂ݎ��s�j
:logger_echo
    rem Usage: call :logger_echo "arg1" ...
    rem  arg1~n �ɋ󔒂��܂ޏꍇ�� " �ň͂ށi�󔒂��Ȃ��ꍇ�͕s�v�j
    rem  e.g.1 call :logger_echo "�� �r���h�J�n"
    rem  e.g.2 call :logger_echo "�E�O���[�v��:" %GITLAB_GROUP% / %P4_GROUP%

    rem ����������̏�����
    set args=

:loop_logger_echo
    rem " ���폜���đ���i�s���ɋ󔒂���j
    set args=%args%%~1 
    shift
    rem ���ϐ���[]�ň͂݁A��ƁA�󔒁A= ���܂ޏꍇ�ɑΉ�
    rem if not "%1"=="" goto loop_logger_echo
    if not [%1] == [] goto loop_logger_echo

    rem ��ʗp�i" ���폜���Ȃ��j
    echo %args%
    rem ���O�t�@�C���p�i" ���폜���Ȃ��j
    echo %args% >> %LOGFILE% 2>&1

exit /b 0


rem ��ʂƃ��O�t�@�C���� CRLF ���o�͂���
:logger_crlf
    rem Usage: call :logger_crlf
    echo.
    echo. >> %LOGFILE%

exit /b 0


rem �R�}���h�����s���A���O�t�@�C���ɃR�}���h�̏o�͌��ʂ�ۑ�����
:logger
    rem Usage: call :logger command(arg1) "arg2" ...
    rem  arg1~n �ɋ󔒂��܂ޏꍇ�� " �ň͂ށi�󔒂��Ȃ��ꍇ�͕s�v�j
    rem  e.g.1 call :logger cd
    rem  e.g.2 call :logger del %LOCKFILE%
    rem  e.g.3 call :logger bash  -i -c "ls -l"

    rem ����������̏�����
    set cmds=

:loop_logger
    rem " ���폜���đ���i�s���ɋ󔒂���j
    set cmds=%cmds%%~1 
    shift
    rem ���ϐ���[]�ň͂݁A��ƁA�󔒁A= ���܂ޏꍇ�ɑΉ�
    rem if not "%1"=="" goto loop_logger
    if not [%1] == [] goto loop_logger
    
    rem call :logger_echo "[logger]" %1 %~2 %~3 %~4 %~5 %~6 "�̎��s"
    call :logger_echo "[logger]" %cmds% "�̎��s"
    rem %1 %~2 %~3 %~4 %~5 %~6 >> %LOGFILE% 2>&1
    rem echo %cmds%, !cmds!
    rem pause
    %cmds% >> %LOGFILE% 2>&1

    set error_value=!errorlevel!
    rem call :logger_echo "[logger]" %1 %~2 %~3 %~4 %~5 %~6 "�����s���܂��� error_value=" !error_value!
    call :logger_echo "[logger] %cmds% �����s���܂��� error_value= %error_value%"

exit /b %error_value%


rem �t�@�C���p�X�擾
:get_file_path
    echo [get_file_path] �h���C�u���A�p�X�i�g���q�������t�@�C�����܂Łj��Ԃ��܂�
    set FILE_PATH=%~dpn1
    call :logger_echo FILE_PATH=!FILE_PATH!
    call :logger_crlf

exit /b


rem �w�E���ʔz�M��̔F�胆�[�U�[�`�F�b�N
:cov_check_auth_user
    rem error_proc_address > send_mail_address ����Ă΂��
    rem %1 �́A%GITLAB_GROUP% �� %P4_GROUP%
    call :logger_echo "[cov_check_auth_user] �w�E���ʔz�M��̔F�胆�[�U�[�`�F�b�N�J�n"
    call :logger_echo "[cov_check_auth_user] ����(�O���[�v��): " %1

    rem *_address.csv ���� *_address_auth.csv ����
    %PYTHON% %SCRIPT_DIR%\cov_check_auth_user.py %ADDRESS_DIR%\%1_address.csv >> %LOGFILE% 2>&1
    set error_value=!errorlevel!

    call :logger_crlf

rem �G���[�͏�ɂ�����
exit /b !error_value!


rem ���{����v���W�F�N�g�������{ URL �ǂݍ���
:exist_project
    call :logger_echo "[exist_project] �v���W�F�N�g�����{�Ώۂ����ׂ܂�"

    rem �t�@�C�����݊m�F
    if not exist "%CFG_DIR%\projects.cfg" (
        call :logger_echo "projects.cfg ��������܂���B"
        exit /b 1
    )

    rem projects.cfg �t�@�C������ǂݍ���
    rem /f �� ; ����n�܂�s�������I�ɃX�L�b�v�A�󔒂��f���~�^�idelim= �s�v�j
    set execution=False
    for /f "tokens=1,2,3,4,5,6,7,8,9 eol=;" %%a in (%CFG_DIR%\projects.cfg) do (
        rem ��s�`�F�b�N
        if "%%a"=="" (
            echo WARNING: �����ȍs���X�L�b�v���܂����B
            continue
        )
        
        call :logger_echo --------------------------------------
        rem %%a �� 1. GitLab�O���[�v��
        call :logger_echo GITLAB_GROUP: %%a

        rem %%b �� 2. GitLab_�v���W�F�N�g��
        call :logger_echo GITLAB_PROJECT: %%b

        rem %%c �� 3. build_dir
        call :logger_echo BUILD_DIR: %%c

        rem %%d �� 4. projectKey
        call :logger_echo PROJECTKEY: %%d

        rem %%e �� 5. GitLab_URL
        set url=%%e
        call :logger_echo GitLab_url: !url!

        rem %%f �� 6. explanation
        call :logger_echo EXPLANATION: %%f

        rem %%g �� 7. e-mail_address
        call :logger_echo E-MAIL_ADDRESS: %%g

        rem %%h �� 8. �ύX�O�̃t�@�C���p�X
        set BEFORE_REPLACEMENT=%%h
        call :logger_echo BEFORE_REPLACEMENT: !BEFORE_REPLACEMENT!

        rem %%i �� 9. �ύX��̃t�@�C���p�X
        set AFTER_REPLACEMENT=%%i
        call :logger_echo AFTER_REPLACEMENT: !AFTER_REPLACEMENT!
        call :logger_crlf
        echo.

        rem if not "%errorlevel%"=="0" (
        rem     call :logger_echo WARNING %%a �̏������ɃG���[���������܂����B
        rem     continue
        rem )

        call :logger_echo "Pass 1" !execution!
        if %%a==%GITLAB_GROUP% (
            rem �O���[�v������
            if %%b==%GITLAB_PROJECT% (
                rem �O���[�v�����v���W�F�N�g���i�f�B�|�p�X�j�����݂���̂Ŏ��{����
                set execution=True
                call :logger_echo "Pass 2 GOOD: GitLab_�O���[�v���ƁAGitLab_�v���W�F�N�g�������݂���" !execution!

                rem GitLab URL �̎�؂�ւ��ikbit-repo.net ���Adev-gpf.com ���j
                echo !url:~8! > temp.txt
                for /f "tokens=1,2 delims=/" %%a in (temp.txt) do (
                    rem %url:~8% �� https:// ������2�ڂ�`/`�܂ł𒊏o
                    rem ��̓I�ɂ� kbit-repo.net/gitlab/ �� dev-gpf.com/gitlab/
                    rem �T�u�O���[�v��؂�{}�Ή��̂���
                    set GITLAB_URL_HEAD=https://%%a/%%b/
                    call :logger_echo "GitLab ��I�����܂����ikbit-repo.net/gitlab/ ���Adev-gpf.com/gitlab/ ���j:" !GITLAB_URL_HEAD!
                    call :logger_crlf
                )

                set error_value=0
                goto :exit_sub

            ) else (
                rem �O���[�v���͑��݂��邪�A�v���W�F�N�g�������݂��Ȃ�
                call :logger_echo "Pass 2 NG: GitLab_�O���[�v���͑��݂��邪�AGitLab_�v���W�F�N�g�������݂��Ȃ�" !execution!
                set /A "error_value = error_value | 2"

            )

        ) else (
            call :logger_echo "Pass 1 NG: GitLab_�O���[�v�������݂��Ȃ�" !execution!
            call :logger_crlf
            rem �O���[�v�������݂��Ȃ�
            set /A "error_value = error_value | 1"
            echo.
        )

    )

    :exit_sub
        rem ���[�v����̒E�o��
        call :logger_echo "[exist_project] ���[�v����o�܂����Berror_value=" !error_value!

    call :logger_echo "[exist_project] exit" !execution!
    if "%execution%"=="False" (
        echo.
        call :logger_echo "[exist_project] ���{�Ώۂł͂Ȃ��̂ŉ������܂���Berror_value=" !error_value!
        call :logger_echo "[exist_project]   error_value= 1 �̂Ƃ� GitLab_�O���[�v�������݂��Ȃ�"
        call :logger_echo "[exist_project]   error_value��2 �̂Ƃ� GitLab_�O���[�v���͑��݂��邪�AGitLab_�v���W�F�N�g�������݂��Ȃ�"

    ) else (
        echo.
        call :logger_echo "[exist_project] �ΏۃO���[�v�A�v���W�F�N�g�����݂��܂����Berror_value=" !error_value!
        call :logger_echo "[exist_project]   error_value=0 �̂Ƃ� GitLab_�O���[�v����GitLab_�v���W�F�N�g�������݂���"

    )
    call :logger_crlf

exit /b !error_value!


rem ���{����v���W�F�N�g�������{ Perforce URL �ǂݍ���
:exist_project_p4
    call :logger_echo "[exist_project_p4] �v���W�F�N�g�����{�Ώۂ����ׂ܂�"

    rem ��������AP4 ���[�J���p�X���쐬���� -> �����Ŏ󂯎��
    rem set P4_DEPOT_PATH=//depot/%P4_GROUP%/%P4_PROJECT%/
    call :logger_echo [exist_project_p4] Perforce_depot_path: %P4_DEPOT_PATH%

    rem �t�@�C�����݊m�F
    if not exist "%CFG_DIR%\projects.cfg" (
        call :logger_echo "projects.cfg ��������܂���B"
        exit /b 1
    )

    rem pause

    rem projects.cfg �t�@�C������ǂݍ���
    rem ; �Ŏn�܂�s�������I�ɃX�L�b�v�A�󔒂��f���~�^�idelim= �s�v�j
    set execution=False
    for /f "tokens=1,2,3,4,5,6,7,8,9,10 eol=;" %%a in (%CFG_DIR%\projects.cfg) do (
        rem ��s�`�F�b�N
        if "%%a"=="" (
            echo WARNING: �����ȍs���X�L�b�v���܂����B
            continue
        )
        rem pause

        rem %%a �� 1. P4 DEPOT ID �i���ʎq�j
        rem call :logger_echo P4_DEPOT_ID %%a
        echo P4_DEPOT_ID: %%a
        rem {}depot
        rem if not "%errorlevel%"=="0" (
        rem     echo WARNING %%a �̏������ɃG���[���������܂����B
        rem     continue
        rem )

        rem %%b �� 2. P4�O���[�v��
        rem p4_group_name
        call :logger_echo P4_GROUP: %%b

        rem %%c �� 3. P4�f�B�|�p�X
        rem //depot/p4_group_name/
        call :logger_echo P4_DEPOT_PATH: %%c

        rem %%d �� 4. P4���r�W����
        rem head
        call :logger_echo P4_REVISION: %%d

        rem %%e �� 5. CC �O���[�v��
        rem cc_group_name
        call :logger_echo CC_GROUP: %%e

        rem %%f �� 6. CC �X�g���[����
        rem cc_stream_name
        call :logger_echo CC_STREAM: %%f

        rem %%g �� 7. CC �X�i�b�v�V���b�gID
        rem 15048
        call :logger_echo CC_SNAPSHOT_ID: %%g

        rem %%h �� 8.���[���A�h���X
        rem sender@sample.com
        call :logger_echo e-mail: %%h

        rem %%i �� 9. �ύX�O�̃t�@�C���p�X
        set BEFORE_REPLACEMENT=%%i
        call :logger_echo BEFORE_REPLACEMENT: !BEFORE_REPLACEMENT!

        rem %%j �� 10. �ύX��̃t�@�C���p�X
        set AFTER_REPLACEMENT=%%j
        call :logger_echo AFTER_REPLACEMENT: !AFTER_REPLACEMENT!
        call :logger_crlf
        echo.

        rem if not "%errorlevel%"=="0" (
        rem     call :logger_echo WARNING %%a �̏������ɃG���[���������܂����B
        rem     continue
        rem )

        call :logger_echo "Pass 1" !execution!
        if %%b==%P4_GROUP% (
            rem �O���[�v������
            if %%c==%P4_DEPOT_PATH% (
                rem �O���[�v�����v���W�F�N�g���i�f�B�|�p�X�j�����݂���̂Ŏ��{����
                set execution=True
                call :logger_echo "Pass 2 GOOD: �O���[�v�����v���W�F�N�g�������݂���" !execution!

                set error_value=0
                goto :exit_sub

            ) else (
                rem �O���[�v���͑��݂��邪�A�v���W�F�N�g�������݂��Ȃ�
                call :logger_echo "Pass 2 NG: �O���[�v���͑��݂��邪�A�v���W�F�N�g�������݂��Ȃ�" !execution!
                set /A "error_value = error_value | 2"

            )

        ) else (
            call :logger_echo "Pass 1 NG: �O���[�v�������݂��Ȃ�" !execution!
            rem �O���[�v�������݂��Ȃ�
            set /A "error_value = error_value | 1"
            echo.
        )

    )

    :exit_sub
        rem ���[�v����̒E�o��
        call :logger_echo "[exist_project_p4] ���[�v����o�܂����Berror_value=" !error_value!

    call :logger_echo "[exist_project_p4] exit" !execution!
    if "%execution%"=="False" (
        echo.
        call :logger_echo "[exist_project_p4] ���{�Ώۂł͂Ȃ��̂ŉ������܂���Berror_value=" !error_value!
        call :logger_echo "[exist_project_p4]   error_value= 1 �O���[�v�������݂��Ȃ�"
        call :logger_echo "[exist_project_p4]   error_value��2 �O���[�v���͑��݂��邪�A�v���W�F�N�g�������݂��Ȃ�"

    ) else (
        echo.
        call :logger_echo "[exist_project_p4] �ΏۃO���[�v�A�v���W�F�N�g�����݂��܂����Berror_value=" !error_value!
        call :logger_echo "[exist_project_p4]   error_value=0 �O���[�v�����v���W�F�N�g�������݂���"

    )
    call :logger_crlf

exit /b !error_value!


rem Git �R�}���h�Q�̎��s
:git
    call :logger_echo "[git] �\�t�g�E�F�A�̕ύX�擾"

    rem �O���[�v���̃f�B���N�g�������݂��Ȃ��Ȃ�쐬
    call :logger cd %GROUPS_DIR%%
    if not exist %GITLAB_GROUP% (
        call :logger_echo "[git] �O���[�v�E�f�B���N�g�� %GITLAB_GROUP% �����݂��Ȃ��̂ō쐬���܂�"
        call :logger mkdir %GITLAB_GROUP%
    
    )

    call :logger cd %GITLAB_GROUP%
    call :logger_crlf

    call :logger_echo "[git] �J�����g�f�B���N�g���i:git �����BGitLab_�O���[�v���t�H���_�ɂ���j"
    call :logger cd
    call :logger_crlf

    rem �o�[�W�����\��
    call :logger_echo "[git] git --version"
    call :logger git --version
    rem git version 2.23.0.windows.
    call :logger_crlf
    
    rem �v���W�F�N�g�E�f�B���N�g���̑��݊m�F
    if not exist %GITLAB_PROJECT% (
        echo.
        call :logger_echo "[git] �v���W�F�N�g�E�f�B���N�g�� %GITLAB_PROJECT% �����݂��Ȃ��̂ŁA�O���[�v�E�f�B���N�g���� git clone ���܂�"

        rem �T�u�O���[�v������ꍇ�A{} �� / �ɒu������
        rem call :logger_echo "[git] git clone" https://kbit-repo.net/gitlab/%GITLAB_GROUP:{}=/%/%GITLAB_PROJECT%.git %GITLAB_PROJECT%
        rem git clone https://kbit-repo.net/gitlab/%GITLAB_GROUP:{}=/%/%GITLAB_PROJECT%.git %GITLAB_PROJECT% >> %LOGFILE% 2>&1
        call :logger_echo "[git] GITLAB_URL_HEAD:" !GITLAB_URL_HEAD!
        call :logger_echo "[git] git clone" !GITLAB_URL_HEAD!%GITLAB_GROUP:{}=/%/%GITLAB_PROJECT%.git %GITLAB_PROJECT%
        git clone !GITLAB_URL_HEAD!%GITLAB_GROUP:{}=/%/%GITLAB_PROJECT%.git %GITLAB_PROJECT% >> %LOGFILE% 2>&1

        rem �E���s���Ă��i%errorlevel%=0�j
        rem error: unable to create file path/to/*.h: Filename too long
        rem %errorlevel%=0 �Ȃ̂ŃG���[�Ή��ł��Ȃ�
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem ���펞�̓p�X
            call :logger_echo "[git] git_clone ����I���ɂ����[���𑗐M���܂���"
            call :logger_crlf

        ) else (
            rem �ُ�I���ɂ����O�t�@�C���𑗐M
            call :error_proc_requester git_clone !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
            exit /b

        )

        call :logger cd %GITLAB_PROJECT%
        call :logger_echo "[git] �J�����g�f�B���N�g���igit clone ����B�v���W�F�N�g���t�H���_�ɂ���j"
        call :logger cd
        call :logger_crlf

        call :logger_echo "[git] �u�����`��؂�ւ��܂�"
        
        call :logger_echo "[git] git switch" %GITLAB_BRANCH:{}=/%
        rem git switch -c DIT_Missing_device_information -> fatal: A branch named 'DIT_Missing_device_information' already exists.
        git switch %GITLAB_BRANCH:{}=/% >> %LOGFILE% 2>&1
        set error_value=!errorlevel!

        rem �G���[�Ή�
        rem �E���s�i%errorlevel%=128�j
        rem fatal: invalid reference: master_2022
        rem fatal: A branch named 'main' already exists.
        if !error_value!==0 (
            rem ���펞�̓p�X
            call :logger_echo "[git] git_switch ����I���ɂ����[���𑗐M���܂���"
            call :logger_crlf

        ) else (
            rem �ُ�I���ɂ����O�t�@�C���𑗐M
            call :error_proc_requester git_switch !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
            exit /b

        )

    ) else (
        echo �v���W�F�N�g�E�f�B���N�g�������݂���
        call :logger cd %GITLAB_PROJECT%
        call :logger_echo "[git] �J�����g�f�B���N�g���igit clone ���Ȃ��ꍇ�B�v���W�F�N�g���t�H���_�ɂ���j"
        call :logger cd
        call :logger_crlf

        call :logger_echo "[git] �v���W�F�N�g�E�f�B���N�g�� %GITLAB_PROJECT% �����݂���̂ŁA�u�����`��؂�ւ� git fetch ���܂�"
        git fetch >> %LOGFILE% 2>&1

        call :logger_echo "[git] �u�����`���m�F���܂�!"
        call :logger_echo "[git] git --no-pager branch"
        git --no-pager branch
        git --no-pager branch >> %LOGFILE%
        call :logger_crlf

        call :logger_echo "[git] �}�[�W���~"
        call :logger_echo "[git] git merge --quit"
        rem pause
        git merge --quit >> %LOGFILE% 2>&1

        rem �G���[�Ή�
        rem �E���s�i%errorlevel%=?�j
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem ���펞�̓p�X
            call :logger_echo "[git] git_merge_quit ����I���ɂ����[���𑗐M���܂���"
            call :logger_crlf

        ) else (
            rem �ُ�I���ɂ����O�t�@�C���𑗐M
            call :error_proc_requester git_merge_quit !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
            exit /b

        )

        call :logger_echo "[git] �}�[�W�������΍�"
        call :logger_echo "[git] git reset --merge"
        rem pause
        git reset --merge >> %LOGFILE% 2>&1

        rem �G���[�Ή�
        rem �E���s�i%errorlevel%=?�j
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem ���펞�̓p�X
            call :logger_echo "[git] git_reset_merge ����I���ɂ����[���𑗐M���܂���"
            call :logger_crlf

        ) else (
            rem �ُ�I���ɂ����O�t�@�C���𑗐M
            call :error_proc_requester git_reset_merge !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
            exit /b

        )

        call :logger_echo "[git] HEAD �����Z�b�g���܂�"
        rem ��ƃR�s�[���ɖ��R�~�b�g�̓��e������� switch �Ɏ��s����̂ŁA
        rem HEAD�i�O��r���h�����R�~�b�g�j�܂Ń��Z�b�g����
        call :logger_echo "[git] git reset --hard HEAD"
        rem pause
        git reset --hard HEAD | nkf32.exe -s >> %LOGFILE% 2>&1

        rem �G���[�Ή�
        rem �E���s�i%errorlevel%=?�j
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem ���펞�̓p�X
            call :logger_echo "[git] git_reset ����I���ɂ����[���𑗐M���܂���"
            call :logger_crlf

        ) else (
            rem �ُ�I���ɂ����O�t�@�C���𑗐M
            call :error_proc_requester git_reset !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
            exit /b

        )

        call :logger_echo "[git] ����̃r���h�Ώۃu�����`�ɐ؂�ւ��܂�"
        call :logger_echo "[git] git switch" %GITLAB_BRANCH:{}=/%
        rem git switch -c DIT_Missing_device_information -> fatal: A branch named 'DIT_Missing_device_information' already exists.
        git switch %GITLAB_BRANCH:{}=/% >> %LOGFILE% 2>&1
            
        rem �G���[�Ή�
        rem �E���s�i%errorlevel%=128�j
        rem fatal: invalid reference: master_2022
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem ���펞�̓p�X
            call :logger_echo "[git] git_switch ����I���ɂ����[���𑗐M���܂���"
            call :logger_crlf

        ) else (
            rem �ُ�I���ɂ����O�t�@�C���𑗐M
            call :error_proc_requester git_switch !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
            exit /b

        )

        call :logger_echo "[git] �����[�g�̍X�V�����[�J���Ɏ�荞�݂܂�"
        call :logger_echo "[git] git fetch origin"
        rem pause
        git fetch origin  >> %LOGFILE% 2>&1

        rem �G���[�Ή�
        rem �E���s�i%errorlevel%=?�j
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem ���펞�̓p�X
            call :logger_echo "[git] git_fetch ����I���ɂ����[���𑗐M���܂���"
            call :logger_crlf

        ) else (
            rem �ُ�I���ɂ����O�t�@�C���𑗐M
            call :error_proc_requester git_fetch !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
            exit /b

        )
        rem pause
    
        call :logger_echo "[git] git reset --hard origin/" %GITLAB_BRANCH:{}=/%
        rem pause
        git reset --hard origin/%GITLAB_BRANCH:{}=/% | nkf32.exe -s >> %LOGFILE% 2>&1

        rem �G���[�Ή�
        rem �E���s�i%errorlevel%=?�j
        set error_value=!errorlevel!
        if !error_value!==0 (
            rem ���펞�̓p�X
            call :logger_echo "[git] git_reset ����I���ɂ����[���𑗐M���܂���"
            call :logger_crlf

        ) else (
            rem �ُ�I���ɂ����O�t�@�C���𑗐M
            call :error_proc_requester git_reset !error_value! %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
            exit /b

        )
        rem pause
    
    )

    call :logger_crlf

    call :logger_echo "[git] �J�����g�f�B���N�g���igit clone �� fetch ������B�v���W�F�N�g���t�H���_�ɂ���j"
    call :logger cd
    call :logger_crlf

    call :logger_echo "[git] �u�����`���m�F���܂�"
    call :logger_echo "[git] git --no-pager branch"
    git --no-pager branch
    call :logger git --no-pager branch

    rem git clone �G���[ Filename too long �Ή��i���{�ς݁j
    rem > git config --system core.longpaths true

    rem �u�����`���̃f�B���N�g�����݊m�F
    if not exist %GITLAB_BRANCH% (
        rem �u�����`�E�f�B���N�g���Ȃ�
        echo.
        call :logger_echo "[git] �u�����`�E�f�B���N�g��" %GITLAB_BRANCH% "�����݂��Ȃ��̂ō쐬���܂�"
        call :logger mkdir %GITLAB_BRANCH%
    
    ) else (
        rem �u�����`�E�f�B���N�g������
        echo.
        call :logger_echo "[git] �u�����`�E�f�B���N�g�����t�H���_���ƍ폜���܂�"
        rem pause
        rem del /S /Q %GITLAB_BRANCH% >> %LOGFILE% 2>&1
        rem �t�@�C�������폜���ăt�H���_�[���c��̂ŁArmdir �ɕύX
        call :logger rmdir /S /Q %GITLAB_BRANCH%
        rem %Brnch% �t�H���_���폜�����̂ŁA������x���
        call :logger mkdir %GITLAB_BRANCH%
    
    )
    call :logger_crlf
    rem pause

    call :logger_echo "[git] ���݂�HEAD���w���R�~�b�g���e���u�����`�t�H���_�ɏ����o���܂�"
    call :logger_echo "[git] checkout-index -a -f --prefix=" %GROUPS_DIR%\%GITLAB_GROUP%\%GITLAB_PROJECT%\%GITLAB_BRANCH%\
    git checkout-index -a -f --prefix=%GROUPS_DIR%\%GITLAB_GROUP%\%GITLAB_PROJECT%\%GITLAB_BRANCH%\ >> %LOGFILE% 2>&1
    set error_value=!errorlevel!
    if !error_value!==0 (
        rem ���펞�̓p�X
        call :logger_echo "[git] git_checkout_index ����I���ɂ����[���𑗐M���܂���"
        call :logger_crlf

    ) else (
        rem �ُ�I���ɂ����O�t�@�C���𑗐M
        call :error_proc_requester git_checkout_index %error_value% %CC_STREAM% %CC_SNAPSHOT% %SENDEREMAILADDRESS% %LOGFILE%
            call :logger_echo "�� cov_snap_2.bat �ُ�I�����܂�"
            exit /b

    )

    call :logger cd %GITLAB_BRANCH%
    call :logger_echo "[git] �J�����g�f�B���N�g���igit checkout-index ��B�u�����`���t�H���_�ɂ���j"
    call :logger cd
    call :logger_crlf
    
    rem �J�����g�f�B���N�g�������ɖ߂�
    call :logger cd %SCRIPT_DIR%
    call :logger_crlf

exit /b !error_value!


rem cov_snap.py SOAP API �𗘗p���� Coverity �\�[�X�R�[�h�w�E�̎擾
:cov_snap
    rem ���́i�����j: %1: %CC_STREAM%, %2: %SNAPSHOTID%, %3: %SENDEREMAILADDRESS%
    rem �o��: %error_value%

    call :logger_echo "[cov_snap] cov_snap.py Python�X�N���v�g���s�J�n"
    call :logger_echo "[cov_snap] %PYTHON%" %SCRIPT_DIR%\cov_snap.py %1 %2 !SENDEREMAILADDRESS!
    call :logger_crlf

    rem py %SCRIPT_DIR%\cov_snap.py %1 %2 %3 ���s�i%SENDEREMAILADDRESS% ���F�胆�[�U�[�����肷��j
    for /f "usebackq tokens=1,2" %%A in (`%PYTHON% %SCRIPT_DIR%\cov_snap.py %1 %2 %3`) do (
        rem cov_snap.py ���� print(error_level, zip_file_path) �Ŏ󂯎��
        set error_value=%%A
        set ZIP_FILE_PATH=%%B
    )

    rem ��for /f ... �̖߂�l�ُ͈�̎��ł� %errorlevel% �� 0 �ɂȂ�̂ŁA
    rem cov_snap.py ���� print���ŁAerror_level �� zip_file_path ���󂯎��
    rem echo %RET_VALUE%

    rem error_value �́A3���Œ�Ƃ���i1���ڂ���3���擾�j
    rem set error_value=%RET_VALUE:~0,3%
    rem echo %error_value%
    
    rem ZIP_FILE_PATH �́A5���ڂ��疖���܂Ŏ擾
    rem set ZIP_FILE_PATH=%RET_VALUE:~4%
    rem echo %ZIP_FILE_PATH%


    rem ����̎��AZIP_FILE_PATH �Ƀt�@�C���̑��΃p�X�i��: .\snapshots\assisnet_prj\assisnet_prj\csv_zip\snapshot_id_11655.zip�j������
    rem �ُ�̂Ƃ� ZIP_FILE_PATH �Ɉُ헝�R������
    call :logger_crlf
    call :logger_echo "cov_snap.py ����̖߂�l�Berrorlevel:" %error_value% ", ZIP_FILE_PATH:" %ZIP_FILE_PATH%
    
    rem ����E�ُ픻��
    if %ZIP_FILE_PATH:~-3%==zip (
        rem *.zip �Ȃ琳��

        rem ZIP_FILE_PATH �𑊑΃p�X�����΃p�X�ɕϊ��i.\ �폜: %S:~x% ��(x+1)�����ڂ��疖���܂Ő؂�o���j
        set ZIP_FILE_PATH=%SCRIPT_DIR%\%ZIP_FILE_PATH:~2%
        echo ZIP_FILE_PATH=!ZIP_FILE_PATH!
        rem pause
        
    ) else (
        rem �ُ�
        rem ZIP_FILE_PATH �ɂ� FileNotFoundError, totalNumberOfCids_0 �Ȃǂُ̈헝�R������
        rem error_value="704" �Ȃǂ̃p�[�X�� :error_proc_requester �ōs��
        echo ZIP_FILE_PATH=!ZIP_FILE_PATH!
        rem pause

    )

    echo error_value=%error_value%
    echo ZIP_FILE_PATH=%ZIP_FILE_PATH%
    rem pause

rem �G���[�͏�ɂ�����
exit /b %error_value%


rem ���񍐏����쐬����
:bug_report
    rem �񍐏����쐬����
    rem ���́i�����j: %1: %CSV_FILE_PATH%
    rem �o��: %error_value%

    call :logger_echo "[bug_report] bug_report_2.py Python�X�N���v�g���s�J�n"
    call :logger_echo "[bug_report] %PYTHON%" %SCRIPT_DIR%\bug_report_2.py %1

    rem bug_report_2.py ���s
    %PYTHON% %SCRIPT_DIR%\bug_report_2.py %1
    set error_value=%errorlevel%

    rem *.py ���� print���̐��Ɉˑ�����̂Ŏ~�߂�
    rem DONE: bug_report_file_path.txt �Ƀt�@�C���p�X�̋L�ڂ͂���
    rem for /f "usebackq tokens=1,2" %%A in (`%PYTHON% %SCRIPT_DIR%\bug_report_2.py %1`) do (
    rem     rem bug_report_2.py ���� print(error_level, REPORT_ZIP_FILE_PATH) �Ŏ󂯎��
    rem     set error_value=%%A
    rem     set REPORT_ZIP_FILE_PATH=%%B
    rem     echo REPORT_ZIP_FILE_PATH: !REPORT_ZIP_FILE_PATH!
    rem     pause
    rem )

    call :logger_echo "[bug_report] bug_report_2.py ���o�͂����t�@�C�� %SCRIPT_DIR%\bug_report_file_path.txt ��ǂݍ���"
    call :logger_echo "[bug_report] �񍐏����k�t�@�C���̃p�X�� bug_report_file_path.txt �ɏ�����Ă���"
    call :logger_echo "[bug_report] ��errorlevel ��0�ȊO�̎��� bug_report_file_path.txt �̓��e�͕ʕ��i�X�V����Ă��Ȃ��j"
    set /p REPORT_ZIP_FILE_PATH=<bug_report_file_path.txt

    rem REPORT_ZIP_FILE_PATH �ɖ��񍐏��t�@�C���̐�΃p�X������
    rem ��: C:\Users\shimatani\Docs\GitLab\Security\cov_snap\snapshots\MESSIAH\messiah_tool\csv_zip\bug_report_14606.zip
    call :logger_echo "[bug_report] bug_report_2.py ����̖߂�l�Berrorlevel:" %error_value% ", REPORT_ZIP_FILE_PATH:" %REPORT_ZIP_FILE_PATH%
    call :logger_crlf

    rem ����E�ُ픻��
    if %REPORT_ZIP_FILE_PATH:~-3%==zip (
        rem *.zip �Ȃ琳��
        call :logger_echo "[bug_report] !REPORT_ZIP_FILE_PATH! �𐳏�ɓǂݍ��݂܂���"

    ) else (
        rem �ُ�
        call :logger_echo "[bug_report] !REPORT_ZIP_FILE_PATH! �𐳏�ɓǂݍ��߂܂���ł���"
        rem REPORT_ZIP_FILE_PATH �ɂ� FileNotFoundError, totalNumberOfCids_0 �Ȃǂُ̈헝�R������
        rem error_value="704" �Ȃǂ̃p�[�X�� :error_proc_requester �ōs��

    )

    call :logger_crlf
    echo error_value=!error_value!
    echo REPORT_ZIP_FILE_PATH=!REPORT_ZIP_FILE_PATH!
    rem pause


rem �G���[�͏�ɂ�����
exit /b %error_value%


rem p4 �R�}���h�̎��s
:p4
    call :logger_echo "[p4] ���r�W�������t�F�b�`���܂��iPython �X�N���v�g���s�j"
    rem %1: p4_group, %2: depot_path, %3: revision, %4: snapshot_id
    call :logger_echo %PYTHON% p4.py %P4_GROUP% %P4_DEPOT_PATH% %P4_REVISION% %CC_SNAPSHOT%
    call %PYTHON% p4.py %P4_GROUP% %P4_DEPOT_PATH% %P4_REVISION% %CC_SNAPSHOT%

    rem p4.py ���s��̃G���[���x�����m�F
    set "error_value=%errorlevel%"
    if !error_value! equ 0 (
        call :logger_echo "[p4] ����Ɋ������܂���"

    ) else (
        call :logger_echo "[p4] �G���[���������܂����B�G���[���x��: " !error_value!

    )

exit /b !error_value!


rem CSV�t�@�C���̃t�@�C�������o�O���|�[�g�i�E�F�u�Łj�p�ɒu������
:replace_file_name
    rem �S�p�󔒂ł����Ă���������Ă��܂��̂ň�����ݒ肵�Ȃ�
    rem %1: CSV�t�@�C����, %2: �u���O������, %3: �u���㕶����
    rem set "csv_file=%1"
    rem set "before_replacement=%2"
    rem set "after_replacement=%3"

    rem �S�p�󔒂𔼊p�󔒂ɒu��
    rem cov_snap_2.bat �Œ�`���ꂽ���ϐ� CSV_FILE_PATH �̓��[�J���X�R�[�v�Ȃ̂Ŏg���Ȃ�
    rem set "csv_file=!CSV_FILE_PATH!"
    rem �t�@�C������擾����
    rem set /p csv_file=<csv_file_path.txt
    rem call :logger_echo "[replace_file_name] CSV_FILE_PATH: %csv_file%"

    rem �S�p�󔒂𔼊p�󔒂ɕϊ�
    set search_text=!BEFORE_REPLACEMENT:�@= !
    set replace_text=!AFTER_REPLACEMENT:�@= !

    call :logger_echo "[replace_file_name] search_text: " %search_text%
    call :logger_echo "[replace_file_name] replace_text: " %replace_text%

    rem search_text �܂��� replace_text �� '-' �̏ꍇ�͒u�����Ȃ��iPowerShell �����s���Ȃ��j
    if "%search_text%"=="-" (
        set "error_value=0"
        call :logger_echo "[replace_file_name] �ύX�O�̕����� '-' �Ȃ̂Œu�����܂���"
        call :logger_crlf
        exit /b !error_value!
    )
    if "%replace_text%"=="-" (
        set "error_value=0"
        call :logger_echo "[replace_file_name] �ύX��̕����� '-' �Ȃ̂Œu�����܂���"
        call :logger_crlf
        exit /b !error_value!
    )

    rem PowerShell�Œu���������s��
    rem �ȉ���CP932���G���R�[�h�ł��Ȃ�
    rem powershell -Command ^
    rem     "Import-Csv -Path '%csv_file%' -Encoding CP932 | ForEach-Object {" ^
    rem     "   $_.'�t�@�C����' = $_.'�t�@�C����' -replace '%search_text%', '%replace_text%';" ^
    rem     "   $_" ^
    rem     "} | Export-Csv -Path '%csv_file%' -NoTypeInformation -Encoding CP932"

    rem Get-Content ���g�p���āA�t�@�C���� -Encoding Default �œǂݍ��݁AConvertFrom-Csv ���g��
    rem CSV_FILE_PATH ���g����
    powershell -Command ^
        "$csvFile = '%CSV_FILE_PATH%';" ^
        "$searchText = '%search_text%';" ^
        "$replaceText = '%replace_text%';" ^
        "$csvData = Get-Content -Path $csvFile -Encoding Default | ConvertFrom-Csv;" ^
        "$csvData | ForEach-Object {" ^
        "   $_.'�t�@�C����' = $_.'�t�@�C����' -replace $searchText, $replaceText;" ^
        "};" ^
        "$csvData | Export-Csv -Path $csvFile -NoTypeInformation -Encoding Default"
    
    rem PowerShell���s��̃G���[���x�����m�F
    set "error_value=%errorlevel%"
    if !error_value! equ 0 (
        call :logger_echo "[replace_file_name] �u������������Ɋ������܂���"
    ) else (
        call :logger_echo "[replace_file_name] �G���[���������܂����B�G���[���x��: " !error_value!
    )
    call :logger_crlf

exit /b !error_value!


rem bug_report, cov_snap, ���̑��Ή� ���ʃG���[�����T�u���[�`���i�˗��Ҍl�ɕԐM�j
rem ���펞�̓��[���𑗐M���Ȃ��B�ُ펞�̂݃��[���𑗐M���ďI������
:error_proc_requester
    rem �Ăяo������ bug_report, cov_snap �̎��A������7�B���̑��̎��A������2��
    rem %1: �Ăяo���� (��: bug_report, cov_snap ���̑�)
    rem %2: �G���[���x�� (��: 0, 1100, 700, etc.)
    rem �ȉ��� bug_report, cov_snap,  �̏ꍇ�̂�
    rem %3: (send_mail_5.vbs �� GITLAB_GROUP ���v�邪�A send_mail_5.vbs �͎g��Ȃ�)
    rem %3: CC_STREAM
    rem %4: CC_SNAPSHOT
    rem %5: SENDEREMAILADDRESS
    rem %6: ���O�t�@�C���܂���ZIP�t�@�C���p�X

    rem %1: �Ăяo���� (��: bug_report, cov_snap,  �ȊO�� git_switch �Ȃ�)
    rem %2: �G���[���x��

    call :logger_echo "[error_proc_requester] �J�n - �Ăяo����:" %1 ", �G���[���x��:" %2

    rem �G���[���x�����i�[
    set "error_value=%2"

    if "%error_value%" == "0" (
        rem ���폈��
        call :logger_echo "[error_proc_requester] ����I���B�G���[���x��:" %error_value%

        rem ���[���𑗐M���Ȃ��Ŗ߂�ꍇ
        rem exit /b %error_value%

    ) else (
        rem �ُ폈��
        if "%1" == "bug_report" (
            if "%error_value%" == "1100" (
                call :logger_echo "[error_proc_requester] bug_report_2.py ChatGPT query error"

            ) else if "%error_value%" == "1101" (
                call :logger_echo "[error_proc_requester] bug_report_2.py FileNotFound"

            ) else (
                call :logger_echo "[error_proc_requester] bug_report ���̑��ُ̈�"

            )

        ) else if "%1" == "cov_snap" (
            if "%error_value%" == "700" (
                call :logger_echo "[error_proc_requester] cov_snap.py last.json �t�@�C�������݂��܂���"

            ) else if "%error_value%" == "701" (
                call :logger_echo "[error_proc_requester] cov_snap.py ZIP�t�@�C�������݂��܂���"

            ) else (
                call :logger_echo "[error_proc_requester] cov_snap ���̑��ُ̈�"

            )

        ) else (
            rem ���̑��̏ꍇ
            call :logger_echo "[error_proc_requester] ���̑��̌Ăяo����:" %1 ", �G���[���x��:" %error_value%

        )
    )
    call :logger_crlf

    rem ����E�ُ펞���[�����M�����i���ʉ��j
    if not "%DEBUG_BAT%" == "ENABLE" (
        rem �{��
        if "%1" == "bug_report" (
            call :send_mail_requester send_mail_bug_report.vbs %3 %4 %5 %error_value% %6
        
        ) else if "%1" == "cov_snap" (
            call :send_mail_requester send_mail_cov_snap.vbs %3 %4 %5 %error_value% %6
        
        ) else (
            rem ���̑��̏ꍇ
            rem TODO: �Ăяo�����̈����s���Ή��v
            call :send_mail_requester send_mail_cov_snap.vbs %3 %4 %5 %error_value% %6
        )

    ) else (
        rem �f�o�b�O��
        call :logger_echo "[error_proc_requester] �f�o�b�O���ɂ����[���𑗐M���܂���"

    )

    call :logger_echo "[error_proc_requester] �� ���[���𑗐M�� :error_proc_requester �ɖ߂��Ă��܂���"
    call :logger_crlf

exit /b %error_value%


rem ����E�ُ�I�������ʂ̃��[�����M�T�u���[�`���i�˗��Ҍl�ɕԐM�j
:send_mail_requester
    rem ����:
    rem %1: VBS�X�N���v�g�� (send_mail_bug_report.vbs, send_mail_cov_snap.vbs)
    rem %2: CC_STREAM
    rem %3: CC_SNAPSHOT
    rem %4: SENDEREMAILADDRESS
    rem %5: error_value
    rem %6: ZIP_FILE_PATH �܂��� LOGFILE (�I�v�V���� - ���݂��Ȃ��ꍇ�͋󕶎�)

    call :logger_echo "[send_mail_requester] �J�n - VBS�X�N���v�g:" %1
    call :logger_echo "[send_mail_requester] ����: %2, %3, %4, %5, %6"

    rem �F�胆�[�U�[�`�F�b�N�͍s��Ȃ��i�����O���[�v�����擾���Ă��Ȃ����߁j

    rem ���[�����M����
    call :logger_echo "[send_mail_requester] cscript %SCRIPT_DIR%\%1 %2 %3 %4 %5 %6"
    cscript %SCRIPT_DIR%\%1 %2 %3 %4 %5 %6

    set error_value=%errorlevel%

    call :logger_echo "[send_mail_requester] �I�� - �G���[���x��:" !error_value!
    echo !error_value!

exit /b %error_value%


rem cov_snap, bug_report ���ʃG���[�Ή��T�u���[�`���i�A�h���X�t�@�C�����p�j
:error_proc_address
    rem ����:
    rem %1: �Ăяo���� (��: cov_snap, bug_report, p4)
    rem %2: GITLAB_GROUP / P4_GROUP
    rem %3: CC_STREAM
    rem %4: CC_SNAPSHOT
    rem %5: SENDEREMAILADDRESS
    rem %6: error_value
    rem %7: ���O�t�@�C���܂���ZIP�t�@�C���p�X

    call :logger_echo "[error_proc_address] �J�n - �Ăяo����:" %1 ", �G���[���x��:" %6
    call :logger_echo "[error_proc_address] ����: " %1, %2, %3, %4, %5, %6, %7
    call :logger_crlf

    if "%6" == "0" (
        rem ���폈��
        call :logger_echo "[error_proc_address] ����I���B�G���[���x��:" %6

    ) else (
        rem �ُ폈��
        if "%1" == "bug_report" (
            if "%6" == "1100" (
                call :logger_echo "[error_proc_address] bug_report_2.py ChatGPT query error"

            ) else if "%6" == "1101" (
                call :logger_echo "[error_proc_address] bug_report_2.py FileNotFound"

            ) else (
                call :logger_echo "[error_proc_address] bug_report ���̑��ُ̈�"

            )

        ) else if "%1" == "cov_snap" (
            if "%6" == "700" (
                call :logger_echo "[error_proc_address] cov_snap.py last.json �t�@�C�������݂��܂���"

            ) else if "%6" == "701" (
                call :logger_echo "[error_proc_address] cov_snap.py ZIP�t�@�C�������݂��܂���"

            ) else (
                call :logger_echo "[error_proc_address] cov_snap ���̑��ُ̈�"

            )

        ) else (
            call :logger_echo "[error_proc_address] ���m�̌Ăяo�����ł�"

        )
    )
    call :logger_crlf

    rem ����E�ُ탁�[�����M
    if not "%DEBUG_BAT%" == "ENABLE" (
        rem �{�ԃ��[�����M
        if "%1" == "bug_report" (
            call :send_mail_address send_mail_bug_report_address.vbs %2 %3 %4 %5 %error_value% %7

        ) else if "%1" == "cov_snap" (
            call :send_mail_address send_mail_cov_snap_address.vbs %2 %3 %4 %5 %error_value% %7
            
        ) else (
            rem ���̑��̏ꍇ
            rem TODO: �Ăяo�����̈����s���Ή��v
            call :send_mail_address send_mail_cov_snap_address.vbs %2 %3 %4 %5 %error_value% %7

        )

    ) else (
        rem �f�o�b�O��
        call :logger_echo "[error_proc_address] �f�o�b�O���ɂ����[���𑗐M���܂���"

    )

    call :logger_echo "[error_proc_address] �� ���[���𑗐M�� :error_proc_requester �ɖ߂��Ă��܂���"
    call :logger_crlf

exit /b %6


rem ���ʃ��[�����M�T�u���[�`��
:send_mail_address
    rem ����:
    rem %1: �Ăяo�����X�N���v�g�� (send_mail_bug_report_address.vbs, send_mail_cov_snap_address.vbs)
    rem %2: GITLAB_GROUP / P4_GROUP
    rem %3: CC_STREAM
    rem %4: CC_SNAPSHOT
    rem %5: SENDEREMAILADDRESS
    rem %6: error_value
    rem %7: ���O�t�@�C���܂���ZIP�t�@�C���p�X

    call :logger_echo "[send_mail_address] �J�n - �X�N���v�g��:" %1 ", �G���[���x��:" %6
    call :logger_echo "[send_mail_address] ����: " %1, %2, %3, %4, %5, %6, %7
    call :logger_crlf

    rem �F�胆�[�U�[�`�F�b�N
    call :logger_echo "�� �F�胆�[�U�[�`�F�b�N���s"
    call :logger_echo "�� call :cov_check_auth_user"
    call :cov_check_auth_user %2
    set error_value=!errorlevel!

    call :logger_echo "[send_mail_address] �F�胆�[�U�[�`�F�b�N���� - �G���[���x��:" !error_value!
    if not "!error_value!" == "0" (
        call :logger_echo "[send_mail_address] �F�胆�[�U�[�`�F�b�N�ŃG���[����"

        rem exit /b !error_value!
    )

    rem ���[�����M�X�N���v�g�̌Ăяo��
    call :logger_echo "[send_mail_address] �X�N���v�g�Ăяo��: cscript %SCRIPT_DIR%\%1 %2 %3 %4 %5 !error_value! %7"
    cscript %SCRIPT_DIR%\%1 %2 %3 %4 %5 !error_value! %7
    set error_value=%errorlevel%
    call :logger_echo "[send_mail_address] �X�N���v�g���� - �G���[���x��:" %error_value%

    exit /b %error_value%
