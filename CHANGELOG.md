# Changelog — Turno Morto

## 2026-10-21 — Reconstrução completa das mesas (documentos, necropsia e carrinho de instrumentos)

As três áreas funcionais da sala foram apagadas e reconstruídas do zero; nenhuma peça antiga reaproveitada.

### A. Mesa de documentos (`_make_document_table`, substitui `_make_table`)
- Tampo de aço inox 1,8×0,75 m a 0,90 m com bordas eased; avental de aço, quatro pernas quadradas com pés niveladores, travessas e prateleira inferior.
- Composição mínima: documento de protocolo impresso (duas folhas + tinta + carimbo + sombra de contato) e caneta apoiada sobre a própria folha. Prancheta removida.
- Colisor e meta `interaction=protocol` preservados; nova posição da folha (2,98, 0,947, 1,18) já coberta pelo `gameplay_probe`.

### B. Mesa de necropsia (`_make_autopsy_table` reescrita)
- Bacia de aço com fundo rebaixado (0,88) e borda elevada contornando (topo 0,93) — o lençol agora fica contido pela borda, como em mesa real, e não drapeia por fora.
- Dreno com anel no pé da bacia; quadro inferior, quatro pernas, travessas em H e pés de borracha.
- Lençol remalhado para a bacia (extensão 2,26×0,88 m, fundo 0,8845): volumes de cabeça/tronco/quadril/pés e dobras em três escalas mantidos.
- Correção latente: o dreno antigo era rotacionado 90° (ficava vertical); agora é disco plano no piso da bacia.

### C. Carrinho de instrumentos (`_make_instrument_cart`, substitui `_make_tray` que ficava sobre a mesa de documentos)
- Mesa de Mayo: bandeja basculante (−6°) com rebaixo sobre poste de aço, base de quatro pernas com rodízios alinhados às pernas; colisor próprio.
- Instrumentos com escala real e apoiados no fundo da bandeja: seringa (corpo, êmbolo, disco e agulha), bisturi (cabo + lâmina), pinça curva de duas pontas, tesoura com anel de pivô e compressa.
- Posição: (1,7, 0, −2,1), a pé da mesa de necropsia, fora da rota da porta.

### Modelos e texturas
- Catálogo do Poly Haven re-verificado: sem modelo de mesa hospitalar/mayo (só madeira e carrinhos industriais) e sem textura de inox escovado limpo (só `metal_plate` suja/enferrujada). Mesas ficaram procedurais com o aço já calibrado — conforme critério "se o modelo pronto não servir, construir alternativa própria".
- Piso PBR real (Poly Haven) e cadeira de rodas fotogramétrica da etapa anterior permanecem.

### Limpeza
- `_make_table`, `_make_tray` removidas; `wood_material` e `laminate_material` extintos (zero referências).

### Validação
- Import headless e execução de 8 s sem erros; `inspection_manager_test: OK`; `gameplay_probe: OK` (21 verificações, incluindo mira no novo documento).
- 10 capturas reais em `/tmp/turnomorto_shots` (nova pose `10_cart`); etapa anterior preservada em `/tmp/turnomorto_shots_mesasantigas`; comparação em `/tmp/turnomorto_mesas_antes_depois.png`.

## 2026-10-21 — Assets PBR reais (Poly Haven CC0) e correção de objetos flutuantes

### Assets externos integrados (CC0, registrados em `assets/LICENSE.md`)

- **Textura de piso** `smooth_concrete_floor` (diff + nor_gl + arm) aplicada à sala e ao corredor com tinta cinza fria esverdeada; corredor mais escuro, mesma instalação. Novo `ProceduralMaterials.external_pbr_floor` (albedo, normal, AO e canal de roughness do mapa ARM; variação de brilho de baixa frequência continua procedural).
- **Modelo** `wheelchair_01.gltf` (fotogrametria, escala real 0,82×1,10×1,09 m) no canto da sala com colisor de caixa, girada 28°; arandela de parede nova no canto para legibilidade (+71% de luminância local).

### Objetos flutuantes corrigidos

