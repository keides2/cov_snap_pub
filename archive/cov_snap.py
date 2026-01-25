#!/usr/bin/python

import os
import sys
import zipfile

# csv
import csv

# JSON
import json

# datetime 型の json.dumps でシリアライズエラーに対応
from datetime import datetime

# This script requires suds that provides SOAP bindings for python.
# Download suds from https://pypi.org/project/suds/
#   unpack it and then run:
#     python setup.py install
#
#   or unpack the 'suds' folder and place it in the same place as this script
from suds.client import Client
from suds.wsse import Security, UsernameToken
from suds.sudsobject import asdict

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

# このスクリプトは、covautolib ディレクトリにある covautolib_3 パッケージを利用しています。
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
from covautolib import covautolib_3

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

    # -------------TODO
    # DONE ストリーム名とスナップショットIDを入力パラメータにないとき、全CIDを抽出
    # DONE 認証キーを環境変数から読む（事前に、環境変数 COVAUTHUSER と COVAUTHKEY に値を設定しておくこと）
    # TODO host, port,...をファイルから読む
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
    log.logger.info(f"[init] username: {username}, auth_key: {auth_key}")

    #
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
    # -------------end of TODO

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
        error_level = "708"
        zip_file_path = "Environment_variable_not_set.zip"
        print(f"{error_level} {zip_file_path}")
        log.logger.error(f"{e}: Environment variable '{key}' not found.")
        sys.exit(error_level)


# プロジェクト一覧取得 getProjects
def get_all_projects(configServiceClient, filepath):
    """
    機能: プロジェクト一覧の取得 getProjects
    入力: configServiceClient インスタンス, filepath
    出力: ファイル projects_list.json
    戻り値: projects_list
    """
    log.logger.info("[get_all_projects] 開始")

    projectIdDO = configServiceClient.client.factory.create("projectFilterSpecDataObj")
    projectIdDO.namePattern = "*"
    results = configServiceClient.client.service.getProjects(projectIdDO)
    log.logger.info("----- getProjects")

    # プロジェクト一覧
    projects_list = []
    for v in results:
        """ print(
            v.projectKey,
            v.id.name,
            v.dateCreated,
            v.userCreated,
            v.dateModified,
            v.userModified,
        )
        """
        tmp_dict = {}
        tmp_dict["project_id"] = v.projectKey
        tmp_dict["project_name"] = v.id.name
        projects_list.append(tmp_dict)

    # projects_list を projects_list.json に書き込む
    log.logger.info("●プロジェクトリスト: {}".format(projects_list))

    filename = filepath + "projects_list.json"
    with open(filename, "w", encoding="cp932", errors="replace") as f:
        json.dump(projects_list, f, ensure_ascii=False, indent=4)

    return projects_list


# ストリーム一覧取得 getStreams
def get_all_streams(configServiceClient, filepath):
    """
    機能: ストリーム一覧の取得 getStreams
    入力: configServiceClient インスタンス
    出力: streams_list.json
    戻り値: streams_list
    """
    log.logger.info("[get_all_streams] 開始")

    streamIdDO = configServiceClient.client.factory.create("streamFilterSpecDataObj")
    streamIdDO.namePattern = "*"
    results = configServiceClient.client.service.getStreams(streamIdDO)
    log.logger.info("----- getStreams")
    #    for v in results:
    #        print v.id.name

    streams_list = []
    for v in results:
        streams_list.append(v.id.name)

    # streams_list を streams_list.json に書き込む
    log.logger.info("●ストリームリスト: {}".format(streams_list))

    filename = filepath + "streams_list.json"
    with open(filename, "w", encoding="cp932", errors="replace") as f:
        json.dump(streams_list, f, ensure_ascii=False, indent=4)

    return streams_list


# 全プロジェクト内のストリーム一覧取得（未使用） getProjects
def get_all_streams_of_a_project(configServiceClient, filepath):
    """
    機能: プロジェクト内のストリーム一覧取得 getProjects
    入力: configServiceClient インスタンス
    出力: ファイル streams_of_<projectname>_list.json
    戻り値: streams_of_projects_l
    """
    log.logger.info("[get_all_streams_of_a_project] 開始")

    projectIdDO = configServiceClient.client.factory.create("projectFilterSpecDataObj")
    projectIdDO.namePattern = "*"
    results = configServiceClient.client.service.getProjects(projectIdDO)
    log.logger.info("----- getProjects")

    # 全プロジェクトのストリーム一覧リスト
    streams_of_projects_l = []

    # プロジェクトの数
    len_results = len(results)

    # ストリーム名の取得
    for project in results:
        # プロジェクト内のストリーム一覧リスト
        streams_list = []

        # ストリームの数
        if hasattr(project, "streams"):
            # streams が存在する場合
            len_projects = len(project.streams)

            # ストリーム名の取得
            for streams_of_project in project.streams:
                stream_name = streams_of_project.id.name
                tmp_dict = {}
                tmp_dict["streamname"] = stream_name
                streams_list.append(tmp_dict)

        elif hasattr(project, "streamLinks"):
            # streams が存在しないが、リンクがある場合
            # ストリーム名の取得
            for streams_of_project in project.streamLinks:
                stream_name = streams_of_project.id.name
                tmp_dict = {}
                tmp_dict["streamname"] = stream_name
                streams_list.append(tmp_dict)

        else:
            # streams もリンクも存在しない場合
            stream_name = "None"
            tmp_dict = {}
            tmp_dict["streamname"] = stream_name
            streams_list.append(tmp_dict)

        # プロジェクト名取得
        projectname = project.id.name

        # 個別にファイル保存
        filename = filepath + "streams_of_" + projectname + "_list.json"
        with open(filename, "w", encoding="cp932", errors="replace") as f:
            json.dump(streams_list, f, ensure_ascii=False, indent=4)

        # streams_of_projects_l 更新
        tmp_dict = {}
        tmp_dict = {projectname: streams_list}
        streams_of_projects_l.append(tmp_dict)

    # まとめてファイル保存
    filename = filepath + "streams_of_projects_list.json"
    with open(filename, "w", encoding="cp932", errors="replace") as f:
        json.dump(streams_of_projects_l, f, ensure_ascii=False, indent=4)

    return streams_of_projects_l


# 全プロジェクト内のストリーム一覧取得 getProjects
def get_all_streams_of_each_project(configServiceClient, filepath):
    """
    機能: 全プロジェクトのストリーム一覧取得 getProjects
    今回の全プロジェクトのストリーム一覧（スナップショットID含まない）作成 streams_of_projects_list.json 生成
    および各プロジェクトのストリーム一覧（スナップショットID含まない）作成 streams_of_<projectname>_list.json 生成
    各プロジェクトのストリーム一覧作成
    入力: configServiceClient インスタンス
    出力: ファイル streams_of_projects_list.json, streams_of_<projectname>_list.json
    戻り値: streams_of_projects_l
    """
    log.logger.info("[get_all_streams_of_each_project] 開始")

    """ streams_of_projects_l = [
        {
            "projectname": {
                "ProjectA": [
                    {
                        "streamname": "StreamA"
                    },
                    {
                        "streamname": "StreamB"
                    }
                ]
            }
        },
        {
            "projectname": {
                "ProjectB": [
                    {
                        "streamname": "ProjectB"
                    }
                ]
            }
        },
        ...
    ]
    """

    """ streams_of_ProjectA_list = [
        {
            "streamname": "StreamA"
        },
        {
            "streamname": "StreamB"
        }
    ]
    """

    projectIdDO = configServiceClient.client.factory.create("projectFilterSpecDataObj")
    projectIdDO.namePattern = "*"
    results = configServiceClient.client.service.getProjects(projectIdDO)
    log.logger.info("----- getProjects")

    # 全プロジェクトのストリーム一覧リスト
    streams_of_projects_l = []

    # プロジェクトの数
    len_results = len(results)

    # ストリーム名の取得
    for project in results:
        # プロジェクト内のストリーム一覧リスト
        streams_list = []

        # ストリームの数
        if hasattr(project, "streams"):
            # streams が存在する場合
            len_projects = len(project.streams)

            # ストリーム名の取得
            for streams_of_project in project.streams:
                stream_name = streams_of_project.id.name
                tmp_dict = {}
                tmp_dict["streamname"] = stream_name
                streams_list.append(tmp_dict)

        elif hasattr(project, "streamLinks"):
            # streams が存在しないが、リンクがある場合
            # ストリーム名の取得
            for streams_of_project in project.streamLinks:
                stream_name = streams_of_project.id.name
                tmp_dict = {}
                tmp_dict["streamname"] = stream_name
                streams_list.append(tmp_dict)

        else:
            # streams もリンクも存在しない場合
            stream_name = "None"
            tmp_dict = {}
            tmp_dict["streamname"] = stream_name
            streams_list.append(tmp_dict)

        # プロジェクト名取得
        projectname = project.id.name

        # 各プロジェクト個別にファイル保存
        # プロジェクト名のディレクトリが存在しないなら作成
        project_dir = filepath + projectname + sep
        if not os.path.isdir(project_dir):
            os.mkdir(project_dir)

        filename = project_dir + "streams_of_" + projectname + "_list.json"
        with open(filename, "w", encoding="cp932", errors="replace") as f:
            json.dump(streams_list, f, ensure_ascii=False, indent=4)

        # streams_of_projects_l 更新
        tmp_dict = {}
        tmp_dict = {"projectname": {projectname: streams_list}}
        streams_of_projects_l.append(tmp_dict)

    # まとめてファイル保存
    filename = filepath + "streams_of_projects_list.json"
    with open(filename, "w", encoding="cp932", errors="replace") as f:
        json.dump(streams_of_projects_l, f, ensure_ascii=False, indent=4)

    return streams_of_projects_l


