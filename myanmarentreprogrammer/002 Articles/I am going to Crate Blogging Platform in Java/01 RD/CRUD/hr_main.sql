--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.4
-- Dumped by pg_dump version 9.3.4
-- Started on 2016-06-06 14:02:13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 224 (class 3079 OID 11750)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2315 (class 0 OID 0)
-- Dependencies: 224
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- TOC entry 237 (class 1255 OID 79513)
-- Name: attendance_month(integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION attendance_month(createdyear integer, createdmonth integer, employeeid integer[]) RETURNS TABLE(employee_id integer, employee_name character varying, department_id integer, total text, overtime text, ot_taken_time integer, late text, late_taken_time integer, early_out text, out_taken_time integer, absence text, absence_taken_time integer, leave_type_id integer, duration numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
	SELECT
		( CASE
			WHEN ATTENDANCE.EMPLOYEE_ID IS NOT NULL THEN
				ATTENDANCE.EMPLOYEE_ID
			ELSE
				LEAVE.LE_EMP_ID
		 END
		) AS EMPLOYEE_ID,
		( CASE
			WHEN ATTENDANCE.EMPLOYEE_ID IS NOT NULL THEN
				ATTENDANCE.EMPLOYEE_NAME
			ELSE
				LEAVE.EMPLOYEE_NAME
		 END
		) AS EMPLOYEE_NAME,
		( CASE
			WHEN ATTENDANCE.EMPLOYEE_ID IS NOT NULL THEN
				ATTENDANCE.DEPARTMENT_ID
			ELSE
				LEAVE.LE_DEPT_ID
		 END
		) AS DEPARTMENT_ID,
		TO_CHAR(ATTENDANCE.TOTAL, 'HH24:MI') AS TOTAL,
		TO_CHAR(ATTENDANCE.OVERTIME, 'HH24:MI') AS OVERTIME,
		CAST(ATTENDANCE.OT_TAKEN_TIME AS INTEGER),
		TO_CHAR(ATTENDANCE.LATE, 'HH24:MI') AS LATE,
		CAST(ATTENDANCE.LATE_TAKEN_TIME AS INTEGER),
		TO_CHAR(ATTENDANCE.EARLY_OUT, 'HH24:MI') AS EARLY_OUT,
		CAST(ATTENDANCE.OUT_TAKEN_TIME AS INTEGER),
		TO_CHAR(ATTENDANCE.ABSENCE, 'HH24:MI') AS ABSENCE,
		CAST(ATTENDANCE.ABSENCE_TAKEN_TIME AS INTEGER),
		LEAVE.LEAVE_TYPE_ID,
		LEAVE.DURATION
	FROM (
		SELECT
			ATT.EMPLOYEE_ID,
			EMP.EMPLOYEE_NAME,
			EMP.DEPARTMENT_ID,
			SUM(ATT.TOTAL) AS TOTAL,
			SUM(ATT.OVERTIME) AS OVERTIME,
			(	SELECT 
					COUNT(ATT2.OVERTIME)
				FROM
					ATTENDANCE ATT2
				WHERE
					CAST(EXTRACT(YEAR FROM ATT2.ATTENDANCE_DATE)AS integer) = createdyear
					AND CAST(EXTRACT(MONTH FROM ATT2.ATTENDANCE_DATE)AS integer) = createdmonth
					AND ATT2.APPROVAL_STS = 2
					AND ATT2.OVERTIME IS NOT NULL
					AND ATT2.EMPLOYEE_ID = ATT.EMPLOYEE_ID
			) AS OT_TAKEN_TIME,
			SUM(ATT.LATE) AS LATE,
			(	SELECT
					COUNT(ATT2.LATE)
				FROM
					ATTENDANCE ATT2
				WHERE
					CAST(EXTRACT(YEAR FROM ATT2.ATTENDANCE_DATE)AS integer) = createdyear
					AND CAST(EXTRACT(MONTH FROM ATT2.ATTENDANCE_DATE)AS integer) = createdmonth
					AND ATT2.APPROVAL_STS = 2
					AND ATT2.LATE IS NOT NULL
					AND ATT2.EMPLOYEE_ID = ATT.EMPLOYEE_ID
			) AS LATE_TAKEN_TIME,
			SUM(ATT.EARLY_OUT) AS EARLY_OUT,
			(	SELECT
					COUNT(ATT2.EARLY_OUT)
				FROM
					ATTENDANCE ATT2
				WHERE
					CAST(EXTRACT(YEAR FROM ATT2.ATTENDANCE_DATE)AS integer) = createdyear
					AND CAST(EXTRACT(MONTH FROM ATT2.ATTENDANCE_DATE)AS integer) = createdmonth
					AND ATT2.APPROVAL_STS = 2
					AND ATT2.EARLY_OUT IS NOT NULL
					AND ATT2.EMPLOYEE_ID = ATT.EMPLOYEE_ID
			) AS OUT_TAKEN_TIME,
			SUM(ATT.ABSENCE) AS ABSENCE,
			(	SELECT 
					COUNT(ATT2.ABSENCE)
				FROM
					ATTENDANCE ATT2
				WHERE
					CAST(EXTRACT(YEAR FROM ATT2.ATTENDANCE_DATE)AS integer) = createdyear
					AND CAST(EXTRACT(MONTH FROM ATT2.ATTENDANCE_DATE)AS integer) = createdmonth
					AND ATT2.APPROVAL_STS = 2
					AND ATT2.EMPLOYEE_ID = ATT.EMPLOYEE_ID
				AND ATT2.ABSENCE IS NOT NULL
			) AS ABSENCE_TAKEN_TIME
		FROM
			ATTENDANCE ATT INNER JOIN UNNEST(employeeid) EM(ID) ON 
				EM.ID = ATT.EMPLOYEE_ID
			INNER JOIN SHIFT_POLICY SHIFT ON
				SHIFT.SHIFT_ID = ATT.SHIFT_ID
			INNER JOIN EMPLOYEE EMP ON 
				ATT.EMPLOYEE_ID = EMP.EMPLOYEE_ID			
		WHERE
			CAST(EXTRACT(YEAR FROM ATT.ATTENDANCE_DATE)AS integer) = createdyear
			AND CAST(EXTRACT(MONTH FROM ATT.ATTENDANCE_DATE)AS integer) = createdmonth
			AND ATT.APPROVAL_STS = 2
		GROUP BY
			ATT.EMPLOYEE_ID,
			EMP.EMPLOYEE_ID
		ORDER BY
			ATT.EMPLOYEE_ID
	) AS ATTENDANCE FULL OUTER JOIN
	(
			SELECT
				YTAKEN.EMPLOYEE_ID AS LE_EMP_ID,
				EMP.EMPLOYEE_NAME,
				EMP.DEPARTMENT_ID AS LE_DEPT_ID,
				YTAKEN.LEAVE_TYPE_ID,
				YTAKEN.DURATION
			FROM
				taken_month(createdyear, createdmonth, employeeid) AS YTAKEN INNER JOIN EMPLOYEE EMP ON
					YTAKEN.EMPLOYEE_ID = EMP.EMPLOYEE_ID
	) AS LEAVE ON
		ATTENDANCE.EMPLOYEE_ID = LEAVE.LE_EMP_ID;
END;
$$;


ALTER FUNCTION public.attendance_month(createdyear integer, createdmonth integer, employeeid integer[]) OWNER TO postgres;

--
-- TOC entry 238 (class 1255 OID 79514)
-- Name: attendance_year(integer, integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION attendance_year(createdyear integer, employeeid integer[]) RETURNS TABLE(employee_id integer, employee_name character varying, department_id integer, total text, overtime text, ot_taken_time integer, late text, late_taken_time integer, early_out text, out_taken_time integer, absence text, absence_taken_time integer, leave_type_id integer, duration numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
	SELECT
		( CASE
			WHEN ATTENDANCE.EMPLOYEE_ID IS NOT NULL THEN
				ATTENDANCE.EMPLOYEE_ID
			ELSE
				LEAVE.LE_EMP_ID
		 END
		) AS EMPLOYEE_ID,
		( CASE
			WHEN ATTENDANCE.EMPLOYEE_ID IS NOT NULL THEN
				ATTENDANCE.EMPLOYEE_NAME
			ELSE
				LEAVE.EMPLOYEE_NAME
		 END
		) AS EMPLOYEE_NAME,
		( CASE
			WHEN ATTENDANCE.EMPLOYEE_ID IS NOT NULL THEN
				ATTENDANCE.DEPARTMENT_ID
			ELSE
				LEAVE.LE_DEPT_ID
		 END
		) AS DEPARTMENT_ID,
		TO_CHAR(ATTENDANCE.TOTAL, 'HH24:MI') AS TOTAL,
		TO_CHAR(ATTENDANCE.OVERTIME, 'HH24:MI') AS OVERTIME,
		CAST(ATTENDANCE.OT_TAKEN_TIME AS INTEGER),
		TO_CHAR(ATTENDANCE.LATE, 'HH24:MI') AS LATE,
		CAST(ATTENDANCE.LATE_TAKEN_TIME AS INTEGER),
		TO_CHAR(ATTENDANCE.EARLY_OUT, 'HH24:MI') AS EARLY_OUT,
		CAST(ATTENDANCE.OUT_TAKEN_TIME AS INTEGER),
		TO_CHAR(ATTENDANCE.ABSENCE, 'HH24:MI') AS ABSENCE,
		CAST(ATTENDANCE.ABSENCE_TAKEN_TIME AS INTEGER),
		LEAVE.LEAVE_TYPE_ID,
		LEAVE.DURATION
	FROM (
		SELECT
			ATT.EMPLOYEE_ID,
			EMP.EMPLOYEE_NAME,
			EMP.DEPARTMENT_ID,
			SUM(ATT.TOTAL) AS TOTAL,
			SUM(ATT.OVERTIME) AS OVERTIME,
			(	SELECT 
					COUNT(ATT2.OVERTIME)
				FROM
					ATTENDANCE ATT2
				WHERE
					CAST(EXTRACT(YEAR FROM ATT2.ATTENDANCE_DATE)AS integer) = createdyear
					AND ATT2.APPROVAL_STS = 2
					AND ATT2.OVERTIME IS NOT NULL
					AND ATT2.EMPLOYEE_ID = ATT.EMPLOYEE_ID
			) AS OT_TAKEN_TIME,
			SUM(ATT.LATE) AS LATE,
			(	SELECT
					COUNT(ATT2.LATE)
				FROM
					ATTENDANCE ATT2
				WHERE
					CAST(EXTRACT(YEAR FROM ATT2.ATTENDANCE_DATE)AS integer) = createdyear
					AND ATT2.APPROVAL_STS = 2
					AND ATT2.LATE IS NOT NULL
					AND ATT2.EMPLOYEE_ID = ATT.EMPLOYEE_ID
			) AS LATE_TAKEN_TIME,
			SUM(ATT.EARLY_OUT) AS EARLY_OUT,
			(	SELECT
					COUNT(ATT2.EARLY_OUT)
				FROM
					ATTENDANCE ATT2
				WHERE
					CAST(EXTRACT(YEAR FROM ATT2.ATTENDANCE_DATE)AS integer) = createdyear
					AND ATT2.APPROVAL_STS = 2
					AND ATT2.EARLY_OUT IS NOT NULL
					AND ATT2.EMPLOYEE_ID = ATT.EMPLOYEE_ID
			) AS OUT_TAKEN_TIME,
			SUM(ATT.ABSENCE) AS ABSENCE,
			(	SELECT 
					COUNT(ATT2.ABSENCE)
				FROM
					ATTENDANCE ATT2
				WHERE
					CAST(EXTRACT(YEAR FROM ATT2.ATTENDANCE_DATE)AS integer) = createdyear
					AND ATT2.APPROVAL_STS = 2
					AND ATT2.EMPLOYEE_ID = ATT.EMPLOYEE_ID
				AND ATT2.ABSENCE IS NOT NULL
			) AS ABSENCE_TAKEN_TIME
		FROM
			ATTENDANCE ATT INNER JOIN UNNEST(employeeid) EM(ID) ON 
				EM.ID = ATT.EMPLOYEE_ID
			INNER JOIN SHIFT_POLICY SHIFT ON
				SHIFT.SHIFT_ID = ATT.SHIFT_ID
			INNER JOIN EMPLOYEE EMP ON 
				ATT.EMPLOYEE_ID = EMP.EMPLOYEE_ID			
		WHERE
			CAST(EXTRACT(YEAR FROM ATT.ATTENDANCE_DATE)AS integer) = createdyear
			AND ATT.APPROVAL_STS = 2
		GROUP BY
			ATT.EMPLOYEE_ID,
			EMP.EMPLOYEE_ID
		ORDER BY
			ATT.EMPLOYEE_ID
	) AS ATTENDANCE FULL OUTER JOIN
	(
			SELECT
				YTAKEN.EMPLOYEE_ID AS LE_EMP_ID,
				EMP.EMPLOYEE_NAME,
				EMP.DEPARTMENT_ID AS LE_DEPT_ID,
				YTAKEN.LEAVE_TYPE_ID,
				YTAKEN.DURATION
			FROM(
				SELECT 
					YY.EMPLOYEE_ID,
					YY.LEAVE_TYPE_ID,
					SUM(YY.DURATION) AS DURATION
				FROM
					taken_year(createdyear, employeeid) AS YY
				GROUP BY
					YY.EMPLOYEE_ID,
					YY.LEAVE_TYPE_ID
				ORDER BY
					YY.EMPLOYEE_ID,
					YY.LEAVE_TYPE_ID
			) AS YTAKEN INNER JOIN EMPLOYEE EMP ON
					YTAKEN.EMPLOYEE_ID = EMP.EMPLOYEE_ID
	) AS LEAVE ON
		ATTENDANCE.EMPLOYEE_ID = LEAVE.LE_EMP_ID;
END;
$$;


ALTER FUNCTION public.attendance_year(createdyear integer, employeeid integer[]) OWNER TO postgres;

--
-- TOC entry 239 (class 1255 OID 79515)
-- Name: getbymonth(integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION getbymonth(createdyear integer, createdmonth integer, emp_id integer[]) RETURNS TABLE(employee_id integer, leave_type_id integer, start_date date, end_date date, is_am boolean, is_pm boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
	CREATE TEMP TABLE year_table AS
		SELECT * FROM taken_year(createdyear, emp_id);
    RETURN QUERY
	(SELECT
		LT.EMPLOYEE_ID,
		LT.LEAVE_TYPE_ID,
		DATE_TRUNC('MONTH', LT.END_DATE)::DATE AS START_DATE,
		LT.END_DATE,
		LT.IS_AM,
		LT.IS_PM
	FROM
		year_table LT
	WHERE
		CAST(EXTRACT(MONTH FROM LT.END_DATE) AS integer) = createdmonth
		AND CAST(EXTRACT(MONTH FROM LT.START_DATE) AS integer) < createdmonth
	GROUP BY
		LT.EMPLOYEE_ID,
		LT.LEAVE_TYPE_ID,
		LT.END_DATE,
		LT.IS_AM,
		LT.IS_PM)
	UNION
	(SELECT
		EQ.EMPLOYEE_ID,
		EQ.LEAVE_TYPE_ID,
		EQ.START_DATE,
		EQ.END_DATE,
		EQ.IS_AM,
		EQ.IS_PM
	FROM
		year_table EQ
	WHERE
		CAST(EXTRACT(MONTH FROM EQ.START_DATE) AS integer) = createdmonth
		AND CAST(EXTRACT(MONTH FROM EQ.END_DATE) AS integer) = createdmonth
	GROUP BY
		EQ.EMPLOYEE_ID,
		EQ.LEAVE_TYPE_ID,
		EQ.START_DATE,
		EQ.END_DATE,
		EQ.IS_AM,
		EQ.IS_PM)
	UNION
	(SELECT
		GT.EMPLOYEE_ID,
		GT.LEAVE_TYPE_ID,
		GT.START_DATE,
		(DATE_TRUNC('MONTH', GT.START_DATE) + INTERVAL '1 MONTH - 1 DAY')::DATE AS END_DATE,
		GT.IS_AM,
		GT.IS_PM
	FROM
		year_table GT
	WHERE
		CAST(EXTRACT(MONTH FROM GT.START_DATE) AS integer) = createdmonth
		AND CAST(EXTRACT(MONTH FROM GT.END_DATE) AS integer) > createdmonth
	GROUP BY
		GT.EMPLOYEE_ID,
		GT.LEAVE_TYPE_ID,
		GT.START_DATE,
		GT.IS_AM,
		GT.IS_PM)
	UNION
	(SELECT
		BT.EMPLOYEE_ID,
		BT.LEAVE_TYPE_ID,
		DATE_TRUNC('MONTH', TO_DATE(createdyear||'-'||createdmonth,'YYYY-MM'))::DATE AS START_DATE,
		(DATE_TRUNC('MONTH', TO_DATE(createdyear||'-'||createdmonth,'YYYY-MM')) + INTERVAL '1 MONTH - 1 DAY')::DATE AS END_DATE,
		BT.IS_AM,
		BT.IS_PM
	FROM
		year_table BT
	WHERE
		CAST(EXTRACT(MONTH FROM BT.START_DATE) AS integer) < createdmonth
		AND CAST(EXTRACT(MONTH FROM BT.END_DATE) AS integer) > createdmonth
	GROUP BY
		BT.EMPLOYEE_ID,
		BT.LEAVE_TYPE_ID,
		BT.IS_AM,
		BT.IS_PM); 
	DROP TABLE IF EXISTS year_table;
END;
$$;


ALTER FUNCTION public.getbymonth(createdyear integer, createdmonth integer, emp_id integer[]) OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 79516)
-- Name: is_am(integer, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION is_am(emp_id integer, start_date date, end_date date) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
half numeric;
begin
	SELECT INTO half
		(CASE 	WHEN AM.BREAK_OUT <= AM.DUTY_IN THEN
					0.5
				END
		) AS HALF
	FROM(
		SELECT
		(CASE	WHEN S.BREAK_OUT < S.DUTY_END AND S.DUTY_END < S.DUTY_START THEN
				S.BREAK_OUT::interval + '24 hour'::interval
			ELSE
				S.BREAK_OUT::interval
			END
		) AS BREAK_OUT,
		(CASE	WHEN ATT.DUTY_IN::interval < S.DUTY_END AND S.DUTY_END < S.DUTY_START THEN
				ATT.DUTY_IN::interval + '24 hour'::interval
			ELSE
				ATT.DUTY_IN::interval
			END
		) AS DUTY_IN
	FROM
		ATTENDANCE ATT INNER JOIN SHIFT_POLICY S ON		
			S.SHIFT_ID = ATT.SHIFT_ID
	WHERE
		ATT.ATTENDANCE_DATE BETWEEN start_date
		AND end_date
		AND ATT.ABSENCE IS NULL
		AND ATT.EMPLOYEE_ID = emp_id
	)AM;

 if(half = 0.5)then
	return half;
 else
	half:=0;
 end if;
 return half;
end;
$$;


ALTER FUNCTION public.is_am(emp_id integer, start_date date, end_date date) OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 79517)
-- Name: is_pm(integer, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION is_pm(emp_id integer, start_date date, end_date date) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
half numeric;
begin
	SELECT INTO half
		(CASE 	WHEN PM.BREAK_IN >= PM.DUTY_OUT THEN
					0.5
				END
		) AS HALF
	FROM(
	SELECT
		(CASE	WHEN S.BREAK_IN < S.DUTY_END AND S.DUTY_END < S.DUTY_START THEN
				S.BREAK_IN::interval + '24 hour'::interval
			ELSE
				S.BREAK_IN::interval
			END
		) AS BREAK_IN,
		(CASE	WHEN ATT.DUTY_OUT < S.DUTY_END AND S.DUTY_END < S.DUTY_START THEN
				ATT.DUTY_OUT::interval + '24 hour'::interval
			ELSE
				ATT.DUTY_OUT::interval
			END
		) AS DUTY_OUT
	FROM
		ATTENDANCE ATT INNER JOIN SHIFT_POLICY S ON		
			S.SHIFT_ID = ATT.SHIFT_ID
	WHERE
		ATT.ATTENDANCE_DATE BETWEEN start_date
		AND end_date
		AND ATT.ABSENCE IS NULL
		AND ATT.EMPLOYEE_ID = emp_id
	)PM;

 if(half = 0.5)then
	return half;
 else
	half:=0;
 end if;
 return half;
end;
$$;


ALTER FUNCTION public.is_pm(emp_id integer, start_date date, end_date date) OWNER TO postgres;

--
-- TOC entry 242 (class 1255 OID 79518)
-- Name: taken_daily(integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION taken_daily(createdyear integer, createdmonth integer, employeeid integer[]) RETURNS TABLE(employee_id integer, employee_name character varying, department_name character varying, leave_date date, leave_name character varying, duration text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
	SELECT
		DTAKEN.EMPLOYEE_ID,
		EMP.EMPLOYEE_NAME,
		DEPT.DEPARTMENT_NAME,
		DTAKEN.LEAVE_DATE,
		LTYPE.NAME AS LEAVE_NAME,
		(CASE	
			WHEN DTAKEN.TAKENDAY = '0-AM' OR DTAKEN.TAKENDAY = '0-PM' THEN
				'1'
			ELSE
				DTAKEN.TAKENDAY
		END
		) AS DURATION
	FROM(
		SELECT
			MTAKEN.EMPLOYEE_ID,
			MTAKEN.LEAVE_TYPE_ID,
			MTAKEN.LEAVE_DATE,
			(CASE	
				WHEN MTAKEN.IS_AM = TRUE THEN
					is_am(MTAKEN.EMPLOYEE_ID, MTAKEN.LEAVE_DATE, MTAKEN.LEAVE_DATE)||'-AM'
				WHEN MTAKEN.IS_PM = TRUE THEN
					is_pm(MTAKEN.EMPLOYEE_ID, MTAKEN.LEAVE_DATE, MTAKEN.LEAVE_DATE)||'-PM'
				ELSE '1'
			END
			) AS TAKENDAY
		FROM(
			SELECT
				MM.EMPLOYEE_ID, 
				MM.LEAVE_TYPE_ID,
				GENERATE_SERIES(MM.START_DATE,MM.END_DATE, '1 DAY'::INTERVAL)::DATE AS LEAVE_DATE,
				MM.IS_AM, 
				MM.IS_PM
			FROM
				getbymonth(createdyear, createdmonth, employeeid) AS MM
		) MTAKEN
	) DTAKEN
		INNER JOIN EMPLOYEE EMP ON
			DTAKEN.EMPLOYEE_ID = EMP.EMPLOYEE_ID
		INNER JOIN DEPARTMENT DEPT ON 
			DEPT.DEPARTMENT_ID = EMP.DEPARTMENT_ID
		INNER JOIN LEAVE_TYPE LTYPE ON
			LTYPE.LEAVE_TYPE_ID = DTAKEN.LEAVE_TYPE_ID;
END;
$$;


ALTER FUNCTION public.taken_daily(createdyear integer, createdmonth integer, employeeid integer[]) OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 79519)
-- Name: taken_month(integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION taken_month(createdyear integer, createdmonth integer, emp_id integer[]) RETURNS TABLE(employee_id integer, leave_type_id integer, duration numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
	SELECT
		MT.EMPLOYEE_ID,
		MT.LEAVE_TYPE_ID,
		SUM(
		(MT.END_DATE - MT.START_DATE + 1) - (
			CASE WHEN MT.IS_AM = TRUE THEN
					is_am(MT.EMPLOYEE_ID, MT.START_DATE, MT.END_DATE)
				 WHEN MT.IS_PM = TRUE THEN
					is_pm(MT.EMPLOYEE_ID, MT.START_DATE, MT.END_DATE)
				 ELSE 0
			END
		)) AS DURATION
	FROM 
		getbymonth(createdyear, createdmonth, emp_id) AS MT
	GROUP BY
		MT.EMPLOYEE_ID,
		MT.LEAVE_TYPE_ID
	ORDER BY
		MT.EMPLOYEE_ID,
		MT.LEAVE_TYPE_ID; 
END;
$$;


ALTER FUNCTION public.taken_month(createdyear integer, createdmonth integer, emp_id integer[]) OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 79520)
-- Name: taken_monthbalance(integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION taken_monthbalance(createdyear integer, createdmonth integer, employeeid integer[]) RETURNS TABLE(employee_id integer, leave_type_id integer, duration numeric, taken_balance numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
	CREATE TEMP TABLE year_baltable AS
		SELECT * FROM taken_year(createdyear, employeeid);
    RETURN QUERY
	SELECT
	(CASE	WHEN TAK.EMPLOYEE_ID IS NOT NULL THEN
				TAK.EMPLOYEE_ID
			ELSE
				TAKEN_BAL.EMPLOYEE_ID
	END
	) AS EMPLOYEE_ID,
	(CASE	WHEN TAK.LEAVE_TYPE_ID IS NOT NULL THEN
				TAK.LEAVE_TYPE_ID
			ELSE
				TAKEN_BAL.LEAVE_TYPE_ID
	END
	)AS LEAVE_TYPE_ID,
	TAK.DURATION,
	TAKEN_BAL.TAKEN_BALANCE
FROM
	taken_month(createdyear, createdmonth, employeeid) AS TAK FULL OUTER JOIN 
	(
		SELECT
			BAL.EMPLOYEE_ID,
			BAL.LEAVE_TYPE_ID,
			SUM(BAL.DURATION) AS TAKEN_BALANCE
		FROM(
			(SELECT
				LTAKEN.EMPLOYEE_ID,
				LTAKEN.LEAVE_TYPE_ID,
				LTAKEN.START_DATE,
				LTAKEN.END_DATE,
				LTAKEN.DURATION
			FROM
				year_baltable LTAKEN
			WHERE
				CAST(EXTRACT(MONTH FROM LTAKEN.END_DATE)AS bigInt) <= createdmonth
				AND CAST(EXTRACT(MONTH FROM LTAKEN.START_DATE)AS bigInt) <= createdmonth
			GROUP BY
				LTAKEN.EMPLOYEE_ID,
				LTAKEN.LEAVE_TYPE_ID,
				LTAKEN.START_DATE,
				LTAKEN.END_DATE,
				LTAKEN.DURATION)
			UNION
			(SELECT
				GT.EMPLOYEE_ID,
				GT.LEAVE_TYPE_ID,
				GT.START_DATE,
				GT.END_DATE,
				(GT.END_DATE - GT.START_DATE + 1) - (
					CASE WHEN GT.IS_AM = TRUE THEN
							is_am(GT.EMPLOYEE_ID, GT.START_DATE, GT.END_DATE)
						 WHEN GT.IS_PM = TRUE THEN
							is_pm(GT.EMPLOYEE_ID, GT.START_DATE, GT.END_DATE)
						 ELSE 0
					END
				) AS DURATION
			FROM (
				SELECT
					LTAKEN.EMPLOYEE_ID,
					LTAKEN.LEAVE_TYPE_ID,
					LTAKEN.START_DATE,
					(DATE_TRUNC('MONTH',TO_DATE(createdyear||'-'||createdmonth,'YYYY-MM'))+INTERVAL '1 MONTH - 1 DAY')::DATE AS END_DATE,
					LTAKEN.IS_AM,
					LTAKEN.IS_PM
				FROM
					year_baltable LTAKEN
				WHERE
					CAST(EXTRACT(MONTH FROM LTAKEN.START_DATE)AS bigInt) <= createdmonth
					AND CAST(EXTRACT(MONTH FROM LTAKEN.END_DATE)AS bigInt) > createdmonth
				GROUP BY
					LTAKEN.EMPLOYEE_ID,
					LTAKEN.LEAVE_TYPE_ID,
					LTAKEN.START_DATE,
					LTAKEN.IS_AM,
					LTAKEN.IS_PM
			)GT		
			)
		) BAL
		GROUP BY
			BAL.EMPLOYEE_ID,
			BAL.LEAVE_TYPE_ID
		ORDER BY
			BAL.EMPLOYEE_ID,
			BAL.LEAVE_TYPE_ID
	) TAKEN_BAL ON	
	TAK.EMPLOYEE_ID = TAKEN_BAL.EMPLOYEE_ID
	AND TAKEN_BAL.LEAVE_TYPE_ID = TAK.LEAVE_TYPE_ID;
	DROP TABLE IF EXISTS year_baltable;
END;
$$;


ALTER FUNCTION public.taken_monthbalance(createdyear integer, createdmonth integer, employeeid integer[]) OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 79521)
-- Name: taken_year(integer, integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION taken_year(createdyear integer, emp_id integer[]) RETURNS TABLE(employee_id integer, leave_type_id integer, start_date date, end_date date, duration numeric, is_am boolean, is_pm boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    (SELECT
		LY.EMPLOYEE_ID,
		LY.LEAVE_TYPE_ID,
		LY.START_DATE,
		LY.END_DATE,
		LY.DURATION - (
			CASE WHEN LY.IS_AM = TRUE THEN
					is_am(LY.EMPLOYEE_ID, LY.START_DATE, LY.END_DATE)
				 WHEN LY.IS_PM = TRUE THEN
					is_pm(LY.EMPLOYEE_ID, LY.START_DATE, LY.END_DATE)
				 ELSE 0
			END
		) AS DURATION,
		LY.IS_AM, 
		LY.IS_PM
	FROM (
		(SELECT
			LT.EMPLOYEE_ID,
			LT.LEAVE_TYPE_ID,
			DATE_TRUNC('YEAR',LT.END_DATE)::DATE AS START_DATE,
			LT.END_DATE,
			LT.END_DATE - DATE_TRUNC('YEAR',LT.END_DATE)::DATE + 1 AS DURATION,
			LT.IS_AM, 
			LT.IS_PM
		FROM
			LEAVE_TAKEN LT INNER JOIN 
			UNNEST(emp_id) EM(ID) ON 
				EM.ID = LT.EMPLOYEE_ID
		WHERE
			CAST(EXTRACT(YEAR FROM LT.START_DATE) AS integer) = createdyear - 1
			AND CAST(EXTRACT(YEAR FROM LT.END_DATE) AS integer) = createdyear
			AND LT.LEAVE_STATUS = 2
		GROUP BY
			LT.EMPLOYEE_ID,
			LT.LEAVE_TYPE_ID,
			LT.END_DATE,
			LT.IS_AM,
			LT.IS_PM)
		UNION
		(SELECT
			GT.EMPLOYEE_ID,
			GT.LEAVE_TYPE_ID,
			GT.START_DATE,
			(DATE_TRUNC('YEAR',GT.START_DATE)+INTERVAL '1 YEAR - 1 DAY')::DATE AS END_DATE,
			(DATE_TRUNC('YEAR',GT.START_DATE)+INTERVAL '1 YEAR - 1 DAY')::DATE - GT.START_DATE + 1 AS DURATION,
			GT.IS_AM, 
			GT.IS_PM
		FROM
			LEAVE_TAKEN GT INNER JOIN 
			UNNEST(emp_id) EM(ID) ON 
				EM.ID = GT.EMPLOYEE_ID
		WHERE
			CAST(EXTRACT(YEAR FROM GT.START_DATE) AS integer) = createdyear
			AND CAST(EXTRACT(YEAR FROM GT.END_DATE) AS integer) = createdyear + 1
			AND GT.LEAVE_STATUS = 2					
		GROUP BY
			GT.EMPLOYEE_ID,
			GT.LEAVE_TYPE_ID,
			GT.START_DATE,
			GT.END_DATE,
			GT.IS_AM,
			GT.IS_PM)
	) LY)
	UNION
	(SELECT
		EQ.EMPLOYEE_ID,
		EQ.LEAVE_TYPE_ID,
		EQ.START_DATE,
		EQ.END_DATE,
		EQ.DURATION,
		EQ.IS_AM, 
		EQ.IS_PM
	FROM
		LEAVE_TAKEN EQ INNER JOIN 
		UNNEST(emp_id) EM(ID) ON 
			EM.ID = EQ.EMPLOYEE_ID
	WHERE
		CAST(EXTRACT(YEAR FROM EQ.START_DATE) AS integer) = createdyear
			AND CAST(EXTRACT(YEAR FROM EQ.END_DATE) AS integer) = createdyear
			AND EQ.LEAVE_STATUS = 2
		GROUP BY
			EQ.EMPLOYEE_ID,
			EQ.LEAVE_TYPE_ID,
			EQ.START_DATE,
			EQ.END_DATE,
			EQ.DURATION,
			EQ.IS_AM,
			EQ.IS_PM);
END;
$$;


ALTER FUNCTION public.taken_year(createdyear integer, emp_id integer[]) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 170 (class 1259 OID 79522)
-- Name: academic_background; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE academic_background (
    academic_id integer NOT NULL,
    employee_id integer NOT NULL,
    degree character varying(100) NOT NULL,
    organization character varying(100) NOT NULL,
    graduate_date date NOT NULL,
    location character varying(50),
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.academic_background OWNER TO postgres;

--
-- TOC entry 2316 (class 0 OID 0)
-- Dependencies: 170
-- Name: COLUMN academic_background.location; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN academic_background.location IS 'Country and City';


--
-- TOC entry 171 (class 1259 OID 79525)
-- Name: academic_background_academic_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE academic_background_academic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999
    CACHE 1;


ALTER TABLE public.academic_background_academic_id_seq OWNER TO postgres;

--
-- TOC entry 2317 (class 0 OID 0)
-- Dependencies: 171
-- Name: academic_background_academic_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE academic_background_academic_id_seq OWNED BY academic_background.academic_id;


--
-- TOC entry 172 (class 1259 OID 79527)
-- Name: address; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE address (
    address_id integer NOT NULL,
    township_id integer NOT NULL,
    city_id integer NOT NULL,
    prefecture_id integer NOT NULL,
    district_id integer NOT NULL,
    address character varying(100) NOT NULL,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.address OWNER TO postgres;

--
-- TOC entry 173 (class 1259 OID 79530)
-- Name: address_address_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE address_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999
    CACHE 1;


ALTER TABLE public.address_address_id_seq OWNER TO postgres;

--
-- TOC entry 2318 (class 0 OID 0)
-- Dependencies: 173
-- Name: address_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE address_address_id_seq OWNED BY address.address_id;


--
-- TOC entry 174 (class 1259 OID 79532)
-- Name: approval_matrix; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE approval_matrix (
    approval_id integer NOT NULL,
    applicant_id integer NOT NULL,
    approver_id integer NOT NULL,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.approval_matrix OWNER TO postgres;

--
-- TOC entry 175 (class 1259 OID 79535)
-- Name: approval_matrix_approval_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE approval_matrix_approval_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999
    CACHE 1;


ALTER TABLE public.approval_matrix_approval_id_seq OWNER TO postgres;

--
-- TOC entry 2319 (class 0 OID 0)
-- Dependencies: 175
-- Name: approval_matrix_approval_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE approval_matrix_approval_id_seq OWNED BY approval_matrix.approval_id;


--
-- TOC entry 223 (class 1259 OID 80022)
-- Name: attendance; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE attendance (
    attendance_id integer NOT NULL,
    employee_id integer NOT NULL,
    shift_id integer NOT NULL,
    attendance_date date NOT NULL,
    category integer NOT NULL,
    type integer NOT NULL,
    duty_in time without time zone NOT NULL,
    duty_out time without time zone,
    total time without time zone,
    break_out time without time zone,
    break_in time without time zone,
    overtime time without time zone,
    late time without time zone,
    early_out time without time zone,
    absence time without time zone,
    approval_sts integer DEFAULT 0 NOT NULL,
    comment character varying(50),
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone,
    early_in time without time zone,
    latest_out time without time zone
);


ALTER TABLE public.attendance OWNER TO postgres;

--
-- TOC entry 2320 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE attendance; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE attendance IS 'attendance';


--
-- TOC entry 2321 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.attendance_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.attendance_id IS 'attendance id';


--
-- TOC entry 2322 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.employee_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.employee_id IS 'employee id';


--
-- TOC entry 2323 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.shift_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.shift_id IS 'work shift id';


--
-- TOC entry 2324 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.attendance_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.attendance_date IS 'attendance date';


--
-- TOC entry 2325 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.category; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.category IS '0:Week Day, 1: Holiday';


--
-- TOC entry 2326 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.type IS '0: Attendance 
     1: Absence
     2: Salary
     3: Holiday
etc….';


--
-- TOC entry 2327 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.duty_in; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.duty_in IS 'duty in time';


--
-- TOC entry 2328 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.duty_out; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.duty_out IS 'duty out time';


--
-- TOC entry 2329 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.total; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.total IS 'total time';


--
-- TOC entry 2330 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.break_out; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.break_out IS 'break time out';


--
-- TOC entry 2331 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.break_in; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.break_in IS 'break time in';


--
-- TOC entry 2332 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.overtime; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.overtime IS 'overtime';


--
-- TOC entry 2333 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.late; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.late IS 'lateness hour';


--
-- TOC entry 2334 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.early_out; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.early_out IS 'early out time';


--
-- TOC entry 2335 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.absence; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.absence IS 'absence hour';


--
-- TOC entry 2336 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.approval_sts; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.approval_sts IS '0 - initial status
1 - requested
2 - approved
3 - cancel';


--
-- TOC entry 2337 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.early_in; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.early_in IS 'early in hour';


--
-- TOC entry 2338 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN attendance.latest_out; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN attendance.latest_out IS 'lateness out hour';


--
-- TOC entry 222 (class 1259 OID 80020)
-- Name: attendance_attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE attendance_attendance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attendance_attendance_id_seq OWNER TO postgres;

--
-- TOC entry 2339 (class 0 OID 0)
-- Dependencies: 222
-- Name: attendance_attendance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE attendance_attendance_id_seq OWNED BY attendance.attendance_id;


--
-- TOC entry 176 (class 1259 OID 79543)
-- Name: bank; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bank (
    bank_id integer NOT NULL,
    bank_cd character varying(8) NOT NULL,
    bank_name character varying(100) NOT NULL,
    delete_flg boolean DEFAULT false,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.bank OWNER TO postgres;

--
-- TOC entry 177 (class 1259 OID 79547)
-- Name: bank_bank_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE bank_bank_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;


ALTER TABLE public.bank_bank_id_seq OWNER TO postgres;

--
-- TOC entry 2340 (class 0 OID 0)
-- Dependencies: 177
-- Name: bank_bank_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE bank_bank_id_seq OWNED BY bank.bank_id;


--
-- TOC entry 178 (class 1259 OID 79549)
-- Name: bank_branch; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bank_branch (
    branch_id integer NOT NULL,
    branch_cd character varying(3) NOT NULL,
    bank_id integer NOT NULL,
    branch_name character varying(100) NOT NULL,
    delete_flg boolean DEFAULT false,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.bank_branch OWNER TO postgres;

--
-- TOC entry 179 (class 1259 OID 79553)
-- Name: bank_branch_branch_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE bank_branch_branch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;


ALTER TABLE public.bank_branch_branch_id_seq OWNER TO postgres;

--
-- TOC entry 2341 (class 0 OID 0)
-- Dependencies: 179
-- Name: bank_branch_branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE bank_branch_branch_id_seq OWNED BY bank_branch.branch_id;


--
-- TOC entry 180 (class 1259 OID 79555)
-- Name: city; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE city (
    city_id integer NOT NULL,
    prefecture_id integer NOT NULL,
    district_id integer NOT NULL,
    city_name character varying(30) NOT NULL,
    delete_flg boolean DEFAULT false,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.city OWNER TO postgres;

--
-- TOC entry 181 (class 1259 OID 79559)
-- Name: city_city_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE city_city_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;


ALTER TABLE public.city_city_id_seq OWNER TO postgres;

--
-- TOC entry 2342 (class 0 OID 0)
-- Dependencies: 181
-- Name: city_city_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE city_city_id_seq OWNED BY city.city_id;


--
-- TOC entry 182 (class 1259 OID 79561)
-- Name: company_profile; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE company_profile (
    name character varying(50) NOT NULL,
    description character varying(500),
    weekly_off_type integer,
    township_id integer NOT NULL,
    city_id integer NOT NULL,
    prefecture_id integer NOT NULL,
    district_id integer NOT NULL,
    address character varying(100) NOT NULL,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.company_profile OWNER TO postgres;

--
-- TOC entry 2343 (class 0 OID 0)
-- Dependencies: 182
-- Name: COLUMN company_profile.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN company_profile.name IS 'company name';


--
-- TOC entry 2344 (class 0 OID 0)
-- Dependencies: 182
-- Name: COLUMN company_profile.weekly_off_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN company_profile.weekly_off_type IS '0: Sat/Sun, 1: Custom';


--
-- TOC entry 183 (class 1259 OID 79567)
-- Name: contract; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE contract (
    contract_id integer NOT NULL,
    contract_type integer NOT NULL,
    start_date date NOT NULL,
    end_date date,
    description character varying(500),
    additional_info character varying(500),
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.contract OWNER TO postgres;

--
-- TOC entry 2345 (class 0 OID 0)
-- Dependencies: 183
-- Name: COLUMN contract.contract_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN contract.contract_type IS '1: probationary, 2: contractual, 3: permanent';


--
-- TOC entry 2346 (class 0 OID 0)
-- Dependencies: 183
-- Name: COLUMN contract.start_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN contract.start_date IS 'Contract starting date';


--
-- TOC entry 2347 (class 0 OID 0)
-- Dependencies: 183
-- Name: COLUMN contract.end_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN contract.end_date IS 'Contract finished date';


--
-- TOC entry 2348 (class 0 OID 0)
-- Dependencies: 183
-- Name: COLUMN contract.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN contract.description IS 'Contract Description';


--
-- TOC entry 184 (class 1259 OID 79573)
-- Name: contract_contract_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE contract_contract_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;


ALTER TABLE public.contract_contract_id_seq OWNER TO postgres;

--
-- TOC entry 2349 (class 0 OID 0)
-- Dependencies: 184
-- Name: contract_contract_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE contract_contract_id_seq OWNED BY contract.contract_id;


--
-- TOC entry 185 (class 1259 OID 79575)
-- Name: department; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE department (
    department_id integer NOT NULL,
    department_name character varying(30) NOT NULL,
    description character varying(100),
    delete_flg boolean DEFAULT false,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.department OWNER TO postgres;

--
-- TOC entry 2350 (class 0 OID 0)
-- Dependencies: 185
-- Name: TABLE department; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE department IS 'department';


--
-- TOC entry 2351 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN department.department_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN department.department_id IS 'department id';


--
-- TOC entry 2352 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN department.department_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN department.department_name IS 'department name';


--
-- TOC entry 2353 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN department.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN department.description IS 'description';


--
-- TOC entry 186 (class 1259 OID 79579)
-- Name: department_department_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE department_department_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99
    CACHE 1;


ALTER TABLE public.department_department_id_seq OWNER TO postgres;

--
-- TOC entry 2354 (class 0 OID 0)
-- Dependencies: 186
-- Name: department_department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE department_department_id_seq OWNED BY department.department_id;


--
-- TOC entry 187 (class 1259 OID 79581)
-- Name: district; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE district (
    district_id integer NOT NULL,
    district_name character varying(30) NOT NULL,
    delete_flg boolean DEFAULT false,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.district OWNER TO postgres;

--
-- TOC entry 188 (class 1259 OID 79585)
-- Name: district_district_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE district_district_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;


ALTER TABLE public.district_district_id_seq OWNER TO postgres;

--
-- TOC entry 2355 (class 0 OID 0)
-- Dependencies: 188
-- Name: district_district_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE district_district_id_seq OWNED BY district.district_id;


--
-- TOC entry 189 (class 1259 OID 79587)
-- Name: emergency_contact; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE emergency_contact (
    contact_id integer NOT NULL,
    employee_id integer NOT NULL,
    name character varying(30) NOT NULL,
    relationship character varying(20),
    email character varying(30),
    phone_no character varying(20),
    nrc_no character varying(20),
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.emergency_contact OWNER TO postgres;

--
-- TOC entry 2356 (class 0 OID 0)
-- Dependencies: 189
-- Name: TABLE emergency_contact; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE emergency_contact IS 'emergency contact information';


--
-- TOC entry 2357 (class 0 OID 0)
-- Dependencies: 189
-- Name: COLUMN emergency_contact.employee_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN emergency_contact.employee_id IS 'employee id';


--
-- TOC entry 2358 (class 0 OID 0)
-- Dependencies: 189
-- Name: COLUMN emergency_contact.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN emergency_contact.name IS 'emergency contact person''s name';


--
-- TOC entry 2359 (class 0 OID 0)
-- Dependencies: 189
-- Name: COLUMN emergency_contact.email; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN emergency_contact.email IS 'emergency contact person''s email';


--
-- TOC entry 2360 (class 0 OID 0)
-- Dependencies: 189
-- Name: COLUMN emergency_contact.phone_no; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN emergency_contact.phone_no IS 'phone number';


--
-- TOC entry 2361 (class 0 OID 0)
-- Dependencies: 189
-- Name: COLUMN emergency_contact.nrc_no; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN emergency_contact.nrc_no IS 'national register card/ passport number';


--
-- TOC entry 190 (class 1259 OID 79590)
-- Name: emergency_contact_contact_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE emergency_contact_contact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999
    CACHE 1;


ALTER TABLE public.emergency_contact_contact_id_seq OWNER TO postgres;

--
-- TOC entry 2362 (class 0 OID 0)
-- Dependencies: 190
-- Name: emergency_contact_contact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE emergency_contact_contact_id_seq OWNED BY emergency_contact.contact_id;


--
-- TOC entry 191 (class 1259 OID 79592)
-- Name: employee; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee (
    employee_id integer NOT NULL,
    employee_name character varying(30) NOT NULL,
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    station_id integer NOT NULL,
    department_id integer NOT NULL,
    category_id integer NOT NULL,
    position_id integer NOT NULL,
    job_email character varying(254),
    status integer DEFAULT 0 NOT NULL,
    gender character varying(6),
    birth_date date,
    marital_sts character varying(20),
    citizen character varying(30),
    nrc_no character varying(30) NOT NULL,
    join_date date NOT NULL,
    phone_no character varying(20),
    personal_email character varying(254),
    bank_id integer,
    branch_id integer,
    account_no character varying(35),
    account_type integer,
    contract_id integer,
    resign_id integer,
    address_id integer,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.employee OWNER TO postgres;

--
-- TOC entry 2363 (class 0 OID 0)
-- Dependencies: 191
-- Name: COLUMN employee.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN employee.status IS '0: active, 1: inactive, 2: resigned';


--
-- TOC entry 2364 (class 0 OID 0)
-- Dependencies: 191
-- Name: COLUMN employee.account_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN employee.account_type IS '0: saving, 1: checking, 2: others';


--
-- TOC entry 192 (class 1259 OID 79599)
-- Name: employee_category; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_category (
    category_id integer NOT NULL,
    category_name character varying(30) NOT NULL,
    description character varying(100),
    delete_flg boolean DEFAULT false,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.employee_category OWNER TO postgres;

--
-- TOC entry 193 (class 1259 OID 79603)
-- Name: employee_category_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_category_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999
    CACHE 1;


ALTER TABLE public.employee_category_category_id_seq OWNER TO postgres;

--
-- TOC entry 2365 (class 0 OID 0)
-- Dependencies: 193
-- Name: employee_category_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_category_category_id_seq OWNED BY employee_category.category_id;


--
-- TOC entry 194 (class 1259 OID 79605)
-- Name: employee_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_employee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;


ALTER TABLE public.employee_employee_id_seq OWNER TO postgres;

--
-- TOC entry 2366 (class 0 OID 0)
-- Dependencies: 194
-- Name: employee_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_employee_id_seq OWNED BY employee.employee_id;


--
-- TOC entry 195 (class 1259 OID 79607)
-- Name: holiday; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE holiday (
    holiday_id integer NOT NULL,
    holiday_date date NOT NULL,
    type integer NOT NULL,
    title character varying(30) NOT NULL,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.holiday OWNER TO postgres;

--
-- TOC entry 2367 (class 0 OID 0)
-- Dependencies: 195
-- Name: COLUMN holiday.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN holiday.type IS '0: Gazette, 1: Custom';


--
-- TOC entry 2368 (class 0 OID 0)
-- Dependencies: 195
-- Name: COLUMN holiday.title; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN holiday.title IS 'holiday title';


--
-- TOC entry 196 (class 1259 OID 79610)
-- Name: holiday_holiday_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE holiday_holiday_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999
    CACHE 1;


ALTER TABLE public.holiday_holiday_id_seq OWNER TO postgres;

--
-- TOC entry 2369 (class 0 OID 0)
-- Dependencies: 196
-- Name: holiday_holiday_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE holiday_holiday_id_seq OWNED BY holiday.holiday_id;


--
-- TOC entry 197 (class 1259 OID 79612)
-- Name: job_history; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE job_history (
    job_history_id integer NOT NULL,
    employee_id integer NOT NULL,
    company_name character varying(50),
    department character varying(50),
    "position" character varying(30),
    start_date date,
    end_date date,
    responsibility character varying(500),
    technology character varying(200),
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.job_history OWNER TO postgres;

--
-- TOC entry 198 (class 1259 OID 79618)
-- Name: job_history_job_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE job_history_job_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999
    CACHE 1;


ALTER TABLE public.job_history_job_history_id_seq OWNER TO postgres;

--
-- TOC entry 2370 (class 0 OID 0)
-- Dependencies: 198
-- Name: job_history_job_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE job_history_job_history_id_seq OWNED BY job_history.job_history_id;


--
-- TOC entry 220 (class 1259 OID 80001)
-- Name: leave_allowance; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE leave_allowance (
    allowance_id integer NOT NULL,
    employee_id integer NOT NULL,
    leave_type_id integer NOT NULL,
    entitlement numeric(4,1) NOT NULL,
    taken numeric(4,1) DEFAULT 0,
    year date,
    created_user integer,
    created_date timestamp without time zone
);


ALTER TABLE public.leave_allowance OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 80005)
-- Name: leave_allowance_allowance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE leave_allowance_allowance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999
    CACHE 1;


ALTER TABLE public.leave_allowance_allowance_id_seq OWNER TO postgres;

--
-- TOC entry 2371 (class 0 OID 0)
-- Dependencies: 221
-- Name: leave_allowance_allowance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE leave_allowance_allowance_id_seq OWNED BY leave_allowance.allowance_id;


--
-- TOC entry 199 (class 1259 OID 79632)
-- Name: leave_taken; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE leave_taken (
    leave_taken_id integer NOT NULL,
    employee_id integer NOT NULL,
    leave_type_id integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    application_date date NOT NULL,
    duration numeric(3,1) NOT NULL,
    is_am boolean DEFAULT false,
    is_pm boolean DEFAULT false,
    is_fullday boolean DEFAULT false,
    leave_status integer DEFAULT 1,
    reason character varying(200),
    comment character varying(200),
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.leave_taken OWNER TO postgres;

--
-- TOC entry 2372 (class 0 OID 0)
-- Dependencies: 199
-- Name: COLUMN leave_taken.leave_status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN leave_taken.leave_status IS '1:request, 2:approved, 3:reject';


--
-- TOC entry 2373 (class 0 OID 0)
-- Dependencies: 199
-- Name: COLUMN leave_taken.reason; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN leave_taken.reason IS 'applicant''s reason';


--
-- TOC entry 2374 (class 0 OID 0)
-- Dependencies: 199
-- Name: COLUMN leave_taken.comment; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN leave_taken.comment IS 'approver comment for reject';


--
-- TOC entry 200 (class 1259 OID 79639)
-- Name: leave_taken_leave_taken_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE leave_taken_leave_taken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999
    CACHE 1;


ALTER TABLE public.leave_taken_leave_taken_id_seq OWNER TO postgres;

--
-- TOC entry 2375 (class 0 OID 0)
-- Dependencies: 200
-- Name: leave_taken_leave_taken_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE leave_taken_leave_taken_id_seq OWNED BY leave_taken.leave_taken_id;


--
-- TOC entry 201 (class 1259 OID 79641)
-- Name: leave_type; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE leave_type (
    leave_type_id integer NOT NULL,
    name character varying(30) NOT NULL,
    description character varying(50),
    leave_per_year integer DEFAULT 0 NOT NULL,
    leave_type character varying(6),
    carry_over boolean DEFAULT false,
    including_holiday boolean DEFAULT false,
    delete_flg boolean DEFAULT false,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.leave_type OWNER TO postgres;

--
-- TOC entry 2376 (class 0 OID 0)
-- Dependencies: 201
-- Name: COLUMN leave_type.leave_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN leave_type.leave_type IS 'paid, unpaid';


--
-- TOC entry 2377 (class 0 OID 0)
-- Dependencies: 201
-- Name: COLUMN leave_type.including_holiday; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN leave_type.including_holiday IS 'to calculate whether Leave includes holiday or not.';


--
-- TOC entry 202 (class 1259 OID 79648)
-- Name: leave_type_leave_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE leave_type_leave_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99
    CACHE 1;


ALTER TABLE public.leave_type_leave_type_id_seq OWNER TO postgres;

--
-- TOC entry 2378 (class 0 OID 0)
-- Dependencies: 202
-- Name: leave_type_leave_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE leave_type_leave_type_id_seq OWNED BY leave_type.leave_type_id;


--
-- TOC entry 203 (class 1259 OID 79650)
-- Name: login_user; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE login_user (
    user_id integer NOT NULL,
    password character varying(100) NOT NULL,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.login_user OWNER TO postgres;

--
-- TOC entry 2379 (class 0 OID 0)
-- Dependencies: 203
-- Name: TABLE login_user; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE login_user IS 'User Login';


--
-- TOC entry 2380 (class 0 OID 0)
-- Dependencies: 203
-- Name: COLUMN login_user.user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN login_user.user_id IS 'user id';


--
-- TOC entry 2381 (class 0 OID 0)
-- Dependencies: 203
-- Name: COLUMN login_user.password; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN login_user.password IS 'Decode digits: (min: 8, max: 16) / 
Encode digits: (max: 100)';


--
-- TOC entry 2382 (class 0 OID 0)
-- Dependencies: 203
-- Name: COLUMN login_user.created_user; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN login_user.created_user IS 'created user id';


--
-- TOC entry 204 (class 1259 OID 79653)
-- Name: position; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "position" (
    position_id integer NOT NULL,
    category_id integer NOT NULL,
    position_name character varying(30) NOT NULL,
    description character varying(100),
    delete_flg boolean DEFAULT false,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public."position" OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 79657)
-- Name: position_position_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE position_position_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999
    CACHE 1;


ALTER TABLE public.position_position_id_seq OWNER TO postgres;

--
-- TOC entry 2383 (class 0 OID 0)
-- Dependencies: 205
-- Name: position_position_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE position_position_id_seq OWNED BY "position".position_id;


--
-- TOC entry 206 (class 1259 OID 79659)
-- Name: prefecture; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE prefecture (
    prefecture_id integer NOT NULL,
    district_id integer NOT NULL,
    prefecture_name character varying(30) NOT NULL,
    delete_flg boolean DEFAULT false,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.prefecture OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 79663)
-- Name: prefecture_prefecture_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE prefecture_prefecture_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;


ALTER TABLE public.prefecture_prefecture_id_seq OWNER TO postgres;

--
-- TOC entry 2384 (class 0 OID 0)
-- Dependencies: 207
-- Name: prefecture_prefecture_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE prefecture_prefecture_id_seq OWNED BY prefecture.prefecture_id;


--
-- TOC entry 208 (class 1259 OID 79665)
-- Name: resignation; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE resignation (
    resign_id integer NOT NULL,
    notice_date timestamp without time zone,
    status integer NOT NULL,
    additional_info character varying(500),
    reason character varying(400),
    resign_date date NOT NULL,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.resignation OWNER TO postgres;

--
-- TOC entry 2385 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN resignation.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN resignation.status IS '1: request, 2: approved, 3: cancel';


--
-- TOC entry 209 (class 1259 OID 79671)
-- Name: resignation_resign_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE resignation_resign_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;


ALTER TABLE public.resignation_resign_id_seq OWNER TO postgres;

--
-- TOC entry 2386 (class 0 OID 0)
-- Dependencies: 209
-- Name: resignation_resign_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE resignation_resign_id_seq OWNED BY resignation.resign_id;


--
-- TOC entry 210 (class 1259 OID 79673)
-- Name: role; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE role (
    role_id integer NOT NULL,
    role_name character varying(20) NOT NULL,
    description character varying(100)
);


ALTER TABLE public.role OWNER TO postgres;

--
-- TOC entry 2387 (class 0 OID 0)
-- Dependencies: 210
-- Name: TABLE role; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE role IS 'role for user login';


--
-- TOC entry 2388 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN role.role_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN role.role_id IS 'role id';


--
-- TOC entry 2389 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN role.role_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN role.role_name IS 'role name';


--
-- TOC entry 2390 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN role.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN role.description IS 'description of role';


--
-- TOC entry 211 (class 1259 OID 79676)
-- Name: role_role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE role_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99
    CACHE 1;


ALTER TABLE public.role_role_id_seq OWNER TO postgres;

--
-- TOC entry 2391 (class 0 OID 0)
-- Dependencies: 211
-- Name: role_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE role_role_id_seq OWNED BY role.role_id;


--
-- TOC entry 212 (class 1259 OID 79678)
-- Name: shift_policy; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE shift_policy (
    shift_id integer NOT NULL,
    description character varying(50) NOT NULL,
    early_in time without time zone NOT NULL,
    early_out time without time zone NOT NULL,
    duty_start time without time zone NOT NULL,
    duty_end time without time zone NOT NULL,
    latest_in time without time zone NOT NULL,
    latest_out time without time zone NOT NULL,
    break_out time without time zone,
    break_in time without time zone,
    morning_ot_start time without time zone,
    morning_ot_end time without time zone,
    evening_ot_start time without time zone,
    evening_ot_end time without time zone,
    delete_flg boolean DEFAULT false,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.shift_policy OWNER TO postgres;

--
-- TOC entry 2392 (class 0 OID 0)
-- Dependencies: 212
-- Name: TABLE shift_policy; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE shift_policy IS 'Work Shift';


--
-- TOC entry 2393 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.shift_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.shift_id IS 'shift id';


--
-- TOC entry 2394 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.description IS 'description for work shift';


--
-- TOC entry 2395 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.early_in; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.early_in IS 'this value must be "duty start time" if early in is empty.';


--
-- TOC entry 2396 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.early_out; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.early_out IS 'this value must be duty end time" if early in is empty.';


--
-- TOC entry 2397 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.duty_start; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.duty_start IS 'duty start time';


--
-- TOC entry 2398 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.duty_end; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.duty_end IS 'duty end time';


--
-- TOC entry 2399 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.latest_in; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.latest_in IS 'latest time in';


--
-- TOC entry 2400 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.latest_out; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.latest_out IS 'latest time out';


--
-- TOC entry 2401 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.break_out; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.break_out IS 'break time out';


--
-- TOC entry 2402 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.break_in; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.break_in IS 'break time out';


--
-- TOC entry 2403 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.morning_ot_start; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.morning_ot_start IS 'start time of morning overtime';


--
-- TOC entry 2404 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.morning_ot_end; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.morning_ot_end IS 'finished time of morning overtime';


--
-- TOC entry 2405 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.evening_ot_start; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.evening_ot_start IS 'start time of evening overtime';


--
-- TOC entry 2406 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN shift_policy.evening_ot_end; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN shift_policy.evening_ot_end IS 'finished time of evening overtime';


--
-- TOC entry 213 (class 1259 OID 79682)
-- Name: shift_policy_shift_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE shift_policy_shift_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999
    CACHE 1;


ALTER TABLE public.shift_policy_shift_id_seq OWNER TO postgres;

--
-- TOC entry 2407 (class 0 OID 0)
-- Dependencies: 213
-- Name: shift_policy_shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE shift_policy_shift_id_seq OWNED BY shift_policy.shift_id;


--
-- TOC entry 214 (class 1259 OID 79684)
-- Name: station; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE station (
    station_id integer NOT NULL,
    station_name character varying(20) NOT NULL,
    description character varying(100)
);


ALTER TABLE public.station OWNER TO postgres;

--
-- TOC entry 2408 (class 0 OID 0)
-- Dependencies: 214
-- Name: TABLE station; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE station IS 'station in a company';


--
-- TOC entry 2409 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN station.station_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN station.station_id IS 'station id';


--
-- TOC entry 2410 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN station.station_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN station.station_name IS 'station name';


--
-- TOC entry 2411 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN station.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN station.description IS 'description of station';


--
-- TOC entry 215 (class 1259 OID 79687)
-- Name: station_station_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE station_station_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99
    CACHE 1;


ALTER TABLE public.station_station_id_seq OWNER TO postgres;

--
-- TOC entry 2412 (class 0 OID 0)
-- Dependencies: 215
-- Name: station_station_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE station_station_id_seq OWNED BY station.station_id;


--
-- TOC entry 216 (class 1259 OID 79689)
-- Name: township; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE township (
    township_id integer NOT NULL,
    city_id integer NOT NULL,
    prefecture_id integer NOT NULL,
    district_id integer NOT NULL,
    township_name character varying(30) NOT NULL,
    delete_flg boolean DEFAULT false,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.township OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 79693)
-- Name: township_township_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE township_township_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;


ALTER TABLE public.township_township_id_seq OWNER TO postgres;

--
-- TOC entry 2413 (class 0 OID 0)
-- Dependencies: 217
-- Name: township_township_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE township_township_id_seq OWNED BY township.township_id;


--
-- TOC entry 218 (class 1259 OID 79695)
-- Name: user_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE user_user_id_seq
    START WITH 100000
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;


ALTER TABLE public.user_user_id_seq OWNER TO postgres;

--
-- TOC entry 2414 (class 0 OID 0)
-- Dependencies: 218
-- Name: user_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE user_user_id_seq OWNED BY login_user.user_id;


--
-- TOC entry 219 (class 1259 OID 79697)
-- Name: weekly_off; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE weekly_off (
    day integer NOT NULL,
    type integer NOT NULL,
    day_type integer,
    created_user integer NOT NULL,
    created_date timestamp without time zone NOT NULL,
    updated_user integer,
    updated_date timestamp without time zone
);


ALTER TABLE public.weekly_off OWNER TO postgres;

--
-- TOC entry 2415 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN weekly_off.day; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN weekly_off.day IS '1:Sunday, 2:Monday, 3:Tueday, 4:Wednesday, 5:Thursday, 6:Friday, 7:Saturday';


--
-- TOC entry 2416 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN weekly_off.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN weekly_off.type IS '0: Sat/Sun, 1: Custom';


--
-- TOC entry 2417 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN weekly_off.day_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN weekly_off.day_type IS '0: Full Day, 1: Half Day';


--
-- TOC entry 1995 (class 2604 OID 79700)
-- Name: academic_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY academic_background ALTER COLUMN academic_id SET DEFAULT nextval('academic_background_academic_id_seq'::regclass);


--
-- TOC entry 1996 (class 2604 OID 79701)
-- Name: address_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY address ALTER COLUMN address_id SET DEFAULT nextval('address_address_id_seq'::regclass);


--
-- TOC entry 1997 (class 2604 OID 79702)
-- Name: approval_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY approval_matrix ALTER COLUMN approval_id SET DEFAULT nextval('approval_matrix_approval_id_seq'::regclass);


--
-- TOC entry 2040 (class 2604 OID 80025)
-- Name: attendance_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attendance ALTER COLUMN attendance_id SET DEFAULT nextval('attendance_attendance_id_seq'::regclass);


--
-- TOC entry 1999 (class 2604 OID 79704)
-- Name: bank_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bank ALTER COLUMN bank_id SET DEFAULT nextval('bank_bank_id_seq'::regclass);


--
-- TOC entry 2001 (class 2604 OID 79705)
-- Name: branch_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bank_branch ALTER COLUMN branch_id SET DEFAULT nextval('bank_branch_branch_id_seq'::regclass);


--
-- TOC entry 2003 (class 2604 OID 79706)
-- Name: city_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY city ALTER COLUMN city_id SET DEFAULT nextval('city_city_id_seq'::regclass);


--
-- TOC entry 2004 (class 2604 OID 79707)
-- Name: contract_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY contract ALTER COLUMN contract_id SET DEFAULT nextval('contract_contract_id_seq'::regclass);


--
-- TOC entry 2006 (class 2604 OID 79708)
-- Name: department_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY department ALTER COLUMN department_id SET DEFAULT nextval('department_department_id_seq'::regclass);


--
-- TOC entry 2008 (class 2604 OID 79709)
-- Name: district_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY district ALTER COLUMN district_id SET DEFAULT nextval('district_district_id_seq'::regclass);


--
-- TOC entry 2009 (class 2604 OID 79710)
-- Name: contact_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY emergency_contact ALTER COLUMN contact_id SET DEFAULT nextval('emergency_contact_contact_id_seq'::regclass);


--
-- TOC entry 2011 (class 2604 OID 79711)
-- Name: employee_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee ALTER COLUMN employee_id SET DEFAULT nextval('employee_employee_id_seq'::regclass);


--
-- TOC entry 2013 (class 2604 OID 79712)
-- Name: category_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_category ALTER COLUMN category_id SET DEFAULT nextval('employee_category_category_id_seq'::regclass);


--
-- TOC entry 2014 (class 2604 OID 79713)
-- Name: holiday_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY holiday ALTER COLUMN holiday_id SET DEFAULT nextval('holiday_holiday_id_seq'::regclass);


--
-- TOC entry 2015 (class 2604 OID 79714)
-- Name: job_history_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job_history ALTER COLUMN job_history_id SET DEFAULT nextval('job_history_job_history_id_seq'::regclass);


--
-- TOC entry 2039 (class 2604 OID 80007)
-- Name: allowance_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_allowance ALTER COLUMN allowance_id SET DEFAULT nextval('leave_allowance_allowance_id_seq'::regclass);


--
-- TOC entry 2020 (class 2604 OID 79717)
-- Name: leave_taken_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_taken ALTER COLUMN leave_taken_id SET DEFAULT nextval('leave_taken_leave_taken_id_seq'::regclass);


--
-- TOC entry 2025 (class 2604 OID 79718)
-- Name: leave_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_type ALTER COLUMN leave_type_id SET DEFAULT nextval('leave_type_leave_type_id_seq'::regclass);


--
-- TOC entry 2026 (class 2604 OID 79719)
-- Name: user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY login_user ALTER COLUMN user_id SET DEFAULT nextval('user_user_id_seq'::regclass);


--
-- TOC entry 2028 (class 2604 OID 79720)
-- Name: position_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "position" ALTER COLUMN position_id SET DEFAULT nextval('position_position_id_seq'::regclass);


--
-- TOC entry 2030 (class 2604 OID 79721)
-- Name: prefecture_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prefecture ALTER COLUMN prefecture_id SET DEFAULT nextval('prefecture_prefecture_id_seq'::regclass);


--
-- TOC entry 2031 (class 2604 OID 79722)
-- Name: resign_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resignation ALTER COLUMN resign_id SET DEFAULT nextval('resignation_resign_id_seq'::regclass);


--
-- TOC entry 2032 (class 2604 OID 79723)
-- Name: role_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY role ALTER COLUMN role_id SET DEFAULT nextval('role_role_id_seq'::regclass);


--
-- TOC entry 2034 (class 2604 OID 79724)
-- Name: shift_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shift_policy ALTER COLUMN shift_id SET DEFAULT nextval('shift_policy_shift_id_seq'::regclass);


--
-- TOC entry 2035 (class 2604 OID 79725)
-- Name: station_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY station ALTER COLUMN station_id SET DEFAULT nextval('station_station_id_seq'::regclass);


--
-- TOC entry 2037 (class 2604 OID 79726)
-- Name: township_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY township ALTER COLUMN township_id SET DEFAULT nextval('township_township_id_seq'::regclass);


--
-- TOC entry 2254 (class 0 OID 79522)
-- Dependencies: 170
-- Data for Name: academic_background; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2418 (class 0 OID 0)
-- Dependencies: 171
-- Name: academic_background_academic_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('academic_background_academic_id_seq', 1, false);


--
-- TOC entry 2256 (class 0 OID 79527)
-- Dependencies: 172
-- Data for Name: address; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2419 (class 0 OID 0)
-- Dependencies: 173
-- Name: address_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('address_address_id_seq', 1, true);


--
-- TOC entry 2258 (class 0 OID 79532)
-- Dependencies: 174
-- Data for Name: approval_matrix; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2420 (class 0 OID 0)
-- Dependencies: 175
-- Name: approval_matrix_approval_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('approval_matrix_approval_id_seq', 1, true);


--
-- TOC entry 2307 (class 0 OID 80022)
-- Dependencies: 223
-- Data for Name: attendance; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2421 (class 0 OID 0)
-- Dependencies: 222
-- Name: attendance_attendance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('attendance_attendance_id_seq', 1, false);


--
-- TOC entry 2260 (class 0 OID 79543)
-- Dependencies: 176
-- Data for Name: bank; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2422 (class 0 OID 0)
-- Dependencies: 177
-- Name: bank_bank_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('bank_bank_id_seq', 1, true);


--
-- TOC entry 2262 (class 0 OID 79549)
-- Dependencies: 178
-- Data for Name: bank_branch; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2423 (class 0 OID 0)
-- Dependencies: 179
-- Name: bank_branch_branch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('bank_branch_branch_id_seq', 1, true);


--
-- TOC entry 2264 (class 0 OID 79555)
-- Dependencies: 180
-- Data for Name: city; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2424 (class 0 OID 0)
-- Dependencies: 181
-- Name: city_city_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('city_city_id_seq', 1, true);


--
-- TOC entry 2266 (class 0 OID 79561)
-- Dependencies: 182
-- Data for Name: company_profile; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2267 (class 0 OID 79567)
-- Dependencies: 183
-- Data for Name: contract; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2425 (class 0 OID 0)
-- Dependencies: 184
-- Name: contract_contract_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('contract_contract_id_seq', 1, true);


--
-- TOC entry 2269 (class 0 OID 79575)
-- Dependencies: 185
-- Data for Name: department; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO department VALUES (1, 'IT ', 'IT Department', false, 100001, '2016-01-03 00:00:00', NULL, NULL);
INSERT INTO department VALUES (2, 'Administration', 'Administration', false, 100001, '2016-05-26 10:21:02.118', NULL, NULL);


--
-- TOC entry 2426 (class 0 OID 0)
-- Dependencies: 186
-- Name: department_department_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('department_department_id_seq', 2, true);


--
-- TOC entry 2271 (class 0 OID 79581)
-- Dependencies: 187
-- Data for Name: district; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2427 (class 0 OID 0)
-- Dependencies: 188
-- Name: district_district_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('district_district_id_seq', 1, true);


--
-- TOC entry 2273 (class 0 OID 79587)
-- Dependencies: 189
-- Data for Name: emergency_contact; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2428 (class 0 OID 0)
-- Dependencies: 190
-- Name: emergency_contact_contact_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('emergency_contact_contact_id_seq', 1, false);


--
-- TOC entry 2275 (class 0 OID 79592)
-- Dependencies: 191
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO employee VALUES (100001, 'Tech Fun', 100001, 3, 1, 1, 1, 1, 'techfun@mail.com', 1, 'Male', NULL, NULL, NULL, '12/TaFaTa(N)123456', '2016-02-03', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 100001, '2016-02-03 00:00:00', NULL, NULL);


--
-- TOC entry 2276 (class 0 OID 79599)
-- Dependencies: 192
-- Data for Name: employee_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO employee_category VALUES (1, 'IT', 'IT', true, 100001, '2016-02-03 00:00:00', NULL, NULL);


--
-- TOC entry 2429 (class 0 OID 0)
-- Dependencies: 193
-- Name: employee_category_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_category_category_id_seq', 1, true);


--
-- TOC entry 2430 (class 0 OID 0)
-- Dependencies: 194
-- Name: employee_employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_employee_id_seq', 100001, true);


--
-- TOC entry 2279 (class 0 OID 79607)
-- Dependencies: 195
-- Data for Name: holiday; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2431 (class 0 OID 0)
-- Dependencies: 196
-- Name: holiday_holiday_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('holiday_holiday_id_seq', 1, false);


--
-- TOC entry 2281 (class 0 OID 79612)
-- Dependencies: 197
-- Data for Name: job_history; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2432 (class 0 OID 0)
-- Dependencies: 198
-- Name: job_history_job_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('job_history_job_history_id_seq', 1, false);


--
-- TOC entry 2304 (class 0 OID 80001)
-- Dependencies: 220
-- Data for Name: leave_allowance; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2433 (class 0 OID 0)
-- Dependencies: 221
-- Name: leave_allowance_allowance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('leave_allowance_allowance_id_seq', 1, false);


--
-- TOC entry 2283 (class 0 OID 79632)
-- Dependencies: 199
-- Data for Name: leave_taken; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2434 (class 0 OID 0)
-- Dependencies: 200
-- Name: leave_taken_leave_taken_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('leave_taken_leave_taken_id_seq', 1, false);


--
-- TOC entry 2285 (class 0 OID 79641)
-- Dependencies: 201
-- Data for Name: leave_type; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2435 (class 0 OID 0)
-- Dependencies: 202
-- Name: leave_type_leave_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('leave_type_leave_type_id_seq', 1, false);


--
-- TOC entry 2287 (class 0 OID 79650)
-- Dependencies: 203
-- Data for Name: login_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO login_user VALUES (100001, '6bea7d2cc55f6a625b0f01f3a7aea14cd0deebad6cb344cb61a3c911aa520b151d5b967f4d74bf31', 1, '2016-01-03 00:00:00', NULL, NULL);


--
-- TOC entry 2288 (class 0 OID 79653)
-- Dependencies: 204
-- Data for Name: position; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "position" VALUES (1, 1, 'Manager ', 'Manager', false, 100001, '2016-01-03 00:00:00', NULL, NULL);


--
-- TOC entry 2436 (class 0 OID 0)
-- Dependencies: 205
-- Name: position_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('position_position_id_seq', 1, true);


--
-- TOC entry 2290 (class 0 OID 79659)
-- Dependencies: 206
-- Data for Name: prefecture; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2437 (class 0 OID 0)
-- Dependencies: 207
-- Name: prefecture_prefecture_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('prefecture_prefecture_id_seq', 1, true);


--
-- TOC entry 2292 (class 0 OID 79665)
-- Dependencies: 208
-- Data for Name: resignation; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2438 (class 0 OID 0)
-- Dependencies: 209
-- Name: resignation_resign_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('resignation_resign_id_seq', 1, false);


--
-- TOC entry 2294 (class 0 OID 79673)
-- Dependencies: 210
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO role VALUES (1, 'USER', 'Normal user');
INSERT INTO role VALUES (2, 'MANAGER', 'Project manager or supervisor/Leader');
INSERT INTO role VALUES (3, 'ADMIN', 'HR staff and CEO/MD');


--
-- TOC entry 2439 (class 0 OID 0)
-- Dependencies: 211
-- Name: role_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('role_role_id_seq', 3, true);


--
-- TOC entry 2296 (class 0 OID 79678)
-- Dependencies: 212
-- Data for Name: shift_policy; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2440 (class 0 OID 0)
-- Dependencies: 213
-- Name: shift_policy_shift_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('shift_policy_shift_id_seq', 1, false);


--
-- TOC entry 2298 (class 0 OID 79684)
-- Dependencies: 214
-- Data for Name: station; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO station VALUES (1, 'Head Office', 'Main');


--
-- TOC entry 2441 (class 0 OID 0)
-- Dependencies: 215
-- Name: station_station_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('station_station_id_seq', 1, true);


--
-- TOC entry 2300 (class 0 OID 79689)
-- Dependencies: 216
-- Data for Name: township; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2442 (class 0 OID 0)
-- Dependencies: 217
-- Name: township_township_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('township_township_id_seq', 1, true);


--
-- TOC entry 2443 (class 0 OID 0)
-- Dependencies: 218
-- Name: user_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('user_user_id_seq', 100001, true);


--
-- TOC entry 2303 (class 0 OID 79697)
-- Dependencies: 219
-- Data for Name: weekly_off; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2043 (class 2606 OID 79728)
-- Name: academic_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY academic_background
    ADD CONSTRAINT "academic_idPK" PRIMARY KEY (academic_id);


--
-- TOC entry 2045 (class 2606 OID 79730)
-- Name: address_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY address
    ADD CONSTRAINT "address_idPK" PRIMARY KEY (address_id);


--
-- TOC entry 2047 (class 2606 OID 79734)
-- Name: approval_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY approval_matrix
    ADD CONSTRAINT "approval_idPK" PRIMARY KEY (approval_id);


--
-- TOC entry 2105 (class 2606 OID 80028)
-- Name: attendance_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY attendance
    ADD CONSTRAINT "attendance_idPK" PRIMARY KEY (attendance_id);


--
-- TOC entry 2049 (class 2606 OID 79738)
-- Name: bank_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bank
    ADD CONSTRAINT "bank_idPK" PRIMARY KEY (bank_id);


--
-- TOC entry 2051 (class 2606 OID 79740)
-- Name: branch_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bank_branch
    ADD CONSTRAINT "branch_idPK" PRIMARY KEY (branch_id);


--
-- TOC entry 2073 (class 2606 OID 79742)
-- Name: category_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_category
    ADD CONSTRAINT "category_idPK" PRIMARY KEY (category_id);


--
-- TOC entry 2053 (class 2606 OID 79744)
-- Name: city_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY city
    ADD CONSTRAINT "city_idPK" PRIMARY KEY (city_id);


--
-- TOC entry 2065 (class 2606 OID 79746)
-- Name: contact_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY emergency_contact
    ADD CONSTRAINT "contact_idPK" PRIMARY KEY (contact_id);


--
-- TOC entry 2059 (class 2606 OID 79748)
-- Name: contract_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT "contract_idPK" PRIMARY KEY (contract_id);


--
-- TOC entry 2101 (class 2606 OID 79750)
-- Name: dayPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY weekly_off
    ADD CONSTRAINT "dayPK" PRIMARY KEY (day);


--
-- TOC entry 2061 (class 2606 OID 79752)
-- Name: department_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY department
    ADD CONSTRAINT "department_idPK" PRIMARY KEY (department_id);


--
-- TOC entry 2063 (class 2606 OID 79754)
-- Name: district_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY district
    ADD CONSTRAINT "district_idPK" PRIMARY KEY (district_id);


--
-- TOC entry 2107 (class 2606 OID 80030)
-- Name: empId_attDate; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY attendance
    ADD CONSTRAINT "empId_attDate" UNIQUE (employee_id, attendance_date);


--
-- TOC entry 2067 (class 2606 OID 79758)
-- Name: employee_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "employee_idPK" PRIMARY KEY (employee_id);


--
-- TOC entry 2075 (class 2606 OID 79760)
-- Name: holiday_dateUQ; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY holiday
    ADD CONSTRAINT "holiday_dateUQ" UNIQUE (holiday_date);


--
-- TOC entry 2077 (class 2606 OID 79762)
-- Name: holiday_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY holiday
    ADD CONSTRAINT "holiday_idPK" PRIMARY KEY (holiday_id);


--
-- TOC entry 2069 (class 2606 OID 79764)
-- Name: job_emailUQ; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "job_emailUQ" UNIQUE (job_email);


--
-- TOC entry 2079 (class 2606 OID 79766)
-- Name: job_history_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY job_history
    ADD CONSTRAINT "job_history_idPK" PRIMARY KEY (job_history_id);


--
-- TOC entry 2103 (class 2606 OID 80009)
-- Name: leave_allowance_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY leave_allowance
    ADD CONSTRAINT "leave_allowance_idPK" PRIMARY KEY (allowance_id);


--
-- TOC entry 2083 (class 2606 OID 79770)
-- Name: leave_type_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY leave_type
    ADD CONSTRAINT "leave_type_idPK" PRIMARY KEY (leave_type_id);


--
-- TOC entry 2055 (class 2606 OID 79772)
-- Name: name_pk; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY company_profile
    ADD CONSTRAINT name_pk PRIMARY KEY (name);


--
-- TOC entry 2071 (class 2606 OID 79774)
-- Name: nrc_noUQ; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "nrc_noUQ" UNIQUE (nrc_no);


--
-- TOC entry 2087 (class 2606 OID 79776)
-- Name: position_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "position"
    ADD CONSTRAINT "position_idPK" PRIMARY KEY (position_id);


--
-- TOC entry 2089 (class 2606 OID 79778)
-- Name: prefecture_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY prefecture
    ADD CONSTRAINT "prefecture_idPK" PRIMARY KEY (prefecture_id);


--
-- TOC entry 2091 (class 2606 OID 79780)
-- Name: resign_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY resignation
    ADD CONSTRAINT "resign_idPK" PRIMARY KEY (resign_id);


--
-- TOC entry 2093 (class 2606 OID 79782)
-- Name: role_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY role
    ADD CONSTRAINT "role_idPK" PRIMARY KEY (role_id);


--
-- TOC entry 2095 (class 2606 OID 79784)
-- Name: shift_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY shift_policy
    ADD CONSTRAINT "shift_idPK" PRIMARY KEY (shift_id);


--
-- TOC entry 2097 (class 2606 OID 79786)
-- Name: station_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY station
    ADD CONSTRAINT "station_idPK" PRIMARY KEY (station_id);


--
-- TOC entry 2081 (class 2606 OID 79788)
-- Name: taken_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY leave_taken
    ADD CONSTRAINT "taken_idPK" PRIMARY KEY (leave_taken_id);


--
-- TOC entry 2099 (class 2606 OID 79790)
-- Name: township_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY township
    ADD CONSTRAINT "township_idPK" PRIMARY KEY (township_id);


--
-- TOC entry 2085 (class 2606 OID 79792)
-- Name: user_idPK; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY login_user
    ADD CONSTRAINT "user_idPK" PRIMARY KEY (user_id);


--
-- TOC entry 2057 (class 2606 OID 79794)
-- Name: week_off_typeUQ; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY company_profile
    ADD CONSTRAINT "week_off_typeUQ" UNIQUE (weekly_off_type);


--
-- TOC entry 2123 (class 2606 OID 79795)
-- Name: address_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "address_idFK" FOREIGN KEY (address_id) REFERENCES address(address_id);


--
-- TOC entry 2113 (class 2606 OID 79800)
-- Name: applicant_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY approval_matrix
    ADD CONSTRAINT "applicant_idFK" FOREIGN KEY (applicant_id) REFERENCES employee(employee_id);


--
-- TOC entry 2114 (class 2606 OID 79805)
-- Name: approver_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY approval_matrix
    ADD CONSTRAINT "approver_idFK" FOREIGN KEY (approver_id) REFERENCES employee(employee_id);


--
-- TOC entry 2115 (class 2606 OID 79810)
-- Name: bank_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bank_branch
    ADD CONSTRAINT "bank_idFK" FOREIGN KEY (bank_id) REFERENCES bank(bank_id);


--
-- TOC entry 2124 (class 2606 OID 79815)
-- Name: bank_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "bank_idFK" FOREIGN KEY (bank_id) REFERENCES bank(bank_id);


--
-- TOC entry 2125 (class 2606 OID 79820)
-- Name: branch_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "branch_idFK" FOREIGN KEY (branch_id) REFERENCES bank_branch(branch_id);


--
-- TOC entry 2137 (class 2606 OID 79825)
-- Name: category_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "position"
    ADD CONSTRAINT "category_idFK" FOREIGN KEY (category_id) REFERENCES employee_category(category_id);


--
-- TOC entry 2126 (class 2606 OID 79830)
-- Name: category_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "category_idFK" FOREIGN KEY (category_id) REFERENCES employee_category(category_id);


--
-- TOC entry 2139 (class 2606 OID 79835)
-- Name: city_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY township
    ADD CONSTRAINT city_id FOREIGN KEY (city_id) REFERENCES city(city_id);


--
-- TOC entry 2109 (class 2606 OID 79840)
-- Name: city_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY address
    ADD CONSTRAINT city_id FOREIGN KEY (city_id) REFERENCES city(city_id);


--
-- TOC entry 2118 (class 2606 OID 79845)
-- Name: city_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY company_profile
    ADD CONSTRAINT "city_idFK" FOREIGN KEY (city_id) REFERENCES city(city_id);


--
-- TOC entry 2127 (class 2606 OID 79850)
-- Name: contract_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "contract_idFK" FOREIGN KEY (contract_id) REFERENCES contract(contract_id);


--
-- TOC entry 2128 (class 2606 OID 79855)
-- Name: department_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT department_id FOREIGN KEY (department_id) REFERENCES department(department_id);


--
-- TOC entry 2138 (class 2606 OID 79860)
-- Name: district_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prefecture
    ADD CONSTRAINT district_id FOREIGN KEY (district_id) REFERENCES district(district_id);


--
-- TOC entry 2116 (class 2606 OID 79865)
-- Name: district_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY city
    ADD CONSTRAINT district_id FOREIGN KEY (district_id) REFERENCES district(district_id);


--
-- TOC entry 2140 (class 2606 OID 79870)
-- Name: district_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY township
    ADD CONSTRAINT district_id FOREIGN KEY (district_id) REFERENCES district(district_id);


--
-- TOC entry 2110 (class 2606 OID 79875)
-- Name: district_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY address
    ADD CONSTRAINT district_id FOREIGN KEY (district_id) REFERENCES district(district_id);


--
-- TOC entry 2119 (class 2606 OID 79880)
-- Name: district_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY company_profile
    ADD CONSTRAINT "district_idFK" FOREIGN KEY (district_id) REFERENCES district(district_id);


--
-- TOC entry 2108 (class 2606 OID 79885)
-- Name: employee_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY academic_background
    ADD CONSTRAINT "employee_idFK" FOREIGN KEY (employee_id) REFERENCES employee(employee_id);


--
-- TOC entry 2122 (class 2606 OID 79895)
-- Name: employee_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY emergency_contact
    ADD CONSTRAINT "employee_idFK" FOREIGN KEY (employee_id) REFERENCES employee(employee_id);


--
-- TOC entry 2134 (class 2606 OID 79900)
-- Name: employee_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job_history
    ADD CONSTRAINT "employee_idFK" FOREIGN KEY (employee_id) REFERENCES employee(employee_id);


--
-- TOC entry 2135 (class 2606 OID 79915)
-- Name: employee_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_taken
    ADD CONSTRAINT "employee_idFK" FOREIGN KEY (employee_id) REFERENCES employee(employee_id);


--
-- TOC entry 2143 (class 2606 OID 80010)
-- Name: employee_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_allowance
    ADD CONSTRAINT "employee_idFK" FOREIGN KEY (employee_id) REFERENCES employee(employee_id);


--
-- TOC entry 2145 (class 2606 OID 80031)
-- Name: employee_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attendance
    ADD CONSTRAINT "employee_idFK" FOREIGN KEY (employee_id) REFERENCES employee(employee_id);


--
-- TOC entry 2136 (class 2606 OID 79930)
-- Name: leave_type_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_taken
    ADD CONSTRAINT "leave_type_idFK" FOREIGN KEY (leave_type_id) REFERENCES leave_type(leave_type_id);


--
-- TOC entry 2144 (class 2606 OID 80015)
-- Name: leave_type_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_allowance
    ADD CONSTRAINT "leave_type_idFK" FOREIGN KEY (leave_type_id) REFERENCES leave_type(leave_type_id);


--
-- TOC entry 2129 (class 2606 OID 79935)
-- Name: position_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "position_idFK" FOREIGN KEY (position_id) REFERENCES "position"(position_id);


--
-- TOC entry 2117 (class 2606 OID 79940)
-- Name: prefecture_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY city
    ADD CONSTRAINT prefecture_id FOREIGN KEY (prefecture_id) REFERENCES prefecture(prefecture_id);


--
-- TOC entry 2141 (class 2606 OID 79945)
-- Name: prefecture_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY township
    ADD CONSTRAINT prefecture_id FOREIGN KEY (prefecture_id) REFERENCES prefecture(prefecture_id);


--
-- TOC entry 2111 (class 2606 OID 79950)
-- Name: prefecture_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY address
    ADD CONSTRAINT prefecture_id FOREIGN KEY (prefecture_id) REFERENCES prefecture(prefecture_id);


--
-- TOC entry 2120 (class 2606 OID 79955)
-- Name: prefecture_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY company_profile
    ADD CONSTRAINT "prefecture_idFK" FOREIGN KEY (prefecture_id) REFERENCES prefecture(prefecture_id);


--
-- TOC entry 2130 (class 2606 OID 79960)
-- Name: resignation_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "resignation_idFK" FOREIGN KEY (resign_id) REFERENCES resignation(resign_id);


--
-- TOC entry 2131 (class 2606 OID 79965)
-- Name: role_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "role_idFK" FOREIGN KEY (role_id) REFERENCES role(role_id);


--
-- TOC entry 2146 (class 2606 OID 80036)
-- Name: shift_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attendance
    ADD CONSTRAINT "shift_idFK" FOREIGN KEY (shift_id) REFERENCES shift_policy(shift_id);


--
-- TOC entry 2132 (class 2606 OID 79975)
-- Name: station_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "station_idFK" FOREIGN KEY (station_id) REFERENCES station(station_id);


--
-- TOC entry 2112 (class 2606 OID 79980)
-- Name: township_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY address
    ADD CONSTRAINT township_id FOREIGN KEY (township_id) REFERENCES township(township_id);


--
-- TOC entry 2121 (class 2606 OID 79985)
-- Name: township_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY company_profile
    ADD CONSTRAINT "township_idFK" FOREIGN KEY (township_id) REFERENCES township(township_id);


--
-- TOC entry 2133 (class 2606 OID 79990)
-- Name: user_idFK; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee
    ADD CONSTRAINT "user_idFK" FOREIGN KEY (user_id) REFERENCES login_user(user_id);


--
-- TOC entry 2142 (class 2606 OID 79995)
-- Name: week_off_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY weekly_off
    ADD CONSTRAINT week_off_type FOREIGN KEY (type) REFERENCES company_profile(weekly_off_type);


--
-- TOC entry 2314 (class 0 OID 0)
-- Dependencies: 6
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2016-06-06 14:02:14

--
-- PostgreSQL database dump complete
--

