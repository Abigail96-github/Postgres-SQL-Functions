CREATE OR REPLACE FUNCTION public.add_business_days(from_date date, num_days integer)
 RETURNS date
 LANGUAGE plpgsql
AS $function$
begin
	from_date:= from_date- 1;
    while num_days > 0 loop
        from_date:= from_date+ 1;
--       from_date:= from_date;
        while from_date in (select fh.date from public.fdm_holiday fh) or extract('dow' from from_date) in (0, 6) loop
            from_date:= from_date+ 1;
        end loop;
        num_days:= num_days- 1;
    end loop;
    return from_date;
end;
$function$
;
