# mレジ_セルフ精算アプリ

- お客様自身で精算を完了させることができるアプリケーション
- 画面レイアウトはiPad向けに最適化

　　![144](https://github.com/TSI-forTerminals/barcode_selfseisan_smaregi/assets/103296935/010cc5fe-c307-4ade-b5d7-251260fcdcaf)

# 動作環境要件

## 動作機器

|世代|iPadOSバージョン|動作可否|
|---|---|---|
|第9世代|16.2|○|

   ※世代更新時やバージョンアップ更新時は必ず動作確認を行うこと

# 制限事項

1. 【診察券バーコードモード時】 １つのスマレジ仮販売に複数のORCA伝票番号が紐づくケースには未対応であるため、連携PGはスマレジ仮販売とORCA伝票番号を１対１で扱うモードで稼働させること
	- 例

		メモに記載された伝票番号は１番の「社保」のみに紐づいており、「未収金」と「返金」は別の伝票番号に紐づいている
				<img width="882" alt="image" src="https://github.com/TSI-forTerminals/barcode_selfseisan_smaregi/assets/103296935/243afc65-2957-4ab8-8ff2-9b3d879be958">

## 外部連携機器

|機器|説明|iPadとの接続方式|備考|
|---|---|---|---|
|ビジコム BC-NL3010UM-W|バーコードリーダ|Lightning–USB 3カメラアダプタ（Lightning to USB 3 Camera Adapter）でLigntning接続|iPadは外部キーボードとして認識する|
|グローリーR08（RT-R08 ／ RAD-R08） (※1)|つり銭機 (※2)|つり銭機アダプタ（グローリー YRT-R08-MN）とのローカルネットワーク接続||
|グローリー300（RT-300 ／ RAD-300） (※1)|つり銭機 (※2)|Ethernet-シリアル変換器（REX-ET60）とのローカルネットワーク接続|以下のモードに設定すること<br>・預かり金計数モード<br>・連動残置|
|グローリー380（RT-380 ／ RAD-380） (※1)|つり銭機 (※2)|Ethernet-シリアル変換器（REX-ET60）とのローカルネットワーク接続|以下のモードに設定すること<br>・預かり金計数モード<br>・連動残置|
|STORES M010-PROD45-V2-4|STORES決済端末|Bluetooth接続|Bluetooth接続時は「Coiney Terminal 710」を表示される|
|EPSON TM-m30-611|レシートプリンタ|Bluetooth接続|Bluetooth接続時は「TM-m30_xxxxxx」|

- ※1 RT：硬貨つり銭機 ／ RAD：紙幣つり銭機
- ※2 つり銭機はいずれか1つのみと接続可（アプリケーション設定で切替可）

# 設定

本アプリは各種設定が完了するまでアプリケーション動作を行わないため、必ず以下の設定を行うこと。

[設定手順](./doc/%E8%A8%AD%E5%AE%9A%E6%89%8B%E9%A0%86.md)

# ログ

アプリケーション動作ログの確認方法を示す。

- 確認方法

   ```
   「ファイル」アプリ
         +- このiPad内
            +- seisan
               +- Logsディレクトリ
                  +- 20230201.log
                  +- 20230202.log
                  +- 20230203.log
                  +- 20230204.log
                  +- 20230205.log
                  +- 20230206.log
                  +- 20230207.log　　← デフォルトで最大7日分のログを保持する
   ```

- 保持するログ数の変更方法

   アプリケーション設定のログ出力設定から変更できる

# 制限事項

- STORES決済端末のBluetooth接続は「iPad本体のシステム設定」で行うこと
   - 理由は「[issue#5](https://github.com/TSI-forTerminals/barcode_selfseisan_smaregi/issues/5)」を参照すること

# 開発

## サードパーティ製ライセンス情報の更新

サードパーティ製のライセンスを追加した場合、必ず以下の操作を行うこと

1. 以下のコマンドを実行

   ```zsh
   license-plist --output-path seisan/Settings.bundle
   ```

1. ビルドを実行し、iPadでデバッグ実行する

1. iPad設定画面を開き「セルフバーコード」アプリの「ライセンス」にライブラリが追加されていることを確認する

※ license-plistコマンドは[LicensePlist](https://github.com/mono0926/LicensePlist)からインストールすること

## 実装メモ

1. EPSON TM-m30の「診療費請求書兼領収書」印刷について

   診察券バーコードモード時の「診療費請求書兼領収書」印刷には [Epson ePOS SDK](https://partner.epson.jp/support/details/contents164/) の v2.22.0 を使用している。

      - [Epson ePOS SDK](https://partner.epson.jp/support/details/contents164/) > [ドライバー・ソフトウェア基本情報（Epson ePOS SDK for iOS）](https://www.epson.jp/dl_soft/readme/36269.htm) > [ePOS_SDK_iOS_v2.22.0.zip](https://www.epson.jp/dl_soft/file/36269/ePOS_SDK_iOS_v2.22.0.zip)

   SDKの組み込み方法については、上記ファイルに同梱される「ePOS_SDK_iOS_um_ja_revX.pdf」の 「Epson ePOS SDK for iOSの組み込み方法（P.25）」 を参照すること。

# リリースノート

[ReleaseNote.md](./ReleaseNote.md)