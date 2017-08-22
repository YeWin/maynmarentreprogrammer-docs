create table category (
category_id serial PRIMARY KEY,
category_name varchar(30),
created_date timestamp without time zone,
updated_date timestamp without time zone
);

create table administrator (
admin_id serial PRIMARY KEY,
admin_name varchar(30),
admin_email varchar(50),
admin_password varchar(30),
created_date timestamp without time zone,
updated_date timestamp without time zone
);

create table post (
post_id serial PRIMARY KEY,
admin_id integer,
category_id integer,
post_title_eng varchar(150),
post_title_mmr varchar(150),
post_title_img_url varchar(150),
post_content text,
created_date timestamp without time zone,
updated_date timestamp without time zone
);

create table archive (
archive_id serial PRIMARY KEY,
post_id integer	,
year varchar(15),
month varchar(15),
created_date timestamp without time zone,
updated_date timestamp without time zone
);

ALTER TABLE ONLY archive
    ADD CONSTRAINT "post_idFK" FOREIGN KEY (post_id) REFERENCES post(post_id);

ALTER TABLE ONLY post
    ADD CONSTRAINT "admin_idFK" FOREIGN KEY (admin_id) REFERENCES administrator(admin_id);

ALTER TABLE ONLY post
    ADD CONSTRAINT "category_idFK" FOREIGN KEY (category_id) REFERENCES category(category_id);

ALTER TABLE administrator ALTER COLUMN admin_password TYPE character varying(200);

ALTER TABLE administrator ADD COLUMN admin_image_url character varying(150);

ALTER TABLE administrator ADD COLUMN about_admin text;

ALTER TABLE post ADD COLUMN content_type integer; -- 1 tutorial, 0 articles