"""注意および説明
1. 環境変数 COVAUTHUSER と COVAUTHKEY を読み取って認証を行うので、これら環境変数の設定が必要です。
2. check_auth_user 関数でメールアドレスを入力し、認定ユーザーであるかを判定します。
   判定は REST API を利用して行われます。
3. 認定ユーザーファイルに認定ユーザーのメールアドレスのみが記録されます。元のメールアドレスファイルは変更されません。
"""
import os
import sys
import csv
import requests
from logging import getLogger, Formatter, StreamHandler, FileHandler, DEBUG

# proxy設定（環境変数から読み込み、デフォルト値あり）
proxies_dic = {
    "http": os.environ.get("HTTP_PROXY", "http://proxy.example.com:8080/"),
    "https": os.environ.get("HTTPS_PROXY", "http://proxy.example.com:8080/"),
}

# 認定ユーザー判定の有効無効
AUTH_USER_ENABLE = True  # 判定を行う True, 判定を行わない False

# REST API ベース URL
API_BASE_URL = "https://sast.kbit-repo.net/api/v2"

# 初期設定
def init_logger():
    """
    機能: ログ設定を行う
    入力: なし
    出力: ロガーオブジェクト
    """
    logger = getLogger("cov_check_auth_user_rest")
    logger.setLevel(DEBUG)

    # ログフォーマット
    handler_format = Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # コンソール出力（UTF-8エンコーディング設定）
    if sys.platform == "win32":
        # Windows: UTF-8でstdoutに出力
        import io
        stream_handler = StreamHandler(
            stream=io.TextIOWrapper(
                sys.stdout.buffer,
                encoding='utf-8',
                errors='replace',
                line_buffering=True
            )
        )
    else:
        stream_handler = StreamHandler()
    stream_handler.setLevel(DEBUG)
    stream_handler.setFormatter(handler_format)
    logger.addHandler(stream_handler)

    # ファイル出力（UTF-8エンコーディング設定）
    log_dir = "./log/"
    if not os.path.exists(log_dir):
        os.mkdir(log_dir)
    file_handler = FileHandler(
        f"{log_dir}cov_check_auth_user_rest.log",
        encoding='utf-8'
    )
    file_handler.setLevel(DEBUG)
    file_handler.setFormatter(handler_format)
    logger.addHandler(file_handler)

    return logger


# 環境変数から秘密情報を取得する
def get_env_variable(key, logger=None):
    """
    機能: 秘密情報を環境変数から取得する
    入力（引数）: key, logger (optional)
    出力（戻り値）: key の値
    """
    try:
        return os.environ[key]
    except KeyError as e:
        if logger:
            logger.error("%s: Environment variable '%s' not found.", e, key)
        print(f"error_level: 708 - Environment variable '{key}' not found")
        sys.exit(708)


