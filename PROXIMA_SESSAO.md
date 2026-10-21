# Retomada — Turno Morto

## Reconstrução das mesas — 2026-10-21

- Três áreas reconstruídas do zero: `_make_document_table` (aço inox, só protocolo impresso + caneta), `_make_autopsy_table` (bacia rebaixada com borda elevada contendo o lençol, dreno, estrutura em perfis) e `_make_instrument_cart` (mesa de Mayo com seringa, bisturi, pinça, tesoura e compressa em escala real).
- Investigação Poly Haven reconfirmada: sem modelos hospitalares de mesa nem textura de inox limpo — mesas procedurais com aço calibrado; piso PBR real e cadeira de rodas fotogramétrica mantidos.
- Contratos intactos (`protocol_body`, `target_body`, console, inspeção). `gameplay_probe: OK`, `inspection_manager_test: OK`, import/run limpos.
- Capturas: 10 poses em `/tmp/turnomorto_shots` (nova `10_cart`); comparação `/tmp/turnomorto_mesas_antes_depois.png`; anterior em `/tmp/turnomorto_shots_mesasantigas`.
- Inspeção humana pendente: conferir o encaixe do lençol na bacia (pose 02) e a organização da bandeja (pose 10).

## Assets PBR reais + correção de flutuantes — 2026-10-21

- Piso da sala e do corredor agora usa textura PBR real (`smooth_concrete_floor`, Poly Haven CC0) via `ProceduralMaterials.external_pbr_floor`; cadeira de rodas fotogramétrica (`wheelchair_01`, CC0) no canto da sala com colisor; assets e licença em `assets/` (`assets/LICENSE.md`).
- 8 flutuantes corrigidos (o maior: monitor do console sem suporte). Lista completa no CHANGELOG.
- Validação: import/run limpos, `inspection_manager_test: OK`, `gameplay_probe: OK`, 9 capturas em `/tmp/turnomorto_shots` (nova pose da cadeira), comparação em `/tmp/turnomorto_assets_antes_depois.png`.
- Fonte para próximos assets: `https://api.polyhaven.com/assets` (catálogo) e `https://api.polyhaven.com/files/<id>` (URLs reais de download — os caminhos do CDN não são adivinháveis: texturas de modelo ficam em `Models/jpg/<res>/<id>/`, não na pasta do gltf).

## Operação Cold Storage — 2026-10-21

Refinamento direcionado concluído sobre a reforma Break Night: computador da mesa do protocolo removido (mesa de apoio com prancheta, caneta e documento impresso em escala real), `_make_gurney` substituída por `_make_autopsy_table` (aço inox, dreno, pernas quadradas, sem elementos de cama), lençol recalcado com caimento sobre o tampo e sem travesseiro, piso trocado de azulejo celular para `resin_floor` com juntas discretas.

- Contratos intactos: `protocol_body` (meta `interaction=protocol`), `target_body` (M-02), console de registro, porta, inspeção, relógio.
- Validação: import/run headless limpos, `inspection_manager_test: OK`, `gameplay_probe: OK` (21 checks), 8 capturas novas em `/tmp/turnomorto_shots`, anteriores em `/tmp/turnomorto_shots_antes`, comparação lado a lado em `/tmp/turnomorto_antes_depois.png`.
- Pendência de inspeção humana: confirmar visualmente legibilidade do conteúdo impresso da folha de perto e o caimento do lençol na lateral do tampo.

## Operação Break Night — 2026-10-21

Reforma visual completa com módulos procedurais novos, atmosfera animada e câmera fotográfica com feedback visual. Nenhum sistema de inspeção foi alterado.

### Estado atual da validação

- `inspection_manager_test: OK` (lógica intocada).
- `tools/gameplay_probe.tscn`: 21 verificações do fluxo completo (porta → corredor → foto da gaveta M-02 → registro → ciclo sem anomalia → protocolo) — `gameplay_probe: OK`. Rodar com: `Godot --headless --path . res://tools/gameplay_probe.tscn`.
- `tools/screenshot_probe.tscn`: 8 capturas reais do viewport salvas em `/tmp/turnomorto_shots` com estatística de luminância. Rodar com display ativo: `Godot --path . --resolution 1280x720 res://tools/screenshot_probe.tscn`. Este é o caminho oficial de inspeção visual — não precisa mais de captura externa de desktop.
- Importação headless e execução de 8 s sem erros.

