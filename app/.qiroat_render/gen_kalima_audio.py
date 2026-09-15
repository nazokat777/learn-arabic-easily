# -*- coding: utf-8 -*-
"""«kalima» to'plami — so'zlarning INSON ovozi (Lingua Libre, Wikimedia
Commons, CC BY-SA 4.0 / CC0).

Kirish: build/kalima_topildi.json (kalima_qidir.py) — har so'z uchun
Commons'dagi yozuvlar (so'zlovchilar). Bu yerda:
  1. so'zlovchi tanlanadi: eng ko'p so'zi bor so'zlovchi birinchi (bir xil
     ovoz), yo'q bo'lsa keyingisi;
  2. fayl yuklab olinadi (429 uchun sekin: 1.2 s, qayta urinish);
  3. faster-whisper bilan TEKSHIRILADI: transkripsiya (harakatsiz) so'zga
     teng bo'lishi shart — teng bo'lmasa keyingi so'zlovchi, hech biri
     mos kelmasa so'z tashlab ketiladi (xato ovoz — eng yomon holat);
  4. kesish (jimlik), balandlik (RMS −19 dB, cho'qqi ≤ −1.5), 0.3 s jimlik.

Kalit: so'zning ilovadagi HARAKATLI shakli — lekin Lingua Libre
so'zlovchisi so'zni PAUZA shaklida aytadi (tanvin o'qilmaydi: «kitaab»,
«kitaabun» emas). Shuning uchun manifest kaliti tanvinsiz/oxirgi
harakatsiz shakl (pauza): «كِتَاب». Ulash darsining yangi bosqichlari
so'zni aynan shu shaklda ko'rsatadi.

Natija: assets/audio/kalima/kNNNN.mp3, kalima_manifest.json,
ATTRIBUTION.txt (so'zlovchilar ro'yxati).
"""
import json, re, subprocess, sys, time, urllib.parse, urllib.request
from collections import Counter
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
API = "https://commons.wikimedia.org/w/api.php"
UA = {"User-Agent": "LearnArabicEasily/1.0 (https://nazokat777.github.io/learn-arabic-easily/; shakhalimov7@gmail.com)"}
SRC = Path("build/kalima_topildi.json")
XOM = Path("build/kalima_xom")
OUT = Path("assets/audio/kalima")
MANIFEST = Path("assets/audio/kalima_manifest.json")
HARAKAT = re.compile(r"[ً-ْٰـ]")
TANVIN_OXIR = re.compile(r"[ًٌٍَُِْ]+$")


def yalang(s): return HARAKAT.sub("", s).strip()


def pauza(ar: str) -> str:
    """Oxirgi tanvin/harakat olib tashlanadi (vaqf): كِتَابٌ → كِتَاب;
    ـةٌ → ـة (ta marbuta o'qilishi «a» — belgi qoladi)."""
    return TANVIN_OXIR.sub("", ar.strip())


def get(p):
    p.update(format="json")
    for k in range(6):
        try:
            req = urllib.request.Request(API + "?" + urllib.parse.urlencode(p), headers=UA)
            return json.load(urllib.request.urlopen(req))
        except Exception:
            time.sleep(4 * (k + 1))
    return {}


URLS = {}  # File:… → (url, lic) — 50 talik paketda olinadi (API 429 ga tushmasin)


def urllarni_ol(titles):
    kerak = [t for t in titles if t not in URLS]
    for i in range(0, len(kerak), 50):
        d = get({"action": "query", "titles": "|".join(kerak[i:i + 50]), "prop": "imageinfo",
                 "iiprop": "url|extmetadata"})
        for p in d.get("query", {}).get("pages", {}).values():
            ii = p.get("imageinfo", [{}])[0]
            if ii.get("url"):
                URLS[p["title"]] = (ii["url"], ii.get("extmetadata", {}).get("LicenseShortName", {}).get("value", ""))
        time.sleep(1.0)