# プロジェクト全体ファイルを読み込みリストに格納する
def read_projects(filepath, filename):
    """
    機能: last.json あるいは last_before_last.json を読み込みリストにして返す
    入力: filepath, filename
    出力: -
    戻り値: リスト
    """
    log.logger.info("[read_projects] 開始")

    # ファイルを開く
    file = filepath + filename
    try:
        with open(file, "r", encoding="cp932") as f:
            # リストに代入
            l = json.load(f)

    except FileNotFoundError:
        log.logger.error(f"[read_projects] File {filename} not found in {filepath}")
        l = []

    except Exception as err:
        log.logger.error("[read_projects] An error occurred: {}".format(err))
        l = []

    return l


# 全プロジェクトからストリーム名を検索し、スナップショットIDのリストを返す
def get_snapshotId_list(target_list, key):
    """
    機能: last_l あるいは last_before_last_l からスナップショットIDのリストを返す
    入力: target_list(last_l あるいは last_before_last_l), streamname
    出力: -
    戻り値: スナップショットIDのリスト
    """
    log.logger.info("[get_snapshotId_list] 開始")

    result = []
    for item in target_list:
        for project in item.values():
            for value in project.values():
                for stream in value:
                    for streamname in stream.values():
                        if key in streamname.keys():
                            snapshot_id = streamname[key]["snapshotId"]
                            result.extend(snapshot_id)
                            break
                    else:
                        continue  # 内側のループを継続
                    break  # 外側のループを脱出
                else:
                    continue  # 内側のループを継続
                break  # 外側のループを脱出
            else:
                continue  # 内側のループを継続
            break  # 外側のループを脱出
        else:
            continue  # 内側のループを継続
        break  # 外側のループを脱出

    return result


# ストリーム内のスナップショットID一覧取得 getSnapshotsForStream
def get_all_snapshotids(configServiceClient, streamname, filepath):
    """
    機能: ストリーム内のスナップショットID一覧の取得
    入力: configServiceClient, streamname, filepath
    出力: snapshots_<streamname>_list.json
    戻り値: snapshots_list
    """
    log.logger.info("[get_all_snapshotids] 開始")

    streamIdDO = configServiceClient.client.factory.create("streamIdDataObj")
    streamIdDO.name = streamname
    results = configServiceClient.client.service.getSnapshotsForStream(streamIdDO)
    log.logger.info("----- getSnapshotsForStream")

    snapshots_list = []
    for v in results:
        snapshots_list.append(v.id)

    # snapshots_list を streamname_snapshots_list.json に書き込む
    log.logger.info("●スナップショットリスト: {}".format(snapshots_list))

    # snapshots_dir = "." + sep + "snapshots" + sep
    filename = filepath + sep + "snapshots_" + streamname + "_list.json"
    with open(filename, "w", encoding="cp932", errors="replace") as f:
        json.dump(snapshots_list, f, ensure_ascii=False, indent=4)

    return snapshots_list


