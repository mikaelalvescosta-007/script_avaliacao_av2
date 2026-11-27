-- ==========================================
-- 0. REMOÇÃO DE TABELAS EXISTENTES (CASO NECESSÁRIO)
-- ==========================================
DROP TABLE IF EXISTS inventario_item CASCADE;
DROP TABLE IF EXISTS save_state CASCADE;
DROP TABLE IF EXISTS recurso_cenario CASCADE;
DROP TABLE IF EXISTS telemetria_partida CASCADE;
DROP TABLE IF EXISTS evento_game_loop CASCADE;
DROP TABLE IF EXISTS partida CASCADE;
DROP TABLE IF EXISTS reporte_bug CASCADE;
DROP TABLE IF EXISTS configuracao_jogo CASCADE;
DROP TABLE IF EXISTS item_catalogo CASCADE;
DROP TABLE IF EXISTS jogador CASCADE;

-- Remoção dos ENUMs caso já existam
DROP TYPE IF EXISTS status_bug_enum;
DROP TYPE IF EXISTS tipo_causa_morte_enum;
DROP TYPE IF EXISTS resultado_partida_enum;
DROP TYPE IF EXISTS categoria_item_enum;
DROP TYPE IF EXISTS tipo_perfil_user;

-- ==========================================
-- CRIAÇÃO DOS TIPOS ENUM
-- ==========================================
CREATE TYPE tipo_perfil_user AS ENUM ('JOGADOR', 'ADMIN', 'TESTER');
CREATE TYPE categoria_item_enum AS ENUM ('COMIDA', 'BEBIDA', 'MEDICAMENTO', 'FERRAMENTA', 'MATERIAL');
CREATE TYPE resultado_partida_enum AS ENUM ('EM_ANDAMENTO', 'VITORIA', 'DERROTA', 'ABANDONADA');
CREATE TYPE tipo_causa_morte_enum AS ENUM ('FOME', 'SEDE', 'DANO_FISICO', 'QUEDA', 'OUTRO');
CREATE TYPE status_bug_enum AS ENUM ('ABERTO', 'EM_ANALISE', 'RESOLVIDO', 'FECHADO');

-- ==========================================
-- 1. TABELA: jogador
-- ==========================================
CREATE TABLE jogador (
    id_jogador SERIAL PRIMARY KEY,
    nickname VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    tipo_perfil tipo_perfil_user NOT NULL,
    total_partidas_jogadas INT,
    total_vitorias INT,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_jogador_nickname UNIQUE (nickname),
    CONSTRAINT uq_jogador_email UNIQUE (email)
);

-- ==========================================
-- 2. TABELA: item_catalogo
-- ==========================================
CREATE TABLE item_catalogo (
    id_item_catalogo SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    categoria categoria_item_enum NOT NULL,
    peso_unitario DECIMAL(5,2) NOT NULL,
    recuperacao_vida DECIMAL(5,2),
    recuperacao_fome DECIMAL(5,2),
    recuperacao_sede DECIMAL(5,2),

    CONSTRAINT uq_item_catalogo_nome UNIQUE (nome)
);

-- ==========================================
-- 3. TABELA: configuracao_jogo
-- ==========================================
CREATE TABLE configuracao_jogo (
    id_configuracao_jogo SERIAL PRIMARY KEY,
    fk_jogador INT NOT NULL,
    volume_geral INT,
    volume_musica INT,
    volume_sfx INT,
    resolucao_tela VARCHAR(20),
    modo_janela BOOLEAN,
    sensibilidade_mouse DECIMAL(5,2),
    data_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_configuracao_jogo_jogador UNIQUE (fk_jogador),
    CONSTRAINT fk_configuracao_jogo_jogador FOREIGN KEY (fk_jogador) REFERENCES jogador(id_jogador) ON DELETE CASCADE
);

