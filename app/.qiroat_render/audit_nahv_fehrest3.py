# -*- coding: utf-8 -*-
"""3-kitob fehresti (266-269-sahifalar) ni JSON bilan solishtiradi."""
import json, re
from pathlib import Path

IDX = [
 (165,"مقدمة الكتاب"),
 (166,"اللغة العربية الكلمة وتقسيمها إلى فعل واسم وحرف"),
 (169,"الكلام على الحرف"),(173,"الكلام على الفعل"),
 (173,"تقسيم الفعل إلى ماض ومضارع وأمر"),
 (176,"تقسيم الفعل إلى مجرد ومزيد"),
 (179,"تقسيم الفعل إلى جامد ومتصرف"),
 (180,"نعم وبئس"),(181,"فعلا التعجب"),(182,"همزتا الوصل والقطع"),
 (184,"تقسيم الفعل إلى صحيح ومعتل"),
 (186,"تقسيم الفعل إلى لازم ومتعد"),
 (189,"تقسيم الفعل إلى مبني للمعلوم ومبني للمجهول"),
 (191,"تقسيم الفعل إلى مؤكد وغير مؤكد"),
 (193,"إعراب الفعل وبناؤه"),(193,"بيان المبني من الأفعال"),
 (195,"بيان المعرب من الأفعال"),(196,"نصب الفعل ومواضعه"),
 (199,"جزم الفعل ومواضعه"),(202,"رفع الفعل ومواضعه"),
 (202,"تتمة في الإعراب التقديري للفعل"),
 (204,"الكلام على الاسم"),(204,"تقسيم الاسم إلى جامد ومشتق"),
 (204,"تقسيم الجامد"),(206,"تقسيم المشتق"),
 (207,"اسم الفاعل"),(208,"اسم المفعول"),(208,"الصفة المشبهة"),
 (209,"اسما الزمان والمكان"),(210,"اسم الآلة"),(210,"اسم التفضيل"),
 (212,"تقسيم الاسم إلى مقصور ومنقوص وصحيح"),
 (213,"تقسيم الاسم إلى مفرد ومثنى وجمع"),
 (218,"تقسيم الاسم إلى مذكر ومؤنث"),
 (220,"تقسيم الاسم إلى نكرة ومعرفة"),
 (220,"الضمير"),(224,"العلم"),(224,"اسم الإشارة"),(225,"الموصول"),
 (226,"المحلى بأل"),(226,"المعرف بالإضافة"),(227,"المعرف بالنداء"),
 (228,"تقسيم الاسم إلى منون وغير منون"),
 (231,"إعراب الاسم وبناؤه"),(232,"بيان المعرب من الأسماء"),
 (233,"رفع الاسم ومواضعه"),(234,"الفاعل"),(235,"نائب الفاعل"),
 (235,"المبتدأ والخبر"),(236,"اسم كان وأخواتها"),(237,"خبر إن وأخواتها"),
 (241,"نصب الاسم ومواضعه"),(242,"المفعول به"),(243,"المفعول المطلق"),
 (244,"المفعول لأجله"),(245,"المفعول فيه"),(246,"المفعول معه"),
 (247,"المستثنى بإلا"),(248,"الحال"),(249,"التمييز"),(251,"المنادى"),
 (252,"خبر كان وأخواتها واسم إن وأخواتها"),
 (254,"جر الاسم ومواضعه"),(254,"المجرور بالحرف"),(254,"حروف الجر"),
 (256,"المضاف إليه"),(256,"تتمة في الإعراب التقديري للاسم"),
 (258,"التوابع"),(258,"النعت"),(260,"العطف"),(261,"التوكيد"),(263,"البدل"),
 (265,"نهاية في الإعراب المحلي"),
]

DIAC = re.compile(r'[\u064B-\u0652\u0670\u0640]')
def norm(s):
    s = DIAC.sub('', s)
    for a,b in (('أ','ا'),('إ','ا'),('آ','ا'),('ى','ي'),('ة','ه'),('ؤ','و'),('ئ','ي')):
        s = s.replace(a,b)
    return re.sub(r'[^\u0621-\u064A]', '', s)

d = json.loads(Path('app/assets/content/nahv_lessons.json').read_text(encoding='utf-8'))
b3 = [x for x in d['lessons'] if x['book'] == 3]
titles = [(norm(x.get('titleAr') or ''), x['page'], x['num']) for x in b3]
bodies = []
for x in b3:
    parts = [(x.get('rule') or {}).get('ar','')]
    for b in x.get('blocks', []):
        parts.append(b.get('ar',''))
        if isinstance(b.get('intro'), dict): parts.append(b['intro'].get('ar',''))
    bodies.append((norm(' '.join(parts)), x['page'], x['num']))

miss = []
for pg, head in IDX:
    h = norm(head); hit = None
    for t,p,n in titles:
        if t and (h in t or t in h) and abs(p-pg) <= 3: hit=1; break
    if not hit:
        for t,p,n in titles:
            if t and (h in t or t in h): hit=1; break
    if not hit:
        for t,p,n in bodies:
            if h and h in t and abs(p-pg) <= 8: hit=1; break
    if not hit: miss.append((pg, head))

print('fehrestdagi sarlavhalar:', len(IDX))
print('topilmagan:', len(miss))
for pg, head in miss: print('  s.%d  %s' % (pg, head))

# Kutilgan natija: 73 tadan 3 tasi "topilmagan" bo'lib chiqadi — uchalasi ham
# YOLG'ON signal, "tuzatish" kerak emas:
#   s.166 — sahifada bosilgan sarlavha yo'q, fehrest matn boshidan sarlavha
#           yasagan; kontent 2-darsda to'liq (ikkala izoh bilan).
#   s.202, s.256 — kitobda faqat «تَتِمَّةٌ» deb bosilgan, fehrest tavsifiy
#           quyruq qo'shgan; matn 17- va 59-darslar bloklari ichida turibdi.