# 認定ユーザーチェック
def check_auth_user(email):
    """
    機能: メールアドレスが認定ユーザーか否かをチェックする
    入力（引数）: メールアドレス
    出力（戻り値）: 認定ユーザーの場合 0, 非認定ユーザーの場合 919, user_id
    """
    # ロガー初期化
    logger = init_logger()
    
    if AUTH_USER_ENABLE:
        # REST API を使用して認定ユーザーをチェック
        username = get_env_variable("COVAUTHUSER", logger)
        auth_key = get_env_variable("COVAUTHKEY", logger)
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
        }
        auth = (username, auth_key)

        # API エンドポイント
        api_url = f"{API_BASE_URL}/users"

        try:
            response = requests.get(api_url, headers=headers, auth=auth, proxies=proxies_dic, verify=False, timeout=20)
            response.raise_for_status()
            response_data = response.json()
            
            # レスポンスデータの型をチェック
            if isinstance(response_data, dict):
                # ページネーション対応: usersキーまたはdataキーを確認
                users = response_data.get("users") or response_data.get("data") or response_data.get("items") or []
                if not users:
                    logger.warning("[check_auth_user] レスポンスに users/data/items キーが見つかりません: %s", list(response_data.keys()))
                    # 辞書そのものが単一ユーザーの場合
                    if "email" in response_data:
                        users = [response_data]
                    else:
                        users = []
            elif isinstance(response_data, list):
                users = response_data
            else:
                logger.error("[check_auth_user] 予期しないレスポンス型: %s", type(response_data))
                return 1, None

            # メールアドレスで認定ユーザーを検索
            for user in users:
                if user.get("email") == email:
                    logger.info("[check_auth_user] %s は認定ユーザーです", email)
                    user_id = user.get("username") or user.get("userName") or user.get("user_id") or user.get("id") or user.get("name")
                    logger.info("[check_auth_user] ユーザーID: %s, user keys: %s", user_id, list(user.keys()))
                    return 0, user_id

            logger.info("[check_auth_user] %s は認定ユーザーではありません", email)
            return 919, None

        except requests.exceptions.RequestException as e:
            logger.error("[check_auth_user] REST API エラー: %s", str(e))
            return 1, None

    else:
        # 認定ユーザー判定を行わない
        return 0, None


# 認定ユーザーファイルのパスを生成
def create_auth_file_path(original_path):
    """
    指定されたファイルパスに `_auth` を挿入した認定ユーザーファイルパスを生成する。
    """
    base, ext = os.path.splitext(original_path)
    return f"{base}_auth{ext}"


# メイン処理
def main(filepath):
    """
    機能:
        メール送信者アドレスファイル（project_address.csv）に記述されているユーザーが、
        認定ユーザーの場合、
        認定ユーザーファイル（project_address_auth.csv）にメールアドレスを追加する。
    引数:
        filepath: メール送信者アドレスファイルのパス
    戻り値:
        errorlevel: (自然数とする)
          0: 正常終了
          905: アドレスファイルが存在しない
          919: 非認定ユーザー
    """
    log.info("[main] 開始")

    # 認定ユーザーファイルのパスを生成
    auth_file_path = create_auth_file_path(filepath)
    log.info("[main] 認定ユーザーファイル: %s", auth_file_path)

    # ファイル存在確認
    if not os.path.exists(filepath):
        log.error("[main] アドレス・ファイルが存在しません: %s", filepath)
        return 905  # 異常終了

    try:
        # 認定ユーザーファイルを書き出しモードで開く（常に新規作成）
        with open(auth_file_path, "w", newline="", encoding="shift_jis") as auth_file:
            auth_writer = csv.writer(auth_file)

            # メールアドレスファイルを開く
            with open(filepath, newline="", encoding="shift_jis") as file:
                reader = csv.reader(file)
                for row in reader:
                    email_type = row[0]

                    # 先頭文字が ';' であればその行を無視
                    if email_type.startswith(";"):
                        continue

                    # 認定ユーザーチェック
                    email = row[1]
                    err, user_id = check_auth_user(email)
                    log.info("[main] check_auth_user結果: err=%s, user_id=%s", err, user_id)

                    if user_id is not None:
                        log.info("[main] 認定ユーザー: %s", email)
                        # 認定ユーザーファイルに追加
                        auth_writer.writerow([email_type, email])

        log.info("[main] 正常終了")
        return 0  # 正常終了

    except Exception as e:
        log.error("[main] エラーが発生しました: %s", str(e))
        log.exception("[main] 詳細なトレースバック:")
        return 1  # 異常終了


# ----------------------------------------------------------------------------- #
if __name__ == "__main__":
    # ロガー初期化
    log = init_logger()

    # 引数チェック
    args = sys.argv
    if len(args) != 2:
        log.error("[__main__] 引数の数が不一致です")
        sys.exit(915)

    file_path = args[1]
    log.info("[__main__] メールアドレスファイル: %s", file_path)

    # メイン処理
    error_level = main(file_path)
    sys.exit(error_level)