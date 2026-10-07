<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$checks = [
    'postgres' => false,
    'redis' => false,
];

try {
    $passwordFile = getenv('POSTGRES_PASSWORD_FILE') ?: '/run/secrets/postgres_password';
    $password = file_get_contents($passwordFile);

    if ($password === false) {
        throw new RuntimeException('PostgreSQL password is unavailable.');
    }

    $host = getenv('POSTGRES_HOST') ?: 'postgres';
    $database = getenv('POSTGRES_DB') ?: 'default';
    $user = getenv('POSTGRES_USER') ?: 'pgsql_user';
    $dsn = "pgsql:host={$host};port=5432;dbname={$database}";

    $pdo = new PDO($dsn, $user, trim($password), [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 2,
    ]);
    $pdo->query('SELECT 1');
    $checks['postgres'] = true;
} catch (Throwable) {
    // Do not expose connection details from a public health endpoint.
}

try {
    $redis = new Redis();
    $redis->connect(getenv('REDIS_HOST') ?: 'redis', 6379, 2.0);
    $checks['redis'] = $redis->ping() !== false;
} catch (Throwable) {
    // Do not expose connection details from a public health endpoint.
}

$healthy = !in_array(false, $checks, true);
http_response_code($healthy ? 200 : 503);

echo json_encode(
    ['status' => $healthy ? 'ok' : 'unhealthy', 'checks' => $checks],
    JSON_THROW_ON_ERROR | JSON_PRETTY_PRINT,
);