- Monitor do console de registro flutuava 30 cm: ganhou coluna e base de suporte.
- Teclado, papéis, painel de botões e botões do console assentados no tampo (estavam 1–2 cm no ar).
- Avental da mesa de apoio saiu de dentro da lâmina e virou faixa visível sob o tampo.
- Cabeça e difusor da luminária cirúrgica encaixados no braço (havia vãos de 2,5–3,7 cm).
- Bolsa de soro realinhada à ponta do gancho; mangueira acompanha.
- Relógio de parede, indicador de emergência e suporte do extintor encostados nas paredes (vãos de 0,5–5,5 cm eliminados).
- Painéis de luz do teto assentados no forro.

### Observação

- O computador da mesa de apoio já havia sido removido na etapa anterior; reverificado (zero referências) e a interação E do protocolo segue válida (`gameplay_probe: OK`).

### Validação

- Import headless e execução de 8 s sem erros; `inspection_manager_test: OK`; `gameplay_probe: OK` (21 verificações).
- 9 capturas reais em `/tmp/turnomorto_shots` (nova pose `09_wheelchair`); etapa anterior preservada em `/tmp/turnomorto_shots_coldstorage`; comparação em `/tmp/turnomorto_assets_antes_depois.png`.
- Nova pose no `tools/screenshot_probe.gd`.

## 2026-10-21 — Operação Cold Storage: mesa do protocolo, mesa de necropsia, papel e piso

Refinamento direcionado sobre a reforma anterior, sem recriar sistemas.

### Mesa do protocolo (`_make_table`)

- **Computador removido** (monitor, tela, suporte, base, teclado, mouse, cabo e o brilho de tela) — não substituído por nenhum eletrônico.
- Bancada refeita como mesa de apoio: lâmina clara com bordas eased (`laminate_material`), avental de aço, quatro pernas quadradas com pés de borracha, travessas e prateleira inferior.
- Composição minimalista: documento de protocolo como elemento principal, prancheta fina com presilha e folha em branco, caneta hospitalar de duas cores. Bandeja de instrumentos realinhada ao novo tampo.
- Luz de tarefa mantida para leitura do documento.

### Protocolo como papel físico

- Escala corrigida: a folha passou de 0,78×0,55 m (tamanho de jornal) para 0,42×0,30 m (formato de formulário).
- Duas folhas sobrepostas com rotações opostas (3°/−5°), bordas eased, papel branco-acinzentado fosco.
- Conteúdo "impresso": bloco de título, filete, três linhas de texto, linha de assinatura em tinta fosca escura e carimbo vermelho-maro discreto — nada emissivo, nada projetado.
- Sombra de contato radial sob o documento e sob a prancheta (`GradientTexture2D` radial).
- Colisor e meta `interaction=protocol` preservados; interação E abre/fecha o overlay 2D inalterado.

### Mesa de necropsia (`_make_autopsy_table`, substitui `_make_gurney`)

- Removidos colchonet, cabeceira com apoio acolchoado, grades laterais, base hidráulica, coluna de controle, pedal e rodízios — zero elementos de cama.
- Tampo rígido de aço inox 2,4×1,0 m a 0,90 m com reforço interno, dreno com anel no pé da mesa, quatro pernas quadradas recuadas, travessas em H e pés niveladores de borracha.
- Corpo coberto sem travesseiro: malha do lençol recalculada para o tampo (base 0,905 m) com volumes sugeridos de cabeça, tronco, quadril e pés, dobras em três escalas e caimento real sobre a lateral do tampo (smoothstep de drape).

### Piso

- `tile_floor` (azulejo celular, padrão orgânico) substituído por `resin_floor`: resina hospitalar contínua com grão laranja-casca finíssimo (normal 0.14), manchas de brilho suaves (roughness 0.39–0.55) e variação tonal de baixo contraste via textura de albedo.
- Juntas de dilatação discretas na sala (2) e corredor (7), com material próprio escuro.
- Manchas de piso atenuadas (alpha 0.5→0.3) e marcas de parede (0.42→0.26).

### Validação

- Import headless e execução de 8 s sem erros; `inspection_manager_test: OK`; `gameplay_probe: OK` (21 verificações, incluindo raycast do novo documento e fluxo completo).
- 8 novas capturas reais em `/tmp/turnomorto_shots` (luminância 0.065–0.134; mesa +29%, console +27%). Comparação antes/depois por pose em `/tmp/turnomorto_antes_depois.png`; capturas da etapa anterior preservadas em `/tmp/turnomorto_shots_antes`.

