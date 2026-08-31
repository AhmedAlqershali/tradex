<?php

namespace Tests\Unit;

use App\Models\ProductImage;
use App\Support\PublicMediaUrl;
use PHPUnit\Framework\TestCase;

class ExampleTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config()->set('app.url', 'http://localhost');
    }

    public function test_public_media_url_is_canonicalized_for_product_images(): void
    {
        config()->set('app.url', 'http://localhost');

        $image = new ProductImage([
            'path' => '/storage/products/123/abc.jpg',
        ]);

        $this->assertSame(
            PublicMediaUrl::origin() . '/storage/products/123/abc.jpg',
            $image->url,
        );
    }
}
