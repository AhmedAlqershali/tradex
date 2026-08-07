<?php

namespace Tests\Feature\AI;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Exceptions\AiProviderException;
use App\Providers\RepositoryServiceProvider;
use App\Services\AI\GeminiProviderService;
use App\Services\AI\OpenRouterProviderService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class OpenRouterProviderTest extends TestCase
{
    use RefreshDatabase;

    public function test_openrouter_provider_throws_when_api_key_is_missing(): void
    {
        config(['services.openrouter.key' => '']);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessageMatches('/OPENROUTER_API_KEY/');

        (new OpenRouterProviderService())->complete('system prompt', 'user prompt');
    }

    public function test_openrouter_provider_parses_successful_response(): void
    {
        config([
            'services.openrouter.key'   => 'fake-test-key',
            'services.openrouter.model' => 'openrouter/free',
        ]);

        Http::fake([
            'https://openrouter.ai/api/v1/chat/completions' => Http::response([
                'id'      => 'test-completion',
                'model'   => 'openrouter/free',
                'choices' => [
                    ['message' => ['role' => 'assistant', 'content' => 'A useful response.']],
                ],
                'usage' => [
                    'prompt_tokens'     => 12,
                    'completion_tokens' => 8,
                    'total_tokens'      => 20,
                    'cost'              => 0,
                ],
            ], 200),
        ]);

        $result = (new OpenRouterProviderService())->complete('You are helpful.', 'Say hello.');

        $this->assertSame('A useful response.', $result['result']);
        $this->assertSame(20, $result['tokens_used']);
        $this->assertSame(0.0, $result['cost_usd']);

        Http::assertSent(function ($request): bool {
            return $request->hasHeader('Authorization', 'Bearer fake-test-key')
                && $request['model'] === 'openrouter/free'
                && $request['messages'][0]['role'] === 'system'
                && $request['messages'][1]['role'] === 'user';
        });
    }

    public function test_openrouter_provider_rejects_empty_response(): void
    {
        config(['services.openrouter.key' => 'fake-test-key']);

        Http::fake([
            '*' => Http::response(['choices' => [['message' => ['content' => '']]]], 200),
        ]);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessageMatches('/empty response/i');

        (new OpenRouterProviderService())->complete('system prompt', 'user prompt');
    }

    public function test_openrouter_provider_surfaces_provider_errors_without_exposing_key(): void
    {
        config(['services.openrouter.key' => 'fake-test-key']);

        Http::fake([
            '*' => Http::response(['error' => ['message' => 'Free model unavailable.']], 429),
        ]);

        try {
            (new OpenRouterProviderService())->complete('system prompt', 'user prompt');
            $this->fail('Expected an OpenRouter provider exception.');
        } catch (AiProviderException $e) {
            $this->assertStringContainsString('Free model unavailable.', $e->getMessage());
            $this->assertStringNotContainsString('fake-test-key', $e->getMessage());
        }
    }

    public function test_provider_binding_defaults_to_gemini_and_switches_to_openrouter(): void
    {
        config(['services.ai_provider' => 'gemini']);
        $this->assertInstanceOf(GeminiProviderService::class, $this->app->make(AiProviderInterface::class));

        config(['services.ai_provider' => 'openrouter']);
        $this->assertInstanceOf(OpenRouterProviderService::class, $this->app->make(AiProviderInterface::class));
    }
}