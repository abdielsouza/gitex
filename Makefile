.PHONY: runprod

runprod:
	SECRET_KEY_BASE=`mix phx.gen.secret` DATABASE_URL=postgresql://postgres.zbfkjdjzctddudhktgpt:Github%402745@aws-1-sa-east-1.pooler.supabase.com:5432/postgres _build/prod/rel/gitex/bin/server