-- ==========================================
-- 4. TABELA: reporte_bug
-- ==========================================
CREATE TABLE reporte_bug (
    id_reporte_bug SERIAL PRIMARY KEY,
    fk_jogador INT NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    descricao TEXT NOT NULL,
    status status_bug_enum NOT NULL,
    data_envio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reporte_bug_jogador FOREIGN KEY (fk_jogador) REFERENCES jogador(id_jogador) ON DELETE CASCADE
);

-- ==========================================
-- 5. TABELA: partida
-- ==========================================
CREATE TABLE partida (
    id_partida SERIAL PRIMARY KEY,
    fk_jogador INT NOT NULL,
    dias_sobrevividos INT,
    tempo_jogado_segundos INT,
    resultado resultado_partida_enum NOT NULL,
    causa_morte tipo_causa_morte_enum,
    data_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_fim TIMESTAMP,

    CONSTRAINT fk_partida_jogador FOREIGN KEY (fk_jogador) REFERENCES jogador(id_jogador) ON DELETE CASCADE
);

-- ==========================================
-- 6. TABELA: evento_game_loop
-- ==========================================
CREATE TABLE evento_game_loop (
    id_evento_game_loop SERIAL PRIMARY KEY,
    fk_partida INT NOT NULL,
    dia_virtual INT NOT NULL,
    descricao_evento VARCHAR(255) NOT NULL,
    data_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_evento_game_loop_partida FOREIGN KEY (fk_partida) REFERENCES partida(id_partida) ON DELETE CASCADE
);

-- ==========================================
-- 7. TABELA: telemetria_partida
-- ==========================================
CREATE TABLE telemetria_partida (
    id_telemetria_partida SERIAL PRIMARY KEY,
    fk_partida INT NOT NULL,
    fps_medio INT,
    input_lag_ms INT,
    itens_coletados_total INT,
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_telemetria_partida_partida FOREIGN KEY (fk_partida) REFERENCES partida(id_partida) ON DELETE CASCADE
);

-- ==========================================
-- 8. TABELA: recurso_cenario
-- ==========================================
CREATE TABLE recurso_cenario (
    id_recurso_cenario SERIAL PRIMARY KEY,
    fk_partida INT NOT NULL,
    fk_item_catalogo INT NOT NULL,
    posicao_x DECIMAL(10,4) NOT NULL,
    posicao_y DECIMAL(10,4) NOT NULL,
    posicao_z DECIMAL(10,4) NOT NULL,
    coletado BOOLEAN,

    CONSTRAINT fk_recurso_cenario_partida FOREIGN KEY (fk_partida) REFERENCES partida(id_partida) ON DELETE CASCADE,
    CONSTRAINT fk_recurso_cenario_item_catalogo FOREIGN KEY (fk_item_catalogo) REFERENCES item_catalogo(id_item_catalogo) ON DELETE CASCADE
);

-- ==========================================
-- 9. TABELA: save_state
-- ==========================================
CREATE TABLE save_state (
    id_save_state SERIAL PRIMARY KEY,
    fk_partida INT NOT NULL,
    vida_atual DECIMAL(5,2) NOT NULL,
    fome_atual DECIMAL(5,2) NOT NULL,
    sede_atual DECIMAL(5,2) NOT NULL,
    posicao_x DECIMAL(10,4) NOT NULL,
    posicao_y DECIMAL(10,4) NOT NULL,
    posicao_z DECIMAL(10,4) NOT NULL,
    capacidade_maxima_peso DECIMAL(6,2) NOT NULL,
    data_salvamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_save_state_partida UNIQUE (fk_partida),
    CONSTRAINT fk_save_state_partida FOREIGN KEY (fk_partida) REFERENCES partida(id_partida) ON DELETE CASCADE
);

