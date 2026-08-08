<?php

namespace Tests;

use App\Models\Subscription;
use App\Models\Plan;
use App\Models\User;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Support\Facades\Http;

abstract class TestCase extends BaseTestCase
{
    /**
     * Fake the HaveIBeenPwned API globally for all tests.
     *
     * The `uncompromised()` password rule hits api.pwnedpasswords.com.
     * During tests the rule would flag common test passwords like
     * "Password123!" as compromised (they genuinely appear in breach
     * databases), causing unrelated tests to fail with a 422.
     *
     * We return an empty response body (0 matches) so the rule always
     * passes in the test environment, matching real-world behaviour for
     * a unique, newly-generated password.
     */
    protected function setUp(): void
    {
        parent::setUp();

        Http::fake([
            'https://api.pwnedpasswords.com/*' => Http::response('', 200),
        ]);
    }

    /**
     * Give a merchant the entitlement required by merchant business routes.
     */
    protected function entitleMerchant(User $merchant): Subscription
    {
        $plan = Plan::factory()->active()->create([
            'ai_usage_limit' => null,
        ]);

        return Subscription::factory()
            ->forUser($merchant)
            ->active()
            ->forPlan($plan)
            ->create();
    }
}
