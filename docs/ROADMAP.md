# IRONVEIL — Plano até o ato final

Proposta de direção para as próximas versões: melhorias nas 9 fases atuais e um plano de
**5 atos** para fechar a história no nome do jogo — o **Véu de Ferro**.

---

## 1. A história completa (proposta)

Os Atos 1 a 3 continuam como estão, com uma mudança no fim do Ato 3: ao morrer, o Diretor Maar
revela que só cumpria ordens do **Conselho das Válvulas**, que vive acima da Torre e mantém a
cidade lacrada sob o **Véu de Ferro**, uma cúpula que cobre a montanha. A desculpa oficial: lá
fora o ar é veneno. A verdade: o Véu existe para que ninguém saia — e a pressão das Caldeiras é
o que o mantém fechado.

| Ato | Nome | Onde | Ideia central |
|---|---|---|---|
| 1 | As Caldeiras | base da montanha | fuga, aprender a se mover |
| 2 | O Mercado Suspenso | meio, sobre o abismo | furtividade, multidão, a prova |
| 3 | A Torre do Diretório | topo da cidade | máquinas, o primeiro rosto do poder |
| 4 | **As Fundições Profundas** | abaixo das Caldeiras | descer em vez de subir: a máquina que gera a pressão |
| 5 | **O Véu de Ferro** | a cúpula sobre a cidade | abrir o céu |

**Ato 4 — As Fundições Profundas.** Para soltar o Véu, Sera precisa cortar a pressão na fonte: a
**Fornalha-Mãe**, escondida sob as Caldeiras. Escuridão quase total (só a lanterna de Sera e o
metal derretido iluminam), esteiras transportadoras, rios de ferro fundido, operários
escravizados que podem virar aliados. Tomé e Lira voltam.
- Fase 10 — *Poço de Escória*: descida vertical, esteiras e jatos de escória.
- Fase 11 — *Cadinhos*: guindastes de ferro fundido, furtividade no escuro (lanterna liga/desliga).
- Fase 12 — *Coração da Montanha*. **Chefão: a Fornalha-Mãe**, um golem de fundição comandado pela
  Conselheira Ívora; a arena enche de ferro derretido em plataformas que afundam.
- **Upgrade: Botas de Pressão** — um impulso no ar (pulo duplo curto ou arrancada).

**Ato 5 — O Véu de Ferro.** Com a Fornalha apagada, o Véu fica sem pressão e pode ser aberto por
dentro. Passarelas expostas ao vento sobre a cúpula, chuva ácida, a frota do Conselho.
- Fase 13 — *Passarelas do Véu*: vento lateral que empurra Sera, rajadas com aviso.
- Fase 14 — *Doca da Frota*: entrar escondida num dirigível e sabotá-lo por dentro, em movimento.
- Fase 15 — *A Coroa*. **Chefão final: o Tecelão**, a máquina que mantém as placas do Véu, com o
  Conselho dentro. Luta em três estágios, com o Véu se abrindo aos poucos e a primeira luz do sol
  entrando na arena.
- **Final**: o Véu se abre, a cidade vê o céu pela primeira vez. Sem upgrade; abre um **Novo Jogo+**
  com todos os upgrades e inimigos mais fortes.

---

## 2. Melhorias nas fases existentes

### Ato 1 — As Caldeiras
- **Caldeira Norte**: um momento de fuga roteirizado no começo (alarme, guardas chegando por trás)
  para criar urgência antes do tutorial.
- **Sala das Bombas**: a sala dos drones é plana; dar a ela dois andares, com o painel no alto, para
  usar o rebite de escalada sob pressão.
- **Poço do Guindaste**: a subida no guindaste é passiva; fazer guardas e drones atacarem durante a
  viagem, com Sera atirando do cesto.
- **Martelo-de-Vapor**: uma terceira fase de luta curta, com a arena inundando de vapor e só as
  plataformas altas seguras.

### Ato 2 — O Mercado Suspenso
- **Docas de Carga**: uma sequência de perseguição: a ponte de tábuas desabando atrás de Sera.
- **Bazar das Correntes**: hoje a multidão é plana. Criar um mercado em dois níveis (sacadas), com
  um guarda que revista a multidão e obriga Sera a trocar de grupo.
- **Telhados do Diretório**: vento e chuva visuais; telhas que escorregam (atrito menor).
- **Dirigível Vigília**: deixar Sera subir na âncora e ser carregada, como forma alternativa de
  chegar a um canhão.

### Ato 3 — A Torre do Diretório
- **Átrio de Bronze**: um salão de baile vazio com guardas em ronda e o relógio tocando: a cada
  badalada as luzes apagam por um segundo (janela para passar).
- **Engrenagem Mestra**: engrenagens gigantes giratórias como plataformas (andar sobre os dentes).
- **Gabinete do Diretor**: antes do chefão, uma sala de arquivos onde Sera lê documentos que
  preparam o Ato 4 (o Conselho, a Fornalha-Mãe).
- **O Regulador**: mostrar mais claramente, no próprio cenário, que o freio só pega no alto
  (um ponteiro no relógio que acende ao passar pela marca).

### Para todas as fases
- **Segredos**: 1 item escondido por fase (página de diário, peça de um mapa) com contador no mapa.
- **Tempo e ranking**: tempo por fase e medalhas (sem morrer, sem ser vista).
- **Música**: trilha procedural por ato (hoje só há ambiente).
- **Sprites**: trocar a Sera desenhada por código por sprites com normal map (pipeline do
  SpriteKiln, visão lateral) para reagir às luzes 2D.

---

## 3. Reações dos moradores ao sangue

Já no jogo: **fugir desesperado**, **vomitar**, **ajoelhar e rezar**, **encolher tremendo**.

Outras sugestões:
- **Desmaiar**: cai duro e fica no chão (pode ser pisado pelos guardas).
- **Gritar e apontar para Sera**: chama o guarda mais próximo — o gore passa a ter custo.
- **Tapar os olhos e andar às cegas**, trombando nas coisas.
- **Limpar o rosto em pânico**, esfregando as mãos no casaco.
- **Esconder-se** na reentrância mais próxima (e ocupar o lugar de Sera).
- **Tropeçar na fuga** e cair, levantando de novo.
- **Rezar em voz alta** em grupo: outros civis por perto se juntam.
- No Ato 3: **criados que desmaiam de forma afetada** e **um escrivão que anota tudo**.

---

## 4. Ordem sugerida de trabalho

1. Ajustar o fim do Ato 3 (revelação do Conselho) e o mapa para 5 atos.
2. Ato 4 completo (mecânicas: escuridão e lanterna, esteiras, ferro fundido; chefão; Botas de Pressão).
3. Melhorias das fases 1–9 marcadas acima, começando pelas de maior impacto: guindaste com
   combate, Bazar em dois níveis, badaladas do Átrio.
4. Ato 5 e o final; Novo Jogo+.
5. Música procedural, segredos, tempo/medalhas e sprites com normal map.
