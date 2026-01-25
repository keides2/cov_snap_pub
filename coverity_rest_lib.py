#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
coverity_rest_client.py - Coverity Connect REST APIクライアント

Coverity Connect の REST API v2 にアクセスするためのクライアントクラスを提供します。

主な機能:
    - プロジェクト/ストリーム情報の取得
    - スナップショット情報の取得
    - 指摘（Issue）の検索とページング処理
    - 個別CIDのソースコード情報取得

環境変数:
    - COVURL: Coverity Connect サーバーURL（必須、例: https://coverity.example.com:8080）
    - COVAUTHUSER: 認証ユーザー名（必須）
    - COVAUTHKEY: 認証キー（必須）
    - COVERITY_PROXY: Coverity専用プロキシ（推奨、例: http://proxy.example.com:3128/）
    - HTTPS_PROXY: HTTPS通信用プロキシ（オプション、COVERITY_PROXYがない場合に使用）
    - HTTP_PROXY: HTTP通信用プロキシ（オプション、COVERITY_PROXYとHTTPS_PROXYがない場合に使用）

プロキシ優先順位:
    1. COVERITY_PROXY（最優先、推奨）
    2. HTTPS_PROXY
    3. HTTP_PROXY
    4. 未設定の場合は直接接続

注意:
    - 企業ネットワーク環境では COVERITY_PROXY の設定を強く推奨します
    - タイムアウトエラーが発生する場合は、必ず COVERITY_PROXY を設定してください
