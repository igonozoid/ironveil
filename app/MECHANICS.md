# IRONVEIL — Atos 1 a 5 · Regras e mecânicas

Ironveil é uma cidade vertical lacrada dentro de uma montanha. Sera Vael, engenheira-chefe de
manutenção, é acusada de sabotagem e foge das Caldeiras (o nível mais baixo da cidade), subindo
em direção ao Mercado Suspenso. Os guardas do Diretório a perseguem. No **Ato 2** ela atravessa o
Mercado Suspenso e encontra a prova de que a explosão da Caldeira Sul foi ordenada pela Torre do
Diretório (seção 12). No **Ato 3** ela sobe a Torre do Diretório e enfrenta o Diretor Halvard
Maar no alto do relógio-mestre (seção 13).

Gênero: plataforma cinematográfico 2D, side-scroller. Resolução interna 640×360 (escala para
1280×720). O mundo é uma grade de células de 20 px; cada tela tem 32×18 células.

---

## 1. Controles

| Ação | Teclado | Controle |
|---|---|---|
| Mover | Setas ← → | Direcional / analógico esquerdo |
| Agachar | ↓ | Direcional ↓ / analógico para baixo |
| Pular | Z | A (Xbox) / ✕ |
| Atirar | X | X (Xbox) / ▢ ou gatilho direito |
| Rolar (esquiva) | C | LB / gatilho esquerdo |
| Trotar / correr (alterna) | Shift | L3 (apertar o analógico) |
| Tela cheia | F11 | — |
| Encostar (junto a uma reentrância) | ↑ | Direcional ↑ |
| Rebite de escalada | segurar ↑ + X | ↑ + X |
| Interagir | A | B (Xbox) / ◯ |
| Usar ferramenta | S | Y (Xbox) / △ |
| Trocar ferramenta | Q | RB |
| Pausa | Esc | Start |

Nos menus: setas para navegar, Enter / Espaço / Z para confirmar.

---

## 2. Sera

Origem do personagem = pés. Corpo de 10×28 px em pé e 10×16 px agachada.

### 2.1 Movimento com peso
- **Andar**: 80 px/s. Arranca em ~0,06 s e para em ~0,05 s: resposta rápida, sem deslizar.
- **Correr**: segurando a direção por 0,2 s Sera embala até 150 px/s. No analógico, uma
  inclinação leve (< 65%) só anda.
- **Virar**: inverter a direção dispara uma pequena animação de giro (0,07 s; o corpo "gira"
  pelo eixo). Virar correndo vira uma derrapada curta (0,12 s) que freia o embalo.
- **Agachar** (↓): 40 px/s. Cabe em vãos de 1 célula de altura e faz os tiros dos guardas
  passarem por cima. Se não houver espaço para levantar, Sera continua agachada.
- **Queda**: cair mais de 180 px (9 células) causa 1 de dano e um atordoamento de 0,55 s.

### 2.2 Pulos
- **Pulo curto** (parada ou andando): ~43 px de altura e pouco avanço; parada, o pulo é vertical.
- **Pulo longo** (correndo): mantém a velocidade de corrida, alcança ~4,5 células de distância.
- Bom controle aéreo: dá para corrigir a trajetória no ar, sem passar da velocidade do pulo. Há uma pequena tolerância (0,1 s) para
  pular logo depois de sair de uma borda.

### 2.3 Bordas
- **Agarrar**: no ar, caindo ou no topo do pulo, de frente para uma parede cujo topo esteja na
  altura das mãos, Sera se pendura automaticamente. Alcance prático: paredes de até 3 células.
- **Subir**: ↑ ou Z pendurada. Sobe e avança para cima da borda (agacha se não houver espaço).
- **Soltar**: ↓, ou empurrar para longe da parede.
- **Descer de bordas**: agachada na beirada de um bloco, aperte Z: Sera se vira e desce até
  ficar pendurada pelo lado de fora.
- **Plataformas vazadas** (e pinos de rebite): agachada em cima, Z atravessa para baixo.

### 2.4 Encostar
- Junto a uma **reentrância** na parede do fundo (nicho escuro com moldura de cobre e lâmpada),
  aperte ↑ para encostar.
- Encostada, Sera é **imune a tiros** e os guardas **não atiram**. Ela não anda nem atira.
- Vapor e explosões ainda ferem Sera encostada.
- Sair: ↓, ←, → ou Z.

### 2.5 Lança-rebites
- X dispara um rebite reto para a frente (cadência de 0,3 s, munição infinita), na altura do peito,
  ou na altura da cintura se agachada.
- Para atirar para o outro lado, vire (o giro é rápido) ou role (C) já na direção certa.
- Rebites ferem guardas (1 de dano), destroem drones, cortam caixas de força e ricocheteiam
  em paredes, portas e grades.

### 2.5.1 Rolamento (C)
- No chão, C faz Sera **rolar** na direção apertada (ou para onde olha): rápida, rente ao chão,
  por 0,36 s, com 0,22 s de recarga.
- **Rolando, Sera não toma dano** de tiros, ondas de choque, explosões, vapor, lâminas e investidas.
  Os tiros passam por ela. Só **queda** e **esmagamento** (pistões, grades) ainda ferem.
- Rolando, ela tem a altura de agachada: passa por vãos baixos. Se terminar embaixo de algo, fica
  agachada até sair.
- Bater numa parede encerra o rolamento. Rolar para fora de uma borda vira queda normal.

### 2.6 Rebite de escalada
- Pontos marcados nas paredes (anel amarelo pulsante) aceitam o rebite de escalada.
- Segure ↑ e aperte X a até 170 px de um ponto acima de Sera, com linha de visão livre.
- O rebite crava um **pino**: um ponto de agarrar onde Sera se pendura (pulando até ele) e sobre
  o qual pode ficar de pé (é uma plataforma vazada). Pendurada num pino sem espaço acima, Z salta.