# プロジェクト内全情報が記載された今回のリスト last_list および指摘一覧 CSV ファイルを作成する
def make_last_list(configServiceClient, defectServiceClient, all_streams, filepath):
    """
    機能: プロジェクト名、ストリーム名、スナップショットID が記載された今回のリストを作成する
    並行してスナップショットの指摘一覧ファイル（CSV、ZIP）を生成する
    入力: configServiceClient、defectServiceClient、全プロジェクト内の全ストリームのリスト all_streams、filepath
    出力: cid_info_<38421>.json, snapshot_id_<13542>.csv, snapshot_id_<13542>.zip, last_list
    戻り値: error_level, ret_zip_file_name_path
    """
    log.logger.info("[make_last_list] 開始")

    # 前回のファイル last.json を読み込み、last_before_last.json に上書き保存する
    filename = filepath + "last.json"
    with open(filename, "r", encoding="cp932") as f:
        last = json.load(f)

    filename = filepath + "last_before_last.json"
    with open(filename, "w", encoding="cp932", errors="replace") as f:
        json.dump(last, f, ensure_ascii=False, indent=4)

    # 今回の全プロジェクトのリスト
    last_list = []

    # 差分が無いときの戻り値用
    ret_zip_file_name_path = filepath
    error_level = "0"

    # 前回のリスト作成
    filename = "last_before_last.json"
    last_before_last_l = read_projects(filepath, filename)

    if not last_before_last_l:
        # 戻り値が []
        log.logger.error("[make_last_list] 前回のリストの読み取りに失敗しました")
        sys.exit(1)

    # ストリームを巡回し、all_streams にスナップショットIDを追加する
    # スナップショットIDはストリーム名で決まる
    # 引数 all_streams リストの要素数はグループの数（グループ名を含む）のでグループ巡回と同じ
    # ストリーム内のスナップショットID一覧取得
    for project in all_streams:
        """ project = {
            "projectname": {
                "ProjectA": [
                    {
                        "streamname": "StreamA"
                    },
                    {
                        "streamname": "StreamB"
                    }
                ]
            }
        }
        """

        # プロジェクト名辞書からプロジェクト名を取得（今回用）
        projct_last_dict = project["projectname"]

        """ projct_last_dict = {
                "ProjectA": [
                    {
                        "streamname": "StreamA"
                    },
                    {
                        "streamname": "StreamB"
                    }
                ]
            }
        """

        # DONE: キー（プロジェクト名）取得
        # projectnameはループの内側で定義されているため、ループの外側では存在しない。この行はエラーを引き起こす可能性がある。→存在しエラーにならない
        for projectname in projct_last_dict.keys():
            log.logger.info("●プロジェクト名: {}".format(projectname))

        # DONE: キー（プロジェクト名）取得（修正案）→修正しない
        # projectname = list(projct_last_dict.keys())[0]
        # log.logger.info("●プロジェクト名: {}".format(projectname))

        # プロジェクト名のディレクトリが存在しないなら作成
        project_dir = filepath + projectname + sep
        if not os.path.isdir(project_dir):
            os.mkdir(project_dir)

        # テンポラリーなプロジェクト名辞書とリスト
        tmp_proj_last_dict = {"projectname": {projectname: []}}

        # プロジェクト名辞書からストリーム名を取得、 i にインデックス（ストリーム数）
        for i, streamname_last_dict in enumerate(projct_last_dict[projectname]):
            """ streamname_last_dict = {
                {
                    "streamname": "StreamA"
                }
            }
            """

            # 代入前に今回用辞書を作成
            # streamname_last_dict = streamname_last_dict.copy()

            # ストリーム名取得
            streamname = streamname_last_dict["streamname"]

            # ストリーム名のディレクトリが存在しないなら作成
            stream_dir = snapshots_dir + projectname + sep + streamname + sep
            if not os.path.isdir(stream_dir):
                os.mkdir(stream_dir)

            """ csv_zip ディレクトリ
            スナップショットの全指摘ファイル保存先
            （例）スナップショットID=13542 のとき、
            パス: .\snapshots\ProjectA\StreamA\csv_zip
            ファイル名: snapshot_id_13542.csv、 同.zip
            """
            # csv_zip ディレクトリが存在しないなら作成
            csv_zip_dir = stream_dir + "csv_zip" + sep
            if not os.path.isdir(csv_zip_dir):
                os.mkdir(csv_zip_dir)

            # ストリーム内のスナップショットID一覧取得
            if streamname != "None":
                # 今回のスナップショットIDリスト snapshots_l
                snapshots_l = get_all_snapshotids(
                    configServiceClient, streamname, stream_dir
                )

                """ ここで追加された新しいスナップショットIDの抽出を行う """
                # 前回のスナップショットIDリスト old_list を読み込み
                old_list = get_snapshotId_list(last_before_last_l, streamname)

                # スナップショットIDの新旧差分 diff_list （新しく追加されたスナップショットIDのみ抽出）
                diff_list = get_diff_list(old_list, snapshots_l)
                log.logger.info("[make_last_list] 差分 diff_list: {}".format(diff_list))

                """ ここで CID 詳細を取得し、CSV、ZIP ファイル作成まで行う """
                # 追加されたスナップショットID 取得
                for snapshot_id in diff_list:
                    # 全CID cids_list と、マージされた欠陥のリスト mergedDefects を取得
                    log.logger.info(
                        "[make_last_list] get_all_cids_in_a_snapshot() を呼び出します"
                    )
                    log.logger.info(
                        "[make_last_list] プロジェクト: {}, ストリーム: {}, スナップショットID: {}".format(
                            projectname, streamname, snapshot_id
                        )
                    )
                    cids_list, mergedDefects = get_all_cids_in_a_snapshot(
                        defectServiceClient, projectname, snapshot_id, stream_dir
                    )

                    # 指摘がゼロ
                    if cids_list[0] == "706":
                        error_level = "706"
                        ret_zip_file_name_path = "totalNumberOfCids_0"

                        # return error_level, ret_zip_file_name_path
                        break

                    # get_cid_info() で取得できない項目の取得
                    mergedDefects_dict = get_mergedDefects_snapshot(
                        snapshot_id,
                        stream_dir,
                        mergedDefects,
                    )

                    """ mergedDefects_dict = {
                        'firstDetectedSnapshotId': 13533,
                        'firstDetected': datetime.datetime(20...D6C1C160>),
                        'firstDetectedStream': 'StreamB',
                        'lastDetected': 'datetime.datetime(20...6C1C340>)',
                        'lastDetectedSnapshotId': 13542,
                        'lastDetectedStream': 'StreamB'
                    }
                    """

                    # CID 取得
                    tmp_list = []
                    log.logger.info(
                        "[make_last_list] get_cid_info() を {} 回呼び出します。しばらくお待ちください。".format(
                            len(cids_list)
                        )
                    )
                    for i, cid in enumerate(cids_list):
                        # プログレスバー(1000個ごとに * 表示）
                        if i % 5000 == 0:
                            print("|", end="")
                        elif i % 1000 == 0:
                            print("*", end="")

                        # CID の詳細取得 result_dict
                        # TODO: エラーをキャッチする
                        try:
                            result_dict = get_cid_info(
                                defectServiceClient, streamname, cid, stream_dir
                            )
                            # print(result_dict)

                            """ result_dict = {
                            "checkerName": "ALLOC_FREE_MISMATCH",
                            "cid": 37322,
                            "defectInstances": [
                                "events": [
                                    {
                                        "eventDescription": "条件 \"CNetUserPasswd::m_pMyObj != NULL\" は true となりました。",
                                        "eventKind": "PATH",
                                        "eventNumber": 1,
                                        "eventSet": 0,
                                        "eventTag": "cond_true",
                                        "fileId": {
                                            "contentsMD5": "xxxxxxxxxxxxxxx",
                                            "filePathname": "/p4v/depot/StreamA/src/Network/net_UserPasswd.cpp"
                                        },
                                        "lineNumber": 247,
                                        "main": false,
                                        "polarity": false
                                    },
                                    {
                                        ...
                                    }
                                ]
                                "category": {
                                    "displayName": "API の誤使用",
                                    "name": "API usage errors"
                                },
                                "checkerName": "ALLOC_FREE_MISMATCH",
                                "component": "Default.Other",
                                "cwe": 762,
                                "domain": "STATIC_C",
                                "extra": "pHeader",
                                "function": {
                                    "fileId": {
                                        "contentsMD5": "xxxxxxxxxxxxxxx",
                                        "filePathname": "/p4v/depot/StreamA/src/Network/net_UserPasswd.cpp"
                                },
                                "functionDisplayName": "CNetUserPasswd::SendToPC()",
                                "functionMangledName": "_ZN14CNetUserPasswd8SendToPCEv",
                                "functionMergeName": "_ZN14CNetUserPasswd8SendToPCEv"
                                },
                                "id": {
                                    "id": 43895062
                                },
                                "impact": {
                                    "displayName": "中",
                                    "name": "Medium"
                                },
                                "issueKinds": [
                                    {
                                        "displayName": "品質",
                                        "name": "QUALITY"
                                    }
                                ],
                                "localEffect": "正しいアロケータとの違いによっては、リソース リークまたはメモリ破損が発生する可能性があります。",
                                "longDescription": "誤ったデアロケータを使用してリソースが解放されました",
                                "misraCategory": "None",
                                "subcategory": "none",
                                "type": {
                                    "displayName": "誤ったデアロケータが使用されました",
                                    "name": "Incorrect deallocator used"
                                },
                                {
                                ...
                                }
                            ],
                            "defectStateAttributeValues": [
                                {
                                    "attributeDefinitionId": {
                                        "name": "DefectStatus"
                                    },
                                    "attributeValueId": {
                                        "name": "New"
                                    }
                                },
                                {
                                ...
                                },
                                ...
                            ],
                            "domain": "STATIC_C",
                            "history": [
                                {
                                    "dateCreated": "2021-03-02T08:39:56.449000+09:00",
                                    "defectStateAttributeValues": [
                                        {
                                            "attributeDefinitionId": {
                                                "name": "Classification"
                                            },
                                            "attributeValueId": {
                                                "name": "Unclassified"
                                            }
                                        },
                                        ...
                                    "userCreated": "admin"
                                },
                                {
                                    "dateCreated": "2021-03-02T08:39:56.449000+09:00",
                                    "defectStateAttributeValues": [
                                        {
                                        ...
                                        },
                                        ...
                                    "userCreated": "admin"
                                },
                                ...

                            ],
                            "id": {
                                "defectTriageId": 11300,
                                "defectTriageVerNum": 3,
                                "id": 1157369,
                                "verNum": 0
                            },
                            "streamId": {
                                "name": "StreamA"
                            }
                        }
                        """

                            # 詳細が空
                            if result_dict == {}:
                                # error_level = "707"
                                # ret_zip_file_name_path = "get_cid_info_null"
                                log.logger.error(
                                    "[make_last_list] CID: {} は取得できませんでした（get_cid_info() の戻り値が空）".format(
                                        cid
                                    )
                                )
                                continue
                                # return error_level, ret_zip_file_name_path

                        except Exception as e:
                            log.logger.error("[make_last_list] An error occurred: {}".format(e))
                            continue

                        # CSV 作成用 JSON ファイル作成
                        # ここで result_dict に mergedDefects_dict をマージする
                        ret_list = add_cids_to_json(result_dict, mergedDefects_dict)

                        """ ret_list = [
                            {
                                'cid': 255684,
                                'checkerName': 'CERT DCL51-CPP',
                                'domain': 'STATIC_C',
                                'streamname': 'StreamB',
                                'eventDescription': <Text, len() = 34>,
                                'filePathname': <Text, len() = 43>,
                                'lineNumber': 15,
                                'eventTag': 'cert_dcl51_cpp_violation',
                                'impact': '低',
                                ...
                                'firstDetectedSnapshotId': 13533,
                                'firstDetected': datetime.datetime(20...D6C1C160>),
                                'firstDetectedStream': 'StreamB',
                                'lastDetected': 'datetime.datetime(20...6C1C340>)',
                                'lastDetectedSnapshotId': 13542,
                                'lastDetectedStream': 'StreamB'
                            },
                            {
                                'cid': 255684,
                                'checkerName': 'CERT DCL51-CPP',
                                'domain': 'STATIC_C',
                                'streamname': 'StreamB',
                                'eventDescription': <Text, len() = 34>,
                                'filePathname': <Text, len() = 43>,
                                'lineNumber': 19,
                                'eventTag': 'cert_dcl51_cpp_violation',
                                'impact': '低',
                                ...
                                'firstDetectedSnapshotId': 13533,
                                'firstDetected': datetime.datetime(20...D6C1C160>),
                                'firstDetectedStream': 'StreamB',
                                'lastDetected': 'datetime.datetime(20...6C1C340>)',
                                'lastDetectedSnapshotId': 13542,
                                'lastDetectedStream': 'StreamB'
                            }
                        ]
                        """

                        # リストに追加（一つのCIDについて複数のイベントがある場合に対応）
                        for l in ret_list:
                            tmp_list.append(l)

                    # print("tmp_list: {}".format(tmp_list))
                    print("\n")

                    # csv ファイルに保存
                    csv_filepath_name = (
                        csv_zip_dir + "snapshot_id_" + str(snapshot_id) + ".csv"
                    )
                    json_dic_to_csv(tmp_list, csv_filepath_name)

                    # ZIP ファイル作成
                    # 圧縮したいファイルのリスト
                    files = [csv_filepath_name]

                    # 拡張子なしの圧縮後ファイル名
                    zip_file_name_base_without_ext = os.path.splitext(
                        os.path.basename(csv_filepath_name)
                    )[0]
                    # ZIP圧縮ファイルへのパス
                    zip_file_name_path = (
                        csv_zip_dir + zip_file_name_base_without_ext + ".zip"
                    )

                    # 圧縮
                    ret_zip_file_name_path = zip_files(files, zip_file_name_path)

            """ ここから diff_last_before_last_from_last.json の作成 """
            # ストリーム名の辞書にスナップショットIDリストを追加済み
            streamname_last_dict["streamname"] = {
                streamname_last_dict["streamname"]: {"snapshotId": diff_list}
            }

            """ streamname_last_dict = {
                    {
                        "streamname": {
                            "StreamA": {
                                "snapshotId": [
                                    12918, ...
                                ]
                            }
                        }
                    }
                }
            """

            """ ここから last_list.json の作成 """
            streamname_last_dict["streamname"] = {
                streamname: {"snapshotId": snapshots_l}
            }

            # プロジェクト名辞書にスナップショットID付きストリーム名の辞書を追加（今回用）
            tmp_proj_last_dict["projectname"][projectname].append(streamname_last_dict)

        # 全プロジェクトの今回リストにプロジェクトを追加
        last_list.append(tmp_proj_last_dict)

    # 今回の結果 last_list を last.json に保存する
    filename = snapshots_dir + "last.json"
    with open(filename, "w", encoding="cp932", errors="replace") as f:
        json.dump(last_list, f, ensure_ascii=False, indent=4)

    log.logger.info("'last.json' を更新しました")

    # 今回の結果 last_list を last_before_last.json に保存する
    # filename = snapshots_dir + "last_before_last.json"
    # with open(filename, "w", encoding="cp932", errors='replace') as f:
    #     json.dump(last_list, f, ensure_ascii=False, indent=4)

    return error_level, ret_zip_file_name_path


