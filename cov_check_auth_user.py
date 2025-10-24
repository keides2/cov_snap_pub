"""注意および説明
1. 環境変数 COVAUTHUSER と COVAUTHKEY を読み取って認証を行うので、これら環境変数の設定が必要です。
2. check_auth_user 関数でメールアドレスを入力し、認定ユーザーであるかを判定します。
   判定は covautolib_2 モジュールの COVApi クラスの check_user_id メソッドを利用して行われます。
3. 認定ユーザーファイルに認定ユーザーのメールアドレスのみが記録されます。元のメールアドレスファイルは変更されません。
"""
import os
import sys
import csv

# This script requires suds that provides SOAP bindings for python.
# Download suds from https://pypi.org/project/suds/
#   unpack it and then run:
#     python setup.py install
#
#   or unpack the 'suds' folder and place it in the same place as this script
from suds.client import Client
from suds.wsse import Security, UsernameToken
# from suds.sudsobject import asdict

# For basic logging
# import logging
#
# logging.basicConfig()
# Uncomment to debug SOAP XML
# logging.getLogger("suds.client").setLevel(logging.DEBUG)
# logging.getLogger("suds.transport").setLevel(logging.DEBUG)
#
# getFileContents result requires decompress and decoding
# import base64
# import zlib

# このスクリプトは、covautolib ディレクトリにある covautolib_2 パッケージを利用しています。
# そのため PYTHONPATH 環境変数に covautolib ディレクトリの親ディレクトリを追加してください。
#
# 例:
# Windows (コマンドプロンプト)
#   パッケージが C:\Users\username\Docs\GitLab\Security\covautolib にある場合
#   set PYTHONPATH=C:\Users\username\Docs\GitLab\Security
#
# AlmaLinux (ターミナル)
#   パッケージが /home/username/covautolib にある場合
#   export PYTHONPATH=/home/username
#
# Coverity Connect API モジュール集の利用
from covautolib.covautolib_3 import COVApi, LOGGER_2

# proxy
proxies_dic = {
    "http": "http://proxy.example.com:xxxx/",
    "https": "http://proxy.example.com:xxxx/",
}

# 認定ユーザー判定の有効無効
AUTH_USER_ENABLE = True    # 判定を行う True, 判定を行わない False


# 初期設定
def init():
    """
    機能: 初期設定を行う
    入力: なし
    出力: なし
    戻り値: defectServiceClient, configServiceClient
    """
    log.logger.info("[init] 開始")

    # ビューのID: 無条件全表示のコピー
    # view_id = 10551

    # DONE 認証キーを環境変数から読む（事前に、環境変数 COVAUTHUSER と COVAUTHKEY に値を設定しておくこと）
    # ------------connection details,
    # To run these examples adjust these connection parameters
    # to match your instance URL and credentials
    #
    host = "coverity-connect.example.com"
    port = "443"
    ssl = True
    username = get_env_variable("COVAUTHUSER")
    auth_key = get_env_variable("COVAUTHKEY")
    # log.logger.info("[init] username: {}, auth_key: {}".format(username, auth_key))
    log.logger.info("[init] username: %s, auth_key: %s", username, auth_key)

    # ------------configuration, project details,
    # For testing the individual call examples adjust the example project, stream, defect
    # specifics to match your projects, streams, etc...
    #
    # use the getProjects call if don't have one ready
    # projectname='DeveloperStreams'
    #
    # streamnamepattern='plugintest*'
    # use getStreams with streamnamepattern if you don't have one ready
    # streamname='plugintest'
    #  use getStreams with streamnamepattern if you don't have one ready
    # snapshotid=10006
    # for getFileContents...
    # use getStreamDefects  v[0].defectInstances[0].events[0].fileId.contentsMD5 and filePathname
    # filepath='/idirs-7.7.0-misra/gzip-trunk-misra/lib/quotearg.c'
    # filecontentsMD5='cd583eecf0af533e6f93f31bb7390065'
    # use getComponentMaps, getComponent if you don't have one ready
    # componentname1='gzip.lib'
    # componentname2='gzip.Other'
    # a cid which has instances, triage and detectionhistory
    # use one of the getMergedDefect calls if don't have one ready
    # cid=439207

    # インスタンス作成
    # パスワード使用の場合
    # defectServiceClient = DefectServiceClient(host, port, ssl, username, password)
    # configServiceClient = ConfigServiceClient(host, port, ssl, username, password)

    # 認証キー使用の場合
    defectServiceClient = DefectServiceClient(host, port, ssl, username, auth_key)
    configServiceClient = ConfigServiceClient(host, port, ssl, username, auth_key)

    return defectServiceClient, configServiceClient


