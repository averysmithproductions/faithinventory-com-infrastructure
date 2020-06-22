#!/bin/bash
AWS_PROFILE=$1
# global parameters

aws ssm delete-parameter	--name 		"/global/thalliumeli/gatsbyjs.com/WEBHOOK_ID" --profile $AWS_PROFILE
aws ssm put-parameter 		--name 		"/global/thalliumeli/gatsbyjs.com/WEBHOOK_ID"			\
							--type 		"String"												\
							--value		"<webhookId>"											\
							--overwrite 														\
							--profile $AWS_PROFILE												\
							--description "The id used to invoke the Gatsby Cloud webhook."

# prod parameters

aws ssm delete-parameter	--name 		"/prod/thalliumeli/SES_SENDER_EMAIL_ADDRESS" --profile $AWS_PROFILE
aws ssm put-parameter 		--name 		"/prod/thalliumeli/SES_SENDER_EMAIL_ADDRESS"			\
							--type 		"String"												\
							--value		"<emailAddress>"										\
							--overwrite 														\
							--profile $AWS_PROFILE												\
							--description "An environment credential needed for ThalliumEliSES to send magic link emails."

# dev parameters

aws ssm delete-parameter	--name 		"/dev/thalliumeli/SES_SENDER_EMAIL_ADDRESS" --profile $AWS_PROFILE
aws ssm put-parameter 		--name 		"/dev/thalliumeli/SES_SENDER_EMAIL_ADDRESS"				\
							--type 		"String"												\
							--value		"<emailAddress>"										\
							--overwrite 														\
							--profile $AWS_PROFILE												\
							--description "An environment credential needed for ThalliumEliSES to send magic link emails."