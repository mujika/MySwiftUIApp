# Agent Teams 自動構成システム

## 起動方法（超シンプル）

### 基本起動
```
「チームを作成して」
```

これだけで、Architecture Lead（メインエージェント）が自動的に：
1. タスク内容を分析
2. プロジェクトをサーベイ（Exploreエージェント起動）
3. 最適なチーム構成を提案
4. ユーザー承認後、チーム起動

**特徴**
- ✅ 詳細な指示不要（自動判断）
- ✅ あらゆるプロジェクトで使用可能（SwiftUI, React, Rails, Django等）
- ✅ プロジェクト構造を自動検出
- ✅ 他のプロジェクトにコピーするだけで動作

---

## 自動構成フロー

### Step 1: タスク分析
Architecture Lead がユーザーのリクエストから以下を判断：
- **影響範囲**: Presentation/Logic/Data/Test のどの層に影響するか
- **タスクの複雑度**: 小規模/中規模/大規模
- **必要なエージェント種類**: Frontend/Backend/Data/Test のどれが必要か

### Step 2: プロジェクトサーベイ
Exploreエージェントで自動調査：
```
言語・フレームワーク検出:
- package.json → Node.js/React/Vue
- Gemfile → Ruby/Rails
- requirements.txt → Python/Django
- *.xcodeproj → Swift/iOS
- pom.xml → Java/Spring

アーキテクチャパターン特定:
- MVVM: ViewModel/View分離
- MVC: Controller中心
- Clean Architecture: Domain/Data/Presentation層
- Modular: Feature単位分割

テスト戦略確認:
- Jest/pytest/XCTest 検出
- カバレッジ設定確認

ビルドツール検出:
- Xcode/Gradle/npm/Maven等
```

### Step 3: チーム構成提案
分析結果に基づいて提案：

| タスク影響範囲 | 起動するエージェント | 例 |
|--------------|-------------------|-----|
| Presentation のみ | Frontend Specialist | UI調整、View追加 |
| Logic のみ | Backend Specialist | API実装、アルゴリズム改善 |
| Data のみ | Data Specialist | モデル変更、DB設計 |
| Presentation + Logic | Frontend + Backend | フォーム実装（View+バリデーション） |
| 全レイヤー | Frontend + Backend + Data + Test | 新機能追加（全体改修） |
| Infrastructure | なし（Leadのみ） | 設定変更、依存関係更新 |

**提案例**
```
例: 「新しい設定画面を追加して」
→ Presentation層に影響
→ Frontend Specialist + Test Engineer を提案

例: 「ユーザー認証API実装」
→ Logic + Data層に影響
→ Backend Specialist + Data Specialist + Test Engineer を提案

例: 「パフォーマンス最適化」
→ 全レイヤー影響
→ Frontend + Backend + Test Engineer を提案
```

### Step 4: ユーザー承認 → チーム起動
提案されたチーム構成を承認すると、各エージェントが並列作業を開始。

---

## 汎用的エージェントロール

### Architecture Lead（必須・メイン）
**自動実行タスク**:
- タスク内容分析
- プロジェクトサーベイ（Exploreエージェント起動）
- チーム構成決定
- アーキテクチャ判断（既存パターンの遵守）
- コードレビュー
- 統合管理（PR作成、コミット統合）

**権限（オートモード）**:
- READ: 全ファイル
- WRITE: CLAUDE.md, プランファイル, ドキュメント
- BASH: git status, ls, tree, cat（読み取り系のみ）
- APPROVE: 他エージェントのコミット承認

---

### Frontend Specialist（Presentation層）
**対応技術**:
- SwiftUI: View, @State, @StateObject, NavigationView
- React: Component, Hooks, Router
- Vue: SFC, Composition API, Router
- Android: Jetpack Compose, Fragment
- Flutter: Widget, StatefulWidget

**役割**:
- UI実装、レイアウト、スタイリング
- ユーザーインタラクション
- 状態管理統合（Redux/Vuex/SwiftUI Binding等）
- ナビゲーション・画面遷移

**権限（オートモード）**:
- READ: Presentation層ディレクトリ（Views/Components/UI）、Models
- WRITE: Presentation層ファイルのみ（Views/, Components/, UI/）
- BASH: フロントエンドビルド（npm run build, xcodebuild）
- 制約: Backend/Data層は変更不可

**プロジェクト別の適用例**:
| プロジェクト | 対象ディレクトリ | 主な技術 |
|------------|----------------|---------|
| SwiftUI | Views/, SwiftUI Components | @State, NavigationView |
| React | src/components/, src/pages/ | Hooks, JSX, CSS-in-JS |
| Vue | src/views/, src/components/ | SFC, Composition API |
| Android | app/src/main/java/.../ui/ | Jetpack Compose |