# 環境変数から秘密情報を取得する
def get_env_variable(key):
    """
    機能: 秘密情報を環境変数から取得する
    入力（引数）: key
    出力（戻り値）: key の値
    使用例: 認証キーを取得
    cov_auth_key = get_env_variable('COVAUTHKEY')
    """
    try:
        return os.environ[key]

    except KeyError as e:
        # print(f"{e}: Environment variable '{key}' not found.")
        # cov_snap.bat に {e} (COVAUTHUSER) と `Environment` を返してしまう
        log.logger.error("%s: Environment variable '%s' not found.", e, key)
        # error_level = 708
        print("error_level: 708")
        sys.exit(708)


# 認定ユーザーチェック
def check_auth_user(email):
    """
    機能: メールアドレスが認定ユーザーか否かをチェックする
    入力（引数）: メールアドレス
    出力（戻り値）: 認定ユーザーの場合 0, 非認定ユーザーの場合 919, user_id
    """
    # 認定ユーザーの有効無効判定
    if AUTH_USER_ENABLE:
        # 利用者が認定ユーザであるか判定する
        # 利用者（の電子メール）が認定ユーザーの場合、ユーザーIDを得る
        # covapi = covautolib_2.COVApi()
        covapi = COVApi()
        user_id = covapi.check_user_id(email)

        if user_id is None:
            # 認定ユーザーではない
            log.logger.info("[check_auth_user] %s: %s は認定ユーザーではありません", email, user_id)
            errorlevel = 919
            return errorlevel, None

        else:
            # 利用者が認定ユーザである
            log.logger.info("[check_auth_user] %s: %s  は認定ユーザーです", email, user_id)
            errorlevel = 0
            return errorlevel, user_id

    else:
        # 利用者が認定ユーザであるか判定しない
        errorlevel = 0
        return errorlevel, None


# 仕様変更: 元のメールアドレスファイルはそのままに、認定ユーザーファイルを生成する
def create_auth_file_path(original_path):
    """
    指定されたファイルパスに `_auth` を挿入した認定ユーザーファイルパスを生成する。
    """
    base, ext = os.path.splitext(original_path)
    return f"{base}_auth{ext}"


# -----------------------------------------------------------------------------
class WebServiceClient:
    def __init__(self, webservice_type, host, port, ssl, username, auth_key):
        url = ""
        if ssl:
            url = "https://" + host + ":" + port
        else:
            url = "http://" + host + ":" + port
        if webservice_type == "configuration":
            self.wsdlFile = url + "/ws/v9/configurationservice?wsdl"
        elif webservice_type == "defect":
            self.wsdlFile = url + "/ws/v9/defectservice?wsdl"
        else:
            raise "unknown web service type: " + webservice_type

        self.client = Client(self.wsdlFile, proxy=proxies_dic)
        self.security = Security()
        # 引数 auth_key が password の場合
        # self.token = UsernameToken(username, password)
        # self.security.tokens.append(self.token)
        self.auth_key = UsernameToken(username, auth_key)
        self.security.tokens.append(self.auth_key)
        self.client.set_options(wsse=self.security, proxy=proxies_dic)

    def getwsdl(self):
        print(self.client)


# -----------------------------------------------------------------------------
class DefectServiceClient(WebServiceClient):
    def __init__(self, host, port, ssl, username, password):
        WebServiceClient.__init__(self, "defect", host, port, ssl, username, password)


# -----------------------------------------------------------------------------
class ConfigServiceClient(WebServiceClient):
    def __init__(self, host, port, ssl, username, password):
        WebServiceClient.__init__(
            self, "configuration", host, port, ssl, username, password
        )

    def getProjects(self):
        return self.client.service.getProjects()


