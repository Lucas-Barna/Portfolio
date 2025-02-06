-- Criando TABELA d_produtos 
CREATE TABLE d_produtos (
    ID_PRODUTOS VARCHAR(4)PRIMARY KEY,   
    DESCRICAO VARCHAR(200),
    PRECO DECIMAL(10,2),
    CUSTO DECIMAL(10,2)
);



 -- extraindo csv PRODUTOS
LOAD DATA INFILE 'C:/xampp/mysql/data/Produtos.csv'
INTO TABLE d_produtos
FIELDS TERMINATED BY ';' -- Definir o separador de campos (ponto/vírgula)
LINES TERMINATED BY '\n' -- Final de linha
IGNORE 1 ROWS;           -- Ignorar a primeira linha (cabeçalho, se houver)

-- Removendo aspas duplas de  d_produtos

UPDATE d_produtos 

SET 	ID_PRODUTOS=REPLACE(`ID_PRODUTOS`,'"','');

-- criando coluna de categoria de PRODUTOS

ALTER TABLE d_produtos
ADD CATEGORIA VARCHAR(20) AFTER ID_PRODUTOS;

-- condicional para preencher a coluna

UPDATE d_produtos 
SET Categoria = 
    CASE 
	WHEN DESCRICAO LIKE '%Teclado e Mouse%' THEN 'Teclado e Mouse'
        WHEN DESCRICAO LIKE '%Mouse%' THEN 'Mouse'
        WHEN DESCRICAO LIKE '%Teclado%' THEN 'Teclados'
        WHEN DESCRICAO LIKE '%Headset%' THEN 'Headset'
        WHEN DESCRICAO LIKE '%Roteador%' THEN 'Roteadores'
        WHEN DESCRICAO LIKE '%Cadeira%' THEN 'Cadeiras'
        WHEN DESCRICAO LIKE '%Nobreak%' THEN 'Nobreaks'
        WHEN DESCRICAO LIKE '%Memória%' THEN 'Memórias'
        WHEN DESCRICAO LIKE '%Pen Drive%' THEN 'Pen Drives'
        WHEN DESCRICAO LIKE '%Monitor%' THEN 'Monitores'
        WHEN DESCRICAO LIKE '%HD%' THEN 'HD'
        WHEN DESCRICAO LIKE '%Computador%' THEN 'Computadores'
        ELSE 'Outros'
    END;


----------------------------------------------------------------------------------
	
-- Criando TABELA d_vendedores


CREATE TABLE d_vendedores (

ID_VENDEDOR VARCHAR(3)PRIMARY KEY,
DESCRICAO VARCHAR(20)

);

-- extraindo csv VENDEDORES 

LOAD DATA INFILE 'C:/xampp/mysql/data/VENDEDORES.csv'
INTO TABLE d_vendedores
FIELDS TERMINATED BY ';' -- Definir o separador de campos (ponto/vírgula)
LINES TERMINATED BY '\n' -- Final de linha
IGNORE 1 ROWS;           -- Ignorar a primeira linha (cabeçalho, se houver)


-- Removendo aspas duplas de ID_VENDEDOR e DESCRICAO


UPDATE d_vendedores
SET ID_VENDEDOR = REPLACE(ID_VENDEDOR, '"', ''),
    DESCRICAO = REPLACE(DESCRICAO, '"', '');

	
	
----------------------------------------------------------------------------------

	
--  TABELA FATO VENDAS


CREATE TABLE f_vendas (
    ID_VENDAS INT NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    ID_PRODUTOS VARCHAR(4),  
    ID_VENDEDOR VARCHAR(3),  
    DATA_VENDA DATE  
    
);


-- EXTRAINDO CSV VENDAS

LOAD DATA INFILE 'C:/xampp/mysql/data/VENDAS.csv'
INTO TABLE f_vendas
FIELDS TERMINATED BY ';' -- Definir o separador de campos (ponto/vírgula)
LINES TERMINATED BY '\n' -- Final de linha
IGNORE 1 ROWS           -- Ignorar a primeira linha (cabeçalho, se houver)
(ID_PRODUTOS, ID_VENDEDOR, DATA_VENDA); -- preencher as informações somente destas colunas


-- Removendo aspas duplas de ID_PRODUTOS

UPDATE f_vendas 

SET 	ID_PRODUTOS=REPLACE(`ID_PRODUTOS`,'"','');

 -- alterando registro de data da venda que estava como 29/02/2022. SQL reconheceu como 0000-00-00
UPDATE f_vendas 

SET 	DATA_VENDA=REPLACE(DATA_VENDA,'0000-00-00','2022-02-28')
WHERE ID_VENDAS = 61;


-- VIEW VENDEDORES

CREATE VIEW V_VENDAS AS 