### 2.7 Interagir (A)
Religar máquinas: alavancas, válvulas, painéis, caixas de força, elevador de saída e conversar
com NPCs. O HUD mostra a ação disponível na parte de baixo da tela.

### 2.8 Vida
- 4 pontos, **sem regeneração automática**. Só o Selante cura.
- Após levar dano, 1 s de invulnerabilidade (Sera pisca).
- Dano: tiro 1, vapor 1 (a cada 0,35 s dentro do jato), explosão 1, drone 1, queda alta 1,
  grade caindo 2.
- Com 0 de vida Sera cai e a fase recomeça do **checkpoint** (início da fase), com a vida e o
  inventário que ela tinha ao entrar na fase.

---

## 3. Ferramentas (inventário)

A ferramenta selecionada aparece no canto superior direito. **Q** troca (só entre as que Sera
possui), **S** usa. Ao pegar um item sem ter nada selecionado, ele é selecionado automaticamente.

| Ferramenta | Item no chão | Efeito |
|---|---|---|
| **Carga de vapor** | lata de cobre com luz vermelha (+2) | Arremessada num arco; quica; **explode após 2 s** (raio 46 px). Destrói grades, causa 2 de dano a guardas (derruba), destrói drones, corta caixas de força e fere Sera (1) se ela estiver perto. |
| **Selante** | tubo verde (+1) | Cura **2 pontos** de vida (máx. 4). Não é gasto com a vida cheia. |
| **Cartão de acesso** | cartão amarelo (+1) | Abre uma **porta de segurança** próxima. É **consumido** ao usar; sem porta por perto não é gasto. |

---

## 4. Inimigos

### 4.1 Guarda do Diretório (vermelho-escuro)
- **Patrulha** ida e volta (até 5 células do ponto inicial), parando e virando em paredes,
  beiradas e no limite da ronda.
- **Visão**: 240 px à frente, mesma altura (±44 px) e linha de visão livre. Também percebe Sera
  colada às costas (< 24 px). Não vê Sera encostada.
- Ao ver Sera ("!" acima da cabeça) alterna em ciclo:
  1. **Mira** (0,6 s, com laser vermelho de aviso)
  2. **Atira** 2 vezes (0,38 s entre tiros), na altura do peito: Sera agachada desvia.
  3. **Se abriga** (1,4 s) atrás de um escudo: fica **imune a rebites** (som metálico).
  4. Se ainda vê Sera, volta a mirar; senão, volta a patrulhar.
- **2 rebites** derrotam um guarda. Levar um rebite pelas costas faz o guarda virar e reagir.
- **Sera encostada**: o guarda **não atira**; espera 2,5 s (com "?") e **volta a patrulhar**
  (virando de costas). Se Sera sair da reentrância enquanto ele espera, ele volta a mirar.
- Também morre com vapor (1 de dano por pulso), explosões (2) e esmagado por grade.

### 4.2 Drone de vapor
- Voa em padrão fixo: horizontal (vai e vem), vertical (sobe e desce) ou circular.
- **Explode ao tocar Sera** (1 de dano, raio pequeno que também fere guardas próximos).
- Um rebite, vapor ou explosão o destroem. Os drones baixos passam por cima de Sera agachada.

### 4.3 Chefão: Martelo-de-Vapor (Capataz Ordo)
Andador blindado vermelho-escuro com um martelo hidráulico, uma metralhadora no braço e um
tanque de caldeira nas costas. Fica na **Plataforma do Elevador**, a última tela da fase 3, e
trava o elevador para o Mercado até cair. Tem **20 de vida** (barra no alto da tela).

**Ataques** (sempre virado para Sera):
- **Rajada alta**: a mira vermelha aparece na altura do peito e depois vêm 5 tiros.
  Escape agachando ou encostando na reentrância.
- **Rajada baixa**: a mira amarela aparece na altura das canelas e depois vêm 3 tiros.
  Escape pulando ou encostando.
- **Martelada**: ele ergue o martelo, que brilha em vermelho, e bate no chão à frente.
  - O golpe direto tira 2 de vida.
  - Saem **duas ondas de choque** pelo chão, uma para cada lado. É preciso **pular** por cima:
    encostar não protege.
- Ele não atira em Sera encostada. Em vez disso, prepara uma martelada para tirá-la de lá.
- Andar por baixo dele enquanto ele caminha fere Sera (1, pisão).

**Pontos fracos**:
- **Tanque das costas**: o rebite sempre causa 1 de dano. Atire de trás: role (**C**) por baixo
  dele e vire.
- **Núcleo da frente**: abre por ~1,4 s depois de cada martelada e enquanto ele está atordoado.
  Nesse intervalo o rebite pela frente causa 1. Com o núcleo fechado, a frente é blindada.
- **Jato de vapor**: atraia o Martelo para cima dos dois bocais do chão e abra a válvula. Causa
  2 de dano, ele fica **atordoado** por 2,2 s com o núcleo aberto, e o efeito pode se repetir
  a cada 3 s.
- **Carga de vapor**: causa 2 de dano e atordoa por pouco tempo se ele estiver andando ou
  atirando.
- **Explosão de drone** perto dele: causa 1 de dano.

**Segunda metade** (vida ≤ 10, "PRESSÃO MÁXIMA!"):
- Ele fica mais rápido: anda mais, mira por menos tempo, dispara rajadas mais longas e as
  ondas de choque correm mais.
- Dá **duas marteladas seguidas**.
- Lança **drones**: um varre o chão na altura do peito e o outro gira acima. Nunca há mais de
  2 drones dele ao mesmo tempo.

**Suprimentos**: com vida 14 e com vida 6, um cano do teto estoura e derruba **2 cargas de
vapor** do lado oposto ao chefão. A arena também tem uma carga e um selante.

**Derrota**:
- Explosões em cadeia.
- A cabine se despedaça, com sangue e gibs do piloto se a opção de gore estiver ligada.
- A carcaça fica soltando fumaça no chão.
- O elevador para o Mercado é liberado.

