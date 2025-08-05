Declare @Product_ID int = 0
Declare @AIGeneratedDescription NVARCHAR(max)

exec SP_Generate_AI_Product_Description @Product_ID = @Product_ID,
										@API_Key = '',
										@AI_Endpoint = '',
										@Product_Description_JSON = @AIGeneratedDescription OUTPUT

SELECT 
    p.product_id,
    p.product_name,
    p.currency,
    p.price,
    c.category_name,
    b.brand_name,
    co.color_name,
    g.gender,
    s.season,
    json_return.description AS AIProductDescription

FROM dbo.products p
INNER JOIN dbo.category c ON p.category_id = c.category_id
INNER JOIN dbo.brand b    ON p.brand_id = b.brand_id
INNER JOIN dbo.color co   ON p.color_id = co.color_id
INNER JOIN dbo.gender g   ON p.gender_id = g.gender_id
INNER JOIN dbo.season s   ON p.season_id = s.season_id
CROSS APPLY OPENJSON(@AIGeneratedDescription, '$.result.choices')
WITH (
    content NVARCHAR(MAX) '$.message.content'
) AS con
CROSS APPLY OPENJSON(con.content)
WITH (
    description NVARCHAR(MAX),
    product     NVARCHAR(200)
) AS json_return
WHERE p.product_id = @Product_ID;
