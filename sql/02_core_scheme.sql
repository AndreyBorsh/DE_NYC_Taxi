create table if not exists core.dim_zone (
	zone_key integer primary key,
	borough text not null,
	zone text not null,
	service_zone text
)

create table if not exists core.dim_payment_type (
	payment_type_key integer primary key,
	payment_type_name text not null
)

insert into core.dim_payment_type (payment_type_key, payment_type_name) values
    (0, 'Flex Fare'),
    (1, 'Credit card'),
    (2, 'Cash'),
    (3, 'No charge'),
    (4, 'Dispute'),
    (5, 'Unknown'),
    (6, 'Voided trip')
on conflict (payment_type_key) do nothing;

create table if not exists core.dim_date (
    date_key    integer primary key,
    full_date   date not null,
    year        smallint not null,
    quarter     smallint not null,
    month       smallint not null,
    day         smallint not null,
    day_of_week smallint not null,
    is_weekend  boolean not null
);

create table if not exists core.fact_trips(
	trip_id bigserial primary key,
	pickup_date_key integer references core.dim_date(date_key) not null,
	pickup_zone_key  integer not null references core.dim_zone(zone_key),
	dropoff_zone_key integer not null references core.dim_zone(zone_key),
	payment_type_key integer references core.dim_payment_type(payment_type_key) not null,
	pickup_ts timestamp not null,
	dropoff_ts timestamp not null,
	passenger_count smallint,
	trip_distance numeric(8,2) not null,
	duration_min numeric(8,2) not null,
	fare_amount numeric(10,2) not null,
	tip_amount numeric(10,2) not null,
	total_amount numeric(10,2) not null
);
create index if not exists ix_fact_trips_pickup_date on core.fact_trips(pickup_date_key);
create index if not exists ix_fact_trips_pickup_zone on core.fact_trips(pickup_zone_key);
create index if not exists ix_fact_trips_dropoff_zoney on core.fact_trips(dropoff_zone_key);


select * from raw.taxi_zone_lookup tzl
select * from raw.yellow_trips
select * from core.dim_payment_type
select count(*) from raw.taxi_zone_lookup where service_zone is null