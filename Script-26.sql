CREATE OR REPLACE FUNCTION public.sp_get_cardnum_auths(offset_param integer, card_number_param text, start_date_param date, end_date_param date)
 RETURNS SETOF authorizations_file
 LANGUAGE plpgsql
AS $function$
DECLARE
    result_data authorizations_file;
BEGIN
    IF EXISTS (
        SELECT 1
        FROM authorizations_file af
        WHERE "CARD_NUM"::TEXT = card_number_param
        AND TO_DATE("AUTH_DATE", 'YYYYMMDDHH24MISS')::DATE >= start_date_param
        AND TO_DATE("AUTH_DATE", 'YYYYMMDDHH24MISS')::DATE <= end_date_param
    ) THEN
        RETURN QUERY (
            SELECT * FROM authorizations_file af
            WHERE "CARD_NUM"::TEXT = card_number_param
            AND TO_DATE("AUTH_DATE", 'YYYYMMDDHH24MISS')::DATE >= start_date_param
            AND TO_DATE("AUTH_DATE", 'YYYYMMDDHH24MISS')::DATE <= end_date_param
            ORDER BY "run_date_time" DESC
            OFFSET offset_param
            LIMIT 10
        );
    ELSE
        RETURN NEXT result_data; -- Return NULL
    END IF;
END;
$function$
;