### 4.4 Regra geral
Inimigos só agem na tela em que Sera está. Tiros saem da tela e somem.

---

## 5. Cenário interativo — sabotagem como alternativa ao combate

| Elemento | Como funciona |
|---|---|
| **Válvula** (roda vermelha) | A: abre por 3 s os jatos de vapor ligados a ela (todos os bocais acionáveis da mesma tela). Recarrega em 3,6 s. |
| **Jato de vapor** | Coluna de vapor (até 5 células). Fere **Sera, guardas e drones**. Bocais de chão sobem; de teto descem. |
| **Jato periódico** | Liga 1,5 s / desliga 2,1 s sozinho; avisa 0,5 s antes (borbulha e luz laranja). Atravesse no intervalo. |
| **Alavanca** | A: aciona o elevador de carga mais próximo (sobe/desce entre dois andares). |
| **Elevador de carga** | Plataforma de 3 células com cabos; leva Sera e o que estiver em cima. |
| **Painel** | A: religa a energia da porta blindada mais próxima (abre a porta). |
| **Porta blindada** | Listras amarelas; bloqueia até um painel religá-la. |
| **Porta de segurança** | Azul-acinzentada com luz amarela; abre com o Cartão de acesso. |
| **Grade** | Barra a passagem; só uma carga de vapor a destrói. |
| **Grade suspensa + caixa de força** | A grade fica pendurada por corrente eletromagnética. Cortar a corrente (rebite, A ou explosão na **caixa de força**) faz a grade despencar: **esmaga guardas** embaixo (fere Sera em 2) e vira plataforma. |
| **Reentrância** | Ponto de encostar (seção 2.4). |
| **Elevador de saída** | Luz verde piscando. Em cima dele, A: sobe e encerra a fase. |

---

## 6. Aliado: Tomé (operador de guindaste)

- Encontrado no Poço do Guindaste (fase 3), ao lado do console do guindaste (macacão ocre, boné).
- A: abre um diálogo curto em caixa de texto (A / Z / Enter avançam; apertar durante a digitação
  completa a fala).
- Ao fim da conversa ele **destrava o gancho do guindaste**: com Sera parada em cima por 0,7 s,
  o gancho a leva pelo poço vertical até o andar de cima (atalho vertical). Lá em cima ele espera
  Sera descer antes de poder ser usado de novo.
- Antes da conversa o gancho fica travado (luz vermelha).

---

## 7. Estrutura do Ato 1

- **Câmera fixa por tela**: cada tela (32×18 células) é um enquadramento fixo; ao sair pela
  borda a câmera corta para a tela vizinha (horizontal ou vertical).
- 3 fases curtas; **cada uma termina num elevador** que leva à próxima:

| Fase | Telas | Conteúdo |
|---|---|---|
| 1 — **Caldeira Norte** | 3 | Tutorial: correr, pular, agarrar/subir/descer bordas, túnel agachada; primeiro guarda com reentrância e válvula de vapor; grade destruída com carga de vapor; jatos periódicos; drone vertical; elevador de saída. |
| 2 — **Sala das Bombas** | 3 | Alavanca + elevador de carga; caixa de força + grade suspensa sobre um guarda (vire e atire na caixa); sala das bombas com drones, painel que abre a porta blindada, cartão de acesso; porta de segurança; rebite de escalada para vencer uma parede de 6 células; guarda no andar de cima; elevador de saída. |
| 3 — **Poço do Guindaste** | 4 | Guarda sob jatos de teto (válvula); Tomé e o guindaste; subida pelo poço; último guarda e drone; elevador do poço até a **Plataforma do Elevador**; **chefão: Martelo-de-Vapor**; elevador para o Mercado Suspenso. |

- **Fim do ato**: tela "Ato 1 concluído" — Sera, no alto do poço, vê a luz dourada do Mercado
  Suspenso acima. Em seguida o **mapa de fases** mostra Sera andando até a fase 4, a primeira do
  Ato 2 (estrutura na seção 12). A vida volta ao máximo no começo de cada ato.

### Checkpoint e salvamento
- O jogo salva no início de cada fase (`user://ironveil_save.json`): fase, vida, inventário e
  ferramenta selecionada.
- Morrer ou escolher **Reiniciar fase** (pausa) volta ao início da fase com esse estado.
- **Checkpoint do chefão**: ao chegar à Plataforma do Elevador o jogo salva de novo, com a vida
  e o inventário daquele momento. Morrer na luta recomeça ali, e o diálogo de abertura fica
  curto. Os itens da arena reaparecem.
- **Continuar** no menu inicial carrega o último checkpoint. **Novo jogo** sobrescreve o save.
- O checkpoint do chefão vale também para o Ato 2. A arena dos telhados não tem elevador de
  entrada, então o checkpoint é gravado ao entrar na tela.
- **Progresso permanente**: ao chegar ao elevador do fim de uma fase, ela é registrada como
  concluída. Concluir as 3 fases de um ato registra o ato como concluído.
  - O menu inicial mostra o resumo de cada ato.
  - O mapa de fases mostra ✓ em cada fase terminada e ★ em cada ato concluído.
  - Esse registro não é apagado por **Novo jogo**.

### Mapa de fases (progressão)
- **Onde abre**: no menu inicial (**Mapa de fases**), na pausa e automaticamente entre uma fase e
  outra.
- **O que mostra**: um corte da montanha-cidade.
  - Embaixo, as 3 fases das Caldeiras (Ato 1). Acima, as 3 do Mercado Suspenso (Ato 2).
  - No alto, as 3 fases da Torre do Diretório (Ato 3), com os nomes à esquerda.
  - Os chefões aparecem como ícones: martelo, dirigível e relógio.
  - Os caminhos entre fases concluídas ficam acesos em cobre. Sera aparece na fase do
    checkpoint.