### Arquitetura visual nova

- `scripts/procedural_meshes.gd` e `scripts/procedural_materials.gd`: malhas (superelipsoide, tubo, revolução) e materiais (NoiseTexture2D como normal/roughness, triplanar) compartilhados por todo o cenário.
- `scripts/room_atmosphere.gd`: flicker do fluorescente do corredor (fixture z=-13), pulso da luz de emergência, poeira (CPUParticles3D).
- `shaders/post_fx.gdshader` + `scripts/viewfinder_frame.gd`: grain, vinheta, flash de foto e moldura de visor (CanvasLayer 90, acima do protocolo).
- Environment: ACES, fog de profundidade 5,5–28 m, glow 1.05, dois ReflectionProbes.

### Próximos passos sugeridos

1. Inspecionar as 8 capturas de `/tmp/turnomorto_shots` e ajustar escalas/tons pontuais conforme impressão visual.
2. Usar os módulos procedurais para substituir as primitivas restantes (gavetas do armário da sala, prateleiras).
3. Ampliar o catálogo de anomalias usando `ANOMALIAS.md` (a cena agora tem props candidatos naturais: carrinho, soro, extintor, relógio de parede).
4. Quando houver decisão de áudio, sincronizar zumbido com o flicker do `room_atmosphere.gd`.

## Refinamento visual profundo — 2026-10-21

- O teto da sala inicial agora usa painéis hospitalares separados em vez de uma grade cruzada grosseira.
- Os materiais foram reequilibrados para reduzir especularidade do piso e saturação ciano, mantendo a atmosfera fria.
- A mesa cirúrgica recebeu colchão, trilhos laterais, base, hidráulica, suportes e rodízios proporcionais.
- A malha do lençol foi subdividida e suavizada; o travesseiro agora usa cápsula procedural.
- A bancada recebeu pernas cilíndricas, cabo do monitor e um detalhe discreto na tela.
- A luz de preenchimento e a luminária cirúrgica foram reduzidas para evitar manchas fortes no piso.

### Validação desta etapa

- Importação e carregamento headless no Godot 4.7.2: OK.
- Execução headless da cena por oito segundos: OK.
- `inspection_manager_test: OK`.
- A janela do jogo foi localizada no processo, mas a captura de tela do display retornou preta. O viewport headless usa renderizador dummy e não forneceu imagem. A inspeção visual final ainda precisa ser feita pelo usuário na janela real.

### Próximo passo

Revisar uma nova captura real da sala, priorizando as silhuetas que ainda parecerem primitivas. O gameplay não deve ser reescrito; a próxima melhoria deve substituir apenas os elementos visuais restantes mais evidentes.

## Refinamento visual posterior — 2026-10-21

- Removidas as placas e textos 3D desnecessários, inclusive a escrita acima da porta.
- Removida a cadeira do meio da sala.
- HUD inicial agora não exibe objetivos fixos; status de câmera, relatório e mensagens aparecem de forma contextual.
- Adicionados bisturi, pinças e tesoura pequenos à bandeja cirúrgica.
- Ajustados teto e materiais da porta para reduzir formas pretas e melhorar a leitura da sala.
- A folha de protocolo continua funcionando com E.

### Próximo passo

Fazer uma nova captura dentro do jogo para revisar a escala dos objetos restantes e, se necessário, substituir gradualmente mais primitivas por malhas procedurais arredondadas, sem alterar os sistemas de inspeção.

## Ajuste visual posterior — 2026-10-21

- Ajustado o vão da parede do fundo para ter a mesma largura da porta metálica, removendo o aspecto de abertura larga com painéis soltos.
- Removidos os blocos quadrados grandes do piso, mantendo apenas a superfície contínua e a canaleta.
- Próxima verificação visual: confirmar no editor a porta fechada e aberta em primeira pessoa.

## Última atualização — reforma visual da sala inicial (2026-10-21)

Implementada uma reforma procedural apenas na sala inicial, mantendo o corredor, os seis compartimentos, a porta, o jogador, a câmera lógica, a fotografia, as anomalias M-02/M-07 e a progressão do relógio.

