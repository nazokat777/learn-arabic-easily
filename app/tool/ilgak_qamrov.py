# Qaysi Qiroat so'zlarida ilgak yo'q — kitob bo'yicha.
import json,io,re,sys
D=re.compile('[\u064B-\u0652\u0653-\u0655\u0656-\u0670\u065F\u0640\u06D6-\u06ED\u08D3-\u08FF]')
il=json.load(io.open('assets/content/ilgak.json',encoding='utf-8'))['sozlar']
ks={k.replace('؟','').strip() for k in il}
q=json.load(io.open('assets/content/qiroat_lessons.json',encoding='utf-8'))['lessons']
for b in (1,2,3):
  miss=[]; n=0
  for l in q:
    if l.get('book',1)!=b: continue
    for v in l['vocab']:
      n+=1
      a=re.split('[،,]',v['ar'])[0].split('=')[0].strip()
      k=D.sub('',a).replace('\u200d','').replace('؟','').replace('?','').strip()
      if k not in ks: miss.append(a)
  print(b,'jami',n,'ilgaksiz',len(miss))
