-- Reduce dump size for faster local migration / testing runs.
--
-- 0) Make every FK in the DB ON DELETE CASCADE. Django's on_delete is
--    enforced in Python only — at the Postgres level every FK is NO ACTION,
--    so a raw DELETE on auth_user fails on the first child table. Since
--    auth_user cascades across ~54 tables transitively, we bulk-rewrite
--    all FKs instead of chasing the chain by hand. This is destructive
--    for a production DB (SET_NULL/PROTECT semantics are lost), but for a
--    freshly imported dump that we're about to shrink anyway it's fine.
--
-- 1) Users: keep 'admin', 'user' and 100 random others. With step 0 in
--    place the CASCADE removes dependent rows (routines, plans, sessions,
--    logs, weight entries, images, trophies, gym contracts, simple_history
--    records, admin log, tokens, …) automatically.
--
-- 2) Ingredients: keep every ingredient still referenced from MealItem,
--    LogItem or IngredientWeightUnit (these three are the only FKs that
--    point at nutrition_ingredient), plus enough random extras to reach
--    100 000 rows. If more than 100 000 ingredients are referenced they
--    all stay.

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Rewrite every FK in the public schema to ON DELETE CASCADE
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    r            record;
    col_list     text;
    ref_col_list text;
BEGIN
    FOR r IN
        SELECT c.conrelid::regclass  AS tbl,
               c.confrelid::regclass AS ref_tbl,
               c.conname,
               c.conkey,
               c.confkey
        FROM   pg_constraint c
        WHERE  c.contype = 'f'
          AND  c.confdeltype <> 'c'
          AND  c.connamespace = 'public'::regnamespace
    LOOP
        SELECT string_agg(quote_ident(a.attname), ',' ORDER BY k.ord)
          INTO col_list
          FROM unnest(r.conkey) WITH ORDINALITY AS k(attnum, ord)
          JOIN pg_attribute a ON a.attrelid = r.tbl AND a.attnum = k.attnum;

        SELECT string_agg(quote_ident(a.attname), ',' ORDER BY k.ord)
          INTO ref_col_list
          FROM unnest(r.confkey) WITH ORDINALITY AS k(attnum, ord)
          JOIN pg_attribute a ON a.attrelid = r.ref_tbl AND a.attnum = k.attnum;

        EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I',
                       r.tbl, r.conname);
        EXECUTE format(
            'ALTER TABLE %s ADD CONSTRAINT %I FOREIGN KEY (%s) '
            'REFERENCES %s(%s) ON DELETE CASCADE',
            r.tbl, r.conname, col_list, r.ref_tbl, ref_col_list);
    END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Users
-- ---------------------------------------------------------------------------
WITH users_to_keep AS (
    SELECT id FROM auth_user WHERE username IN ('admin', 'user')
    UNION
    (SELECT id
     FROM auth_user
     WHERE username NOT IN ('admin', 'user')
     ORDER BY random()
     LIMIT 100)
)
DELETE FROM auth_user
WHERE id NOT IN (SELECT id FROM users_to_keep);

-- ---------------------------------------------------------------------------
-- 2. Ingredients
-- ---------------------------------------------------------------------------
-- Note: user deletion above already cascaded and removed a lot of MealItem /
-- LogItem rows, so the "referenced" set is evaluated against the *reduced*
-- state — which is what we want.
WITH referenced AS (
    SELECT ingredient_id AS id FROM nutrition_mealitem
    UNION
    SELECT ingredient_id FROM nutrition_logitem
    UNION
    SELECT ingredient_id FROM nutrition_ingredientweightunit
),
random_extras AS (
    SELECT id
    FROM nutrition_ingredient
    WHERE id NOT IN (SELECT id FROM referenced)
    ORDER BY random()
    LIMIT GREATEST(0, 100000 - (SELECT count(*) FROM referenced))
),
ingredients_to_keep AS (
    SELECT id FROM referenced
    UNION
    SELECT id FROM random_extras
)
DELETE FROM nutrition_ingredient
WHERE id NOT IN (SELECT id FROM ingredients_to_keep);

COMMIT;

-- Reclaim space and refresh planner stats. Must run outside the transaction.
VACUUM ANALYZE auth_user;
VACUUM ANALYZE nutrition_ingredient;
