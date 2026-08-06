<?php

namespace App\Contracts\Repositories;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Collection;

/**
 * Base contract that every Eloquent repository must implement.
 *
 * Phase 2+: concrete repositories go in app/Repositories/Eloquent/
 */
interface BaseRepositoryInterface
{
    public function all(): Collection;

    public function findById(int $id): ?Model;

    public function create(array $data): Model;

    public function update(int $id, array $data): bool;

    public function delete(int $id): bool;
}
