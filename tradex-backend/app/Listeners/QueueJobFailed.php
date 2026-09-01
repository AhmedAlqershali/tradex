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
     */
    public function handle(JobFailed $event): void
    {
        $exception = $event->exception;
        $payload = $event->job->payload();

        // Extract job class name safely
        $jobClass = $payload['displayName'] ?? ($payload['job'] ?? 'unknown');

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
