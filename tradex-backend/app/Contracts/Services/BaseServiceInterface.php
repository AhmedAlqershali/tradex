<?php

namespace App\Contracts\Services;

use Illuminate\Support\Collection;

/**
 * Base contract that every Service class must implement.
 *
 * Phase 2+: concrete services go in app/Services/
 */
interface BaseServiceInterface
{
    public function all(): Collection;

    public function findById(int $id): mixed;

    public function create(array $data): mixed;

    public function update(int $id, array $data): bool;

    public function delete(int $id): bool;
}
