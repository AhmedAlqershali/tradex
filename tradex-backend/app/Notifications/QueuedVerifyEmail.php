<?php

namespace App\Notifications;

use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\Log;

class QueuedVerifyEmail extends VerifyEmail implements ShouldQueue
{
    use Queueable;

    /**
     * Override toMail to add diagnostic logging.
     * Logs mailer configuration (without secrets) and any exceptions.
     */
    public function toMail($notifiable)
    {
        try {
            $config = config('mail');
            $mailer = $config['default'] ?? 'unknown';
            $mailerConfig = $config['mailers'][$mailer] ?? [];

            Log::info('QueuedVerifyEmail.toMail', [
                'notifiable_id' => $notifiable?->getKey(),
                'notifiable_email' => $notifiable?->getEmailForVerification(),
                'default_mailer' => $mailer,
                'mailer_transport' => $mailerConfig['transport'] ?? 'unknown',
                'smtp_host' => $mailerConfig['host'] ?? 'default',
                'smtp_port' => $mailerConfig['port'] ?? 'default',
                'smtp_scheme' => $mailerConfig['scheme'] ?? 'not set',
                'smtp_timeout' => $mailerConfig['timeout'] ?? 'not set',
            ]);

            return parent::toMail($notifiable);
        } catch (\Throwable $e) {
            Log::error('QueuedVerifyEmail.toMail failed', [
                'notifiable_id' => $notifiable?->getKey() ?? 'unknown',
                'exception' => $e::class,
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            throw $e;
        }
    }

    public function failed(\Throwable $e): void
    {
        $config = config('mail');
        $mailer = $config['default'] ?? 'unknown';
        $mailerConfig = $config['mailers'][$mailer] ?? [];

        Log::error('QueuedVerifyEmail job failed', [
            'exception' => $e::class,
            'message' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine(),
            'trace' => substr($e->getTraceAsString(), 0, 4000),
            'default_mailer' => $mailer,
            'mailer_transport' => $mailerConfig['transport'] ?? 'unknown',
            'smtp_host' => $mailerConfig['host'] ?? 'default',
            'smtp_port' => $mailerConfig['port'] ?? 'default',
            'smtp_scheme' => $mailerConfig['scheme'] ?? 'not set',
            'mail_from_address' => $config['from']['address'] ?? 'not set',
            'mail_from_name' => $config['from']['name'] ?? 'not set',
        ]);
    }
}
