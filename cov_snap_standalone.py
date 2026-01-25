#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
cov_snap_standalone.py - Coverity スナップショット取得ツール（単独実行版）

使用方法:
  # モード1: ローカル保存（認証あり）
  python cov_snap_standalone.py coverity_stream_name 15023 user@example.com
  
  # モード2: 認定ユーザー配信
  python cov_snap_standalone.py coverity_stream_name 15023

特徴:
  - バッチファイル連携の複雑性を排除
  - argparseによるシンプルな引数処理
  - エラーメッセージが明確
  - 進捗表示対応
"""

import os
import sys
import argparse
import logging
import csv
import json
import zipfile
import subprocess
import traceback
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email.mime.text import MIMEText
from email import encoders

# カラー出力サポート
try:
    from colorama import init as colorama_init, Fore, Style
    colorama_init(autoreset=True)
    HAS_COLORAMA = True
except ImportError:
    print("⚠️ 警告: colorama が見つかりません（pip install colorama でインストール推奨）",
          file=sys.stderr)
    HAS_COLORAMA = False
    
    # colorama なしでも動作するようにダミークラス
    class Fore:
        GREEN = RED = YELLOW = CYAN = MAGENTA = BLUE = ""
    
    class Style:
        RESET_ALL = BRIGHT = ""

# REST APIクライアント（専用モジュール）
try:
    from coverity_rest_lib import CoverityRestClient
    from cov_check_auth_user_rest import check_auth_user
    import requests
    LEGACY_AVAILABLE = True
except ImportError:
    print("⚠️ 警告: coverity_rest_lib.py または cov_check_auth_user_rest.py が見つかりません", file=sys.stderr)
    LEGACY_AVAILABLE = False


def setup_logging(verbose=False):
    """ログ設定"""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    return logging.getLogger(__name__)


def validate_environment():
    """環境変数チェック"""
    required_vars = ['COVAUTHUSER', 'COVURL']
    
    # COVAUTHKEY または COVAUTHKEY_FILE のどちらか一方が必要
    if not os.getenv('COVAUTHKEY') and not os.getenv('COVAUTHKEY_FILE'):
        color = Fore.RED if HAS_COLORAMA else ""
        reset = Style.RESET_ALL if HAS_COLORAMA else ""
        print(f"{color}❌ エラー: COVAUTHKEY または COVAUTHKEY_FILE が設定されていません{reset}",
              file=sys.stderr)
        print("\n設定方法（PowerShell）:", file=sys.stderr)
        print("  $env:COVAUTHKEY='your_auth_key'", file=sys.stderr)
        print("  または", file=sys.stderr)
        print("  $env:COVAUTHKEY_FILE='C:\\Users\\HP\\.coverity\\auth-key'",
              file=sys.stderr)
        sys.exit(708)
    
    # COVAUTHUSER と COVURL のチェック
    missing = [var for var in required_vars if not os.getenv(var)]
    
    if missing:
        color = Fore.RED if HAS_COLORAMA else ""
        reset = Style.RESET_ALL if HAS_COLORAMA else ""
        print(f"{color}❌ エラー: 環境変数が設定されていません: {', '.join(missing)}{reset}",
              file=sys.stderr)
        print("\n設定方法（PowerShell）:", file=sys.stderr)
        print("  $env:COVAUTHUSER='your_username'", file=sys.stderr)
        print("  $env:COVURL='https://coverity.example.com:8080'",
              file=sys.stderr)
        sys.exit(708)


def show_progress(message: str, step: int, total: int):
    """進捗表示

    Args:
        message (str): 表示メッセージ
        step (int): 現在のステップ
        total (int): 総ステップ数
    """
    percentage = int((step / total) * 100)
    bar_length = 40
    filled = int((step / total) * bar_length)
    bar = "█" * filled + "░" * (bar_length - filled)
    
    color = Fore.CYAN if HAS_COLORAMA else ""
    reset = Style.RESET_ALL if HAS_COLORAMA else ""
    
    print(f"{color}[{step}/{total}] {bar} {percentage}% | {message}{reset}")


def extract_certified_users_by_stream(stream_name, address_dir):
    """
    機能: ストリーム名からアドレスファイルを読み込み、認定ユーザーを抽出
    
    【新方式】
        - グループ名ではなく、ストリーム名でアドレスファイルを検索
        - generate_stream_address_files.py で事前生成された
          {stream_name}_address.csv を使用
    
    処理フロー:
        1. <stream_name>_address.csv を読み込み
        2. cov_check_auth_user_rest.py を実行して認定ユーザーをフィルタ
        3. <stream_name>_address_auth.csv から認定ユーザーリストを取得
    
    入力（引数）:
        stream_name: ストリーム名（例: "my_project_stream"）
        address_dir: アドレスファイルディレクトリのパス
    
    出力（戻り値）:
        dict: 認定ユーザーの辞書 {'To': [...], 'Cc': [...], 'Bcc': [...]}
        error_level: エラーレベル（"0": 正常、その他: 異常）
    """
    logger = logging.getLogger(__name__)
    logger.info(
        f"[extract_certified_users_by_stream] 開始 - ストリーム名: {stream_name}"
    )
    
    # ストリーム名ベースのアドレスファイル
    address_file = os.path.join(address_dir, f"{stream_name}_address.csv")
    auth_file = os.path.join(address_dir, f"{stream_name}_address_auth.csv")
    
    # アドレスファイル存在確認
    if not os.path.exists(address_file):
        logger.error(
            f"[extract_certified_users_by_stream] "
            f"アドレスファイルが見つかりません: {address_file}"
        )
        logger.error(
            "ヒント: generate_stream_address_files.py を実行して "
            "ストリーム名アドレスファイルを生成してください"
        )
        return {}, "905"
    
    # cov_check_auth_user_rest.py を実行
    script_dir = os.path.dirname(os.path.abspath(__file__))
    check_auth_script = os.path.join(script_dir, "cov_check_auth_user_rest.py")
    
    if not os.path.exists(check_auth_script):
        logger.error(
            f"[extract_certified_users_by_stream] "
            f"認証チェックスクリプトが見つかりません: {check_auth_script}"
        )
        return {}, "908"
    
    # Python実行コマンド
    try:
        logger.info(
            f"[extract_certified_users_by_stream] 認証チェック実行: {check_auth_script}"
        )
        result = subprocess.run(
            [sys.executable, check_auth_script, address_file],
            capture_output=True,
            text=True,
            encoding='utf-8',
            errors='replace',
            timeout=60
        )
        
        if result.returncode != 0:
            logger.error(
                f"[extract_certified_users_by_stream] 認証チェック失敗: "
                f"returncode={result.returncode}"
            )
            logger.error(f"[extract_certified_users_by_stream] STDOUT: {result.stdout}")
            logger.error(f"[extract_certified_users_by_stream] STDERR: {result.stderr}")
            return {}, str(result.returncode)
        
        logger.info(f"[extract_certified_users_by_stream] 認証チェック完了")
        
    except subprocess.TimeoutExpired:
        logger.error(
            "[extract_certified_users_by_stream] 認証チェックがタイムアウトしました"
        )
        return {}, "906"
    except Exception as e:
        logger.error(
            f"[extract_certified_users_by_stream] 認証チェック実行エラー: {str(e)}"
        )
        return {}, "907"
    
    # 認定ユーザーファイル読み込み
    if not os.path.exists(auth_file):
        logger.warning(
            f"[extract_certified_users_by_stream] "
            f"認定ユーザーファイルが生成されませんでした: {auth_file}"
        )
        return {}, "0"  # 正常終了だが認定ユーザーなし
    
    # To/Cc/Bcc 辞書を作成
    certified_users = {'To': [], 'Cc': [], 'Bcc': []}
    try:
        with open(auth_file, 'r', encoding='shift_jis') as f:
            reader = csv.reader(f)
            for row in reader:
                if len(row) >= 2 and not row[0].startswith(';'):
                    addr_type = row[0].strip()
                    email = row[1].strip()
                    
                    if email:
                        if addr_type == 'To':
                            certified_users['To'].append(email)
                        elif addr_type == 'Cc':
                            certified_users['Cc'].append(email)
                        elif addr_type == 'Bcc':
                            certified_users['Bcc'].append(email)
        
        total_count = (
            len(certified_users['To']) + 
            len(certified_users['Cc']) + 
            len(certified_users['Bcc'])
        )
        logger.info(
            f"[extract_certified_users_by_stream] 認定ユーザー数: "
            f"To={len(certified_users['To'])}, "
            f"Cc={len(certified_users['Cc'])}, "
            f"Bcc={len(certified_users['Bcc'])}, "
            f"合計={total_count}"
        )
        return certified_users, "0"
        
    except Exception as e:
        logger.error(
            f"[extract_certified_users_by_stream] ファイル読み込みエラー: {str(e)}"
        )
        return {'To': [], 'Cc': [], 'Bcc': []}, "909"


def send_mail_with_attachment(
        to_addresses_dict, subject, body, attachments, 
        from_address="Coverity <coverity@example.com>"
    ):
    """
    機能: 添付ファイル付きメールを送信（To/Cc/Bcc対応、1通のメールで送信）
    
    入力（引数）:
        to_addresses_dict: 宛先辞書 {'To': [...], 'Cc': [...], 'Bcc': [...]}
        subject: 件名
        body: 本文
        attachments: 添付ファイルパスのリスト
        from_address: 送信元メールアドレス
    
    出力（戻り値）:
        int: 成功した送信数（全受信者数 or 0）
    """
    logger = logging.getLogger(__name__)
    smtp_server = "smtp.example.com"
    smtp_port = 25
    
    # To/Cc/Bccリストを取得
    to_addresses = to_addresses_dict.get('To', [])
    cc_addresses = to_addresses_dict.get('Cc', [])
    bcc_addresses = to_addresses_dict.get('Bcc', [])
    
    # 全受信者のリスト（SMTP送信に使用）
    all_recipients = to_addresses + cc_addresses + bcc_addresses
    
    if not all_recipients:
        logger.warning(
            "[send_mail_with_attachment] 送信先アドレスがありません"
        )
        return 0
    
    total_count = len(to_addresses) + len(cc_addresses) + len(bcc_addresses)
    logger.info(
        f"[send_mail_with_attachment] メール送信開始 - "
        f"To: {len(to_addresses)}, Cc: {len(cc_addresses)}, "
        f"Bcc: {len(bcc_addresses)}, 合計: {total_count}名"
    )
    
    try:
        # メッセージ作成（1通のメール）
        msg = MIMEMultipart()
        msg['From'] = from_address
        msg['To'] = ", ".join(to_addresses) if to_addresses else ""
        msg['Cc'] = ", ".join(cc_addresses) if cc_addresses else ""
        # Bccはヘッダーに含めない（Bccの仕様）
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain', 'utf-8'))
        
        # 添付ファイル追加
        for filepath in attachments:
            if os.path.exists(filepath):
                with open(filepath, 'rb') as f:
                    part = MIMEBase('application', 'octet-stream')
                    part.set_payload(f.read())
                    encoders.encode_base64(part)
                    part.add_header(
                        'Content-Disposition',
                        f'attachment; filename={os.path.basename(filepath)}'
                    )
                    msg.attach(part)
            else:
                logger.warning(
                    f"[send_mail_with_attachment] "
                    f"添付ファイルが見つかりません: {filepath}"
                )
        
        # SMTP送信（1回のみ、全受信者に送信）
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.sendmail(from_address, all_recipients, msg.as_string())
            logger.info(
                f"[send_mail_with_attachment] メール送信成功 - "
                f"To: {', '.join(to_addresses)}, "
                f"Cc: {', '.join(cc_addresses)}, "
                f"Bcc: {len(bcc_addresses)}名"
            )
            return len(all_recipients)
            
    except Exception as e:
        logger.error(
            f"[send_mail_with_attachment] メール送信失敗: {str(e)}"
        )
        return 0


def check_snapshot_exists(rest_client, project_key, stream_name, snapshot_id, stream_data=None):
    """
    機能: スナップショットIDが存在するか確認
    入力: rest_client, project_key, stream_name, snapshot_id, stream_data (optional)
    出力: -
    戻り値: True (存在する) / False (存在しない)
    """
    logger = logging.getLogger(__name__)
    try:
        logger.info(f"[check_snapshot_exists] ID {snapshot_id} の存在確認")
        
        # 1. stream_data.snapshots を最初にチェック（高速）
        snapshots = None
        if stream_data and 'snapshots' in stream_data:
            snapshots = stream_data.get('snapshots', [])
            logger.info(f"[check_snapshot_exists] stream_dataから{len(snapshots)}件取得")
        else:
            # 2. APIでスナップショットリストを取得
            try:
                logger.info("[check_snapshot_exists] API呼び出し中...")
                response = rest_client.get_snapshots_for_stream(stream_name)
                snapshots = response.get('snapshotsForStream', [])
                logger.info(f"[check_snapshot_exists] APIから{len(snapshots)}件取得")
            except requests.exceptions.HTTPError as http_err:
                if '404' in str(http_err):
                    logger.warning(f"[check_snapshot_exists] 404エラー: 存在しません")
                    return False
                logger.warning(f"[check_snapshot_exists] HTTPエラー: {http_err}")
                logger.warning("[check_snapshot_exists] フェイルセーフでTrueを返します")
                return True
            except Exception as api_err:
                logger.warning(f"[check_snapshot_exists] APIエラー: {api_err}")
                logger.warning("[check_snapshot_exists] フェイルセーフでTrueを返します")
                return True
        
        # 3. スナップショットID一致確認
        if not snapshots:
            logger.warning("[check_snapshot_exists] リストが空、フェイルセーフでTrueを返します")
            return True
        
        snapshot_id_int = int(snapshot_id)
        for snapshot in snapshots:
            sid = snapshot.get('id') if isinstance(snapshot, dict) else snapshot
            if sid == snapshot_id_int:
                logger.info(f"[check_snapshot_exists] ID {snapshot_id} 見つかりました")
                return True
        
        logger.warning(f"[check_snapshot_exists] ID {snapshot_id} は存在しません")
        return False
        
    except Exception as e:
        logger.error(f"[check_snapshot_exists] 予期せぬエラー: {e}")
        logger.error(f"トレースバック: {traceback.format_exc()}")
        return True  # フェイルセーフ


def get_all_cids_in_a_snapshot(
    rest_client, projectname, project_key, stream_name, 
    snapshot_id, filepath, stream_data=None
    ):
    """
    機能: スナップショット内のCIDリストを作成する (REST API版)
    """
    logger = logging.getLogger(__name__)
    logger.info("[get_all_cids_in_a_snapshot] 開始 (REST API)")

    # REST API でスナップショットの指摘を取得
    try:
        response = rest_client.search_issues_by_snapshot(project_key, stream_name, snapshot_id)
    except requests.exceptions.HTTPError as e:
        logger.error(f"[get_all_cids_in_a_snapshot] REST API エラー: {e}")
        cids_list = ["706"]
        return cids_list, None
    
    # レスポンスから指摘一覧を取得
    rows = response.get('rows', [])
    total_count = response.get('totalRows', 0)
    
    logger.info(f"[get_all_cids_in_a_snapshot] 全 CID: {total_count}件")
    
    if total_count == 0:
        if not check_snapshot_exists(
            rest_client, project_key, stream_name, snapshot_id, stream_data
        ):
            logger.error(
                f"[get_all_cids_in_a_snapshot] "
                f"スナップショットIDが存在しません: {snapshot_id}"
            )
            cids_list = ["703"]
            return cids_list, response
        else:
            logger.info(
                "[get_all_cids_in_a_snapshot] "
                "スナップショットは存在しますが指摘件数がゼロです"
            )
            cids_list = ["706"]
            return cids_list, response
    
    # CID リスト作成
    cids_list = []
    for row in rows:
        for item in row:
            if item.get('key') == 'cid':
                cid = item.get('value')
                if cid:
                    cids_list.append(int(cid))
                break
    
    logger.info(f"[get_all_cids_in_a_snapshot] CID リスト作成完了: {len(cids_list)}件")
    
    # ファイル保存
    filename = filepath + "cids_of_snapshot_" + str(snapshot_id) + "_list.json"
    with open(filename, "w", encoding="utf-8", errors="replace") as f:
        json.dump(cids_list, f, ensure_ascii=False, indent=4)
    
    return cids_list, response


def process_snapshot_direct(
    rest_client,
    filepath,
    stream_name,
    snapshot_id
    ):
    """
    機能: 指定されたストリーム・スナップショットIDから
         直接 REST API でデータを取得し、CSVレポートを生成する
    
    引数:
        rest_client: CoverityRestClient インスタンス
        filepath: 出力先ベースパス
        stream_name: ストリーム名
        snapshot_id: スナップショットID
    
    戻り値:
        error_level: エラーレベル ("0" = 成功)
        zip_file_path: 生成されたZIPファイルのパス
    """
    logger = logging.getLogger(__name__)
    sep = os.sep
    
    logger.info(
        f"[process_snapshot_direct] 開始: ストリーム='{stream_name}', "
        f"スナップショット={snapshot_id}"
    )
    
    error_level = "0"
    ret_zip_file_name_path = ""
    
    # ストリーム情報を取得してproject_keyを特定
    try:
        logger.info(
            f"[process_snapshot_direct] REST API でストリーム情報を取得中..."
        )
        stream_data = rest_client.get_stream_by_name(stream_name)
        
        if not stream_data:
            logger.error(
                f"[process_snapshot_direct] ストリーム '{stream_name}' が見つかりません"
            )
            error_level = "704"
            ret_zip_file_name_path = "StreamNotFoundInAPI"
            return error_level, ret_zip_file_name_path
        
        project_key = stream_data.get('primaryProjectName')
        if not project_key:
            logger.error(
                f"[process_snapshot_direct] ストリーム '{stream_name}' の "
                f"primaryProjectName を取得できません"
            )
            error_level = "705"
            ret_zip_file_name_path = "ProjectKeyNotFound"
            return error_level, ret_zip_file_name_path
        
        logger.info(
            f"[process_snapshot_direct] project_key='{project_key}' を取得"
        )
        
    except Exception as err:
        logger.error(
            f"[process_snapshot_direct] ストリーム情報取得エラー: {err}"
        )
        error_level = "710"
        ret_zip_file_name_path = f"StreamAPIError: {err}"
        return error_level, ret_zip_file_name_path
    
    # 出力ディレクトリを作成
    csv_zip_dir = (
        filepath + project_key + sep + stream_name + sep + "csv_zip" + sep
    )
    os.makedirs(csv_zip_dir, exist_ok=True)
    logger.info(
        f"[process_snapshot_direct] 出力ディレクトリ: {csv_zip_dir}"
    )
    
    # 既存のZIPファイルをチェック
    zipfilepath = csv_zip_dir + "snapshot_id_" + str(snapshot_id) + ".zip"
    if os.path.isfile(zipfilepath):
        logger.info(
            f"[process_snapshot_direct] 既存のZIPファイルを発見: {zipfilepath}"
        )
        return error_level, zipfilepath
    
    # 指摘一覧を取得
    logger.info(
        f"[process_snapshot_direct] スナップショット {snapshot_id} の指摘一覧を取得中..."
    )
    
    try:
        stream_dir = filepath + project_key + sep + stream_name + sep
        os.makedirs(stream_dir, exist_ok=True)
        
        cids_list, rest_response = get_all_cids_in_a_snapshot(
            rest_client,
            project_key,
            project_key,
            stream_name,
            snapshot_id,
            stream_dir,
            stream_data
        )
        
        # スナップショットIDが存在しない
        if cids_list[0] == "703":
            error_level = "703"
            ret_zip_file_name_path = "snapshot_id_not_found"
            logger.error(
                f"[process_snapshot_direct] "
                f"スナップショットID {snapshot_id} が存在しません"
            )
            return error_level, ret_zip_file_name_path
        
        # 指摘がゼロ
        if cids_list[0] == "706":
            error_level = "706"
            ret_zip_file_name_path = "totalNumberOfCids_0"
            return error_level, ret_zip_file_name_path
        
        # CSV作成
        rows = rest_response.get('rows', [])
        csv_file_path = csv_zip_dir + "snapshot_id_" + str(snapshot_id) + ".csv"
        
        logger.info(
            f"[process_snapshot_direct] CSVファイル作成: {csv_file_path}"
        )
        
        # CSV作成ロジック
        with open(csv_file_path, "w", newline="", encoding="cp932", errors='replace') as csvfile:
            writer = csv.writer(csvfile)
            
            columns_metadata = rest_response.get('columns', [])
            
            # 英語ラベルから日本語への変換マップ
            label_translation = {
                'CID': 'CID',
                'File': 'ファイル名',
                'Function': '関数名',
                'Line': '行番号',
                'Impact': '影響度',
                'Kind': '問題の種類',
                'Type': '型',
                'Checker': 'チェッカー名',
                'cid': 'CID',
                'mergeKey': 'マージキー',
                'displayFile': 'ファイル名',
                'fileLanguage': '言語',
                'displayFunction': '関数名',
                'lineNumber': '行番号',
                'displayImpact': '影響度',
                'displayIssueKind': '問題の種類',
                'displayType': '型',
                'displayCategory': 'カテゴリ',
                'cwe': 'CWE',
                'occurrenceCount': '出現回数',
                'checker': 'チェッカー名',
                'status': 'ステータス',
                'firstDetected': '初回の検出日',
                'firstSnapshotId': '初回のスナップショットID',
                'firstSnapshotDate': '初回のスナップショット日',
                'firstSnapshotStream': '初回のストリーム',
                'lastDetectedId': '直近の検出ID',
                'lastDetected': '直近の検出日',
                'lastDetectedStream': '直近のストリーム',
                'classification': '分類',
                'severity': '重大度',
                'action': 'アクション',
                'owner': '担当者'
            }
            
            # ヘッダー行を作成
            header = []
            if columns_metadata and isinstance(columns_metadata, list) and len(columns_metadata) > 0:
                if isinstance(columns_metadata[0], dict):
                    for col in columns_metadata:
                        label = col.get('label', col.get('key', ''))
                        japanese_label = label_translation.get(label, label)
                        header.append(japanese_label)
                else:
                    header = [label_translation.get(lbl, lbl) for lbl in columns_metadata]
            else:
                if rows and len(rows) > 0:
                    header = [f"Column{i+1}" for i in range(len(rows[0]))]
            
            writer.writerow(header)
            
            # データ行を作成
            for row in rows:
                csv_row = []
                for cell in row:
                    value = cell.get('value', '') if isinstance(cell, dict) else cell
                    csv_row.append(value)
                
                writer.writerow(csv_row)
            
            logger.info(
                f"[process_snapshot_direct] "
                f"CSV作成完了: {len(rows)} 行 x {len(header)} カラム"
            )
        
        # ZIP作成
        try:
            with zipfile.ZipFile(zipfilepath, "w", zipfile.ZIP_DEFLATED) as new_zip:
                new_zip.write(
                    csv_file_path,
                    arcname=os.path.basename(csv_file_path)
                )
            
            logger.info(
                f"[process_snapshot_direct] ZIP作成完了: {zipfilepath}"
            )
            
        except Exception as zip_err:
            logger.error(
                f"[process_snapshot_direct] ZIP作成失敗: {zip_err}"
            )
            logger.error(traceback.format_exc())
            error_level = "701"
            ret_zip_file_name_path = f"ZipCreationError: {zip_err}"
            return error_level, ret_zip_file_name_path
        
        return error_level, zipfilepath
        
    except Exception as err:
        logger.error(
            f"[process_snapshot_direct] 指摘一覧取得エラー: {err}"
        )
        logger.error(traceback.format_exc())
        error_level = "707"
        ret_zip_file_name_path = f"IssueAPIError: {err}"
        return error_level, ret_zip_file_name_path


def main():
    """メイン処理"""
    parser = argparse.ArgumentParser(
        description='Coverity Connect スナップショット取得ツール',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
使用例:
  # モード1: ローカル保存（個人実行）
  python %(prog)s coverity_stream_name 15023 user@example.com
  
  # モード2: 認定ユーザー全員に配信
  python %(prog)s coverity_stream_name 15023
  
  # 詳細ログ出力
  python %(prog)s coverity_stream_name 15023 --verbose

エラーコード:
  0   : 成功
  703 : スナップショットIDが存在しない
  706 : 指摘件数がゼロ
  708 : 環境変数エラー
  709 : 認定ユーザーではない
  712 : アドレスファイルが見つからない
  713 : メール送信失敗
        '''
    )
    
    # 必須引数
    parser.add_argument('stream_name',
                       help='Coverity ストリーム名（例: coverity_stream_name）')
    parser.add_argument('snapshot_id',
                       help='スナップショットID（例: 15023）')
    
    # オプション引数
    parser.add_argument('sender_email',
                       nargs='?',
                       default=None,
                       help='送信者メールアドレス（省略時はモード2）')
    
    parser.add_argument('--output-dir',
                       default=None,
                       help='出力ディレクトリ（デフォルト: C:\\cov\\snapshots）')
    
    parser.add_argument('--verbose', '-v',
                       action='store_true',
                       help='詳細ログ出力')
    
    parser.add_argument('--no-auth',
                       action='store_true',
                       help='認証チェックをスキップ（開発用）')
    
    # パース
    args = parser.parse_args()
    
    # ログ設定
    logger = setup_logging(args.verbose)
    
    # 環境変数チェック
    validate_environment()
    
    # バナー表示
    print("=" * 60)
    print("Coverity Connect スナップショット取得ツール")
    print("=" * 60)
    print(f"ストリーム名    : {args.stream_name}")
    print(f"スナップショットID: {args.snapshot_id}")
    
    if args.sender_email:
        print(f"実行モード      : モード1（ローカル保存）")
        print(f"送信者          : {args.sender_email}")
    else:
        print(f"実行モード      : モード2（認定ユーザー配信）")
    
    print("=" * 60)
    print()
    
    # 既存のcov_snap.pyの関数を利用
    if not LEGACY_AVAILABLE:
        print("❌ エラー: 既存モジュールが読み込めません", file=sys.stderr)
        return 1
    
    try:
        # REST APIクライアント初期化
        logger.info("REST APIクライアント初期化中...")
        rest_client = CoverityRestClient()
        
        # 出力ディレクトリ設定
        output_dir = args.output_dir or (
            "C:\\cov\\snapshots\\" if os.name == "nt" else "/cov/snapshots/"
        )
        
        # ディレクトリが存在しない場合は作成
        if not os.path.exists(output_dir):
            logger.info(f"出力ディレクトリを作成します: {output_dir}")
            try:
                os.makedirs(output_dir, exist_ok=True)
                logger.info("✅ ディレクトリ作成完了")
            except PermissionError:
                print(f"❌ エラー: ディレクトリ作成権限がありません: {output_dir}",
                      file=sys.stderr)
                print(f"   代替案: --output-dir オプションでユーザーフォルダを指定してください",
                      file=sys.stderr)
                print(f"   例: --output-dir {os.path.expanduser('~/cov_snapshots')}",
                      file=sys.stderr)
                return 1
            except Exception as e:
                # ディスク満杯、ファイルシステムエラーなど
                print(f"❌ エラー: ディレクトリ作成失敗: {e}", file=sys.stderr)
                return 1
        
        # モード判定
        if args.sender_email:
            # モード1: 認証チェック（REST API）
            if not args.no_auth:
                show_progress("認定ユーザーをREST APIで検証中...", 1, 3)
                logger.info("認定ユーザーチェック中（REST API）...")
                
                # REST APIで認定ユーザー確認
                # check_auth_user は (error_code, user_id) を返す
                error_code, user_id = check_auth_user(args.sender_email)
                
                if error_code != 0:
                    color = Fore.RED if HAS_COLORAMA else ""
                    reset = Style.RESET_ALL if HAS_COLORAMA else ""
                    print(f"{color}❌ エラー: 認定ユーザーではありません{reset}", file=sys.stderr)
                    print(f"   メールアドレス: {args.sender_email}", file=sys.stderr)
                    print(f"   ストリーム: {args.stream_name}", file=sys.stderr)
                    return 919 if error_code == 919 else 709
                
                logger.info(f"✅ 認定ユーザー確認OK (User ID: {user_id})")
        
        # スナップショット取得
        show_progress("スナップショット指摘データを取得中...", 2, 3)
        logger.info("スナップショット取得開始...")
        error_level, zip_file_path = process_snapshot_direct(
            rest_client,
            output_dir,
            args.stream_name,
            args.snapshot_id
        )
        
        # 結果判定
        if error_level != "0":
            color = Fore.RED if HAS_COLORAMA else ""
            reset = Style.RESET_ALL if HAS_COLORAMA else ""
            print(f"\n{color}❌ エラー: {error_level}{reset}", file=sys.stderr)
            error_messages = {
                "703": "スナップショットIDが存在しません",
                "706": "指摘件数がゼロです",
                "710": "ストリーム情報取得エラー"
            }
            if error_level in error_messages:
                print(f"   {error_messages[error_level]}", file=sys.stderr)
            return int(error_level)
        
        # 成功
        show_progress("処理完了", 3, 3)
        color = Fore.GREEN if HAS_COLORAMA else ""
        reset = Style.RESET_ALL if HAS_COLORAMA else ""
        print(f"\n{color}✅ 成功！{reset}")
        print(f"   出力ファイル: {zip_file_path}")
        
        # モード2: メール配信
        if not args.sender_email:
            logger.info("認定ユーザーへのメール配信中...")
            
            # アドレスディレクトリ取得
            address_dir = os.getenv('COVERITY_ADDRESS_DIR')
            
            if not address_dir:
                print("⚠️ 警告: COVERITY_ADDRESS_DIR が未設定のため、メール配信をスキップします",
                      file=sys.stderr)
                return 0
            
            # 認定ユーザー抽出
            certified_users, error = extract_certified_users_by_stream(
                args.stream_name, address_dir
            )
            
            if error != "0":
                print(f"❌ エラー: アドレスファイル読み込み失敗（エラー{error}）",
                      file=sys.stderr)
                return 712
            
            # メール送信
            subject = f"Coverity スナップショット {args.snapshot_id} - {args.stream_name}"
            body = f"""
Coverity Connect スナップショット取得結果

ストリーム: {args.stream_name}
スナップショットID: {args.snapshot_id}
出力ファイル: {os.path.basename(zip_file_path)}

このメールは自動送信されています。
"""
            
            mail_result = send_mail_with_attachment(
                certified_users,
                subject,
                body,
                [zip_file_path]
            )
            
            if mail_result == 0:
                print(f"❌ エラー: メール送信失敗（エラー{mail_result}）",
                      file=sys.stderr)
                return 713
            
            print("   ✅ メール送信完了")
        
        return 0
        
    except KeyboardInterrupt:
        print("\n⚠️ ユーザーによる中断", file=sys.stderr)
        return 130
        
    except Exception as e:
        logger.exception("予期しないエラー:")
        print(f"\n❌ 予期しないエラー: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
