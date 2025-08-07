# データフロー図

## システム全体のデータフロー

```mermaid
graph TB
    subgraph "クライアント層"
        A[ユーザー<br/>タブレット/スマホ]
        B[React PWA<br/>フロントエンド]
        C[IndexedDB<br/>ローカルストレージ]
        D[Service Worker<br/>同期マネージャー]
    end
    
    subgraph "ネットワーク層"
        E[CDN<br/>GitHub Pages]
        F[Google OAuth<br/>認証サービス]
    end
    
    subgraph "データ層"
        G[Google Sheets API]
        H[Google スプレッドシート<br/>永続化ストレージ]
    end
    
    A --> B
    B <--> C
    B <--> D
    B <--> E
    B <--> F
    D <--> G
    G <--> H
    F --> G
```

## ユーザー操作フロー

### 1. 伝票作成フロー

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant F as フロントエンド
    participant L as LocalStorage
    participant S as Service Worker
    participant G as Google Sheets API
    participant D as スプレッドシート
    
    U->>F: 伝票作成開始
    F->>F: フォーム表示
    U->>F: メニュー選択
    F->>F: 金額自動計算
    U->>F: 顧客情報入力
    F->>L: 自動保存(30秒毎)
    U->>F: 保存ボタン押下
    F->>L: 伝票データ保存
    F->>S: 同期リクエスト
    
    alt オンライン時
        S->>G: データ送信
        G->>D: スプレッドシート更新
        D-->>G: 更新完了
        G-->>S: レスポンス
        S-->>F: 同期完了通知
        F-->>U: 保存完了表示
    else オフライン時
        S->>S: 同期キューに追加
        S-->>F: オフライン保存通知
        F-->>U: オフライン保存表示
    end
```

### 2. データ同期フロー

```mermaid
sequenceDiagram
    participant S as Service Worker
    participant L as LocalStorage
    participant G as Google Sheets API
    participant D as スプレッドシート
    
    Note over S: オンライン復帰検知
    S->>L: 未同期データ取得
    L-->>S: 未同期データリスト
    
    loop 各未同期データ
        S->>G: データ送信
        G->>D: データ書き込み
        
        alt 成功
            D-->>G: 書き込み完了
            G-->>S: 成功レスポンス
            S->>L: 同期フラグ更新
        else 競合発生
            D-->>G: 競合エラー
            G-->>S: 競合データ
            S->>S: 競合解決処理
            S->>G: マージデータ送信
        else API制限
            G-->>S: レート制限エラー
            S->>S: 待機後リトライ
        end
    end
    
    S->>L: 同期完了状態更新
```

### 3. 売上分析フロー

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant F as フロントエンド
    participant C as キャッシュ
    participant G as Google Sheets API
    participant D as スプレッドシート
    
    U->>F: 売上分析画面表示
    F->>C: キャッシュ確認
    
    alt キャッシュ有効
        C-->>F: キャッシュデータ
        F-->>U: 即座に表示
        F->>G: バックグラウンド更新
    else キャッシュ無効
        F->>G: データ取得要求
        G->>D: クエリ実行
        D-->>G: 売上データ
        G-->>F: 集計データ
        F->>C: キャッシュ更新
        F-->>U: 分析結果表示
    end
```

## エラーハンドリングフロー

```mermaid
flowchart TD
    A[API呼び出し] --> B{成功?}
    B -->|Yes| C[正常処理]
    B -->|No| D{エラー種別}
    
    D -->|認証エラー| E[再認証要求]
    D -->|ネットワークエラー| F[オフライン処理]
    D -->|レート制限| G[待機後リトライ]
    D -->|データ競合| H[競合解決処理]
    
    E --> I[ユーザー認証画面]
    F --> J[ローカル保存]
    G --> K[指数バックオフ]
    H --> L[最新データ優先]
    
    I --> A
    J --> M[同期キュー追加]
    K --> A
    L --> A
```

## データフローの特徴

1. **オフラインファースト設計**
   - すべての操作はまずローカルで実行
   - バックグラウンドで非同期同期

2. **楽観的UI更新**
   - ユーザー操作は即座に反映
   - エラー時のみロールバック

3. **自動リトライメカニズム**
   - ネットワークエラー時の自動再試行
   - 指数バックオフによる負荷分散

4. **競合解決戦略**
   - タイムスタンプベースの解決
   - 最新データ優先原則
   - 変更履歴の保持