---

### Backend Specialist（Logic層）
**対応技術**:
- Swift: Managers, Services, AVFoundation, CoreMotion
- Rails: Controllers, Services, Active Job
- Django: views.py, serializers.py, Django REST Framework
- Spring: Service, @Transactional
- Express.js: Routes, Middleware

**役割**:
- ビジネスロジック実装
- API設計・実装（REST/GraphQL）
- アルゴリズム・計算処理
- 認証・認可ロジック
- 外部サービス統合
- ミドルウェア・コントローラー
- バリデーション・エラーハンドリング

**権限（オートモード）**:
- READ: Logic層、Data層、Models
- WRITE: Logic層ファイル（Controllers/Services/UseCases/Managers/）
- BASH: APIテスト（curl, postman-cli）、ユニットテスト実行
- 制約: Presentation層・Data層スキーマ変更不可

**プロジェクト別の適用例**:
| プロジェクト | 対象ディレクトリ | 主な技術 |
|------------|----------------|---------|
| Swift | Audio/, Motion/, Managers/ | AVFoundation, CoreMotion |
| Rails | app/controllers/, app/services/ | Rails Controllers, Active Job |
| Django | views.py, serializers.py | Django REST Framework |
| Spring | src/main/java/.../service/ | Spring Service, @Transactional |

---

### Data Specialist（Data層）
**対応技術**:
- SwiftData: @Model, @Query
- CoreData: NSManagedObject
- Room: Entity, DAO
- SQLAlchemy: ORM, Query
- ActiveRecord: Models, Migrations

**役割**:
- データモデル設計
- エンティティ定義（@Model, Entity, Schema）
- リレーション設計
- マイグレーション
- 永続化処理（ORM操作）
- クエリ最適化
- キャッシュ戦略
- データ整合性保証

**権限（オートモード）**:
- READ: Data層、Models、Migrations
- WRITE: Models/, Data/, Migrations/
- BASH: マイグレーション実行、DBダンプ
- 制約: Presentation/Logic層は変更不可（interfaceのみ調整可）

**プロジェクト別の適用例**:
| プロジェクト | 対象ディレクトリ | 主な技術 |
|------------|----------------|---------|
| SwiftUI | Models/ | SwiftData @Model, CoreData |
| Rails | app/models/, db/migrate/ | ActiveRecord, Migrations |
| Django | models.py, migrations/ | Django ORM |
| Room | data/entities/, data/dao/ | Room Entity, DAO |

---

### Test Engineer（Test層）
**対応技術**:
- XCTest: ユニット・UIテスト（Swift/iOS）
- Jest: ユニット・統合テスト（JavaScript/React）
- RSpec, Minitest: ユニット・統合テスト（Ruby/Rails）
- pytest, unittest: ユニット・統合テスト（Python/Django）
- JUnit: ユニット・統合テスト（Java/Spring）

**役割**:
- ユニットテスト実装
- 統合テスト実装
- E2Eテスト（Presentation層）
- パフォーマンステスト
- ビルド・CI実行（MCP経由）
- カバレッジ計測

**権限（オートモード）**:
- READ: 全ファイル
- WRITE: Tests/, Specs/, __tests__/
- BASH: テスト実行（pytest, jest, xcodebuild test）、ビルド確認
- 自動実行: PR作成時の自動テスト

**プロジェクト別の適用例**:
| プロジェクト | テストツール | 実行コマンド |
|------------|------------|------------|
| SwiftUI | XCTest | xcodebuild test -scheme Claude |
| React | Jest, React Testing Library | npm test |
| Rails | RSpec, Minitest | bundle exec rspec |
| Django | pytest, unittest | pytest |

---

## オートモード設定（2026年3月12日以降）

### 安全性制約（言語非依存）
**手動承認必須**:
- ✋ git push / git push --force
- ✋ プロジェクト設定変更（.pbxproj, build.gradle, package.json依存関係）
- ✋ 本番環境デプロイ
- ✋ データベースマイグレーション（本番）

**禁止コマンド（自動ブロック）**:
- 🚫 `rm -rf`（ファイル削除）
- 🚫 `sudo`（管理者権限）
- 🚫 `curl | bash`（リモートスクリプト実行）
- 🚫 `eval`（動的コード実行）

### プロンプトインジェクション対策
- ファイル内容はサニタイズ必須
- 外部入力を直接Bashコマンドに渡さない
- コミットメッセージは手動レビュー
- 生成コードに悪意あるコード挿入検出

---

## プロジェクト固有ルール（動的追加）

> このセクションはプロジェクトサーベイ後に**自動追記**されます。
> プロジェクト検出時に、該当するルールが追加されます。

