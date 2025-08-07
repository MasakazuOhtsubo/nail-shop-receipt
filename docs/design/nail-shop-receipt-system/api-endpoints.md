# API エンドポイント仕様

## 概要

このAPIは、Google Sheets APIをラップし、フロントエンドアプリケーションに統一的なインターフェースを提供します。すべてのエンドポイントは、Service Worker内で実装され、オフライン対応とキャッシュ機能を提供します。

## 基本仕様

### ベースURL
```
/api/v1
```

### 共通ヘッダー
```http
Content-Type: application/json
Authorization: Bearer {google-access-token}
X-Request-ID: {uuid}
```

### 共通レスポンス形式
```json
{
  "success": true,
  "data": {},
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### エラーレスポンス形式
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "エラーメッセージ",
    "details": {}
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### エラーコード一覧
- `AUTH_ERROR`: 認証エラー
- `VALIDATION_ERROR`: バリデーションエラー
- `NOT_FOUND`: リソースが見つかりません
- `CONFLICT`: データ競合
- `RATE_LIMIT`: レート制限
- `NETWORK_ERROR`: ネットワークエラー
- `SYNC_ERROR`: 同期エラー
- `INTERNAL_ERROR`: 内部エラー

## 認証エンドポイント

### Google OAuth認証開始
```http
GET /api/v1/auth/google
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "authUrl": "https://accounts.google.com/o/oauth2/v2/auth?..."
  }
}
```

### OAuth コールバック処理
```http
POST /api/v1/auth/callback
```

**リクエスト**
```json
{
  "code": "authorization-code",
  "state": "csrf-token"
}
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "accessToken": "access-token",
    "refreshToken": "refresh-token",
    "expiresAt": "2024-01-01T00:00:00Z",
    "user": {
      "email": "user@example.com",
      "name": "ユーザー名"
    }
  }
}
```

### トークンリフレッシュ
```http
POST /api/v1/auth/refresh
```

**リクエスト**
```json
{
  "refreshToken": "refresh-token"
}
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "accessToken": "new-access-token",
    "expiresAt": "2024-01-01T00:00:00Z"
  }
}
```

### ログアウト
```http
POST /api/v1/auth/logout
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "message": "ログアウトしました"
  }
}
```

## メニュー管理エンドポイント

### メニュー一覧取得
```http
GET /api/v1/menus?category={category}&active={true|false}
```

**クエリパラメータ**
- `category` (optional): カテゴリでフィルタリング
- `active` (optional): 有効/無効でフィルタリング

**レスポンス**
```json
{
  "success": true,
  "data": [
    {
      "id": "menu-id",
      "name": "ジェルネイル",
      "price": 5000,
      "duration": 60,
      "category": "nail",
      "isActive": true,
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### メニュー詳細取得
```http
GET /api/v1/menus/{menuId}
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "id": "menu-id",
    "name": "ジェルネイル",
    "price": 5000,
    "duration": 60,
    "category": "nail",
    "isActive": true,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

### メニュー作成
```http
POST /api/v1/menus
```

**リクエスト**
```json
{
  "name": "新メニュー",
  "price": 3000,
  "duration": 45,
  "category": "nail"
}
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "id": "new-menu-id",
    "name": "新メニュー",
    "price": 3000,
    "duration": 45,
    "category": "nail",
    "isActive": true,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

### メニュー更新
```http
PUT /api/v1/menus/{menuId}
```

**リクエスト**
```json
{
  "name": "更新メニュー",
  "price": 3500,
  "isActive": false
}
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "id": "menu-id",
    "name": "更新メニュー",
    "price": 3500,
    "duration": 45,
    "category": "nail",
    "isActive": false,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

### メニュー削除
```http
DELETE /api/v1/menus/{menuId}
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "message": "メニューを削除しました"
  }
}
```

## 伝票管理エンドポイント

### 伝票一覧取得
```http
GET /api/v1/receipts?page={page}&pageSize={pageSize}&customerName={name}&startDate={date}&endDate={date}
```

**クエリパラメータ**
- `page` (optional): ページ番号（デフォルト: 1）
- `pageSize` (optional): ページサイズ（デフォルト: 20、最大: 100）
- `customerName` (optional): 顧客名で部分一致検索
- `startDate` (optional): 開始日（ISO 8601形式）
- `endDate` (optional): 終了日（ISO 8601形式）
- `staffName` (optional): スタッフ名でフィルタリング

**レスポンス**
```json
{
  "success": true,
  "data": [
    {
      "id": "receipt-id",
      "receiptNumber": "20240101-0001",
      "customerName": "田中様",
      "serviceDate": "2024-01-01T14:00:00Z",
      "items": [
        {
          "menuId": "menu-id",
          "menuName": "ジェルネイル",
          "price": 5000,
          "quantity": 1,
          "subtotal": 5000
        }
      ],
      "totalAmount": 5000,
      "staffName": "スタッフA",
      "paymentMethod": "cash",
      "memo": "次回予約: 2月1日",
      "syncStatus": "synced",
      "createdAt": "2024-01-01T14:30:00Z",
      "updatedAt": "2024-01-01T14:30:00Z",
      "syncedAt": "2024-01-01T14:31:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalCount": 150,
    "totalPages": 8
  }
}
```

### 伝票詳細取得
```http
GET /api/v1/receipts/{receiptId}
```

### 伝票作成
```http
POST /api/v1/receipts
```

**リクエスト**
```json
{
  "customerName": "新規顧客様",
  "serviceDate": "2024-01-01T15:00:00Z",
  "items": [
    {
      "menuId": "menu-id-1",
      "quantity": 1
    },
    {
      "menuId": "menu-id-2",
      "quantity": 2
    }
  ],
  "staffName": "スタッフB",
  "paymentMethod": "credit",
  "memo": "初回来店"
}
```

### 伝票番号生成
```http
GET /api/v1/receipts/generate-number?date={serviceDate}
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "receiptNumber": "20240101-0002"
  }
}
```

## 売上分析エンドポイント

### 売上集計取得
```http
GET /api/v1/analytics/sales?startDate={date}&endDate={date}&groupBy={groupBy}
```

**クエリパラメータ**
- `startDate` (required): 開始日
- `endDate` (required): 終了日
- `groupBy` (optional): 集計単位（day|week|month、デフォルト: day）

**レスポンス**
```json
{
  "success": true,
  "data": {
    "period": {
      "start": "2024-01-01",
      "end": "2024-01-31"
    },
    "totalSales": 1500000,
    "receiptCount": 250,
    "averagePerReceipt": 6000,
    "dailySales": [
      {
        "date": "2024-01-01",
        "sales": 50000,
        "receiptCount": 10
      }
    ],
    "menuRanking": [
      {
        "menuId": "menu-id",
        "menuName": "ジェルネイル",
        "category": "nail",
        "soldCount": 120,
        "totalSales": 600000,
        "rank": 1
      }
    ],
    "paymentMethodBreakdown": [
      {
        "method": "cash",
        "count": 150,
        "amount": 900000,
        "percentage": 60.0
      }
    ]
  }
}
```

### エクスポート
```http
POST /api/v1/analytics/export
```

**リクエスト**
```json
{
  "startDate": "2024-01-01",
  "endDate": "2024-01-31",
  "format": "csv"
}
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "downloadUrl": "/downloads/export-20240101-20240131.csv",
    "expiresAt": "2024-02-01T00:00:00Z"
  }
}
```

## 同期エンドポイント

### 手動同期実行
```http
POST /api/v1/sync
```

**リクエスト**
```json
{
  "force": false
}
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "syncedAt": "2024-01-01T00:00:00Z",
    "syncedReceipts": ["receipt-id-1", "receipt-id-2"],
    "syncedMenus": ["menu-id-1"],
    "conflicts": [],
    "errors": []
  }
}
```

### 同期状態取得
```http
GET /api/v1/sync/status
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "status": "idle",
    "lastSyncAt": "2024-01-01T00:00:00Z",
    "pendingCount": 5,
    "error": null
  }
}
```

## システム管理エンドポイント

### ヘルスチェック
```http
GET /api/v1/health
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "version": "1.0.0",
    "services": {
      "googleSheets": "connected",
      "localStorage": "available",
      "network": "online"
    }
  }
}
```

### キャッシュクリア
```http
POST /api/v1/system/clear-cache
```

**レスポンス**
```json
{
  "success": true,
  "data": {
    "message": "キャッシュをクリアしました"
  }
}
```