# 特定ストリームのスナップショットIDについて、指摘一覧 CSV ファイルを作成する
def add_snapshot_to_last_list(
    defectServiceClient,
    filepath,
    stream_name,
    snapshot_id,
):
    """
    機能: プロジェクト名、ストリーム名、スナップショットID が記載された今回のリストを作成する
    並行してスナップショットの指摘一覧ファイル（CSV、ZIP）を生成する
    ZIPファイル作成後に、last.jsonを更新する
    入力: defectServiceClient、全プロジェクト内の全ストリームのリスト all_streams、filepath、stream_name, snapshot_id
    出力: cid_info_<38421>.json, snapshot_id_<13542>.csv, snapshot_id_<13542>.zip, last_list
    戻り値: error_level, ret_zip_file_name_path
    """
    log.logger.info("[add_snapshot_to_last_list] 開始")

    # 差分が無いときの戻り値用
    error_level = "0"
    ret_zip_file_name_path = filepath

    # 前回のファイル last.json を読み込み、今回のリスト last_l に代入する
    try:
        # ストリーム名が存在しない場合のエラー処理追加
        filename = filepath + "last.json"
        with open(filename, "r", encoding="cp932") as f:
            last_l = json.load(f)

    except FileNotFoundError as err:
        log.logger.error(
            "[add_snapshot_to_last_list] FileNotFoundError! 前回のリストの読み取りに失敗しました: {}".format(err)
        )
        error_level = "700"
        ret_zip_file_name_path = "FileNotFoundError"
        return error_level, ret_zip_file_name_path

    if not last_l:
        # 戻り値が []
        log.logger.error("[add_snapshot_to_last_list] last_l が [] 前回のリストの読み取りに失敗しました")
        error_level = "702"
        ret_zip_file_name_path = "last_l_null_Error"
        return error_level, ret_zip_file_name_path

    # ストリーム名からプロジェクト名を探す
    target_dict = {"streamname": stream_name}

    try:
        idx_project, prj_l = find_key_with_dictionary(last_l, target_dict)
        projectname = prj_l[0]

    except Exception as err:
        log.logger.error(
            "[add_snapshot_to_last_list] find_key_with_dictionary() で Exception! ストリームが存在しない可能性があります: {}".format(err)
        )
        error_level = "703"
        ret_zip_file_name_path = "Exception"
        return error_level, ret_zip_file_name_path

    # 過去に取得済みなら、そのZIPファイルを返す
    csv_zip_dir = (
        snapshots_dir + projectname + sep + stream_name + sep + "csv_zip" + sep
    )
    zipfilepath = csv_zip_dir + "snapshot_id_" + str(snapshot_id) + ".zip"
    # ZIPファイルの存在確認
    if os.path.isfile(zipfilepath):
        # 既に存在する（error_level='0'で返す）
        return error_level, zipfilepath

    # ストリームを巡回し、all_streams にスナップショットIDを追加する
    # スナップショットIDはストリーム名で決まる
    # 引数 all_streams リストの要素数はグループの数（グループ名を含む）のでグループ巡回と同じ
    # ストリーム内のスナップショットID一覧取得

    """ project = {
            "projectname": {
                "ProjectA": [
                    {
                        "streamname": "StreamA"
                    },
                    {
                        "streamname": "StreamB"
                    }
                ]
            }
        }
    """

    """ projct_last_dict = {
            "ProjectA": [
                {
                    "streamname": "StreamA"
                },
                {
                    "streamname": "StreamB"
                }
            ]
        }
    """

    # プロジェクト名のディレクトリが存在しないなら作成
    project_dir = filepath + projectname + sep
    if not os.path.isdir(project_dir):
        os.mkdir(project_dir)

    # ストリーム名のディレクトリが存在しないなら作成
    stream_dir = project_dir + stream_name + sep
    if not os.path.isdir(stream_dir):
        os.mkdir(stream_dir)

    """ csv_zip ディレクトリ
    スナップショットの全指摘ファイル保存先
    （例）スナップショットID=13542 のとき、
    パス: .\snapshots\ProjectA\StreamA\csv_zip
    ファイル名: snapshot_id_13542.csv、 同.zip
    """

    # csv_zip ディレクトリが存在しないなら作成
    csv_zip_dir = stream_dir + "csv_zip" + sep
    if not os.path.isdir(csv_zip_dir):
        os.mkdir(csv_zip_dir)

    # 全CID cids_list と、マージされた欠陥のリスト mergedDefects を取得
    log.logger.info("[add_snapshot_to_last_list] get_all_cids_in_a_snapshot() を呼び出します")
    log.logger.info(
        "[add_snapshot_to_last_list] プロジェクト: {}, ストリーム: {}, スナップショットID: {}".format(
            projectname, stream_name, snapshot_id
        )
    )
    cids_list, mergedDefects = get_all_cids_in_a_snapshot(
        defectServiceClient, projectname, snapshot_id, stream_dir
    )

    # 指摘がゼロ
    if cids_list[0] == "706":
        error_level = "706"
        ret_zip_file_name_path = "totalNumberOfCids_0"

        return error_level, ret_zip_file_name_path

    # get_cid_info() で取得できない項目の取得
    log.logger.info("[add_snapshot_to_last_list] get_mergedDefects_snapshot() を呼び出します")
    mergedDefects_dict = get_mergedDefects_snapshot(
        snapshot_id,
        stream_dir,
        mergedDefects,
    )

    """ mergedDefects_dict = {
        'firstDetectedSnapshotId': 13533,
        'firstDetected': datetime.datetime(20...D6C1C160>),
        'firstDetectedStream': 'StreamB',
        'lastDetected': 'datetime.datetime(20...6C1C340>)',
        'lastDetectedSnapshotId': 13542,
        'lastDetectedStream': 'StreamB'
    }
    """

    # CID 取得
    tmp_list = []
    log.logger.info(
        "[add_snapshot_to_last_list] get_cid_info() を {} 回呼び出します。しばらくお待ちください。".format(
            len(cids_list)
        )
    )

    # cid巡回
    for i, cid in enumerate(cids_list):
        # プログレスバー(1000個ごとに * 表示）
        if i % 5000 == 0:
            print("|", end="")
        elif i % 1000 == 0:
            print("*", end="")

        # CID の詳細取得 result_dict
        result_dict = get_cid_info(defectServiceClient, stream_name, cid, stream_dir)
        # print(result_dict)
        """ result_dict = {
                "checkerName": "ALLOC_FREE_MISMATCH",
                "cid": 37322,
                "defectInstances": [
                    "events": [
                        {
                            "eventDescription": "条件 \"CNetUserPasswd::m_pMyObj != NULL\" は true となりました。",
                            "eventKind": "PATH",
                            "eventNumber": 1,
                            "eventSet": 0,
                            "eventTag": "cond_true",
                            "fileId": {
                                "contentsMD5": "xxxxxxxxxxxxxxx",
                                "filePathname": "/p4v/depot/StreamA/src/Network/net_UserPasswd.cpp"
                            },
                            "lineNumber": 247,
                            "main": false,
                            "polarity": false
                        },
                        {
                            ...
                        }
                    ]
                    "category": {
                        "displayName": "API の誤使用",
                        "name": "API usage errors"
                    },
                    "checkerName": "ALLOC_FREE_MISMATCH",
                    "component": "Default.Other",
                    "cwe": 762,
                    "domain": "STATIC_C",
                    "extra": "pHeader",
                    "function": {
                        "fileId": {
                            "contentsMD5": "xxxxxxxxxxxxxxx",
                            "filePathname": "/p4v/depot/StreamA/src/Network/net_UserPasswd.cpp"
                    },
                    "functionDisplayName": "CNetUserPasswd::SendToPC()",
                    "functionMangledName": "_ZN14CNetUserPasswd8SendToPCEv",
                    "functionMergeName": "_ZN14CNetUserPasswd8SendToPCEv"
                    },
                    "id": {
                        "id": 43895062
                    },
                    "impact": {
                        "displayName": "中",
                        "name": "Medium"
                    },
                    "issueKinds": [
                        {
                            "displayName": "品質",
                            "name": "QUALITY"
                        }
                    ],
                    "localEffect": "正しいアロケータとの違いによっては、リソース リークまたはメモリ破損が発生する可能性があります。",
                    "longDescription": "誤ったデアロケータを使用してリソースが解放されました",
                    "misraCategory": "None",
                    "subcategory": "none",
                    "type": {
                        "displayName": "誤ったデアロケータが使用されました",
                        "name": "Incorrect deallocator used"
                    },
                    {
                    ...
                    }
                ],
                "defectStateAttributeValues": [
                    {
                        "attributeDefinitionId": {
                            "name": "DefectStatus"
                        },
                        "attributeValueId": {
                            "name": "New"
                        }
                    },
                    {
                    ...
                    },
                    ...
                ],
                "domain": "STATIC_C",
                "history": [
                    {
                        "dateCreated": "2021-03-02T08:39:56.449000+09:00",
                        "defectStateAttributeValues": [
                            {
                                "attributeDefinitionId": {
                                    "name": "Classification"
                                },
                                "attributeValueId": {
                                    "name": "Unclassified"
                                }
                            },
                            ...
                        "userCreated": "admin"
                    },
                    {
                        "dateCreated": "2021-03-02T08:39:56.449000+09:00",
                        "defectStateAttributeValues": [
                            {
                            ...
                            },
                            ...
                        "userCreated": "admin"
                    },
                    ...
                ],
                "id": {
                    "defectTriageId": 11300,
                    "defectTriageVerNum": 3,
                    "id": 1157369,
                    "verNum": 0
                },
                "streamId": {
                    "name": "StreamA"
                }
            }
        """

        # 詳細が空
        if result_dict == {}:
            # error_level = "707"
            # ret_zip_file_name_path = "get_cid_info_null"
            log.logger.error(
                "[add_snapshot_to_last_list] CID: {} は取得できませんでした（get_cid_info() の戻り値が空）".format(
                    cid
                )
            )
            continue
            # return error_level, ret_zip_file_name_path

        # CSV 作成用 JSON ファイル作成
        # ここで result_dict に mergedDefects_dict をマージする
        ret_list = add_cids_to_json(result_dict, mergedDefects_dict)

        """ ret_list = [
                {
                    'cid': 255684,
                    'checkerName': 'CERT DCL51-CPP',
                    'domain': 'STATIC_C',
                    'streamname': 'StreamB',
                    'eventDescription': <Text, len() = 34>,
                    'filePathname': <Text, len() = 43>,
                    'lineNumber': 15,
                    'eventTag': 'cert_dcl51_cpp_violation',
                    'impact': '低',
                    ...
                    'firstDetectedSnapshotId': 13533,
                    'firstDetected': datetime.datetime(20...D6C1C160>),
                    'firstDetectedStream': 'StreamB',
                    'lastDetected': 'datetime.datetime(20...6C1C340>)',
                    'lastDetectedSnapshotId': 13542,
                    'lastDetectedStream': 'StreamB'
                },
                {
                    'cid': 255684,
                    'checkerName': 'CERT DCL51-CPP',
                    'domain': 'STATIC_C',
                    'streamname': 'StreamB',
                    'eventDescription': <Text, len() = 34>,
                    'filePathname': <Text, len() = 43>,
                    'lineNumber': 19,
                    'eventTag': 'cert_dcl51_cpp_violation',
                    'impact': '低',
                    ...
                    'firstDetectedSnapshotId': 13533,
                    'firstDetected': datetime.datetime(20...D6C1C160>),
                    'firstDetectedStream': 'StreamB',
                    'lastDetected': 'datetime.datetime(20...6C1C340>)',
                    'lastDetectedSnapshotId': 13542,
                    'lastDetectedStream': 'StreamB'
                }
            ]
        """

        # リストに追加（一つのCIDについて複数のイベントがある場合に対応）
        for l in ret_list:
            tmp_list.append(l)

    # print("tmp_list: {}".format(tmp_list))
    print("\n")

    # csv ファイルに保存
    log.logger.info("[add_snapshot_to_last_list] json_dic_to_csv() を呼び出し、CSVファイルを作成します")
    csv_filepath_name = csv_zip_dir + "snapshot_id_" + str(snapshot_id) + ".csv"
    json_dic_to_csv(tmp_list, csv_filepath_name)

    # ZIP ファイル作成
    log.logger.info("[add_snapshot_to_last_list] ZIPファイルを作成します")

    # 圧縮したいファイルのリスト
    files = [csv_filepath_name]
    # 拡張子なしの圧縮後ファイル名
    zip_file_name_base_without_ext = os.path.splitext(
        os.path.basename(csv_filepath_name)
    )[0]
    # ZIP圧縮ファイルへのパス
    zip_file_name_path = csv_zip_dir + zip_file_name_base_without_ext + ".zip"
    # 圧縮
    ret_zip_file_name_path = zip_files(files, zip_file_name_path)

    # 新しいスナップショットIDは、cov_snap.bat を引数無しで実行し取得するので以下は実装しない
    # 新しいスナップショットIDが last_l リストにないなら追加し、last.json を更新する
    # ストリーム名のインデックス idx_stream 取得
    # prj_l = last_l[idx_project]["projectname"]
    # target_dict = {"streamname": stream_name}
    # # idx_stream, strm_l = find_key_with_dictionary(prj_l, target_dict)
    # idx_stream = find_idx_in_list(prj_l, projectname, stream_name)

    # ないなら
    # if not last_l[idx_project]["projectname"][projectname][idx_stream]["streamname"][stream_name]["snapshotId"]:
    #     # 新しいスナップショットIDを last_l リストに追加する
    #     last_l[idx_project]["projectname"][projectname][idx_stream]["streamname"][
    #         stream_name
    #     ]["snapshotId"].append(int(snapshot_id))
    #
    # filename = snapshots_dir + "last.json"
    # with open(filename, "w", encoding="cp932", errors="replace") as f:
    #     json.dump(last_l, f, ensure_ascii=False, indent=4)

    return error_level, ret_zip_file_name_path


