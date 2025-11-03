#!/bin/bash

# 風速データのダウンロードからPNG画像生成まで一気通貫で実行するパイプライン

# 引数の説明を表示する関数
show_usage() {
    echo "Usage: $0 [DATE] [START_HOUR] [END_HOUR]"
    echo "  DATE: 日付（YYYYMMDD形式、デフォルト: 今日）"
    echo "  START_HOUR: 開始時間（0-384、デフォルト: 0）"
    echo "  END_HOUR: 終了時間（0-384、デフォルト: 23）"
    echo ""
    echo "このスクリプトは以下の処理を順番に実行します:"
    echo "  1. GFS風速データのダウンロード (01_fetch_wind_vector.sh)"
    echo "  2. GRIB2データからPNG画像の生成 (02_create_png.sh)"
    echo ""
    echo "例:"
    echo "  $0                          # 今日の0-23時間先のデータを処理"
    echo "  $0 20251101                 # 2025年11月1日の0-23時間先のデータを処理"
    echo "  $0 20251101 0 12            # 2025年11月1日の0-12時間先のデータを処理"
    echo "  $0 \$(date +%Y%m%d) 6 18      # 今日の6-18時間先のデータを処理"
}

# ログ出力用の関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# エラーログ出力用の関数
error_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# 実行時間計測の開始
start_time=$(date +%s)

# ヘルプオプションの処理
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# 引数の設定
DATE=${1:-$(date +%Y%m%d)}
START_HOUR=${2:-0}
END_HOUR=${3:-23}

# 引数の検証
if ! [[ "$START_HOUR" =~ ^[0-9]+$ ]] || ! [[ "$END_HOUR" =~ ^[0-9]+$ ]]; then
    error_log "START_HOURとEND_HOURは数値で指定してください"
    show_usage
    exit 1
fi

if [[ $START_HOUR -gt $END_HOUR ]]; then
    error_log "START_HOUR ($START_HOUR) はEND_HOUR ($END_HOUR) より小さくする必要があります"
    show_usage
    exit 1
fi

if [[ $START_HOUR -lt 0 || $END_HOUR -gt 384 ]]; then
    error_log "時間は0-384の範囲で指定してください"
    show_usage
    exit 1
fi

# 必要なスクリプトの存在確認
if [[ ! -f "01_fetch_wind_vector.sh" ]]; then
    error_log "01_fetch_wind_vector.sh が見つかりません"
    exit 1
fi

if [[ ! -f "02_create_png.sh" ]]; then
    error_log "02_create_png.sh が見つかりません"
    exit 1
fi

# スクリプトの実行権限確認
if [[ ! -x "01_fetch_wind_vector.sh" ]]; then
    log "01_fetch_wind_vector.sh に実行権限を付与します"
    chmod +x 01_fetch_wind_vector.sh
fi

if [[ ! -x "02_create_png.sh" ]]; then
    log "02_create_png.sh に実行権限を付与します"
    chmod +x 02_create_png.sh
fi

log "=== Wind Current RGB Pipeline Started ==="
log "処理対象: 日付=${DATE}, 時間範囲=${START_HOUR}-${END_HOUR}"

# ステップ1: 風速データのダウンロード
log "ステップ1: GFS風速データのダウンロードを開始します..."
step1_start=$(date +%s)

if ./01_fetch_wind_vector.sh "$DATE" "$START_HOUR" "$END_HOUR"; then
    step1_end=$(date +%s)
    step1_duration=$((step1_end - step1_start))
    log "ステップ1: 風速データのダウンロードが完了しました（所要時間: ${step1_duration}秒）"
else
    error_log "ステップ1: 風速データのダウンロードに失敗しました"
    exit 1
fi

# ダウンロードされたファイルの確認
grib2_count=$(ls -1 grib2/wind_${DATE}_*.grib2 2>/dev/null | wc -l)
if [[ $grib2_count -eq 0 ]]; then
    error_log "GRIB2ファイルが生成されていません"
    exit 1
fi
log "生成されたGRIB2ファイル数: ${grib2_count}個"

# ステップ2: PNG画像の生成
log "ステップ2: PNG画像の生成を開始します..."
step2_start=$(date +%s)

if ./02_create_png.sh "$DATE" "$START_HOUR" "$END_HOUR"; then
    step2_end=$(date +%s)
    step2_duration=$((step2_end - step2_start))
    log "ステップ2: PNG画像の生成が完了しました（所要時間: ${step2_duration}秒）"
else
    error_log "ステップ2: PNG画像の生成に失敗しました"
    exit 1
fi

# 生成されたPNGファイルの確認
png_count=$(ls -1 png/wind_wind_${DATE}_*.png 2>/dev/null | wc -l)
if [[ $png_count -eq 0 ]]; then
    error_log "PNGファイルが生成されていません"
    exit 1
fi
log "生成されたPNGファイル数: ${png_count}個"

# 実行時間の計算と結果表示
end_time=$(date +%s)
total_duration=$((end_time - start_time))

log "=== Wind Current RGB Pipeline Completed ==="
log "総実行時間: ${total_duration}秒"
log "処理結果:"
log "  - GRIB2ファイル: ${grib2_count}個 (grib2/)"
log "  - PNGファイル: ${png_count}個 (png/)"
log ""
log "生成されたファイル一覧:"
log "GRIB2ファイル:"
ls -la grib2/wind_${DATE}_*.grib2 2>/dev/null | while read -r line; do
    log "  $line"
done

log "PNGファイル:"
ls -la png/wind_wind_${DATE}_*.png 2>/dev/null | while read -r line; do
    log "  $line"
done

log "パイプライン実行が正常に完了しました！"