# Turno Morto

Jogo de terror psicológico em primeira pessoa: você é o funcionário do turno da noite
em um necrotério. Entre no corredor refrigerado, compare o ambiente com a visita
anterior, fotografe a anomalia — se ela existir — e registre o relatório antes das 06:00.

**Status:** em desenvolvimento (protótipo jogável da sala inicial e do corredor).

## Como jogar

1. Abra o projeto no **Godot 4.7.2** e execute a cena principal (`F5`), ou rode direto:
   ```bash
   godot --path .
   ```
2. Pressione **E** na porta para iniciar a inspeção.
3. Percorra o corredor e observe os seis compartimentos mortuários.
4. Se notar uma alteração, enquadre-a com a mira e pressione **F** para fotografar.
5. Volte à sala de segurança e registre no console: **R** (houve anomalia) ou
   **N** (não houve anomalia).
6. O relógio avança a cada relatório correto. O turno termina às **06:00**.

### Controles

| Tecla | Ação |
|-------|------|
| `WASD` | mover |
| Mouse | olhar |
| `E` | interagir (porta, protocolo) |
| `F` | fotografar |
| `R` | registrar anomalia no console |
| `N` | confirmar ausência de anomalia |
| `Esc` | liberar a captura do mouse |

## Sistemas

- **Inspeção por ciclo:** a cada hora o ambiente pode (ou não) conter uma anomalia.
  Reportar errado não avança o relógio.
- **Câmera fotográfica como equipamento de trabalho:** visor, flash e validação por
  raycast — a evidência só vale se o alvo estiver enquadrado.
- **Protocolo interativo:** o documento físico sobre a mesa abre uma interface legível.
- **Atmosfera:** fluorescente com falha elétrica, luz de emergência pulsante, poeira em
  suspensão, névoa de profundidade no corredor e pós-efeto discreto (grão e vinheta).

## Tecnologia

- **Godot 4.7.2** (renderizador Compatibility, física Jolt)
- Cenário construído em runtime por GDScript com malhas e materiais procedurais
  (superelipsoides, tubos, sólidos de revolução)
- Texturas PBR reais e um modelo fotogramétrico integrados (Poly Haven, CC0)

## Estrutura

```
assets/       modelos e texturas externos (com licenças em assets/LICENSE.md)
scenes/       cenas principais (sala, jogador, porta)
scripts/      construção do cenário, materiais/malhas procedurais, atmosfera
shaders/      pós-efeto de câmera
tests/        teste automatizado do ciclo de inspeção
tools/        sondas de validação (gameplay e capturas de tela)
```

## Testes

```bash
# lógica do ciclo de inspeção
godot --headless --path . -s res://tests/inspection_manager_test.gd

# fluxo completo (porta, corredor, foto, registro, protocolo)
godot --headless --path . res://tools/gameplay_probe.tscn
```

Saída esperada: `inspection_manager_test: OK` e `gameplay_probe: OK`.

## Licença

- O **código original do Turno Morto** (scripts, cenas, shaders, ferramentas e
  documentos deste repositório) é distribuído sob a licença **MIT** — veja o
  arquivo [`LICENSE`](LICENSE).
- Os **recursos externos** em `assets/` (modelo e texturas do Poly Haven)
  **não** são cobertos pela MIT: permanecem sob suas licenças originais
  (**CC0**), conforme documentado em [`assets/LICENSE.md`](assets/LICENSE.md).
- A engine [Godot Engine](https://godotengine.org) não é distribuída neste
  repositório e possui sua própria licença MIT.

## Créditos

- Modelos e texturas de [Poly Haven](https://polyhaven.com) — licença **CC0**
  (detalhes e origem de cada arquivo em [`assets/LICENSE.md`](assets/LICENSE.md)).
- Demais arte (geometria, materiais e texturas procedurais), código e design:
  feitos para este projeto.
