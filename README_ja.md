# cov_snap

Coverity Connect サーバーからスナップショットを取得します。
bug_report 実行環境がある場合は、ChatGPT を利用したバグレポートを作成することができます（bug_report と連携します）。

## 概要

cov_snap は Coverity Connect サーバー（CC）に登録されているすべてのスナップショットの指摘を抽出するスクリプトです。ハンバーガーメニューからエクスポートしても取得できないソースコードビューのマイルストーン等の指摘も取得できます。

また、Azure OpenAI Service を利用して、指摘内容をCSVファイルから詳細なレポートを作成することもできます（bug_report_2.py が必要）。

## 機能

### メール送信による自動実行
Outlook を使用して、件名の先頭を識別子 `[cov_snap]` で始まり、空白区切りで引数を指定した内容のメールを送信することで、このバッチファイルが起動します（Outlook VBA が必要）。

### 対応する実行パターン

#### 3引数モード
- CC から指摘を取得（cov_snap）、bug_report を起動、CSVファイル（圧縮したZIPファイル）を送信者のみに返信
- ソースコードは GitLab から取得しません
```
[cov_snap] cc_stream_name 14090
```
```bash
cov_snap_2.bat cc_stream_name 14090 sender@example.com
```

#### 4引数モード
- CC から指摘を取得（cov_snap）、bug_report を起動、CSVファイル（圧縮したZIPファイル）をアドレスファイルに登録されたメールアドレスに返信
- ソースコードは GitLab から取得しません
```
[cov_snap] gitlab_group_name cc_stream_name 14090
```
```bash
cov_snap_2.bat gitlab_group_name cc_stream_name 14090 sender@example.com
```

#### 7引数モード
- ソースコードを GitLab から取得し、cov_snap, bug_report を起動、CSVファイル（圧縮したZIPファイル）をアドレスファイルに登録されたメールアドレスに返信
```
[cov_snap] gitlab_group_name gitlab_project_name gitlab_branch_name cc_group_name cc_stream_name 15076 sender@example.com
```
```bash
cov_snap_2.bat gitlab_group_name gitlab_project_name gitlab_branch_name cc_group_name cc_stream_name 15076 sender@example.com
```

#### 8引数モード（Perforce対応）
- ソースコードを Perforce から取得し、cov_snap を起動、CSVファイル（圧縮したZIPファイル）をアドレスファイルに登録されたメールアドレスに返信
- bug_report は起動しません
```
[cov_snap] p4_group_name //depot/p4_group_name/ head cc_group_name cc_stream_name 15048 sender@example.com
```

## 必要な環境

### システム要件
- Windows 10 以降
- Python 3.8+
- Git（GitLab連携時）
- Perforce P4 CLI（Perforce連携時）
- Microsoft Outlook（メール送信時）

### 必要なディレクトリ
以下のディレクトリが必要です：
```
c:\cov\
c:\cov\groups\
c:\cov\log\
S:\path\to\config\
S:\path\to\address\
```

### Python モジュール
以下のPythonモジュールが必要です：

#### 必須モジュール
```bash
pip install suds-community
pip install requests
pip install pandas
pip install openpyxl
```

#### Coverity Connect API用ライブラリ
```bash
# このスクリプトは、別リポジトリの covautolib パッケージを利用します
# 事前に covautolib をインストールしてください

# GitHubからクローンしてインストールする場合
git clone https://github.com/keides2/covautolib.git
cd covautolib
pip install -e .

# または、PYTHONPATH で指定する場合
# Windows (コマンドプロンプト)
set PYTHONPATH=C:\path\to\covautolib\parent\directory

# Linux (ターミナル)
export PYTHONPATH=/path/to/covautolib/parent/directory
```

**注意**: `covautolib` は別途インストールが必要な依存ライブラリです。詳細は [covautolib リポジトリ](https://github.com/keides2/covautolib) を参照してください。

#### covautolib_3 への依存
`cov_snap.py` は `from covautolib import covautolib_3` を実行しており、`covautolib_3` が Python モジュールとして解決できることが必須です。

環境例:

```powershell
# cov_snap_pub と同階層にある covautolib_pub を開発インストール
pip install -e ..\covautolib_pub

# もしくは一時的に PYTHONPATH に追加
$env:PYTHONPATH = "C:\Users\HP\Docs\Security\covautolib_pub"
```

```bash
# Linux/macOS の例
pip install -e ../covautolib_pub
export PYTHONPATH="$(pwd)/../covautolib_pub"
```



### 環境変数
以下の環境変数の設定が必要です：
```bash
# Coverity Connect認証情報
set COVAUTHUSER=your_username
set COVAUTHKEY=your_auth_key

# プロキシ設定（必要な場合）
set HTTP_PROXY=http://proxy.example.com:port/
set HTTPS_PROXY=http://proxy.example.com:port/
```

## 設定ファイル

### last.json
初回実行時は空の配列 `[]` で開始されます。実行後は実際のプロジェクト・ストリーム・スナップショット情報で更新されます。

### アドレスファイル
グループ別のメール送信先を管理：
```
group_name_address.csv
group_name_address_auth.csv  # 認定ユーザーのみ
```

## API通信
- すべての情報は SOAP API を使用して取得されます（mergeKey による結合も実行）
- CSV ファイルを生成し、ZIP ファイルに圧縮します
- 結果は CC 画面の設定（歯車アイコン）で「詳細ビュー表示」にチェックした状態で取得した結果と同じです

## 注意事項
- Coverity ライセンス数の制限により、**ライセンスを保有する認定ユーザーのみ**が指摘結果を取得できます
- CC に登録されている認定ユーザーのみに配信されます
- このバッチファイルは Outlook VBA `ThisOutlookSession_2.vba` から起動されます

## 単体実行
Python スクリプト `cov_snap.py` を直接起動する場合、メールによる配信は行われません。

引数なしで実行すると全プロジェクトを検索しますが、処理時間が長く、途中で異常終了する可能性があるため、全プロジェクトを検索する場合は `cov_snap.py` を直接実行してください。

## ライセンス
MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照してください。

## 作者
Keisuke Shimatani (keides2)
