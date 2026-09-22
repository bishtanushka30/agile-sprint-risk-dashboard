SELECT 
    status,
    COUNT(*) AS invalid_completion_dates
FROM tickets
WHERE YEAR(completion_date) = 0
GROUP BY status
ORDER BY invalid_completion_dates DESC;
SELECT
    status,
    COUNT(*) AS total_tickets,
    SUM(YEAR(completion_date) = 0) AS missing_completion_date
FROM tickets
GROUP BY status
ORDER BY missing_completion_date DESC;
-- =====================================================
-- 3. DELIVERY PERFORMANCE
-- =====================================================

-- Calculate overall ticket completion

SELECT
    COUNT(*) AS total_tickets,
    SUM(status = 'Done') AS completed_tickets,
    SUM(status <> 'Done') AS open_tickets,
    ROUND(100 * SUM(status = 'Done') / COUNT(*), 2)
        AS completion_percentage
FROM tickets;
-- =====================================================
-- 4. SPRINT ANALYSIS
-- =====================================================

-- Check the sprints available in the dataset

SELECT DISTINCT sprint
FROM tickets
ORDER BY sprint;
-- Number of tickets in each sprint

SELECT
    sprint,
    COUNT(*) AS total_tickets
FROM tickets
GROUP BY sprint
ORDER BY CAST(SUBSTRING(sprint, 7) AS UNSIGNED);
-- Completion performance by sprint

SELECT
    sprint,
    COUNT(*) AS total_tickets,
    SUM(status = 'Done') AS completed_tickets,
    SUM(status <> 'Done') AS open_tickets,
    ROUND(100 * SUM(status = 'Done') / COUNT(*), 2)
        AS completion_percentage
FROM tickets
GROUP BY sprint
ORDER BY CAST(SUBSTRING(sprint, 7) AS UNSIGNED);
-- Workload vs completion by sprint

SELECT
    sprint,
    COUNT(*) AS total_tickets,
    SUM(status = 'Done') AS completed_tickets,
    ROUND(
        100 * SUM(status = 'Done') / COUNT(*),
        2
    ) AS completion_percentage
FROM tickets
GROUP BY sprint
ORDER BY total_tickets DESC;
-- Open tickets by priority

SELECT
    priority,
    COUNT(*) AS open_tickets
FROM tickets
WHERE status <> 'Done'
GROUP BY priority
ORDER BY open_tickets DESC;

-- Blocked tickets by priority

SELECT
    priority,
    COUNT(*) AS blocked_tickets
FROM tickets
WHERE blocked = 'Yes'
GROUP BY priority
ORDER BY blocked_tickets DESC;
-- =========================================================
-- Dependency Analysis
-- =========================================================

-- Check how many tickets have dependencies

SELECT
    dependency,
    COUNT(*) AS total_tickets
FROM tickets
WHERE dependency IS NOT NULL
  AND dependency <> ''
GROUP BY dependency
ORDER BY total_tickets DESC;
-- Dependency-related blocked work

SELECT
    dependency,
    blocked,
    COUNT(*) AS total_tickets
FROM tickets
GROUP BY dependency, blocked
ORDER BY dependency, blocked;
-- =========================================================
-- Ticket Aging Analysis
-- =========================================================

-- Identify open tickets that have been in the system the longest

SELECT
    ticket_id,
    sprint,
    team,
    priority,
    status,
    created_date,
    DATEDIFF(CURDATE(), created_date) AS ticket_age_days
FROM tickets
WHERE status <> 'Done'
ORDER BY ticket_age_days DESC;
-- =========================================================
-- Ticket Aging Risk Buckets
-- =========================================================

-- Group open tickets by how long they have remained open

SELECT
    CASE
        WHEN DATEDIFF(CURDATE(), created_date) <= 30 THEN '0-30 Days'
        WHEN DATEDIFF(CURDATE(), created_date) <= 60 THEN '31-60 Days'
        WHEN DATEDIFF(CURDATE(), created_date) <= 90 THEN '61-90 Days'
        ELSE '90+ Days'
    END AS aging_bucket,
    COUNT(*) AS total_tickets
FROM tickets
WHERE status <> 'Done'
GROUP BY aging_bucket
ORDER BY
    CASE aging_bucket
        WHEN '0-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        WHEN '90+ Days' THEN 4
    END;
    -- High-risk open tickets

SELECT
    ticket_id,
    sprint,
    team,
    priority,
    status,
    blocked,
    dependency,
    created_date,
    DATEDIFF(CURDATE(), created_date) AS ticket_age_days
