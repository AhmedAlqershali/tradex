<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

class VerifyExistingUsers extends Command
{
    private const EMAILS = [
        'abunael29@gmail.com',
        'abunael28@gmail.com',
    ];

    protected $signature = 'users:verify-existing';

    protected $description = 'Verify the two explicitly approved existing user accounts';

    public function handle(): int
    {
        foreach (self::EMAILS as $email) {
            $user = User::query()->where('email', $email)->first();

            if (! $user) {
                $this->line("{$email}: not found; no account created.");

                continue;
            }

            if ($user->hasVerifiedEmail()) {
                $this->line("{$email}: already verified; no change.");

                continue;
            }

            $user->markEmailAsVerified();
            $this->line("{$email}: marked as verified.");
        }

        return self::SUCCESS;
    }
}