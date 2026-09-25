#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets/audio"
FFMPEG="${FFMPEG:-/opt/homebrew/bin/ffmpeg}"

mkdir -p "$OUT"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "anoisesrc=color=white:duration=0.18:sample_rate=44100" \
	-f lavfi -i "sine=frequency=105:duration=0.18:sample_rate=44100" \
	-filter_complex "[0:a]highpass=f=1000,lowpass=f=7800,volume=0.30,afade=t=out:st=0.025:d=0.155[n];[1:a]volume=0.58,afade=t=out:st=0.01:d=0.17[b];[n][b]amix=inputs=2:normalize=0,alimiter=limit=0.88" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/ar_fire.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "anoisesrc=color=white:duration=0.095:sample_rate=44100" \
	-f lavfi -i "sine=frequency=165:duration=0.095:sample_rate=44100" \
	-filter_complex "[0:a]highpass=f=1500,lowpass=f=9000,volume=0.28,afade=t=out:st=0.012:d=0.083[n];[1:a]volume=0.38,afade=t=out:st=0.008:d=0.087[b];[n][b]amix=inputs=2:normalize=0,alimiter=limit=0.82" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/smg_fire.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "anoisesrc=color=brown:duration=0.62:sample_rate=44100" \
	-f lavfi -i "sine=frequency=58:duration=0.62:sample_rate=44100" \
	-filter_complex "[0:a]lowpass=f=1700,highpass=f=65,volume=0.62,afade=t=out:st=0.12:d=0.50[n];[1:a]volume=0.72,afade=t=out:st=0.08:d=0.54[b];[n][b]amix=inputs=2:normalize=0,alimiter=limit=0.9" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/rocket_fire.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "sine=frequency=760:duration=0.16:sample_rate=44100" \
	-f lavfi -i "anoisesrc=color=white:duration=0.16:sample_rate=44100" \
	-filter_complex "[0:a]tremolo=f=42:d=0.72,volume=0.45,afade=t=out:st=0.035:d=0.125[t];[1:a]highpass=f=2800,lowpass=f=9000,volume=0.12,afade=t=out:st=0.02:d=0.14[n];[t][n]amix=inputs=2:normalize=0" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/enemy_fire.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "anoisesrc=color=white:duration=0.13:sample_rate=44100" \
	-f lavfi -i "sine=frequency=310:duration=0.13:sample_rate=44100" \
	-filter_complex "[0:a]highpass=f=900,lowpass=f=6200,volume=0.26,afade=t=out:st=0.015:d=0.115[n];[1:a]volume=0.34,afade=t=out:st=0.01:d=0.12[t];[n][t]amix=inputs=2:normalize=0" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/impact.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "anoisesrc=color=brown:duration=0.26:sample_rate=44100" \
	-f lavfi -i "sine=frequency=86:duration=0.26:sample_rate=44100" \
	-filter_complex "[0:a]lowpass=f=1100,volume=0.32,afade=t=out:st=0.03:d=0.23[n];[1:a]volume=0.42,afade=t=out:st=0.02:d=0.24[t];[n][t]amix=inputs=2:normalize=0" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/player_hurt.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "anoisesrc=color=brown:duration=0.92:sample_rate=44100" \
	-f lavfi -i "sine=frequency=48:duration=0.92:sample_rate=44100" \
	-filter_complex "[0:a]lowpass=f=1250,highpass=f=35,volume=0.74,afade=t=out:st=0.16:d=0.76[n];[1:a]volume=0.78,afade=t=out:st=0.12:d=0.80[b];[n][b]amix=inputs=2:normalize=0,alimiter=limit=0.92" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/explosion.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "anoisesrc=color=white:duration=0.28:sample_rate=44100" \
	-filter_complex "highpass=f=550,lowpass=f=5200,volume=0.34,afade=t=in:st=0:d=0.025,afade=t=out:st=0.07:d=0.21" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/dodge.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "sine=frequency=1280:duration=0.055:sample_rate=44100" \
	-f lavfi -i "sine=frequency=940:duration=0.07:sample_rate=44100" \
	-filter_complex "[0:a]volume=0.24,afade=t=out:st=0.01:d=0.045[a];[1:a]volume=0.30,afade=t=out:st=0.015:d=0.055,adelay=190|190[b];[a][b]amix=inputs=2:normalize=0" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/reload.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "sine=frequency=880:duration=0.075:sample_rate=44100" \
	-filter_complex "volume=0.22,afade=t=out:st=0.02:d=0.055" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/ui_click.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "sine=frequency=520:duration=0.11:sample_rate=44100" \
	-f lavfi -i "sine=frequency=780:duration=0.16:sample_rate=44100" \
	-filter_complex "[0:a]volume=0.25,afade=t=out:st=0.03:d=0.08[a];[1:a]volume=0.26,afade=t=out:st=0.05:d=0.11,adelay=75|75[b];[a][b]amix=inputs=2:normalize=0" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/ui_confirm.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "sine=frequency=440:duration=0.22:sample_rate=44100" \
	-f lavfi -i "sine=frequency=550:duration=0.22:sample_rate=44100" \
	-f lavfi -i "sine=frequency=660:duration=0.48:sample_rate=44100" \
	-filter_complex "[0:a]volume=0.22,afade=t=out:st=0.14:d=0.08[a];[1:a]volume=0.22,afade=t=out:st=0.14:d=0.08,adelay=180|180[b];[2:a]volume=0.24,afade=t=out:st=0.24:d=0.24,adelay=360|360[c];[a][b][c]amix=inputs=3:normalize=0" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/victory.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "sine=frequency=165:duration=0.42:sample_rate=44100" \
	-f lavfi -i "sine=frequency=110:duration=0.58:sample_rate=44100" \
	-filter_complex "[0:a]volume=0.25,afade=t=out:st=0.2:d=0.22[a];[1:a]volume=0.28,afade=t=out:st=0.28:d=0.30,adelay=260|260[b];[a][b]amix=inputs=2:normalize=0" \
	-ac 1 -ar 44100 -c:a pcm_s16le "$OUT/defeat.wav"

"$FFMPEG" -y -loglevel error \
	-f lavfi -i "sine=frequency=55:duration=24:sample_rate=44100" \
	-f lavfi -i "sine=frequency=110:duration=24:sample_rate=44100" \
	-f lavfi -i "sine=frequency=220:duration=24:sample_rate=44100" \
	-f lavfi -i "sine=frequency=275:duration=24:sample_rate=44100" \
	-f lavfi -i "sine=frequency=330:duration=24:sample_rate=44100" \
	-filter_complex "[0:a]volume=0.13,lowpass=f=180[bass];[1:a]tremolo=f=2:d=0.78,volume=0.055[mid];[2:a]tremolo=f=2:d=0.90,volume=0.024[a];[3:a]tremolo=f=3:d=0.88,volume=0.018[b];[4:a]tremolo=f=4:d=0.86,volume=0.014[c];[bass][mid][a][b][c]amix=inputs=5:normalize=0,lowpass=f=6200,volume=8,alimiter=limit=0.78" \
	-ac 2 -ar 44100 -c:a pcm_s16le "$OUT/neon_bastion_loop.wav"

echo "Generated Neon Bastion audio assets in $OUT"
