<?php
// Served only inside the disposable smoke-test container, never copied into the image.
try {
    foreach (['Redis' => 'redis', 'Memcached' => 'memcached', 'Imagick' => 'imagick'] as $class => $extension) {
        $reflection = new ReflectionClass($class);
        if (!$reflection->isInternal() || $reflection->getExtensionName() !== $extension) {
            throw new RuntimeException("$class must come from the native $extension extension");
        }
    }
    if (phpversion('redis') !== '6.3.0' || phpversion('memcached') !== '3.4.0' || phpversion('imagick') !== '3.8.1') {
        throw new RuntimeException('Unexpected native extension version');
    }
    $redis = new Redis();
    $redis->setOption(Redis::OPT_SERIALIZER, Redis::SERIALIZER_PHP);
    $data = ['native' => true];
    if ($redis->_unserialize($redis->_serialize($data)) !== $data) {
        throw new RuntimeException('phpredis serialization failed');
    }
    $memcached = new Memcached();
    if (!$memcached->addServer('127.0.0.1', 11211) || count($memcached->getServerList()) !== 1) {
        throw new RuntimeException('Memcached server configuration failed');
    }
    $image = new Imagick();
    $image->newImage(2, 2, new ImagickPixel('red'));
    $image->setImageFormat('png');
    $decoded = new Imagick();
    $decoded->readImageBlob($image->getImageBlob());
    if ($decoded->getImageWidth() !== 2 || $decoded->getImageHeight() !== 2) {
        throw new RuntimeException('Imagick PNG round trip failed');
    }
    header('Content-Type: text/plain');
    echo "Native extension checks passed\n";
} catch (Throwable $error) {
    http_response_code(500);
    echo $error->getMessage(), "\n";
}