- `scripts/first_room.gd` agora cria materiais hospitalares mais claros, acabamento de piso/teto, parede inferior, iluminação fria reforçada, mesa de exame detalhada, corpo coberto por lençol procedural, mesa de trabalho equipada, cadeira de escritório, luminária cirúrgica e folha de protocolo.
- `scenes/door.tscn` agora representa uma porta metálica hospitalar com visor, batente, puxador e placa, mantendo o script de abertura existente.
- A folha `ProtocolSheet` fica sobre a mesa de trabalho. Ao enquadrá-la e pressionar E, abre o painel de protocolo. E ou Esc fecha o painel e devolve o controle ao jogador.
- `scenes/first_room.tscn` recebeu iluminação ambiente mais clara e uma HUD menos carregada, sem alterar o sistema de inspeção.

### Testes confirmados

- Importação headless no Godot 4.7.2 sem erros.
- Execução headless da cena principal por oito segundos sem erros de runtime.
- `inspection_manager_test: OK`.
- `protocol_probe: OK`, confirmando raycast da folha e abertura do protocolo com E.
- Nenhuma inspeção visual interativa foi confirmada nesta sessão porque a janela do Godot não ficou disponível para controle visual.

### Próximo passo recomendado

Abrir a cena no Godot e fazer uma inspeção visual manual da sala em resolução de jogo, ajustando posições, escala e contraste dos objetos conforme necessário. Depois, refinar o visor da câmera sem alterar o fluxo de inspeção já preservado.

## Estado atual

O projeto abre com Godot 4.7.2, usando Compatibility e Jolt Physics. A cena principal é scenes/first_room.tscn.

O cenário é construído em runtime por scripts/first_room.gd. A sala de segurança está conectada a um corredor com seis compartimentos mortuários, etiquetas M-01 a M-06, puxadores, portas numeradas, luminárias fluorescentes, luz de emergência, mesa de registro e console.

## Sistemas existentes

- scripts/player.gd: movimentação WASD, olhar pelo mouse e captura/liberação do mouse com Esc.
- scripts/door.gd: abertura, fechamento e animação da porta de acesso.
- scripts/inspection_manager.gd: estados pronto, explorando, retornando e concluído.
- scripts/first_room.gd: construção do cenário, HUD, raycast da câmera, fotografia e registro.
- tests/inspection_manager_test.gd: teste automatizado do ciclo completo.

## Fluxo atual

1. O relógio começa em 00:00 e permanece parado.
2. E na porta inicia a inspeção e abre o acesso ao corredor.
3. O jogador precisa entrar no corredor.
4. F só é aceito quando o raycast da câmera enquadra a gaveta-alvo.
5. R registra uma anomalia fotografada quando o jogador está perto do console.
6. N confirma ausência de anomalia somente nos ciclos sem anomalia.
7. Relatórios incorretos não avançam o relógio.
8. O turno termina em 06:00.

O calendário atual é determinístico: há anomalia em 00:00, 02:00 e 04:00; os ciclos 01:00, 03:00 e 05:00 não possuem anomalia. A anomalia inicial troca visualmente a etiqueta M-02 por M-07.

## Verificações já realizadas

- Importação headless no Godot 4.7.2 sem erros.
- Execução headless da cena por oito segundos sem erros.
- Teste automatizado do gerenciador aprovado com inspection_manager_test: OK.
- O usuário relatou exploração manual do corredor, descoberta da etiqueta, funcionamento parcial da fotografia/registro e avanço até 02:00.

## Pendências prioritárias

1. Melhorar a clareza do HUD e do estado do relatório.
2. Tornar a anomalia mais legível sem denunciá-la diretamente.
3. Corrigir bugs observados no teste manual do fluxo R/N.
4. Refinar materiais procedurais, desgaste visual e iluminação.
5. Adicionar atmosfera sonora quando houver uma solução adequada.
6. Continuar ampliando o cenário gradualmente, preservando o corredor e o sistema de inspeção.

## Limitações conhecidas

- A fotografia é uma validação por raycast e não salva imagens reais.
- O cenário usa primitivas e materiais procedurais; ainda não há texturas externas.
- Não há áudio ambiente implementado.