## 2026-10-21 — Operação Break Night: reforma visual, modelagem procedural e câmera fotográfica

Reforma visual profunda do necrotério preservando integralmente os sistemas de inspeção. Validada pela primeira vez do projeto com capturas de tela reais (8 poses renderizadas pela própria engine em janela com GPU, salvas em /tmp/turnomorto_shots).

### Módulos novos

- `scripts/procedural_meshes.gd`: superelipsoide (caixa com cantos arredondados), tubo por transporte paralelo (puxadores, cabos, rodapés sanitários curvos, mangueiras) e sólido de revolução (copos, frascos, bacias), com winding corrigido para a convenção do Godot.
- `scripts/procedural_materials.gd`: fábrica de materiais com texturas nativas `NoiseTexture2D` (normal map com bump_strength, roughness map com rampa, triplanar global) — azulejo por células, pintura, aço escovado, esmalte hospitalar, tecido, papel, cerâmica, telas e difusores emissivos. Cache compartilhado de texturas.
- `scripts/room_atmosphere.gd`: flicker de fluorescente com crise elétrica aleatória e tremor de reator, pulso senoidal da luz de emergência e poeira em suspensão (CPUParticles3D, compatível com qualquer renderer).
- `shaders/post_fx.gdshader`: vinheta, grão de sensor animado e aberração cromática mínima (hint_screen_texture).
- `scripts/viewfinder_frame.gd`: moldura de visor que "arma" quando um alvo válido está enquadrado.
- `scripts/player.gd`: head bob sutil proporcional à velocidade (input e física intocados).

### Cena e iluminação

- `scenes/first_room.tscn`: tonemap ACES, fog de profundidade (começa a 5,5 m, termina a 28 m) para engolir o fim do corredor, glow com threshold 1.05, ambient mais escuro, remoção da luz de preenchimento flat, dois ReflectionProbes (sala e corredor) e luz direcional de modelagem reduzida a 0.22.
- Fluorescentes do corredor agora são carcaças com difusor emissivo e SpotLight3D direcionados para baixo com sombra; o segundo fixture entra em flicker.
- Lâmpada cirúrgica com spot com sombra apontado para a maca; luzes de tarefa verdes sobre o console de registro e a mesa de trabalho (luminância local +76% e +49%).
- Gavetas mortuárias refeitas: frente chanfrada, trilhos-puxador em aço inox, recessos, rebites, placa de identificação, cartão de papel e batente/fascia; colisor da gaveta M-02 preservado como alvo do raycast.
- Portas do corredor remodeladas (folha chanfrada, visor de vidro, barra antipânico, dobradiças, placas), com materiais da porta principal substituídos em runtime.
- Novos detalhes de uso: tubulações no teto do corredor com suportes e registro com volante, grades de ventilação, carrinho de serviço com colisão, suporte de soro com bolsa e mangueira, extintor de parede, relógio de parede sincronizado com o relógio do turno, manchas no piso e marcas de parede, rodapé sanitário curvo contínuo.
- Câmera fotográfica: flash branco com fade ao fotografar, visor armado ao enquadrar anomalia, grain/vinheta permanentes discretos.

### Validação executada

- Importação headless sem erros; execução headless da cena por 8 segundos sem erros.
- `inspection_manager_test: OK`.
- Novo `tools/gameplay_probe` (21 verificações): porta, entrada no corredor, raycast da gaveta M-02, foto válida, registro com avanço para 01:00, ciclo limpo com N para 02:00, protocolo com E, atmosfera, pós-efeto, relógio e visor — `gameplay_probe: OK`.
- Novo `tools/screenshot_probe`: 8 capturas reais do viewport (spawn, maca, mesa, console, corredor, gavetas, close da anomalia, fim do corredor) com luminância média entre 0.05 e 0.115 — nenhum frame preto ou estourado.

## 2026-10-21 — Refinamento visual profundo da sala cirúrgica