FROM tickets
WHERE status <> 'Done'
  AND (
      priority IN ('High', 'Critical')
      OR blocked = 'Yes'
      OR dependency = 'Yes'
  )
ORDER BY
    ticket_age_days DESC;
    -- High-risk tickets with multiple risk signals

SELECT
    ticket_id,
    sprint,
    team,
    priority,
    status,
    blocked,
    dependency,
    DATEDIFF(CURDATE(), created_date) AS ticket_age_days
FROM tickets
WHERE status <> 'Done'
  AND (
      priority IN ('High', 'Critical')
      OR blocked = 'Yes'
      OR dependency = 'Yes'
  )
ORDER BY
    (priority IN ('Critical', 'High')) DESC,
    blocked DESC,
    dependency DESC,
    ticket_age_days DESC;
    -- Risk level distribution

SELECT
    CASE
        WHEN priority = 'Critical'
             AND blocked = 'Yes'
             AND dependency = 'Yes'
            THEN 'Critical Risk'

        WHEN priority IN ('Critical', 'High')
             AND (blocked = 'Yes' OR dependency = 'Yes')
            THEN 'High Risk'

        WHEN blocked = 'Yes'
             OR dependency = 'Yes'
            THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_level,

    COUNT(*) AS total_tickets

FROM tickets
WHERE status <> 'Done'

GROUP BY risk_level

ORDER BY
    CASE risk_level
        WHEN 'Critical Risk' THEN 1
        WHEN 'High Risk' THEN 2
        WHEN 'Medium Risk' THEN 3
        WHEN 'Low Risk' THEN 4
    END;
   
-- Team-level risk analysis

SELECT
    team,

    COUNT(*) AS open_tickets,

    SUM(
        priority IN ('High', 'Critical')
        OR blocked = 'Yes'
        OR dependency = 'Yes'
    ) AS risk_tickets,

    ROUND(
        100 * SUM(
            priority IN ('High', 'Critical')
            OR blocked = 'Yes'
            OR dependency = 'Yes'
        ) / COUNT(*),
        2
    ) AS risk_percentage

FROM tickets

WHERE status <> 'Done'

GROUP BY team

ORDER BY risk_percentage DESC;
-- Check issue types
SELECT
    issue_type,
    COUNT(*) AS total_tickets
FROM tickets
GROUP BY issue_type
ORDER BY total_tickets DESC;

-- Bugs by team

SELECT
    team,
    COUNT(*) AS bug_tickets
FROM tickets
WHERE issue_type = 'Bug'
GROUP BY team
ORDER BY bug_tickets DESC;

-- Bug rate by team

SELECT
    team,
    COUNT(*) AS total_tickets,
    SUM(issue_type = 'Bug') AS bug_tickets,
    ROUND(
        100 * SUM(issue_type = 'Bug') / COUNT(*),
        2
    ) AS bug_percentage
FROM tickets
GROUP BY team
ORDER BY bug_percentage DESC;

-- Bug completion status

SELECT
    status,
    COUNT(*) AS bug_tickets
FROM tickets
WHERE issue_type = 'Bug'
GROUP BY status
ORDER BY bug_tickets DESC;

-- Open bugs by team

SELECT
    team,
    COUNT(*) AS open_bugs
FROM tickets
WHERE issue_type = 'Bug'
  AND status <> 'Done'
GROUP BY team
ORDER BY open_bugs DESC;

-- Blocked bugs by team

SELECT
    team,
    COUNT(*) AS blocked_bugs
FROM tickets
WHERE issue_type = 'Bug'
  AND blocked = 'Yes'
GROUP BY team
ORDER BY blocked_bugs DESC;

-- Blocked bug rate by team

SELECT
    team,
    COUNT(*) AS open_bugs,
    SUM(blocked = 'Yes') AS blocked_bugs,
    ROUND(
        100 * SUM(blocked = 'Yes') / COUNT(*),
        2
    ) AS blocked_bug_percentage
FROM tickets
WHERE issue_type = 'Bug'
  AND status <> 'Done'
GROUP BY team
ORDER BY blocked_bug_percentage DESC;

-- Open bugs by status and team

SELECT
    team,
    status,
    COUNT(*) AS open_bugs
FROM tickets
WHERE issue_type = 'Bug'
  AND status <> 'Done'
GROUP BY team, status
ORDER BY team, open_bugs DESC;

-- Team Quality & Delivery Summary

