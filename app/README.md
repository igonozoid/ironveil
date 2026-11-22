# IRONVEIL — As Caldeiras · O Mercado Suspenso · A Torre do Diretório

Plataforma cinematográfico 2D (side-scroller) feito em **Godot 4** (testado no 4.7.2).
Sera Vael, engenheira acusada de sabotagem, foge das Caldeiras de Ironveil, atravessa o Mercado
Suspenso e sobe a Torre do Diretório. O jogo completo contém:
- **Ato 1 — As Caldeiras**: introdução animada, 3 fases e o chefão Martelo-de-Vapor.
- **Ato 2 — O Mercado Suspenso**: 3 fases (abismo, tábuas podres, tirolesas, holofotes,
  multidão, guardas com escudo) e o chefão dirigível Vigília.
- **Ato 3 — A Torre do Diretório**: 3 fases (torretas, pistões esmagadores, autômatos,
  plataformas de engrenagem), o chefão final Regulador e a tela de encerramento.
- Rolamento (esquiva), sangue que gruda nas pessoas, no cenário e na tela, e a roupa de Sera
  que se suja.
- Visual: iluminação 2D dinâmica (lâmpadas, janelas, lanternas, holofotes, clarões de tiro e
  explosão), pós-processamento por ato (gradação de cor, brilho, vinheta, grão) e tremor de
  tela suave. Tudo desenhado por código, sem imagens externas.
- Controles de toque para Android e builds para Linux, Windows, macOS e Android.
- O mapa de progressão de fases (com repetição de fases concluídas), menu, checkpoints e telas
  de fim de ato.

As regras completas estão em [MECHANICS.md](MECHANICS.md).

## Requisitos

- Godot **4.7** ou mais recente (versão padrão, não a .NET — o projeto é só GDScript).
- Renderizador "Compatibility" (OpenGL 3.3 / OpenGL ES 3): roda até em máquinas modestas.

## Como rodar

### Pelo editor
1. Abra o Godot e clique em **Importar**.
2. Selecione `app/project.godot`.
3. Aperte **F5** (Executar projeto).

### Pela linha de comando
Godot instalado normalmente:

```bash
godot --path app
```

Godot instalado via Flatpak:

```bash
flatpak run org.godotengine.Godot --path app
```

Na primeira execução o Godot importa os recursos (alguns segundos).

## Controles

Setas: mover · Z: pular · X: atirar · C: rolar (esquiva) · ↑ junto à reentrância:
encostar · ↑ + X: rebite de escalada · A: interagir · S: usar ferramenta · Q: trocar
ferramenta · Esc: pausa. Controles de videogame também funcionam (veja MECHANICS.md).

## Exportar (Linux, Windows, macOS e Android)

O projeto traz `export_presets.cfg` com quatro presets:

| Preset | Saída | Observações |
|---|---|---|
| **Linux** | `ironveil.x86_64` | 64 bits, `.pck` embutido (um arquivo só). No Linux: `chmod +x` e execute. |
| **Windows Desktop** | `ironveil.exe` | 64 bits, `.pck` embutido. Exporta do Linux sem ferramentas extras (`application/modify_resources` desligado: ligue e configure o `rcedit` se quiser ícone e metadados no `.exe`). |
| **macOS** | `ironveil-macos.zip` | App universal (Intel + Apple Silicon), assinatura ad-hoc, sem notarização. No primeiro uso: clique com o botão direito no app → **Abrir** (ou `xattr -dr com.apple.quarantine Ironveil.app`). |
| **Android** | `ironveil.apk` | arm64 e armv7, tela cheia, paisagem. Controles de toque aparecem sozinhos em telas de toque. |

### Builds automáticos (GitHub Actions)
`.github/workflows/build.yml` roda o teste de fumaça e exporta as quatro plataformas a cada push
na `main`; os arquivos ficam em **Actions → build → Artifacts**. Ao criar uma tag `v*`
(ex.: `git tag v1.0.0 && git push --tags`), eles também vão para um **Release**.

Android sem configuração extra gera um **APK de depuração** (instale por sideload, permitindo
"fontes desconhecidas"). Para um APK de release assinado, crie uma keystore e cadastre em
*Settings → Secrets and variables → Actions*:
- `ANDROID_KEYSTORE_BASE64`: a keystore em base64 (`base64 -w0 release.keystore`);
- `ANDROID_KEYSTORE_ALIAS`: o alias da chave;
- `ANDROID_KEYSTORE_PASSWORD`: a senha.

