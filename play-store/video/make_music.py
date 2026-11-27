#!/usr/bin/env python3
"""Generates an original, sleek, upbeat royalty-free electronic-tech background soundtrack WAV
for the Ghost Play Play Store promo video.
Zero external dependencies (Python stdlib only). Usage: make_music.py <duration_sec> <out.wav>
"""
import math, random, struct, sys, wave

SR = 44100


def mtof(m):
    return 440.0 * (2.0 ** ((m - 69) / 12.0))


def generate(dur, out_path):
    n_samples = int(dur * SR)
    bpm = 118.0
    beat_s = 60.0 / bpm          # ~0.508s
    bar_s = beat_s * 4           # ~2.034s
    sixteenth_s = beat_s / 4.0

    # Sleek, modern, uplifting progression: Em9 -> Cmaj7 -> Gmaj7 -> D6 (1 bar each)
    chords = [
        [52, 55, 59, 62, 66],  # Em9
        [48, 52, 55, 59, 64],  # Cmaj7
        [55, 59, 62, 66, 67],  # Gmaj7
        [50, 54, 57, 59, 62],  # D6
    ]
    roots = [40, 36, 43, 38]  # E2, C2, G2, D2
    arp_pattern = [0, 2, 3, 4, 2, 3, 1, 4]

    buf_l = [0.0] * n_samples
    buf_r = [0.0] * n_samples
    rng = random.Random(77)

    # Pre-build tight punchy kick, crisp hi-hat, and soft rim/clap
    kick_len = int(0.24 * SR)
    kick = []
    ph = 0.0
    for i in range(kick_len):
        t = i / SR
        freq = 42.0 + 74.0 * math.exp(-t * 34.0)
        ph += 2.0 * math.pi * freq / SR
        env = math.exp(-t * 13.5) * min(1.0, t * 420.0)
        kick.append(math.sin(ph) * env * 0.40)

    hat_len = int(0.042 * SR)
    hat = []
    prev = 0.0
    for i in range(hat_len):
        t = i / SR
        w = rng.uniform(-1.0, 1.0)
        hp = w - prev * 0.87
        prev = w
        hat.append(hp * math.exp(-t * 100.0) * 0.065)

    snap_len = int(0.09 * SR)
    snap = []
    prev_s = 0.0
    for i in range(snap_len):
        t = i / SR
        w = rng.uniform(-1.0, 1.0)
        bp = (w - prev_s * 0.72) * math.exp(-t * 48.0)
        prev_s = w
        snap.append(bp * 0.11)

    # 1. Drums (clean four-on-the-floor kick + soft backbeat snap + subtle shaker groove)
    total_beats = int(dur / beat_s) + 1
    for b in range(total_beats):
        start = int(b * beat_s * SR)
        if b < 2:  # airy intro before groove drops
            continue
        for i in range(kick_len):
            idx = start + i
            if idx < n_samples:
                buf_l[idx] += kick[i]
                buf_r[idx] += kick[i]
        if b % 2 == 1:
            for i in range(snap_len):
                idx = start + i
                if idx < n_samples:
                    buf_l[idx] += snap[i] * 0.92
                    buf_r[idx] += snap[i] * 1.08

    total_16 = int(dur / sixteenth_s) + 1
    for s in range(total_16):
        if s % 4 == 0:
            continue
        accent = 1.0 if (s % 4 == 2) else 0.42
        start = int(s * sixteenth_s * SR)
        pan_l = 0.62 if (s % 2 == 0) else 0.42
        pan_r = 1.05 - pan_l
        for i in range(hat_len):
            idx = start + i
            if idx < n_samples:
                v = hat[i] * accent
                buf_l[idx] += v * pan_l
                buf_r[idx] += v * pan_r

    # 2. Warm lush synth pads + rhythmic deep bass + crystalline glass-pluck arpeggio
    total_bars = int(dur / bar_s) + 1
    for bar in range(total_bars):
        ci = bar % len(chords)
        chord = chords[ci]
        root_f = mtof(roots[ci])
        bar_start = int(bar * bar_s * SR)
        bar_len = int(bar_s * SR)

        # Warm stereo pad chords with gentle sidechain breathing
        freqs = [mtof(n) for n in chord]
        for i in range(bar_len):
            idx = bar_start + i
            if idx >= n_samples:
                break
            t = i / SR
            beat_phase = (t % beat_s) / beat_s
            duck = 0.52 + 0.48 * min(1.0, beat_phase * 3.2)
            env = min(1.0, t * 7.0) * min(1.0, (bar_s - t) * 7.0) * duck * 0.052
            sl = 0.0
            sr = 0.0
            for fi, f in enumerate(freqs):
                det = 1.0020 if (fi % 2 == 0) else 0.9980
                sl += math.sin(2.0 * math.pi * f * t) + 0.18 * math.sin(4.0 * math.pi * f * t)
                sr += math.sin(2.0 * math.pi * f * det * t) + 0.18 * math.sin(4.0 * math.pi * f * det * t)
            buf_l[idx] += sl * env
            buf_r[idx] += sr * env

        # Smooth pulsing sub-bass
        for step in range(8):
            if step in (0, 2, 3, 5, 6):
                st = bar_start + int(step * (beat_s / 2.0) * SR)
                blen = int(0.25 * SR)
                for i in range(blen):
                    idx = st + i
                    if idx >= n_samples:
                        break
                    t = i / SR
                    env = min(1.0, t * 110.0) * math.exp(-t * 7.2) * 0.17
                    v = math.sin(2.0 * math.pi * root_f * t) + 0.25 * math.sin(4.0 * math.pi * root_f * t)
                    buf_l[idx] += v * env
                    buf_r[idx] += v * env

        # Crystalline bell-pluck arpeggio (subtle stereo ping-pong)
        for step in range(8):
            note = chord[arp_pattern[step]] + 12
            f = mtof(note)
            st = bar_start + int(step * (beat_s / 2.0) * SR)
            plen = int(0.30 * SR)
            pan = 0.36 if (step % 2 == 0) else 0.64
            for i in range(plen):
                idx = st + i
                if idx >= n_samples:
                    break
                t = i / SR
                env = min(1.0, t * 260.0) * math.exp(-t * 9.5) * 0.082
                v = (
                    math.sin(2.0 * math.pi * f * t)
                    + 0.32 * math.sin(4.0 * math.pi * f * t) * math.exp(-t * 16.0)
                    + 0.12 * math.sin(6.0 * math.pi * f * t) * math.exp(-t * 26.0)
                )
                buf_l[idx] += v * env * (1.0 - pan) * 1.4
                buf_r[idx] += v * env * pan * 1.4

    # 3. Gentle fade-in / fade-out + soft normalization
    fade_in = int(0.6 * SR)
    fade_out = int(2.2 * SR)
    peak = max(1e-6, max(max(abs(x) for x in buf_l), max(abs(x) for x in buf_r)))
    gain = 0.72 / peak

    frames = bytearray(n_samples * 4)
    for i in range(n_samples):
        env = 1.0
        if i < fade_in:
            env = i / fade_in
        elif i > n_samples - fade_out:
            env = max(0.0, (n_samples - i) / fade_out)
        l = max(-0.98, min(0.98, buf_l[i] * gain * env))
        r = max(-0.98, min(0.98, buf_r[i] * gain * env))
        struct.pack_into("<hh", frames, i * 4, int(l * 32767), int(r * 32767))

    with wave.open(out_path, "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(frames)


if __name__ == "__main__":
    generate(float(sys.argv[1]), sys.argv[2])
