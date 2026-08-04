insert into core.dim_zone(zone_key, borough, zone, service_zone)
	select locationid, coalesce(borough, 'Unknown'), coalesce(zone, 'Unknown'), service_zone 
		from raw.taxi_zone_lookup
		on conflict (zone_key) do update
		set borough = excluded.borough,
			zone = excluded.zone,
			service_zone = excluded.service_zone;

select count(*) from core.dim_zone;

insert into core.dim_date (date_key, full_date, year, quarter, month, day, day_of_week, is_weekend)
	select to_char(d, 'YYYYMMDD')::int,
	d::date,
	extract(year from d)::smallint,
	extract(quarter from d)::smallint,
	extract(month from d)::smallint,
	extract(day from d)::smallint,
	extract(isodow from d)::smallint,
	extract(isodow from d) in (6, 7)
	from generate_series('2024-01-01'::date, '2024-01-31'::date, interval '1 day') d
	on conflict(date_key) do nothing;

select count(*) from core.dim_date;
select * from core.dim_date order by date_key limit 7;

delete from core.fact_trips
	where pickup_ts >= '2024-01-01'::date and pickup_ts < '2024-02-01'::date;

insert into core.fact_trips (pickup_date_key, pickup_zone_key, dropoff_zone_key, payment_type_key, pickup_ts,
								dropoff_ts, passenger_count, trip_distance, duration_min, fare_amount, 
								tip_amount, total_amount)
	select to_char(tpep_pickup_datetime, 'YYYYMMDD')::int, pulocationid, dolocationid, payment_type, 
					tpep_pickup_datetime, tpep_dropoff_datetime, passenger_count::smallint, trip_distance::numeric(8, 2),
					(extract(epoch from (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60)::numeric(8, 2),
					fare_amount::numeric(10, 2),
					tip_amount::numeric(10, 2),
					total_amount::numeric(10, 2)
	from raw.yellow_trips
	where tpep_pickup_datetime >= '2024-01-01'::date and tpep_pickup_datetime < '2024-02-01'::date
		and tpep_dropoff_datetime > tpep_pickup_datetime and total_amount > 0 and trip_distance > 0
		and pulocationid in (select zone_key from core.dim_zone)
		and dolocationid in (select zone_key from core.dim_zone)
		and payment_type in (select payment_type_key from core.dim_payment_type);

select count(*) from core.fact_trips;
select
    count(*) filter (where tpep_pickup_datetime <  '2024-01-01'
                        or tpep_pickup_datetime >= '2024-02-01') as out_of_month,
    count(*) filter (where tpep_dropoff_datetime <= tpep_pickup_datetime) as bad_time,
    count(*) filter (where total_amount <= 0)   as bad_amount,
    count(*) filter (where trip_distance <= 0)  as zero_distance
from raw.yellow_trips;

select z.borough, count(*)
from core.fact_trips f
join core.dim_zone z on z.zone_key = f.pickup_zone_key
group by 1 order by 2 desc;