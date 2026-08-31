<?php

namespace Tests\Feature\Console;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class VerifyExistingUsersCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_verifies_only_the_two_existing_target_accounts(): void
    {
        $first = User::factory()->unverified()->create(['email' => 'abunael29@gmail.com']);
        $second = User::factory()->unverified()->create(['email' => 'abunael28@gmail.com']);
        $unrelated = User::factory()->unverified()->create(['email' => 'other@example.com']);

        $this->artisan('users:verify-existing')
            ->expectsOutput('abunael29@gmail.com: marked as verified.')
            ->expectsOutput('abunael28@gmail.com: marked as verified.')
            ->assertExitCode(0);

        $this->assertNotNull($first->fresh()->email_verified_at);
        $this->assertNotNull($second->fresh()->email_verified_at);
        $this->assertNull($unrelated->fresh()->email_verified_at);
        $this->assertSame(3, User::query()->count());
    }

    public function test_it_does_not_create_missing_accounts(): void
    {
        User::factory()->unverified()->create(['email' => 'other@example.com']);

        $this->artisan('users:verify-existing')
            ->expectsOutput('abunael29@gmail.com: not found; no account created.')
            ->expectsOutput('abunael28@gmail.com: not found; no account created.')
            ->assertExitCode(0);

        $this->assertSame(1, User::query()->count());
    }

    public function test_running_it_twice_is_idempotent(): void
    {
        $first = User::factory()->unverified()->create(['email' => 'abunael29@gmail.com']);
        $second = User::factory()->unverified()->create(['email' => 'abunael28@gmail.com']);

        $this->artisan('users:verify-existing')->assertExitCode(0);

        $firstVerifiedAt = $first->fresh()->email_verified_at;
        $secondVerifiedAt = $second->fresh()->email_verified_at;

        $this->artisan('users:verify-existing')
            ->expectsOutput('abunael29@gmail.com: already verified; no change.')
            ->expectsOutput('abunael28@gmail.com: already verified; no change.')
            ->assertExitCode(0);

        $this->assertTrue($firstVerifiedAt->equalTo($first->fresh()->email_verified_at));
        $this->assertTrue($secondVerifiedAt->equalTo($second->fresh()->email_verified_at));
        $this->assertSame(2, User::query()->count());
    }

    public function test_email_verification_requirement_remains_enabled_for_other_users(): void
    {
        $user = User::factory()->unverified()->create([
            'email'    => 'other@example.com',
            'password' => bcrypt('Password123!'),
            'status'   => 'active',
            'role'     => 'client',
        ]);

        $this->artisan('users:verify-existing')->assertExitCode(0);

        $this->postJson('/api/v1/auth/login', [
            'email'    => $user->email,
            'password' => 'Password123!',
        ])
            ->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'يرجى تأكيد بريدك الإلكتروني أولًا.')
            ->assertJsonMissingPath('data.token');

        $this->assertNull($user->fresh()->email_verified_at);
    }

    public function test_entrypoint_runs_the_command_only_when_explicitly_enabled(): void
    {
        $entrypoint = file_get_contents(base_path('docker/entrypoint.sh'));

        $this->assertIsString($entrypoint);
        $this->assertStringContainsString('if [ "${VERIFY_EXISTING_USERS:-}" = "true" ]; then', $entrypoint);
        $this->assertStringContainsString('php artisan users:verify-existing', $entrypoint);
        $this->assertStringContainsString('fi', $entrypoint);
    }
}