-- ==========================================
-- 10. TABELA: inventario_item
-- ==========================================
CREATE TABLE inventario_item (
    id_inventario_item SERIAL PRIMARY KEY,
    fk_save_state INT NOT NULL,
    fk_item_catalogo INT NOT NULL,
    slot_posicao INT NOT NULL,
    quantidade INT NOT NULL,

    CONSTRAINT fk_inventario_item_save_state FOREIGN KEY (fk_save_state) REFERENCES save_state(id_save_state) ON DELETE CASCADE,
    CONSTRAINT fk_inventario_item_item_catalogo FOREIGN KEY (fk_item_catalogo) REFERENCES item_catalogo(id_item_catalogo) ON DELETE CASCADE
);


-- ==========================================
-- SCRIPT DE INSERÇÃO DIDÁTICA (DADOS REALISTAS)
-- ==========================================

-- 1. JOGADOR
INSERT INTO jogador (nickname, email, senha_hash, tipo_perfil, total_partidas_jogadas, total_vitorias) VALUES
('ShadowSurvivor', 'shadow@email.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'JOGADOR', 15, 3),
('AnaExplorer', 'ana.exp@email.com', '$2y$10$8kR5vN2m1L0p9Q3w5e6r7u8i9o0p1a2s3d4f5g6h7j8k9l0z1x2c3v', 'JOGADOR', 22, 5),
('CarlosAdmin', 'carlos.adm@email.com', '$2y$10$3vB2nM1k9L8j7H6g5f4d3s2a1p0o9i8u7y6t5r4e3w2q1z0x9c8v7b', 'ADMIN', 40, 12),
('BiaGamer', 'bia.gamer@email.com', '$2y$10$5tG7bN4m2V1c0x9z8l7k6j5h4g3f2d1s0a9p8o7i6u5y4t3r2e1w0q', 'JOGADOR', 8, 1),
('LucasTester', 'lucas.qa@email.com', '$2y$10$1qA2z3W4s5X6c7D8f9V0gHjKlPoIuYtReWqAsDfGhJkLzXcVbNm', 'TESTER', 50, 10),
('MarianaSurv', 'mariana@email.com', '$2y$10$9p0O9i8U7y6T5r4E3w2Q1a0S9d8F7g6H5j4K3l2Z1x0C9v8B7n6M5', 'JOGADOR', 12, 2),
('PedroCraft', 'pedro.craft@email.com', '$2y$10$4bN5m6L7k8J9h0G1f2D3s4A5p6O7i8U9y0T1r2E3w4Q5a6S7d8F9g', 'JOGADOR', 30, 7),
('ElenaQA', 'elena.qa@email.com', '$2y$10$7z8x9c0v1b2n3m4L5k6J7h8G9f0D1s2A3p4O5i6U7y8T9r0E1w2Q3', 'TESTER', 35, 8),
('RafaelNomad', 'rafael.nomad@email.com', '$2y$10$2w3e4r5t6y7u8i9o0p1a2s3d4f5g6h7j8k9l0z1x2c3v4b5n6m7k8', 'JOGADOR', 5, 0),
('SofiaRanger', 'sofia.ranger@email.com', '$2y$10$6m5n4b3v2c1x0z9l8k7j6h5g4f3d2s1a0p9o8i7u6y5t4r3e2w1q0', 'JOGADOR', 18, 4);

-- 2. ITEM_CATALOGO
INSERT INTO item_catalogo (nome, categoria, peso_unitario, recuperacao_vida, recuperacao_fome, recuperacao_sede) VALUES
('Garrafa de Água Purificada', 'BEBIDA', 0.50, 0.00, 0.00, 35.00),
('Lata de Feijão Enlatado', 'COMIDA', 0.45, 5.00, 40.00, 5.00),
('Kit Médico de Emergência', 'MEDICAMENTO', 1.20, 60.00, 0.00, 0.00),
('Barra de Cereal Energética', 'COMIDA', 0.15, 2.00, 15.00, 0.00),
('Cantil com Água Filtrada', 'BEBIDA', 0.80, 0.00, 0.00, 50.00),
('Bandagem Estéril', 'MEDICAMENTO', 0.10, 20.00, 0.00, 0.00),
('Pé de Cabra Reforçado', 'FERRAMENTA', 2.50, 0.00, 0.00, 0.00),
('Sucata Metálica', 'MATERIAL', 1.00, 0.00, 0.00, 0.00),
('Ração Militar Desidratada', 'COMIDA', 0.60, 10.00, 65.00, -10.00),
('Lanterna Tática', 'FERRAMENTA', 0.40, 0.00, 0.00, 0.00);

-- 3. CONFIGURACAO_JOGO
INSERT INTO configuracao_jogo (fk_jogador, volume_geral, volume_musica, volume_sfx, resolucao_tela, modo_janela, sensibilidade_mouse) VALUES
(1, 80, 60, 90, '1920x1080', FALSE, 1.25),
(2, 100, 80, 100, '2560x1440', FALSE, 1.50),
(3, 70, 40, 85, '1920x1080', TRUE, 1.00),
(4, 90, 75, 90, '1366x768', FALSE, 1.10),
(5, 50, 20, 80, '1920x1080', TRUE, 1.35),
(6, 85, 70, 85, '1920x1080', FALSE, 1.20),
(7, 95, 50, 100, '3840x2160', FALSE, 0.95),
(8, 65, 30, 75, '1920x1080', TRUE, 1.40),
(9, 100, 100, 100, '1600x900', FALSE, 1.15),
(10, 75, 60, 80, '1920x1080', FALSE, 1.30);

-- 4. REPORTE_BUG
INSERT INTO reporte_bug (fk_jogador, titulo, descricao, status) VALUES
(1, 'Personagem preso em colisão de parede', 'Ao pular próximo ao prédio central, o jogador fica travado na geometria.', 'ABERTO'),
(2, 'Inventário não atualiza peso', 'Após consumir uma lata de comida, o peso total permaneceu inalterado.', 'EM_ANALISE'),
(4, 'Queda brusca de FPS na chuva', 'Durante tempestades noturnas a taxa de quadros cai abaixo de 20 FPS.', 'ABERTO'),
(5, 'Duplicação de item no slot 1', 'Arrastar rápido entre slots duplica visualmente a bandagem.', 'RESOLVIDO'),
(6, 'Áudio da música corta ao abrir mapa', 'A trilha sonora reinicia toda vez que o mapa da cidade é fechado.', 'FECHADO'),
(7, 'Recurso flutuando no cenário', 'Uma garrafa de água apareceu 2 metros acima do chão na praça norte.', 'RESOLVIDO'),
(8, 'Save não carrega posição Z', 'Ao carregar partida salva em telhado, o personagem nasce no térreo.', 'EM_ANALISE'),
(9, 'Erro de tradução no menu de pausa', 'O botão de retomar partida aparece em inglês mesmo em português.', 'FECHADO'),
(10, 'Lanterna apaga sozinha ao correr', 'Pressionar shift para correr desativa a luz da lanterna.', 'ABERTO'),
(3, 'Crash ao finalizar partida com vitória', 'O jogo fecha inesperadamente na tela de estatísticas finais.', 'EM_ANALISE');

-- 5. PARTIDA
INSERT INTO partida (fk_jogador, dias_sobrevividos, tempo_jogado_segundos, resultado, causa_morte, data_fim) VALUES
(1, 14, 18400, 'VITORIA', NULL, CURRENT_TIMESTAMP),
(2, 7, 9200, 'DERROTA', 'FOME', CURRENT_TIMESTAMP),
(3, 21, 27500, 'VITORIA', NULL, CURRENT_TIMESTAMP),
(4, 3, 3600, 'DERROTA', 'SEDE', CURRENT_TIMESTAMP),
(5, 5, 6100, 'EM_ANDAMENTO', NULL, NULL),
(6, 9, 11400, 'DERROTA', 'DANO_FISICO', CURRENT_TIMESTAMP),
(7, 15, 19800, 'VITORIA', NULL, CURRENT_TIMESTAMP),
(8, 2, 2400, 'ABANDONADA', NULL, CURRENT_TIMESTAMP),
(9, 4, 4800, 'DERROTA', 'QUEDA', CURRENT_TIMESTAMP),
(10, 8, 10200, 'EM_ANDAMENTO', NULL, NULL);

-- 6. EVENTO_GAME_LOOP
INSERT INTO evento_game_loop (fk_partida, dia_virtual, descricao_evento) VALUES
(1, 1, 'Início da jornada na zona residencial abandonada.'),
(1, 5, 'Primeira tempestade severa enfrentada com sucesso.'),
(2, 3, 'Encontrado abrigo temporário no metrô subterrâneo.'),
(2, 7, 'Nível crítico de fome atingido durante exploração.'),
(3, 10, 'Rádio comunicador reparado na torre leste.'),
(4, 2, 'Suprimentos de água esgotados na região industrial.'),
(5, 4, 'Encontrada caixa de suprimentos médicos no hospital.'),
(6, 8, 'Emboscada sofrida próximo à ponte bloqueada.'),
(7, 15, 'Resgate concluído no ponto de extração norte.'),
(10, 6, 'Base improvisada montada no armazém central.');

-- 7. TELEMETRIA_PARTIDA
INSERT INTO telemetria_partida (fk_partida, fps_medio, input_lag_ms, itens_coletados_total) VALUES
(1, 60, 12, 48),
(2, 58, 15, 23),
(3, 60, 10, 74),
(4, 45, 22, 11),
(5, 59, 14, 19),
(6, 55, 18, 31),
(7, 60, 11, 56),
(8, 52, 20, 7),
(9, 49, 19, 14),
(10, 60, 13, 29);

-- 8. RECURSO_CENARIO
INSERT INTO recurso_cenario (fk_partida, fk_item_catalogo, posicao_x, posicao_y, posicao_z, coletado) VALUES
(1, 1, 125.4500, 10.0000, -45.2000, TRUE),
(1, 2, 130.1000, 10.0000, -42.8000, TRUE),
(2, 3, -84.3200, 15.5000, 210.7500, FALSE),
(3, 7, 310.0000, 22.1000, 98.4000, TRUE),
(4, 5, -12.6000, 5.0000, -115.9000, FALSE),
(5, 6, 45.8000, 12.3000, 67.2000, TRUE),
(6, 8, 200.2500, 8.0000, -180.0000, TRUE),
(7, 9, -150.7500, 30.0000, 44.1000, TRUE),
(9, 10, 78.9000, 11.2000, 12.3000, FALSE),
(10, 4, -55.4000, 9.5000, 88.6000, TRUE);

-- 9. SAVE_STATE
INSERT INTO save_state (fk_partida, vida_atual, fome_atual, sede_atual, posicao_x, posicao_y, posicao_z, capacidade_maxima_peso) VALUES
(1, 95.00, 80.00, 85.00, 140.5000, 10.0000, -30.2500, 25.00),
(2, 15.00, 0.00, 20.00, -90.1000, 15.5000, 205.0000, 20.00),
(3, 100.00, 90.00, 92.00, 350.0000, 25.0000, 110.0000, 30.00),
(4, 20.00, 35.00, 0.00, -15.0000, 5.0000, -120.0000, 20.00),
(5, 78.50, 64.00, 71.00, 50.2000, 12.3000, 70.1000, 25.00),
(6, 0.00, 45.00, 50.00, 210.0000, 8.0000, -175.5000, 25.00),
(7, 88.00, 75.00, 80.00, -145.0000, 30.0000, 50.0000, 30.00),
(8, 65.00, 55.00, 60.00, 10.0000, 10.0000, 10.0000, 20.00),
(9, 0.00, 70.00, 65.00, 80.0000, 2.0000, 15.0000, 20.00),
(10, 82.00, 68.50, 74.00, -50.0000, 9.5000, 90.0000, 25.00);

-- 10. INVENTARIO_ITEM
INSERT INTO inventario_item (fk_save_state, fk_item_catalogo, slot_posicao, quantidade) VALUES
(1, 1, 1, 2),
(1, 2, 2, 3),
(1, 7, 3, 1),
(3, 3, 1, 2),
(3, 9, 2, 4),
(5, 6, 1, 3),
(5, 10, 2, 1),
(7, 5, 1, 2),
(10, 4, 1, 5),
(10, 8, 2, 4);


-- ==========================================
-- 11. CONSULTAS DE VALIDAÇÃO (TESTE RÁPIDO)
-- ==========================================

-- 1. Testar tabela jogador
SELECT * FROM jogador;

-- 2. Testar tabela item_catalogo
SELECT * FROM item_catalogo;

-- 3. Testar tabela configuracao_jogo
SELECT * FROM configuracao_jogo;

-- 4. Testar tabela reporte_bug
SELECT * FROM reporte_bug;

-- 5. Testar tabela partida
SELECT * FROM partida;

-- 6. Testar tabela evento_game_loop
SELECT * FROM evento_game_loop;

-- 7. Testar tabela telemetria_partida
SELECT * FROM telemetria_partida;

-- 8. Testar tabela recurso_cenario
SELECT * FROM recurso_cenario;

-- 9. Testar tabela save_state
SELECT * FROM save_state;

-- 10. Testar tabela inventario_item
SELECT * FROM inventario_item;
--
-- ==========================================
-- QUESTAO 01 
-- ==========================================
SELECT 
  nome,
  categoria,
  peso_unitario
FROM 
  item_catalogo
WHERE categoria = 'COMIDA'
ORDER BY 
  peso_unitario ASC;

-- ==========================================
-- QUESTAO 04
-- ==========================================
SELECT 
  j.nickname,
  rb.titulo,
  rb.status
FROM 
  reporte_bug rb 
INNER JOIN 
  jogador j ON rb.fk_jogador = j.id_jogador
WHERE 
  rb.status = 'ABERTO'
ORDER BY 
  rb.titulo ASC;

-- ==========================================
-- QUESTAO 05
-- ==========================================
SELECT 
  p.id_partida,
  j.nickname,
  p.dias_sobrevividos,
  p.tempo_jogado_segundos
FROM 
  partida p    
INNER JOIN 
  jogador j ON p.fk_jogador = j.id_jogador
WHERE         
  p.resultado = 'VITORIA'
ORDER BY 
  p.dias_sobrevividos DESC;

-- ==========================================
-- QUESTAO 02
-- ==========================================
SELECT 
  nickname,
  total_partidas_jogadas,
  total_vitorias
FROM 
  jogador
ORDER BY
  total_vitorias DESC 
LIMIT 4;

-- ==========================================
-- QUESTAO 07
-- ==========================================
SELECT 
  p.id_partida,
  j.nickname,
  tp.fps_medio,
  tp.itens_coletados_total 
FROM 
  telemetria_partida tp
INNER JOIN 
  partida p ON tp.fk_partida = p.id_partida
INNER JOIN 
  jogador j ON p.fk_jogador = j.id_jogador
WHERE 
  tp.fps_medio < 58
ORDER BY
  tp.fps_medio ASC;

-- ==========================================
-- QUESTAO 06
-- ==========================================
SELECT 
  j.nickname,
  egl.dia_virtual,
  egl.descricao_evento 
FROM
  evento_game_loop egl
INNER JOIN 
  partida p ON egl.fk_partida = p.id_partida
INNER JOIN 
  jogador j ON p.fk_jogador = j.id_jogador
WHERE
  egl.dia_virtual >= 7
ORDER BY 
  egl.dia_virtual DESC
LIMIT 3;
