-- ========================================
-- Google スプレッドシート スキーマ定義
-- 注: これはGoogle スプレッドシートの構造を表すための疑似SQL
-- 実際はスプレッドシートのシートとカラムとして実装
-- ========================================

-- ========================================
-- メニューシート (Sheet: menus)
-- ========================================
-- カラム構成:
-- A: id (TEXT) - UUID形式
-- B: name (TEXT) - メニュー名
-- C: price (NUMBER) - 価格
-- D: duration (NUMBER) - 所要時間（分）
-- E: category (TEXT) - カテゴリ
-- F: is_active (BOOLEAN) - 有効フラグ
-- G: created_at (DATETIME) - 作成日時
-- H: updated_at (DATETIME) - 更新日時

CREATE TABLE IF NOT EXISTS menus (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    price INTEGER NOT NULL CHECK (price >= 0 AND price <= 999999),
    duration INTEGER NOT NULL CHECK (duration > 0),
    category TEXT NOT NULL CHECK (category IN ('nail', 'care', 'art', 'option', 'set', 'other')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- データ検証ルール（Google スプレッドシートで設定）
-- name: 最大100文字
-- price: 0以上999,999以下の整数
-- duration: 1以上の整数
-- category: 指定された値のみ

-- ========================================
-- 伝票シート (Sheet: receipts)
-- ========================================
-- カラム構成:
-- A: id (TEXT) - UUID形式
-- B: receipt_number (TEXT) - 伝票番号 (YYYYMMDD-0001形式)
-- C: customer_name (TEXT) - 顧客名
-- D: service_date (DATETIME) - 施術日時
-- E: items (TEXT) - JSON形式の明細データ
-- F: total_amount (NUMBER) - 合計金額
-- G: staff_name (TEXT) - 担当スタッフ名
-- H: payment_method (TEXT) - 支払い方法
-- I: memo (TEXT) - メモ
-- J: created_at (DATETIME) - 作成日時
-- K: updated_at (DATETIME) - 更新日時

CREATE TABLE IF NOT EXISTS receipts (
    id TEXT PRIMARY KEY,
    receipt_number TEXT UNIQUE NOT NULL,
    customer_name TEXT NOT NULL,
    service_date TIMESTAMP NOT NULL,
    items TEXT NOT NULL, -- JSON配列として保存
    total_amount INTEGER NOT NULL CHECK (total_amount >= 0),
    staff_name TEXT NOT NULL,
    payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'credit', 'paypay', 'other')),
    memo TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- インデックス定義（Google スプレッドシートではフィルタビューで実現）
-- 伝票番号での検索用
-- 顧客名での検索用
-- 施術日での範囲検索用
-- スタッフ名での検索用

-- ========================================
-- 集計用ビュー（Google スプレッドシートのピボットテーブル）
-- ========================================

-- 日別売上集計
CREATE VIEW daily_sales AS
SELECT 
    DATE(service_date) as sales_date,
    COUNT(*) as receipt_count,
    SUM(total_amount) as total_sales,
    AVG(total_amount) as average_per_receipt
FROM receipts
GROUP BY DATE(service_date)
ORDER BY sales_date DESC;

-- メニュー別売上ランキング
-- 注: itemsカラムのJSON解析が必要
CREATE VIEW menu_ranking AS
WITH menu_sales AS (
    -- JSONから展開したメニュー別集計
    SELECT 
        menu_id,
        menu_name,
        SUM(quantity) as sold_count,
        SUM(subtotal) as total_sales
    FROM receipts_items_expanded
    GROUP BY menu_id, menu_name
)
SELECT 
    ms.*,
    m.category,
    RANK() OVER (ORDER BY ms.total_sales DESC) as rank
FROM menu_sales ms
JOIN menus m ON ms.menu_id = m.id
ORDER BY rank;

-- 支払い方法別集計
CREATE VIEW payment_method_breakdown AS
SELECT 
    payment_method,
    COUNT(*) as count,
    SUM(total_amount) as amount,
    ROUND(100.0 * SUM(total_amount) / (SELECT SUM(total_amount) FROM receipts), 2) as percentage
FROM receipts
GROUP BY payment_method
ORDER BY amount DESC;

-- ========================================
-- ローカルストレージ (IndexedDB) スキーマ
-- ========================================

-- オブジェクトストア: menus
-- キー: id
-- インデックス: category, is_active

-- オブジェクトストア: receipts
-- キー: id
-- インデックス: receipt_number, customer_name, service_date, sync_status

-- オブジェクトストア: sync_queue
-- 同期待ちのデータを管理
CREATE TABLE sync_queue (
    id TEXT PRIMARY KEY,
    entity_type TEXT NOT NULL CHECK (entity_type IN ('menu', 'receipt')),
    entity_id TEXT NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('create', 'update', 'delete')),
    data TEXT NOT NULL, -- JSON形式
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_retry_at TIMESTAMP
);

-- オブジェクトストア: metadata
-- アプリケーションのメタデータ
CREATE TABLE metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- データ整合性とパフォーマンスのための設計方針
-- ========================================

-- 1. Google スプレッドシートの制限事項
--    - 1シートあたり500万セル（約10万行のデータ）
--    - API呼び出しは1日あたり制限あり
--    - バッチ処理で効率化

-- 2. データ分割戦略
--    - 年度ごとにスプレッドシートを分割
--    - アーカイブ用シートの作成

-- 3. パフォーマンス最適化
--    - 頻繁にアクセスするデータはIndexedDBにキャッシュ
--    - バックグラウンド同期で遅延を隠蔽

-- 4. データ整合性
--    - 楽観的ロックによる競合制御
--    - タイムスタンプベースの競合解決