import math
S=256; C=S/2
out=[]
out.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">')
out.append('''<defs>
<radialGradient id="bg" cx="50%" cy="45%" r="70%"><stop offset="0" stop-color="#3a2a22"/><stop offset="1" stop-color="#120f14"/></radialGradient>
<linearGradient id="brass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f0d27a"/><stop offset="0.5" stop-color="#b8863a"/><stop offset="1" stop-color="#6e4a22"/></linearGradient>
<linearGradient id="iron" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4c5260"/><stop offset="1" stop-color="#23262e"/></linearGradient>
<linearGradient id="light" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff4cf"/><stop offset="0.45" stop-color="#ffc35a"/><stop offset="1" stop-color="#ff8a2a" stop-opacity="0.15"/></linearGradient>
<radialGradient id="glow" cx="50%" cy="60%" r="50%"><stop offset="0" stop-color="#ffb347" stop-opacity="0.55"/><stop offset="1" stop-color="#ffb347" stop-opacity="0"/></radialGradient>
<clipPath id="inner"><circle cx="128" cy="128" r="84"/></clipPath>
</defs>''')
out.append(f'<rect width="{S}" height="{S}" rx="44" fill="url(#bg)"/>')
# gear teeth
teeth=16; R1=100; R2=116
pts=[]
for i in range(teeth*4):
    a=2*math.pi*i/(teeth*4)
    r=R2 if (i%4) in (1,2) else R1
    pts.append(f"{C+r*math.cos(a):.1f},{C+r*math.sin(a):.1f}")
out.append(f'<polygon points="{" ".join(pts)}" fill="url(#brass)"/>')
out.append(f'<circle cx="{C}" cy="{C}" r="{R1-4}" fill="#2a2018"/>')
out.append(f'<circle cx="{C}" cy="{C}" r="88" fill="#16131a"/>')
# inner scene clipped
out.append('<g clip-path="url(#inner)">')
out.append(f'<rect x="40" y="40" width="176" height="176" fill="#1b1a24"/>')
out.append(f'<ellipse cx="128" cy="168" rx="90" ry="70" fill="url(#glow)"/>')
# light slit
out.append('<polygon points="122,40 134,40 162,216 94,216" fill="url(#light)" opacity="0.9"/>')
# dome plates: left and right halves, opened at center
for side in (-1,1):
    for k in range(4):
        x0 = 128 + side*(10 + k*22)
        x1 = 128 + side*(10 + (k+1)*22)
        ytop0 = 44 + (k*k)*2.5
        ytop1 = 44 + ((k+1)*(k+1))*2.5
        poly=[(x0,ytop0),(x1,ytop1),(x1,ytop1+70-k*6),(x0,ytop0+76-k*6)]
        p=" ".join(f"{x:.1f},{y:.1f}" for x,y in poly)
        out.append(f'<polygon points="{p}" fill="url(#iron)" stroke="#11131a" stroke-width="2"/>')
        # rivets
        for r in range(3):
            ry=ytop0+14+r*20
            rx=(x0+x1)/2
            out.append(f'<circle cx="{rx:.1f}" cy="{ry:.1f}" r="2.4" fill="#8c95a6"/>')
    # glowing edge on the slit
    ex=128+side*10
    out.append(f'<line x1="{ex}" y1="44" x2="{ex}" y2="120" stroke="#ffd98a" stroke-width="2.5"/>')
# floor / city rim
out.append('<path d="M40 190 Q128 176 216 190 L216 216 L40 216 Z" fill="#0d0b10"/>')
out.append('<path d="M40 190 Q128 176 216 190" fill="none" stroke="#ff9a3c" stroke-width="2" opacity="0.8"/>')
# Sera silhouette in the light
out.append('''<g fill="#0b0a0e">
<circle cx="128" cy="142" r="6"/>
<path d="M122 149 L134 149 L133 168 L123 168 Z"/>
<path d="M123 168 L127 168 L125 184 L120 184 Z"/>
<path d="M129 168 L133 168 L136 184 L131 184 Z"/>
<path d="M123 141 Q114 140 109 147 Q115 144 121 146 Z"/>
<path d="M133 152 L144 136 L146 138 L135 155 Z"/>
</g>''')
out.append('</g>')
# inner ring highlight
out.append(f'<circle cx="{C}" cy="{C}" r="88" fill="none" stroke="#e0b860" stroke-width="3"/>')
out.append(f'<circle cx="{C}" cy="{C}" r="18" fill="none"/>')
# bolts on gear
for i in range(8):
    a=2*math.pi*i/8+math.pi/8
    out.append(f'<circle cx="{C+94*math.cos(a):.1f}" cy="{C+94*math.sin(a):.1f}" r="3" fill="#5a3e1e"/>')
out.append('</svg>')
open('/home/igonoz/Documents/_projects/Claude_IronVeil/app/icon.svg','w').write("\n".join(out))
print("ok")