Nunca coloque a keystore nem as senhas no repositório (o `.gitignore` já barra `*.keystore`).

### Exportar na sua máquina
1. Instale os modelos de exportação da **mesma versão** do editor: **Editor → Gerenciar modelos
   de exportação → Baixar e instalar**.
2. Exporte pelo editor (**Projeto → Exportar…**) ou pela linha de comando, a partir de `app/`:

```bash
mkdir -p ../build/linux ../build/windows ../build/macos ../build/android
```

```bash
godot --headless --path . --export-release "Linux" ../build/linux/ironveil.x86_64
```

```bash
godot --headless --path . --export-release "Windows Desktop" ../build/windows/ironveil.exe
```

```bash
godot --headless --path . --export-release "macOS" ../build/macos/ironveil-macos.zip
```

Android também precisa do Android SDK e do JDK 17 em **Editor → Configurações do Editor →
Exportar → Android** (e de uma keystore de depuração, que o editor cria sozinho):

```bash
godot --headless --path . --export-debug "Android" ../build/android/ironveil.apk
```

(Com Flatpak, troque `godot` por `flatpak run org.godotengine.Godot`.)

## Teste de fumaça automatizado

`tests/test_runner.tscn` simula entradas e verifica as mecânicas principais das 3 fases (correr,
giro, agarrar/subir/descer bordas, túnel agachada, reentrância × guarda, tiros, válvula, carga
de vapor, elevadores, caixa de força + grade, painel, cartão, rebite de escalada, Tomé +
guindaste, drone e a luta do chefão: elevador da arena, checkpoint, pontos fracos, vapor, onda
de choque, derrota) e do Ato 2 (tábua podre, tirolesa, holofote e reforço, guarda com escudo,
multidão e linha de tiro, Lira, livro de válvulas, arpão, âncora, derrota do dirigível,
checkpoint da arena, mapa) e do Ato 3 (sangue em Sera, nos guardas, no fundo e na tela; rolamento
contra tiros, investida e vão baixo; torreta; pistão; autômato; plataforma; o Regulador com
pêndulo, freio, núcleo e derrota; migração de save; tela final). O teste guarda e restaura o
save do jogador:

```bash
godot --headless --path . res://tests/test_runner.tscn
```

A última linha deve ser `RESULT: ALL PASS`. A pasta `tests/` não entra nas exportações.

## Estrutura

```
app/
├── project.godot            configuração (640×360, autoloads Game e Sfx)
├── export_presets.cfg       presets Linux, Windows, macOS e Android
├── scenes/                  main_menu.tscn, intro.tscn, game.tscn, progress_map.tscn, end_screen.tscn
├── resources/ui_theme.tres  tema da interface (cobre/ferrugem)
├── scripts/
│   ├── autoload/            game_state.gd (estado, save, controles), sfx.gd (sons sintetizados)
│   ├── levels/level_data.gd telas ASCII das 9 fases + textos de dica
│   ├── level.gd             monta colisão, desenho, fundo e entidades a partir das telas
│   ├── game.gd              mundo: câmera por tela, morte, transições, HUD, partículas de ambiente
│   ├── fx/                  post_process.gdshader (pós-processamento) e light.gd (luzes 2D)
│   ├── blood.gd             sangue: gotas, manchas, escorridos, poças, gibs, sangue no fundo
│   ├── splats.gd            manchas de sangue grudadas no corpo dos personagens
│   ├── player.gd            Sera
│   ├── entities/            guarda, drone, jatos, válvula, alavanca, painel, elevadores,
│   │                        portas, grades, caixa de força, rebites, itens, Tomé,
│   │                        chefão (boss.gd) e onda de choque; Ato 2: tirolesa, tábua,
│   │                        holofote, civil, Lira, livro, dirigível (airship.gd),
│   │                        bomba, canhão-arpão; Ato 3: plataforma de engrenagem,
│   │                        pistão, torreta, autômato, engrenagem que cai, freio e
│   │                        o Regulador (regulator.gd)…
│   └── ui/                  HUD, diálogo, pausa, menu inicial, introdução animada,
│                            mapa de fases (progress_map.gd), telas de fim de ato,
│                            sangue na tela (screen_blood.gd), pós-processamento
│                            (post_fx.gd), controles de toque (touch_controls.gd)
└── tests/                   teste de fumaça
```

O save fica em `user://ironveil_save.json` (no Linux: `~/.local/share/godot/app_userdata/Ironveil/`;
no Windows: `%APPDATA%\Godot\app_userdata\Ironveil\`).