SELECT
    team,

    COUNT(*) AS total_tickets,

    SUM(issue_type = 'Bug') AS total_bugs,

    SUM(
        issue_type = 'Bug'
        AND status <> 'Done'
    ) AS open_bugs,

    SUM(
        issue_type = 'Bug'
        AND blocked = 'Yes'
        AND status <> 'Done'
    ) AS blocked_bugs,

    ROUND(
        100 * SUM(issue_type = 'Bug') / COUNT(*),
        2
    ) AS bug_percentage,

    ROUND(
        100 * SUM(
            issue_type = 'Bug'
            AND blocked = 'Yes'
            AND status <> 'Done'
        )
        /
        NULLIF(
            SUM(issue_type = 'Bug' AND status <> 'Done'),
            0
        ),
        2
    ) AS blocked_bug_percentage

FROM tickets

GROUP BY team

ORDER BY blocked_bug_percentage DESC;

SELECT
    team,

    COUNT(*) AS total_tickets,

    SUM(issue_type = 'Bug') AS total_bugs,

    SUM(issue_type = 'Bug' AND status <> 'Done') AS open_bugs,

    SUM(issue_type = 'Bug' AND blocked = 'Yes' AND status <> 'Done') AS blocked_bugs,

    ROUND(
        100 * SUM(issue_type = 'Bug') / COUNT(*),
        2
    ) AS bug_percentage,

    ROUND(
        100 * SUM(
            issue_type = 'Bug'
            AND blocked = 'Yes'
            AND status <> 'Done'
        )
        / NULLIF(
            SUM(issue_type = 'Bug' AND status <> 'Done'),
            0
        ),
        2
    ) AS blocked_bug_percentage

FROM tickets

GROUP BY team

ORDER BY blocked_bug_percentage DESC;

SELECT
    sprint,
    team,
    SUM(story_points) AS planned_points,
    SUM(
        CASE
            WHEN status = 'Done' THEN story_points
            ELSE 0
        END
    ) AS completed_points,
    ROUND(
        100 * SUM(
            CASE
                WHEN status = 'Done' THEN story_points
                ELSE 0
            END
        ) / NULLIF(SUM(story_points), 0),
        2
    ) AS completion_percentage
FROM tickets
GROUP BY sprint, team
ORDER BY sprint, completion_percentage;

SELECT
    sprint,

    SUM(story_points) AS planned_points,

    SUM(
        CASE
            WHEN status = 'Done' THEN story_points
            ELSE 0
        END
    ) AS completed_points,

    ROUND(
        100 * SUM(
            CASE
                WHEN status = 'Done' THEN story_points
                ELSE 0
            END
        ) / NULLIF(SUM(story_points), 0),
        2
    ) AS completion_percentage

FROM tickets

GROUP BY sprint

ORDER BY completion_percentage ASC;

SELECT
    ROUND(AVG(completion_percentage), 2) AS average_completion,
    ROUND(MIN(completion_percentage), 2) AS lowest_completion,
    ROUND(MAX(completion_percentage), 2) AS highest_completion
FROM (
    SELECT
        sprint,
        ROUND(
            100 * SUM(
                CASE
                    WHEN status = 'Done' THEN story_points
                    ELSE 0
                END
            ) / NULLIF(SUM(story_points), 0),
            2
        ) AS completion_percentage
    FROM tickets
    GROUP BY sprint
) AS sprint_summary;

SELECT
    sprint,
    SUM(story_points) AS planned_points,
    
    SUM(
        CASE
            WHEN status = 'Done' THEN story_points
            ELSE 0
        END
    ) AS completed_points,
    
    ROUND(
        100 * SUM(
            CASE
                WHEN status = 'Done' THEN story_points
                ELSE 0
            END
        ) / NULLIF(SUM(story_points), 0),
        2
    ) AS completion_percentage,
    
    COUNT(*) AS total_tickets,
    
    SUM(issue_type = 'Bug') AS total_bugs,
    
    SUM(
        issue_type = 'Bug'
        AND status <> 'Done'
    ) AS open_bugs,
    
    SUM(
        blocked = 'Yes'
        AND status <> 'Done'
    ) AS blocked_tickets

FROM tickets
GROUP BY sprint
ORDER BY sprint;

SELECT
    sprint,

    ROUND(
        100 * SUM(
            CASE
                WHEN status = 'Done' THEN story_points
                ELSE 0
            END
        ) / NULLIF(SUM(story_points), 0),
        2
    ) AS completion_percentage,

    SUM(
        issue_type = 'Bug'
        AND status <> 'Done'
    ) AS open_bugs,

    SUM(
        blocked = 'Yes'
        AND status <> 'Done'
    ) AS blocked_tickets,

    COUNT(*) AS total_tickets,

    ROUND(
        100 * SUM(
            blocked = 'Yes'
            AND status <> 'Done'
        ) / COUNT(*),
        2
    ) AS blocked_percentage

