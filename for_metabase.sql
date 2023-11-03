/*
PostgreSQL
Таблица с метриками активностей пользователей.

В таблице должна быть информация:
-Сколько всего было заходов на платформу      +
-Сколько было уникальных пользователей        +
-Сколько было попыток решить задачу           +
-Сколько было успешных попыток                +        
-Сколько было решено задач                    +

Таблица разбита на месяцы, а также есть поквартальная информация. Каждый столбец с кварталом должны быть выделен цветом.    -  доделать
Строка с уникальными пользователями должна также подсвечиваться.                                                            -  доделать

Отчет должен иметь фильтр по году: меняешь год и все пересчитывается.                                                       -  реализовал в строке 29
*/

with t1 as (
	select 
		date_trunc('month', userentry.entry_at) as ym,
		userentry.id as entry,
		userentry.user_id,
		codesubmit.id as attempt,
		case when codesubmit.is_false = 0 then codesubmit.id end as corr_attempt,
		case when codesubmit.is_false = 0 then codesubmit.problem_id end as corr_prob
	from userentry 
		left join codesubmit on userentry.user_id = codesubmit.user_id and extract(month from userentry.entry_at) = extract(month from codesubmit.created_at)
	where userentry.user_id >= 94                        --  отсечены тестовые юзеры
		and extract(year from entry_at) = {{entry_at}}     --  переменная (цифра года) задается с клавиатуры в поле Metabase
	)
	, t2 as (
select                                                 -- выборка, содержащая колонки:
    distinct ym,                                       -- месяц года
    'entries' as metrics,                              -- метрика (в данном случае "входы на платформу")
    entry as id                                        -- уникальные айди входов на платформу
from t1
union all                                              -- юнион с аналогичной выборкой, но метрикой "уникальные пользователи"
select                                       
    distinct ym,
    'users' as metrics,
    user_id as id
from t1
union all                                              -- юнион с метрикой "уникальные попытки" и т.д.
select 
    distinct ym,
    'attempts' as metrics,
    attempt as id
from t1
union all
select 
    distinct ym,
    'success_attempts' as metrics,
    corr_attempt as id
from t1
union all
select 
    distinct ym,
    'problems_solved' as metrics,
    corr_prob as id
from t1
    )
select                                               -- выборка из объединенной таблицы t2, содержащей все искомые метрики
    to_char(ym, 'yyyy-mm') as "month",                 -- месяц
    metrics,                                         -- название метрики
    count(id)                                        -- подсчет количества значений метрики
from t2
group by "month", metrics                              -- группировка по месяцу и метрике для реализации сводной таблицы
order by "month", metrics
	
