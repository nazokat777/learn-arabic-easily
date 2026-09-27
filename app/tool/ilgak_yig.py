# ilg/*.tsv -> assets/content/ilgak.json  (kalit: harakatsiz arabcha)
import io,json,glob,re,sys,os
D=re.compile('[\u064B-\u0652\u0653-\u0655\u0656-\u0670\u065F\u0640\u06D6-\u06ED\u08D3-\u08FF]')
src=sys.argv[1] if len(sys.argv)>1 else 'tool/ilgak'
out={}
for f in sorted(glob.glob(os.path.join(src,'*.tsv'))):
    for n,ln in enumerate(io.open(f,encoding='utf-8'),1):
        ln=ln.rstrip('\n')
        if not ln.strip(): continue
        p=ln.split('\t')
        assert len(p)==4,(f,n,ln)
        k=D.sub('',p[0]).replace('\u200d','').strip()
        out[k]={'o':p[1],'i':p[2],'s':p[3]}
io.open('assets/content/ilgak.json','w',encoding='utf-8').write(json.dumps({'meta':{'izoh':"Mnemonik ilgaklar: o — o'qilishi, i — tovushdosh tanish so'z, s — sahna. Kitob matni emas, yodlash yordamchisi."},'sozlar':out},ensure_ascii=False,indent=0))
print(len(out))
