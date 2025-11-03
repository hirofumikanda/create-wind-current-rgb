#!/bin/bash

# 引数の説明を表示する関数
show_usage() {
    echo "Usage: $0 [DATE] [START_HOUR] [END_HOUR]"
    echo "  DATE: 日付（YYYYMMDD形式、指定しない場合は全ファイル処理）"
    echo "  START_HOUR: 開始時間（0-384、DATEを指定した場合のみ有効）"
    echo "  END_HOUR: 終了時間（0-384、DATEを指定した場合のみ有効）"
    echo "  例: $0  # 全ファイル処理"
    echo "  例: $0 20251101  # 2025年11月1日の全時間"
    echo "  例: $0 20251101 0 12  # 2025年11月1日の0時間先から12時間先まで"
}

# ヘルプオプションの処理
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# 引数の設定
DATE=$1
START_HOUR=${2:-0}
END_HOUR=${3:-999}

if [[ -n "$DATE" ]]; then
    if [[ -n "$2" && -n "$3" ]]; then
        # 引数の検証
        if ! [[ "$START_HOUR" =~ ^[0-9]+$ ]] || ! [[ "$END_HOUR" =~ ^[0-9]+$ ]]; then
            echo "エラー: START_HOURとEND_HOURは数値で指定してください"
            show_usage
            exit 1
        fi

        if [[ $START_HOUR -gt $END_HOUR ]]; then
            echo "エラー: START_HOUR ($START_HOUR) はEND_HOUR ($END_HOUR) より小さくする必要があります"
            show_usage
            exit 1
        fi

        echo "Creating png data from $DATE (hours: $START_HOUR to $END_HOUR)"
    else
        echo "Creating png data from $DATE (all hours)"
    fi
else
    echo "Creating png data from all grib2 files in grib2/ directory"
fi

# pngディレクトリを作成（存在しない場合）
mkdir -p png

# ファイルリストを作成
if [[ -n "$DATE" ]]; then
    if [[ -n "$2" && -n "$3" ]]; then
        # 特定の日付と時間範囲
        file_list=()
        for ((i=START_HOUR; i<=END_HOUR; i++)); do
            hour=$(printf "%03d" $i)
            file_pattern="grib2/wind_${DATE}_${hour}.grib2"
            if [[ -f "$file_pattern" ]]; then
                file_list+=("$file_pattern")
            fi
        done
    else
        # 特定の日付のすべてのファイル
        file_list=(grib2/wind_${DATE}_*.grib2)
    fi
else
    # すべてのgrib2ファイル
    file_list=(grib2/*.grib2)
fi

curl -O https://raw.githubusercontent.com/naogify/grib2png.sh/main/grib2info.sh
curl -O https://raw.githubusercontent.com/naogify/grib2png.sh/main/grib2uv2png.sh
chmod +x grib2info.sh grib2uv2png.sh

# ファイルを処理
for grib2_file in "${file_list[@]}"; do
  if [[ -f "$grib2_file" ]]; then
    # ファイル名から拡張子を除去してベース名を取得
    base_name=$(basename "$grib2_file" .grib2)
    echo "Processing $grib2_file..."

    # PNG作成
    ./grib2uv2png.sh "$grib2_file" \
      -o "png/${base_name}.png" \
      -u ":UGRD:10 m above ground:" \
      -v ":VGRD:10 m above ground:" \
      -scale -40 40

    echo "Created png/${base_name}.png"
  fi
done

echo "All PNG files created successfully!"