- Substituída a grade de faixas escuras do teto por painéis hospitalares separados, com juntas técnicas discretas.
- Ajustados piso, parede, teto, metal, plástico, vidro, tecido e papel para reduzir reflexos artificiais, saturação e manchas luminosas.
- Refinadas as junções de parede com trilhos técnicos, rodapés e cantos de acabamento.
- Remodelada a mesa cirúrgica procedural com colchão separado, trilhos laterais, base, coluna hidráulica, suporte de controle, rodízios e castores orientados corretamente.
- Suavizada a malha procedural do lençol e substituído o travesseiro cúbico por uma malha cápsula.
- Melhorada a bancada com pernas cilíndricas, cabo do monitor e detalhe de tela.
- Mantidos os instrumentos da bandeja em escala pequena e organizada.
- Equilibradas a luz fria, a luz de preenchimento e a luminária cirúrgica para preservar legibilidade sem lavar o piso.
- Preservados controles, porta, protocolo, corredor, inspeção, anomalias e progressão do relógio.

### Verificações

- Godot 4.7.2 carregou o projeto e a cena sem erros.
- Execução headless da cena por oito segundos concluída sem erros de runtime.
- `inspection_manager_test: OK`.
- A captura direta do desktop encontrou a janela do processo, mas retornou uma superfície preta; a tentativa de captura do viewport headless também não produziu imagem porque o modo dummy não possui textura renderizada. Nenhuma captura visual foi inventada.

## 2026-10-21 — Refinamento visual da sala cirúrgica

- Removida completamente a placa textual acima da porta e as sinalizações 3D redundantes na sala.
- Removida a cadeira do centro da composição; o espaço de circulação e a mesa cirúrgica ficaram desobstruídos.
- Objetivos fixos da HUD foram ocultados. Mensagens de câmera, relatório e status agora aparecem apenas durante estados ou interações relevantes.
- A bandeja cirúrgica recebeu bisturi, pinças e tesoura em escala pequena, sem bloquear a mesa.
- Suavizada a grade escura do teto e melhorada a leitura do metal da porta.
- Mantidos o protocolo interativo, a porta, o corredor, o jogador e os sistemas de inspeção e relógio.

### Verificações do refinamento

- Godot 4.7.2 carregou o projeto e a cena sem erros.
- Execução headless da cena principal concluída sem erros de runtime.
- `inspection_manager_test: OK`.
- `refinement_probe: OK`: cadeira ausente, placa removida, HUD inicial sem objetivos fixos e protocolo abriu/fechou com E.
- A aparência foi avaliada pelas capturas fornecidas; não houve controle visual direto da janela do Godot pelo agente.

## 2026-10-21 — Ajuste do vão da porta e remoção de placas visuais

- Corrigida a largura da parede do fundo para casar com a porta metálica e eliminar as duas placas laterais que pareciam quadrados soltos.
- Removidos os grandes blocos quadrados de acabamento do piso; a sala agora usa o piso contínuo e a canaleta discreta.
- O corredor, as colisões, a porta interativa e os sistemas de inspeção permaneceram inalterados.

## 2026-10-21 — Reforma visual da sala inicial

- Reformada exclusivamente a sala inicial em `scripts/first_room.gd`, preservando o corredor, os compartimentos, o jogador, a fotografia, as anomalias existentes e o gerenciador de inspeção.
- Atualizados materiais procedurais para piso hospitalar, paredes em dois tons, teto modular, metais, tecido, vidro, plástico, papel e superfícies de trabalho.
- Adicionados acabamento de piso, canaleta de drenagem, painéis de teto, rodapés e iluminação fria mais clara, mantendo a luz de emergência.
- Substituída a maca simples por uma mesa de exame com estrutura metálica, base hidráulica, rodas e corpo fictício imóvel coberto por um lençol procedural com volume, dobras e queda lateral.
- Melhorada a mesa de trabalho com monitor, tela emissiva, suporte, teclado, mouse, documentos, caneta e copo.
- Substituída a cadeira quadrada por uma cadeira de escritório com encosto, coluna, base e rodízios.
- Reformada a porta de acesso existente em `scenes/door.tscn` com metal, batente, visor, barra, puxador e sinalização hospitalar.
- Adicionada folha de protocolo sobre a mesa. Quando enquadrada e pressionada E, abre uma interface legível com as tarefas iniciais do turno; E ou Esc fecha o documento.
- Removidos textos ambientais redundantes e reduzida a instrução fixa da HUD, mantendo apenas as orientações necessárias para interação.

### Verificações desta reforma

