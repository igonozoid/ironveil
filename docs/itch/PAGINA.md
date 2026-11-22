# Página do IRONVEIL no itch.io

Textos e configurações prontos para copiar em **itch.io → Create new project**
(`https://itch.io/game/new`).

## Campos principais

| Campo | Valor |
|---|---|
| **Title** | IRONVEIL |
| **Project URL** | `ironveil` (a página fica em `https://SEU-USUARIO.itch.io/ironveil`) |
| **Short description / tagline** | Plataforma cinematográfico em cinco atos: vapor, latão e uma conspiração que fecha o céu. |
| **Classification** | Games |
| **Kind of project** | Downloadable |
| **Release status** | Released (ou In development, se preferir) |
| **Pricing** | No payments (grátis) — ou "Donate" para aceitar doações |
| **Uploads** | deixe vazio: o GitHub Actions envia os builds sozinho (veja abaixo) |
| **Genre** | Platformer |
| **Tags** | `steampunk`, `cinematic-platformer`, `2d`, `story-rich`, `gore`, `godot`, `pixel-art`, `stealth`, `boss-battles`, `atmospheric` |
| **AI generation disclosure** | Sim: o código, a arte desenhada por código, a música procedural e os textos foram criados com ajuda de IA (Claude). |
| **Custom noun** | game |
| **Languages** | Portuguese (Brazil), English |
| **Inputs** | Keyboard, Xbox controller, Touchscreen |
| **Accessibility** | Configurable controls, (opcional) "Interactive tutorial" |
| **Content / Metadata → Classification** | marque violência/sangue (há gore, que pode ser desligado) |
| **Cover image** | `docs/itch/cover_630x500.png` |
| **Screenshots** | as 10 imagens de `docs/screenshots/` |
| **Visibility** | Draft até conferir tudo; depois Public |

Na aba **Edit theme** dá para usar `docs/itch/banner_960x300.png` como banner do topo e as cores:
fundo `#120f14`, texto `#e8d6be`, links `#e0b860`.

---

## Descrição (cole no campo Description)

### Português

**IRONVEIL** é um plataforma cinematográfico 2D em cinco atos.

Ironveil é uma cidade vertical lacrada dentro de uma montanha. Quando a Caldeira Sul explode e mata
vinte e três pessoas, o Diretório aponta uma culpada: **Sera Vael**, a engenheira-chefe de
manutenção. Para provar a verdade ela vai subir das Caldeiras ao Mercado Suspenso e à Torre do
Diretório, descer até a Fornalha-Mãe e, no fim, abrir o **Véu de Ferro** que esconde o céu.

- **15 fases e 5 chefões**, cada um com um jeito diferente de ser vencido — descubra.
- Movimento com peso: correr, agarrar bordas, rolar, encostar nas frestas da parede.
- O cenário como arma: válvulas de vapor, grades que despencam, pistões, cargas explosivas, água
  que endurece o ferro fundido.
- Furtividade: holofotes, multidões para se misturar, guardas que não atiram com civis na frente.
- **Upgrades** a cada chefão: mais vida, arpão de mão, couraça e botas de pressão.
- Moradores que conversam e dão dicas — e reagem ao sangue (fogem, vomitam, rezam).
- Iluminação 2D dinâmica, trilha sonora procedural por ato e gore opcional.
- Mapa de fases para repetir qualquer fase, checkpoints e save automático.
- **Português e inglês**, teclas configuráveis, controle e tela de toque (Android).

Tudo — arte, sons e música — é gerado por código, sem nenhuma imagem ou áudio externo.

### English

**IRONVEIL** is a five-act 2D cinematic platformer.

Ironveil is a vertical city sealed inside a mountain. When the South Boiler explodes and kills
twenty-three people, the Directorate names a culprit: **Sera Vael**, the chief maintenance
engineer. To prove the truth she must climb from the Boilers to the Hanging Market and the
Directorate Tower, descend to the Mother Furnace, and finally open the **Iron Veil** that hides
the sky.

- **15 stages and 5 bosses**, each beaten a different way — figure it out.
- Weighty movement: run, grab ledges, roll, press into wall alcoves.
- The world as a weapon: steam valves, falling grates, pistons, explosive charges, water that
  crusts molten iron.
- Stealth: searchlights, crowds to blend into, guards who won't shoot through civilians.
- **Upgrades** from every boss: extra health, a hand harpoon, brass armor and pressure boots.
- Townsfolk who talk and give tips — and react to blood (they flee, vomit, pray).
- Dynamic 2D lighting, a procedural soundtrack for each act, and optional gore.
- A stage map to replay any stage, checkpoints and autosave.
- **Portuguese and English**, rebindable keys, gamepad and touchscreen (Android).

Everything — art, sound and music — is generated in code, with no external images or audio.

### Instalação / Installation

- **Windows**: extraia e abra `ironveil.exe` (SmartScreen: *Mais informações → Executar assim mesmo*).
- **Linux**: `./ironveil.x86_64`
- **macOS**: clique com o botão direito em *Ironveil.app → Abrir* na primeira vez.
- **Android**: instale o APK permitindo "apps desconhecidos".

Código-fonte: https://github.com/igonozoid/ironveil

---

## Envio automático dos builds (GitHub → itch.io)

O workflow `.github/workflows/build.yml` envia os builds com o **butler** (a ferramenta oficial do
itch.io) a cada tag `v*`, nos canais `windows`, `linux`, `osx` e `android`. Configuração única:

1. Crie a página (acima) e anote o endereço, por exemplo `seu-usuario/ironveil`.
2. Gere uma chave em **itch.io → Settings → API keys → Generate new API key**.
3. Guarde a chave como secret do repositório (nunca no código):
   `gh secret set BUTLER_API_KEY` (cole a chave quando pedir) ou em
   *GitHub → Settings → Secrets and variables → Actions → New repository secret*.
4. Diga ao workflow qual é a página: `gh variable set ITCH_GAME --body "seu-usuario/ironveil"`.
5. Publique uma versão: `git tag v1.3.0 && git push origin v1.3.0`.

A mesma tag atualiza o **Release do GitHub** e o **itch.io**. Depois do primeiro envio, confira
em *Edit game* se cada arquivo ficou com a plataforma certa e publique a página.
