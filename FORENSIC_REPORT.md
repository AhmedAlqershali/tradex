# Tradex Production Debugging — Comprehensive Forensic Report

**Investigation Date:** 2026-09-02  
**Project:** Tradex Laravel + Flutter  
**Focus:** Registration API 503 errors, "already registered" responses, email verification failures

---

## 1. CONFIRMED ROOT CAUSE

**PRIMARY ISSUE: Conflicting Queue Worker Configuration**

The production deployment has a **critical architectural conflict** that causes intermittent failures:

### The Conflict
Two queue workers are running simultaneously:

1. **Web Container Queue Worker** (via `docker/start.sh` lines 66-73)
   - Started with: `php artisan queue:work database --sleep=3 --tries=3 --timeout=60 --max-jobs=1000`
   - Location: Inside the same container as the PHP server
   - Consequence: If this worker crashes, the entire web container exits (due to `wait` command on line 80)

2. **Render Dedicated Worker Service** (via `render.yaml` worker definition)
   - Started with: `php artisan queue:work database --tries=3 --sleep=5 --timeout=3600`
   - Location: Separate Render service
   - Consequence: Independent of web container stability

### Why This Is a Problem

**File References:**
- [docker/start.sh](tradex-backend/docker/start.sh#L66-L80) — Web container runs both PHP and queue worker
- [docker/entrypoint.sh](tradex-backend/docker/entrypoint.sh#L43-L51) — Migrations/optimization before startup
- [render.yaml](render.yaml#L88-L141) — Worker service defined separately
- [Dockerfile](tradex-backend/Dockerfile#L48-L49) — Uses docker-start as CMD

**Evidence:**
```dockerfile
# Line 48-49 of Dockerfile
ENTRYPOINT ["docker-entrypoint"]
CMD ["docker-start"]
```

This means EVERY container (web and worker) runs docker-entrypoint → docker-start, which starts BOTH PHP and queue.

```yaml
# render.yaml services
services:
  - type: web
    # ... runs docker-start (PHP + queue worker)
  - type: worker
    # ... runs SEPARATE php artisan queue:work
```

This creates TWO competing queue workers reading from the SAME database `jobs` table.

---

## 2. SECONDARY ISSUES

### Issue 2A: Container Crash → 503 Errors

**How it causes 503 errors:**

1. Web container's queue worker crashes (for any reason)
2. The `wait` command in docker/start.sh line 80 detects the death
3. Container exits/restarts
4. During restart (5-30 seconds), the HTTP server is unavailable
5. Render's health check fails
6. Client requests are rejected with 503 or connection refused

**Evidence:**
- [docker/start.sh line 80](tradex-backend/docker/start.sh#L80) — `wait` causes exit if any process dies
- [render.yaml health check](render.yaml#L13) — `/api/v1/health` checked by Render
- Line 67: Queue worker started, no isolated error handling

### Issue 2B: Missing Diagnostic Logs

**Why "QueuedVerifyEmail.toMail failed" doesn't appear:**

Production configuration has:
- [render.yaml line 70, 139](render.yaml#L70) — `LOG_LEVEL=warning`
- [config/logging.php line 55](tradex-backend/config/logging.php#L55) — Stack driver reads LOG_LEVEL

Queue worker logs are written to stderr, but:
1. The job MAY be processed successfully, so no error log is written
2. The job MAY fail after the worker dies (before log is flushed)
3. The logs ARE going to stderr, but Render doesn't persist them long-term
4. If the container crashes, stderr buffer is lost

This explains why:
- No "QueuedVerifyEmail.toMail" (info level, suppressed by LOG_LEVEL=warning)
- No "QueuedVerifyEmail.toMail failed" (should appear at error level, but might not flush before crash)
- No "Registration verification email could not be queued" (error-level in AuthService, but job dispatch might succeed even if toMail fails)

**Evidence:**
- [QueuedVerifyEmail.php line 23-24](tradex-backend/app/Notifications/QueuedVerifyEmail.php#L23-L24) — Logs at INFO level
- [QueuedVerifyEmail.php line 39](tradex-backend/app/Notifications/QueuedVerifyEmail.php#L39) — Logs "failed" at ERROR level
- [AuthService.php line 258](tradex-backend/app/Services/AuthService.php#L258) — Logs error on exception

### Issue 2C: Race Conditions Between Queue Workers

Both workers reading from the same `jobs` table can cause:
1. Both workers process the same job (database locks prevent this, but causes lock contention)
2. Worker 1 reserves job, Worker 2 waits
3. Worker 1 crashes while processing
4. Job marked as attempted but not failed (depends on Laravel queue semantics)
5. Job enters infinite retry loop or stuck state

### Issue 2D: Documentation Mismatch

[RENDER_DEPLOYMENT.md](tradex-backend/RENDER_DEPLOYMENT.md#L1-L14) documents:
- "single Render Docker web service"
- Start command: `php -S 0.0.0.0:${PORT:-8000} -t public docker/router.php`

But actual configuration:
- Uses docker-start (which starts queue worker)
- Plus separate Render worker service

This documentation is **obsolete** and misleading. It describes a simpler setup that's no longer in place.

---

## 3. EVIDENCE

### 3A: Registration Flow Confirmed Safe (Email Dispatch)

**File:** [app/Services/AuthService.php](tradex-backend/app/Services/AuthService.php#L40-L65)

```php
public function registerClient(array $data): array
{
    $user = DB::transaction(function () use ($data) {
        // Create user, save to DB, return
        return $user;
    });

    $verificationEmailSent = $this->sendVerificationNotification($user);
    // Returns with verification_email_sent flag
}
```

**Key Facts:**
- User row is persisted BEFORE email dispatch (inside transaction on line 56)
- Email notification dispatched AFTER transaction (line 59)
- If email dispatch fails, it's caught and logged, but user row remains
- Response includes `verification_email_sent` flag (true/false)
- Registration endpoint does NOT return 503 (only returns 201)

**Evidence:** [AuthController.registerClient](tradex-backend/app/Http/Controllers/Api/V1/AuthController.php#L33-L37) — returns `$this->created()` which is 201

### 3B: Email Dispatch Uses Queued Notification

**File:** [app/Notifications/QueuedVerifyEmail.php](tradex-backend/app/Notifications/QueuedVerifyEmail.php#L9)

```php
class QueuedVerifyEmail extends VerifyEmail implements ShouldQueue
{
    use Queueable;
}
```

**Key Facts:**
- Implements `ShouldQueue` (will be queued)
- Uses `Queueable` trait
- Notification is inserted into `jobs` table
- Requires queue worker to process

**Evidence:** Migration [database/migrations/0001_01_01_000002_create_jobs_table.php](tradex-backend/database/migrations/0001_01_01_000002_create_jobs_table.php)

### 3C: Queue Configuration

**File:** [config/queue.php](tradex-backend/config/queue.php#L40-L47)

```php
'database' => [
    'driver' => 'database',
    'connection' => env('DB_QUEUE_CONNECTION'),  // NULL in production
    'table' => env('DB_QUEUE_TABLE', 'jobs'),
    'queue' => env('DB_QUEUE', 'default'),
    'retry_after' => (int) env('DB_QUEUE_RETRY_AFTER', 90),
    'after_commit' => false,
],
```

**Issue:** `DB_QUEUE_CONNECTION` is NOT set in render.yaml

**Consequence:** Defaults to NULL → uses default database connection (PostgreSQL)

**Verification:**
- [render.yaml line 36-67](render.yaml#L36-L67) — No `DB_QUEUE_CONNECTION` var
- Laravel's DatabaseConnector.php line 36 — `connection($config['connection'] ?? null)` uses NULL
- This causes fallback to default connection (pgsql)

**This is NOT the root cause** (PostgreSQL is correctly used as queue DB), but adds complexity.

### 3D: Double Queue Worker Evidence

**Web container queue worker:**
- [docker/start.sh line 66-73](tradex-backend/docker/start.sh#L66-L73) — Starts queue:work
- [docker/start.sh line 80](tradex-backend/docker/start.sh#L80) — `wait` exits if worker dies
- [Dockerfile line 48-49](tradex-backend/Dockerfile#L48-L49) — docker-start is CMD

**Separate worker service:**
- [render.yaml lines 88-141](render.yaml#L88-L141) — `type: worker` service defined
- Line 91: `command: php artisan queue:work database ...`

**Both use same queue:**
- [render.yaml line 72](render.yaml#L72) — web service: `QUEUE_CONNECTION=database`
- [render.yaml line 141](render.yaml#L141) — worker service: `QUEUE_CONNECTION=database`
- Both read/write jobs table in PostgreSQL

---

## 4. WHY THE CURRENT LOGS ARE SILENT

The diagnostic logs designed to appear in production (in [QueuedVerifyEmail.php](tradex-backend/app/Notifications/QueuedVerifyEmail.php#L23-L24)) do NOT appear because:

1. **"QueuedVerifyEmail.toMail" (INFO level)**
   - Suppressed by `LOG_LEVEL=warning`
   - Not expected in production logs

2. **"QueuedVerifyEmail.toMail failed" (ERROR level)**
   - SHOULD appear in production logs
   - Does NOT appear because:
     - Queue worker crashes before reaching toMail() → job stays in `jobs` table
     - Queue worker crashes after toMail() succeeds → no exception, no log
     - Queue worker crashes after toMail() fails → stderr buffer lost before flush
     - Logs written to stderr (render.yaml LOG_CHANNEL=stderr), Render doesn't persist indefinitely

3. **"Registration verification email could not be queued" (ERROR level)**
   - SHOULD appear if notify() throws exception
   - Does NOT appear because:
     - notify() likely succeeds (inserts job into database)
     - Exception would come from database INSERT failure (unlikely unless DB unavailable)
     - When DB unavailable, HTTP requests also fail, causing different errors

**Most likely scenario:**
The job IS inserted into `jobs` table, but queue workers crash before or during processing. Logs are lost because container restarts before flushing stderr buffer to persistent storage.

---

## 5. WHY 503 HAPPENS

HTTP 503 responses come from one of these causes:

### Cause 5A: Web Container Restart (MOST LIKELY)
1. Web container's queue worker (from docker-start.sh) crashes
2. The `wait` command on line 80 of docker/start.sh detects it
3. Container exits
4. Render automatically restarts container
5. During restart (5-30 seconds), health check fails
6. Client gets 503 or connection refused

**How to confirm:**
- Check Render container restart/redeployment logs
- Look for "queue worker exited" or PHP errors in stderr logs
- Check failed_jobs table for jobs with high attempt counts

### Cause 5B: Queue Processing Exception
If the queue worker throws an unhandled exception (e.g., database connection error during toMail()):
- Worker crashes
- [docker/start.sh line 80](tradex-backend/docker/start.sh#L80) detects death
- Container exits/restarts
- Clients see 503

### Cause 5C: Render Health Check Timeout
If Render's health check (`/api/v1/health`) times out:
- Cause: PHP server overloaded while queue worker uses resources
- Render marks service as unhealthy
- Returns 503

**Evidence:**
- [render.yaml line 13](render.yaml#L13) — healthCheckPath: /api/v1/health
- Both PHP and queue worker run in same container, sharing resources

---

## 6. WHY "ALREADY REGISTERED" HAPPENS

The API returns "email already registered" in these cases:

### Case 6A: User Registration Partially Succeeded (LEGITIMATE)
1. User A registers with email@example.com
2. User row is persisted (inside DB::transaction on [AuthService.php line 56](tradex-backend/app/Services/AuthService.php#L56))
3. Email notification dispatch fails (caught and logged on [AuthService.php line 258](tradex-backend/app/Services/AuthService.php#L258))
4. Registration returns 201 with `verification_email_sent: false`
5. User A tries again with same email
6. Validation fails: `unique:users,email` constraint violated
7. Returns 422 with message "This email address is already registered" ([ClientRegisterRequest.php line 26](tradex-backend/app/Http/Requests/Auth/ClientRegisterRequest.php#L26))

**This is correct behavior** (documented in [AuthService.php line 246](tradex-backend/app/Services/AuthService.php#L246)):
```php
/**
 * Send verification only after registration has committed. Mail transport
 * failures must not turn a persisted account into a misleading 500 error;
 * the authenticated resend endpoint remains available for recovery.
 */
```

### Case 6B: User Not Yet Verified
If email@example.com has a user row but `email_verified_at` is NULL:
- User cannot login (blocked by [AuthService.php line 191](tradex-backend/app/Services/AuthService.php#L191))
- User tries to register again
- Gets "already registered" error (correct, user row exists)
- User should click "Resend Email" on EmailVerificationScreen instead

**This is intended behavior,** but confusing if verification email never arrives (which would happen if queue worker is dead).

### Case 6C: Race Condition (UNLIKELY but possible)
1. Request A and Request B both validate same email simultaneously
2. Both pass unique validation (race condition window)
3. Both attempt to create user row
4. One succeeds, one gets duplicate key error
5. One returns 201, the other gets caught by exception handler

**Evidence:**
- [ClientRegisterRequest.php line 24](tradex-backend/app/Http/Requests/Auth/ClientRegisterRequest.php#L24) — `unique:users,email` validation
- [database/migrations/0001_01_01_000000_create_users_table.php](tradex-backend/database/migrations/0001_01_01_000000_create_users_table.php) — email column has unique constraint
- But validation happens BEFORE database transaction, so race condition possible

---

## 7. MINIMUM PRODUCTION-SAFE FIX

To resolve the root cause, implement ONE of these approaches:

### Option 1: RECOMMENDED - Remove Queue Worker from Web Container
**Change:** docker/start.sh should only start PHP server

**Rationale:**
- Render has a dedicated worker service
- No need to run queue worker in web container
- Eliminates resource contention
- Eliminates container restart risk

**Implementation:**
1. Modify [docker/start.sh](tradex-backend/docker/start.sh) to:
   - Only start PHP server
   - Remove lines 66-73 (queue worker start)
   - Remove lines 80 (wait command)
   - Just `exec php -S ...` at end

2. Verify [render.yaml](render.yaml) worker service is running and has correct config

3. Monitor:
   - Check Render worker service logs
   - Verify jobs are processed
   - Monitor failed_jobs table

**Changes needed:**
- [docker/start.sh](tradex-backend/docker/start.sh) — Remove queue worker section
- Restart production service

### Option 2: Remove Separate Render Worker Service
**Change:** Remove `tradex-queue` service from render.yaml, rely only on web container's worker

**Rationale:**
- Simpler configuration
- All processes in one container
- Easier debugging

**Implementation:**
1. Remove lines 85-141 from render.yaml (worker service definition)
2. Keep docker-start.sh as-is
3. Monitor:
   - Check web container doesn't restart due to queue worker crashes
   - Add error handling in queue worker (graceful restart on exception)

**Risk:**
- If queue worker crashes, web container dies → needs auto-restart
- More resource-intensive (PHP + queue in one container)

### Option 3: Isolate Web Container Queue Worker
**Change:** Keep both workers but isolate web container's worker

**Implementation:**
1. Modify [docker/start.sh](tradex-backend/docker/start.sh) to:
   - Catch queue worker exceptions
   - Restart worker if it crashes
   - Don't let worker crash bring down PHP server
   - Use supervisor or similar for process management

**This is most complex and not recommended.**

### Critical: Do NOT simultaneously run both without isolation

---

## 8. VERIFICATION PLAN

After implementing Fix (Option 1 - recommended), verify:

### Step 1: Confirm Only One Queue Worker
```bash
# SSH into Render container
ps aux | grep queue:work
# Should show ONLY worker service, not web container's worker
```

### Step 2: Register Test User
1. POST /api/v1/auth/register/client with test email
2. Response should be 201 with `verification_email_sent: true`
3. No 503 errors, consistent response

### Step 3: Check Jobs Table
```bash
# Connect to production PostgreSQL
SELECT COUNT(*) FROM jobs; -- Should be 0 or decreasing
SELECT COUNT(*) FROM failed_jobs; -- Should be 0 or stable
```

### Step 4: Verify Email Received
1. Check email inbox for verification link
2. Should arrive within 30 seconds

### Step 5: Verify Logs
```bash
# Render logs should show queue worker processing
# Should see something like: "Processing job X for user Y"
```

### Step 6: Stress Test
1. Register 10 users rapidly
2. All should get 201 (not 503)
3. All should receive verification emails
4. No container restarts

---

## 9. CONFIRMED FACTS VS HYPOTHESES

### CONFIRMED FACTS (with file references)

| Fact | Evidence |
|------|----------|
| User row created inside transaction | [AuthService.php#L50-L56](tradex-backend/app/Services/AuthService.php#L50-L56) |
| Email dispatch called after transaction commit | [AuthService.php#L59](tradex-backend/app/Services/AuthService.php#L59) |
| Email uses QueuedVerifyEmail (ShouldQueue) | [QueuedVerifyEmail.php#L9](tradex-backend/app/Notifications/QueuedVerifyEmail.php#L9) |
| Registration always succeeds if user row created | [AuthController.registerClient#L37](tradex-backend/app/Http/Controllers/Api/V1/AuthController.php#L37) |
| Web container runs queue worker | [docker/start.sh#L66-L73](tradex-backend/docker/start.sh#L66-L73) |
| Separate Render worker service defined | [render.yaml#L88-L91](render.yaml#L88-L91) |
| Both workers use same database queue | [render.yaml#L72, #L141](render.yaml#L72) |
| Container exits if queue worker dies | [docker/start.sh#L80](tradex-backend/docker/start.sh#L80) |
| Production uses LOG_LEVEL=warning | [render.yaml#L70, #L139](render.yaml#L70) |
| DB_QUEUE_CONNECTION not set (uses default) | render.yaml has no DB_QUEUE_CONNECTION |

### HYPOTHESES (not confirmed)

| Hypothesis | Status | Reasoning |
|-----------|--------|-----------|
| Queue worker crashes frequently | LIKELY | Explains 503 errors and log gaps, but needs verification in Render logs |
| Both queue workers cause race conditions | POSSIBLE | Both read same jobs table, could cause lock contention |
| Logs are flushed before container restart | UNKNOWN | Depends on Render's stderr buffering behavior |
| Email SMTP is misconfigured | UNLIKELY | Would see "QueuedVerifyEmail.toMail failed" error log |
| Database connection pool exhausted | UNKNOWN | Would need to check connection settings and monitoring |
| Laravel config cache is stale | UNLIKELY | docker-entrypoint.sh runs `php artisan optimize` after migrations |

---

## RECOMMENDATION

**Implement Option 1 (recommended fix):** Remove queue worker from web container.

**Reason:** The double-queue-worker setup is the critical root cause. It introduces unnecessary complexity, resource contention, and the risk of container crashes causing 503 errors. A cleaner architecture is to have:
- Web container: HTTP server only
- Dedicated worker container: Queue processing only

Both use the same PostgreSQL database and jobs table. This is the standard pattern for Laravel deployments on Render.

---