# スナップショット内のCIDリスト作成 getMergedDefectsForSnapshotScope
def get_all_cids_in_a_snapshot(defectServiceClient, projectname, snapshot_id, filepath):
    """
    機能: スナップショット内のCIDリストを作成する
    入力: defectServiceClient, projectname, snapshot_id, filepath
    出力: -
    戻り値: cids_list, マージされた欠陥のリスト mergedDefects
    """
    log.logger.info("[get_all_cids_in_a_snapshot] 開始")

    projectIdDO = defectServiceClient.client.factory.create("projectIdDataObj")
    projectIdDO.name = projectname
    filterSpecDO = defectServiceClient.client.factory.create(
        "snapshotScopeDefectFilterSpecDataObj"
    )

    pageSpecDO = defectServiceClient.client.factory.create("pageSpecDataObj")
    pageSpecDO.pageSize = 1000
    pageSpecDO.startIndex = 0
    snapshotScopeDO = defectServiceClient.client.factory.create(
        "snapshotScopeSpecDataObj"
    )
    snapshotScopeDO.showSelector = str(snapshot_id)

    # CID リスト作成
    cids_list = []

    # ページ番号
    page_num = 0

    # CID 総数
    totalNumberOfCids = 0

    # ページごとに CID を取得するループ
    while True:
        # ページ番号に応じて startIndex を設定
        pageSpecDO.startIndex = page_num * 1000

        # SOAP API を呼び出し（マージされた欠陥のリスト）
        mergedDefects = (
            defectServiceClient.client.service.getMergedDefectsForSnapshotScope(
                projectIdDO, filterSpecDO, pageSpecDO, snapshotScopeDO
            )
        )

        # 最初のページなら CID 総数を取得
        if page_num == 0:
            totalNumberOfCids = mergedDefects.totalNumberOfRecords
            log.logger.info(
                "[get_all_cids_in_a_snapshot] 全 CID: {}件".format(totalNumberOfCids)
            )

            if totalNumberOfCids == 0:
                # 指摘件数がゼロ/スナップショットIDが存在しない
                cids_list = ["706"]  # error_level = "706"
                return cids_list, mergedDefects

        log.logger.info(
            "------------ getMergedDefectsForSnapshotScope (1000件 x page.{})".format(
                page_num + 1
            )
        )

        # CID, mergeKey の取得
        # for id in mergedDefects.mergedDefectIds:
        #     print(id.cid, id.mergeKey)

        # CID リストに追加
        for id in mergedDefects.mergedDefectIds:
            cid = id.cid
            cids_list.append(cid)

        # ページ番号を増やす
        page_num += 1

        # CID リストが CID 総数に達したらループを抜ける
        if len(cids_list) >= totalNumberOfCids:
            break

    # まとめてファイル保存
    filename = filepath + "cids_of_snapshot_" + str(snapshot_id) + "_list.json"
    with open(filename, "w", encoding="cp932", errors="replace") as f:
        json.dump(cids_list, f, ensure_ascii=False, indent=4)

    return cids_list, mergedDefects


