--- Data Cleaning

select *
from layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Value or Blank values
-- 4. Remove Any Coloumns


create table layoffs_staging
like layoffs;

select *
from layoffs_staging;

insert layoffs_staging
select *
from layoffs;

						# -- 1. Remove Duplicates -- #
select *,
row_number() over(
partition by company, industry, total_laid_off, percentage_laid_off, `date`) as row_num
from layoffs_staging;

with duplicate_cte as
(
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging
)
select *
from duplicate_cte
where row_num > 1; -- menunjukan adanya duplikat pada data, dan data mana saja yang duplicate

select *
from layoffs_staging
where company = 'casper';

with duplicate_cte as
(
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging
)
delete 
from duplicate_cte
where row_num > 1; 
-- MySQL tidak mengizinkan DELETE langsung dari CTE (WITH clause).  
-- CTE hanya bersifat temporary result set, bukan tabel nyata yang bisa dihapus datanya.

DROP TABLE IF EXISTS layoffs_staging2;

CREATE TABLE layoffs_staging2 AS -- pakai ROW_NUMBER di table sementara (paling benar)
SELECT *,
ROW_NUMBER() OVER(
    PARTITION BY company,
                 location,
                 industry,
                 total_laid_off,
                 percentage_laid_off,
                 `date`,
                 stage,
                 country,
                 funds_raised_millions
) AS row_num
FROM layoffs_staging;

DELETE FROM layoffs_staging2
WHERE row_num > 1; -- hapus duplicate

SELECT *
FROM layoffs_staging2
where row_num > 1; -- sudah tidak ada duplicate

insert into layoffs_staging2
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging;

delete
FROM layoffs_staging2
where row_num > 1; -- pastikan tidak ada duplicate

select *
from layoffs_staging2;


							# -- 2. Standardizing Data -- #

select company, trim(company) -- TRIM() digunakan untuk menghapus karakter di awal dan akhir string, biasanya spasi.
from layoffs_staging2;

update layoffs_staging2
set company = trim(company); --  update data yang sudah bersih

select distinct industry
from layoffs_staging2;
-- order by 1;

select *
from layoffs_staging2
where industry like 'Crypto%'; -- ada 2 macam tulisan crypto dan crypto currency

SET SQL_SAFE_UPDATES = 0; -- Non aktifkan safe update, karena tadi safe updatenya aktif jadi tidak bisa ganti crypto currency ke crypto

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'; -- update format jadi hanya ada crypto saja

select distinct location
from layoffs_staging2
order by 1;

select distinct country -- ternyata di country ada 2 macam tulisan United States dan United States. beda di . tapi harus disamakan
from layoffs_staging2
order by 1;

select *
from layoffs_staging2
where country like'United States%'
order by 1;

select distinct country, trim(trailing '.' from country) -- untuk hapus titiknya ternyata bisa pakai trim(trailing) 
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = trim(trailing '.' from country) -- update data yang sudah di sesuaikan dengan menghapus titik tadi
where country like 'United States%';

select distinct country
from layoffs_staging2
order by 1; -- dilakukan pengecekan apakah sudah terupdate dan hasilnya pun sudah ter update

select *
from layoffs_staging2;

-- timeseries, disini kita ganti format tanggalnya yang masih dalam bentuk teks menjadi time series biar lebih rapih 
select `date`
from layoffs_staging2; -- bisa dilihat sebelum di ganti format tanggalnya sangat berantakan

select `date`,
str_to_date(`date`, '%m/%d/%Y') as date_correct
from layoffs_staging2; -- penggantian format tanggan bisa pakai str_to_date ya seperti ini

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y'); -- saatnya di update 

alter table layoffs_staging2 -- Mengubah tipe data date, ALTER TABLE digunakan untuk mengubah struktur tabel yang sudah ada (bukan isi datanya), 
modify column `date` date; -- Mengubah dari TEXT → DATE


						# -- 3. Null Value or Blank values -- #
-- total_laid_off
select *
from layoffs_staging2;

select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null; -- lihat pada coloumn total_laid_off dan percentage_laid_off seberapa banyak null 
-- ternayata banyak ya


SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR industry = ''; -- ternayata di coloumn indutry juga ada null dan blank
   
select *
from layoffs_staging2
where company = 'Airbnb'; -- dimana untuk mengisi data industry yang nul bisa melihat data yang sejenis

update layoffs_staging2
set industry = null
where industry = ''; -- jadi kita buat yang blank menjadi null
   

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR industry = ''; -- kita cek apakah sudah ter update
   
select *
from layoffs_staging2
where company like 'bally%'; -- masih proses cek

select t1.industry, t2.industry
from layoffs_staging2 t1 -- gabungkan atau join layoffs_staging2 dengan layoffs_staging2
join layoffs_staging2 t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null; -- dimana kita fokus melihat industry yang null dengan industri yang not null

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL; -- buat yang null terisi berdasar pada data yang sesuai dengan data yang null

						# -- 4. Remove Any Coloumns --#

select *
from layoffs_staging2
;
-- karena di coloum total_laid_off dan percentage_laid_off banyak sekali null dan dilihat dari isi datanya 2 coloum tersebut kemungkinan tidak terlalu dibutuhkan
-- jadi lebih baik dihapus saja data yang null

delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

select *
from layoffs_staging2
;

alter table layoffs_staging2 -- Menghapus kolom helper (row_num)
drop column row_num; -- Membersihkan kolom yang hanya dipakai sementara