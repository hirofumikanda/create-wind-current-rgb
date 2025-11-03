# Wind Current RGB Pipeline

NOAA GFS（Global Forecast System）の気象風ベクトルデータを処理し、RGB PNG可視化画像を生成するパイプラインです。

## 概要

このプロジェクトは、気象予報データから風の流れを可視化するための3段階パイプラインを提供します：

1. **データ取得**：AWS S3からGFS GRIB2データをダウンロード
2. **データ変換**：GRIB2ファイルからRGB PNG画像を生成
3. **統合実行**：上記プロセスを一括実行

## 必要なツール

- Docker（必須）
- AWS CLI（NOAA公開データアクセス用）

## 使用されるDockerイメージ

このパイプラインは以下のDockerコンテナに依存しています：

- `28mm/wgrib2`：GRIB2データ抽出・フィルタリング
- `alexgleith/cdo`：U/V風成分のマージ
- `ghcr.io/naogify/wgrib2`：GRIB2情報表示・変換
- `osgeo/gdal`：地理空間データ変換・投影

## ディレクトリ構造

```
.
├── 01_fetch_wind_vector.sh  # GFSデータダウンロードスクリプト
├── 02_create_png.sh         # PNG画像生成スクリプト
├── pipeline.sh              # 統合実行スクリプト
├── grib2/                   # GRIB2ファイル保存ディレクトリ
└── png/                     # PNG出力ディレクトリ
```

## 使用方法

### 1. 基本的な使用方法（推奨）

パイプライン全体を実行：
```bash
./pipeline.sh [日付] [開始時間] [終了時間]
```

例：
```bash
# 今日の0-23時間先のデータを処理
./pipeline.sh

# 2025年11月1日の0-12時間先のデータを処理
./pipeline.sh 20251101 0 12

# 特定の日付の全時間を処理
./pipeline.sh 20251101
```

### 2. 個別実行

#### データダウンロードのみ
```bash
./01_fetch_wind_vector.sh 20251101 0 12
```

#### 既存GRIB2ファイルからPNG生成のみ
```bash
./02_create_png.sh 20251101 0 12
```

## パラメータ説明

- **日付**：YYYYMMDD形式（例：20251101）、省略時は今日
- **開始時間**：0-384の範囲（予報時間、省略時は0）
- **終了時間**：0-384の範囲（予報時間、省略時は23）

## データ処理の詳細

### 入力データ
- **ソース**：NOAA GFS 0.25度格子データ
- **取得元**：AWS S3 (`s3://noaa-gfs-bdp-pds/`)
- **データ種別**：UGRD（東西風成分）、VGRD（南北風成分）
- **高度**：地上10m

### 出力データ
- **フォーマット**：RGB PNG画像
- **投影法**：EPSG:4326（WGS84地理座標）
- **チャンネル構成**：
  - R（赤）：U成分（東西風）
  - G（緑）：V成分（南北風）
- **スケール**：風速-40〜+40 m/s → ピクセル値0-255

### ファイル命名規則
- **GRIB2入力**：`wind_YYYYMMDD_HHH.grib2`
- **PNG出力**：`wind_wind_YYYYMMDD_HHH.png`
- **予報時間**：HHHは000-384の3桁ゼロパディング

## ライセンス

このプロジェクトはMITライセンスで公開されています。

## 関連リンク

- [NOAA GFS データセット](https://registry.opendata.aws/noaa-gfs-bdp-pds/)
   - データの利用に当たってはデータセットの利用規約に従ってください。
- [naogify/grib2png.sh](https://github.com/naogify/grib2png.sh)
   - grib2からPNGへのエンコードに使用しています。