"""

import os
import sys
import json
import requests
from requests.auth import HTTPBasicAuth
import logging

# ロガー設定
logger = logging.getLogger(__name__)


def get_env_variable(key):
    """
    環境変数から値を取得する
    
    Args:
        key (str): 環境変数名
    
    Returns:
        str: 環境変数の値
    
    Raises:
        SystemExit: 環境変数が設定されていない場合、エラーコード708で終了
    """
    try:
        return os.environ[key]
    except KeyError as e:
        error_level = "708"
        zip_file_path = "Environment_variable_not_set.zip"
        print(f"{error_level} {zip_file_path}")
        logger.error(f"{e}: Environment variable '{key}' not found.")
        sys.exit(int(error_level))


class CoverityRestClient:
    """
    Coverity Connect REST APIクライアント
    
    Coverity Connect の REST API v2 を使用して、プロジェクト、ストリーム、
    スナップショット、指摘情報を取得します。
    
    Attributes:
        base_url (str): REST API のベースURL
        username (str): 認証ユーザー名
        auth_key (str): 認証キー
        auth (HTTPBasicAuth): Basic認証オブジェクト
        proxies (dict): プロキシ設定
        headers (dict): HTTPリクエストヘッダー
    """
    
    def __init__(self):
        """
        CoverityRestClient を初期化する
        
        環境変数から以下を取得して初期化します:
            - COVURL: Coverity サーバーURL
            - COVAUTHUSER: 認証ユーザー名
            - COVAUTHKEY: 認証キー
            - HTTP_PROXY/HTTPS_PROXY: プロキシ設定（オプション）
        
        Raises:
            ValueError: COVURL が設定されていない場合
        """
        # Coverity サーバーURLを環境変数から取得
        covurl = os.getenv('COVURL')
        if not covurl:
            raise ValueError("環境変数 COVURL が設定されていません")
        
        # URLから /api/v2 を除いたベースURLを構築
        self.base_url = covurl.rstrip('/') + '/api/v2'
        
        # 認証情報を環境変数から取得
        self.username = get_env_variable("COVAUTHUSER")
        self.auth_key = get_env_variable("COVAUTHKEY")
        self.auth = HTTPBasicAuth(self.username, self.auth_key)
        
        # プロキシ設定（環境変数から取得）
        # COVERITY_PROXY を優先、なければ HTTP_PROXY/HTTPS_PROXY を使用
        proxy_url = (
            os.getenv('COVERITY_PROXY') or 
            os.getenv('HTTPS_PROXY') or 
            os.getenv('HTTP_PROXY')
        )
        if proxy_url:
            self.proxies = {
                "http": proxy_url,
                "https": proxy_url,
            }
            logger.info(f"プロキシ使用: {proxy_url}")
        else:
            self.proxies = {}  # プロキシなし
            logger.info("プロキシ未設定（直接接続）")
        
        # ヘッダー
        self.headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Accept-Language": "ja,ja-JP",  # 日本語を優先
        }
    
    def get_projects(self):
        """
        プロジェクト一覧を取得
        
        Returns:
            dict: プロジェクト情報のJSON
        
        Raises:
            requests.exceptions.HTTPError: HTTPリクエストエラー
        """
        url = f"{self.base_url}/projects"
        response = requests.get(
            url,
            auth=self.auth,
            headers=self.headers,
            proxies=self.proxies,
            verify=False,
            timeout=90  # 30秒→90秒に延長（プロジェクト一覧取得）
        )
        response.raise_for_status()
        return response.json()
    
    def get_streams(self):
        """
        ストリーム一覧を取得
        
        Returns:
            dict: ストリーム情報のJSON
        
        Raises:
            requests.exceptions.HTTPError: HTTPリクエストエラー
        """
        url = f"{self.base_url}/streams"
        response = requests.get(
            url,
            auth=self.auth,
            headers=self.headers,
            proxies=self.proxies,
            verify=False,
            timeout=120  # 30秒→120秒に延長（ストリーム一覧は大量データのため）
        )
        response.raise_for_status()
        return response.json()
    
    def get_stream_by_name(self, stream_name):
        """
        指定された名前のストリーム情報を取得
        
        Args:
            stream_name (str): ストリーム名（例: "my_project_stream"）
        
        Returns:
            dict: ストリーム情報、見つからない場合は None
        """
        streams_response = self.get_streams()
        
        # デバッグ: レスポンス構造を確認
        logger.debug(f"[get_stream_by_name] ストリーム検索: '{stream_name}'")
        logger.debug(f"[get_stream_by_name] レスポンスタイプ: {type(streams_response)}")
        
        # streams は配列として返される、または 'streams' キー内にある
        if isinstance(streams_response, list):
            streams = streams_response
        elif isinstance(streams_response, dict) and 'streams' in streams_response:
            streams = streams_response['streams']
        else:
            streams = []
        
        logger.info(f"[get_stream_by_name] 取得したストリーム数: {len(streams)}")
        
        # stream_name に一致するストリームを探す
        for idx, stream in enumerate(streams):
            # デバッグ: 最初の1件の完全な構造を表示
            if idx == 0:
                logger.debug(f"[get_stream_by_name] ストリーム[0]の構造: {stream}")
            
            # ストリーム名を取得（REST APIのレスポンスでは直接 'name' キーにある）
            stream_id_name = stream.get('name')
            
            # デバッグ: 最初の数件を表示
            if idx < 5:
                logger.debug(f"[get_stream_by_name] ストリーム[{idx}]: '{stream_id_name}'")
            
            if stream_id_name == stream_name:
                logger.info(f"[get_stream_by_name] マッチ発見: '{stream_id_name}'")
                return stream
        
        logger.warning(f"[get_stream_by_name] ストリーム '{stream_name}' が見つかりません")
        return None
    
    def get_snapshots_for_stream(self, stream_name, project_name=None):
        """
        指定ストリームのスナップショット一覧を取得
        
        Args:
            stream_name (str): ストリーム名（例: "cov_auto"）
            project_name (str, optional): プロジェクト名（例: "EVACUATION"）
        
        Returns:
            dict: レスポンスJSON
                {
                    "snapshotsForStream": [
                        {"id": 10010},
                        ...
                    ]
                }
        
        Note:
            Swagger UIによると idType パラメータが必要:
            - byName: ストリーム名で指定（name パラメータと併用）
        """
        # プロジェクト名が指定されている場合は "プロジェクト/ストリーム" 形式
        if project_name:
            stream_identifier = f"{project_name}/{stream_name}"
        else:
            stream_identifier = stream_name
        
        # 正しいエンドポイント: /streams/stream/snapshots
        # "stream" は固定文字列（プレースホルダーではない）
        url = f"{self.base_url}/streams/stream/snapshots"
        
        # ストリーム名はクエリパラメータで指定
        params = {
            "idType": "byName",
            "name": stream_identifier
        }
        
        response = requests.get(
            url,
            auth=self.auth,
            headers=self.headers,
            params=params,
            proxies=self.proxies,
            verify=False,
            timeout=90  # 30秒→90秒に延長（スナップショット一覧取得）
        )
        response.raise_for_status()
        return response.json()
    
    def search_issues_by_snapshot(
        self, project_key, stream_name, snapshot_id, page_size=10000
    ):
        """
        指定スナップショットの指摘を検索（ページング処理対応）
        
        Args:
            project_key (str): プロジェクトキー
            stream_name (str): ストリーム名
            snapshot_id (int): スナップショットID
            page_size (int, optional): 1ページあたりの取得件数（デフォルト: 10000）
        
        Returns:
            dict: 全ページを統合したレスポンス
                {
                    'totalRows': 総件数,
                    'rows': 全行データ,
                    'columns': カラム定義,
                    ...
                }
        """
        url = f"{self.base_url}/issues/search"
        
        # 共通のリクエストデータ
        data = {
            "filters": [
                {
                    "columnKey": "project",
                    "matchMode": "oneOrMoreMatch",
                    "matchers": [
                        {
                            "class": "Project",
                            "name": project_key,
                            "type": "nameMatcher"
                        }
                    ],
                },
                {
                    "columnKey": "streams",
                    "matchMode": "oneOrMoreMatch",
                    "matchers": [
                        {
                            "class": "Stream",
                            "name": stream_name,
                            "type": "nameMatcher"
                        }
                    ],
                }
            ],
            "columns": [
                "cid",
                "mergeKey",
                "displayFile",
                "fileLanguage",
                "displayFunction",
                "lineNumber",
                "displayImpact",
                "displayIssueKind",
                "displayType",
                "displayCategory",
                "cwe",
                "occurrenceCount",
                "checker",
                "status",
                "firstDetected",
                "firstSnapshotId",
                "firstSnapshotDate",
                "firstSnapshotStream",
                "lastDetectedId",
                "lastDetected",
                "lastDetectedStream",
                "classification",
                "severity",
                "action",
                "owner"
            ],
            "snapshotScope": {
                "show": {
                    "scope": str(snapshot_id),
                    "includeOutdated": False
                }
            }
        }
        
        # デバッグ: リクエストペイロードをログ出力
        logger.debug(
            f"[search_issues_by_snapshot] リクエストペイロード: "
            f"{json.dumps(data, indent=2, ensure_ascii=False)}"
        )
        
        # ページング処理で全データを取得
        all_rows = []
        offset = 0
        total_rows = None
        first_response = None
        page_count = 0
        
        while True:
            page_count += 1
            params = {
                "locale": "ja_JP",
                "rowCount": page_size,
                "offset": offset,
                "sortOrder": "asc",
                "includeColumnLabels": True,
                "queryType": "bySnapshot",
                "sortColumn": "cid",
            }
            
            logger.info(
                f"[search_issues_by_snapshot] "
                f"ページ {page_count}: offset={offset}, rowCount={page_size}"
            )
            
            response = requests.post(
                url,
                auth=self.auth,
                headers=self.headers,
                proxies=self.proxies,
                params=params,
                json=data,
                verify=False,
                timeout=60
            )
            response.raise_for_status()
            page_data = response.json()
            
            # 最初のレスポンスを保存（メタデータ用）
            if first_response is None:
                first_response = page_data
                total_rows = page_data.get('totalRows', 0)
                
                if total_rows > page_size:
                    logger.warning(
                        f"[search_issues_by_snapshot] "
                        f"[WARNING] 総件数 {total_rows} が {page_size} を超えています。"
                        f"ページング処理で全データを取得します"
                    )
            
            # 現在のページの行データを追加
            rows = page_data.get('rows', [])
            all_rows.extend(rows)
            
            logger.info(
                f"[search_issues_by_snapshot] "
                f"ページ {page_count}: {len(rows)}件取得 (累計: {len(all_rows)}/{total_rows})"
            )
            
            # 全件取得完了判定
            if len(rows) < page_size or len(all_rows) >= total_rows:
                break
            
            # 次ページへ
            offset += page_size
        
        # 統合されたレスポンスを返す
        result = first_response.copy()
        result['rows'] = all_rows
        result['totalRows'] = len(all_rows)
        
        logger.info(
            f"[search_issues_by_snapshot] "
            f"[OK] 全 {page_count} ページ、{len(all_rows)}件取得完了"
        )
        
        return result
    
    def get_source_code_info(self, cid, stream_name, include_count=True, locale='ja_JP'):
        """
        個別CIDのソースコード情報を取得（REST API版）
        
        GET /api/v2/issues/sourceCodeInfo
        
        Args:
            cid (int): CID番号
            stream_name (str): ストリーム名
            include_count (bool, optional): 問題発生箇所の総数を含めるか（デフォルト: True）
            locale (str, optional): ロケール（デフォルト: 'ja_JP'で日本語取得）
        
        Returns:
            dict: ソースコード情報
                {
                    'mainEventDescription': メインイベントの説明,
                    'eventTag': イベントタグ,
                    'localEffect': ローカル効果,
                    'longDescription': 詳細説明,
                    'domain': ドメイン,
                    'filePathname': ファイルパス,
                    'lineNumber': 行番号,
                }
            
            エラー時は None を返します
        
        Note:
            - issueOccurrences配列の最初の要素から詳細情報を抽出します
            - locale='ja_JP'を指定すると、localEffectとlongDescriptionが日本語で取得されます
        """
        url = f"{self.base_url}/issues/sourceCodeInfo"
        
        params = {
            'cid': cid,
            'streamName': stream_name,
            'includeTotalIssueOccurrencesCount': 'true' if include_count else 'false',
            'locale': locale
        }
        
        try:
            response = requests.get(
                url,
                params=params,
                auth=self.auth,
                headers=self.headers,
                proxies=self.proxies,
                verify=False,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            
            # issueOccurrences配列から最初の要素を取得
            occurrences = data.get('issueOccurrences', [])
            if not occurrences:
                logger.warning(f"CID {cid}: issueOccurrencesが空です")
                return None
            
            occurrence = occurrences[0]
            
            # メインイベントを探す
            events = occurrence.get('events', [])
            main_event = None
            for event in events:
                if event.get('main') == True:
                    main_event = event
                    break
            
            # 結果を構築
            result = {
                'mainEventDescription': '',
                'eventTag': '',
                'localEffect': occurrence.get('localEffect', ''),
                'longDescription': occurrence.get('longDescription', ''),
                'domain': occurrence.get('domain', ''),
                'filePathname': '',
                'lineNumber': '',
            }
            
            # メインイベントから情報を取得
            if main_event:
                result['mainEventDescription'] = main_event.get('eventDescription', '')
                result['eventTag'] = main_event.get('eventTag', '')
                result['lineNumber'] = main_event.get('lineNumber', '')
                
                # ファイル情報
                file_info = main_event.get('file', {})
                result['filePathname'] = file_info.get('filePathname', '')
            
            return result
            
        except requests.exceptions.HTTPError as e:
            logger.error(f"CID {cid}: HTTP エラー: {e}")
            if e.response:
                logger.error(f"レスポンス: {e.response.text}")
            return None
        except Exception as e:
            logger.error(f"CID {cid}: エラーが発生しました: {e}")
            return None