FROM tickets
GROUP BY sprint
ORDER BY sprint;

SELECT
    sprint,

    ROUND(
        100 * SUM(
            CASE
                WHEN status = 'Done' THEN story_points
                ELSE 0
            END
        ) / NULLIF(SUM(story_points), 0),
        2
    ) AS completion_percentage,

    SUM(
        issue_type = 'Bug'
        AND status <> 'Done'
    ) AS open_bugs,

    SUM(
        blocked = 'Yes'
        AND status <> 'Done'
    ) AS blocked_tickets,

    COUNT(*) AS total_tickets,

    ROUND(
        100 * SUM(
            blocked = 'Yes'
            AND status <> 'Done'
        ) / COUNT(*),
        2
    ) AS blocked_percentage,

    CASE
        WHEN
            100 * SUM(blocked = 'Yes' AND status <> 'Done') / COUNT(*) >= 15
            OR
            100 * SUM(
                CASE
                    WHEN status = 'Done' THEN story_points
                    ELSE 0
                END
            ) / NULLIF(SUM(story_points), 0) < 45
        THEN 'High Risk'

        WHEN
            100 * SUM(blocked = 'Yes' AND status <> 'Done') / COUNT(*) >= 10
            OR
            100 * SUM(
                CASE
                    WHEN status = 'Done' THEN story_points
                    ELSE 0
                END
            ) / NULLIF(SUM(story_points), 0) < 55
        THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_level

FROM tickets
GROUP BY sprint
ORDER BY sprint;

SELECT
    sprint,

    ROUND(
        100 * SUM(
            CASE
                WHEN status = 'Done' THEN story_points
                ELSE 0
            END
        ) / NULLIF(SUM(story_points), 0),
        2
    ) AS completion_percentage,

    SUM(
        issue_type = 'Bug'
        AND status <> 'Done'
    ) AS open_bugs,

    SUM(
        blocked = 'Yes'
        AND status <> 'Done'
    ) AS blocked_tickets,

    COUNT(*) AS total_tickets,

    ROUND(
        100 * SUM(
            blocked = 'Yes'
            AND status <> 'Done'
        ) / COUNT(*),
        2
    ) AS blocked_percentage,

    CASE
        WHEN
            100 * SUM(
                CASE
                    WHEN status = 'Done' THEN story_points
                    ELSE 0
                END
            ) / NULLIF(SUM(story_points), 0) < 45
            OR
            100 * SUM(
                blocked = 'Yes'
                AND status <> 'Done'
            ) / COUNT(*) >= 10
        THEN 'High Risk'

        WHEN
            100 * SUM(
                CASE
                    WHEN status = 'Done' THEN story_points
                    ELSE 0
                END
            ) / NULLIF(SUM(story_points), 0) < 55
        THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_level

FROM tickets
GROUP BY sprint
ORDER BY sprint;

CREATE OR REPLACE VIEW sprint_risk_dashboard AS

SELECT
    sprint,

    ROUND(
        100 * SUM(
            CASE
                WHEN status = 'Done' THEN story_points
                ELSE 0
            END
        ) / NULLIF(SUM(story_points), 0),
        2
    ) AS completion_percentage,

    SUM(
        issue_type = 'Bug'
        AND status <> 'Done'
    ) AS open_bugs,

    SUM(
        blocked = 'Yes'
        AND status <> 'Done'
    ) AS blocked_tickets,

    COUNT(*) AS total_tickets,

    ROUND(
        100 * SUM(
            blocked = 'Yes'
            AND status <> 'Done'
        ) / COUNT(*),
        2
    ) AS blocked_percentage,

    CASE
        WHEN
            100 * SUM(
                CASE
                    WHEN status = 'Done' THEN story_points
                    ELSE 0
                END
            ) / NULLIF(SUM(story_points), 0) < 45
            OR
            100 * SUM(
                blocked = 'Yes'
                AND status <> 'Done'
            ) / COUNT(*) >= 10
        THEN 'High Risk'

        WHEN
            100 * SUM(
                CASE
                    WHEN status = 'Done' THEN story_points
                    ELSE 0
                END
            ) / NULLIF(SUM(story_points), 0) < 55
        THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_level

FROM tickets
GROUP BY sprint
ORDER BY sprint;

SELECT *
FROM sprint_risk_dashboard;

SELECT *
FROM tickets;

SELECT *
FROM sprint_risk_dashboard;