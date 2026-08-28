<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // ── AI Provider (OpenAI-compatible) ───────────────────────────────────────
    // Retained for reference / fallback. Swap the binding in
    // RepositoryServiceProvider to switch between providers.
    'openai' => [
        'key'      => env('OPENAI_API_KEY',   ''),
        'model'    => env('OPENAI_MODEL',     'gpt-4o-mini'),
        'base_url' => env('OPENAI_BASE_URL',  'https://api.openai.com/v1'),
    ],

    // ── OpenRouter (OpenAI-compatible, live verification only) ─────────────────
    'openrouter' => [
        'key'      => env('OPENROUTER_API_KEY', ''),
        'model'    => env('OPENROUTER_MODEL', 'openrouter/free'),
        'base_url' => env('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1'),
    ],

    // Gemini remains the default provider. Set AI_PROVIDER=openrouter only for
    // a temporary OpenRouter verification process.
    'ai_provider' => env('AI_PROVIDER', 'gemini'),

    // ── Google Gemini ─────────────────────────────────────────────────────────
    // Active AI provider. GeminiProviderService is bound to AiProviderInterface
    // in RepositoryServiceProvider.
    //   GEMINI_API_KEY   — required; obtain from https://aistudio.google.com/app/apikey
    //   GEMINI_MODEL     — default: gemini-3.6-flash (fast, low-cost)
    //   GEMINI_BASE_URL  — Gemini REST base; change only if using a VPC proxy
    'gemini' => [
        'key'      => env('GEMINI_API_KEY',   ''),
        'model'    => env('GEMINI_MODEL',     'gemini-3.6-flash'),
        'base_url' => env('GEMINI_BASE_URL',  'https://generativelanguage.googleapis.com/v1beta'),
    ],

    'fcm' => [
        'project_id' => env('FIREBASE_PROJECT_ID'),
        'credentials' => env('FIREBASE_CREDENTIALS'),
    ],

];