- **Entre fases** ("travel"): Sera anda pelo mapa até a próxima fase. Z / Enter começa a fase.
- **Pelo menu** ("browse"):
  - **Escolher fase**: ←/→ (ou ↑/↓, ou clique).
  - **Informações**: o painel à direita mostra ato, nome, situação, descrição e chefão.
  - **Fases liberadas**: as concluídas, a do checkpoint e a seguinte a uma concluída.
  - **Z / A / Enter**:
    - Na fase do checkpoint: continua dali.
    - Numa fase concluída: **repete** a fase. A repetição começa com vida cheia e um kit básico,
      não mexe no checkpoint salvo e, ao terminar, volta ao mapa.
    - Numa fase nova liberada: começa a fase.
  - **Esc**: volta ao menu.

---

## 8. Introdução, sangue e efeitos

### Introdução animada
- **Novo jogo** abre uma cutscene desenhada por código, em 7 cenas com barras de cinema e
  narração digitada: a montanha de Ironveil; a cidade em corte (do Mercado Suspenso às
  Caldeiras); a explosão da Caldeira Sul; o Diretório acusando Sera (cartaz de PROCURADA); a
  fuga pelos corredores; o poço com a luz no alto; o título.
- **Z / A / Enter**: completa o texto ou avança para a próxima cena.
- **Esc / Start** ou o botão **"Pular ▶▶"**: pula a introdução inteira e começa a Fase 1.
- O menu inicial tem **Ver introdução** para assistir de novo.

### Sangue e gore (opção, ligada por padrão)
- **Rebite num guarda**: jato de sangue na direção do tiro, mais um respingo para trás.
- **Guarda morto** (rebite ou vapor): cai, espirra sangue e deixa uma **poça** que cresce.
- **Explosão ou grade caindo**: o guarda é **despedaçado**, com gibs que quicam e sangram,
  muito sangue em todas as direções e uma poça.
- **Sera ferida**: espirra sangue; ao morrer, explosão de sangue e poça.
- **Sangue nas pessoas**: gotas que voam grudam em quem estiver no caminho — Sera, guardas,
  autômatos e civis — e ficam no corpo, acompanhando o personagem quando ele vira ou agacha.
  Civis respingados se assustam e fogem.
- **Roupa de Sera**: o sangue alheio e o dela mesma (ao ser ferida) mancham o macacão, que também
  vai escurecendo de sujeira. As manchas continuam depois de morrer ou trocar de fase e só somem
  no começo de cada ato (ou num jogo novo).
- **Cenário**: parte das gotas se espatifa na **parede do fundo**, atrás da ação, com respingos e
  escorridos.
- **Tela**: quando alguém é ferido ou despedaçado perto de Sera, o sangue **espirra na tela**
  em manchas que escorrem devagar e somem em alguns segundos.
- As gotas voam com gravidade e viram **manchas permanentes** no chão, nas paredes e no teto.
  Algumas **escorrem** pela parede. As manchas ficam até a fase recomeçar.
- Drones explodem em pedaços de metal, sem sangue.
- **Hitstop**: o jogo congela por uma fração de segundo ao derrubar um guarda ou levar dano.
- A opção **"Sangue e gore: Ligado/Desligado"** fica no menu inicial e na pausa, e é salva.
  Desligada, o sangue vira faíscas e destroços.

### Iluminação e pós-processamento
- **Luzes 2D**: o mundo fica um pouco mais escuro por tema e as luzes clareiam por cima:
  janelas de caldeira e feixes do alto (Ato 1), lanternas e o brilho do abismo (Ato 2),
  arandelas e luar das janelas (Ato 3), a lâmpada de cada reentrância, o cone dos holofotes
  (vermelho no alarme), o núcleo do Regulador e uma luz suave em Sera. Tiros e explosões
  soltam clarões rápidos. Só as luzes da tela atual ficam acesas.
- **Pós-processamento** (opção **Efeitos**, no menu e na pausa): gradação de cor por ato
  (Caldeiras quentes, Mercado ao entardecer, Torre fria), brilho nos pontos claros, vinheta e
  grão de filme leves. Ao levar dano, a imagem se separa em cores por um instante; com 1 de vida,
  as bordas pulsam em vermelho e a cor perde força.
- **Tremor de tela**: por "trauma" que soma a cada impacto e decai em tempo real (senos, sem
  chiado aleatório). Hitstops seguidos não se atrapalham.
- **Esticar e achatar**: Sera estica ao pular e achata ao pousar (mais forte em quedas altas).

### Controles de toque (Android)
Em telas de toque aparecem botões na tela: direcional à esquerda; à direita **Z** pular,
**X** atirar, **C** rolar, **A** usar, **S** ferramenta, **Q** trocar; **II** pausa no alto.
Os botões mostram as mesmas letras das dicas. Menus, mapa, introdução e telas de fim aceitam toque.

### Partículas
- Ambiente por fase: brasas e poeira (Caldeira Norte), gotejamento (Sala das Bombas), poeira
  dourada e brasas (Poço do Guindaste).
- Poeira ao pular, pousar, correr e derrapar; fumaça no cano do lança-rebites e do rifle;
  explosões com fogo, fumaça, faíscas e destroços.

## 9. Interface

- **Canto superior esquerdo**: vida (4 blocos azul-claros).
- **Canto superior direito**: ferramenta selecionada (ícone, nome, quantidade).
- **Alto, ao centro** (só na luta do chefão): barra de vida do Martelo-de-Vapor. Ela muda de cor
  na segunda metade da luta.
- **Caixa de diálogo** e **painel de dicas** de tutorial: no **alto da tela**, logo abaixo da
  vida e da ferramenta, para não cobrir a área de jogo. Abrir um diálogo esconde a dica.
- **Embaixo, ao centro**: ação contextual disponível (ex.: "A: abrir válvula", "↑: encostar") e,
  logo acima dela, mensagens curtas (itens coletados, portas abertas etc.).
- **Menu inicial**: Novo jogo (abre a introdução), Continuar (mostra a fase do checkpoint),
  Mapa de fases, Ver introdução, Sangue e gore (liga/desliga), Sair. Embaixo: fases concluídas
  por ato.
