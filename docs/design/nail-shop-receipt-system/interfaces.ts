// ========================================
// 基本エンティティ定義
// ========================================

/** メニューカテゴリ */
export type MenuCategory = 'nail' | 'care' | 'art' | 'option' | 'set' | 'other';

/** 支払い方法 */
export type PaymentMethod = 'cash' | 'credit' | 'paypay' | 'other';

/** 同期状態 */
export type SyncStatus = 'synced' | 'pending' | 'error';

/** メニュー */
export interface Menu {
  id: string;
  name: string;
  price: number;
  duration: number; // 分単位
  category: MenuCategory;
  isActive: boolean;
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
}

/** 伝票明細 */
export interface ReceiptItem {
  menuId: string;
  menuName: string; // スナップショット用
  price: number; // スナップショット用
  quantity: number;
  subtotal: number;
}

/** 伝票 */
export interface Receipt {
  id: string;
  receiptNumber: string; // YYYYMMDD-0001 形式
  customerName: string;
  serviceDate: string; // ISO 8601
  items: ReceiptItem[];
  totalAmount: number;
  staffName: string;
  paymentMethod: PaymentMethod;
  memo?: string;
  syncStatus: SyncStatus;
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
  syncedAt?: string; // ISO 8601
}

/** ローカルストレージメタデータ */
export interface LocalMetadata {
  version: number;
  lastSyncAt?: string; // ISO 8601
  pendingSyncCount: number;
}

// ========================================
// APIリクエスト/レスポンス定義
// ========================================

/** 基本APIレスポンス */
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: ApiError;
  timestamp: string; // ISO 8601
}

/** APIエラー */
export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, any>;
}

/** ページネーション情報 */
export interface PaginationInfo {
  page: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
}

/** ページネーション付きレスポンス */
export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination?: PaginationInfo;
}

// メニュー関連
export interface CreateMenuRequest {
  name: string;
  price: number;
  duration: number;
  category: MenuCategory;
}

export interface UpdateMenuRequest extends Partial<CreateMenuRequest> {
  isActive?: boolean;
}

// 伝票関連
export interface CreateReceiptRequest {
  customerName: string;
  serviceDate: string;
  items: Array<{
    menuId: string;
    quantity: number;
  }>;
  staffName: string;
  paymentMethod: PaymentMethod;
  memo?: string;
}

export interface SearchReceiptsRequest {
  customerName?: string;
  startDate?: string;
  endDate?: string;
  staffName?: string;
  page?: number;
  pageSize?: number;
}

// 売上分析関連
export interface SalesAnalytics {
  period: {
    start: string;
    end: string;
  };
  totalSales: number;
  receiptCount: number;
  averagePerReceipt: number;
  dailySales: DailySales[];
  menuRanking: MenuRanking[];
  paymentMethodBreakdown: PaymentMethodBreakdown[];
}

export interface DailySales {
  date: string;
  sales: number;
  receiptCount: number;
}

export interface MenuRanking {
  menuId: string;
  menuName: string;
  category: MenuCategory;
  soldCount: number;
  totalSales: number;
  rank: number;
}

export interface PaymentMethodBreakdown {
  method: PaymentMethod;
  count: number;
  amount: number;
  percentage: number;
}

export interface GetSalesAnalyticsRequest {
  startDate: string;
  endDate: string;
  groupBy?: 'day' | 'week' | 'month';
}

// ========================================
// Google Sheets 関連定義
// ========================================

/** Google認証トークン */
export interface GoogleAuthToken {
  accessToken: string;
  refreshToken?: string;
  expiresAt: string; // ISO 8601
  scope: string[];
}

/** スプレッドシート設定 */
export interface SpreadsheetConfig {
  spreadsheetId: string;
  menuSheetName: string;
  receiptSheetName: string;
}

/** 同期リクエスト */
export interface SyncRequest {
  lastSyncAt?: string;
  pendingReceipts: Receipt[];
  pendingMenus: Menu[];
}

/** 同期レスポンス */
export interface SyncResponse {
  syncedAt: string;
  syncedReceipts: string[]; // 同期成功した伝票ID
  syncedMenus: string[]; // 同期成功したメニューID
  conflicts: SyncConflict[];
  errors: SyncError[];
}

/** 同期競合 */
export interface SyncConflict {
  entityType: 'menu' | 'receipt';
  entityId: string;
  localVersion: any;
  remoteVersion: any;
  resolution: 'local' | 'remote' | 'merged';
}

/** 同期エラー */
export interface SyncError {
  entityType: 'menu' | 'receipt';
  entityId: string;
  errorCode: string;
  errorMessage: string;
}

// ========================================
// UI状態管理定義
// ========================================

/** アプリケーション状態 */
export interface AppState {
  auth: AuthState;
  menu: MenuState;
  receipt: ReceiptState;
  analytics: AnalyticsState;
  sync: SyncState;
  ui: UIState;
}

export interface AuthState {
  isAuthenticated: boolean;
  user?: {
    email: string;
    name: string;
  };
  token?: GoogleAuthToken;
}

export interface MenuState {
  menus: Menu[];
  loading: boolean;
  error?: string;
}

export interface ReceiptState {
  receipts: Receipt[];
  currentReceipt?: Partial<Receipt>;
  loading: boolean;
  error?: string;
}

export interface AnalyticsState {
  data?: SalesAnalytics;
  loading: boolean;
  error?: string;
  cachedAt?: string;
}

export interface SyncState {
  status: 'idle' | 'syncing' | 'error';
  lastSyncAt?: string;
  pendingCount: number;
  error?: string;
}

export interface UIState {
  sidebarOpen: boolean;
  theme: 'light' | 'dark';
  notification?: {
    type: 'success' | 'error' | 'warning' | 'info';
    message: string;
  };
}

// ========================================
// ユーティリティ型定義
// ========================================

/** 日付範囲 */
export interface DateRange {
  start: string;
  end: string;
}

/** バリデーションエラー */
export interface ValidationError {
  field: string;
  message: string;
}

/** バリデーション結果 */
export interface ValidationResult {
  isValid: boolean;
  errors: ValidationError[];
}