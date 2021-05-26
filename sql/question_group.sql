SELECT
	content.Id game_id,
	question.Id item_id,
	question_group_config.DisplayOrder item_order
FROM
	iquizoo_content_db.question
	INNER JOIN iquizoo_content_db.question_group_config
		ON question.Id = question_group_config.QuestionId
	INNER JOIN iquizoo_content_db.content
		ON content.Id = question_group_config.QuestionGroupId;