# 初回検出日ほかの取得 getMergedDefectsForSnapshotScope
def get_mergedDefects_snapshot(snapshot_id, filepath, mergedDefects):
    """
    機能: get_cid_info() で取得できない次の項目を取得する
        初回検出日、最初のスナップショット、最初のスナップショットの日付、最初のスナップショットのストリーム、
        最後のスナップショット、最後のスナップショットの日付、最後のスナップショットのストリーム、
    入力: snapshot_id, filepath, mergedDefects
    出力: -
    戻り値: tmp_dict(mergedDefects_dict)
    """
    log.logger.info("[get_mergedDefects_snapshot] 開始")

    """
    projectIdDO = defectServiceClient.client.factory.create("projectIdDataObj")
    projectIdDO.name = projectname
    filterSpecDO = defectServiceClient.client.factory.create(
        "snapshotScopeDefectFilterSpecDataObj"
    )

    pageSpecDO = defectServiceClient.client.factory.create("pageSpecDataObj")
    pageSpecDO.pageSize = 1000
    pageSpecDO.startIndex = 0
    snapshotScopeDO = defectServiceClient.client.factory.create(
        "snapshotScopeSpecDataObj"
    )
    snapshotScopeDO.showSelector = str(snapshot_id)

    # SOAP API を呼び出し
    mergedDefects = defectServiceClient.client.service.getMergedDefectsForSnapshotScope(
        projectIdDO, filterSpecDO, pageSpecDO, snapshotScopeDO
    )
    """

    """
    # cid のインデックスを探す
    # CID リストファイルを開く
    filename = filepath + "cids_of_snapshot_" + str(snapshot_id) + "_list.json"
    with open(filename, "r", encoding="cp932") as f:
        cids_list = json.load(f)

    if cid in cids_list:
        i = cids_list.index(cid)
    else:
        print("[get_mergedDefects_snapshot] cid: {} が見つかりません".format(cid))

    # cid チェック
    print(
        "cid: {}, mergedDefects.mergedDefectIds[i].cid: {}".format(
            cid, mergedDefects.mergedDefectIds[i].cid
        )
    )  # = cid ?
    """

    tmp_dict = {}

    # 最初のスナップショット
    firstDetectedSnapshotId = mergedDefects.mergedDefects[0].firstDetectedSnapshotId
    tmp_dict["firstDetectedSnapshotId"] = firstDetectedSnapshotId

    # 最初のスナップショットの日付(初回検出日: First Snapshot Date)
    firstDetected = mergedDefects.mergedDefects[
        0
    ].firstDetected  # datetime.datetime(2023, 5, 17, 10, ...
    tmp_dict["firstDetected"] = firstDetected

    # 最初のスナップショットのストリーム
    firstDetectedStream = mergedDefects.mergedDefects[0].firstDetectedStream
    tmp_dict["firstDetectedStream"] = firstDetectedStream

    # 最後のスナップショット
    lastDetectedSnapshotId = mergedDefects.mergedDefects[0].lastDetectedSnapshotId
    tmp_dict["lastDetectedSnapshotId"] = lastDetectedSnapshotId

    # 最後のスナップショットの日付(Last Snapshot Date)
    lastDetected = mergedDefects.mergedDefects[0].lastDetected
    tmp_dict["lastDetected"] = lastDetected

    # 最後のスナップショットのストリーム
    lastDetectedStream = mergedDefects.mergedDefects[0].lastDetectedStream
    tmp_dict["lastDetectedStream"] = lastDetectedStream

    """
    # まとめてファイル保存
    filename = filepath + "cids_of_snapshot_" + str(snapshot_id) + "_list.json"
    with open(filename, "w", encoding="cp932", errors='replace') as f:
        json.dump(cids_list, f, ensure_ascii=False, indent=4)
    """

    return tmp_dict


# CID 別 JSON 辞書を作成
def add_cids_to_json(result_dict, mergedDefects_dict):
    """
    機能: get_cid_info 関数の戻り値辞書から、CSV に登録する項目を抽出する
    入力: result_dict, mergedDefects_dict
    出力: -
    戻り値: tmp_list
    """
    # log.logger.info("[add_cids_to_json] 開始")

    tmp_list = []
    # イベント（main が true）
    # "events" > "main" の値が true の時の "eventDescription" 他の値を求める
    for i, defectInstance in enumerate(result_dict["defectInstances"]):
        for j, event in enumerate(defectInstance["events"]):
            if event["main"]:
                tmp_dict = {}

                # cid
                tmp_dict["CID"] = result_dict["cid"]  # 246494

                # ファイル
                tmp_dict["ファイル名"] = event["fileId"][
                    "filePathname"
                ]  # "/p4v/depot/StreamA/iPU/build/src/app/Predict/pd_CentralAbst.cpp"

                # 言語（取得できない）

                # 関数名
                if "functionDisplayName" in defectInstance["function"]:  # キーがないときがある
                    tmp_dict["関数名"] = defectInstance["function"][
                        "functionDisplayName"
                    ]  # "CPdCentralAbst::makeNSCAbnormalPacket(pd_Type_t, unsigned short, ..., unsigned char)"
                else:
                    tmp_dict["関数名"] = "None"

                # 行番号
                tmp_dict["行番号"] = event["lineNumber"]  # 1358

                # 影響度
                tmp_dict["影響度"] = defectInstance["impact"]["displayName"]  # "低"

                # 問題の種類 issueKinds はリスト（"品質"、"セキュリティ"）
                issueKinds_str = ""
                for k, displayName in enumerate(defectInstance["issueKinds"]):
                    if k == 0:
                        issueKinds_str = displayName["displayName"]
                    else:
                        issueKinds_str = (
                            issueKinds_str + "," + displayName["displayName"]
                        )
                tmp_dict["問題の種類"] = issueKinds_str  # "品質"、"セキュリティ"

                # 型
                tmp_dict["型"] = defectInstance["type"]["displayName"]  # "CERT-CPP 式。"

                # チェッカー
                tmp_dict["チェッカー名"] = result_dict["checkerName"]  # "CERT EXP60-CPP"

                # ドメイン
                tmp_dict["ドメイン"] = result_dict["domain"]  # "STATIC_C"

                # ストリーム
                tmp_dict["ストリーム名"] = result_dict["streamId"]["name"]  # "StreamA"

                # メインイベントの説明
                tmp_dict["メインイベントの説明"] = event[
                    "eventDescription"
                ]  # "標準以外のレイアウトをもつ \"xml\" を、実行境界を越えて渡しています。"

                # イベントタグ
                tmp_dict["イベントタグ"] = event["eventTag"]  # "cert_exp60_cpp_violation"

                # カテゴリ
                tmp_dict["カテゴリ"] = defectInstance["category"][
                    "displayName"
                ]  # "コーディング規約違反"

                # ローカル効果
                tmp_dict["ローカル効果"] = defectInstance["localEffect"]  # "CERT 違反。"

                # 説明
                tmp_dict["説明"] = defectInstance[
                    "longDescription"
                ]  # "実行境界を越えて標準以外のレイアウト型オブジェクトを渡してはいけません。"

                """ mergedDefects_dict を追加 """
                # 初回の検出日
                tmp_dict["初回の検出日"] = mergedDefects_dict[
                    "firstDetected"
                ]  # datetime.datetime(20...D6C1C160>)

                # 初回のスナップショットID
                tmp_dict["初回のスナップショットID"] = mergedDefects_dict[
                    "firstDetectedSnapshotId"
                ]  # 13533

                # 初回のストリーム
                tmp_dict["初回のストリーム"] = mergedDefects_dict[
                    "firstDetectedStream"
                ]  # 'StreamB'

                # 直近の検出日
                tmp_dict["直近の検出日"] = mergedDefects_dict[
                    "lastDetected"
                ]  # datetime.datetime(20...D6C1C160>

                # 直近のスナップショットID
                tmp_dict["直近のスナップショットID"] = mergedDefects_dict[
                    "lastDetectedSnapshotId"
                ]  # 13542

                # 直近のストリーム
                tmp_dict["直近のストリーム"] = mergedDefects_dict[
                    "lastDetectedStream"
                ]  # 'StreamB'

                # events > main: true が 複数ある場合
                tmp_list.append(tmp_dict)

    return tmp_list


# リストの差分抽出（未使用）
def get_list_diff(old_list, new_list):
    """
    リストの差分抽出
    """
    log.logger.info("[get_list_diff] 開始")

    diff_list = []

    for new_item in new_list:
        found = False
        for old_item in old_list:
            if old_item["streamname"] == new_item["streamname"]:
                found = True
                diff_item = get_dict_diff(old_item, new_item)
                if diff_item:
                    diff_list.append(diff_item)
                break

        if not found:
            diff_list.append(new_item)

    return diff_list


# 辞書の差分抽出（未使用）
def get_dict_diff(old_dict, new_dict):
    """
    辞書の差分抽出
    """
    log.logger.info("[get_dict_diff] 開始")

    temp_dict = {}
    diff_dict = {}

    for key, new_value in new_dict.items():
        """
        if key not in old_dict:
            diff_dict[key] = new_value
        elif isinstance(new_value, dict) and isinstance(old_dict[key], dict):
            # new_valueが辞書型のデータの場合、かつ、old_dict[key] が辞書型のデータの場合、再帰呼び出し
            diff_value = get_dict_diff(old_dict[key], new_value)
            if diff_value:
                diff_dict[key] = diff_value
        elif old_dict[key] != new_value:
            diff_dict[key] = new_value
        """

        if key not in old_dict:
            # key 'name' が古いリストに無い場合
            diff_dict[key] = new_value
        else:
            # key 'name' が古いリストにある場合
            temp_key = key
            temp_dict[temp_key] = new_value

        if isinstance(new_value, dict) and isinstance(old_dict[key], dict):
            # new_valueが辞書型のデータの場合、かつ、old_dict[key] が辞書型のデータの場合、再帰呼び出し
            diff_value = get_dict_diff(old_dict[key], new_value)

            if diff_value:
                # 差分があった場合
                diff_dict[key] = diff_value

        elif old_dict[key] != new_value:
            # 'name' の値が異なる場合
            # diff_dict[temp_key] = temp_dict[temp_key]
            # diff_dict[key] = new_value
            diff_dict = temp_dict

    return diff_dict