def yukla(title: str, dest: Path) -> bool:
    if dest.exists() and dest.stat().st_size > 1000:
        return True
    if title not in URLS:
        urllarni_ol([title])
    if title not in URLS:
        return False
    url, lic = URLS[title]
    for k in range(5):
        try:
            req = urllib.request.Request(url, headers=UA)
            data = urllib.request.urlopen(req).read()
            # 429/HTML sahifa .wav bo'lib qolmasin — RIFF sarlavhasi shart.
            if len(data) < 1000 or not (data[:4] == b"RIFF" or data[:4] == b"OggS" or data[:4] == b"fLaC"):
                raise ValueError("audio emas")
            dest.write_bytes(data)
            dest.with_suffix(".lic").write_text(lic, encoding="utf-8")
            time.sleep(0.4)
            return True
        except Exception:
            time.sleep(4 * (k + 1))
    return False


def main():
    top = json.loads(SRC.read_text(encoding="utf-8"))
    bor = {k: v for k, v in top.items() if v["fayllar"]}
    tartib = [s for s, _ in Counter(f["sozlovchi"] for v in bor.values() for f in v["fayllar"]).most_common()]
    print("so'zlar:", len(bor), "so'zlovchilar:", tartib[:6], flush=True)
    # Barcha nomzod fayllarning URL'i bir yo'la (har so'z uchun 3 tagacha).
    urllarni_ol([f["fayl"] for v in bor.values()
                 for f in sorted(v["fayllar"], key=lambda f: tartib.index(f["sozlovchi"]))[:3]])
    print("url:", len(URLS), flush=True)

    from faster_whisper import WhisperModel
    model = WhisperModel("small", device="cpu", compute_type="int8")

    def eshit(path: Path) -> list[str]:
        """Yolg'iz qisqa so'zda whisper gallyutsinatsiya qiladi (شكرا, مرحبا);
        3 marta takrorlab (0.5 s jimlik bilan) transkripsiya barqaror bo'ladi.
        Qaytaradi: eshitilgan so'zlar (harakatsiz)."""
        x3 = path.with_suffix(".x3.wav")
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(path), "-i", str(path), "-i", str(path),
                        "-filter_complex",
                        "[0:a]apad=pad_dur=0.5[a];[1:a]apad=pad_dur=0.5[b];[a][b][2:a]concat=n=3:v=0:a=1,apad=pad_dur=0.5",
                        "-ar", "16000", "-ac", "1", str(x3)], capture_output=True)
        segs, _ = model.transcribe(str(x3), language="ar", beam_size=5, condition_on_previous_text=False)
        x3.unlink(missing_ok=True)
        t = yalang(" ".join(s.text for s in segs))
        return [w for w in re.split(r"[\s،,.؟!]+", t) if w]

    def norm(s: str) -> str:
        return (s.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا").replace("ة", "ه")
                 .replace("ى", "ي").replace("ال", "", 1) if s.startswith("ال") else
                s.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا").replace("ة", "ه").replace("ى", "ي"))

    def oxshash(a: str, b: str) -> float:
        import difflib
        return difflib.SequenceMatcher(None, a, b).ratio()

    def tekshir(y: str, sozlar: list[str]):
        """(mos keldimi, tanvin bilan o'qilganmi). So'zlovchi «بابون» desa —
        tanvinli o'qish: kalit tanvinli shakl bo'ladi."""
        if not sozlar:
            return False, False
        from collections import Counter
        w = Counter(sozlar).most_common(1)[0][0]
        ny, nw = norm(y), norm(w)
        if oxshash(ny, nw) >= 0.8:
            return True, False
        # tanvin: oxirida ن / ون / ين / ان (بابون, كتابن, بيتن)
        for q in ("ون", "ين", "ان", "ن"):
            if nw.endswith(q) and oxshash(ny, nw[: -len(q)]) >= 0.8:
                return True, True
        return False, False

    XOM.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}
    hisob = {"ok": 0, "rad": 0, "yoq": 0}
    manba = {}
    n = max([int(v[1:5]) for v in manifest.values()] + [-1]) + 1
    for y, v in bor.items():
        kalit = pauza(v["ar"])
        if kalit in manifest:
            continue
        fayllar = sorted(v["fayllar"], key=lambda f: tartib.index(f["sozlovchi"]))
        tanlandi = None
        for f in fayllar[:3]:
            xom = XOM / (re.sub(r"[^\w]+", "_", f["fayl"]) + ".wav")
            if not yukla(f["fayl"], xom):
                continue
            try:
                sozlar = eshit(xom)
            except Exception as e:  # buzuq fayl — o'chirib, keyingisiga
                print(f"  buzuq {f['fayl']}: {e}", flush=True)
                xom.unlink(missing_ok=True)
                continue
            ok, tanvinli = tekshir(y, sozlar)
            if ok:
                tanlandi = (f, xom, tanvinli)
                break
            print(f"  rad {y}: {f['sozlovchi']} → «{' '.join(sozlar)}»", flush=True)
        if not tanlandi:
            hisob["rad" if fayllar else "yoq"] += 1
            continue
        f, xom, tanvinli = tanlandi
        # Tanvin bilan o'qilgan bo'lsa — kalit to'liq (kitobdagi) shakl.
        if tanvinli:
            kalit = v["ar"].strip()
        dest = OUT / f"k{n:04d}.mp3"
        kes = ("silenceremove=start_periods=1:start_threshold=-40dB,"
               "areverse,silenceremove=start_periods=1:start_threshold=-40dB,areverse,"
               "highpass=f=70,afade=t=in:d=0.01")
        o = subprocess.run(["ffmpeg", "-v", "info", "-i", str(xom), "-af", kes + ",volumedetect",
                            "-f", "null", "-"], capture_output=True, text=True).stderr
        try:
            mean = float(re.search(r"mean_volume: (\S+)", o).group(1))
            peak = float(re.search(r"max_volume: (\S+)", o).group(1))
        except AttributeError:
            hisob["rad"] += 1
            continue
        gain = min(-19.0 - mean, -1.5 - peak)
        r = subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(xom), "-af",
                            f"{kes},volume={gain:.2f}dB,apad=pad_dur=0.3",
                            "-ac", "1", "-ar", "24000", "-b:a", "48k", str(dest)], capture_output=True)
        if r.returncode != 0:
            hisob["rad"] += 1
            continue
        manifest[kalit] = dest.name
        manba[dest.name] = {"fayl": f["fayl"], "sozlovchi": f["sozlovchi"], "tanvin": tanvinli,
                            "lic": (xom.with_suffix(".lic").read_text(encoding="utf-8") if xom.with_suffix(".lic").exists() else "")}
        hisob["ok"] += 1
        n += 1
        print(f"{kalit}  ← {f['sozlovchi']}{' (tanvin)' if tanvinli else ''}", flush=True)
        MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=0), encoding="utf-8", newline="\n")
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=0), encoding="utf-8", newline="\n")
    mp = OUT / "manba.json"
    eski = json.loads(mp.read_text(encoding="utf-8")) if mp.exists() else {}
    eski.update(manba)
    mp.write_text(json.dumps(eski, ensure_ascii=False, indent=1), encoding="utf-8", newline="\n")
    sozlovchilar = sorted({m["sozlovchi"] for m in eski.values()})
    (OUT / "ATTRIBUTION.txt").write_text(
        "So'zlar ovozi: Lingua Libre (lingualibre.org) orqali Wikimedia Commons'ga yozilgan yozuvlar, "
        "litsenziya CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/).\n"
        "So'zlovchilar: " + ", ".join(sozlovchilar) + ".\n"
        "Har fayl manbasi: manba.json. Fayllar kesilgan va balandligi normalizatsiya qilingan.\n",
        encoding="utf-8")
    print(hisob, "jami:", len(manifest))


if __name__ == "__main__":
    main()
