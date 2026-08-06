<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Traits\ApiResponseTrait;

/**
 * Base controller for all API v1 controllers.
 *
 * Every controller in this namespace should extend BaseApiController.
 *
 * Phase 2+: add shared middleware, auth checks, etc. here.
 */
abstract class BaseApiController extends Controller
{
    use ApiResponseTrait;
}