- **Pausa** (Esc): Continuar, Reiniciar fase, Sangue e gore, Mapa de fases, Menu principal, Sair.

---

## 10. Visual e áudio

- Formas geométricas e cores chapadas, sem sprites. Personagens são desenhados por código com
  animação procedural (passada, corrida inclinada, giro, agachar, pendurar, encostar).
- **Sera**: macacão azul-claro com cintura e busto, alça e cinto de cobre, botas e luvas,
  cabelo escuro com franja e rabo de cavalo, óculos de proteção na testa, rosto com olho, nariz,
  boca e piscadas. Movimento secundário: **respiração** (tronco e ombros) parada,
  **rabo de cavalo** com física de mola (balança com passos, vento da corrida, pulos e pousos) e
  **busto** com uma mola discreta que acompanha passos, pulos e pousos.
- **Encostada**, Sera aparece **de frente** para a câmera (costas na parede), com o rosto
  iluminado pela lâmpada da reentrância.
- Paleta: ferrugem, cobre e cinza-escuro; vapor em branco. **Sera em azul-claro**, **guardas em
  vermelho-escuro**, Tomé em ocre.
- Sons sintetizados na inicialização (sem arquivos de áudio): rebite, tiro do guarda, impacto,
  ricochete, explosão, vapor, passos, pulo, pouso, alavanca, porta, elevador, itens, diálogo e um
  zumbido ambiente de caldeira em loop.

---

## 11. Formato das fases (para editar ou criar telas)

As fases ficam em `scripts/levels/level_data.gd`. Cada tela é uma lista de 18 linhas com 32
caracteres. Telas são identificadas por `"x,y"` (y negativo = acima). Dicas `?` usam os textos
da lista `hints` da tela, na ordem de leitura (linha a linha, da esquerda para a direita).

| Char | Significado | Char | Significado |
|---|---|---|---|
| `#` | parede/chão | `.` | vazio |
| `-` | plataforma vazada | `@` | início de Sera |
| `R` | reentrância (encostar) | `?` | dica |
| `G` | guarda | `D` `d` `o` | drone horizontal / vertical / circular |
| `V` | válvula | `v` `w` | jato p/ cima / p/ baixo (acionado pela válvula) |
| `p` | jato periódico | `L` | alavanca (elevador mais próximo) |
| `E` / `e` | elevador: base / destino (mesma coluna, na linha do piso) | `P` | painel (porta blindada mais próxima) |
| `B` | porta blindada (desce até o chão) | `S` | porta de segurança |
| `H` | grade quebrável | `F` | grade suspensa (3 células) |
| `J` | caixa de força (grade suspensa mais próxima) | `O` | ponto de rebite de escalada |
| `T` | Tomé | `K` / `k` | guindaste: base / topo |
| `X` | elevador de saída (sobe 7 células; travado se houver chefão na tela) | `1` `2` `3` | carga (+2) / selante / cartão |
| `Y` / `y` | elevador da arena: base / destino (mesma coluna, na linha do piso; grava checkpoint ao chegar) | `M` | chefão (Martelo-de-Vapor) |
| `Z` / `z` | tirolesa: início (alto) / fim, ligados ao mais próximo | `b` | tábua podre |
| `N` | holofote (vira para o centro da tela) | `c` | civil |
| `g` | guarda com escudo | `l` | Lira (abre a porta blindada mais próxima) |
| `Q` | livro de válvulas (armário) | `h` | canhão-arpão |
| `A` | chefão: dirigível Vigília (a altura do chão é a do primeiro sólido abaixo) | `&` | ponto de retorno do checkpoint do chefão (arena sem elevador) |
| `m` / `n` | plataforma de engrenagem: início / fim (liga ao mais próximo; horizontal ou vertical) | `u` | pistão esmagador (do teto ao chão da coluna) |
| `t` | torreta-sentinela (vira para o centro da tela) | `a` | autômato |
| `f` | freio do pêndulo (lado pela metade da tela) | `W` | chefão: o Regulador (a altura do chão é a do primeiro sólido abaixo) |

Opções por fase: `"theme": "market"` / `"tower"` (visual do Mercado / da Torre), `"abyss": true` (sem chão sob as telas
de baixo: cair é fatal) e `"boss_title"` (título mostrado ao voltar no checkpoint do chefão).

Bordas de tela sem vizinha ganham paredes invisíveis; células fora das telas contam como sólidas.

---

## 12. Ato 2 — O Mercado Suspenso

### História
Sera chega ao Mercado Suspenso: plataformas de comércio penduradas por correntes sobre o abismo
das Caldeiras. Lira, uma contrabandista do Bazar, conta que o **livro de válvulas** da Caldeira
Sul está no arquivo do Diretório.

Nos telhados, Sera abre o armário e encontra a prova:
- As válvulas foram abertas **por ordem remota da Torre**.
- Uma nota diz para culpar a engenheira de plantão.

A Comandante Vesk e o dirigível Vigília tentam impedir que o livro saia do telhado. O ato termina
com Sera encarando a Torre do Diretório (Ato 3, "em breve").

### Fases
| Fase | Telas | Conteúdo |
|---|---|---|
| 4 — **Docas de Carga** | 3 | Chegada. Abismo e tábuas podres; primeira tirolesa por cima de um vão enorme; primeiro holofote (quebrado por trás com um rebite); guarda comum com reentrâncias; guarda com escudo; elevador. |
| 5 — **Bazar das Correntes** | 3 | Rua cheia de civis com guarda e holofote (esconder-se na multidão); Lira abre a passagem dos contrabandistas; praça com holofote, sacada (agarrar a borda) e tirolesa até o elevador. |
| 6 — **Telhados do Diretório** | 3 | Telhados com vãos (correr para pular), chaminés-reentrância, tábuas e holofote; arquivo com o livro de válvulas, muro com rebite de escalada e tirolesa; **chefão: dirigível Vigília**; elevador para o arquivo da Torre. |