# プロジェクトの検索（未使用）
def has_project(old_list, new_list, projectname):
    """
    プロジェクトの検索
    """
    log.logger.info("[has_project] 開始")

    # old_list
    for proj_dict in old_list:
        found = False
        for key, old_value in proj_dict.items():
            # key = "projectname"
            """ old_value =
            {
                "ProjectA": [
                    {"streamname": {"StreamA": {"snapshotId": [1, 2, 3]}}},
                    {
                        "streamname": {
                            "StreamB": {"snapshotId": [4, 5, 6]}
                        }
                    },
                    {
                        "streamname": {
                            "StreamC": {"snapshotId": [7, 8]}
                        }
                    },
                ]
            }
            """
            for key, value in old_value.items():
                if key == projectname:
                    found = True
                    ret_old_list = old_value[projectname]
                else:
                    ret_old_list = []

    # new_list
    for proj_dict in new_list:
        found = False
        for key, new_value in proj_dict.items():
            # key = "projectname"
            """ new_value =
            {
                "ProjectA": [
                    {"streamname": {"StreamA": {"snapshotId": [1, 2, 3]}}},
                    {
                        "streamname": {
                            "StreamB": {"snapshotId": [5, 6, 7]}
                        }
                    },
                    {
                        "streamname": {
                            "StreamC": {"snapshotId": [7, 8]}
                        }
                    },
                ]
            }
            """
            for key, value in new_value.items():
                if key == projectname:
                    found = True
                    ret_new_list = new_value[projectname]
                else:
                    ret_new_list = []

    # old_value と new_value の値（リスト）を返す
    return ret_old_list, ret_new_list


# 新しいリストに追加された要素を抽出する
def get_diff_list(old_list, new_list):
    """
    機能: 古いリストと新しいリストらを比較し、新しいリストに追加されている要素だけを持つ diff_list を返す
    入力: old_list, new_list
    出力: diff_list
    """
    log.logger.info("[get_diff_list] 開始")

    diff_list = [item for item in new_list if item not in old_list]

    return diff_list


# cid 詳細取得 getStreamDefects
def get_cid_info(defectServiceClient, streamname, cid, filepath):
    """
    機能: cid 詳細の取得
    入力: defectServiceClient インスタンス, streamname, cid, filepath
    出力: v_dict_keylist.json, "cid_info_" + cid + ".json"
    戻り値: result_dict
    """
    # log.logger.info("[get_cid_info] 開始")

    mergedDefectIdDO = defectServiceClient.client.factory.create(
        "mergedDefectIdDataObj"
    )

    mergedDefectIdDO.cid = cid
    streamIdDO = defectServiceClient.client.factory.create("streamIdDataObj")
    streamIdDO.name = streamname
    streamsList = [streamIdDO]
    filterSpecDO = defectServiceClient.client.factory.create(
        "streamDefectFilterSpecDataObj"
    )

    filterSpecDO.includeDefectInstances = True
    filterSpecDO.includeHistory = True
    filterSpecDO.streamIdList = streamsList

    result_dict = {}

    try:
        v = defectServiceClient.client.service.getStreamDefects(
            mergedDefectIdDO, filterSpecDO
        )
        # print("\nv: {}".format(v[0]))

        # Bing
        v_dict = v[0].__dict__

        """ v_dict["__keylist__"] = [
            "checkerName",
            "cid",
            "defectInstances",
            "defectStateAttributeValues",
            "domain",
            "history",
            "id",
            "streamId"
        ]
        """

        # v_dict の __keylist__ を v_dict_keylist.json に書き込む
        # filename = snapshots_dir + "v_dict_keylist.json"
        # with open(filename, "w", encoding="cp932", errors='replace') as f:
        #     json.dump(v_dict["__keylist__"], f, ensure_ascii=False, indent=4)

        # CHatGPT
        # v_json = generate_result_json(v[0])

        """# "history[0].dateCreated" がJSONシリアライズエラーになるので削除する
        modified_v_dict_keylist = [
            "checkerName",
            "cid",
            "defectInstances",
            "defectStateAttributeValues",
            "domain",
            "id",
            "streamId",
        ]

        # 書き換え
        v_dict["__keylist__"] = modified_v_dict_keylist
        """
        if "defectInstances" in v_dict["__keylist__"]:
            # 辞書作成
            result_dict = recursive_dict(v[0])

            # 結果 result_dict を result.json に書き込む
            filename = filepath + "cid_info_" + str(cid) + ".json"
            with open(filename, "w", encoding="cp932", errors="replace") as f:
                enc = json.dump(
                    result_dict, f, ensure_ascii=False, indent=4, default=expireEncoda
                )

    except Exception as err:
        log.logger.error("[get_cid_info] An error occurred: {}".format(err))
        result_dict = {}

    return result_dict


# datetime型を json.dumps したときシリアライズエラーにしない
def expireEncoda(object):
    if isinstance(object, datetime):
        return object.isoformat()


# JSON 辞書を CSVファイルに変換して保存
def json_dic_to_csv(json_dict, filepath):
    """
    機能: JSON 辞書を CSVファイルに変換して保存
    入力: json_dict, filepath
    出力: CSVファイル
    戻り値: なし
    """
    log.logger.info("[json_dic_to_csv] 開始")

    ret = 0
    # CSVファイルに書き込み
    try:
        with open(filepath, "w", newline="", encoding="cp932") as f:
            writer = csv.DictWriter(
                f,
                fieldnames=json_dict[0].keys(),
                doublequote=True,
                quoting=csv.QUOTE_ALL,
            )
            writer.writeheader()
            writer.writerows(json_dict)

    except PermissionError:
        log.logger.error("[json_dic_to_csv] PermissionError: {}".format(filepath))
        ret = 13

    except Exception as err:
        log.logger.error("[json_dic_to_csv] An error occurred: {}".format(err))
        ret = 14

    return ret


# キーの値（プロジェクト名）を探す
def find_key_with_dictionary(json_data, target_dict):
    """
    機能: last_l リストから、与えられたストリーム名を持つプロジェクト名を探してこれを返す
    入力: last_l リスト、ストリーム名辞書 {"streamname": "D-BIPS_DX2"}
    戻り値: last_l リスト上のプロジェクトのインデックス、プロジェクト名（result リスト）
    """
    result = []

    for idx, item in enumerate(json_data):
        if "projectname" in item and isinstance(item["projectname"], dict):
            for value in item["projectname"].values():
                if isinstance(value, list):
                    # 値がリストの場合

                    for sub_item in value:
                        # print(sub_item)
                        """ sub_item =
                        {'streamname': {'StreamA': {'snapshotId': [12918, 12947, ..., 13541]}}}
                        """
                        """ sub_item.values() =
                        [{'StreamA': {'snapshotId': [12918, 12947, ..., 13541]}}]
                        """
                        # print(stream_name in sub_item["streamname"])
                        if (
                            isinstance(sub_item, dict)
                            # 項目が辞書の場合
                            and target_dict["streamname"] in sub_item["streamname"]
                            # 項目が検索対象の辞書と同じキーを持つ場合
                        ):
                            # result.append(item["projectname"])
                            for prj in item.values():
                                print(prj)
                                for prj_name in prj.keys():
                                    print(prj_name)

                            result.append(prj_name)
                            break

                    else:
                        continue
                    break

                else:
                    continue

            else:
                continue
            break

        else:
            continue

    else:
        print("見つかりませんでした")

    return idx, result


# ストリーム名の（リストの）インデックスを探す（未確認）
def find_idx_in_list(json_data, projectname, streamname):
    """
    機能: json_data リストから、与えられたストリーム名のインデックスを返す
    入力: json_data リスト、プロジェクト名、ストリーム名
    戻り値: json_data リスト上のストリーム名のインデックス
    """

    for index, item in enumerate(json_data[projectname]):
        if streamname in item["streamname"]:
            return index

    return -1


# ファイルの圧縮
def zip_files(files, zip_file_name_path):
    """
    機能: ファイルを圧縮し、ZIP形式の圧縮ファイルをそのファイルのあるディレクトリに保存します
    入力:
      files: 圧縮したいファイルのリスト（['/path/to/file1.txt', '/path/to/file2.txt', '/path/to/file3.txt']）
      zip_file_name_path: パス付き圧縮後のファイル名 ('/path/to/files.zip')
    出力: ZIP形式圧縮ファイル（'/path/to/files.zip'）
    戻り値: 圧縮ファイルへのパス（'/path/to/files.zip'）
    """
    log.logger.info("[zip_files] 開始")

    with zipfile.ZipFile(
        zip_file_name_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6
    ) as zip_file:
        for file in files:
            # ディレクトリ名
            # dir_name = os.path.dirname(file)

            # 拡張子ありのファイル名
            file_name_base_with_ext = os.path.basename(file)

            # ZIPファイルへのパス
            # zip_file_path = os.path.join(dir_name, file_name_base_with_ext)

            # 圧縮して保存
            zip_file.write(file, arcname=file_name_base_with_ext)

    return zip_file_name_path


# 辞書のパース Qiita <- stackoverflow
def recursive_dict(d):
    """
    取得したレスポンスを辞書型に整形
    """
    # log.logger.info("[recursive_dict] 開始")

    out = {}
    for k, v in asdict(d).items():
        if hasattr(v, "__keylist__"):
            out[k] = recursive_dict(v)
        elif isinstance(v, list):
            out[k] = []
            for item in v:
                if hasattr(item, "__keylist__"):
                    out[k].append(recursive_dict(item))
                else:
                    out[k].append(item)
        else:
            out[k] = v

    return out


