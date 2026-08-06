#!/bin/bash
# ============================================
#  convert.sh — MKV to MP4 converter
#  Usage: ./convert.sh input.mkv [options]
# ============================================

set -e

# ---------- defaults ----------
PRESET="slow"
CRF=20
AUDIO="copy"
SUFFIX="converted"
ENCODER="gpu"

# ---------- help ----------
usage() {
  echo ""
  echo "  Usage: ./convert.sh <input.mkv> [options]"
  echo ""
  echo "  Options:"
  echo "    -o <file>     Output filename       (default: input_converted.mp4)"
  echo "    -c <0-51>     CRF quality           (default: 20, lower = better quality)"
  echo "    -p <preset>   Encoding preset       (default: slow)"
  echo "                  Choices: ultrafast, fast, medium, slow, veryslow"
  echo "    -a <codec>    Audio codec           (default: copy)"
  echo "                  Choices: copy, aac, mp3"
  echo "    -e <gpu|cpu>  Encoder               (default: gpu, falls back to cpu if no GPU)"
  echo "    -h            Show this help"
  echo ""
  echo "  Examples:"
  echo "    ./convert.sh video.mkv"
  echo "    ./convert.sh video.mkv -o final.mp4 -c 22"
  echo "    ./convert.sh video.mkv -e cpu -p veryslow -c 18"
  echo ""
}

# ---------- check ffmpeg ----------
if ! command -v ffmpeg &> /dev/null; then
  echo "  ERROR: ffmpeg is not installed."
  exit 1
fi

# ---------- require input ----------
if [[ -z "$1" || "$1" == "-h" ]]; then
  usage
  exit 0
fi

INPUT="$1"
shift

if [[ ! -f "$INPUT" ]]; then
  echo "  ERROR: File not found — '$INPUT'"
  exit 1
fi

# ---------- parse options ----------
while getopts ":o:c:p:a:e:h" opt; do
  case $opt in
    o) OUTPUT="$OPTARG" ;;
    c) CRF="$OPTARG" ;;
    p) PRESET="$OPTARG" ;;
    a) AUDIO="$OPTARG" ;;
    e) ENCODER="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) echo "  ERROR: Option -$OPTARG requires a value."; exit 1 ;;
    \?) echo "  ERROR: Unknown option -$OPTARG"; exit 1 ;;
  esac
done

# ---------- default output name ----------
if [[ -z "$OUTPUT" ]]; then
  BASENAME="${INPUT%.*}"
  OUTPUT="${BASENAME}_${SUFFIX}.mp4"
fi

# ---------- pick GPU or CPU codec ----------
if [[ "$ENCODER" == "gpu" ]]; then
  if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
    VCODEC="hevc_nvenc"
  else
    echo "  ⚠ No NVIDIA GPU detected — falling back to CPU."
    ENCODER="cpu"
    VCODEC="libx265"
  fi
else
  VCODEC="libx265"
fi

# ---------- summary ----------
echo ""
echo "  ▶ Input   : $INPUT"
echo "  ▶ Output  : $OUTPUT"
echo "  ▶ Codec   : $VCODEC ($ENCODER)"
echo "  ▶ CRF     : $CRF"
echo "  ▶ Preset  : $PRESET"
echo "  ▶ Audio   : $AUDIO"
echo ""

# ---------- run ----------
ffmpeg -i "$INPUT" \
  -c:v "$VCODEC" \
  -preset "$PRESET" \
  -crf "$CRF" \
  -c:a "$AUDIO" \
  -tag:v hvc1 \
  "$OUTPUT"

echo ""
echo "  ✅ Done! Saved to: $OUTPUT"
echo ""