### Abismo
- Nas fases do Mercado não há chão sob as telas de baixo.
- Cair por um vão é **morte imediata**: volta ao checkpoint.

### Tábuas podres
- Plataformas vazadas de madeira, uma célula cada.
- Rangem ao serem pisadas e **caem 0,45 s depois**.
- Voltam ao lugar 4 s depois.
- Atravesse sem parar.

### Tirolesa
- Um cabo entre dois postes, sempre descendo, com bandeirolas.
- **Pule contra o cabo** para agarrar: Sera prende o gancho no ar, com as mãos a até ~9 px do
  cabo e caindo ou no alto do pulo.
- Sera desliza até o fim (acelera até 230 px/s).
- **Z** solta com um impulso para cima e **↓** solta sem impulso.
- Pode-se levar tiros durante a descida.

### Holofote
- Lâmpada num poste que varre o chão à frente com um cone de luz (230 px, ida e volta em 4,5 s).
- **Alarme**: se a luz alcançar Sera (com linha de visão), o cone fica vermelho e trava nela por
  3 s.
  - Todos os guardas da tela vêm atrás dela.
  - **Um reforço** desce de corda atrás do holofote (no máximo 1 por holofote).
- **Não é vista**: encostada numa reentrância ou misturada na multidão.
- **Quebrar**: um rebite ou uma explosão quebra a lâmpada. Por trás do poste fica fora da luz.

### Multidão (civis)
- Civis andam devagar perto de suas barracas e param de vez em quando.
- **Misturar-se**: Sera fica invisível para guardas e holofotes quando está:
  - no chão, colada a um civil;
  - sem correr (andar está ok);
  - sem ter atirado no último 1,2 s.

  O aviso "Misturada na multidão" aparece embaixo.
- **Linha de tiro**: guardas **não atiram** se houver um civil entre eles e Sera. Esperam e
  voltam a mirar.
- Explosões por perto fazem os civis **fugirem** por 3 s. Enquanto fogem, eles não escondem Sera.
- Civis não levam dano: rebites e tiros os atravessam.

### Guarda com escudo
- Igual ao guarda comum (2 acertos), mas com um escudo de chapa à frente.
- Rebites **de frente** batem no escudo, e o guarda reage.
- Para derrotá-lo:
  - **Pelas costas**: espere ele virar na patrulha, ou role (C) por ele e vire para atirar.
  - **Vapor** ou **carga de vapor**.

### Lira (aliada)
- Contrabandista de capuz verde no Bazar.
- Ao conversar (A), conta do livro de válvulas e **abre a passagem dos contrabandistas** (a porta
  blindada que bloqueia o caminho).

### Chefão: dirigível Vigília (Comandante Vesk)
Dirigível-patrulha vermelho com o emblema do Diretório. Paira no alto do telhado do arquivo e
trava o elevador até cair. Tem **24 de vida**.

**Ataques**:
- **Bombardeio**: passa sobre Sera e solta 3 bombas (5 na segunda metade). Cada uma mostra um
  **alvo vermelho no chão** e explode ao cair (fere Sera e guardas).
- **Varredura de holofote**: um cone de luz cruza o telhado.
  - Se pegar Sera, trava em vermelho e dispara uma **rajada inclinada** (6 tiros, 8 na segunda
    metade).
  - **Encostar numa chaminé** protege, e a multidão também, se houver.
- **Tropa**: um guarda desce de corda. No máximo 2 vivos.
- **Âncora** (segunda metade):
  - Uma âncora cai no telhado e é arrastada atrás de Sera. Encostar nela fere.
  - **3 rebites** cortam o cabo: 3 de dano, e o dirigível perde o prumo.
  - Ela recolhe sozinha depois de 7 s.

**Ponto fraco — canhões-arpão**:
- **Disparo**: aperte A junto a um dos dois canhões do telhado.
- **Mira**: o canhão gira até 35° para o lado do dirigível. A lâmpada pisca e o aviso diz
  "ALVO NA MIRA!" quando o casco está na linha.
- **Acerto**: o arpão causa **4 de dano** e cola no casco, e o dirigível se desequilibra por um
  instante.
- **Recarga**: 4 s.
- Ao cruzar o telhado, o dirigível costuma passar por cima de um dos canhões.

**Segunda metade** (vida ≤ 12):
- Motores pegando fogo.
- Voa mais baixo e mais rápido.
- Aparece a âncora.

**Derrota**:
- Explosões em cadeia.
- A tripulação é lançada da gôndola: sangue e gibs, se o gore estiver ligado.
- O dirigível tomba e cai atrás dos telhados, com uma explosão final no abismo.
- O elevador é liberado.

---

## 13. Ato 3 — A Torre do Diretório

### História
Com o livro de válvulas na mão, Sera entra na Torre do Diretório pela base. Lá no alto, o
**Diretor Halvard Maar** comanda o **Regulador**, o relógio-mestre que marca o tempo de Ironveil.
Maar admite tudo: mandou explodir a Caldeira Sul para "aliviar a pressão" de uma cidade que
começava a se organizar. Derrotado o Regulador, Sera lê o livro pelos alto-falantes do Diretório
para a cidade inteira, e as Caldeiras abrem as válvulas — fim do jogo.

### Fases
| Fase | Telas | O que tem |
|---|---|---|
| 7 — **Átrio de Bronze** | 3 | Rolamento por baixo de uma grade baixa; primeira torreta-sentinela; galeria com 3 pistões esmagadores; primeiro autômato; plataforma de engrenagem sobre um poço de vapor; guarda e elevador de saída. |
| 8 — **Engrenagem Mestra** | 3 | Guarda com escudo, torreta e pistão juntos; autômato no corredor de baixo; plataforma vertical até o corredor de cima; galeria final com 2 pistões, guarda e torreta. |
| 9 — **Gabinete do Diretor** | 2 | Antessala com guardas, guarda com escudo e autômato; arena do Regulador (checkpoint ao entrar). |