# 辞書のパース Genie (ChatGPT)
def recursive_dict_2(d):
    """
    Convert a response object to a dictionary recursively.
    """
    out = {}
    for k, v in d.items():
        if isinstance(v, dict):
            out[k] = recursive_dict(v)
        elif isinstance(v, list):
            out[k] = [
                recursive_dict(item) if isinstance(item, dict) else item for item in v
            ]
        else:
            out[k] = v
    return out


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
def main(stream_name, snapshot_id, sender_email):
    """
    機能:
        追加されたスナップショットの指摘をCSV、ZIPファイルに保存する。
        引数に、ストリーム名とスナップショットIDが与えられた場合は、そのスナップショットの指摘を、
        引数が無い場合は、全グループを巡回し、新しく追加されたスナップショットの指摘を
        対象に、すべてのCIDの情報を取得し、CSVファイルとその圧縮ファイル（ZIPファイル）を生成する
    引数:
        stream_name: ストリーム名 / None
        snapshot_id: スナップショットID / None
        sender_email: メール送信者 / None
    戻り値:
        error_level: (3桁固定とする)
          000: 正常終了
          700: last.json ファイルが無い
          701: ZIPファイルがない
          702: last_l が空（[]）
          703: ストリームが存在しない可能性
          704: -
          705: 引数の数が不一致
          706: 指摘件数がゼロ/スナップショットIDが存在しない
          707: CID 詳細が空 (get_cid_info() の戻り値)
          708: 環境変数エラー、KeyError(辞書)
          709: （ライセンスを持たない）認定ユーザー以外からの要求
        zip_file_path: 最後に圧縮したZIPファイルのパス
    """
    log.logger.info("[main] 開始")

    # error_level 初期化
    error_level = "0"

    # 初期設定（オブジェクト生成）
    defectServiceClient, configServiceClient = init()

    """ 前回と今回のプロジェクトリストについて
    ・今回のリスト: last.json
    ・前回のリスト: last_before_last.json
    スクリプトの最初に今回のリストを last_before_last.json の名前で（上書き）保存する
    """

    # 引数チェック
    if stream_name == "None" and snapshot_id == "None":
        # 全グループが対象
        # 全プロジェクトの情報が記載された今回のリスト last_list を作成する（last_list.json 生成）
        # その過程で、スナップショットの指摘一覧（JSON、CSV、ZIP）を生成する
        log.logger.info("[main] 全グループを対象にします")

        # 今回のプロジェクト一覧取得 projects_list.json 生成
        projects_l = get_all_projects(configServiceClient, snapshots_dir)
        """ projects_l = [
            {
                "project_id": 10078,
                "project_name": "ProjectA"
            },
            {
                "project_id": 10080,
                "project_name": "ProjectB"
            },
            ...
        ]
        """

        # 今回のストリーム一覧取得 streams_list.json 生成
        streams_l = get_all_streams(configServiceClient, snapshots_dir)
        """ streams_l = [
            "1.3.3.30051",
            "additional_models_master",
            "StreamB",
            "ProjectB",
            "ProjectB_2022",
            ...
        ]
        """

        # 今回の全プロジェクトのストリーム一覧（スナップショットID含まない）作成（streams_of_projects_list.json 生成）
        # および各プロジェクトのストリーム一覧（スナップショットID含まない）作成（streams_of_<projectname>_list.json 生成）
        streams_of_projects_l = get_all_streams_of_each_project(
            configServiceClient, snapshots_dir
        )
        """ streams_of_projects_l = [
            {
                "projectname": {
                    "ProjectA": [
                        {
                            "streamname": "StreamA"
                        },
                        {
                            "streamname": "StreamB"
                        }
                    ]
                }
            }
            ...
        ]
        """

        error_level, zip_file_path = make_last_list(
            configServiceClient,
            defectServiceClient,
            streams_of_projects_l,
            snapshots_dir,
        )

    else:
        # 特定ストリームのスナップショットIDが対象
        # TODO 全プロジェクトの情報が記載された今回のリスト last_list を更新する（last_list.json 更新）
        # その過程で、スナップショットの指摘一覧（JSON、CSV、ZIP）を生成する

        # 認定ユーザーの有効無効判定
        # cov_auto_5.bat から呼び出される場合はダミーアドレスなのでチェックをスキップ
        if sender_email == "noreply@example.com":
            # ダミーアドレスの場合は認証チェックをスキップ
            log.logger.info("[main] 認証チェックをスキップ（ダミーアドレス: %s）", sender_email)
            pass
        elif AUTH_USER_ENABLE:
            # 利用者が認定ユーザであるか判定する
            # 利用者（の電子メール）が認定ユーザーの場合、ユーザーIDを得る
            covapi = covautolib_3.COVApi()
            user_id = covapi.check_user_id(sender_email)

            if user_id is None:
                # 認定ユーザーではない
                error_level = "709"
                zip_file_path = "Requests_from_non-authorized_user.zip"

                return error_level, zip_file_path
        
        else:
            # 利用者が認定ユーザであるか判定しない
            pass
        
        # 利用者が認定ユーザであるか判定しない / 認定ユーザーである
        log.logger.info("[main] 特定ストリームのスナップショットIDを対象にします")
        error_level, zip_file_path = add_snapshot_to_last_list(
            defectServiceClient,
            snapshots_dir,
            stream_name,
            snapshot_id,
        )

    return error_level, zip_file_path


# -----------------------------------------------------------------------------
if __name__ == "__main__":
    #
    # 引数チェック
    args = sys.argv
    len_args = len(args)
    print("[__main__] 引数チェック前 len_args: {}".format(len_args))

    if len_args == 1:
        # 引数の数が 0 （スクリプト名のみ）の場合、全プロジェクトを巡回する
        stream_name = "None"
        snapshot_id = "None"
        sender_email = "None"

    elif len_args == 4:
        # 引数の数が 3 （判定値は 4）の場合は、特定ストリームのスナップショットIDについて実行する
        stream_name = args[1]
        snapshot_id = args[2]
        sender_email = args[3]

    else:
        # 引数の数が 0、4 以外の場合は、何もしない
        print("\n")
        print("  Arguments mismatch:")
        print(
            "     Usage [Windows @build server]: \n"
            + "       $ python / py "
            + args[0]
            + " stream_name snapshot_id sender_email"
            + "\nOR\n"
            "     Usage [Windows @local PC]: \n"
            + "       $ python3 "
            + args[0]
            + " stream_name snapshot_id sender_email"
            + "\n"
        )

        # 異常終了：引数の数が不一致
        error_level = "705"
        print("[__main__] 引数の数が不一致なので退出します")
        print("[__main__] 引数の数が不一致 error_level: {}".format(error_level))

        # ZIP形式圧縮ファイルのデフォルト
        zip_file_path = "Mismatched_number_of_arguments.zip"

        # ZIPファイルのパスをバッチファイルに渡して終了
        print(zip_file_path)
        sys.exit(error_level)

    # 引数表示
    print(
        "stream_name: {}, snapshot_id: {}, sender_email: {}".format(
            stream_name, snapshot_id, sender_email
        )
    )

    # 共通
    # os.sep は、Windows: \\, Linux: /
    sep = os.sep
    # base_dir はカレントディレクトリ "/home/username/cov_auto"
    base_dir = "." + sep

    # log ディレクトリが存在しないなら作成
    log_dir = base_dir + "log" + sep
    if not os.path.isdir(log_dir):
        os.mkdir(log_dir)

    # snapshots ディレクトリが存在しないなら作成
    snapshots_dir = base_dir + "snapshots" + sep
    if not os.path.isdir(snapshots_dir):
        os.mkdir(snapshots_dir)

    # logger
    # LOGGER クラスのインスタンス作成
    log = covautolib_3.LOGGER_2("cov_snap_py", snapshot_id)
    log.logger.info("[__main__] ログ開始します")

    # ログ出力テスト
    log.logger.debug("ログ出力テスト")
    log.logger.debug("Debug")
    log.logger.error("Error")
    log.logger.info("Info")
    log.logger.warning("Warning\n")
    log.logger.info("[main] 引数チェック通過")
    log.logger.info("[main] stream_name: {}".format(stream_name))
    log.logger.info("[main] snapshot_id: {}".format(snapshot_id))
    log.logger.info("[main] sender_email: {}".format(sender_email))

    # main() 開始
    log.logger.info("[__main__] main() を呼び出します")
    error_level, zip_file_path = main(stream_name, snapshot_id, sender_email)

    # main() 終了
    log.logger.info(
        "[__main__] main() から戻ってきました。error_level: {}, ZIPファイル: {}".format(
            error_level, zip_file_path
        )
    )

    # 異常判定
    if error_level != "0":
        # 異常終了
        log.logger.error(
            "[__main__] main() を異常終了しました。戻り値: {} ('last.json' が更新されている場合は途中のエラー番号です)".format(
                error_level
            )
        )
    else:
        # 正常終了
        log.logger.info("[__main__] main() を正常終了しました。戻り値: {}".format(error_level))

    # sys.exit(error_level) で呼び出し元に error_level が渡らないので、
    # error_level と、ZIPファイルのパスをバッチファイルに渡して終了
    print(error_level, zip_file_path)
    sys.exit(error_level)
