# -*- coding: utf-8 -*-
"""Har sahifadagi matn miqdorini (qora piksel) o'lchaydi — darslar to'liqligini
saralash uchun. Manba skaner bo'lgani uchun matnni o'qib bo'lmaydi, lekin
sahifada qancha matn borligini piksel bo'yicha taqqoslash mumkin."""
import io, json, fitz
SRC = r"C:\Users\User\Downloads\durus-an-Nahviyya-1-2-3-4-qismlar (2).pdf"
d = fitz.open(SRC)
siyoh = {}
for i in range(d.page_count):
    pm = d[i].get_pixmap(matrix=fitz.Matrix(0.5, 0.5), colorspace=fitz.csGRAY)
    buf = pm.samples
    qora = sum(1 for b in buf if b < 128)
    siyoh[i + 1] = qora
io.open("nahv_ink.json", "w", encoding="utf-8").write(json.dumps(siyoh))
print("sahifalar:", len(siyoh), "| namuna 19:", siyoh.get(19), "20:", siyoh.get(20))