- Godot 4.7.2 em modo headless importou o projeto e carregou a cena sem erros.
- A cena principal foi executada por oito segundos em modo headless sem erros de runtime.
- `tests/inspection_manager_test.gd` continua aprovado com `inspection_manager_test: OK`.
- Uma sonda temporária confirmou a mira sobre a folha, a tecla E e a abertura do painel com `protocol_probe: OK`; a sonda foi removida após o teste.
- Não foi realizada inspeção visual interativa pelo agente, pois nenhuma janela do Godot foi exposta ao controle visual nesta sessão.

## 2026-10-20 — Primeiro cômodo

- Configurada a cena inicial em scenes/first_room.tscn.
- Criado um cômodo 3D de necrotério com piso, paredes, teto, corredor e porta interativa.
- Adicionadas iluminação fria, luz de emergência, materiais hospitalares e sinalização ambiental.
- Criados mesa, cadeira, maca, armário mortuário, prateleiras e bandeja metálica como objetos preparados para futuras anomalias.
- Criado controle em primeira pessoa com WASD, mouse, tecla E e Esc.
- Configurada a execução da cena inicial pelo project.godot.
- Validado com Godot 4.7.2.stable.official em modo headless:
  - importação do projeto sem erros;
  - execução da cena por três segundos sem erros de runtime.

## Limitações atuais

- O sistema de fotografia usa validação por raio e não salva imagens reais no disco.
- Ainda não há áudio ambiente nem modelos externos.
- A inspeção visual interativa pelo agente não ficou disponível porque a janela do Godot não foi exposta pela interface de automação.

## 2026-10-20 — Expansão funcional

- Estendido o corredor conectado à sala com seis compartimentos mortuários, portas numeradas, puxadores, etiquetas e sinalização.
- Substituídos os materiais básicos por variações procedurais leves para piso, parede, teto, metal, aço das gavetas e móveis.
- Aprimorada a mesa de registro com tampo, estrutura, painel frontal, gaveta e console.
- Criado o gerenciador de inspeção com estados de exploração, retorno, relatório e conclusão.
- O relógio agora avança somente após uma confirmação válida e termina exatamente às 06:00.
- Criada a câmera lógica com mira, raycast, distância e alvo validado.
- Criada a primeira anomalia reproduzível: a etiqueta da gaveta M-02 aparece como M-07 no ciclo com anomalia.

## 2026-10-20 — Checkpoint de fim de sessão

### Estado preservado

- Projeto Godot 4.7.2 configurado para o renderizador Compatibility.
- Cena inicial e corredor conectado preservados em scenes/first_room.tscn.
- Jogador, câmera e porta preservados em scenes/player.tscn e scenes/door.tscn.
- Sistema de inspeção preservado em scripts/inspection_manager.gd.
- Fotografia por validação lógica, alvo DrawerFront_02 e anomalia M-02/M-07 preservados.
- Progressão determinística do relógio de 00:00 a 06:00 preservada.
- Seis compartimentos mortuários, materiais procedurais, iluminação e mesa de registro preservados.
- Os oito arquivos Markdown de documentação de origem permaneceram intactos.

### Verificações executadas neste checkpoint

- project.godot, cenas, scripts, teste e CHANGELOG confirmados como arquivos existentes no disco.
- Importação do projeto no Godot 4.7.2 em modo headless concluída sem erros.
- Execução do teste tests/inspection_manager_test.gd concluída com inspection_manager_test: OK.
- Execução da cena principal em modo headless por oito segundos concluída sem erros.

### Testes manuais registrados por relato do usuário

- Cenário inicial e corredor foram abertos e explorados manualmente.
- Compartimentos mortuários numerados foram verificados durante o jogo.
- A anomalia da etiqueta foi encontrada durante a exploração.
- Fotografia e registro funcionaram parcialmente.
- O relógio avançou durante inspeções até 02:00.

### Pendências para a próxima sessão

- Tornar o fluxo de registro e o feedback visual da anomalia mais claros.
- Melhorar texturas e materiais sem introduzir dependências externas pesadas.
- Refinar a iluminação e a atmosfera de terror psicológico.
- Revisar bugs encontrados durante o teste manual.
- Manter a fotografia como validação lógica até uma decisão futura sobre salvar imagens reais.
