# Changelog

すべての重要な変更はこのファイルに記録されます。

このフォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/) に基づいており、
このプロジェクトは [Semantic Versioning](https://semver.org/lang/ja/) に準拠しています。

## [Unreleased]

### 追加
- README/README_EN.md - COVLint連携情報セクション追加
  * CovSnapのCSVファイルをVSCode拡張機能COVLintで活用できることを説明
  * VS Marketplace と GitHub へのリンクを追加
  * ソースコード上での指摘表示、オフライン作業のメリットを記載
- coverity_rest_lib.py - Coverity Connect REST APIクライアントライブラリ
  * CoverityRestClientクラスを独立したモジュールとして分離
  * プロジェクト/ストリーム/スナップショット/指摘情報の取得機能
  * ページング処理対応（10,000件超の大量データ対応）

### 変更
- README/README_EN.md - 詳細情報取得の説明を改善
  * "個別CIDの詳細情報" → "ソースコード画面に表示される詳細情報" に変更
  * より分かりやすい表現に改善
- cov_snap_standalone.py
  * coverity_rest_lib から CoverityRestClient をインポート
  * スタンドアロンツールとして独立動作が可能に

### 修正
- README/README_EN.md - VS Marketplace リンク訂正
  * keides.covlint → keides2.covlint に修正
  
### アーカイブ
- README_ja.md を archive/ に移動
  * メンテナンスの手間を削減（README.md を日本語版メインとして使用）
- cov_snap.py (3,596行) を src/archive/ に移動
  * 旧バージョンを参照用として保存
  * 新アーキテクチャ移行のため、アクティブな依存関係から除外

## [2.1.0] - 2026-01-22

### 追加
- pytest包括的テストスイート実装（18テスト、100%成功）
  * Phase 1: ユニットテスト 14テスト
  * Phase 2: Mode 2統合テスト 2テスト
  * Phase 3: E2Eテスト 1テスト
  * Phase 4: 大規模データテスト 1テスト
- docs/PYTEST_TEST_STRUCTURE.md - pytest構造ドキュメント（600行超）
- docs/TEST_REPORT_2026-01-22.md - 完全なテストレポート
- Mode 2（認定ユーザー配信）の実メール配信テスト完了

### 修正
- **UTF-8エンコーディング問題の解決**
  * subprocess通信: UTF-8エンコーディング明示的指定
  * ロガー設定: io.TextIOWrapperでUTF-8強制
  * 効果: UNCパス（日本語含む）の処理が安定化
- **環境変数の正しい処理**
  * COVAUTHKEY: 環境変数から正しいAPIキーを読み込み
  * プロキシ設定: HTTP_PROXY/HTTPS_PROXYを優先使用
  * 設定検証: 起動時に必須環境変数をチェック
- **プロキシ設定の修正**
  * 区切り文字の修正（正しいURL形式に統一）
  * 企業ネットワークでのREST API接続が安定
- **CSVフォーマットの修正**
  * エンコーディング: Shift-JIS（本番環境に合わせる）
  * ヘッダー: なし（データ行のみ）
  * フォーマット: `Type,Email` (カンマ区切り)

### ドキュメント
- VERSION.md更新: v2.1.0の変更内容を追加
- README.md更新: プロキシ設定を一般化、環境変数の説明を強化
- QUICKSTART.md更新: プロキシ設定を一般化
- TROUBLESHOOTING.md更新: トラブルシューティングガイド強化

### 改善効果
- 本番環境での安定稼働保証
- エンコーディングエラーゼロ
- メール配信成功率100%
- テストカバレッジ完全化

## [2.0.0] - 2026-01-19

### 追加
- VERSION.mdのプレースホルダー方式導入（`{{VERSION}}`, `{{PACKAGE_NAME}}`, `{{RELEASE_DATE}}`）
- create_package.ps1にdocstring風ヘルプコメント追加
- packaging/verify_*/ を.gitignoreに追加
- Get-Helpコマンドサポート（-Examples, -Detailed, -Full）

### 変更
- **[BREAKING]** ストリーム名ベース引数に簡素化
  * MODE 1: 4引数 → 3引数（group_name削除）
  * MODE 2: 3引数 → 2引数（group_name削除）
- **[BREAKING]** アドレスファイル構造変更
  * ディレクトリ: `address/` → `address_stream/`
  * ファイル名: `{group_name}_address.csv` → `{stream_name}_address.csv`
- 用語統一: 「個人実行/チーム配信」→「個人利用/チーム利用」
- create_package.ps1のパラメータ改善
  * `-CleanTemp` → `-CleanBuild`
  * `-Version`パラメータを必須化
- メール件名からgroup_name削除（stream_nameのみ）

### 削除
- **[BREAKING]** group_name引数を完全削除
- 5引数パターンの後方互換性サポート削除（警告のみ残存）

### ドキュメント
- README.mdとQUICKSTART.mdをv2.0.0仕様に全面改訂
- PACKAGING_GUIDE.mdをプレースホルダー方式に対応
- VERSION.mdの自動生成化
- 実行例をすべてストリーム名ベースに更新

### パッケージング
- パッケージサイズ: 73.12 KB
- 配布パッケージ: `cov_snap_toolkit_v2.0.0_20260119.zip`

## [1.1.0] - 2026-01-15

### 追加
- 引数0の場合のエラー処理追加（エラーコード714: 全グループ巡回未実装）
- アドレスファイルベース統一認証を実装（MODE 1/2共通）

### 変更
- **[BREAKING]** MODE 1の引数順を変更: `group_name stream_name snapshot_id sender_email`（group_nameを第1引数に）
- **[BREAKING]** MODE 2の引数順を変更: `group_name stream_name snapshot_id`（group_nameを必須化）
- MODE 1認証方式をCOVApiからアドレスファイルベースに変更
- SOAP API関数に非推奨コメントを追加（全グループ巡回用として保持）

### 削除
- **[BREAKING]** MODE 2の2引数パターンを削除（group_name自動抽出機能を削除）

### ドキュメント
- README.mdに使い方セクションを追加
- QUICKSTART.mdのMODE 1/2説明を更新
- tests/README.mdの認証設計思想セクションを更新
- tests/TEST_CASES.mdのテストケースと実行例を更新

### テスト
- 引数0のエラーハンドリングテスト追加（TC6-1）
- MODE 1/2の実環境テスト実施（security/cov_auto/50758）
- すべてのテストケースが正常動作を確認

## [1.0.0] - 2026-01-06

### 追加
- REST API v2完全対応
- ページング処理実装（10,000件超対応）
- 詳細情報取得機能追加（5フィールド）
- 4つのテストスクリプト追加

### 変更
- SOAP APIからREST API v2に完全移行
- パフォーマンス大幅向上（Stage 1: 4-5倍高速化）
- 予測可能な実行時間（0.28秒/CID）

### 削除
- SOAP API依存を100%削除

### ドキュメント
- REST_API_MIGRATION_COMPLETE.md作成（約1000行）
- TEST_SCRIPTS_GUIDE.md作成（約600行）
- REST_API_MIGRATION_SUMMARY.md作成（約300行）

## [0.9.0] - 2025-12-XX

### 追加
- 初期バージョン
- SOAP API対応
- 基本的なスナップショット取得機能

[Unreleased]: https://github.com/keides2/cov_snap/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/keides2/cov_snap/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/keides2/cov_snap/compare/v0.9.0...v1.0.0
[0.9.0]: https://github.com/keides2/cov_snap/releases/tag/v0.9.0
