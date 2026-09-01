<?php

namespace App\Listeners;

use Illuminate\Queue\Events\JobFailed;
use Illuminate\Support\Facades\Log;

class QueueJobFailed
{
    /**
     * Handle the event.
     *
     * Logs failed queue jobs with diagnostic information (without secrets).
     * Provides clear exception details for troubleshooting.
     */
    public function handle(JobFailed $event): void
    {
        $exception = $event->exception;
        $payload = $event->job->payload();

        // Extract job class name safely
        $jobClass = $payload['displayName'] ?? ($payload['job'] ?? 'unknown');

        // Format clear diagnostic message for logs
        $diagnosticMessage = sprintf(
            "[QUEUE JOB FAILED] Job: %s | Exception: %s | Message: %s | File: %s:%d",
            $jobClass,
            $exception::class,
            $exception->getMessage(),
            $exception->getFile(),
            $exception->getLine()
        );

        Log::error($diagnosticMessage);

        // Also log structured array for log aggregation systems
        Log::error('Queue job failed', [
            'job_class' => $jobClass,
            'queue' => $event->job->getQueue(),
            'attempts' => $payload['attempts'] ?? 'unknown',
            'max_tries' => $payload['maxTries'] ?? 'unknown',
            'timeout' => $payload['timeout'] ?? 'unknown',
            'exception_class' => $exception::class,
            'exception_message' => $exception->getMessage(),
            'exception_file' => $exception->getFile(),
            'exception_line' => $exception->getLine(),
        ]);
    }
}
