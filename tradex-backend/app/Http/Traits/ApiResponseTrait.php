<?php

namespace App\Http\Traits;

use Illuminate\Http\JsonResponse;

/**
 * Standardises all API JSON responses.
 *
 * Usage: add `use ApiResponseTrait;` inside any API controller.
 */
trait ApiResponseTrait
{
    /**
     * 200 success response.
     */
    protected function success(mixed $data = null, string $message = 'Success', int $status = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data'    => $data,
        ], $status);
    }

    /**
     * 201 created response.
     */
    protected function created(mixed $data = null, string $message = 'Resource created successfully.'): JsonResponse
    {
        return $this->success($data, $message, 201);
    }

    /**
     * Generic error response.
     */
    protected function error(string $message = 'An error occurred.', int $status = 400, mixed $errors = null): JsonResponse
    {
        $payload = [
            'success' => false,
            'message' => $message,
            'data'    => null,
        ];

        if (! is_null($errors)) {
            $payload['errors'] = $errors;
        }

        return response()->json($payload, $status);
    }

    /**
     * 404 not found response.
     */
    protected function notFound(string $message = 'Resource not found.'): JsonResponse
    {
        return $this->error($message, 404);
    }

    /**
     * 422 validation error response.
     */
    protected function validationError(mixed $errors, string $message = 'Validation failed.'): JsonResponse
    {
        return $this->error($message, 422, $errors);
    }

    /**
     * 401 unauthenticated response.
     */
    protected function unauthenticated(string $message = 'Unauthenticated.'): JsonResponse
    {
        return $this->error($message, 401);
    }

    /**
     * 403 forbidden response.
     */
    protected function forbidden(string $message = 'Forbidden.'): JsonResponse
    {
        return $this->error($message, 403);
    }

    /**
     * 500 server error response.
     */
    protected function serverError(string $message = 'Internal server error.'): JsonResponse
    {
        return $this->error($message, 500);
    }
}