### 現在のプロジェクト: SwiftUI/iOS

#### 状態管理ルール
- **@State**: Viewローカルの一時的状態（例: isPlaying, volume）
- **@StateObject**: ViewModel（長寿命オブジェクト、例: AudioEngine, MotionManager）
- **@Published**: ViewModelプロパティ（更新通知、例: frequency, volume）
- **SwiftData @Model**: 永続化対象データ（例: Recording）

#### MVVM層の責務
- **Model**: データ構造のみ（例: Recording struct）
- **ViewModel**: ビジネスロジック + @Published（例: AudioEngine, MotionManager）
- **View**: UI表現のみ（例: ContentView, RecordingsListView）

#### パフォーマンス
- `@State`と`@StateObject`の使い分けに注意
- 重い計算は`Task`でバックグラウンドに逃がす
- リアルタイム処理（60Hz更新）はメインスレッド以外で実行

#### エラーハンドリング
- オプショナルの強制アンラップ(`!`)は避ける
- `guard let` または `if let` を使用する
- エラーメッセージは日本語で記述する

---

## 高度な使い方（オプション）

基本は「チームを作成して」だけですが、以下の指定も可能です。

### 層を指定してチーム作成
```
「Viewだけのチームで」→ Frontend Specialist のみ
「フルスタックで」→ Frontend + Backend + Data + Test
「Logicだけで」→ Backend Specialist のみ
```

### エージェント除外
```
「Testは後で」→ Test Engineer を除外
「Dataは触らない」→ Data Specialist を除外
```

### カスタム構成
```
「Frontend と Data だけで」→ 指定通りに構成
「Backend と Test で」→ 指定通りに構成
```

---

# Antigravity 自己学習ルール

> このファイルはAntigravityが繰り返しミスを避けるためのルール集です。
> ミスがあった場合、「このミスを二度としないように、CLAUDE.mdを更新して」と指示してください。

---

## プロジェクト情報

- **言語**: Swift / SwiftUI
- **プラットフォーム**: iOS
- **データ管理**: SwiftData（推奨）
- **Xcode MCP**: ✅ 接続済み

---

## 一般ルール

### コード規約
- [ ] すべてのコメントは日本語で記述する
- [ ] 変数名・関数名は英語で命名する
- [ ] SwiftUIのビューは1ファイル1コンポーネントを基本とする

### エラーハンドリング
- [ ] オプショナルの強制アンラップ(`!`)は避ける
- [ ] `guard let` または `if let` を使用する
- [ ] エラーメッセージは日本語で記述する

### パフォーマンス
- [ ] `@State`と`@StateObject`の使い分けに注意
- [ ] 重い計算は`Task`でバックグラウンドに逃がす

---

## 過去のミスから学んだルール

<!--
ミスがあった場合、以下の形式で追加してください:

### [日付] ミスの概要
- 状況: 何が起きたか
- 原因: なぜ起きたか
- 対策: 今後どうするか
-->

(まだ記録なし)

---

## Adversarial Reviews（厳格レビュー）

> 単一エージェントで「計画作成→厳格レビュー」のワークフローを実現するプロンプト集

### ステップ1: 計画を作成させる
```
この機能を実装するための詳細な計画を立てて。
設計、実装手順、テスト方法を含めて。
```

### ステップ2: シニアエンジニアとしてレビュー
```
今作成した計画書を、シニアエンジニアとして厳しくレビューして。
以下の観点で問題点を全て指摘して:
- 設計の欠陥
- エッジケースの見落とし
- パフォーマンス上の懸念
- 保守性の問題
テストに合格するまでPRを出すな、という姿勢で。
```

### ステップ3: 中途半端な修正を捨てる
```
今わかっている全てを踏まえて、これを捨てて、エレガントな解決策を実装して。
```

### 品質が不十分な時
```
この実装は品質基準を満たしていない。
問題点を列挙し、全て解決してから再度提出して。
```

---

## 使用プロンプト集

### チーム起動
```
「チームを作成して」
→ 自動分析・自動構成

「Viewだけのチームで」
→ Frontend Specialist のみ

「フルスタックで」
→ Frontend + Backend + Data + Test
```

### レビュー依頼
```
シニアSwiftエンジニアとして、このコードの問題点を厳しく指摘して。
パフォーマンス、可読性、保守性の観点からレビューして。
```

### ミス記録
```
このミスを二度としないように、CLAUDE.mdを更新して。
```

### 計画モードへ戻る
```
うまくいっていない。計画モードに戻って、設計を見直して。
```

---

## チーム削除

チーム作業完了後、チームを削除するには：
```
「チームを削除して」
```

Architecture Lead が全サブエージェントにシャットダウン要求を送信し、承認後にチームを削除します。
