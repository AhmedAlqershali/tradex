<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Platform commission rate
    |--------------------------------------------------------------------------
    |
    | This is the single source of truth for the platform commission.
    | The value is stored as a readable percentage for historical snapshots,
    | and arithmetic converts it to a decimal only at calculation time.
    |
    */

    'rate_percentage' => 5.00,
];