### Plataforma de engrenagem
- Vai e volta entre dois pontos (horizontal ou vertical), parando 0,7 s em cada ponta. Leva Sera.

### Pistão esmagador
- Ciclo fixo: recolhido, **luz vermelha piscando** (aviso), batida no chão, sobe devagar.
- Quem estiver embaixo na batida é **esmagado**: Sera perde toda a vida, guardas viram pedaços.
  Rolar não protege. Atrair guardas para baixo dele funciona.

### Torreta-sentinela
- Presa ao chão, vira para o centro da tela e varre devagar. Vê Sera a até 280 px à frente.
- Ao ver: mira por 0,7 s com um **laser vermelho** e solta uma rajada de 3 tiros inclinados.
- Encostar ou rolar escapa. **3 rebites** ou uma explosão a destroem.

### Autômato de corda
- Carcaça de latão com um operador dentro. Patrulha devagar; ao ver Sera, sopra vapor e **investe**.
- A investida fere (1) e joga Sera longe. **Rolando, Sera atravessa** o autômato sem dano.
- Bater de frente numa parede deixa o autômato tonto por 1,6 s.
- **Couraça na frente**: rebites de frente não ferem. **Chave de corda nas costas**: 1 de dano por
  rebite (2 de vida). Vapor e explosões também funcionam; pistões o esmagam.
- Ao morrer, a carcaça se abre em peças de latão — e no que sobrou do operador.

### Chefão: o Regulador (Diretor Halvard Maar)
O relógio-mestre ocupa o alto da arena: mostrador, engrenagens, um **pêndulo com lâmina** e a
**cabine de vidro** do Diretor pendurada por correntes. Trava o elevador até parar. **24 de vida**.

**Ataques**:
- **Pêndulo**: solto, varre o centro da arena (4 passadas; 6 e mais rápido na segunda metade).
  A lâmina passa na altura do peito: **agache, role ou pule**. Nas pontas da arena ela passa alta.
  Durante a varredura, o Diretor derruba engrenagens em cima de Sera.
- **Chuva de engrenagens**: 4 (6) engrenagens marcam um **alvo dourado** no chão e despencam.
  Caindo, ferem mesmo rolando; depois saem rolando pelo chão (rolar passa por elas).
- **Jatos de vapor no piso** (segunda metade): o chão brilha e, 0,8 s depois, sobe vapor.
- **Autômatos** (segunda metade): saem pela escotilha do lado oposto a Sera. No máximo 2 vivos.

**Ponto fraco — freios do pêndulo**:
- Há um **freio** em cada ponta da arena (aperte A). Ele só pega quando a lâmina chega ao **alto
  do lado dele**: a luz fica verde e o aviso diz "TRAVE AGORA!". Cedo demais, nada acontece.
- Freio certo: o pêndulo trava (**4 de dano**) e a **cabine do Diretor desce** até o chão.
- Com a cabine embaixo, o **núcleo** (escotilha brilhante) fica exposto por 4,6 s:
  **1 por rebite, até 4 por vez**, ou **3** com uma carga de vapor. Depois a blindagem fecha e a
  cabine sobe.

**Segunda metade** (vida ≤ 12): pêndulo mais rápido e mais longo, jatos de vapor, autômatos e
menos pausa entre ataques.

**Derrota**: o pêndulo se solta e cai, a cabine se estilhaça e o Diretor não sai inteiro (sangue,
gibs e vidro, se o gore estiver ligado). O elevador para o alto da Torre é liberado.

### Fim
O elevador leva à tela final: amanhecer no alto da Torre, o relógio parado, vapor subindo das
Caldeiras e Sera lendo o livro na corneta dos alto-falantes. Depois, o mapa para repetir fases.
Um save antigo parado no fim do Ato 2 passa a continuar no começo do Ato 3.

---

## 14. Configurações, abertura de fase, moradores e upgrades

### Configurações (menu principal e pausa)
- **Sangue e gore**, **Efeitos de tela** e **Tela cheia** (também com F11 a qualquer momento).
- **Teclas**: cada ação pode receber outra tecla (clique ou Enter, depois a tecla nova; Esc
  cancela). Se a tecla já era de outra ação, as duas trocam. "Restaurar teclas padrão" desfaz tudo.
  As falas dos moradores, os avisos e os textos de controles usam sempre as teclas atuais.
- **O que "Efeitos de tela" muda**: gradação de cor de cada ato, brilho em volta das luzes,
  cantos escurecidos, grão de filme e a separação de cores ao levar dano. As luzes 2D do cenário
  e a borda de vida não dependem dessa opção.

### Trotar e correr
- Por padrão Sera **trota** (o movimento de antes). **Shift** alterna para **correr**: velocidade
  215 em vez de 150, inclinação maior, poeira e pulos bem mais longos. O HUD mostra "CORRENDO".
- Correndo, ela não se mistura na multidão.

### Abertura de fase
- Ao começar ou continuar uma fase (menu, mapa ou passagem entre fases), entram faixas de
  cinema com o ato, o nome da fase e uma linha de clima, e Sera chega andando pela esquerda.
- O jogo só começa quando o jogador aperta qualquer tecla (ou botão, ou toque).
- Morrer e voltar ao checkpoint não repete a abertura. No checkpoint do chefão também não há.

### Sujeira e borda de vida
- A sujeira de Sera (fuligem e sangue no macacão) acompanha a **vida perdida**: com a vida cheia
  ela está limpa; cada quadrado perdido suja mais. **Ao se curar, ela limpa** (inclusive os
  respingos de sangue alheio, que de qualquer forma somem sozinhos em ~9 s).
- **Borda de vida**: a borda da tela fica vermelha e mais grossa conforme a vida cai, pulsa com
  1 de vida e fecha em preto na morte. Ao se curar, volta a ficar transparente.

