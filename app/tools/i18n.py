#!/usr/bin/env python3
"""Extrai os textos do jogo e gera os arquivos de idioma (gettext .po).

O português é o idioma-fonte: cada texto em português é a chave (msgid).
  i18n/pt_BR.po  -> português (msgstr = msgid)
  i18n/en.po     -> inglês; traduções existentes são preservadas
  i18n/en.json   -> traduções em inglês para mesclar (opcional; chave = texto em pt)

Uso (na pasta app/):  python3 tools/i18n.py
Para um idioma novo: copie i18n/en.po para i18n/xx.po, traduza os msgstr e
acrescente o idioma em Game.LANGUAGES e em project.godot (locale/translations).
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_FILES = {"scripts/ui/cheat_console.gd", "scripts/music_synth.gd", "scripts/autoload/music.gd"}
LIT = re.compile(r'"((?:[^"\\]|\\.)*)"')
TECH = re.compile(r'^[a-z0-9_./:%#&+-]+$')


def unescape(s):
    return s.encode("utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")


def candidates():
    found = []
    seen = set()

    def add(t):
        t = t.strip()
        if not t or t in seen:
            return
        if not re.search(r"[A-Za-zÀ-ú]", t) or len(t) < 2:
            return
        if len(t) == 32 and re.fullmatch(r"[#.@?\w~<>&|-]{32}", t):
            return  # linhas das telas das fases
        if TECH.match(t) or re.fullmatch(r"[0-9a-fA-F]{6,8}", t):
            return
        if t.startswith(("res://", "user://")) or t.endswith((".gd", ".tscn", ".png", ".svg", ".json")):
            return
        if "shader_type" in t or "void fragment" in t:
            return
        seen.add(t)
        found.append(t)

    for f in sorted(glob.glob(os.path.join(ROOT, "scripts/**/*.gd"), recursive=True)):
        rel = os.path.relpath(f, ROOT)
        if rel in SKIP_FILES:
            continue
        in_multiline = False
        for line in open(f, encoding="utf-8"):
            st = line.strip()
            if '"""' in st:
                in_multiline = st.count('"""') == 1 and not in_multiline
                continue
            if in_multiline or st.startswith("#"):
                continue
            # Ignora o que está depois de um comentário de linha
            code = line.split(" #")[0] if '"' not in line.split(" #")[-1] else line
            for m in LIT.finditer(code):
                raw = unescape(m.group(1))
                if "|" in raw and ("||" in raw or re.match(r"^[^|]{1,40}\|", raw)):
                    # Falas dos moradores: "Nome|fala||Nome|fala"
                    for part in raw.split("||"):
                        if "|" in part:
                            who, say = part.split("|", 1)
                            add(who)
                            add(say)
                        else:
                            add(part)
                else:
                    add(raw)
    return found


def po_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t")


def po_unescape(s):
    return s.replace("\\n", "\n").replace("\\t", "\t").replace('\\"', '"').replace("\\\\", "\\")


def read_po(path):
    out = {}
    if not os.path.exists(path):
        return out
    msgid = msgstr = None
    cur = None
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if line.startswith("msgid "):
            if msgid is not None and msgstr:
                out[po_unescape(msgid)] = po_unescape(msgstr)
            msgid = line[7:-1]
            msgstr = None
            cur = "id"
        elif line.startswith("msgstr "):
            msgstr = line[8:-1]
            cur = "str"
        elif line.startswith('"') and cur:
            if cur == "id":
                msgid += line[1:-1]
            else:
                msgstr += line[1:-1]
    if msgid is not None and msgstr:
        out[po_unescape(msgid)] = po_unescape(msgstr)
    out.pop("", None)
    return out


def write_po(path, lang, entries):
    with open(path, "w", encoding="utf-8") as f:
        f.write('msgid ""\nmsgstr ""\n')
        f.write('"Content-Type: text/plain; charset=UTF-8\\n"\n')
        f.write(f'"Language: {lang}\\n"\n\n')
        for k, v in entries:
            f.write(f'msgid "{po_escape(k)}"\nmsgstr "{po_escape(v)}"\n\n')


def main():
    ids = candidates()
    write_po(os.path.join(ROOT, "i18n/pt_BR.po"), "pt_BR", [(k, k) for k in ids])
    en = read_po(os.path.join(ROOT, "i18n/en.po"))
    jpath = os.path.join(ROOT, "i18n/en.json")
    if os.path.exists(jpath):
        en.update(json.load(open(jpath, encoding="utf-8")))
    missing = [k for k in ids if not en.get(k)]
    write_po(os.path.join(ROOT, "i18n/en.po"), "en", [(k, en.get(k, "")) for k in ids])
    print(f"{len(ids)} textos; faltam {len(missing)} traduções em inglês.")
    if "--missing" in sys.argv:
        json.dump(missing, open(os.path.join(ROOT, "i18n/missing_en.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=0)


if __name__ == "__main__":
    main()
