--Выручка по районам в выходные
select z.borough,
       count(*) trips,
       round(sum(f.total_amount)) revenue
from core.fact_trips f
join core.dim_zone z on z.zone_key = f.pickup_zone_key
join core.dim_date d on d.date_key = f.pickup_date_key
where d.is_weekend
group by z.borough
order by revenue desc;

--Выручка и средний чек по районам посадки
select z.borough,
		count(*),
		round(avg(f.total_amount), 2) avg_check,
		round(sum(f.total_amount), 2) revenue
from core.fact_trips f
join core.dim_zone z on z.zone_key = f.pickup_zone_key
group by z.borough
order by revenue desc;

--Спрос и чаевые по часам суток
select extract(hour from f.pickup_ts)::int hour_pickup,
		count(*),
		round(avg(f.tip_amount), 2) tip,
		round(avg(f.duration_min), 1) avg_duration_min
from core.fact_trips f
group by hour_pickup
order by hour_pickup desc

--Будни против выходных в разрезе способов оплаты
select p.payment_type_name, d1.is_weekend, count(*) trips,
		round(sum(f.total_amount)) revenue, 
		round(100.0 * count(*) / sum(count(*)) over (partition by d1.is_weekend), 1) share_pct
from core.fact_trips f
join core.dim_payment_type p on p.payment_type_key = f.payment_type_key
join core.dim_date d1 on f.pickup_date_key = d1.date_key
group by p.payment_type_name, d1.is_weekend 
order by d1.is_weekend, trips desc;

--Топ 3 зоны посадки внутри каждого района
with cnt_borough as (
	select count(*) cnt, z.zone, z.borough,
			row_number() over (partition by z.borough order by count(*) desc) rn
	from core.fact_trips f
	join core.dim_zone z on f.pickup_zone_key = z.zone_key
	group by z.zone, z.borough
)
select *
from cnt_borough
where rn <= 3
order by borough, cnt desc