# 開始
def main(filepath):
    """
    機能:
        メール送信者アドレスファイル（project_address.csv）に記述されているユーザーが、
        認定ユーザーの場合、
        認定ユーザーファイル（project_address_auth.csv）にメールアドレスを追加する。
        （仕様変更により、非認定ユーザーの場合はコメントアウトして元ファイルに上書き保存することをやめる）
    引数:
        filepath: メール送信者アドレスファイルのパス
    戻り値:
        errorlevel: (自然数とする)
          0: 正常終了
          905: アドレスファイルが存在しない
          914: KeyError(辞書)
          915: 引数の数が不一致
          918: 環境変数エラー
          919: 非認定ユーザー
    """
    log.logger.info("[main] 開始")

    # 初期設定（オブジェクト生成）
    defectserviceclient, configserviceclient = init()

    # アドレスリストの初期化
    # updated_emails = []

    # 認定ユーザーファイルのパスを生成
    auth_file_path = create_auth_file_path(filepath)
    log.logger.info("[main] 認定ユーザーファイル: %s", auth_file_path)

    # ファイル存在確認
    if not os.path.exists(filepath):
        log.logger.error("[main] アドレス・ファイルが存在しません: %s", filepath)
        return 905  # 異常終了

    try:
        # 認定ユーザーファイルを書き出しモードで開く（常に新規作成）
        with open(auth_file_path, 'w', newline='', encoding='shift_jis') as auth_file:
            auth_writer = csv.writer(auth_file)

            # メールアドレスファイルを開く
            with open(filepath, newline='', encoding='shift_jis') as file:
                reader = csv.reader(file)
                for row in reader:
                    # row[0] は to, Cc, Bcc, row[1] がメールアドレス
                    email_type = row[0]
                    
                    # 先頭文字が';'であればその行を無視
                    if email_type.startswith(';'):
                        # email_type が既に';'で始まっている場合は、何も変更しない
                        # updated_emails.append([email_type])
                        continue
                    
                    # 認定ユーザーチェック
                    email = row[1]
                    err, user_id = check_auth_user(email)

                    # if err != 0:
                    #    認定ユーザーでない場合はコメントアウト
                    #    email_type = ';' + email_type
    
                    # リストに追加
                    # updated_emails.append([email_type, email])

                    if user_id is not None:
                        log.logger.info("[main] 認定ユーザー: %s", email)
                        # 認定ユーザーファイルに追加
                        auth_writer.writerow([email_type, email])

        # 変更リストをファイルに書き戻す
        # with open(filepath, 'w', newline='', encoding='shift_jis') as file:
        #     writer = csv.writer(file)
        #     writer.writerows(updated_emails)

        log.logger.info("[main] 正常終了")
        return 0  # 正常終了

    except Exception as e:
        log.logger.error("[main] エラーが発生しました: %s", str(e))
        return 1  # 異常終了


# -----------------------------------------------------------------------------
if __name__ == "__main__":
    #
    # 引数（送信者メールアドレスファイルのパス）チェック
    args = sys.argv
    len_args = len(args)
    print(f"[__main__] 引数チェック前 len_args: {len_args}")

    if len_args == 2:
        # 引数の数が 1 （判定値は 2）の場合は、送信者メールアドレスファイルのチェックを行う
        file_path = args[1]

    else:
        # 引数の数が 2 以外の場合は、何もしない
        print("\n")
        print("  Arguments mismatch:")
        print(
            "     Usage [Windows @build server]: \n"
            + "       $ python / py "
            + args[0]
            + " path/to/group_address.csv"
            + "\nOR\n"
            "     Usage [Windows @local PC]: \n"
            + "       $ python3 "
            + args[0]
            + " path/to/group_address.csv"
            + "\n"
        )

        # 異常終了：引数の数が不一致
        # error_level = 915
        print("[__main__] 引数の数が不一致なので退出します")
        print("[__main__] 引数の数が不一致 error_level: 915")
        sys.exit(915)

    # 引数表示
    print(
        f"file path: {file_path}"
    )

    # 共通
    # os.sep は、Windows: \\, Linux: /
    sep = os.sep
    # base_dir
    base_dir = "." + sep

    # log ディレクトリが存在しないなら作成
    log_dir = base_dir + "log" + sep
    if not os.path.isdir(log_dir):
        os.mkdir(log_dir)

    # logger
    # DONE: LOGGER クラスのインスタンス作成
    log = LOGGER_2("cov_check_auth_user_py", str(999))
    log.logger.info("[__main__] ログ開始します")

    # ログ出力テスト
    log.logger.debug("ログ出力テスト")
    log.logger.debug("Debug")
    log.logger.error("Error")
    log.logger.info("Info")
    log.logger.warning("Warning\n")
    log.logger.info("[main] 引数チェック通過")
    log.logger.info("[main] cov_check_auth_user_py: %s", file_path)

    # main() 開始
    log.logger.info("[__main__] main() を呼び出します")
    error_level = main(file_path)

    # main() 終了
    log.logger.info(
        "[__main__] main() から戻ってきました。error_level: %d", error_level
    )

    # 異常判定
    if error_level != 0:
        # 異常終了
        log.logger.error(
            "[__main__] main() を異常終了しました。戻り値: %d", error_level
        )
    else:
        # 正常終了
        log.logger.info(
            "[__main__] main() を正常終了しました。戻り値: %d", error_level
        )

    # sys.exit(error_level) で呼び出し元に error_level が渡らないので、
    # error_level をバッチファイルに渡して終了
    print(error_level)
    sys.exit(error_level)
