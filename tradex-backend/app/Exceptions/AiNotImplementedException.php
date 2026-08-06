<?php

namespace App\Exceptions;

use Exception;

class AiNotImplementedException extends Exception
{
    protected $message = "AI provider or feature is not implemented.";
}
