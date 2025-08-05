USE [ShopAI]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_Generate_AI_Product_Description]
	(
    @Product_ID INT,
	@API_Key NVARCHAR(100),
	@AI_Endpoint NVARCHAR(1000),
	@Description_Language NVARCHAR(100) = 'English',
    @Product_Description_JSON NVARCHAR(MAX) OUTPUT
	)
AS
BEGIN

--Get Product Context Information
	declare @ProductDetails NVARCHAR(255)

	set @ProductDetails =	(SELECT 
						product_name+'=>'+CAST(price AS VARCHAR) + '=>'+c.category_name+'=>'+b.brand_name+'=>'+col.color_name+'=>'+g.gender+'=>'+s.season
						FROM 
						products p
						JOIN category c ON p.category_id = c.category_id
						JOIN brand b ON p.brand_id = b.brand_id
						JOIN color col ON p.color_id = col.color_id
						JOIN gender g ON p.gender_id = g.gender_id
						JOIN season s ON p.season_id = s.season_id
						where product_id = @Product_ID)

--Define AI Playload JSON Object

	declare @prompt nvarchar(max);
	set @prompt = 
	json_object(
		'messages': json_array(
				json_object(
					'role':'system',
					'content':'
						You are an awesome AI marketing assistant for a clothing reseller company. 
						Your job is to write psychological attracting  product descriptions for the companies online shop. You should write the description in 3-5 sentences in the language '+@Description_Language+' and you should respect the principles of AIDA (Attention, Interest, Desire, Action) for writing the description. 
						You will have access to the Product Name, Product Price (in CHF), Product Category, Product Brand, Product Color, Product Gender, Product Season provided to you in the format „Name=>Price=>Category=>Brand=>Color=>Gender=>Season“. Write the description appropriately to the provided Product attributes.
					'
				),
				json_object(
					'role':'user',
					'content': '## Source ##
						' + @ProductDetails + '
						## End ##

						Your answer needs to be a json object with the following format.
						{
							"description": // the product suitable product description
							"product": // the product name for which you wrote the description
						}
						Respond with pure JSON, no markdown formatting, no code block, just the raw object.'
				)
		),
		'max_tokens': 800,
		'temperature': 0.3,
		'frequency_penalty': 0,
		'presence_penalty': 0,
		'top_p': 0.95,
		'stop': null
	);


	declare @retval int, @response nvarchar(max);
	declare @headers nvarchar(300) = N'{"api-key": "'+@API_Key+'", "content-type": "application/json"}';


	exec @retval = sp_invoke_external_rest_endpoint
		@url = @AI_Endpoint,
		@headers = @headers,
		@method = 'POST',    
		@timeout = 120,
		@payload = @prompt,
		@response = @response output;

	set @Product_Description_JSON = @response

END

GO