### Moradores que dão dicas
- As dicas agora são **pessoas** (operários nas Caldeiras, feirantes no Mercado, criados e
  relojoeiros na Torre). Quando Sera chega perto aparece um balão; **A** conversa.
- Nos chefões ninguém explica nada: descobrir o ponto fraco faz parte da luta.
- **Reação ao sangue** (moradores e civis): ao serem respingados, ao acaso **fogem
  desesperados**, **vomitam**, **se ajoelham e rezam** ou **se encolhem tremendo**.

### Upgrades dos chefões
| Chefão | Upgrade | Efeito |
|---|---|---|
| Martelo-de-Vapor | **Válvula do Martelo** | +1 quadrado de vida (5 no total). |
| Dirigível Vigília | **Arpão de mão** | Segure o tiro por meio segundo e solte: um arpão que atravessa inimigos, fura escudos e couraças (2 de dano) e para na parede. Em chefões conta como dois rebites. |
| O Regulador | **Couraça do Regulador** | Uma placa de latão absorve um golpe (menos quedas e esmagamento) e se recarrega após 12 s. Aparece ao lado da vida no HUD. |
| Fornalha-Mãe | **Botas de Pressão** | No ar, a tecla de rolar dá um impulso horizontal (uma vez por pulo). |

- O prêmio cai no chão da arena quando o chefão morre; pegá-lo enche a vida. Quem sair sem pegar
  recebe mesmo assim. Saves antigos com chefões já vencidos recebem os upgrades ao carregar.


---

## 15. Trilha sonora

Música procedural, sem arquivos de áudio: cada faixa é composta por regras (progressão de acordes,
baixo, pad, arpejo, melodia em frases e percussão) e sintetizada nota a nota em segundo plano
(`scripts/music_synth.gd`, ~5 s por faixa, gerada ao abrir o menu). Loops de 16 compassos com
crossfade de 1,6 s.

| Faixa | Onde | Clima |
|---|---|---|
| menu | menu, mapa, introdução | lenta, caixinha de música |
| act1 | Caldeiras | baixo em ostinato e batidas de metal |
| act2 | Mercado | frígio, cordas dedilhadas, palheta, swing |
| act3 | Torre | cravo, tique-taque de relógio |
| act4 | Fundições | drones graves e bigornas |
| act5 | Véu de Ferro | metais e bateria acelerados |
| boss | qualquer chefão com a barra na tela | 140 bpm, menor harmônica |
| ending | final do jogo | maior, calma |

**Configurações**: volume da Música e dos Efeitos sonoros (cada clique +10%; depois de 100% volta a 0).

---

## 16. Ato 4 — As Fundições Profundas

Antes de morrer, o Diretor Maar revela que obedecia ao **Conselho das Válvulas**, que mantém a
cidade fechada sob o **Véu de Ferro** — e que a pressão que segura o Véu vem da **Fornalha-Mãe**,
abaixo das Caldeiras. Sera desce com Tomé.

| Fase | Telas | O que tem |
|---|---|---|
| 10 — **Poço de Escória** | 2 | Esteira que despeja no ferro fundido; poço vertical com parapeitos; poça larga que só se atravessa com crosta; autômato. |
| 11 — **Cadinhos** | 3 | Esteira contra Sera, martelos-pilão, rio de ferro com um registro, guardas e autômato. |
| 12 — **Coração da Montanha** | 2 | Antessala com Lira e itens; arena da Fornalha-Mãe. |

- **Escuridão**: o mundo fica bem mais escuro e a luz de Sera vira uma lanterna maior.
- **Ferro fundido (`~`)**: encostar é morte na hora — nem rolar, nem a couraça, nem a
  invencibilidade salvam. Guardas e autômatos viram cinza.
- **Registro de resfriamento (`j` + bico `q`)**: abre a água por 1,3 s numa coluna até o chão.
  O ferro atingido vira **crosta** por 6 s (dá para andar em cima); recarrega em 5 s.
- **Esteiras (`>` `<`)**: arrastam quem estiver em cima a 55 px/s.

### Chefão: a Fornalha-Mãe (Conselheira Ívora)
Golem de fundição que anda dentro da poça de ferro, com a conselheira numa gaiola no ombro.
30 de vida (segunda metade em 15). Punhos na beira da poça soltam ondas de choque; bolas de
ferro fundido caem em arco. Como vencê-la fica para o jogador descobrir (os moradores dão pistas).
Prêmio: **Botas de Pressão**.

---

## 17. Ato 5 — O Véu de Ferro

Sem a Fornalha, as placas do Véu cedem. Sera sobe à cúpula para derrubar o Conselho.

| Fase | Telas | O que tem |
|---|---|---|
| 13 — **Passarelas do Véu** | 3 | Abismo, vento em rajadas, tábuas soltas, holofote, tirolesa sobre o vazio. |
| 14 — **Doca da Frota** | 3 | Vento, esteiras de carga, prensa, plataforma de carga sobre o vão, torreta, autômato. |
| 15 — **A Coroa** | 2 | Antessala; arena do Tecelão. |

- **Vento**: ciclos de calmaria, aviso (riscos finos e assobio) e rajada que empurra Sera para um
  lado. Agachada, o empurrão cai para 30%. A fase define a força (`"wind"`).

### Chefão final: o Tecelão (o Conselho das Válvulas)
A máquina que tece as placas do Véu, com o Conselho numa cápsula de vidro. 36 de vida, em três
estágios (24 e 12). Lançadeira que cruza a arena numa de três alturas (com linha de aviso), placas
que despencam, raios, autômatos e, no último estágio, vento. A cada estágio o Véu se abre mais e
entra luz do sol. Derrotado, o Véu se abre: **fim do jogo**.

### Legenda nova (formato das fases)
`~` ferro fundido · `>` `<` esteira · `j` registro de resfriamento · `q` bico de água ·
`U` Fornalha-Mãe · `I` Tecelão · opção de fase `"theme": "foundry"` / `"veil"` e `"wind": força`.