SELECT 
    v.ID_VENDAS AS "Código da Venda",
    p.DESCRICAO AS "Produto Vendido",
    ve.DESCRICAO AS "Vendedor",
    v.DATA_VENDA AS "Data da venda",
    p.PRECO AS "Valor da Venda",
    p.CUSTO AS "Custos"    
FROM f_vendas v
LEFT JOIN d_produtos p 
    ON v.ID_PRODUTOS = p.ID_PRODUTOS
LEFT JOIN d_vendedores ve
    ON ve.ID_VENDEDOR = v.ID_VENDEDOR
WHERE p.PRECO IS NOT NULL

----------------------------------------------------------------------------------


-- Consultas e métricas

-- Vendas Anual

SELECT 
    YEAR(v.DATA_VENDA) AS "Ano",
    SUM(p.PRECO) AS "Valor da Venda",
    SUM(p.CUSTO) AS "Custos",
    SUM(p.PRECO) - SUM(p.CUSTO) AS "Receita Líquida",
    CAST(((SUM(p.PRECO) - SUM(p.CUSTO)) / SUM(p.PRECO)) * 100 AS DECIMAL(10, 2)) AS "Margem"
    
FROM f_vendas v
LEFT JOIN d_produtos p 
    ON v.ID_PRODUTOS = p.ID_PRODUTOS
WHERE p.PRECO IS NOT NULL

GROUP BY 
    YEAR(v.DATA_VENDA);
	
	
 --  Top 5 produtos vendidos no ano de 2022
 
SELECT 
    p.CATEGORIA AS 'Categoria',
    p.DESCRICAO AS "Produto Vendido",
    SUM(p.PRECO) - SUM(p.CUSTO) AS "Receita Líquida",
    ROUND(((SUM(p.PRECO) - SUM(p.CUSTO)) / 
           (SELECT SUM(p1.PRECO) - SUM(p1.CUSTO) 
            FROM f_vendas v1
            LEFT JOIN d_produtos p1 
                ON v1.ID_PRODUTOS = p1.ID_PRODUTOS
            WHERE p1.PRECO IS NOT NULL AND YEAR(v1.DATA_VENDA) = 2022) * 100), 2) AS "Porcentagem"
FROM f_vendas v
LEFT JOIN d_produtos p 
    ON v.ID_PRODUTOS = p.ID_PRODUTOS
WHERE p.PRECO IS NOT NULL AND YEAR(v.DATA_VENDA) = 2022
GROUP BY 
    p.ID_PRODUTOS
ORDER BY 
    (SUM(p.PRECO) - SUM(p.CUSTO)) DESC 
LIMIT 5;


-- Vendas por vendedor 

SELECT 
    ve.DESCRICAO AS "Vendedor",
    COUNT(v.ID_PRODUTOS) AS "Produtos Vendidos",
    ROUND((COUNT(v.ID_PRODUTOS) / 
           (SELECT COUNT(v1.ID_PRODUTOS)
            FROM f_vendas v1
            LEFT JOIN d_produtos p1 ON v1.ID_PRODUTOS = p1.ID_PRODUTOS
            WHERE p1.PRECO IS NOT NULL AND YEAR(v1.DATA_VENDA) = 2022) * 100), 2) AS "Porcentagem"
FROM f_vendas v
LEFT JOIN d_produtos p 
    ON v.ID_PRODUTOS = p.ID_PRODUTOS
LEFT JOIN d_vendedores ve
    ON ve.ID_VENDEDOR = v.ID_VENDEDOR
WHERE p.PRECO IS NOT NULL AND YEAR(v.DATA_VENDA) = 2022
GROUP BY 
    ve.ID_VENDEDOR
ORDER BY 
    COUNT(v.ID_PRODUTOS)DESC;
	
	
-- Vendas Acumuladas (YTD)

SELECT 
    YEAR(v.DATA_VENDA) AS "Ano",
    MONTH(v.DATA_VENDA) AS "Mês",
    SUM(SUM(p.PRECO)) OVER (PARTITION BY YEAR(v.DATA_VENDA) ORDER BY MONTH(v.DATA_VENDA)) AS "Valor da Venda Acumulado",
    SUM(SUM(p.CUSTO)) OVER (PARTITION BY YEAR(v.DATA_VENDA) ORDER BY MONTH(v.DATA_VENDA)) AS "Custos Acumulados",
    SUM(SUM(p.PRECO) - SUM(p.CUSTO)) OVER (PARTITION BY YEAR(v.DATA_VENDA) ORDER BY MONTH(v.DATA_VENDA)) AS "Receita Líquida Acumulada"
FROM f_vendas v
LEFT JOIN d_produtos p 
    ON v.ID_PRODUTOS = p.ID_PRODUTOS
WHERE p.PRECO IS NOT NULL
GROUP BY 
    YEAR(v.DATA_VENDA),
    MONTH(v.DATA_VENDA)
ORDER BY 
    YEAR(v.DATA_VENDA) ASC, MONTH(v.DATA_VENDA); 

