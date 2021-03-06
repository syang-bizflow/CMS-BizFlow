
/**
 * Gets the participant names for a active work item of a process instance.
 *
 * @param I_PROCID - Process ID
 *
 * @return Names of participants concatenated by comma.
 */
CREATE OR REPLACE FUNCTION HHS_FN_GETCURPRTCPTNAMES
(
	I_PROCID IN NUMBER
)
RETURN VARCHAR2
IS
	L_COUNT NUMBER(10);
	L_NAME VARCHAR2(100);
	L_VALUE VARCHAR2(2000);

	CURSOR CUR_GET_ALL_PRTCP IS
		SELECT W.PRTCPNAME
		FROM WITEM W
			INNER JOIN ACT A ON A.PROCID = W.PROCID AND A.ACTSEQ = W.ACTSEQ
		WHERE W.PROCID = I_PROCID AND W.STATE IN ('I', 'R', 'P', 'V')
		ORDER BY A.ACTSEQ;

BEGIN

	L_COUNT := 0;
	L_VALUE := ' ';

	OPEN CUR_GET_ALL_PRTCP;

	LOOP
		FETCH CUR_GET_ALL_PRTCP INTO L_NAME;
		EXIT WHEN CUR_GET_ALL_PRTCP%NOTFOUND;

		IF (L_COUNT = 0) THEN
			L_VALUE := L_NAME;
		ELSE
			L_VALUE := L_VALUE || ',' || L_NAME;
		END IF;
		L_COUNT := L_COUNT + 1;
	END LOOP;

	CLOSE CUR_GET_ALL_PRTCP;

	RETURN L_VALUE;
END;

/




/**
 * Gets the activity names for an active process instance.
 *
 * @param I_PROCID - Process ID
 *
 * @return Names of activities concatenated by comma.
 */
CREATE OR REPLACE FUNCTION HHS_FN_GETCURACTNAMES
(
	I_PROCID NUMBER
)
RETURN VARCHAR2
IS
	L_COUNT NUMBER(10);
	L_NAME VARCHAR2(100);
	L_VALUE VARCHAR2(2000);

	CURSOR CUR_GET_ALL_ACT IS
		SELECT NAME FROM ACT
		WHERE PROCID = I_PROCID AND STATE IN ('R', 'V')
		ORDER BY ACTSEQ;
BEGIN
	L_VALUE := ' ';
	L_COUNT := 0;
	OPEN CUR_GET_ALL_ACT;

	LOOP
		FETCH CUR_GET_ALL_ACT INTO L_NAME;
		EXIT WHEN CUR_GET_ALL_ACT%NOTFOUND;

		IF (L_COUNT = 0) THEN
			L_VALUE := L_NAME;
		ELSE
			L_VALUE := L_VALUE || ',' || L_NAME;
		END IF;
		L_COUNT := L_COUNT + 1;
	END LOOP;

	CLOSE CUR_GET_ALL_ACT;

	RETURN L_VALUE;
END;

/





/**
 * Gets the Request Date for the given process instance.
 * If the process is Classification, it will return the creationdtime of
 * the parent Strategic Consultation process instance.  If not, it will return
 * the creationdtime of itself.
 *
 * @param I_PROCID - Process ID
 *
 * @return Creation Date Time of the process instance or parent process instance.
 */
CREATE OR REPLACE FUNCTION HHS_FN_GETREQUESTDT
(
	I_PROCID IN NUMBER
)
RETURN DATE
IS
	L_PARENTPROCID NUMBER(20);
	L_PROCNAME VARCHAR2(100);
	L_RETURN_DATE DATE;

BEGIN
	BEGIN
		SELECT PARENTPROCID, NAME, CREATIONDTIME
		INTO L_PARENTPROCID, L_PROCNAME, L_RETURN_DATE
		FROM PROCS
		WHERE PROCID = I_PROCID;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			L_PARENTPROCID := NULL;
			L_PROCNAME := NULL;
			L_RETURN_DATE := NULL;
		WHEN OTHERS THEN
			L_PARENTPROCID := NULL;
			L_PROCNAME := NULL;
			L_RETURN_DATE := NULL;
	END;

	-- For Classification process, lookup parent's creationdtime
	IF L_PARENTPROCID IS NOT NULL AND L_PARENTPROCID > 0
		AND L_PROCNAME IS NOT NULL AND L_PROCNAME = 'Classification'
	THEN
		BEGIN
			SELECT CREATIONDTIME
			INTO L_RETURN_DATE
			FROM PROCS
			WHERE PROCID = L_PARENTPROCID;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				L_RETURN_DATE := NULL;
			WHEN OTHERS THEN
				L_RETURN_DATE := NULL;
		END;
	END IF;

	RETURN L_RETURN_DATE;
END;

/


/**
* Insert comment into the cmnt table
* This SP is for Notes Tab implementation.
*
* @param	I_SVRID
* @param	I_PROCID
* @param	I_WITEMSEQ
* @param	I_ACTSEQ
* @param	I_ACTNAME
* @param	I_CREATOR
* @param	I_CREATORNAME
* @param	I_CONTENTS
*/
create or replace PROCEDURE SP_INSERT_COMMENT
  (
      I_SVRID           IN      VARCHAR2
    , I_PROCID          IN      NUMBER
    , I_WITEMSEQ        IN      NUMBER
    , I_ACTSEQ          IN      NUMBER
    , I_ACTNAME         IN      VARCHAR2
    , I_CREATOR         IN      VARCHAR2
    , I_CREATORNAME     IN      VARCHAR2
    , I_CONTENTS        IN      VARCHAR2
  )
IS
  V_CMNTSEQ     NUMBER(10);
  V_PROCIDSTR   VARCHAR2(10);
  V_UTC         DATE;    

  BEGIN

    IF I_PROCID IS NOT NULL AND I_PROCID > 0 THEN
    
      SELECT TO_CHAR(I_PROCID)
      INTO V_PROCIDSTR
      FROM DUAL;
      
      SP_GET_ID(I_SVRID, V_PROCIDSTR, 1, V_CMNTSEQ);
      
      
      SELECT SYSTIMESTAMP AT TIME ZONE 'UTC'
      INTO V_UTC
      FROM DUAL;      
      
      INSERT INTO CMNT
      (SVRID, PROCID, CMNTSEQ, GETTYPE, SENDTYPE, WITEMSEQ, ACTSEQ, ACTNAME, CREATIONDTIME, CREATOR, CREATORNAME, CONTENTS)
      VALUES
      (I_SVRID, I_PROCID, V_CMNTSEQ, 'C', 'B', I_WITEMSEQ, I_ACTSEQ, I_ACTNAME, V_UTC, I_CREATOR, I_CREATORNAME, I_CONTENTS);
      
      COMMIT;

    END IF;

  EXCEPTION
  
    WHEN OTHERS THEN
      raise_application_error(-20714, sqlerrm);
  
  END;

  /
